<?php

require_once __DIR__ . '/../config.php';

date_default_timezone_set('Asia/Kolkata');

$pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
$pdo->exec("SET NAMES utf8mb4");
$pdo->exec("SET time_zone = '+05:30'");

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

        echo json_encode(["status" => "success", "data" => $comments], JSON_UNESCAPED_UNICODE);
    }
    elseif ($action === 'get_post') {
        $postId = $_GET['post_id'] ?? '';
        if (!$postId) {
            http_response_code(400);
            echo json_encode(["status" => "error", "message" => "post_id required"]);
            exit();
        }

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
            WHERE p.id = ?
            LIMIT 1
        ");
        $stmt->execute([$userId, $userId, $postId]);
        $post = $stmt->fetch(PDO::FETCH_ASSOC);

        if (!$post) {
            http_response_code(404);
            echo json_encode(["status" => "error", "message" => "Post not found"]);
            exit();
        }

        echo json_encode(["status" => "success", "data" => $post], JSON_UNESCAPED_UNICODE);
    }
    elseif ($action === 'save_post') {
        $postId = $_POST['post_id'] ?? '';
        if (!$postId) {
            http_response_code(400);
            echo json_encode(["status" => "error", "message" => "post_id required"]);
            exit();
        }

        // Check if already saved
        $checkStmt = $pdo->prepare("SELECT 1 FROM feed_saves WHERE user_id = ? AND post_id = ?");
        $checkStmt->execute([$userId, $postId]);

        if ($checkStmt->fetchColumn()) {
            // Unsave
            $delStmt = $pdo->prepare("DELETE FROM feed_saves WHERE user_id = ? AND post_id = ?");
            $delStmt->execute([$userId, $postId]);
            echo json_encode(["status" => "success", "message" => "Post unsaved", "is_saved" => false]);
        } else {
            // Save
            $insStmt = $pdo->prepare("INSERT INTO feed_saves (user_id, post_id) VALUES (?, ?)");
            $insStmt->execute([$userId, $postId]);
            echo json_encode(["status" => "success", "message" => "Post saved", "is_saved" => true]);
        }
    }
    elseif ($action === 'view_post') {
        $postId = $_POST['post_id'] ?? '';
        if (!$postId) {
            http_response_code(400);
            echo json_encode(["status" => "error", "message" => "post_id required"]);
            exit();
        }

        // Only record unique views (one per user per post)
        $checkStmt = $pdo->prepare("SELECT 1 FROM feed_views WHERE user_id = ? AND post_id = ?");
        $checkStmt->execute([$userId, $postId]);

        if (!$checkStmt->fetchColumn()) {
            $insStmt = $pdo->prepare("INSERT INTO feed_views (user_id, post_id) VALUES (?, ?)");
            $insStmt->execute([$userId, $postId]);
        }

        // Return current view count
        $countStmt = $pdo->prepare("SELECT COUNT(*) FROM feed_views WHERE post_id = ?");
        $countStmt->execute([$postId]);
        $viewCount = (int)$countStmt->fetchColumn();

        echo json_encode(["status" => "success", "views_count" => $viewCount]);
    }
    elseif ($action === 'get_post_viewers') {
        $postId = $_GET['post_id'] ?? '';
        if (!$postId) {
            http_response_code(400);
            echo json_encode(["status" => "error", "message" => "post_id required"]);
            exit();
        }

        $stmt = $pdo->prepare("
            SELECT u.id, u.full_name, u.profile_image_url, u.city
            FROM feed_views v
            JOIN cinecircle u ON v.user_id = u.id
            WHERE v.post_id = ?
            ORDER BY v.viewed_at DESC
        ");
        $stmt->execute([$postId]);
        $viewers = $stmt->fetchAll(PDO::FETCH_ASSOC);

        echo json_encode(["status" => "success", "data" => $viewers]);
    }
    elseif ($action === 'get_post_likes') {
        $postId = $_GET['post_id'] ?? '';
        if (!$postId) {
            http_response_code(400);
            echo json_encode(["status" => "error", "message" => "post_id required"]);
            exit();
        }

        $stmt = $pdo->prepare("
            SELECT u.id, u.full_name, u.profile_image_url, u.city
            FROM feed_likes l
            JOIN cinecircle u ON l.user_id = u.id
            WHERE l.post_id = ?
            ORDER BY u.full_name ASC
        ");
        $stmt->execute([$postId]);
        $likes = $stmt->fetchAll(PDO::FETCH_ASSOC);

        echo json_encode(["status" => "success", "data" => $likes]);
    }
    elseif ($action === 'report_post') {
        $postId = $_POST['post_id'] ?? '';
        $reason = $_POST['reason'] ?? 'Inappropriate content';

        if (!$postId) {
            http_response_code(400);
            echo json_encode(["status" => "error", "message" => "post_id required"]);
            exit();
        }

        // Whitelist allowed reasons
        $allowedReasons = [
            'Inappropriate content',
            'Spam or misleading',
            'Harassment or bullying',
            'Fake profile or impersonation',
            'Violence or dangerous content',
            'Other',
        ];
        if (!in_array($reason, $allowedReasons)) {
            $reason = 'Inappropriate content';
        }

        // Check if already reported
        $chkStmt = $pdo->prepare("SELECT id FROM feed_reports WHERE post_id = ? AND user_id = ? LIMIT 1");
        $chkStmt->execute([$postId, $userId]);
        if ($chkStmt->fetch()) {
            echo json_encode(["status" => "already_reported", "message" => "You have already reported this post."]);
            exit();
        }

        // Insert (IGNORE handles any race-condition duplicates)
        $insStmt = $pdo->prepare(
            "INSERT IGNORE INTO feed_reports (post_id, user_id, reason) VALUES (?, ?, ?)"
        );
        $insStmt->execute([$postId, $userId, $reason]);

        echo json_encode(["status" => "success", "message" => "Report submitted. Thank you for keeping CineCircle safe."]);
    }
    elseif ($action === 'check_report') {
        // Check whether the current user has already reported a post
        $postId = $_GET['post_id'] ?? '';
        if (!$postId) {
            echo json_encode(["status" => "error", "message" => "post_id required"]);
            exit();
        }
        $chkStmt = $pdo->prepare("SELECT id FROM feed_reports WHERE post_id = ? AND user_id = ? LIMIT 1");
        $chkStmt->execute([$postId, $userId]);
        $reported = (bool)$chkStmt->fetch();
        echo json_encode(["status" => "success", "already_reported" => $reported]);
    }
    elseif ($action === 'search') {
        $query = trim($_GET['query'] ?? '');
        if (!$query) {
            echo json_encode(["status" => "success", "users" => [], "posts" => []]);
            exit();
        }

        $searchQuery = "%$query%";

        // 1. Search Users
        $userStmt = $pdo->prepare("
            SELECT id, full_name, profile_image_url, role_title, city,
            EXISTS(SELECT 1 FROM user_follows WHERE follower_id = ? AND following_id = cinecircle.id) as is_following
            FROM cinecircle
            WHERE (full_name LIKE ? OR role_title LIKE ? OR city LIKE ?)
            AND id != ?
            LIMIT 10
        ");
        $userStmt->execute([$userId, $searchQuery, $searchQuery, $searchQuery, $userId]);
        $users = $userStmt->fetchAll(PDO::FETCH_ASSOC);

        // 2. Search Posts
        $postStmt = $pdo->prepare("
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
            WHERE (p.title LIKE ? OR p.description LIKE ? OR p.category LIKE ?)
            ORDER BY p.created_at DESC
            LIMIT 20
        ");
        $postStmt->execute([$userId, $userId, $searchQuery, $searchQuery, $searchQuery]);
        $posts = $postStmt->fetchAll(PDO::FETCH_ASSOC);

        echo json_encode(["status" => "success", "users" => $users, "posts" => $posts], JSON_UNESCAPED_UNICODE);
    }
    elseif ($action === 'get_new_users') {
        // Get users that the current user is not following
        $stmt = $pdo->prepare("
            SELECT id, full_name, profile_image_url, role_title, city, 0 as is_following
            FROM cinecircle
            WHERE id != ?
            AND id NOT IN (SELECT following_id FROM user_follows WHERE follower_id = ?)
            ORDER BY created_at DESC
            LIMIT 15
        ");
        $stmt->execute([$userId, $userId]);
        $newUsers = $stmt->fetchAll(PDO::FETCH_ASSOC);

        echo json_encode(["status" => "success", "data" => $newUsers], JSON_UNESCAPED_UNICODE);
    }
    elseif ($action === 'get_saved_posts') {
        $stmt = $pdo->prepare("
            SELECT 
                p.id, p.user_id, p.category, p.title, p.description,
                p.media_url, p.media_type, p.created_at,
                u.full_name as author_name, u.role_title, u.profile_image_url,
                (SELECT COUNT(*) FROM feed_likes WHERE post_id = p.id) as likes_count,
                (SELECT COUNT(*) FROM feed_comments WHERE post_id = p.id) as comments_count,
                (SELECT COUNT(*) FROM feed_views WHERE post_id = p.id) as views_count,
                EXISTS(SELECT 1 FROM feed_likes WHERE post_id = p.id AND user_id = ?) as is_liked,
                1 as is_saved
            FROM feed_saves s
            JOIN feed_posts p ON s.post_id = p.id
            JOIN cinecircle u ON p.user_id = u.id
            WHERE s.user_id = ?
            ORDER BY p.created_at DESC
        ");
        $stmt->execute([$userId, $userId]);
        $savedPosts = $stmt->fetchAll(PDO::FETCH_ASSOC);

        echo json_encode(["status" => "success", "data" => $savedPosts], JSON_UNESCAPED_UNICODE);
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
