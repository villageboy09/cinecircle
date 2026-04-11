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

try {
    // Authenticate user
    $userStmt = $pdo->prepare("SELECT id FROM cinecircle WHERE mobile_number = ? LIMIT 1");
    $userStmt->execute([$mobile]);
    $userId = $userStmt->fetchColumn();

    if (!$userId) {
        http_response_code(404);
        echo json_encode(["status" => "error", "message" => "User not found"]);
        exit();
    }

    if ($action === 'like_post') {
        $postId = $_POST['post_id'] ?? '';
        if (!$postId) {
            http_response_code(400);
            echo json_encode(["status" => "error", "message" => "post_id required"]);
            exit();
        }

        // Check if already liked
        $checkStmt = $pdo->prepare("SELECT 1 FROM feed_likes WHERE user_id = ? AND post_id = ?");
        $checkStmt->execute([$userId, $postId]);
        
        if ($checkStmt->fetchColumn()) {
            // Unlike
            $delStmt = $pdo->prepare("DELETE FROM feed_likes WHERE user_id = ? AND post_id = ?");
            $delStmt->execute([$userId, $postId]);
            echo json_encode(["status" => "success", "message" => "Post unliked", "is_liked" => false]);
        } else {
            // Like
            $insStmt = $pdo->prepare("INSERT INTO feed_likes (user_id, post_id) VALUES (?, ?)");
            $insStmt->execute([$userId, $postId]);
            echo json_encode(["status" => "success", "message" => "Post liked", "is_liked" => true]);
        }
    } 
    elseif ($action === 'comment_post') {
        $postId = $_POST['post_id'] ?? '';
        $comment = $_POST['comment'] ?? '';
        
        if (!$postId || !$comment) {
            http_response_code(400);
            echo json_encode(["status" => "error", "message" => "post_id and comment required"]);
            exit();
        }

        $id = sprintf('%04x%04x-%04x-%04x-%04x-%04x%04x%04x',
            mt_rand(0, 0xffff), mt_rand(0, 0xffff),
            mt_rand(0, 0xffff),
            mt_rand(0, 0x0fff) | 0x4000,
            mt_rand(0, 0x3fff) | 0x8000,
            mt_rand(0, 0xffff), mt_rand(0, 0xffff), mt_rand(0, 0xffff)
        );

        $insStmt = $pdo->prepare("INSERT INTO feed_comments (id, post_id, user_id, comment) VALUES (?, ?, ?, ?)");
        $insStmt->execute([$id, $postId, $userId, $comment]);
        
        echo json_encode(["status" => "success", "message" => "Comment added"]);
    }
    elseif ($action === 'get_comments') {
        $postId = $_GET['post_id'] ?? '';
        if (!$postId) {
            http_response_code(400);
            echo json_encode(["status" => "error", "message" => "post_id required"]);
            exit();
        }

        $stmt = $pdo->prepare("
            SELECT c.id, c.comment, c.created_at, u.full_name, u.profile_image_url
            FROM feed_comments c
            JOIN cinecircle u ON c.user_id = u.id
            WHERE c.post_id = ?
            ORDER BY c.created_at ASC
        ");
        $stmt->execute([$postId]);
        $comments = $stmt->fetchAll(PDO::FETCH_ASSOC);

        echo json_encode(["status" => "success", "data" => $comments]);
    }
    else {
        http_response_code(400);
        echo json_encode(["status" => "error", "message" => "Invalid action"]);
    }

} catch (PDOException $e) {
    http_response_code(500);
    echo json_encode(["status" => "error", "message" => "Database error: " . $e->getMessage()]);
}

?>
