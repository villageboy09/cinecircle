<?php

require_once __DIR__ . '/../config.php';

// Enable PDO exceptions
$pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);

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

if (!$mobile) {
    http_response_code(400);
    echo json_encode(["status" => "error", "message" => "Mobile number required."]);
    exit();
}

try {
    // 1. Get logged-in user details for Nearby queries
    $userStmt = $pdo->prepare("SELECT id, city FROM cinecircle WHERE mobile_number = ? LIMIT 1");
    $userStmt->execute([$mobile]);
    $user = $userStmt->fetch(PDO::FETCH_ASSOC);

    if (!$user) {
        http_response_code(404);
        echo json_encode(["status" => "error", "message" => "User not found"]);
        exit();
    }

    $userId = $user['id'];
    $userCity = $user['city'] ?? '';

    // 2. Fetch Feed Posts
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
            u.full_name as author_name, 
            u.role_title, 
            u.profile_image_url,
            (SELECT COUNT(*) FROM feed_likes WHERE post_id = p.id) as likes_count,
            (SELECT COUNT(*) FROM feed_comments WHERE post_id = p.id) as comments_count,
            (SELECT COUNT(*) FROM feed_views WHERE post_id = p.id) as views_count,
            EXISTS(SELECT 1 FROM feed_likes WHERE post_id = p.id AND user_id = ?) as is_liked,
            EXISTS(SELECT 1 FROM feed_saves WHERE post_id = p.id AND user_id = ?) as is_saved
        FROM feed_posts p
        JOIN cinecircle u ON p.user_id = u.id
        ORDER BY p.created_at DESC
        LIMIT 50
    ");
    $postsStmt->execute([$userId, $userId]);
    $posts = $postsStmt->fetchAll(PDO::FETCH_ASSOC);

    // 3. Fetch Trending Talent (Exclude self + check is_following)
    $trendingStmt = $pdo->prepare("
        SELECT id, full_name, role_title, city, profile_image_url,
               EXISTS(SELECT 1 FROM user_follows WHERE follower_id = ? AND following_id = cinecircle.id) as is_following
        FROM cinecircle 
        WHERE id != ?
        ORDER BY RAND() 
        LIMIT 5
    ");
    $trendingStmt->execute([$userId, $userId]);
    $trending = $trendingStmt->fetchAll(PDO::FETCH_ASSOC);

    // 4. Fetch Nearby Creators (Check is_following)
    $nearbyStmt = $pdo->prepare("
        SELECT id, full_name, role_title, city, profile_image_url,
               EXISTS(SELECT 1 FROM user_follows WHERE follower_id = ? AND following_id = cinecircle.id) as is_following
        FROM cinecircle 
        WHERE city = ? AND id != ?
        LIMIT 4
    ");
    $nearbyStmt->execute([$userId, $userCity, $userId]);
    $nearby = $nearbyStmt->fetchAll(PDO::FETCH_ASSOC);

    // Convert is_following to boolean
    foreach ($trending as &$t) $t['is_following'] = (bool)$t['is_following'];
    foreach ($nearby as &$n) $n['is_following'] = (bool)$n['is_following'];

    echo json_encode([
        "status" => "success",
        "data" => [
            "current_user_id" => $userId,
            "posts" => $posts,
            "trending" => $trending,
            "nearby" => $nearby
        ]
    ]);

} catch (PDOException $e) {
    http_response_code(500);
    echo json_encode(["status" => "error", "message" => "Database error: " . $e->getMessage()]);
}

?>
