import 'package:flutter/foundation.dart';

class GlobalNotifier {
  GlobalNotifier._();

  static final GlobalNotifier instance = GlobalNotifier._();

  final ValueNotifier<int> followersCount = ValueNotifier<int>(0);
  final ValueNotifier<int> followingCount = ValueNotifier<int>(0);
  final ValueNotifier<int> creditsBalance = ValueNotifier<int>(0);
  final ValueNotifier<Map<String, bool>> followStates =
      ValueNotifier<Map<String, bool>>(<String, bool>{});

  void updateFollowCounts({int? followers, int? following}) {
    if (followers != null) followersCount.value = followers;
    if (following != null) followingCount.value = following;
  }

  void updateCredits(int value) {
    creditsBalance.value = value;
  }

  void updateFollowState(String userId, bool isFollowing) {
    final updated = Map<String, bool>.from(followStates.value);
    updated[userId] = isFollowing;
    followStates.value = updated;
  }

  void adjustFollowing(int delta) {
    followingCount.value = (followingCount.value + delta).clamp(0, 1 << 30);
  }
}
