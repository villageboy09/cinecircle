import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer/shimmer.dart';
import 'webseries_player_screen.dart';

const _wsApi = 'https://team.cropsync.in/cine_circle/webseries_api.php';

class WebseriesDetailScreen extends StatefulWidget {
  final String seriesId;
  const WebseriesDetailScreen({super.key, required this.seriesId});

  @override
  State<WebseriesDetailScreen> createState() => _WebseriesDetailScreenState();
}

class _WebseriesDetailScreenState extends State<WebseriesDetailScreen>
    with SingleTickerProviderStateMixin {
  Map<String, dynamic> _detail = {};
  List<dynamic> _episodes = [];
  bool _isLoading = true;
  bool _isSaved = false;
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this, initialIndex: 1);
    _fetchDetail();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  Future<String> _getMobile() async {
    final p = await SharedPreferences.getInstance();
    return p.getString('user_phone') ?? '';
  }

  Future<void> _fetchDetail() async {
    setState(() => _isLoading = true);
    try {
      final mobile = await _getMobile();
      final res = await http.get(Uri.parse(
          '$_wsApi?action=get_webseries_detail&mobile_number=$mobile&series_id=${widget.seriesId}'));
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        if (data['status'] == 'success' && mounted) {
          final d = data['data'] as Map<String, dynamic>;
          setState(() {
            _detail = d;
            _episodes = d['episodes'] ?? [];
            _isSaved = d['is_saved'] ?? false;
          });
        }
      }
    } catch (e) {
      debugPrint('fetchDetail error: $e');
    }
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _toggleWatchlist() async {
    final mobile = await _getMobile();
    try {
      final res = await http.post(Uri.parse(_wsApi), body: {
        'action': 'toggle_watchlist',
        'mobile_number': mobile,
        'series_id': widget.seriesId,
      });
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        if (data['status'] == 'success' && mounted) {
          setState(() => _isSaved = data['is_saved'] ?? !_isSaved);
        }
      }
    } catch (e) {
      debugPrint('toggleWatchlist error: $e');
    }
  }

  void _playEpisode(Map<String, dynamic> ep) {
    if ((ep['video_url'] ?? '').isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: const Text('Video not available yet', style: TextStyle(fontFamily: 'Google Sans')),
          backgroundColor: Colors.black, behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))));
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => WebseriesPlayerScreen(
        seriesId: widget.seriesId,
        seriesTitle: _detail['title'] ?? '',
        episodeId: ep['id'],
        videoUrl: ep['video_url'],
        episodeNumber: ep['episode_number'] ?? 1,
        episodeTitle: ep['title'] ?? '',
        episodeList: _episodes,
      )),
    ).then((_) => _fetchDetail()); // refresh progress on return
  }

  String _formatDur(int secs) {
    final m = secs ~/ 60;
    final s = secs % 60;
    return '${m}m ${s.toString().padLeft(2, '0')}s';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: _isLoading ? _buildShimmer() : _buildContent(),
    );
  }

  Widget _buildShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade200, highlightColor: Colors.grey.shade100,
      child: SafeArea(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(height: 56, color: Colors.white),
        Container(height: 220, color: Colors.white),
        const SizedBox(height: 16),
        Padding(padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(height: 24, width: 200, color: Colors.white),
            const SizedBox(height: 12),
            Container(height: 14, width: double.infinity, color: Colors.white),
            const SizedBox(height: 8),
            Container(height: 14, width: 160, color: Colors.white),
          ])),
      ])),
    );
  }

  Widget _buildContent() {
    final hasBanner = (_detail['banner_url'] ?? '').isNotEmpty;
    final hasCover  = (_detail['cover_url']  ?? '').isNotEmpty;
    final tags = (_detail['tags'] ?? '').toString().split(',').where((t) => t.trim().isNotEmpty).toList();

    return NestedScrollView(
      headerSliverBuilder: (ctx, _) => [
        SliverAppBar(
          expandedHeight: hasBanner ? 220 : 0,
          pinned: true,
          backgroundColor: Colors.white,
          iconTheme: const IconThemeData(color: Colors.black),
          title: Image.asset('assets/cinelogo.png', height: 28, fit: BoxFit.contain),
          centerTitle: true,
          actions: [
            IconButton(
              icon: Icon(_isSaved ? Icons.bookmark : Icons.bookmark_border, color: Colors.black, size: 26),
              onPressed: _toggleWatchlist,
            ),
          ],
          flexibleSpace: hasBanner
              ? FlexibleSpaceBar(
                  background: CachedNetworkImage(
                    imageUrl: _detail['banner_url'], fit: BoxFit.cover,
                    placeholder: (_, _) => Container(color: Colors.grey.shade900),
                    errorWidget: (_, _, _) => Container(color: Colors.grey.shade900)),
                )
              : null,
        ),
      ],
      body: SingleChildScrollView(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Header info
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: hasCover
                    ? CachedNetworkImage(
                        imageUrl: _detail['cover_url'], width: 120, height: 175, fit: BoxFit.cover,
                        placeholder: (_, _) => Container(width: 120, height: 175, color: Colors.grey.shade900),
                        errorWidget: (_, _, _) => Container(width: 120, height: 175, color: Colors.grey.shade900,
                          child: Center(child: Text(_detail['title'] ?? '', textAlign: TextAlign.center,
                            style: const TextStyle(fontFamily: 'Google Sans', color: Colors.white, fontSize: 12)))))
                    : Container(width: 120, height: 175, color: Colors.grey.shade900,
                        child: Center(child: Text(_detail['title'] ?? '', textAlign: TextAlign.center,
                          style: const TextStyle(fontFamily: 'Google Sans', color: Colors.white, fontSize: 12)))),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(_detail['title'] ?? '',
                    style: const TextStyle(fontFamily: 'Google Sans', fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black, height: 1.2, letterSpacing: -0.5)),
                  const SizedBox(height: 10),
                  Wrap(spacing: 8, runSpacing: 6, children: [
                    if ((_detail['genre'] ?? '').isNotEmpty) _pill(_detail['genre']),
                    ...tags.take(2).map((t) => _pill(t.trim())),
                  ]),
                  const SizedBox(height: 12),
                  Row(children: [
                    Icon(Icons.play_circle_outline, size: 14, color: Colors.grey.shade600),
                    const SizedBox(width: 4),
                    Text('${_detail['total_episodes'] ?? 0} Episodes',
                      style: TextStyle(fontFamily: 'Google Sans', fontSize: 13, color: Colors.grey.shade600)),
                  ]),
                  const SizedBox(height: 4),
                  if ((_detail['language'] ?? '').isNotEmpty)
                    Row(children: [
                      Icon(Icons.language, size: 14, color: Colors.grey.shade600),
                      const SizedBox(width: 4),
                      Text(_detail['language'],
                        style: TextStyle(fontFamily: 'Google Sans', fontSize: 13, color: Colors.grey.shade600)),
                    ]),
                ]),
              ),
            ]),
          ),

          // Play button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: SizedBox(
              width: double.infinity, height: 50,
              child: ElevatedButton.icon(
                onPressed: _episodes.isNotEmpty ? () => _playEpisode(_episodes[0]) : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black, foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                ),
                icon: const Icon(Icons.play_arrow, size: 22),
                label: const Text('Play From Episode 1',
                  style: TextStyle(fontFamily: 'Google Sans', fontSize: 15, fontWeight: FontWeight.w600)),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Tabs
          TabBar(
            controller: _tabCtrl,
            labelStyle: const TextStyle(fontFamily: 'Google Sans', fontSize: 15, fontWeight: FontWeight.w600),
            unselectedLabelStyle: const TextStyle(fontFamily: 'Google Sans', fontSize: 15, fontWeight: FontWeight.w500),
            labelColor: Colors.black,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Colors.black,
            indicatorWeight: 3,
            tabs: const [Tab(text: 'About'), Tab(text: 'Episodes'), Tab(text: 'Cast')],
          ),
          Divider(height: 1, color: Colors.grey.shade200),

          // Tab content (non-scrollable inside NestedScrollView)
          SizedBox(
            height: (_episodes.length * 110.0).clamp(300, 2000),
            child: TabBarView(controller: _tabCtrl, children: [
              _buildAboutTab(),
              _buildEpisodesTab(),
              _buildCastTab(),
            ]),
          ),
          const SizedBox(height: 32),
        ]),
      ),
    );
  }

  Widget _buildAboutTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(_detail['description'] ?? 'No description available.',
          style: const TextStyle(fontFamily: 'Google Sans', fontSize: 15, color: Colors.black87, height: 1.6)),
        if ((_detail['status'] ?? '').isNotEmpty) ...[
          const SizedBox(height: 20),
          _infoRow(Icons.fiber_smart_record_outlined, 'Status', _detail['status']),
        ],
        if ((_detail['language'] ?? '').isNotEmpty)
          _infoRow(Icons.language, 'Language', _detail['language']),
        if ((_detail['total_episodes'] ?? 0) > 0)
          _infoRow(Icons.format_list_numbered, 'Episodes', '${_detail['total_episodes']}'),
        if ((_detail['avg_duration_min'] ?? 0) > 0)
          _infoRow(Icons.timer_outlined, 'Avg. Duration', '${_detail['avg_duration_min']} min / ep'),
      ]),
    );
  }

  Widget _buildEpisodesTab() {
    if (_episodes.isEmpty) {
      return Center(child: Text('No episodes yet.',
        style: TextStyle(fontFamily: 'Google Sans', color: Colors.grey.shade500)));
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _episodes.length,
      itemBuilder: (_, i) => _buildEpisodeItem(_episodes[i]),
    );
  }

  Widget _buildCastTab() {
    return Center(child: Padding(
      padding: const EdgeInsets.all(32),
      child: Text('Cast information coming soon.',
        textAlign: TextAlign.center,
        style: TextStyle(fontFamily: 'Google Sans', color: Colors.grey.shade500, fontSize: 15)),
    ));
  }

  Widget _buildEpisodeItem(Map<String, dynamic> ep) {
    final hasThumb = (ep['thumbnail_url'] ?? '').isNotEmpty;
    final pct = (ep['progress_pct'] as int? ?? 0) / 100.0;
    final durSec = ep['duration_sec'] as int? ?? 0;
    final durLabel = durSec > 0 ? _formatDur(durSec) : ep['duration_label'] ?? '';
    final isPremium = ep['is_premium'] as bool? ?? false;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
        // Thumbnail
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: hasThumb
              ? CachedNetworkImage(
                  imageUrl: ep['thumbnail_url'], width: 100, height: 68, fit: BoxFit.cover,
                  placeholder: (_, _) => Container(width: 100, height: 68, color: Colors.grey.shade200),
                  errorWidget: (_, _, _) => _thumbPlaceholder(ep))
              : _thumbPlaceholder(ep),
        ),
        const SizedBox(width: 14),
        // Info
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Ep ${ep['episode_number']}: ${ep['title'] ?? ''}',
            style: const TextStyle(fontFamily: 'Google Sans', fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black),
            maxLines: 2, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 4),
          Row(children: [
            Text(durLabel, style: TextStyle(fontFamily: 'Google Sans', fontSize: 11, color: Colors.grey.shade600)),
            if (isPremium) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: Colors.amber.shade50, borderRadius: BorderRadius.circular(4)),
                child: Text('Premium', style: TextStyle(fontFamily: 'Google Sans', fontSize: 10, color: Colors.amber.shade800))),
            ],
          ]),
          if (pct > 0) ...[
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: pct.clamp(0, 1),
                backgroundColor: Colors.grey.shade200,
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.black),
                minHeight: 3,
              ),
            ),
          ],
        ])),
        const SizedBox(width: 10),
        // Play button
        GestureDetector(
          onTap: () => _playEpisode(ep),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
            decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(20)),
            child: Text(pct > 0 && pct < 1 ? 'Resume' : pct >= 1 ? 'Rewatch' : 'Play',
              style: const TextStyle(fontFamily: 'Google Sans', color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
          ),
        ),
      ]),
    );
  }

  Widget _thumbPlaceholder(Map<String, dynamic> ep) {
    return Container(width: 100, height: 68, color: Colors.grey.shade900,
      child: Center(child: Text('Ep ${ep['episode_number']}',
        style: const TextStyle(fontFamily: 'Google Sans', color: Colors.white54, fontSize: 12))));
  }

  Widget _pill(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(6)),
      child: Text(text, style: const TextStyle(fontFamily: 'Google Sans', fontSize: 12, color: Colors.black87)),
    );
  }

  Widget _infoRow(IconData icon, String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Row(children: [
        Icon(icon, size: 16, color: Colors.grey.shade600),
        const SizedBox(width: 8),
        Text('$label: ', style: const TextStyle(fontFamily: 'Google Sans', fontSize: 13, fontWeight: FontWeight.w600)),
        Text('$value', style: TextStyle(fontFamily: 'Google Sans', fontSize: 13, color: Colors.grey.shade700)),
      ]),
    );
  }
}
