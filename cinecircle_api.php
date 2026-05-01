<?php

require_once __DIR__ . '/../config.php';

date_default_timezone_set('Asia/Kolkata');

// Enable PDO exceptions
$pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
$pdo->exec("SET time_zone = '+05:30'");

// Headers
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type");
header("Content-Type: application/json; charset=UTF-8");

// Handle OPTIONS
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

// Secure UUID generator
function generate_uuid_v4() {
    $data = random_bytes(16);
    $data[6] = chr((ord($data[6]) & 0x0f) | 0x40);
    $data[8] = chr((ord($data[8]) & 0x3f) | 0x80);
    return vsprintf('%s%s-%s-%s-%s-%s%s%s', str_split(bin2hex($data), 4));
}

// Get action
$action = $_POST['action'] ?? '';

if ($action === 'signup') {

    $fullName = trim($_POST['full_name'] ?? '');
    $mobile = trim($_POST['mobile_number'] ?? '');
    $passwordRaw = $_POST['password'] ?? '';
    $accountType = $_POST['account_type'] ?? 'Public';

    // Validate inputs
    if (!$fullName || !$mobile || !$passwordRaw) {
        http_response_code(400);
        echo json_encode(["status" => "error", "message" => "All fields are required."]);
        exit();
    }

    if (!preg_match('/^[0-9]{10,15}$/', $mobile)) {
        http_response_code(400);
        echo json_encode(["status" => "error", "message" => "Invalid mobile number."]);
        exit();
    }

    $validAccountTypes = ['Public', 'Professional', 'Company'];
    if (!in_array($accountType, $validAccountTypes, true)) {
        $accountType = 'Public';
    }

    try {
        // Check duplicate
        $stmt = $pdo->prepare("SELECT id FROM cinecircle WHERE mobile_number = ? LIMIT 1");
        $stmt->execute([$mobile]);

        if ($stmt->fetch()) {
            http_response_code(409);
            echo json_encode(["status" => "error", "message" => "Mobile already registered."]);
            exit();
        }

        // Generate ID + hash
        $id = generate_uuid_v4();
        $passwordHashed = password_hash($passwordRaw, PASSWORD_BCRYPT);

        // Insert
        $insertStmt = $pdo->prepare("
            INSERT INTO cinecircle 
            (id, mobile_number, full_name, password, account_type) 
            VALUES (?, ?, ?, ?, ?)
        ");

        $insertStmt->execute([
            $id,
            $mobile,
            $fullName,
            $passwordHashed,
            $accountType
        ]);

        http_response_code(201);
        echo json_encode([
            "status" => "success",
            "message" => "Account created successfully",
            "user_id" => $id
        ]);

    } catch (PDOException $e) {

        if ($e->errorInfo[1] == 1062) {
            http_response_code(409);
            echo json_encode(["status" => "error", "message" => "Mobile already registered."]);
        } else {
            http_response_code(500);
            echo json_encode([
                "status" => "error",
                "message" => "Server error"
            ]);
        }
    }

} elseif ($action === 'login') {

    $mobile = trim($_POST['mobile_number'] ?? '');
    $passwordRaw = $_POST['password'] ?? '';

    if (!$mobile || !$passwordRaw) {
        http_response_code(400);
        echo json_encode(["status" => "error", "message" => "Mobile number and password are required."]);
        exit();
    }

    try {
        $stmt = $pdo->prepare("SELECT id, mobile_number, full_name, password, account_type, profile_image_url FROM cinecircle WHERE mobile_number = ? LIMIT 1");
        $stmt->execute([$mobile]);
        $user = $stmt->fetch(PDO::FETCH_ASSOC);

        if ($user && password_verify($passwordRaw, $user['password'])) {
            http_response_code(200);
            echo json_encode([
                "status" => "success",
                "message" => "Login successful",
                "user" => [
                    "id" => $user['id'],
                    "full_name" => $user['full_name'],
                    "mobile_number" => $user['mobile_number'],
                    "account_type" => $user['account_type'],
                    "profile_image_url" => $user['profile_image_url'] ?? ''
                ]
            ]);
        } else {
            http_response_code(401);
            echo json_encode(["status" => "error", "message" => "Invalid mobile number or password."]);
        }
    } catch (PDOException $e) {
        http_response_code(500);
        echo json_encode(["status" => "error", "message" => "Server error"]);
    }

} elseif ($action === 'reset_password') {

    $mobile = trim($_POST['mobile_number'] ?? '');
    $newPassword = $_POST['new_password'] ?? '';

    if (!$mobile || !$newPassword) {
        http_response_code(400);
        echo json_encode(["status" => "error", "message" => "Mobile number and new password are required."]);
        exit();
    }

    if (!preg_match('/^[0-9]{10,15}$/', $mobile)) {
        http_response_code(400);
        echo json_encode(["status" => "error", "message" => "Invalid mobile number."]);
        exit();
    }

    try {
        $stmt = $pdo->prepare("SELECT id FROM cinecircle WHERE mobile_number = ? LIMIT 1");
        $stmt->execute([$mobile]);
        $userId = $stmt->fetchColumn();

        if (!$userId) {
            http_response_code(404);
            echo json_encode(["status" => "error", "message" => "User not found"]);
            exit();
        }

        $passwordHashed = password_hash($newPassword, PASSWORD_BCRYPT);
        $update = $pdo->prepare("UPDATE cinecircle SET password = ? WHERE mobile_number = ?");
        $update->execute([$passwordHashed, $mobile]);

        echo json_encode(["status" => "success", "message" => "Password reset successful"]);
    } catch (PDOException $e) {
        http_response_code(500);
        echo json_encode(["status" => "error", "message" => "Server error"]);
    }

} elseif ($action === 'update_profile') {
    $mobile = $_POST['mobile_number'] ?? '';
    $fullName = $_POST['full_name'] ?? '';
    $roleTitle = $_POST['role_title'] ?? '';
    $city = $_POST['city'] ?? '';
    $bio = $_POST['bio'] ?? '';

    if (!$mobile) {
        http_response_code(400);
        echo json_encode(["status" => "error", "message" => "Mobile number required."]);
        exit();
    }

    try {
        $stmt = $pdo->prepare("UPDATE cinecircle SET full_name = ?, role_title = ?, city = ?, bio = ? WHERE mobile_number = ?");
        $stmt->execute([$fullName, $roleTitle, $city, $bio, $mobile]);

        echo json_encode(["status" => "success", "message" => "Profile updated"]);
    } catch (PDOException $e) {
        http_response_code(500);
        echo json_encode(["status" => "error", "message" => "Server error"]);
    }

} elseif ($action === 'add_skill') {
    $mobile = $_POST['mobile_number'] ?? '';
    $skillName = $_POST['skill_name'] ?? '';

    if (!$mobile || !$skillName) {
        http_response_code(400);
        echo json_encode(["status" => "error", "message" => "Missing data."]);
        exit();
    }
    
    try {
        $stmt = $pdo->prepare("SELECT id FROM cinecircle WHERE mobile_number = ?");
        $stmt->execute([$mobile]);
        $userId = $stmt->fetchColumn();

        if ($userId) {
            $ins = $pdo->prepare("INSERT INTO user_skills (user_id, skill_name) VALUES (?, ?)");
            $ins->execute([$userId, $skillName]);
            echo json_encode(["status" => "success", "message" => "Added skill"]);
        } else {
            http_response_code(404);
            echo json_encode(["status" => "error", "message" => "User not found"]);
        }
    } catch (PDOException $e) {
        http_response_code(500);
        echo json_encode(["status" => "error", "message" => "Server error"]);
    }

} elseif ($action === 'add_credit') {
    $mobile = $_POST['mobile_number'] ?? '';
    $projectTitle = $_POST['project_title'] ?? '';
    $role = $_POST['role'] ?? '';
    $year = $_POST['year'] ?? '';

    if (!$mobile || !$projectTitle || !$role) {
        http_response_code(400);
        echo json_encode(["status" => "error", "message" => "Missing data."]);
        exit();
    }

    try {
        $stmt = $pdo->prepare("SELECT id FROM cinecircle WHERE mobile_number = ?");
        $stmt->execute([$mobile]);
        $userId = $stmt->fetchColumn();

        if ($userId) {
            $ins = $pdo->prepare("INSERT INTO user_credits (user_id, project_title, role, year) VALUES (?, ?, ?, ?)");
            $ins->execute([$userId, $projectTitle, $role, $year ?: null]);
            echo json_encode(["status" => "success", "message" => "Added credit"]);
        } else {
            http_response_code(404);
            echo json_encode(["status" => "error", "message" => "User not found"]);
        }
    } catch (PDOException $e) {
        http_response_code(500);
        echo json_encode(["status" => "error", "message" => "Server error"]);
    }

} elseif ($action === 'add_reel') {
    $mobile = $_POST['mobile_number'] ?? '';
    $title = $_POST['title'] ?? '';
    $mediaUrl = $_POST['media_url'] ?? '';
    $desc = $_POST['description'] ?? '';

    if (!$mobile || !$mediaUrl) {
        http_response_code(400);
        echo json_encode(["status" => "error", "message" => "Missing data."]);
        exit();
    }

    try {
        $stmt = $pdo->prepare("SELECT id FROM cinecircle WHERE mobile_number = ?");
        $stmt->execute([$mobile]);
        $userId = $stmt->fetchColumn();

        if ($userId) {
            $ins = $pdo->prepare("INSERT INTO user_portfolio (user_id, media_url, title, description) VALUES (?, ?, ?, ?)");
            $ins->execute([$userId, $mediaUrl, $title, $desc]);
            echo json_encode(["status" => "success", "message" => "Added reel"]);
        } else {
            http_response_code(404);
            echo json_encode(["status" => "error", "message" => "User not found"]);
        }
    } catch (PDOException $e) {
        http_response_code(500);
        echo json_encode(["status" => "error", "message" => "Server error"]);
    }

} elseif ($action === 'get_profile') {
    $mobile = $_POST['mobile_number'] ?? '';

    if (!$mobile) {
        http_response_code(400);
        echo json_encode(["status" => "error", "message" => "Mobile number required."]);
        exit();
    }

    try {
        $stmt = $pdo->prepare("SELECT id, full_name, mobile_number, account_type, bio, city, role_title, profile_image_url FROM cinecircle WHERE mobile_number = ?");
        $stmt->execute([$mobile]);
        $user = $stmt->fetch(PDO::FETCH_ASSOC);

        if ($user) {
            $userId = $user['id'];
            
            $stmtSkills = $pdo->prepare("SELECT skill_name FROM user_skills WHERE user_id = ?");
            $stmtSkills->execute([$userId]);
            $skills = $stmtSkills->fetchAll(PDO::FETCH_ASSOC);
            
            $stmtCredits = $pdo->prepare("SELECT project_title, role, year FROM user_credits WHERE user_id = ?");
            $stmtCredits->execute([$userId]);
            $credits = $stmtCredits->fetchAll(PDO::FETCH_ASSOC);

            $stmtReels = $pdo->prepare("SELECT title, media_url, description FROM user_portfolio WHERE user_id = ?");
            $stmtReels->execute([$userId]);
            $reels = $stmtReels->fetchAll(PDO::FETCH_ASSOC);

            echo json_encode([
                "status" => "success",
                "profile" => $user,
                "skills" => $skills,
                "credits" => $credits,
                "reels" => $reels
            ]);
        } else {
            http_response_code(404);
            echo json_encode(["status" => "error", "message" => "User not found"]);
        }
    } catch (PDOException $e) {
        http_response_code(500);
        echo json_encode(["status" => "error", "message" => "Server error"]);
    }

} elseif ($action === 'upload_profile_image') {
    $mobile = $_POST['mobile_number'] ?? '';
    if (!$mobile || !isset($_FILES['image'])) {
        http_response_code(400);
        echo json_encode(["status" => "error", "message" => "Missing data or image"]);
        exit();
    }

    $target_dir = "cinecircle_profile/";
    if (!file_exists($target_dir)) mkdir($target_dir, 0777, true);

    $file_ext = strtolower(pathinfo($_FILES["image"]["name"], PATHINFO_EXTENSION));
    $file_name = uniqid("profile_") . "." . $file_ext;
    $target_file = $target_dir . $file_name;

    if (move_uploaded_file($_FILES["image"]["tmp_name"], $target_file)) {
        $full_url = "https://team.cropsync.in/cine_circle/" . $target_file;
        $stmt = $pdo->prepare("UPDATE cinecircle SET profile_image_url = ? WHERE mobile_number = ?");
        $stmt->execute([$full_url, $mobile]);
        
        echo json_encode(["status" => "success", "url" => $full_url]);
    } else {
        http_response_code(500);
        echo json_encode(["status" => "error", "message" => "Failed to upload file"]);
    }

} elseif ($action === 'upload_featured_reel') {
    $mobile = $_POST['mobile_number'] ?? '';
    $title = $_POST['title'] ?? '';
    $desc = $_POST['description'] ?? '';

    if (!$mobile || !isset($_FILES['media'])) {
        http_response_code(400);
        echo json_encode(["status" => "error", "message" => "Missing data or media"]);
        exit();
    }

    $target_dir = "cinecircle_featuredreel/";
    if (!file_exists($target_dir)) mkdir($target_dir, 0777, true);

    $file_ext = strtolower(pathinfo($_FILES["media"]["name"], PATHINFO_EXTENSION));
    $file_name = uniqid("reel_") . "." . $file_ext;
    $target_file = $target_dir . $file_name;

    if (move_uploaded_file($_FILES["media"]["tmp_name"], $target_file)) {
        $full_url = "https://team.cropsync.in/cine_circle/" . $target_file;
        
        $stmt = $pdo->prepare("SELECT id FROM cinecircle WHERE mobile_number = ?");
        $stmt->execute([$mobile]);
        $userId = $stmt->fetchColumn();

        if ($userId) {
            $ins = $pdo->prepare("INSERT INTO user_portfolio (user_id, media_url, title, description) VALUES (?, ?, ?, ?)");
            $ins->execute([$userId, $full_url, $title, $desc]);
            echo json_encode(["status" => "success", "url" => $full_url]);
        } else {
            http_response_code(404);
            echo json_encode(["status" => "error", "message" => "User not found"]);
        }
    } else {
        http_response_code(500);
        echo json_encode(["status" => "error", "message" => "Failed to upload file"]);
    }

} else {
    http_response_code(400);
    echo json_encode(["status" => "error", "message" => "Invalid action"]);
}
?>