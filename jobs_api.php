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

// Authenticate user
try {
    $userStmt = $pdo->prepare("SELECT id FROM cinecircle WHERE mobile_number = ? LIMIT 1");
    $userStmt->execute([$mobile]);
    $userRow = $userStmt->fetch(PDO::FETCH_ASSOC);

    if (!$userRow) {
        http_response_code(404);
        echo json_encode(["status" => "error", "message" => "User not found"]);
        exit();
    }

    $userId = $userRow['id'];

} catch (PDOException $e) {
    http_response_code(500);
    echo json_encode(["status" => "error", "message" => "DB error: " . $e->getMessage()]);
    exit();
}

// UUID helper
function generateUUID(): string {
    return sprintf('%04x%04x-%04x-%04x-%04x-%04x%04x%04x',
        mt_rand(0, 0xffff), mt_rand(0, 0xffff),
        mt_rand(0, 0xffff),
        mt_rand(0, 0x0fff) | 0x4000,
        mt_rand(0, 0x3fff) | 0x8000,
        mt_rand(0, 0xffff), mt_rand(0, 0xffff), mt_rand(0, 0xffff)
    );
}

// Format time ago helper
function timeAgo(string $timestamp): string {
    $now  = new DateTime();
    $past = new DateTime($timestamp);
    $diff = $now->diff($past);
    if ($diff->d > 0) return $diff->d . 'd ago';
    if ($diff->h > 0) return $diff->h . 'h ago';
    if ($diff->i > 0) return $diff->i . 'm ago';
    return 'Just now';
}

try {

    // ─────────────────────────────────────────────────────
    // ACTION: get_casting_jobs
    // ─────────────────────────────────────────────────────
    if ($action === 'get_casting_jobs') {
        $jobType  = $_GET['job_type'] ?? '';   // 'Casting', 'Crew', 'Services', 'Remote' — empty = All
        $search   = trim($_GET['search'] ?? '');

        // $params starts empty — WHERE clause adds filter params only.
        // array_unshift prepends exactly 2 $userId values for the two
        // EXISTS subqueries in the SELECT clause.
        $params = [];
        $where  = ['jp.is_active = 1'];

        if (!empty($jobType)) {
            $where[]  = 'jp.job_type = ?';
            $params[] = $jobType;
        }
        if (!empty($search)) {
            $where[]  = '(jp.title LIKE ? OR jp.company LIKE ? OR jp.location LIKE ?)';
            $params[] = "%$search%";
            $params[] = "%$search%";
            $params[] = "%$search%";
        }

        $whereClause = implode(' AND ', $where);

        $stmt = $pdo->prepare("
            SELECT
                jp.id, jp.title, jp.company, jp.location,
                jp.job_type, jp.pay_type, jp.pay_amount,
                jp.image_url, jp.is_urgent, jp.deadline, jp.created_at,
                u.full_name AS poster_name, u.profile_image_url AS poster_avatar,
                EXISTS(SELECT 1 FROM job_saves s WHERE s.user_id = ? AND s.job_type = 'casting' AND s.job_id = jp.id) AS is_saved,
                EXISTS(SELECT 1 FROM job_applications a WHERE a.applicant_id = ? AND a.job_type = 'casting' AND a.job_id = jp.id) AS has_applied
            FROM job_posts jp
            JOIN cinecircle u ON jp.poster_user_id = u.id
            WHERE $whereClause
            ORDER BY jp.is_urgent DESC, jp.created_at DESC
            LIMIT 50
        ");

        // Prepend exactly 2 userId params for the 2 EXISTS subqueries
        array_unshift($params, $userId, $userId);
        $stmt->execute($params);
        $jobs = $stmt->fetchAll(PDO::FETCH_ASSOC);

        // Format time_ago and cast booleans
        foreach ($jobs as &$job) {
            $job['time_ago']    = timeAgo($job['created_at']);
            $job['is_saved']    = (bool)$job['is_saved'];
            $job['has_applied'] = (bool)$job['has_applied'];
            $job['is_urgent']   = (bool)$job['is_urgent'];
        }

        echo json_encode(["status" => "success", "data" => $jobs]);
    }

    // ─────────────────────────────────────────────────────
    // ACTION: get_daily_posts
    // ─────────────────────────────────────────────────────
    elseif ($action === 'get_daily_posts') {
        $roleType = $_GET['role_type'] ?? '';  // 'Lead', 'Supporting' etc — empty = All
        $search   = trim($_GET['search'] ?? '');

        $params = [$userId, $userId];
        $where  = ['dp.is_active = 1'];

        if (!empty($roleType)) {
            $where[]  = 'dp.role_type = ?';
            $params[] = $roleType;
        }
        if (!empty($search)) {
            $where[]  = '(dp.title LIKE ? OR dp.location LIKE ? OR dp.project_type LIKE ?)';
            $params[] = "%$search%";
            $params[] = "%$search%";
            $params[] = "%$search%";
        }

        $whereClause = implode(' AND ', $where);

        $stmt = $pdo->prepare("
            SELECT
                dp.id, dp.title, dp.role_type, dp.project_type,
                dp.shoot_date, dp.pay_per_day, dp.location,
                dp.description, dp.image_url, dp.is_urgent, dp.created_at,
                u.full_name AS poster_name, u.profile_image_url AS poster_avatar,
                EXISTS(SELECT 1 FROM job_saves s WHERE s.user_id = ? AND s.job_type = 'daily' AND s.job_id = dp.id) AS is_saved,
                EXISTS(SELECT 1 FROM job_applications a WHERE a.applicant_id = ? AND a.job_type = 'daily' AND a.job_id = dp.id) AS has_applied
            FROM daily_short_posts dp
            JOIN cinecircle u ON dp.poster_user_id = u.id
            WHERE $whereClause
            ORDER BY dp.is_urgent DESC, dp.created_at DESC
            LIMIT 50
        ");

        $stmt->execute($params);
        $posts = $stmt->fetchAll(PDO::FETCH_ASSOC);

        foreach ($posts as &$post) {
            $post['time_ago']   = timeAgo($post['created_at']);
            $post['is_saved']   = (bool)$post['is_saved'];
            $post['has_applied']= (bool)$post['has_applied'];
            $post['is_urgent']  = (bool)$post['is_urgent'];
        }

        echo json_encode(["status" => "success", "data" => $posts]);
    }

    // ─────────────────────────────────────────────────────
    // ACTION: get_job_detail
    // ─────────────────────────────────────────────────────
    elseif ($action === 'get_job_detail') {
        $jobId   = $_GET['job_id'] ?? '';
        $jobType = $_GET['job_type'] ?? 'casting'; // 'casting' | 'daily'

        if (!$jobId) {
            http_response_code(400);
            echo json_encode(["status" => "error", "message" => "job_id required"]);
            exit();
        }

        if ($jobType === 'casting') {
            $stmt = $pdo->prepare("
                SELECT jp.*,
                       u.full_name AS poster_name,
                       u.profile_image_url AS poster_avatar,
                       u.mobile_number AS poster_mobile,
                       EXISTS(SELECT 1 FROM job_saves s WHERE s.user_id = ? AND s.job_type = 'casting' AND s.job_id = jp.id) AS is_saved,
                       EXISTS(SELECT 1 FROM job_applications a WHERE a.applicant_id = ? AND a.job_type = 'casting' AND a.job_id = jp.id) AS has_applied
                FROM job_posts jp
                JOIN cinecircle u ON jp.poster_user_id = u.id
                WHERE jp.id = ?
            ");
            $stmt->execute([$userId, $userId, $jobId]);
        } else {
            $stmt = $pdo->prepare("
                SELECT dp.*,
                       u.full_name AS poster_name,
                       u.profile_image_url AS poster_avatar,
                       u.mobile_number AS poster_mobile,
                       EXISTS(SELECT 1 FROM job_saves s WHERE s.user_id = ? AND s.job_type = 'daily' AND s.job_id = dp.id) AS is_saved,
                       EXISTS(SELECT 1 FROM job_applications a WHERE a.applicant_id = ? AND a.job_type = 'daily' AND a.job_id = dp.id) AS has_applied
                FROM daily_short_posts dp
                JOIN cinecircle u ON dp.poster_user_id = u.id
                WHERE dp.id = ?
            ");
            $stmt->execute([$userId, $userId, $jobId]);
        }

        $job = $stmt->fetch(PDO::FETCH_ASSOC);

        if (!$job) {
            http_response_code(404);
            echo json_encode(["status" => "error", "message" => "Job not found"]);
            exit();
        }

        // Decode JSON columns for casting posts
        if ($jobType === 'casting') {
            $job['requirements']          = json_decode($job['requirements'] ?? '[]', true);
            $job['responsibilities']      = json_decode($job['responsibilities'] ?? '[]', true);
            $job['submission_materials']  = json_decode($job['submission_materials'] ?? '[]', true);
        }

        $job['time_ago']    = timeAgo($job['created_at']);
        $job['is_saved']    = (bool)$job['is_saved'];
        $job['has_applied'] = (bool)$job['has_applied'];
        $job['is_urgent']   = (bool)$job['is_urgent'];

        // Fetch applicant count
        $countStmt = $pdo->prepare("SELECT COUNT(*) FROM job_applications WHERE job_id = ? AND job_type = ?");
        $countStmt->execute([$jobId, $jobType]);
        $job['applicant_count'] = (int)$countStmt->fetchColumn();

        echo json_encode(["status" => "success", "data" => $job]);
    }

    // ─────────────────────────────────────────────────────
    // ACTION: apply_job
    // ─────────────────────────────────────────────────────
    elseif ($action === 'apply_job') {
        $jobId     = $_POST['job_id'] ?? '';
        $jobType   = $_POST['job_type'] ?? 'casting';
        $coverNote = $_POST['cover_note'] ?? '';

        if (!$jobId) {
            http_response_code(400);
            echo json_encode(["status" => "error", "message" => "job_id required"]);
            exit();
        }

        // Prevent duplicate application
        $checkStmt = $pdo->prepare("SELECT id FROM job_applications WHERE applicant_id = ? AND job_id = ? AND job_type = ?");
        $checkStmt->execute([$userId, $jobId, $jobType]);
        if ($checkStmt->fetch()) {
            echo json_encode(["status" => "already_applied", "message" => "You've already applied for this job"]);
            exit();
        }

        $pdo->prepare("INSERT INTO job_applications (id, applicant_id, job_type, job_id, cover_note) VALUES (?, ?, ?, ?, ?)")
            ->execute([generateUUID(), $userId, $jobType, $jobId, $coverNote]);

        echo json_encode(["status" => "success", "message" => "Application submitted!"]);
    }

    // ─────────────────────────────────────────────────────
    // ACTION: toggle_save_job
    // ─────────────────────────────────────────────────────
    elseif ($action === 'toggle_save_job') {
        $jobId   = $_POST['job_id'] ?? '';
        $jobType = $_POST['job_type'] ?? 'casting';

        if (!$jobId) {
            http_response_code(400);
            echo json_encode(["status" => "error", "message" => "job_id required"]);
            exit();
        }

        $checkStmt = $pdo->prepare("SELECT 1 FROM job_saves WHERE user_id = ? AND job_type = ? AND job_id = ?");
        $checkStmt->execute([$userId, $jobType, $jobId]);

        if ($checkStmt->fetchColumn()) {
            // Unsave
            $pdo->prepare("DELETE FROM job_saves WHERE user_id = ? AND job_type = ? AND job_id = ?")
                ->execute([$userId, $jobType, $jobId]);
            echo json_encode(["status" => "success", "is_saved" => false, "message" => "Job unsaved"]);
        } else {
            // Save
            $pdo->prepare("INSERT INTO job_saves (user_id, job_type, job_id) VALUES (?, ?, ?)")
                ->execute([$userId, $jobType, $jobId]);
            echo json_encode(["status" => "success", "is_saved" => true, "message" => "Job saved"]);
        }
    }

    // ─────────────────────────────────────────────────────
    // ACTION: get_my_applications
    // ─────────────────────────────────────────────────────
    elseif ($action === 'get_my_applications') {
        $stmt = $pdo->prepare("
            SELECT ja.id, ja.job_type, ja.job_id, ja.status, ja.applied_at,
                   COALESCE(jp.title, dp.title) AS title,
                   COALESCE(jp.company, dp.project_type) AS company,
                   COALESCE(jp.location, dp.location) AS location,
                   COALESCE(jp.image_url, dp.image_url) AS image_url
            FROM job_applications ja
            LEFT JOIN job_posts jp ON ja.job_type = 'casting' AND ja.job_id = jp.id
            LEFT JOIN daily_short_posts dp ON ja.job_type = 'daily' AND ja.job_id = dp.id
            WHERE ja.applicant_id = ?
            ORDER BY ja.applied_at DESC
        ");
        $stmt->execute([$userId]);
        $apps = $stmt->fetchAll(PDO::FETCH_ASSOC);

        foreach ($apps as &$app) {
            $app['time_ago'] = timeAgo($app['applied_at']);
        }

        echo json_encode(["status" => "success", "data" => $apps]);
    }

    else {
        http_response_code(400);
        echo json_encode(["status" => "error", "message" => "Invalid action"]);
    }

} catch (PDOException $e) {
    http_response_code(500);
    echo json_encode(["status" => "error", "message" => "DB error: " . $e->getMessage()]);
}

?>
