import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'public_profile_screen.dart';
import 'global_notifier.dart';

const _socialApiCard = 'https://team.cropsync.in/cine_circle/social_api.php';

enum CardType { trending, nearby }

/// Reusable stateful Follow card used in both Trending Talent and Nearby Creators
class FollowCard extends StatefulWidget {
  final String userId;
  final String name;
  final String role;
  final String location;
  final String? imageUrl;
  final CardType cardType;
  final bool initialIsFollowing;

  const FollowCard({
    super.key,
    required this.userId,
    required this.name,
    required this.role,
    required this.location,
    required this.imageUrl,
    required this.cardType,
    this.initialIsFollowing = false,
  });

  @override
  State<FollowCard> createState() => _FollowCardState();
}

class _FollowCardState extends State<FollowCard> {
  bool _isFollowing = false;
  bool _isLoading = false;
  late final VoidCallback _followListener;

  @override
  void initState() {
    super.initState();
    final global = GlobalNotifier.instance;

    // ALWAYS trust the server-provided initialIsFollowing on first build.
    // The cache may contain stale values from previous interactions that
    // no longer match the database (e.g. user unfollowed via profile page).
    _isFollowing = widget.initialIsFollowing;

    // Always seed/overwrite the cache with the server-provided state so that
    // the cache is up-to-date and sibling cards share the correct value.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      global.updateFollowState(widget.userId, widget.initialIsFollowing);
    });

    _followListener = () {
      final next = global.followStates.value[widget.userId];
      if (next != null && next != _isFollowing && mounted) {
        setState(() => _isFollowing = next);
      }
    };
    global.followStates.addListener(_followListener);
  }

  @override
  void didUpdateWidget(FollowCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.userId != widget.userId ||
        oldWidget.initialIsFollowing != widget.initialIsFollowing) {
      // When the parent rebuilds with fresh data, trust the server value again.
      setState(() {
        _isFollowing = widget.initialIsFollowing;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        GlobalNotifier.instance
            .updateFollowState(widget.userId, widget.initialIsFollowing);
      });
    }
  }

  @override
  void dispose() {
    GlobalNotifier.instance.followStates.removeListener(_followListener);
    super.dispose();
  }

  Future<String> _getMobile() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_phone') ?? '';
  }

  Future<void> _toggle() async {
    if (_isLoading || widget.userId.isEmpty) return;
    setState(() => _isLoading = true);
    try {
      final mobile = await _getMobile();
      final res = await http.post(
        Uri.parse(_socialApiCard),
        body: {
          'action': 'toggle_follow',
          'mobile_number': mobile,
          'target_user_id': widget.userId,
        },
      );
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        if (data['status'] == 'success') {
          final next = data['is_following'] == true;
          if (mounted) setState(() => _isFollowing = next);
          GlobalNotifier.instance.updateFollowState(widget.userId, next);
          GlobalNotifier.instance.adjustFollowing(next ? 1 : -1);
        }
      }
    } catch (e) {
      debugPrint('Follow toggle error: $e');
    }
    setState(() => _isLoading = false);
  }

  void _openProfile() {
    if (widget.userId.isEmpty) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PublicProfileScreen(userId: widget.userId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.cardType == CardType.trending) {
      return _buildTrending();
    } else {
      return _buildNearby();
    }
  }

  // ─── TRENDING CARD (vertical, 180px wide) ─────────────
  Widget _buildTrending() {
    final bool hasImg = widget.imageUrl != null && widget.imageUrl!.isNotEmpty;
    return GestureDetector(
      onTap: _openProfile,
      child: Container(
        width: 180,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              spreadRadius: 2,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(color: Colors.grey.shade100),
        ),
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(20),
                image: hasImg
                    ? DecorationImage(
                        image: NetworkImage(widget.imageUrl!),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: hasImg
                  ? null
                  : Icon(Icons.person, color: Colors.grey.shade400, size: 40),
            ),
            const SizedBox(height: 12),
            Column(
              children: [
                Text(
                  widget.name,
                  style: const TextStyle(
                    fontFamily: 'Google Sans',
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                    letterSpacing: -0.3,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  widget.role,
                  style: const TextStyle(
                    fontFamily: 'Google Sans',
                    fontSize: 12,
                    color: Color(0xFF616161),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (widget.location.isNotEmpty)
                  Text(
                    widget.location,
                    style: const TextStyle(
                      fontFamily: 'Google Sans',
                      fontSize: 11,
                      color: Color(0xFF9E9E9E),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
            const Spacer(),
            GestureDetector(
              onTap: _toggle,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 11),
                decoration: BoxDecoration(
                  color: _isFollowing ? Colors.white : Colors.black,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: _isFollowing ? Colors.grey.shade300 : Colors.black,
                  ),
                ),
                child: _isLoading
                    ? Center(
                        child: SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: _isFollowing ? Colors.black : Colors.white,
                          ),
                        ),
                      )
                    : Text(
                        _isFollowing ? 'Following' : 'Follow',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Google Sans',
                          color: _isFollowing ? Colors.black87 : Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── NEARBY CARD (horizontal, grid cell) ──────────────
  Widget _buildNearby() {
    final bool hasImg = widget.imageUrl != null && widget.imageUrl!.isNotEmpty;
    return GestureDetector(
      onTap: _openProfile,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
          border: Border.all(color: Colors.grey.shade100),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(12),
                image: hasImg
                    ? DecorationImage(
                        image: NetworkImage(widget.imageUrl!),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: hasImg
                  ? null
                  : Icon(Icons.person, color: Colors.grey.shade400),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    widget.name,
                    style: const TextStyle(
                      fontFamily: 'Google Sans',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    widget.role,
                    style: const TextStyle(
                      fontFamily: 'Google Sans',
                      fontSize: 11,
                      color: Color(0xFF616161),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            // Small follow icon button
            GestureDetector(
              onTap: _toggle,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: _isFollowing ? Colors.grey.shade100 : Colors.black,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: _isFollowing ? Colors.grey.shade300 : Colors.black,
                  ),
                ),
                child: _isLoading
                    ? Center(
                        child: SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(
                            strokeWidth: 1.5,
                            color: _isFollowing ? Colors.black : Colors.white,
                          ),
                        ),
                      )
                    : Icon(
                        _isFollowing ? Icons.check : Icons.person_add_alt_1,
                        size: 14,
                        color: _isFollowing ? Colors.black54 : Colors.white,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
