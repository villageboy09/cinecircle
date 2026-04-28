<?php
require_once __DIR__ . '/../config.php';
$pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST, GET, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type");
header("Content-Type: application/json; charset=UTF-8");
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') { http_response_code(200); exit(); }

$action = $_POST['action'] ?? ($_GET['action'] ?? '');
$mobile = $_POST['mobile_number'] ?? ($_GET['mobile_number'] ?? '');
if (!$action || !$mobile) {
    http_response_code(400);
    echo json_encode(["status"=>"error","message"=>"Missing action or mobile_number"]);
    exit();
}

try {
    $u = $pdo->prepare("SELECT id, full_name FROM cinecircle WHERE mobile_number=? LIMIT 1");
    $u->execute([$mobile]);
    $me = $u->fetch(PDO::FETCH_ASSOC);
    if (!$me) { http_response_code(404); echo json_encode(["status"=>"error","message"=>"User not found"]); exit(); }
    $myId = $me['id'];
} catch (PDOException $e) {
    http_response_code(500); echo json_encode(["status"=>"error","message"=>$e->getMessage()]); exit();
}

function genUUID(): string {
    return sprintf('%04x%04x-%04x-%04x-%04x-%04x%04x%04x',
        mt_rand(0,0xffff),mt_rand(0,0xffff),mt_rand(0,0xffff),
        mt_rand(0,0x0fff)|0x4000,mt_rand(0,0x3fff)|0x8000,
        mt_rand(0,0xffff),mt_rand(0,0xffff),mt_rand(0,0xffff));
}
function fmtDur(int $s): string {
    return intdiv($s,60).'m '.str_pad($s%60,2,'0',STR_PAD_LEFT).'s';
}
// Converts a relative path to a full URL.
// Videos:     uploads/videos/filename.mp4  → https://team.cropsync.in/cine_circle/uploads/videos/filename.mp4
// Images:     uploads/filename.webp        → https://team.cropsync.in/cine_circle/uploads/filename.webp
// Already-absolute URLs are returned unchanged.
function toAbsUrl(?string $path): string {
    if (!$path || $path === '') return '';
    if (str_starts_with($path, 'http://') || str_starts_with($path, 'https://')) return $path;
    return 'https://team.cropsync.in/cine_circle/' . ltrim($path, '/');
}

try {

// ── get_webseries_list ────────────────────────────────────
if ($action === 'get_webseries_list') {
    $page   = max(1,(int)($_GET['page']??1));
    $limit  = 20; $offset = ($page-1)*$limit;
    $status = $_GET['status'] ?? '';
    $type   = $_GET['type']   ?? '';
    $search = trim($_GET['search'] ?? '');
    $order  = $_GET['order']  ?? 'newest';

    $where = ['w.is_active=1']; $params = [$myId];
    if (in_array($status,['ONGOING','COMPLETED','UPCOMING'])) { $where[]='w.status=?'; $params[]=$status; }
    if (in_array($type,['SERIES','SHORT']))                   { $where[]='w.type=?';   $params[]=$type; }
    if ($search!=='') {
        $where[]='(w.title LIKE ? OR w.genre LIKE ? OR w.tags LIKE ?)';
        $lk='%'.$search.'%'; $params[]=$lk; $params[]=$lk; $params[]=$lk;
    }
    $wc = implode(' AND ',$where);
    $oc = $order==='most_watched' ? 'watch_count DESC,w.created_at DESC' : 'w.created_at DESC';
    $params[]=$limit; $params[]=$offset;

    $st = $pdo->prepare("
        SELECT w.id,w.title,w.description,w.genre,w.tags,w.status,w.type,
               w.cover_url,w.total_episodes,w.avg_duration_min,w.language,
               EXISTS(SELECT 1 FROM webseries_watchlist wl WHERE wl.user_id=? AND wl.series_id=w.id) AS is_saved,
               (SELECT COUNT(DISTINCT user_id) FROM webseries_watch_progress WHERE series_id=w.id) AS watch_count
        FROM webseries w WHERE $wc ORDER BY $oc LIMIT ? OFFSET ?");
    $st->execute($params);
    $rows=$st->fetchAll(PDO::FETCH_ASSOC);
    foreach($rows as &$r){
        $r['is_saved']=(bool)$r['is_saved'];
        $r['watch_count']=(int)$r['watch_count'];
        $r['total_episodes']=(int)$r['total_episodes'];
        $r['avg_duration_min']=(int)$r['avg_duration_min'];
        $r['cover_url']=toAbsUrl($r['cover_url']);
    }
    echo json_encode(["status"=>"success","data"=>$rows,"page"=>$page,"has_more"=>count($rows)===$limit]);
}

// ── get_webseries_detail ──────────────────────────────────
elseif ($action === 'get_webseries_detail') {
    $sid = $_GET['series_id'] ?? '';
    if (!$sid) { echo json_encode(["status"=>"error","message"=>"Missing series_id"]); exit(); }

    $st=$pdo->prepare("SELECT w.*,EXISTS(SELECT 1 FROM webseries_watchlist WHERE user_id=? AND series_id=w.id) AS is_saved FROM webseries w WHERE w.id=? AND w.is_active=1");
    $st->execute([$myId,$sid]);
    $series=$st->fetch(PDO::FETCH_ASSOC);
    if (!$series) { echo json_encode(["status"=>"error","message"=>"Series not found"]); exit(); }
    $series['is_saved']=(bool)$series['is_saved'];
    // Normalize all series-level URL fields
    foreach(['cover_url','banner_url','trailer_url'] as $f){
        $series[$f]=toAbsUrl($series[$f]??'');
    }

    $ep=$pdo->prepare("
        SELECT e.id,e.episode_number,e.title,e.description,e.thumbnail_url,e.video_url,
               e.duration_sec,e.is_premium,e.credits_cost,
               COALESCE(wp.watched_sec,0) AS watched_sec,
               COALESCE(wp.is_completed,0) AS is_completed,
               CASE WHEN e.duration_sec>0 THEN LEAST(100,ROUND(COALESCE(wp.watched_sec,0)/e.duration_sec*100)) ELSE 0 END AS progress_pct
        FROM webseries_episodes e
        LEFT JOIN webseries_watch_progress wp ON wp.episode_id=e.id AND wp.user_id=?
        WHERE e.series_id=? AND e.is_active=1 ORDER BY e.sort_order,e.episode_number");
    $ep->execute([$myId,$sid]);
    $episodes=$ep->fetchAll(PDO::FETCH_ASSOC);

    $ids=array_column($episodes,'id');
    $likeMap=[];
    if($ids){
        $ph=implode(',',array_fill(0,count($ids),'?'));
        $lk=$pdo->prepare("SELECT episode_id,COUNT(*) AS likes,SUM(CASE WHEN user_id=? THEN 1 ELSE 0 END) AS user_liked FROM webseries_reactions WHERE type='LIKE' AND episode_id IN($ph) GROUP BY episode_id");
        $lk->execute(array_merge([$myId],$ids));
        foreach($lk->fetchAll(PDO::FETCH_ASSOC) as $l) $likeMap[$l['episode_id']]=['likes'=>(int)$l['likes'],'user_liked'=>(bool)$l['user_liked']];
    }

    foreach($episodes as &$ep){
        $ep['episode_number']=(int)$ep['episode_number'];
        $ep['duration_sec']=(int)$ep['duration_sec'];
        $ep['is_premium']=(bool)$ep['is_premium'];
        $ep['credits_cost']=(int)$ep['credits_cost'];
        $ep['watched_sec']=(int)$ep['watched_sec'];
        $ep['is_completed']=(bool)$ep['is_completed'];
        $ep['progress_pct']=(int)$ep['progress_pct'];
        $ep['duration_label']=fmtDur((int)$ep['duration_sec']);
        $ep['like_count']=$likeMap[$ep['id']]['likes']??0;
        $ep['user_liked']=$likeMap[$ep['id']]['user_liked']??false;
        // Normalize episode media URLs
        $ep['video_url']=toAbsUrl($ep['video_url']??'');
        $ep['thumbnail_url']=toAbsUrl($ep['thumbnail_url']??'');
    }
    $series['episodes']=$episodes;
    echo json_encode(["status"=>"success","data"=>$series]);
}

// ── save_watch_progress ───────────────────────────────────
elseif ($action === 'save_watch_progress') {
    $eid=(string)($_POST['episode_id']??'');
    $sid=(string)($_POST['series_id']??'');
    $sec=(int)($_POST['watched_sec']??0);
    $done=(int)($_POST['is_completed']??0);
    if(!$eid||!$sid){echo json_encode(["status"=>"error","message"=>"Missing ids"]);exit();}
    $pdo->prepare("INSERT INTO webseries_watch_progress(id,user_id,series_id,episode_id,watched_sec,is_completed) VALUES(?,?,?,?,?,?) ON DUPLICATE KEY UPDATE watched_sec=GREATEST(watched_sec,VALUES(watched_sec)),is_completed=VALUES(is_completed),last_watched=NOW()")
        ->execute([genUUID(),$myId,$sid,$eid,$sec,$done]);
    echo json_encode(["status"=>"success"]);
}

// ── toggle_watchlist ──────────────────────────────────────
elseif ($action === 'toggle_watchlist') {
    $sid=$_POST['series_id']??'';
    if(!$sid){echo json_encode(["status"=>"error","message"=>"Missing series_id"]);exit();}
    $chk=$pdo->prepare("SELECT id FROM webseries_watchlist WHERE user_id=? AND series_id=?");
    $chk->execute([$myId,$sid]);
    if($chk->fetch()){
        $pdo->prepare("DELETE FROM webseries_watchlist WHERE user_id=? AND series_id=?")->execute([$myId,$sid]);
        echo json_encode(["status"=>"success","is_saved"=>false]);
    } else {
        $pdo->prepare("INSERT INTO webseries_watchlist(id,user_id,series_id) VALUES(?,?,?)")->execute([genUUID(),$myId,$sid]);
        echo json_encode(["status"=>"success","is_saved"=>true]);
    }
}

// ── get_watchlist ─────────────────────────────────────────
elseif ($action === 'get_watchlist') {
    $st=$pdo->prepare("SELECT w.id,w.title,w.genre,w.cover_url,w.status,w.total_episodes,w.avg_duration_min FROM webseries_watchlist wl JOIN webseries w ON w.id=wl.series_id WHERE wl.user_id=? AND w.is_active=1 ORDER BY wl.added_at DESC");
    $st->execute([$myId]);
    $rows=$st->fetchAll(PDO::FETCH_ASSOC);
    foreach($rows as &$r) {
        $r['total_episodes']=(int)$r['total_episodes'];
        $r['cover_url']=toAbsUrl($r['cover_url']);
    }
    echo json_encode(["status"=>"success","data"=>$rows]);
}

// ── toggle_episode_like ───────────────────────────────────
elseif ($action === 'toggle_episode_like') {
    $eid=$_POST['episode_id']??'';
    if(!$eid){echo json_encode(["status"=>"error","message"=>"Missing episode_id"]);exit();}
    $chk=$pdo->prepare("SELECT id FROM webseries_reactions WHERE user_id=? AND episode_id=? AND type='LIKE'");
    $chk->execute([$myId,$eid]);
    if($chk->fetch()){
        $pdo->prepare("DELETE FROM webseries_reactions WHERE user_id=? AND episode_id=? AND type='LIKE'")->execute([$myId,$eid]);
        $liked=false;
    } else {
        $pdo->prepare("INSERT INTO webseries_reactions(id,user_id,episode_id,type) VALUES(?,?,?,'LIKE')")->execute([genUUID(),$myId,$eid]);
        $liked=true;
    }
    $cnt=$pdo->prepare("SELECT COUNT(*) FROM webseries_reactions WHERE episode_id=? AND type='LIKE'");
    $cnt->execute([$eid]);
    echo json_encode(["status"=>"success","is_liked"=>$liked,"like_count"=>(int)$cnt->fetchColumn()]);
}

// ── get_episode_comments ──────────────────────────────────
elseif ($action === 'get_episode_comments') {
    $eid=$_GET['episode_id']??'';
    $page=max(1,(int)($_GET['page']??1)); $limit=20; $offset=($page-1)*$limit;
    if(!$eid){echo json_encode(["status"=>"error","message"=>"Missing episode_id"]);exit();}
    $st=$pdo->prepare("SELECT r.id,r.body,r.created_at,u.full_name,u.profile_image_url FROM webseries_reactions r JOIN cinecircle u ON r.user_id=u.id WHERE r.episode_id=? AND r.type='COMMENT' ORDER BY r.created_at DESC LIMIT ? OFFSET ?");
    $st->execute([$eid,$limit,$offset]);
    echo json_encode(["status"=>"success","data"=>$st->fetchAll(PDO::FETCH_ASSOC),"page"=>$page]);
}

// ── post_episode_comment ──────────────────────────────────
elseif ($action === 'post_episode_comment') {
    $eid=$_POST['episode_id']??''; $body=trim($_POST['body']??'');
    if(!$eid||$body===''){echo json_encode(["status"=>"error","message"=>"Missing fields"]);exit();}
    $id=genUUID();
    $pdo->prepare("INSERT INTO webseries_reactions(id,user_id,episode_id,type,body) VALUES(?,?,?,'COMMENT',?)")->execute([$id,$myId,$eid,$body]);
    echo json_encode(["status"=>"success","comment_id"=>$id,"author"=>$me['full_name']]);
}

// ── record_share ──────────────────────────────────────────
elseif ($action === 'record_share') {
    $eid=$_POST['episode_id']??'';
    if(!$eid){echo json_encode(["status"=>"error","message"=>"Missing episode_id"]);exit();}
    // Only insert if not already shared (one share tracked per user per episode)
    $chk=$pdo->prepare("SELECT id FROM webseries_reactions WHERE user_id=? AND episode_id=? AND type='SHARE'");
    $chk->execute([$myId,$eid]);
    if(!$chk->fetch()){
        $pdo->prepare("INSERT INTO webseries_reactions(id,user_id,episode_id,type) VALUES(?,?,?,'SHARE')")
            ->execute([genUUID(),$myId,$eid]);
    }
    $cnt=$pdo->prepare("SELECT COUNT(*) FROM webseries_reactions WHERE episode_id=? AND type='SHARE'");
    $cnt->execute([$eid]);
    echo json_encode(["status"=>"success","share_count"=>(int)$cnt->fetchColumn()]);
}

else {
    http_response_code(400);
    echo json_encode(["status"=>"error","message"=>"Invalid action: $action"]);
}

} catch (PDOException $e) {
    http_response_code(500);
    echo json_encode(["status"=>"error","message"=>"DB: ".$e->getMessage()]);
}
?>
