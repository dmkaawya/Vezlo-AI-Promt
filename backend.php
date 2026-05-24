<?php
/**
 * Vezlo AI Prompt — PHP Backend API Template
 * 
 * Endpoints:
 *   GET    /api/prompts          — List prompts (with search, filter, sort, pagination)
 *   GET    /api/prompts/{id}     — Get single prompt detail
 *   POST   /api/prompts          — Create new prompt
 *   POST   /api/prompts/{id}/copy  — Increment copy count
 *   POST   /api/prompts/{id}/view  — Increment view count
 *   POST   /api/prompts/{id}/fav   — Toggle favorite
 *   POST   /api/prompts/{id}/report — Submit report
 *   POST   /api/contact          — Submit contact message
 */

header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(204);
    exit;
}

// ---- Database connection (update with your credentials) ----
 $host = 'localhost';
 $db   = 'vezlo_ai_prompt';
 $user = 'root';
 $pass = '';
 $charset = 'utf8mb4';

 $dsn = "mysql:host=$host;dbname=$db;charset=$charset";
 $options = [
    PDO::ATTR_ERRMODE            => PDO::ERRMODE_EXCEPTION,
    PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
    PDO::ATTR_EMULATE_PREPARES   => false,
];

try {
    $pdo = new PDO($dsn, $user, $pass, $options);
} catch (PDOException $e) {
    http_response_code(500);
    echo json_encode(['error' => 'Database connection failed']);
    exit;
}

// ---- Simple router ----
 $uri = parse_url($_SERVER['REQUEST_URI'], PHP_URL_PATH);
 $uri = str_replace('/api', '', $uri);
 $method = $_SERVER['REQUEST_METHOD'];
 $parts = array_values(array_filter(explode('/', $uri)));

// GET /prompts
if ($method === 'GET' && count($parts) === 1 && $parts[0] === 'prompts') {
    $category = $_GET['category'] ?? 'all';
    $search   = $_GET['search'] ?? '';
    $sort     = $_GET['sort'] ?? 'newest';
    $page     = max(1, intval($_GET['page'] ?? 1));
    $limit    = min(50, max(1, intval($_GET['limit'] ?? 12)));
    $offset   = ($page - 1) * $limit;

    $where = ["p.status = 'approved'"];
    $params = [];

    if ($category !== 'all') {
        $where[] = "c.name = ?";
        $params[] = $category;
    }
    if ($search) {
        $where[] = "(MATCH(p.title, p.caption, p.prompt_text) AGAINST(? IN BOOLEAN MODE) OR p.title LIKE ?)";
        $params[] = $search;
        $params[] = "%$search%";
    }

    $whereSQL = implode(' AND ', $where);

    $orderBy = match($sort) {
        'copied'    => 'p.copy_count DESC',
        'favorited' => 'p.avg_rating DESC, p.view_count DESC',
        default     => 'p.created_at DESC'
    };

    $countSQL = "SELECT COUNT(*) FROM prompts p JOIN categories c ON p.category_id = c.id WHERE $whereSQL";
    $stmt = $pdo->prepare($countSQL);
    $stmt->execute($params);
    $total = $stmt->fetchColumn();

    $dataSQL = "SELECT p.*, c.name AS category
                FROM prompts p
                JOIN categories c ON p.category_id = c.id
                WHERE $whereSQL
                ORDER BY $orderBy
                LIMIT $limit OFFSET $offset";
    $stmt = $pdo->prepare($dataSQL);
    $stmt->execute($params);
    $prompts = $stmt->fetchAll();

    echo json_encode(['total' => $total, 'page' => $page, 'data' => $prompts]);
    exit;
}

// GET /prompts/{id}
if ($method === 'GET' && count($parts) === 2 && $parts[0] === 'prompts' && is_numeric($parts[1])) {
    $id = intval($parts[1]);
    $stmt = $pdo->prepare("SELECT p.*, c.name AS category FROM prompts p JOIN categories c ON p.category_id = c.id WHERE p.id = ?");
    $stmt->execute([$id]);
    $prompt = $stmt->fetch();

    if (!$prompt) {
        http_response_code(404);
        echo json_encode(['error' => 'Prompt not found']);
        exit;
    }

    // Get images
    $imgStmt = $pdo->prepare("SELECT image_url FROM prompt_images WHERE prompt_id = ? ORDER BY sort_order");
    $imgStmt->execute([$id]);
    $prompt['images'] = array_column($imgStmt->fetchAll(), 'image_url');

    // Get tags
    $tagStmt = $pdo->prepare("SELECT t.name FROM tags t JOIN prompt_tags pt ON t.id = pt.tag_id WHERE pt.prompt_id = ?");
    $tagStmt->execute([$id]);
    $prompt['tags'] = array_column($tagStmt->fetchAll(), 'name');

    echo json_encode($prompt);
    exit;
}

// POST /prompts — Create new prompt
if ($method === 'POST' && count($parts) === 1 && $parts[0] === 'prompts') {
    $data = json_decode(file_get_contents('php://input'), true);

    $required = ['title', 'prompt_text', 'category_id', 'display_name', 'email'];
    foreach ($required as $field) {
        if (empty($data[$field])) {
            http_response_code(400);
            echo json_encode(['error' => "Missing required field: $field"]);
            exit;
        }
    }

    $stmt = $pdo->prepare("INSERT INTO prompts (title, caption, prompt_text, category_id, is_original, status) VALUES (?, ?, ?, ?, ?, 'pending')");
    $
