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
    $userStmt = $pdo->prepare("SELECT id, full_name FROM cinecircle WHERE mobile_number = ? LIMIT 1");
    $userStmt->execute([$mobile]);
    $me = $userStmt->fetch(PDO::FETCH_ASSOC);

    if (!$me) {
        http_response_code(404);
        echo json_encode(["status" => "error", "message" => "User not found"]);
        exit();
    }
    $userId = $me['id'];

    if ($action === 'upload_story') {
        $mediaType = $_POST['media_type'] ?? 'image';
        $caption = $_POST['caption'] ?? '';

        $userNameSanitized = preg_replace('/[^A-Za-z0-9_\-]/', '_', $me['full_name'] ?? 'User');
        $uploadSubDir = 'uploads/stories/' . $userNameSanitized . '/';
        $uploadFullPath = __DIR__ . '/' . $uploadSubDir;
        
        if (!is_dir($uploadFullPath)) {
            mkdir($uploadFullPath, 0777, true);
        }

        $mediaUrl = '';
        if (isset($_FILES['media']) && $_FILES['media']['error'] === UPLOAD_ERR_OK) {
            $ext = strtolower(pathinfo($_FILES['media']['name'], PATHINFO_EXTENSION));
            $fileName = sprintf('%04x%04x-%04x', mt_rand(0, 0xffff), mt_rand(0, 0xffff), mt_rand(0, 0xffff)) . '.' . $ext;
            
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

        if (!$mediaUrl) {
            http_response_code(400);
            echo json_encode(["status" => "error", "message" => "Media file required"]);
            exit();
        }

        $id = sprintf('%04x%04x-%04x-%04x-%04x-%04x%04x%04x',
            mt_rand(0, 0xffff), mt_rand(0, 0xffff),
            mt_rand(0, 0xffff),
            mt_rand(0, 0x0fff) | 0x4000,
            mt_rand(0, 0x3fff) | 0x8000,
            mt_rand(0, 0xffff), mt_rand(0, 0xffff), mt_rand(0, 0xffff)
        );

        $stmt = $pdo->prepare("INSERT INTO feed_stories (id, user_id, media_url, media_type, caption) VALUES (?, ?, ?, ?, ?)");
        $stmt->execute([$id, $userId, $mediaUrl, $mediaType, $caption]);

        echo json_encode(["status" => "success", "message" => "Story uploaded", "story_id" => $id]);
    }
    elseif ($action === 'get_active_stories') {
        // Fetch users who have active stories (within last 24h)
        // Group by user to show them in the stories bar
        $stmt = $pdo->prepare("
            SELECT DISTINCT u.id as user_id, u.full_name, u.profile_image_url
            FROM feed_stories s
            JOIN cinecircle u ON s.user_id = u.id
            WHERE s.created_at > NOW() - INTERVAL 24 HOUR
            ORDER BY s.created_at DESC
        ");
        $stmt->execute();
        $users = $stmt->fetchAll(PDO::FETCH_ASSOC);

        // For each user, fetch their stories
        foreach ($users as &$user) {
            $storyStmt = $pdo->prepare("
                SELECT id, media_url, media_type, caption, created_at,
                EXISTS(SELECT 1 FROM story_views WHERE story_id = s.id AND user_id = ?) as is_viewed
                FROM feed_stories s
                WHERE user_id = ? AND created_at > NOW() - INTERVAL 24 HOUR
                ORDER BY created_at ASC
            ");
            $storyStmt->execute([$userId, $user['user_id']]);
            $user['stories'] = $storyStmt->fetchAll(PDO::FETCH_ASSOC);
            
            // Check if user has any unviewed stories
            $user['has_unviewed'] = false;
            foreach ($user['stories'] as $story) {
                if (!$story['is_viewed']) {
                    $user['has_unviewed'] = true;
                    break;
                }
            }
        }

        echo json_encode(["status" => "success", "data" => $users], JSON_UNESCAPED_UNICODE);
    }
    elseif ($action === 'mark_story_viewed') {
        $storyId = $_POST['story_id'] ?? '';
        if (!$storyId) {
            http_response_code(400);
            echo json_encode(["status" => "error", "message" => "story_id required"]);
            exit();
        }

        $stmt = $pdo->prepare("INSERT IGNORE INTO story_views (story_id, user_id) VALUES (?, ?)");
        $stmt->execute([$storyId, $userId]);

        echo json_encode(["status" => "success", "message" => "Story marked as viewed"]);
    }
    elseif ($action === 'react_to_story') {
        $storyId = $_POST['story_id'] ?? '';
        $emoji = $_POST['emoji'] ?? '';

        if (!$storyId || !$emoji) {
            http_response_code(400);
            echo json_encode(["status" => "error", "message" => "story_id and emoji required"]);
            exit();
        }

        $id = sprintf('%04x%04x-%04x-%04x-%04x-%04x%04x%04x',
            mt_rand(0, 0xffff), mt_rand(0, 0xffff),
            mt_rand(0, 0xffff),
            mt_rand(0, 0x0fff) | 0x4000,
            mt_rand(0, 0x3fff) | 0x8000,
            mt_rand(0, 0xffff), mt_rand(0, 0xffff), mt_rand(0, 0xffff)
        );

        $stmt = $pdo->prepare("INSERT INTO story_reactions (id, story_id, user_id, emoji) VALUES (?, ?, ?, ?) ON DUPLICATE KEY UPDATE emoji = ?");
        $stmt->execute([$id, $storyId, $userId, $emoji, $emoji]);

        echo json_encode(["status" => "success", "message" => "Reaction sent"]);
    }
    elseif ($action === 'get_story_viewers') {
        $storyId = $_GET['story_id'] ?? '';
        if (!$storyId) {
            http_response_code(400);
            echo json_encode(["status" => "error", "message" => "story_id required"]);
            exit();
        }

        // Check if I am the owner of the story
        $ownerStmt = $pdo->prepare("SELECT user_id FROM feed_stories WHERE id = ?");
        $ownerStmt->execute([$storyId]);
        $ownerId = $ownerStmt->fetchColumn();

        if ($ownerId != $userId) {
            http_response_code(403);
            echo json_encode(["status" => "error", "message" => "Only the owner can see the viewer list"]);
            exit();
        }

        $stmt = $pdo->prepare("
            SELECT u.id, u.full_name, u.profile_image_url, v.viewed_at,
                   (SELECT emoji FROM story_reactions WHERE story_id = v.story_id AND user_id = v.user_id LIMIT 1) as reaction_emoji
            FROM story_views v
            JOIN cinecircle u ON v.user_id = u.id
            WHERE v.story_id = ?
            ORDER BY v.viewed_at DESC
        ");
        $stmt->execute([$storyId]);
        $viewers = $stmt->fetchAll(PDO::FETCH_ASSOC);

        echo json_encode(["status" => "success", "data" => $viewers], JSON_UNESCAPED_UNICODE);
    }
    elseif ($action === 'get_user_stories') {
        $targetUserId = $_GET['user_id'] ?? '';
        if (!$targetUserId) {
            http_response_code(400);
            echo json_encode(["status" => "error", "message" => "user_id required"]);
            exit();
        }

        $stmt = $pdo->prepare("
            SELECT u.id as user_id, u.full_name, u.profile_image_url
            FROM cinecircle u
            WHERE u.id = ?
            LIMIT 1
        ");
        $stmt->execute([$targetUserId]);
        $user = $stmt->fetch(PDO::FETCH_ASSOC);

        if (!$user) {
            http_response_code(404);
            echo json_encode(["status" => "error", "message" => "User not found"]);
            exit();
        }

        $storyStmt = $pdo->prepare("
            SELECT id, media_url, media_type, caption, created_at,
            EXISTS(SELECT 1 FROM story_views WHERE story_id = s.id AND user_id = ?) as is_viewed
            FROM feed_stories s
            WHERE user_id = ? AND created_at > NOW() - INTERVAL 24 HOUR
            ORDER BY created_at ASC
        ");
        $storyStmt->execute([$userId, $targetUserId]);
        $user['stories'] = $storyStmt->fetchAll(PDO::FETCH_ASSOC);

        echo json_encode(["status" => "success", "data" => $user], JSON_UNESCAPED_UNICODE);
    }
    else {
        http_response_code(400);
        echo json_encode(["status" => "error", "message" => "Invalid action"]);
    }

} catch (PDOException $e) {
    http_response_code(500);
    echo json_encode(["status" => "error", "message" => "Database error: " . $e->getMessage()]);
}
