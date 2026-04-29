<?php

require_once __DIR__ . '/../config.php';

$pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);

header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST, GET, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type");
header("Content-Type: application/json; charset=UTF-8");

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

$action = $_POST['action'] ?? ($_GET['action'] ?? '');
$mobile = $_POST['mobile_number'] ?? ($_GET['mobile_number'] ?? '');

if (!$action || !$mobile) {
    http_response_code(400);
    echo json_encode(["status" => "error", "message" => "Missing action or mobile_number"]);
    exit();
}

// ── Auth ────────────────────────────────────────────────
try {
    $userStmt = $pdo->prepare("SELECT id, full_name, profile_image_url FROM cinecircle WHERE mobile_number = ? LIMIT 1");
    $userStmt->execute([$mobile]);
    $me = $userStmt->fetch(PDO::FETCH_ASSOC);

    if (!$me) {
        http_response_code(404);
        echo json_encode(["status" => "error", "message" => "User not found"]);
        exit();
    }
    $myId = $me['id'];
} catch (PDOException $e) {
    http_response_code(500);
    echo json_encode(["status" => "error", "message" => "DB error: " . $e->getMessage()]);
    exit();
}

// ── Helpers ─────────────────────────────────────────────
function generateUUID(): string {
    return sprintf('%04x%04x-%04x-%04x-%04x-%04x%04x%04x',
        mt_rand(0, 0xffff), mt_rand(0, 0xffff),
        mt_rand(0, 0xffff),
        mt_rand(0, 0x0fff) | 0x4000,
        mt_rand(0, 0x3fff) | 0x8000,
        mt_rand(0, 0xffff), mt_rand(0, 0xffff), mt_rand(0, 0xffff)
    );
}

function timeAgo(string $ts): string {
    $diff = (new DateTime())->diff(new DateTime($ts));
    if ($diff->days > 6)  return date('d M', strtotime($ts));
    if ($diff->days > 0)  return $diff->days . 'd ago';
    if ($diff->h   > 0)  return $diff->h   . 'h ago';
    if ($diff->i   > 0)  return $diff->i   . 'm ago';
    return 'Just now';
}

function createNotification(PDO $pdo, string $userId, ?string $actorId, string $type, string $title, string $body = '', string $entityType = '', string $entityId = ''): void {
    try {
        $pdo->prepare("
            INSERT INTO notifications (id, user_id, actor_id, type, title, body, entity_type, entity_id)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?)
        ")->execute([generateUUID(), $userId, $actorId, $type, $title, $body, $entityType, $entityId]);
    } catch (PDOException $e) {
        // Notification failure should never break the main action
    }
}

// Canonical conversation pair: always user1_id < user2_id (lexicographic)
function convPair(string $a, string $b): array {
    return strcmp($a, $b) < 0 ? [$a, $b] : [$b, $a];
}

try {

// ════════════════════════════════════════════════════════
// FOLLOW
// ════════════════════════════════════════════════════════

    // ── toggle_follow ──────────────────────────────────────
    if ($action === 'toggle_follow') {
        $targetId = $_POST['target_user_id'] ?? '';
        if (!$targetId || $targetId === $myId) {
            echo json_encode(["status" => "error", "message" => "Invalid target_user_id"]);
            exit();
        }

        $checkStmt = $pdo->prepare("SELECT id FROM user_follows WHERE follower_id = ? AND following_id = ?");
        $checkStmt->execute([$myId, $targetId]);

        if ($checkStmt->fetch()) {
            // Unfollow
            $pdo->prepare("DELETE FROM user_follows WHERE follower_id = ? AND following_id = ?")
                ->execute([$myId, $targetId]);
            $isFollowing = false;
        } else {
            // Follow
            $pdo->prepare("INSERT INTO user_follows (id, follower_id, following_id) VALUES (?, ?, ?)")
                ->execute([generateUUID(), $myId, $targetId]);
            $isFollowing = true;
            // Notify the followed user
            createNotification($pdo, $targetId, $myId, 'follow',
                ($me['full_name'] ?? 'Someone') . ' started following you', '', 'profile', $myId);
        }

        // Return fresh counts
        $cntStmt = $pdo->prepare("SELECT
            (SELECT COUNT(*) FROM user_follows WHERE following_id = ?) AS followers,
            (SELECT COUNT(*) FROM user_follows WHERE follower_id  = ?) AS following
        ");
        $cntStmt->execute([$targetId, $targetId]);
        $counts = $cntStmt->fetch(PDO::FETCH_ASSOC);

        echo json_encode([
            "status"       => "success",
            "is_following" => $isFollowing,
            "followers"    => (int)$counts['followers'],
            "following"    => (int)$counts['following'],
        ]);
    }

    // ── get_follow_state ───────────────────────────────────
    elseif ($action === 'get_follow_state') {
        $targetId = $_GET['target_user_id'] ?? '';
        if (!$targetId) {
            echo json_encode(["status" => "error", "message" => "Missing target_user_id"]);
            exit();
        }

        $stmt = $pdo->prepare("SELECT
            EXISTS(SELECT 1 FROM user_follows WHERE follower_id = ? AND following_id = ?) AS is_following,
            (SELECT COUNT(*) FROM user_follows WHERE following_id = ?)                    AS followers,
            (SELECT COUNT(*) FROM user_follows WHERE follower_id  = ?)                    AS following
        ");
        $stmt->execute([$myId, $targetId, $targetId, $targetId]);
        $row = $stmt->fetch(PDO::FETCH_ASSOC);

        echo json_encode([
            "status"       => "success",
            "is_following" => (bool)$row['is_following'],
            "followers"    => (int)$row['followers'],
            "following"    => (int)$row['following'],
        ]);
    }

    // ── get_followers ──────────────────────────────────────
    elseif ($action === 'get_followers') {
        $targetId = $_GET['target_user_id'] ?? $myId;
        $page  = max(1, (int)($_GET['page'] ?? 1));
        $limit = 30;
        $offset = ($page - 1) * $limit;

        $stmt = $pdo->prepare("
            SELECT u.id, u.full_name, u.role_title, u.profile_image_url, u.city,
                   EXISTS(SELECT 1 FROM user_follows WHERE follower_id = ? AND following_id = u.id) AS is_following
            FROM user_follows f
            JOIN cinecircle u ON f.follower_id = u.id
            WHERE f.following_id = ?
            ORDER BY f.created_at DESC
            LIMIT ? OFFSET ?
        ");
        $stmt->execute([$myId, $targetId, $limit, $offset]);
        $rows = $stmt->fetchAll(PDO::FETCH_ASSOC);
        foreach ($rows as &$r) $r['is_following'] = (bool)$r['is_following'];

        echo json_encode(["status" => "success", "data" => $rows, "page" => $page, "my_user_id" => $myId]);
    }

    elseif ($action === 'get_following') {
        $targetId = $_GET['target_user_id'] ?? $myId;
        $page  = max(1, (int)($_GET['page'] ?? 1));
        $limit = 30;
        $offset = ($page - 1) * $limit;

        $stmt = $pdo->prepare("
            SELECT u.id, u.full_name, u.role_title, u.profile_image_url, u.city,
                   EXISTS(SELECT 1 FROM user_follows WHERE follower_id = ? AND following_id = u.id) AS is_following
            FROM user_follows f
            JOIN cinecircle u ON f.following_id = u.id
            WHERE f.follower_id = ?
            ORDER BY f.created_at DESC
            LIMIT ? OFFSET ?
        ");
        $stmt->execute([$myId, $targetId, $limit, $offset]);
        $rows = $stmt->fetchAll(PDO::FETCH_ASSOC);
        foreach ($rows as &$r) $r['is_following'] = (bool)$r['is_following'];

        echo json_encode(["status" => "success", "data" => $rows, "page" => $page, "my_user_id" => $myId]);
    }

// ════════════════════════════════════════════════════════
// PROFILE VIEWS
// ════════════════════════════════════════════════════════

    // ── record_profile_view ────────────────────────────────
    elseif ($action === 'record_profile_view') {
        $profileId = $_POST['profile_id'] ?? '';
        if (!$profileId || $profileId === $myId) {
            echo json_encode(["status" => "ok"]);  // Silently skip self-views
            exit();
        }

        // Deduplicate: one view per viewer per profile per calendar day
        $pdo->prepare("
            INSERT INTO profile_views (id, viewer_id, profile_id, viewed_at)
            VALUES (?, ?, ?, NOW())
            ON DUPLICATE KEY UPDATE viewed_at = NOW()
        ")->execute([generateUUID(), $myId, $profileId]);

        // Notify profile owner — at most once per viewer per day
        $notifCheck = $pdo->prepare("
            SELECT id FROM notifications
            WHERE user_id = ? AND actor_id = ? AND type = 'profile_view'
              AND DATE(created_at) = CURDATE()
        ");
        $notifCheck->execute([$profileId, $myId]);
        if (!$notifCheck->fetch()) {
            createNotification($pdo, $profileId, $myId, 'profile_view',
                ($me['full_name'] ?? 'Someone') . ' viewed your profile', '', 'profile', $myId);
        }

        echo json_encode(["status" => "ok"]);
    }

    // ── get_profile_viewers ────────────────────────────────
    elseif ($action === 'get_profile_viewers') {
        $stmt = $pdo->prepare("
            SELECT u.id, u.full_name, u.role_title, u.profile_image_url, u.city,
                   pv.viewed_at,
                   EXISTS(SELECT 1 FROM user_follows WHERE follower_id = ? AND following_id = u.id) AS is_following
            FROM profile_views pv
            JOIN cinecircle u ON pv.viewer_id = u.id
            WHERE pv.profile_id = ?
            ORDER BY pv.viewed_at DESC
            LIMIT 50
        ");
        $stmt->execute([$myId, $myId]);
        $rows = $stmt->fetchAll(PDO::FETCH_ASSOC);
        foreach ($rows as &$r) {
            $r['is_following'] = (bool)$r['is_following'];
            $r['time_ago']     = timeAgo($r['viewed_at']);
        }

        // Total unique viewer count in the last 30 days
        $totalStmt = $pdo->prepare("
            SELECT COUNT(DISTINCT viewer_id) AS total_views
            FROM profile_views
            WHERE profile_id = ? AND viewed_at >= DATE_SUB(NOW(), INTERVAL 30 DAY)
        ");
        $totalStmt->execute([$myId]);
        $total = (int)$totalStmt->fetchColumn();

        echo json_encode(["status" => "success", "data" => $rows, "total_views_30d" => $total]);
    }

// ════════════════════════════════════════════════════════
// MESSAGING
// ════════════════════════════════════════════════════════

    // ── get_conversations ──────────────────────────────────
    elseif ($action === 'get_conversations') {
        $stmt = $pdo->prepare("
            SELECT c.id AS conversation_id,
                   c.last_message, c.last_message_at,
                   CASE WHEN c.user1_id = ? THEN c.unread_user1 ELSE c.unread_user2 END AS unread_count,
                   CASE WHEN c.user1_id = ? THEN c.user2_id    ELSE c.user1_id    END AS other_user_id,
                   u.full_name, u.role_title, u.profile_image_url
            FROM conversations c
            JOIN cinecircle u ON u.id = CASE WHEN c.user1_id = ? THEN c.user2_id ELSE c.user1_id END
            WHERE (c.user1_id = ? OR c.user2_id = ?) AND c.last_message IS NOT NULL
            ORDER BY c.last_message_at DESC
        ");
        $stmt->execute([$myId, $myId, $myId, $myId, $myId]);
        $rows = $stmt->fetchAll(PDO::FETCH_ASSOC);
        foreach ($rows as &$r) {
            $r['time_ago']     = timeAgo($r['last_message_at']);
            $r['unread_count'] = (int)$r['unread_count'];
        }

        echo json_encode(["status" => "success", "data" => $rows]);
    }

    // ── get_messages ───────────────────────────────────────
    elseif ($action === 'get_messages') {
        $convId = $_GET['conversation_id'] ?? '';
        if (!$convId) {
            echo json_encode(["status" => "error", "message" => "Missing conversation_id"]);
            exit();
        }
        $page  = max(1, (int)($_GET['page'] ?? 1));
        $limit = 40;
        $offset = ($page - 1) * $limit;

        // Verify membership
        $chkStmt = $pdo->prepare("SELECT id, user1_id, user2_id FROM conversations WHERE id = ? AND (user1_id = ? OR user2_id = ?)");
        $chkStmt->execute([$convId, $myId, $myId]);
        $conv = $chkStmt->fetch(PDO::FETCH_ASSOC);
        if (!$conv) {
            echo json_encode(["status" => "error", "message" => "Conversation not found"]);
            exit();
        }

        $stmt = $pdo->prepare("
            SELECT m.id, m.sender_id, m.body, m.media_url, m.media_type, m.is_read, m.sent_at,
                   m.reply_to_message_id,
                   u.full_name AS sender_name, u.profile_image_url AS sender_avatar,
                   r.body AS reply_to_body,
                   ru.full_name AS reply_to_sender_name
            FROM messages m
            JOIN cinecircle u ON m.sender_id = u.id
            LEFT JOIN messages r ON m.reply_to_message_id = r.id
            LEFT JOIN cinecircle ru ON r.sender_id = ru.id
            WHERE m.conversation_id = ?
            ORDER BY m.sent_at DESC
            LIMIT ? OFFSET ?
        ");
        $stmt->execute([$convId, $limit, $offset]);
        $msgs = $stmt->fetchAll(PDO::FETCH_ASSOC);
        // Reverse so oldest first (chat display order)
        $msgs = array_reverse($msgs);

        $reactionsByMessage = [];
        $messageIds = array_column($msgs, 'id');
        if (!empty($messageIds)) {
            $placeholders = implode(',', array_fill(0, count($messageIds), '?'));
            $params = array_merge([$myId], $messageIds);
            $rxStmt = $pdo->prepare("
                SELECT message_id, emoji, COUNT(*) AS count,
                       SUM(user_id = ?) AS reacted
                FROM message_reactions
                WHERE message_id IN ($placeholders)
                GROUP BY message_id, emoji
            ");
            $rxStmt->execute($params);
            $rxRows = $rxStmt->fetchAll(PDO::FETCH_ASSOC);
            foreach ($rxRows as $r) {
                $mid = $r['message_id'];
                if (!isset($reactionsByMessage[$mid])) $reactionsByMessage[$mid] = [];
                $reactionsByMessage[$mid][] = [
                    'emoji' => $r['emoji'],
                    'count' => (int)$r['count'],
                    'reacted' => ((int)$r['reacted']) > 0,
                ];
            }
        }
        foreach ($msgs as &$m) {
            $m['is_me']    = $m['sender_id'] === $myId;
            $m['is_read']  = (bool)$m['is_read'];
            $m['time_ago'] = timeAgo($m['sent_at']);
            $m['reactions'] = $reactionsByMessage[$m['id']] ?? [];
        }

        // Mark all incoming messages as read
        $pdo->prepare("UPDATE messages SET is_read = 1 WHERE conversation_id = ? AND sender_id != ?")
            ->execute([$convId, $myId]);

        // Reset unread count for me
        if ($conv['user1_id'] === $myId) {
            $pdo->prepare("UPDATE conversations SET unread_user1 = 0 WHERE id = ?")->execute([$convId]);
        } else {
            $pdo->prepare("UPDATE conversations SET unread_user2 = 0 WHERE id = ?")->execute([$convId]);
        }

        echo json_encode(["status" => "success", "data" => $msgs, "page" => $page]);
    }

    // ── send_message ───────────────────────────────────────
    elseif ($action === 'send_message') {
        $recipientId = $_POST['recipient_id']    ?? '';
        $body        = trim($_POST['body']       ?? '');
        $mediaUrl    = $_POST['media_url']       ?? null;
        $mediaType   = $_POST['media_type']      ?? null;
        $replyToId   = $_POST['reply_to_message_id'] ?? null;

        if (!$recipientId || (!$body && !$mediaUrl)) {
            echo json_encode(["status" => "error", "message" => "Missing recipient_id or body"]);
            exit();
        }

        [$u1, $u2] = convPair($myId, $recipientId);

        // Get or create conversation
        $convStmt = $pdo->prepare("SELECT id, user1_id FROM conversations WHERE user1_id = ? AND user2_id = ?");
        $convStmt->execute([$u1, $u2]);
        $conv = $convStmt->fetch(PDO::FETCH_ASSOC);

        $msgId   = generateUUID();
        $snippet = mb_substr($body ?: '📎 Media', 0, 100);

        if (!$conv) {
            // Create conversation
            $convId = generateUUID();
            // Determine who is user1 vs user2 to set correct unread
            $unread1 = $u1 === $recipientId ? 1 : 0;
            $unread2 = $u2 === $recipientId ? 1 : 0;
            $pdo->prepare("
                INSERT INTO conversations (id, user1_id, user2_id, last_message, last_message_at, unread_user1, unread_user2)
                VALUES (?, ?, ?, ?, NOW(), ?, ?)
            ")->execute([$convId, $u1, $u2, $snippet, $unread1, $unread2]);
        } else {
            $convId = $conv['id'];
            // Increment unread for recipient
            $unreadCol = ($conv['user1_id'] === $recipientId) ? 'unread_user1' : 'unread_user2';
            $pdo->prepare("
                UPDATE conversations SET last_message = ?, last_message_at = NOW(), $unreadCol = $unreadCol + 1
                WHERE id = ?
            ")->execute([$snippet, $convId]);
        }

        if ($replyToId) {
            $replyStmt = $pdo->prepare("SELECT id FROM messages WHERE id = ? AND conversation_id = ?");
            $replyStmt->execute([$replyToId, $convId]);
            if (!$replyStmt->fetch()) {
                echo json_encode(["status" => "error", "message" => "Invalid reply target"]);
                exit();
            }
        }

        // Insert message
        $pdo->prepare("
            INSERT INTO messages (id, conversation_id, sender_id, body, media_url, media_type, reply_to_message_id)
            VALUES (?, ?, ?, ?, ?, ?, ?)
        ")->execute([$msgId, $convId, $myId, $body, $mediaUrl, $mediaType, $replyToId]);

        // Notification for recipient
        createNotification($pdo, $recipientId, $myId, 'message',
            ($me['full_name'] ?? 'Someone') . ' sent you a message',
            mb_substr($body, 0, 80),
            'conversation', $convId
        );

        echo json_encode([
            "status"          => "success",
            "message_id"      => $msgId,
            "conversation_id" => $convId,
        ]);
    }

    // ── react_message ─────────────────────────────────────
    elseif ($action === 'react_message') {
        $messageId = $_POST['message_id'] ?? '';
        $emoji = $_POST['emoji'] ?? '';
        if (!$messageId) {
            echo json_encode(["status" => "error", "message" => "Missing message_id"]);
            exit();
        }

        $chk = $pdo->prepare("
            SELECT m.conversation_id, c.user1_id, c.user2_id
            FROM messages m
            JOIN conversations c ON m.conversation_id = c.id
            WHERE m.id = ?
        ");
        $chk->execute([$messageId]);
        $row = $chk->fetch(PDO::FETCH_ASSOC);
        if (!$row || ($row['user1_id'] !== $myId && $row['user2_id'] !== $myId)) {
            echo json_encode(["status" => "error", "message" => "Unauthorized"]);
            exit();
        }

        $pdo->prepare("DELETE FROM message_reactions WHERE message_id = ? AND user_id = ?")
            ->execute([$messageId, $myId]);

        if (!empty($emoji)) {
            $pdo->prepare("INSERT INTO message_reactions (id, message_id, user_id, emoji) VALUES (?, ?, ?, ?)")
                ->execute([generateUUID(), $messageId, $myId, $emoji]);
        }

        $rxStmt = $pdo->prepare("
            SELECT message_id, emoji, COUNT(*) AS count,
                   SUM(user_id = ?) AS reacted
            FROM message_reactions
            WHERE message_id = ?
            GROUP BY message_id, emoji
        ");
        $rxStmt->execute([$myId, $messageId]);
        $rxRows = $rxStmt->fetchAll(PDO::FETCH_ASSOC);

        $reactions = [];
        foreach ($rxRows as $r) {
            $reactions[] = [
                'emoji' => $r['emoji'],
                'count' => (int)$r['count'],
                'reacted' => ((int)$r['reacted']) > 0,
            ];
        }

        echo json_encode(["status" => "success", "data" => $reactions]);
    }

    // ── start_conversation ─────────────────────────────────
    elseif ($action === 'start_conversation') {
        $recipientId = $_POST['recipient_id'] ?? '';
        if (!$recipientId || $recipientId === $myId) {
            echo json_encode(["status" => "error", "message" => "Invalid recipient_id"]);
            exit();
        }

        [$u1, $u2] = convPair($myId, $recipientId);

        $convStmt = $pdo->prepare("SELECT id FROM conversations WHERE user1_id = ? AND user2_id = ?");
        $convStmt->execute([$u1, $u2]);
        $conv = $convStmt->fetch(PDO::FETCH_ASSOC);

        if (!$conv) {
            $convId = generateUUID();
            $pdo->prepare("INSERT INTO conversations (id, user1_id, user2_id) VALUES (?, ?, ?)")
                ->execute([$convId, $u1, $u2]);
        } else {
            $convId = $conv['id'];
        }

        echo json_encode(["status" => "success", "conversation_id" => $convId]);
    }

// ════════════════════════════════════════════════════════
// NOTIFICATIONS / ACTIVITY
// ════════════════════════════════════════════════════════

    // ── get_notifications ──────────────────────────────────
    elseif ($action === 'get_notifications') {
        $type  = $_GET['type'] ?? '';  // '' = All, else filter by type
        $page  = max(1, (int)($_GET['page'] ?? 1));
        $limit = 30;
        $offset = ($page - 1) * $limit;

        $params = [$myId];
        $where  = ['n.user_id = ?'];

        if (!empty($type) && $type !== 'All') {
            // Map pill label → DB type values
            $typeMap = [
                'Jobs'           => ['job_match', 'job_application'],
                'Network'        => ['follow', 'profile_view'],
                'Screening Room' => ['post_like', 'post_comment'],
                'Trivia'         => ['daily_quiz', 'reward_redeemed'],
            ];
            if (isset($typeMap[$type])) {
                $placeholders = implode(',', array_fill(0, count($typeMap[$type]), '?'));
                $where[] = "n.type IN ($placeholders)";
                $params  = array_merge($params, $typeMap[$type]);
            }
        }

        $whereClause = implode(' AND ', $where);
        $params[] = $limit;
        $params[] = $offset;

        $stmt = $pdo->prepare("
            SELECT n.id, n.type, n.title, n.body, n.entity_type, n.entity_id, n.is_read, n.created_at,
                   u.full_name AS actor_name, u.profile_image_url AS actor_avatar
            FROM notifications n
            LEFT JOIN cinecircle u ON n.actor_id = u.id
            WHERE $whereClause
            ORDER BY n.created_at DESC
            LIMIT ? OFFSET ?
        ");
        $stmt->execute($params);
        $rows = $stmt->fetchAll(PDO::FETCH_ASSOC);
        foreach ($rows as &$r) {
            $r['is_read']  = (bool)$r['is_read'];
            $r['time_ago'] = timeAgo($r['created_at']);
        }

        // Unread count badge
        $unreadStmt = $pdo->prepare("SELECT COUNT(*) FROM notifications WHERE user_id = ? AND is_read = 0");
        $unreadStmt->execute([$myId]);
        $unread = (int)$unreadStmt->fetchColumn();

        echo json_encode(["status" => "success", "data" => $rows, "unread_count" => $unread, "page" => $page]);
    }

    // ── mark_notifications_read ────────────────────────────
    elseif ($action === 'mark_notifications_read') {
        $notifId = $_POST['notification_id'] ?? '';  // Empty = mark all

        if ($notifId) {
            $pdo->prepare("UPDATE notifications SET is_read = 1 WHERE id = ? AND user_id = ?")
                ->execute([$notifId, $myId]);
        } else {
            $pdo->prepare("UPDATE notifications SET is_read = 1 WHERE user_id = ?")
                ->execute([$myId]);
        }

        echo json_encode(["status" => "success"]);
    }

// ════════════════════════════════════════════════════════
// PUBLIC PROFILE
// ════════════════════════════════════════════════════════

    // ── get_user_profile ───────────────────────────────────
    elseif ($action === 'get_user_profile') {
        $targetId = $_GET['target_user_id'] ?? '';
        if (!$targetId) {
            echo json_encode(["status" => "error", "message" => "Missing target_user_id"]);
            exit();
        }

        $stmt = $pdo->prepare("
            SELECT u.id, u.full_name, u.role_title, u.bio, u.city,
                   u.profile_image_url, u.mobile_number,
                   (SELECT COUNT(*) FROM user_follows WHERE following_id = u.id) AS followers,
                   (SELECT COUNT(*) FROM user_follows WHERE follower_id  = u.id) AS following,
                   EXISTS(SELECT 1 FROM user_follows WHERE follower_id = ? AND following_id = u.id) AS is_following,
                   EXISTS(SELECT 1 FROM user_follows WHERE follower_id = u.id AND following_id = ?) AS follows_you
            FROM cinecircle u
            WHERE u.id = ?
        ");
        $stmt->execute([$myId, $myId, $targetId]);
        $profile = $stmt->fetch(PDO::FETCH_ASSOC);

        if (!$profile) {
            echo json_encode(["status" => "error", "message" => "User not found"]);
            exit();
        }

        $profile['is_following'] = (bool)$profile['is_following'];
        $profile['follows_you']  = (bool)$profile['follows_you'];
        $profile['followers']    = (int)$profile['followers'];
        $profile['following']    = (int)$profile['following'];

        // Skills
        try {
            $sklStmt = $pdo->prepare("SELECT skill_name FROM user_skills WHERE user_id = ?");
            $sklStmt->execute([$targetId]);
            $profile['skills'] = $sklStmt->fetchAll(PDO::FETCH_COLUMN);
        } catch (PDOException $e) { $profile['skills'] = []; }

        // Credits
        try {
            $crdStmt = $pdo->prepare("SELECT project_title, role, year FROM user_credits WHERE user_id = ? ORDER BY year DESC LIMIT 20");
            $crdStmt->execute([$targetId]);
            $profile['credits'] = $crdStmt->fetchAll(PDO::FETCH_ASSOC);
        } catch (PDOException $e) { $profile['credits'] = []; }

        // Reels
        try {
            $rlStmt = $pdo->prepare("SELECT id, title, description, media_url, thumbnail_url FROM featured_reels WHERE user_id = ? LIMIT 10");
            $rlStmt->execute([$targetId]);
            $profile['reels'] = $rlStmt->fetchAll(PDO::FETCH_ASSOC);
        } catch (PDOException $e) { $profile['reels'] = []; }

        // Record profile view
        if ($myId !== $targetId) {
            try {
                $viewCheck = $pdo->prepare("
                    SELECT id FROM profile_views
                    WHERE viewer_id = ? AND profile_id = ? AND DATE(viewed_at) = CURDATE()
                ");
                $viewCheck->execute([$myId, $targetId]);
                $existingView = $viewCheck->fetch();

                if ($existingView) {
                    $pdo->prepare("UPDATE profile_views SET viewed_at = NOW() WHERE id = ?")
                        ->execute([$existingView['id']]);
                } else {
                    $pdo->prepare("INSERT INTO profile_views (id, viewer_id, profile_id, viewed_at) VALUES (?, ?, ?, NOW())")
                        ->execute([generateUUID(), $myId, $targetId]);

                    $notifCheck = $pdo->prepare("
                        SELECT id FROM notifications
                        WHERE user_id = ? AND actor_id = ? AND type = 'profile_view' AND DATE(created_at) = CURDATE()
                    ");
                    $notifCheck->execute([$targetId, $myId]);
                    if (!$notifCheck->fetch()) {
                        createNotification($pdo, $targetId, $myId, 'profile_view',
                            ($me['full_name'] ?? 'Someone') . ' viewed your profile', '', 'profile', $myId);
                    }
                }
            } catch (PDOException $e) { }
        }

        echo json_encode(["status" => "success", "data" => $profile]);
    } 

    elseif ($action === 'create_post') {
        $category    = $_POST['category'] ?? 'Other';
        $title       = $_POST['title']    ?? '';
        $description = $_POST['description'] ?? '';
        $mediaType   = $_POST['media_type']  ?? 'image';
        
        $userNameSanitized = preg_replace('/[^A-Za-z0-9_\-]/', '_', $me['full_name'] ?? 'User');
        $uploadSubDir = 'uploads/feed/' . $userNameSanitized . '/';
        $uploadFullPath = __DIR__ . '/' . $uploadSubDir;
        
        if (!is_dir($uploadFullPath)) {
            mkdir($uploadFullPath, 0777, true);
        }

        $mediaUrl = '';
        if (isset($_FILES['media']) && $_FILES['media']['error'] === UPLOAD_ERR_OK) {
            $ext = strtolower(pathinfo($_FILES['media']['name'], PATHINFO_EXTENSION));
            $fileName = generateUUID() . '.' . $ext;
            
            if (move_uploaded_file($_FILES['media']['tmp_name'], $uploadFullPath . $fileName)) {
                $protocol = (isset($_SERVER['HTTPS']) && $_SERVER['HTTPS'] === 'on') ? "https" : "http";
                $host = $_SERVER['HTTP_HOST'];
                $scriptDir = dirname($_SERVER['PHP_SELF']);
                $mediaUrl = "$protocol://$host" . rtrim($scriptDir, '/') . '/' . $uploadSubDir . $fileName;
            } else {
                echo json_encode(["status" => "error", "message" => "Failed to move upload"]);
                exit();
            }
        }

        $postId = generateUUID();
        $stmt = $pdo->prepare("
            INSERT INTO feed_posts (id, user_id, category, title, description, media_url, media_type, created_at)
            VALUES (?, ?, ?, ?, ?, ?, ?, NOW())
        ");
        $stmt->execute([
            $postId,
            $myId,
            $category,
            $title,
            $description,
            $mediaUrl,
            $mediaType
        ]);

        echo json_encode([
            "status" => "success", 
            "message" => "Post created", 
            "post_id" => $postId
        ]);
    }

        elseif ($action === 'get_user_posts') {
            $targetId = $_GET['target_user_id'] ?? $myId;
            $stmt = $pdo->prepare("
                SELECT 
                    p.id, p.user_id, p.category, p.title, p.description,
                    p.media_url, p.media_type, p.created_at,
                    u.full_name as author_name, u.role_title, u.profile_image_url,
                    (SELECT COUNT(*) FROM feed_likes WHERE post_id = p.id) as likes_count,
                    (SELECT COUNT(*) FROM feed_comments WHERE post_id = p.id) as comments_count,
                    (SELECT COUNT(*) FROM feed_views WHERE post_id = p.id) as views_count,
                    EXISTS(SELECT 1 FROM feed_likes WHERE post_id = p.id AND user_id = ?) as is_liked,
                    EXISTS(SELECT 1 FROM feed_saves WHERE post_id = p.id AND user_id = ?) as is_saved
                FROM feed_posts p
                JOIN cinecircle u ON p.user_id = u.id
                WHERE p.user_id = ?
                ORDER BY p.created_at DESC
            ");
            $stmt->execute([$myId, $myId, $targetId]);
            $posts = $stmt->fetchAll(PDO::FETCH_ASSOC);

            echo json_encode(["status" => "success", "data" => $posts]);
        }

        elseif ($action === 'update_post') {
            $postId = $_POST['post_id'] ?? '';
            $title = trim($_POST['title'] ?? '');
            $description = trim($_POST['description'] ?? '');
            $category = trim($_POST['category'] ?? 'Other');

            if (!$postId) {
                echo json_encode(["status" => "error", "message" => "Missing post_id"]);
                exit();
            }

            $stmt = $pdo->prepare("SELECT user_id, created_at FROM feed_posts WHERE id = ?");
            $stmt->execute([$postId]);
            $post = $stmt->fetch(PDO::FETCH_ASSOC);

            if (!$post) {
                echo json_encode(["status" => "error", "message" => "Post not found"]);
                exit();
            }

            if ($post['user_id'] !== $myId) {
                echo json_encode(["status" => "error", "message" => "Unauthorized"]);
                exit();
            }

            $createdAt = new DateTime($post['created_at']);
            $diff = (new DateTime())->diff($createdAt);
            $ageMinutes = $diff->days * 24 * 60 + $diff->h * 60 + $diff->i;
            if ($ageMinutes > 15) {
                echo json_encode(["status" => "error", "message" => "Editing is allowed only within 15 minutes of posting"]);
                exit();
            }

            $update = $pdo->prepare("UPDATE feed_posts SET title = ?, description = ?, category = ? WHERE id = ?");
            $update->execute([$title, $description, $category, $postId]);

            echo json_encode(["status" => "success", "message" => "Post updated"]);
        }

    elseif ($action === 'delete_post') {
        $postId = $_POST['post_id'] ?? '';
        if (!$postId) {
            echo json_encode(["status" => "error", "message" => "Missing post_id"]);
            exit();
        }

        $stmt = $pdo->prepare("SELECT user_id, media_url FROM feed_posts WHERE id = ?");
        $stmt->execute([$postId]);
        $post = $stmt->fetch(PDO::FETCH_ASSOC);

        if (!$post) {
            echo json_encode(["status" => "error", "message" => "Post not found"]);
            exit();
        }

        if ($post['user_id'] !== $myId) {
            echo json_encode(["status" => "error", "message" => "Unauthorized"]);
            exit();
        }

        if ($post['media_url']) {
            $parsedUrl = parse_url($post['media_url']);
            $path = $parsedUrl['path'];
            $scriptDir = dirname($_SERVER['PHP_SELF']);
            $relativePath = str_replace($scriptDir, '', $path);
            $localPath = __DIR__ . $relativePath;
            
            if (file_exists($localPath)) {
                unlink($localPath);
            }
        }

        $pdo->prepare("DELETE FROM feed_posts WHERE id = ?")->execute([$postId]);
        $pdo->prepare("DELETE FROM feed_likes WHERE post_id = ?")->execute([$postId]);
        $pdo->prepare("DELETE FROM feed_comments WHERE post_id = ?")->execute([$postId]);

        echo json_encode(["status" => "success", "message" => "Post deleted"]);
    }

    // --- SOCIAL CREDITS SYSTEM ---
    elseif ($action === 'get_social_credits') {
        $stmt = $pdo->prepare("SELECT balance FROM social_credits WHERE user_id = ?");
        $stmt->execute([$myId]);
        $row = $stmt->fetch(PDO::FETCH_ASSOC);
        echo json_encode(["status" => "success", "balance" => $row ? (int)$row['balance'] : 0]);
    }

    elseif ($action === 'get_credits') {
        $stmt = $pdo->prepare("SELECT current_balance, total_earned FROM social_credits WHERE user_id = ?");
        $stmt->execute([$myId]);
        $credits = $stmt->fetch(PDO::FETCH_ASSOC);

        if (!$credits) {
            $credits = ["current_balance" => 0, "total_earned" => 0];
        }

        $totalSpent = (int)$credits['total_earned'] - (int)$credits['current_balance'];

        $stmt = $pdo->prepare("SELECT transaction_type, activity_type, amount, description, created_at FROM credit_transactions WHERE user_id = ? ORDER BY created_at DESC LIMIT 20");
        $stmt->execute([$myId]);
        $rawHistory = $stmt->fetchAll(PDO::FETCH_ASSOC);

        $history = [];
        foreach ($rawHistory as $h) {
            $history[] = [
                'type' => strtolower($h['transaction_type']),
                'source' => strtolower($h['activity_type']),
                'amount' => abs($h['amount']), 
                'title' => $h['description'],
                'created_at' => $h['created_at']
            ];
        }

        echo json_encode([
            "status" => "success",
            "data" => [
                "balance" => (int)$credits['current_balance'],
                "total_earned" => (int)$credits['total_earned'],
                "total_spent" => $totalSpent,
                "history" => $history
            ]
        ]);
    }

    elseif ($action === 'award_social_credits') {
        $amount = (int)($_POST['amount'] ?? 10);
        $activity = strtoupper($_POST['activity'] ?? 'GENERAL');
        $description = $_POST['description'] ?? '';

        $pdo->beginTransaction();
        try {
            $stmt = $pdo->prepare("SELECT user_id, current_balance, total_earned FROM social_credits WHERE user_id = ? FOR UPDATE");
            $stmt->execute([$myId]);
            $row = $stmt->fetch(PDO::FETCH_ASSOC);

            if ($row) {
                $newBalance = $row['current_balance'] + $amount;
                $newEarned = $row['total_earned'] + $amount;
                $update = $pdo->prepare("UPDATE social_credits SET current_balance = ?, total_earned = ? WHERE user_id = ?");
                $update->execute([$newBalance, $newEarned, $myId]);
            } else {
                $newBalance = $amount;
                $insert = $pdo->prepare("INSERT INTO social_credits (user_id, mobile_number, current_balance, total_earned) VALUES (?, ?, ?, ?)");
                $insert->execute([$myId, $mobile, $amount, $amount]);
            }

            $log = $pdo->prepare("INSERT INTO credit_transactions (user_id, amount, transaction_type, activity_type, description) VALUES (?, ?, 'EARN', ?, ?)");
            $log->execute([$myId, $amount, $activity, $description]);

            $pdo->commit();
            echo json_encode(["status" => "success", "new_balance" => $newBalance]);
        } catch (Exception $e) {
            $pdo->rollBack();
            echo json_encode(["status" => "error", "message" => $e->getMessage()]);
        }
    }

    elseif ($action === 'get_reward_categories') {
        $stmt = $pdo->prepare("
            SELECT DISTINCT reward_type AS category
            FROM reward_catalog
            WHERE is_active = 1
            ORDER BY FIELD(reward_type, 'TICKET', 'MERCH', 'BADGE', 'PREMIUM')
        ");
        $stmt->execute();
        $categories = $stmt->fetchAll(PDO::FETCH_COLUMN);

        $balStmt = $pdo->prepare("SELECT current_balance FROM social_credits WHERE user_id = ?");
        $balStmt->execute([$myId]);
        $balRow = $balStmt->fetch(PDO::FETCH_ASSOC);

        echo json_encode([
            "status"     => "success",
            "categories" => $categories,
            "balance"    => $balRow ? (int)$balRow['current_balance'] : 0
        ]);
    }

    elseif ($action === 'get_reward_items') {
        $rewardType = strtoupper(trim($_GET['tab'] ?? 'MERCH'));
        $allowed = ['TICKET', 'MERCH', 'BADGE', 'PREMIUM'];
        if (!in_array($rewardType, $allowed)) $rewardType = 'MERCH';

        $stmt = $pdo->prepare("
            SELECT id, reward_name AS title, description,
                   cost_credits AS credits_cost, reward_type AS category,
                   stock_quantity, image_url, icon_name,
                   CASE WHEN stock_quantity IS NULL THEN NULL
                        WHEN stock_quantity = 0 THEN 'Out of stock'
                        WHEN stock_quantity <= 5 THEN CONCAT('Only ', stock_quantity, ' left')
                        ELSE NULL END AS stock_label
            FROM reward_catalog
            WHERE reward_type = ? AND is_active = 1
            ORDER BY cost_credits ASC
        ");
        $stmt->execute([$rewardType]);
        $items = $stmt->fetchAll(PDO::FETCH_ASSOC);
        foreach ($items as &$item) {
            $item['credits_cost'] = (int)$item['credits_cost'];
            if ($item['stock_quantity'] !== null) {
                $item['stock_quantity'] = (int)$item['stock_quantity'];
            }
        }

        $balStmt = $pdo->prepare("SELECT current_balance FROM social_credits WHERE user_id = ?");
        $balStmt->execute([$myId]);
        $balRow = $balStmt->fetch(PDO::FETCH_ASSOC);

        echo json_encode([
            "status"  => "success",
            "data"    => $items,
            "balance" => $balRow ? (int)$balRow['current_balance'] : 0
        ]);
    }

    elseif ($action === 'redeem_item') {
        $itemId = $_POST['item_id'] ?? '';
        
        $pdo->beginTransaction();
        try {
            $stmt = $pdo->prepare("SELECT * FROM reward_catalog WHERE id = ? FOR UPDATE");
            $stmt->execute([$itemId]);
            $item = $stmt->fetch(PDO::FETCH_ASSOC);

            if (!$item) throw new Exception("Item not found");

            $balStmt = $pdo->prepare("SELECT user_id, current_balance FROM social_credits WHERE user_id = ? FOR UPDATE");
            $balStmt->execute([$myId]);
            $balRow = $balStmt->fetch(PDO::FETCH_ASSOC);

            if (!$balRow || $balRow['current_balance'] < $item['cost_credits']) {
                echo json_encode(["status" => "insufficient_credits", "balance" => $balRow ? $balRow['current_balance'] : 0, "required" => $item['cost_credits']]);
                $pdo->rollBack();
                exit();
            }

            $newBalance = $balRow['current_balance'] - $item['cost_credits'];
            $pdo->prepare("UPDATE social_credits SET current_balance = ? WHERE user_id = ?")
                ->execute([$newBalance, $myId]);

            $pdo->prepare("INSERT INTO credit_transactions (user_id, amount, transaction_type, activity_type, description) VALUES (?, ?, 'SPEND', 'REDEMPTION', ?)")
                ->execute([$myId, -$item['cost_credits'], "Redeemed " . $item['reward_name']]);

            $pdo->prepare("INSERT INTO redemptions (user_id, reward_id, status) VALUES (?, ?, 'PENDING')")
                ->execute([$myId, $itemId]);

            $pdo->commit();
            echo json_encode(["status" => "success", "new_balance" => $newBalance]);
        } catch (Exception $e) {
            $pdo->rollBack();
            echo json_encode(["status" => "error", "message" => $e->getMessage()]);
        }
    }

    // THE 'ELSE' BLOCK MUST BE THE VERY LAST CONDITIONAL IN THE CHAIN
    else {
        http_response_code(400);
        echo json_encode(["status" => "error", "message" => "Invalid action: $action"]);
    }

} catch (PDOException $e) {
    http_response_code(500);
    echo json_encode(["status" => "error", "message" => "DB error: " . $e->getMessage()]);
}
?>