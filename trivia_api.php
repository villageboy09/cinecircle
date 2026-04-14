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
    $userStmt = $pdo->prepare("SELECT id, last_login_reward_date FROM cinecircle WHERE mobile_number = ? LIMIT 1");
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

// Ensure credit ledger row exists for user
function ensureLedger(PDO $pdo, string $userId): void {
    $pdo->prepare("INSERT IGNORE INTO user_credits_ledger (id, user_id, balance, total_earned, total_spent) VALUES (?, ?, 0, 0, 0)")
        ->execute([generateUUID(), $userId]);
}

// Add credits helper
function awardCredits(PDO $pdo, string $userId, int $amount, string $source, string $title): void {
    ensureLedger($pdo, $userId);
    $pdo->prepare("UPDATE user_credits_ledger SET balance = balance + ?, total_earned = total_earned + ? WHERE user_id = ?")
        ->execute([$amount, $amount, $userId]);
    $pdo->prepare("INSERT INTO user_credits_history (id, user_id, type, source, title, amount) VALUES (?, ?, 'earn', ?, ?, ?)")
        ->execute([generateUUID(), $userId, $source, $title, $amount]);
}

try {

    // ─────────────────────────────────────────────────────
    // ACTION: daily_login_reward
    // ─────────────────────────────────────────────────────
    if ($action === 'daily_login_reward') {
        $today = date('Y-m-d');
        $lastReward = $userRow['last_login_reward_date'];

        if ($lastReward === $today) {
            echo json_encode(["status" => "already_rewarded", "message" => "Already rewarded today"]);
            exit();
        }

        awardCredits($pdo, $userId, 5, 'daily_login', 'Daily Login Bonus');
        $pdo->prepare("UPDATE cinecircle SET last_login_reward_date = ? WHERE id = ?")
            ->execute([$today, $userId]);

        echo json_encode(["status" => "success", "credits_awarded" => 5]);
    }

    // ─────────────────────────────────────────────────────
    // ACTION: get_credits
    // ─────────────────────────────────────────────────────
    elseif ($action === 'get_credits') {
        ensureLedger($pdo, $userId);

        $ledger = $pdo->prepare("SELECT balance, total_earned, total_spent FROM user_credits_ledger WHERE user_id = ?");
        $ledger->execute([$userId]);
        $ledgerRow = $ledger->fetch(PDO::FETCH_ASSOC);

        // Recent history (last 10)
        $hist = $pdo->prepare("SELECT type, source, title, amount, created_at FROM user_credits_history WHERE user_id = ? ORDER BY created_at DESC LIMIT 10");
        $hist->execute([$userId]);
        $history = $hist->fetchAll(PDO::FETCH_ASSOC);

        echo json_encode([
            "status" => "success",
            "data" => [
                "balance"      => (int)($ledgerRow['balance'] ?? 0),
                "total_earned" => (int)($ledgerRow['total_earned'] ?? 0),
                "total_spent"  => (int)($ledgerRow['total_spent'] ?? 0),
                "history"      => $history,
            ]
        ]);
    }

    // ─────────────────────────────────────────────────────
    // ACTION: get_categories
    // ─────────────────────────────────────────────────────
    elseif ($action === 'get_categories') {
        $stmt = $pdo->prepare("SELECT id, name, icon_name, image_url, credits_reward FROM trivia_categories WHERE is_active = 1 ORDER BY id ASC");
        $stmt->execute();
        $categories = $stmt->fetchAll(PDO::FETCH_ASSOC);

        echo json_encode(["status" => "success", "data" => $categories]);
    }

    // ─────────────────────────────────────────────────────
    // ACTION: get_challenges
    // ─────────────────────────────────────────────────────
    elseif ($action === 'get_challenges') {
        // Fetch daily challenge first (is_daily = 1, valid_date = today or null)
        $today = date('Y-m-d');
        $stmt = $pdo->prepare("
            SELECT c.id, c.title, c.description, c.image_url, c.credits_reward, c.is_daily, c.valid_date,
                   cat.name AS category_name,
                   EXISTS(
                       SELECT 1 FROM user_trivia_attempts a
                       WHERE a.user_id = ? AND a.challenge_id = c.id AND DATE(a.attempted_at) = CURDATE() AND a.completed = 1
                   ) AS already_completed
            FROM trivia_challenges c
            LEFT JOIN trivia_categories cat ON c.category_id = cat.id
            WHERE c.is_active = 1 AND (c.valid_date IS NULL OR c.valid_date = ?)
            ORDER BY c.is_daily DESC, c.id ASC
        ");
        $stmt->execute([$userId, $today]);
        $challenges = $stmt->fetchAll(PDO::FETCH_ASSOC);

        echo json_encode(["status" => "success", "data" => $challenges]);
    }

    // ─────────────────────────────────────────────────────
    // ACTION: get_challenge_questions
    // ─────────────────────────────────────────────────────
    elseif ($action === 'get_challenge_questions') {
        $challengeId = $_GET['challenge_id'] ?? '';
        if (!$challengeId) {
            http_response_code(400);
            echo json_encode(["status" => "error", "message" => "challenge_id required"]);
            exit();
        }

        // Check if already completed today
        $checkStmt = $pdo->prepare("
            SELECT id FROM user_trivia_attempts
            WHERE user_id = ? AND challenge_id = ? AND DATE(attempted_at) = CURDATE() AND completed = 1
        ");
        $checkStmt->execute([$userId, $challengeId]);
        if ($checkStmt->fetch()) {
            echo json_encode(["status" => "already_completed", "message" => "Already completed today"]);
            exit();
        }

        $qStmt = $pdo->prepare("
            SELECT q.id, q.question_text, q.image_url,
                   q.option_a, q.option_b, q.option_c, q.option_d,
                   cq.sort_order
            FROM trivia_challenge_questions cq
            JOIN trivia_questions q ON cq.question_id = q.id
            WHERE cq.challenge_id = ?
            ORDER BY cq.sort_order ASC
        ");
        $qStmt->execute([$challengeId]);
        $questions = $qStmt->fetchAll(PDO::FETCH_ASSOC);

        // Fetch challenge meta
        $metaStmt = $pdo->prepare("SELECT title, credits_reward FROM trivia_challenges WHERE id = ?");
        $metaStmt->execute([$challengeId]);
        $meta = $metaStmt->fetch(PDO::FETCH_ASSOC);

        echo json_encode([
            "status"    => "success",
            "meta"      => $meta,
            "questions" => $questions,
        ]);
    }

    // ─────────────────────────────────────────────────────
    // ACTION: submit_answers
    // ─────────────────────────────────────────────────────
    elseif ($action === 'submit_answers') {
        $challengeId = $_POST['challenge_id'] ?? '';
        $answersRaw  = $_POST['answers'] ?? '{}';  // JSON: {"question_id": "A", ...}

        if (!$challengeId) {
            http_response_code(400);
            echo json_encode(["status" => "error", "message" => "challenge_id required"]);
            exit();
        }

        // Prevent duplicate completion today
        $checkStmt = $pdo->prepare("
            SELECT id FROM user_trivia_attempts
            WHERE user_id = ? AND challenge_id = ? AND DATE(attempted_at) = CURDATE() AND completed = 1
        ");
        $checkStmt->execute([$userId, $challengeId]);
        if ($checkStmt->fetch()) {
            echo json_encode(["status" => "already_completed", "credits_earned" => 0]);
            exit();
        }

        $answers = json_decode($answersRaw, true) ?? [];

        // Fetch correct answers for this challenge
        $corrStmt = $pdo->prepare("
            SELECT q.id, q.correct_option
            FROM trivia_challenge_questions cq
            JOIN trivia_questions q ON cq.question_id = q.id
            WHERE cq.challenge_id = ?
        ");
        $corrStmt->execute([$challengeId]);
        $correctAnswers = $corrStmt->fetchAll(PDO::FETCH_KEY_PAIR); // [id => correct_option]

        $totalQuestions = count($correctAnswers);
        $score = 0;
        foreach ($correctAnswers as $qId => $correct) {
            if (isset($answers[$qId]) && strtoupper($answers[$qId]) === $correct) {
                $score++;
            }
        }

        // Fetch challenge credits
        $metaStmt = $pdo->prepare("SELECT credits_reward, title FROM trivia_challenges WHERE id = ?");
        $metaStmt->execute([$challengeId]);
        $meta = $metaStmt->fetch(PDO::FETCH_ASSOC);
        $maxCredits = (int)($meta['credits_reward'] ?? 0);

        // Pro-rate credits based on score
        $creditsEarned = ($totalQuestions > 0) ? (int)round(($score / $totalQuestions) * $maxCredits) : 0;

        // Record attempt
        $attemptId = generateUUID();
        $pdo->prepare("
            INSERT INTO user_trivia_attempts (id, user_id, challenge_id, score, total_questions, credits_earned, completed)
            VALUES (?, ?, ?, ?, ?, ?, 1)
        ")->execute([$attemptId, $userId, $challengeId, $score, $totalQuestions, $creditsEarned]);

        // Award credits
        if ($creditsEarned > 0) {
            awardCredits($pdo, $userId, $creditsEarned, 'quiz_win', 'Quiz Win: ' . ($meta['title'] ?? 'Trivia'));
        }

        echo json_encode([
            "status"          => "success",
            "score"           => $score,
            "total_questions" => $totalQuestions,
            "credits_earned"  => $creditsEarned,
        ]);
    }

    // ─────────────────────────────────────────────────────
    // ACTION: get_reward_items
    // ─────────────────────────────────────────────────────
    elseif ($action === 'get_reward_items') {
        $tab = $_GET['tab'] ?? 'Merchandise';
        // Also include stock_quantity so Flutter can show 'Out of stock'
        $stmt = $pdo->prepare("
            SELECT id, title, description, image_url, icon_name, category,
                   credits_cost, stock_quantity, stock_label, is_available
            FROM reward_items
            WHERE is_available = 1 AND category = ?
            ORDER BY credits_cost ASC
        ");
        $stmt->execute([$tab]);
        $items = $stmt->fetchAll(PDO::FETCH_ASSOC);

        // Attach user balance
        ensureLedger($pdo, $userId);
        $ledger = $pdo->prepare("SELECT balance FROM user_credits_ledger WHERE user_id = ?");
        $ledger->execute([$userId]);
        $balance = (int)($ledger->fetchColumn() ?? 0);

        echo json_encode(["status" => "success", "balance" => $balance, "data" => $items]);
    }

    // ─────────────────────────────────────────────────────
    // ACTION: redeem_item
    // ─────────────────────────────────────────────────────
    elseif ($action === 'redeem_item') {
        $itemId = $_POST['item_id'] ?? '';
        if (!$itemId) {
            http_response_code(400);
            echo json_encode(["status" => "error", "message" => "item_id required"]);
            exit();
        }

        // Wrap entire flow in a DB transaction for atomicity
        $pdo->beginTransaction();

        try {
            // Fetch item with a write-lock to prevent race conditions on limited stock
            $itemStmt = $pdo->prepare("
                SELECT id, title, credits_cost, is_available, stock_quantity
                FROM reward_items WHERE id = ? FOR UPDATE
            ");
            $itemStmt->execute([$itemId]);
            $item = $itemStmt->fetch(PDO::FETCH_ASSOC);

            if (!$item || !$item['is_available']) {
                $pdo->rollBack();
                http_response_code(404);
                echo json_encode(["status" => "error", "message" => "Item not found or unavailable"]);
                exit();
            }

            // Check stock (NULL = unlimited)
            if ($item['stock_quantity'] !== null && (int)$item['stock_quantity'] <= 0) {
                $pdo->rollBack();
                echo json_encode(["status" => "out_of_stock", "message" => "This item is out of stock"]);
                exit();
            }

            $cost = (int)$item['credits_cost'];

            // Check user balance
            ensureLedger($pdo, $userId);
            $ledger = $pdo->prepare("SELECT balance FROM user_credits_ledger WHERE user_id = ? FOR UPDATE");
            $ledger->execute([$userId]);
            $balance = (int)$ledger->fetchColumn();

            if ($balance < $cost) {
                $pdo->rollBack();
                echo json_encode(["status" => "insufficient_credits", "message" => "Not enough credits", "balance" => $balance, "required" => $cost]);
                exit();
            }

            // Deduct credits from ledger
            $pdo->prepare("UPDATE user_credits_ledger SET balance = balance - ?, total_spent = total_spent + ? WHERE user_id = ?")
                ->execute([$cost, $cost, $userId]);

            // Decrement stock if finite
            if ($item['stock_quantity'] !== null) {
                $pdo->prepare("UPDATE reward_items SET stock_quantity = stock_quantity - 1 WHERE id = ?")
                    ->execute([$itemId]);
                // Auto-mark unavailable if stock hits 0
                $pdo->prepare("UPDATE reward_items SET is_available = 0 WHERE id = ? AND stock_quantity <= 0")
                    ->execute([$itemId]);
            }

            // Record credits history
            $pdo->prepare("INSERT INTO user_credits_history (id, user_id, type, source, title, amount) VALUES (?, ?, 'spend', 'redemption', ?, ?)")
                ->execute([generateUUID(), $userId, 'Redeemed: ' . $item['title'], -$cost]);

            // Record redemption with status = 'Pending'
            $redemptionId = generateUUID();
            $pdo->prepare("INSERT INTO user_redemptions (id, user_id, item_id, credits_spent, status) VALUES (?, ?, ?, ?, 'Pending')")
                ->execute([$redemptionId, $userId, $itemId, $cost]);

            $pdo->commit();

            echo json_encode([
                "status"         => "success",
                "message"        => "Redeemed successfully!",
                "new_balance"    => $balance - $cost,
                "redemption_id"  => $redemptionId,
            ]);

        } catch (Exception $inner) {
            $pdo->rollBack();
            throw $inner; // Re-throw to outer catch
        }
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
