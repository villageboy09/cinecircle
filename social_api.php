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

        echo json_encode(["status" => "success", "data" => $rows, "page" => $page]);
    }

    // ── get_following ──────────────────────────────────────
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

        echo json_encode(["status" => "success", "data" => $rows, "page" => $page]);
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
        // Check if notification was already sent today
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
                   u.full_name AS sender_name, u.profile_image_url AS sender_avatar
            FROM messages m
            JOIN cinecircle u ON m.sender_id = u.id
            WHERE m.conversation_id = ?
            ORDER BY m.sent_at DESC
            LIMIT ? OFFSET ?
        ");
        $stmt->execute([$convId, $limit, $offset]);
        $msgs = $stmt->fetchAll(PDO::FETCH_ASSOC);
        // Reverse so oldest first (chat display order)
        $msgs = array_reverse($msgs);
        foreach ($msgs as &$m) {
            $m['is_me']    = $m['sender_id'] === $myId;
            $m['is_read']  = (bool)$m['is_read'];
            $m['time_ago'] = timeAgo($m['sent_at']);
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
        $body        = trim($_POST['body']        ?? '');
        $mediaUrl    = $_POST['media_url']        ?? null;
        $mediaType   = $_POST['media_type']       ?? null;

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

        // Insert message
        $pdo->prepare("
            INSERT INTO messages (id, conversation_id, sender_id, body, media_url, media_type)
            VALUES (?, ?, ?, ?, ?, ?)
        ")->execute([$msgId, $convId, $myId, $body, $mediaUrl, $mediaType]);

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

    // ── start_conversation ─────────────────────────────────
    // Lightweight: just ensure a conversation row exists, return its id
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

        // Skills — graceful fallback if table doesn't exist
        try {
            $sklStmt = $pdo->prepare("SELECT skill_name FROM user_skills WHERE user_id = ?");
            $sklStmt->execute([$targetId]);
            $profile['skills'] = $sklStmt->fetchAll(PDO::FETCH_COLUMN);
        } catch (PDOException $e) { $profile['skills'] = []; }

        // Credits — graceful fallback if table doesn't exist
        try {
            $crdStmt = $pdo->prepare("SELECT project_title, role, year FROM user_credits WHERE user_id = ? ORDER BY year DESC LIMIT 20");
            $crdStmt->execute([$targetId]);
            $profile['credits'] = $crdStmt->fetchAll(PDO::FETCH_ASSOC);
        } catch (PDOException $e) { $profile['credits'] = []; }

        // Reels — graceful fallback if table doesn't exist
        try {
            $rlStmt = $pdo->prepare("SELECT id, title, description, media_url, thumbnail_url FROM featured_reels WHERE user_id = ? LIMIT 10");
            $rlStmt->execute([$targetId]);
            $profile['reels'] = $rlStmt->fetchAll(PDO::FETCH_ASSOC);
        } catch (PDOException $e) { $profile['reels'] = []; }

        // Record profile view — deduplicated per viewer+profile per calendar day
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

                    // Notify owner once per day per viewer
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
            } catch (PDOException $e) { /* profile_views not critical */ }
        }

        echo json_encode(["status" => "success", "data" => $profile]);
    } 

    elseif ($action === 'create_post') {
        $category    = $_POST['category'] ?? 'Other';
        $title       = $_POST['title']    ?? '';
        $description = $_POST['description'] ?? '';
        $mediaType   = $_POST['media_type']  ?? 'image';
        
        // Sanitize user name for folder naming
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

    elseif ($action === 'delete_post') {
        $postId = $_POST['post_id'] ?? '';
        if (!$postId) {
            echo json_encode(["status" => "error", "message" => "Missing post_id"]);
            exit();
        }

        // Fetch post to verify ownership and get media URL
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

        // Delete physical file if exists
        if ($post['media_url']) {
            $parsedUrl = parse_url($post['media_url']);
            $path = $parsedUrl['path'];
            // Convert URL path to local physical path
            $scriptDir = dirname($_SERVER['PHP_SELF']);
            $relativePath = str_replace($scriptDir, '', $path);
            $localPath = __DIR__ . $relativePath;
            
            if (file_exists($localPath)) {
                unlink($localPath);
            }
        }

        // Delete from DB
        $pdo->prepare("DELETE FROM feed_posts WHERE id = ?")->execute([$postId]);
        // Also delete likes and comments related to this post
        $pdo->prepare("DELETE FROM feed_likes WHERE post_id = ?")->execute([$postId]);
        $pdo->prepare("DELETE FROM feed_comments WHERE post_id = ?")->execute([$postId]);

        echo json_encode(["status" => "success", "message" => "Post deleted"]);
    }

    else {
        http_response_code(400);
        echo json_encode(["status" => "error", "message" => "Invalid action: $action"]);
    }

} catch (PDOException $e) {
    http_response_code(500);
    echo json_encode(["status" => "error", "message" => "DB error: " . $e->getMessage()]);
}
?>
