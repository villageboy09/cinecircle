<?php

require_once __DIR__ . '/../config.php';

date_default_timezone_set('Asia/Kolkata');

// Enable PDO exceptions
$pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
$pdo->exec("SET time_zone = '+05:30'");

// Headers
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type");
header("Content-Type: application/json; charset=UTF-8");

// Handle OPTIONS
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

$mobile = $_GET['mobile_number'] ?? '';
$cursor = $_GET['cursor'] ?? '';        // ISO timestamp of last seen post (for pagination)
$limit  = max(1, min(30, (int)($_GET['limit'] ?? 15)));

if (!$mobile) {
    http_response_code(400);
    echo json_encode(["status" => "error", "message" => "Mobile number required."]);
    exit();
}

try {
    // 1. Get logged-in user details
    $userStmt = $pdo->prepare("SELECT id, city FROM cinecircle WHERE mobile_number = ? LIMIT 1");
    $userStmt->execute([$mobile]);
    $user = $userStmt->fetch(PDO::FETCH_ASSOC);

    if (!$user) {
        http_response_code(404);
        echo json_encode(["status" => "error", "message" => "User not found"]);
        exit();
    }

    $userId   = $user['id'];
    $userCity = $user['city'] ?? '';

    // ── 2. Cursor-based feed posts ──────────────────────────
    // We use created_at < cursor for "older than" semantics.
    // First page has no cursor. Subsequent pages pass the created_at of the last item.
    if (!empty($cursor)) {
        // Decode the cursor (base64 encoded ISO timestamp)
        $cursorTs = base64_decode($cursor);
        $postsStmt = $pdo->prepare("
            SELECT
                p.id,
                p.user_id,
                p.category,
                p.title,
                p.description,
                p.media_url,
                p.media_type,
                p.created_at,
                u.full_name  AS author_name,
                u.role_title,
                u.profile_image_url,
                (SELECT COUNT(*) FROM feed_likes    WHERE post_id = p.id) AS likes_count,
                (SELECT COUNT(*) FROM feed_comments WHERE post_id = p.id) AS comments_count,
                (SELECT COUNT(*) FROM feed_views    WHERE post_id = p.id) AS views_count,
                EXISTS(SELECT 1 FROM feed_likes WHERE post_id = p.id AND user_id = ?)  AS is_liked,
                EXISTS(SELECT 1 FROM feed_saves WHERE post_id = p.id AND user_id = ?)  AS is_saved,
                EXISTS(SELECT 1 FROM feed_stories WHERE user_id = p.user_id AND created_at > NOW() - INTERVAL 24 HOUR) AS has_stories,
                EXISTS(
                    SELECT 1 FROM feed_stories s 
                    WHERE s.user_id = p.user_id 
                    AND s.created_at > NOW() - INTERVAL 24 HOUR 
                    AND NOT EXISTS(SELECT 1 FROM story_views WHERE story_id = s.id AND user_id = ?)
                ) AS has_unviewed_stories
            FROM feed_posts p
            JOIN cinecircle u ON p.user_id = u.id
            WHERE p.created_at < ?
            ORDER BY p.created_at DESC
            LIMIT ?
        ");
        $postsStmt->execute([$userId, $userId, $userId, $cursorTs, $limit]);
    } else {
        $postsStmt = $pdo->prepare("
            SELECT
                p.id,
                p.user_id,
                p.category,
                p.title,
                p.description,
                p.media_url,
                p.media_type,
                p.created_at,
                u.full_name  AS author_name,
                u.role_title,
                u.profile_image_url,
                (SELECT COUNT(*) FROM feed_likes    WHERE post_id = p.id) AS likes_count,
                (SELECT COUNT(*) FROM feed_comments WHERE post_id = p.id) AS comments_count,
                (SELECT COUNT(*) FROM feed_views    WHERE post_id = p.id) AS views_count,
                EXISTS(SELECT 1 FROM feed_likes WHERE post_id = p.id AND user_id = ?)  AS is_liked,
                EXISTS(SELECT 1 FROM feed_saves WHERE post_id = p.id AND user_id = ?)  AS is_saved,
                EXISTS(SELECT 1 FROM feed_stories WHERE user_id = p.user_id AND created_at > NOW() - INTERVAL 24 HOUR) AS has_stories,
                EXISTS(
                    SELECT 1 FROM feed_stories s 
                    WHERE s.user_id = p.user_id 
                    AND s.created_at > NOW() - INTERVAL 24 HOUR 
                    AND NOT EXISTS(SELECT 1 FROM story_views WHERE story_id = s.id AND user_id = ?)
                ) AS has_unviewed_stories
            FROM feed_posts p
            JOIN cinecircle u ON p.user_id = u.id
            ORDER BY p.created_at DESC
            LIMIT ?
        ");
        $postsStmt->execute([$userId, $userId, $userId, $limit]);
    }

    $posts = $postsStmt->fetchAll(PDO::FETCH_ASSOC);

    // Cast boolean fields
    foreach ($posts as &$p) {
        $p['is_liked'] = (bool)$p['is_liked'];
        $p['is_saved'] = (bool)$p['is_saved'];
    }
    unset($p);

    // Build next_cursor from the last post's created_at
    $nextCursor = null;
    $hasMore    = false;
    if (count($posts) === $limit) {
        $lastPost   = end($posts);
        $hasMore    = true;
        $nextCursor = base64_encode($lastPost['created_at']);
    }

    // ── 3. Trending Talent ──────────────────────────────────
    // Deterministic trending score: follower_count * 2 + post_count
    // Only return on first page (no cursor) to avoid duplication mid-scroll
    $trending = [];
    if (empty($cursor)) {
        $trendingStmt = $pdo->prepare("
            SELECT
                u.id,
                u.full_name,
                u.role_title,
                u.city,
                u.profile_image_url,
                (SELECT COUNT(*) FROM user_follows WHERE following_id = u.id) AS follower_count,
                (SELECT COUNT(*) FROM feed_posts   WHERE user_id      = u.id) AS post_count,
                EXISTS(SELECT 1 FROM user_follows WHERE follower_id = ? AND following_id = u.id) AS is_following
            FROM cinecircle u
            WHERE u.id != ?
            ORDER BY (follower_count * 2 + post_count) DESC
            LIMIT 8
        ");
        $trendingStmt->execute([$userId, $userId]);
        $trending = $trendingStmt->fetchAll(PDO::FETCH_ASSOC);
        foreach ($trending as &$t) {
            $t['is_following']   = (intval($t['is_following']) === 1);
            $t['follower_count'] = (int)$t['follower_count'];
            $t['post_count']     = (int)$t['post_count'];
        }
        unset($t);
    }

    // ── 4. Nearby Creators ─────────────────────────────────
    $nearby = [];
    if (empty($cursor) && !empty($userCity)) {
        $nearbyStmt = $pdo->prepare("
            SELECT
                u.id,
                u.full_name,
                u.role_title,
                u.city,
                u.profile_image_url,
                EXISTS(SELECT 1 FROM user_follows WHERE follower_id = ? AND following_id = u.id) AS is_following
            FROM cinecircle u
            WHERE u.city = ? AND u.id != ?
            LIMIT 4
        ");
        $nearbyStmt->execute([$userId, $userCity, $userId]);
        $nearby = $nearbyStmt->fetchAll(PDO::FETCH_ASSOC);
        foreach ($nearby as &$n) $n['is_following'] = (intval($n['is_following']) === 1);
        unset($n);
    }

    echo json_encode([
        "status"      => "success",
        "data"        => [
            "current_user_id" => $userId,
            "current_user_has_stories" => (bool)$pdo->query("SELECT EXISTS(SELECT 1 FROM feed_stories WHERE user_id = '$userId' AND created_at > NOW() - INTERVAL 24 HOUR)")->fetchColumn(),
            "current_user_has_unviewed" => (bool)$pdo->query("
                SELECT EXISTS(
                    SELECT 1 FROM feed_stories s 
                    WHERE s.user_id = '$userId' 
                    AND s.created_at > NOW() - INTERVAL 24 HOUR 
                    AND NOT EXISTS(SELECT 1 FROM story_views WHERE story_id = s.id AND user_id = '$userId')
                )
            ")->fetchColumn(),
            "posts"           => $posts,
            "trending"        => $trending,
            "nearby"          => $nearby,
            "next_cursor"     => $nextCursor,
            "has_more"        => $hasMore,
        ]
    ]);

} catch (PDOException $e) {
    http_response_code(500);
    echo json_encode(["status" => "error", "message" => "Database error: " . $e->getMessage()]);
}

?>
