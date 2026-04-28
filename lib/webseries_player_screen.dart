import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player/video_player.dart';

const _wsApi = 'https://team.cropsync.in/cine_circle/webseries_api.php';

class WebseriesPlayerScreen extends StatefulWidget {
  final String seriesId;
  final String seriesTitle;
  final String episodeId;
  final String videoUrl;
  final int episodeNumber;
  final String episodeTitle;
  final List<dynamic> episodeList;

  const WebseriesPlayerScreen({
    super.key,
    required this.seriesId,
    required this.seriesTitle,
    required this.episodeId,
    required this.videoUrl,
    required this.episodeNumber,
    required this.episodeTitle,
    required this.episodeList,
  });

  @override
  State<WebseriesPlayerScreen> createState() => _WebseriesPlayerScreenState();
}

class _WebseriesPlayerScreenState extends State<WebseriesPlayerScreen> {
  late PageController _pageCtrl;
  final Map<int, VideoPlayerController> _ctrls = {};
  final Map<int, bool> _inited = {};
  final Map<int, bool> _liked = {};
  final Map<int, int> _likeCount = {};

  int _cur = 0;
  bool _showCtrl = false;
  Timer? _hideTimer;
  Timer? _progressTimer;
  String _mobile = '';

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    final startIdx = widget.episodeList.indexWhere(
      (e) => e['id'] == widget.episodeId,
    );
    _cur = startIdx >= 0 ? startIdx : 0;
    _pageCtrl = PageController(initialPage: _cur);
    for (int i = 0; i < widget.episodeList.length; i++) {
      final ep = widget.episodeList[i] as Map<String, dynamic>;
      _liked[i] = ep['user_liked'] as bool? ?? false;
      _likeCount[i] = ep['like_count'] as int? ?? 0;
    }
    _boot();
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _hideTimer?.cancel();
    _progressTimer?.cancel();
    _saveProgress(_cur);
    for (final c in _ctrls.values) {
      c.dispose();
    }
    _pageCtrl.dispose();
    super.dispose();
  }

  Future<void> _boot() async {
    final prefs = await SharedPreferences.getInstance();
    _mobile = prefs.getString('user_phone') ?? '';
    await _initCtrl(_cur);
    if (_cur + 1 < widget.episodeList.length) _initCtrl(_cur + 1);
    _startTimer();
  }

  Future<void> _initCtrl(int idx) async {
    if (_ctrls.containsKey(idx)) return;
    final ep = widget.episodeList[idx] as Map<String, dynamic>;
    final url = ep['video_url'] as String? ?? '';
    if (url.isEmpty) return;
    final c = VideoPlayerController.networkUrl(Uri.parse(url));
    _ctrls[idx] = c;
    try {
      await c.initialize();
      if (!mounted) return;
      setState(() => _inited[idx] = true);
      if (idx == _cur) c.play();
    } catch (e) {
      debugPrint('ctrl[$idx] err: $e');
    }
  }

  void _pruneDistant(int cur) {
    for (final k in _ctrls.keys.where((k) => (k - cur).abs() > 1).toList()) {
      _ctrls[k]?.dispose();
      _ctrls.remove(k);
      _inited.remove(k);
    }
  }

  void _onPage(int idx) {
    _ctrls[_cur]?.pause();
    _saveProgress(_cur);
    _progressTimer?.cancel();
    setState(() {
      _cur = idx;
      _showCtrl = false;
    });
    _ctrls[idx]?.play();
    _initCtrl(idx);
    if (idx + 1 < widget.episodeList.length) _initCtrl(idx + 1);
    _pruneDistant(idx);
    _startTimer();
  }

  void _startTimer() {
    _progressTimer?.cancel();
    _progressTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => _saveProgress(_cur),
    );
  }

  Future<void> _saveProgress(int idx) async {
    if (_mobile.isEmpty || !_ctrls.containsKey(idx)) return;
    final ep = widget.episodeList[idx] as Map<String, dynamic>;
    final c = _ctrls[idx]!;
    final w = c.value.position.inSeconds;
    final t = c.value.duration.inSeconds;
    try {
      await http.post(
        Uri.parse(_wsApi),
        body: {
          'action': 'save_watch_progress',
          'mobile_number': _mobile,
          'series_id': widget.seriesId,
          'episode_id': ep['id'],
          'watched_sec': '$w',
          'is_completed': '${t > 0 && w >= t - 3 ? 1 : 0}',
        },
      );
    } catch (_) {}
  }

  void _tapCtrl() {
    setState(() => _showCtrl = !_showCtrl);
    if (_showCtrl) {
      _hideTimer?.cancel();
      _hideTimer = Timer(const Duration(seconds: 4), () {
        if (mounted) setState(() => _showCtrl = false);
      });
    }
  }

  Future<void> _toggleLike(int idx) async {
    final ep = widget.episodeList[idx] as Map<String, dynamic>;
    final was = _liked[idx] ?? false;
    setState(() {
      _liked[idx] = !was;
      _likeCount[idx] = (_likeCount[idx] ?? 0) + (was ? -1 : 1);
    });
    try {
      await http.post(
        Uri.parse(_wsApi),
        body: {
          'action': 'toggle_episode_like',
          'mobile_number': _mobile,
          'episode_id': ep['id'],
        },
      );
    } catch (_) {
      if (mounted) {
        setState(() {
          _liked[idx] = was;
          _likeCount[idx] = (_likeCount[idx] ?? 0) + (was ? 1 : -1);
        });
      }
    }
  }

  Future<void> _share(int idx) async {
    final ep = widget.episodeList[idx] as Map<String, dynamic>;
    // Record SHARE reaction
    try {
      await http.post(
        Uri.parse(_wsApi),
        body: {
          'action': 'record_share',
          'mobile_number': _mobile,
          'episode_id': ep['id'],
        },
      );
    } catch (_) {}
    await Clipboard.setData(
      ClipboardData(
        text:
            'Watch "${widget.seriesTitle}" Ep ${ep['episode_number']}: ${ep['title']} on CineCircle!',
      ),
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Copied to clipboard!',
            style: TextStyle(fontFamily: 'Google Sans'),
          ),
          backgroundColor: Colors.black87,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _showComments(int idx) {
    final ep = widget.episodeList[idx] as Map<String, dynamic>;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CommentsSheet(episodeId: ep['id'], mobile: _mobile),
    );
  }

  String _fmt(Duration d) =>
      '${d.inMinutes.remainder(60).toString().padLeft(2, '0')}:${d.inSeconds.remainder(60).toString().padLeft(2, '0')}';

  String _fmtCount(int n) =>
      n >= 1000 ? '${(n / 1000).toStringAsFixed(1)}k' : '$n';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            PageView.builder(
              controller: _pageCtrl,
              scrollDirection: Axis.vertical,
              onPageChanged: _onPage,
              itemCount: widget.episodeList.length,
              itemBuilder: (_, i) => _buildPage(i),
            ),
            // Top bar — always visible
            Positioned(
              top: 12,
              left: 16,
              right: 16,
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () async {
                      final nav = Navigator.of(context);
                      await _saveProgress(_cur);
                      nav.pop();
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Colors.black54,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.arrow_back,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.seriesTitle,
                          style: const TextStyle(
                            fontFamily: 'Google Sans',
                            color: Colors.white60,
                            fontSize: 11,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'Ep ${(widget.episodeList[_cur] as Map)['episode_number']}: ${(widget.episodeList[_cur] as Map)['title'] ?? ''}',
                          style: const TextStyle(
                            fontFamily: 'Google Sans',
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPage(int idx) {
    final c = _ctrls[idx];
    final ok = _inited[idx] == true && c != null;
    return GestureDetector(
      onTap: _tapCtrl,
      behavior: HitTestBehavior.opaque,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Video
          Container(
            color: Colors.black,
            child: ok
                ? Center(
                    child: AspectRatio(
                      aspectRatio: c.value.aspectRatio,
                      child: VideoPlayer(c),
                    ),
                  )
                : const Center(
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  ),
          ),
          // Bottom gradient
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: 240,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.88),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),
          // Right reactions
          Positioned(right: 12, bottom: 100, child: _buildReactions(idx)),
          // Bottom episode info + dots
          Positioned(left: 16, right: 80, bottom: 24, child: _buildInfo(idx)),
          // Seek controls
          if (_showCtrl && ok) _buildSeek(idx, c),
        ],
      ),
    );
  }

  Widget _buildReactions(int idx) {
    final liked = _liked[idx] ?? false;
    final lc = _likeCount[idx] ?? 0;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _rBtn(
          liked ? Icons.favorite : Icons.favorite_border,
          liked ? Colors.red : Colors.white,
          lc > 0 ? _fmtCount(lc) : '',
          () => _toggleLike(idx),
        ),
        const SizedBox(height: 22),
        _rBtn(
          Icons.chat_bubble_outline,
          Colors.white,
          'Comments',
          () => _showComments(idx),
        ),
        const SizedBox(height: 22),
        _rBtn(
          Icons.reply,
          Colors.white,
          'Share',
          () => _share(idx),
          flip: true,
        ),
      ],
    );
  }

  Widget _rBtn(
    IconData icon,
    Color color,
    String label,
    VoidCallback onTap, {
    bool flip = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Transform(
            alignment: Alignment.center,
            transform: flip ? Matrix4.rotationY(3.14159) : Matrix4.identity(),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: const BoxDecoration(
                color: Colors.black45,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 26),
            ),
          ),
          if (label.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                fontFamily: 'Google Sans',
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfo(int idx) {
    final ep = widget.episodeList[idx] as Map<String, dynamic>;
    final desc = ep['description'] as String? ?? '';
    final total = widget.episodeList.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Ep ${ep['episode_number']}: ${ep['title'] ?? ''}',
          style: const TextStyle(
            fontFamily: 'Google Sans',
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        if (desc.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            desc,
            style: const TextStyle(
              fontFamily: 'Google Sans',
              color: Colors.white70,
              fontSize: 12,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
        const SizedBox(height: 8),
        if (total > 1)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(
              total.clamp(0, 10),
              (i) => Container(
                margin: const EdgeInsets.only(right: 4),
                width: i == idx ? 18 : 6,
                height: 4,
                decoration: BoxDecoration(
                  color: i == idx ? Colors.white : Colors.white38,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSeek(int idx, VideoPlayerController c) {
    return Positioned(
      bottom: 90,
      left: 16,
      right: 90,
      child: ValueListenableBuilder<VideoPlayerValue>(
        valueListenable: c,
        builder: (_, val, _) {
          final pos = val.position;
          final dur = val.duration;
          final total = dur.inSeconds > 0 ? dur.inSeconds.toDouble() : 1.0;
          final cur = pos.inSeconds.clamp(0, dur.inSeconds).toDouble();
          return Column(
            children: [
              // Play/pause row
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        val.isPlaying ? c.pause() : c.play();
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: const BoxDecoration(
                        color: Colors.black54,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        val.isPlaying ? Icons.pause : Icons.play_arrow,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  thumbShape: const RoundSliderThumbShape(
                    enabledThumbRadius: 6,
                  ),
                  overlayShape: const RoundSliderOverlayShape(
                    overlayRadius: 12,
                  ),
                  activeTrackColor: Colors.white,
                  inactiveTrackColor: Colors.white30,
                  thumbColor: Colors.white,
                  trackHeight: 2.5,
                ),
                child: Slider(
                  value: cur,
                  max: total,
                  onChanged: (v) {
                    c.seekTo(Duration(seconds: v.toInt()));
                    _tapCtrl();
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _fmt(pos),
                      style: const TextStyle(
                        fontFamily: 'Google Sans',
                        color: Colors.white,
                        fontSize: 11,
                      ),
                    ),
                    Text(
                      _fmt(dur),
                      style: const TextStyle(
                        fontFamily: 'Google Sans',
                        color: Colors.white54,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ── Comments Bottom Sheet ─────────────────────────────────────────────────────
class _CommentsSheet extends StatefulWidget {
  final String episodeId;
  final String mobile;
  const _CommentsSheet({required this.episodeId, required this.mobile});

  @override
  State<_CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends State<_CommentsSheet> {
  final _ctrl = TextEditingController();
  List<dynamic> _comments = [];
  bool _loading = true;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _fetch() async {
    setState(() => _loading = true);
    try {
      final res = await http.get(
        Uri.parse(
          '$_wsApi?action=get_episode_comments&mobile_number=${widget.mobile}&episode_id=${widget.episodeId}',
        ),
      );
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        if (data['status'] == 'success' && mounted) {
          setState(() => _comments = data['data'] ?? []);
        }
      }
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _send() async {
    final txt = _ctrl.text.trim();
    if (txt.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      final res = await http.post(
        Uri.parse(_wsApi),
        body: {
          'action': 'post_episode_comment',
          'mobile_number': widget.mobile,
          'episode_id': widget.episodeId,
          'body': txt,
        },
      );
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        if (data['status'] == 'success') {
          _ctrl.clear();
          await _fetch();
        }
      }
    } catch (_) {}
    if (mounted) setState(() => _sending = false);
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      builder: (_, sc) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Text(
              'Comments',
              style: TextStyle(
                fontFamily: 'Google Sans',
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Divider(),
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(color: Colors.black),
                    )
                  : _comments.isEmpty
                  ? const Center(
                      child: Text(
                        'No comments yet. Be the first!',
                        style: TextStyle(
                          fontFamily: 'Google Sans',
                          color: Colors.grey,
                        ),
                      ),
                    )
                  : ListView.builder(
                      controller: sc,
                      itemCount: _comments.length,
                      itemBuilder: (_, i) {
                        final c = _comments[i] as Map<String, dynamic>;
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.grey.shade200,
                            child: Text(
                              (c['full_name'] as String? ?? '?')[0]
                                  .toUpperCase(),
                              style: const TextStyle(
                                fontFamily: 'Google Sans',
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          title: Text(
                            c['full_name'] ?? '',
                            style: const TextStyle(
                              fontFamily: 'Google Sans',
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: Text(
                            c['body'] ?? '',
                            style: const TextStyle(
                              fontFamily: 'Google Sans',
                              fontSize: 14,
                              color: Colors.black87,
                            ),
                          ),
                        );
                      },
                    ),
            ),
            // Input
            Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 8,
                bottom: MediaQuery.of(context).viewInsets.bottom + 12,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _ctrl,
                      style: const TextStyle(
                        fontFamily: 'Google Sans',
                        fontSize: 14,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Add a comment...',
                        hintStyle: TextStyle(
                          fontFamily: 'Google Sans',
                          color: Colors.grey.shade500,
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _send,
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: const BoxDecoration(
                        color: Colors.black,
                        shape: BoxShape.circle,
                      ),
                      child: _sending
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(
                              Icons.send_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
