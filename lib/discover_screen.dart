import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer/shimmer.dart';
import 'webseries_detail_screen.dart';



class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({super.key});
  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> {
  final _searchCtrl = TextEditingController();
  Timer? _debounce;

  List<dynamic> _series = [];
  bool _isLoading = true;
  String _selectedFilter = 'All';
  int _page = 1;
  bool _hasMore = true;
  bool _loadingMore = false;
  final _scrollCtrl = ScrollController();

  // Filter → API params
  static const _filters = ['All', 'Ongoing', 'Completed', 'Shorts', 'Most Watched'];
  static const _filterStatus = {
    'Ongoing': 'ONGOING',
    'Completed': 'COMPLETED',
  };
  static const _filterType = {'Shorts': 'SHORT'};
  static const _filterOrder = {'Most Watched': 'most_watched'};

  @override
  void initState() {
    super.initState();
    _fetchSeries(reset: true);
    _scrollCtrl.addListener(_onScroll);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollCtrl.position.pixels >= _scrollCtrl.position.maxScrollExtent - 200 &&
        !_loadingMore && _hasMore) {
      _fetchSeries(reset: false);
    }
  }

  Future<String> _getMobile() async {
    final p = await SharedPreferences.getInstance();
    return p.getString('user_phone') ?? '';
  }

  Future<void> _fetchSeries({bool reset = true}) async {
    if (reset) {
      setState(() { _isLoading = true; _page = 1; _series = []; });
    } else {
      setState(() => _loadingMore = true);
    }

    try {
      final mobile = await _getMobile();
      final q = Uri(
        scheme: 'https',
        host: 'team.cropsync.in',
        path: '/cine_circle/webseries_api.php',
        queryParameters: {
          'action': 'get_webseries_list',
          'mobile_number': mobile,
          'page': '$_page',
          if (_filterStatus[_selectedFilter] != null) 'status': _filterStatus[_selectedFilter]!,
          if (_filterType[_selectedFilter] != null) 'type': _filterType[_selectedFilter]!,
          if (_filterOrder[_selectedFilter] != null) 'order': _filterOrder[_selectedFilter]!,
          if (_searchCtrl.text.trim().isNotEmpty) 'search': _searchCtrl.text.trim(),
        },
      );

      final res = await http.get(q);
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        if (data['status'] == 'success' && mounted) {
          final newItems = List<dynamic>.from(data['data'] ?? []);
          setState(() {
            _series = reset ? newItems : [..._series, ...newItems];
            _hasMore = data['has_more'] == true;
            _page++;
          });
        }
      }
    } catch (e) {
      debugPrint('fetchSeries error: $e');
    }

    if (mounted) setState(() { _isLoading = false; _loadingMore = false; });
  }

  void _onSearchChanged(String val) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () => _fetchSeries(reset: true));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        title: Image.asset('assets/cinelogo.png', height: 32, fit: BoxFit.contain),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text('Discover',
                  style: TextStyle(
                      fontFamily: 'Google Sans', fontSize: 28,
                      fontWeight: FontWeight.bold, color: Colors.black,
                      letterSpacing: -0.5)),
            ),
            const SizedBox(height: 16),
            // Search
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: TextField(
                  controller: _searchCtrl,
                  onChanged: _onSearchChanged,
                  style: const TextStyle(fontFamily: 'Google Sans', fontSize: 15),
                  decoration: InputDecoration(
                    hintText: 'Search webseries...',
                    hintStyle: TextStyle(fontFamily: 'Google Sans', color: Colors.grey.shade500, fontSize: 15),
                    prefixIcon: const Icon(Icons.search, color: Colors.grey),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Filter pills
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: _filters.map((f) {
                  final sel = f == _selectedFilter;
                  return GestureDetector(
                    onTap: () { setState(() => _selectedFilter = f); _fetchSeries(reset: true); },
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: sel ? Colors.black : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(f,
                        style: TextStyle(
                          fontFamily: 'Google Sans', fontSize: 13,
                          fontWeight: sel ? FontWeight.w600 : FontWeight.w500,
                          color: sel ? Colors.white : Colors.black87,
                        )),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 20),
            // Grid
            Expanded(
              child: _isLoading
                  ? _buildShimmerGrid()
                  : _series.isEmpty
                      ? _buildEmpty()
                      : RefreshIndicator(
                          color: Colors.black,
                          onRefresh: () => _fetchSeries(reset: true),
                          child: GridView.builder(
                            controller: _scrollCtrl,
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: 0.72,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 16,
                            ),
                            itemCount: _series.length + (_loadingMore ? 2 : 0),
                            itemBuilder: (ctx, i) {
                              if (i >= _series.length) return _buildShimmerCard();
                              return _buildCard(ctx, _series[i]);
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(BuildContext ctx, Map<String, dynamic> item) {
    final hasCover = item['cover_url'] != null && (item['cover_url'] as String).isNotEmpty;
    return GestureDetector(
      onTap: () => Navigator.push(
        ctx,
        MaterialPageRoute(builder: (_) => WebseriesDetailScreen(seriesId: item['id'])),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cover image
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(13)),
              child: hasCover
                  ? CachedNetworkImage(
                      imageUrl: item['cover_url'],
                      height: 130, width: double.infinity, fit: BoxFit.cover,
                      placeholder: (_, _) => Container(height: 130, color: Colors.grey.shade200),
                      errorWidget: (_, _, _) => Container(height: 130, color: Colors.grey.shade900,
                        child: Center(child: Text(item['title'] ?? '', textAlign: TextAlign.center,
                          style: const TextStyle(fontFamily: 'Google Sans', color: Colors.white, fontSize: 13)))),
                    )
                  : Container(height: 130, color: Colors.grey.shade900,
                      child: Center(child: Text(item['title'] ?? '', textAlign: TextAlign.center,
                        style: const TextStyle(fontFamily: 'Google Sans', color: Colors.white, fontSize: 13)))),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status badge
                  if (item['status'] != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: item['status'] == 'ONGOING' ? Colors.green.shade50 : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        item['status'] == 'ONGOING' ? 'Ongoing' : item['status'] == 'COMPLETED' ? 'Completed' : item['status'],
                        style: TextStyle(fontFamily: 'Google Sans', fontSize: 10,
                          color: item['status'] == 'ONGOING' ? Colors.green.shade700 : Colors.grey.shade600),
                      ),
                    ),
                  Text(item['title'] ?? '',
                    style: const TextStyle(fontFamily: 'Google Sans', fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black),
                    maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Text('${item['genre'] ?? ''} • ${item['total_episodes'] ?? 0} eps',
                    style: TextStyle(fontFamily: 'Google Sans', fontSize: 11, color: Colors.grey.shade600),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 7),
                    decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(7)),
                    child: const Text('View Show', textAlign: TextAlign.center,
                      style: TextStyle(fontFamily: 'Google Sans', fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmerGrid() {
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2, childAspectRatio: 0.72, crossAxisSpacing: 12, mainAxisSpacing: 16),
      itemCount: 6,
      itemBuilder: (_, _) => _buildShimmerCard(),
    );
  }

  Widget _buildShimmerCard() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade200, highlightColor: Colors.grey.shade100,
      child: Container(
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
        child: Column(children: [
          Container(height: 130, decoration: const BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(13)))),
          Padding(padding: const EdgeInsets.all(10), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(height: 10, width: 50, color: Colors.white),
            const SizedBox(height: 6),
            Container(height: 13, width: double.infinity, color: Colors.white),
            const SizedBox(height: 4),
            Container(height: 11, width: 80, color: Colors.white),
            const SizedBox(height: 8),
            Container(height: 30, width: double.infinity, color: Colors.white, decoration: BoxDecoration(borderRadius: BorderRadius.circular(7))),
          ])),
        ]),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(Icons.movie_outlined, size: 64, color: Colors.grey.shade300),
      const SizedBox(height: 12),
      Text('No webseries found', style: TextStyle(fontFamily: 'Google Sans', color: Colors.grey.shade500, fontSize: 16)),
    ]));
  }
}
