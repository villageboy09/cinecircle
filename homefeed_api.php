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
            EXISTS(SELECT 1 FROM feed_likes WHERE post_id = p.id AND user_id = ?) as is_liked
        FROM feed_posts p
        JOIN cinecircle u ON p.user_id = u.id
        ORDER BY p.created_at DESC
        LIMIT 50
    ");
    $postsStmt->execute([$userId]);
    $posts = $postsStmt->fetchAll(PDO::FETCH_ASSOC);

    // 3. Fetch Trending Talent (Placeholder randomized)
    $trendingStmt = $pdo->prepare("
        SELECT id, full_name, role_title, city, profile_image_url 
        FROM cinecircle 
        ORDER BY RAND() 
        LIMIT 5
    ");
    $trendingStmt->execute();
    $trending = $trendingStmt->fetchAll(PDO::FETCH_ASSOC);

    // 4. Fetch Nearby Creators
    $nearbyStmt = $pdo->prepare("
        SELECT id, full_name, role_title, city, profile_image_url 
        FROM cinecircle 
        WHERE city = ? AND id != ?
        LIMIT 4
    ");
    $nearbyStmt->execute([$userCity, $userId]);
    $nearby = $nearbyStmt->fetchAll(PDO::FETCH_ASSOC);

    echo json_encode([
        "status" => "success",
        "data" => [
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
