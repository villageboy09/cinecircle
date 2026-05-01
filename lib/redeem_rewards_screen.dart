import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

const _redeemApiBase = 'https://team.cropsync.in/cine_circle/trivia_api.php';

const _tabs = ['Merchandise', 'Movie Tickets', 'Event Passes', 'Fan Drops', 'Premium'];

// Maps icon_name from DB to Flutter IconData
const _iconMap = {
  'checkroom': Icons.checkroom,
  'collections': Icons.collections,
  'local_activity': Icons.local_activity,
  'badge': Icons.badge,
  'ondemand_video': Icons.ondemand_video,
  'people': Icons.people,
  'star': Icons.star,
  'card_giftcard': Icons.card_giftcard,
  'movie': Icons.movie,
  'festival': Icons.festival,
};

class RedeemRewardsScreen extends StatefulWidget {
  final int balance;
  const RedeemRewardsScreen({super.key, this.balance = 0});

  @override
  State<RedeemRewardsScreen> createState() => _RedeemRewardsScreenState();
}

class _RedeemRewardsScreenState extends State<RedeemRewardsScreen> {
  int _selectedTab = 0;
  bool _isLoading = true;
  List<dynamic> _items = [];
  int _balance = 0;

  @override
  void initState() {
    super.initState();
    _balance = widget.balance;
    _fetchItems();
  }

  Future<String> _getMobile() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_phone') ?? '';
  }

  Future<void> _fetchItems() async {
    setState(() => _isLoading = true);
    try {
      final mobile = await _getMobile();
      final tab = Uri.encodeComponent(_tabs[_selectedTab]);
      final res = await http.get(
        Uri.parse('$_redeemApiBase?action=get_reward_items&mobile_number=$mobile&tab=$tab'),
      );
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        if (data['status'] == 'success') {
          setState(() {
            _items = data['data'] ?? [];
            _balance = data['balance'] ?? _balance;
          });
        }
      }
    } catch (e) {
      debugPrint('fetchItems error: $e');
    }
    setState(() => _isLoading = false);
  }

  Future<void> _redeemItem(Map<String, dynamic> item) async {
    final cost = int.tryParse(item['credits_cost'].toString()) ?? 0;
    final title = item['title'] ?? 'this item';

    // Confirm dialog
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),
            const Icon(Icons.redeem_rounded, size: 48, color: Colors.black),
            const SizedBox(height: 16),
            Text('Redeem "$title"?',
                textAlign: TextAlign.center,
                style: const TextStyle(fontFamily: 'Google Sans', fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('This will deduct $cost credits from your balance.',
                textAlign: TextAlign.center,
                style: TextStyle(fontFamily: 'Google Sans', fontSize: 14, color: Colors.grey.shade600)),
            const SizedBox(height: 8),
            Text('Current balance: $_balance credits',
                style: const TextStyle(fontFamily: 'Google Sans', fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(height: 24),
            Row(children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.black),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    minimumSize: const Size(0, 50),
                  ),
                  child: const Text('Cancel', style: TextStyle(fontFamily: 'Google Sans', color: Colors.black)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    minimumSize: const Size(0, 50),
                  ),
                  child: const Text('Confirm', style: TextStyle(fontFamily: 'Google Sans', fontWeight: FontWeight.w600)),
                ),
              ),
            ]),
          ],
        ),
      ),
    );

    if (confirmed != true) return;

    try {
      final mobile = await _getMobile();
      final res = await http.post(
        Uri.parse(_redeemApiBase),
        body: {
          'action': 'redeem_item',
          'mobile_number': mobile,
          'item_id': item['id'].toString(),
        },
      );
      if (res.statusCode == 200) {
        final data = json.decode(res.body);

        if (data['status'] == 'success') {
          setState(() => _balance = data['new_balance'] ?? _balance);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Redeemed successfully! ­ƒÄë', style: TextStyle(fontFamily: 'Google Sans')),
                backgroundColor: Colors.green.shade700,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            );
          }
          await _fetchItems(); // Refresh to show updated stock counts
        } else if (data['status'] == 'out_of_stock') {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Sorry, this item is out of stock.', style: TextStyle(fontFamily: 'Google Sans')),
                backgroundColor: Colors.orange.shade700,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            );
          }
          await _fetchItems();
        } else if (data['status'] == 'insufficient_credits') {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Not enough credits. Need ${data['required']} but you have ${data['balance']}.',
                  style: const TextStyle(fontFamily: 'Google Sans'),
                ),
                backgroundColor: Colors.red.shade700,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            );
          }
        }
      }
    } catch (e) {
      debugPrint('redeemItem error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset('assets/cinelogo.png', height: 24, fit: BoxFit.contain),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                const Icon(Icons.copyright, size: 16, color: Colors.white),
                const SizedBox(width: 6),
                Text(
                  '$_balance Credits',
                  style: const TextStyle(
                    fontFamily: 'Google Sans',
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: Text('Redeem Rewards',
                  style: TextStyle(fontFamily: 'Google Sans', fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black, letterSpacing: -0.5)),
            ),
            // Tab Bar
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Row(
                children: _tabs.asMap().entries.map((e) {
                  final isSelected = e.key == _selectedTab;
                  return GestureDetector(
                    onTap: () {
                      setState(() => _selectedTab = e.key);
                      _fetchItems();
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.only(right: 20),
                      padding: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        border: Border(bottom: BorderSide(
                          color: isSelected ? Colors.black : Colors.transparent,
                          width: 3,
                        )),
                      ),
                      child: Text(
                        e.value,
                        style: TextStyle(
                          fontFamily: 'Google Sans',
                          fontSize: 15,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                          color: isSelected ? Colors.black : Colors.grey.shade600,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.purple.shade50.withValues(alpha: 0.4), Colors.white],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: const [0.0, 0.3],
                  ),
                ),
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator(color: Colors.black))
                    : RefreshIndicator(
                        color: Colors.black,
                        onRefresh: _fetchItems,
                        child: ListView(
                          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                          children: [
                            // Info Banner
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: const Text(
                                'Use credits on merchandise, movie tickets, and industry events',
                                style: TextStyle(fontFamily: 'Google Sans', fontSize: 16, color: Colors.black87, height: 1.4),
                              ),
                            ),
                            const SizedBox(height: 20),
                            if (_items.isEmpty)
                              Center(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 48),
                                  child: Column(
                                    children: [
                                      Icon(Icons.inbox_outlined, size: 56, color: Colors.grey.shade300),
                                      const SizedBox(height: 12),
                                      Text('No items available in this category.',
                                          style: TextStyle(fontFamily: 'Google Sans', color: Colors.grey.shade500)),
                                    ],
                                  ),
                                ),
                              )
                            else
                              ..._items.map((item) => _buildRewardItem(item)),
                            const SizedBox(height: 32),
                          ],
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRewardItem(Map<String, dynamic> item) {
    final cost = int.tryParse(item['credits_cost'].toString()) ?? 0;
    final canAfford = _balance >= cost;
    final hasImage = item['image_url'] != null && (item['image_url'] as String).isNotEmpty;
    final iconData = _iconMap[item['icon_name']] ?? Icons.card_giftcard;
    final stockQty = item['stock_quantity']; // null = unlimited, int = finite
    final isOutOfStock = stockQty != null && int.tryParse(stockQty.toString()) == 0;
    final isLowStock = stockQty != null && (int.tryParse(stockQty.toString()) ?? 99) <= 5 && !isOutOfStock;
    final canRedeem = canAfford && !isOutOfStock;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Optional image banner
          if (hasImage)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: Image.network(
                item['image_url'],
                height: 130,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const SizedBox.shrink(),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Icon or placeholder if no image
                if (!hasImage)
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(12)),
                    child: Icon(iconData, size: 32, color: Colors.black87),
                  ),
                if (!hasImage) const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item['title'] ?? '',
                          style: const TextStyle(fontFamily: 'Google Sans', fontSize: 15, fontWeight: FontWeight.w600, color: Colors.black)),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            '$cost Credits',
                            style: TextStyle(fontFamily: 'Google Sans', fontSize: 13,
                                color: canAfford ? Colors.black87 : Colors.red.shade400, fontWeight: FontWeight.w500),
                          ),
                          if (item['stock_label'] != null && (item['stock_label'] as String).isNotEmpty) ...[
                            const SizedBox(width: 6),
                            const Text('\u2022', style: TextStyle(color: Colors.grey, fontSize: 10)),
                            const SizedBox(width: 6),
                            Text(item['stock_label'],
                                style: TextStyle(fontFamily: 'Google Sans', fontSize: 12, color: Colors.grey.shade600)),
                          ],
                          // Low/Out stock badges
                          if (isOutOfStock) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.red.shade50,
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: Colors.red.shade100),
                              ),
                              child: Text('OUT OF STOCK',
                                  style: TextStyle(
                                    fontFamily: 'Google Sans',
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.red.shade700,
                                  )),
                            ),
                          ] else if (isLowStock) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.orange.shade50,
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: Colors.orange.shade100),
                              ),
                              child: Text('ONLY $stockQty LEFT!',
                                  style: TextStyle(
                                    fontFamily: 'Google Sans',
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.orange.shade700,
                                  )),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: canRedeem ? () => _redeemItem(item) : null,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: isOutOfStock
                          ? Colors.grey.shade200
                          : canAfford ? Colors.black : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      isOutOfStock ? 'Sold Out' : canAfford ? 'Redeem' : 'Need more',
                      style: TextStyle(
                        fontFamily: 'Google Sans',
                        color: isOutOfStock
                            ? Colors.grey.shade400
                            : canAfford ? Colors.white : Colors.grey.shade600,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
