import 'package:flutter/material.dart';

class RentalsScreen extends StatefulWidget {
  const RentalsScreen({super.key});

  @override
  State<RentalsScreen> createState() => _RentalsScreenState();
}

class _RentalsScreenState extends State<RentalsScreen> {
  int _selectedTab = 0; // 0 = Equipment, 1 = Costumes

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 16),
          // Segmented Toggle
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedTab = 0),
                      child: Container(
                        decoration: BoxDecoration(
                          color: _selectedTab == 0 ? Colors.black : Colors.transparent,
                          borderRadius: BorderRadius.circular(30),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'Equipment',
                          style: TextStyle(
                            fontFamily: 'Google Sans',
                            fontWeight: FontWeight.w600,
                            color: _selectedTab == 0 ? Colors.white : Colors.black87,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedTab = 1),
                      child: Container(
                        decoration: BoxDecoration(
                          color: _selectedTab == 1 ? Colors.black : Colors.transparent,
                          borderRadius: BorderRadius.circular(30),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'Costumes',
                          style: TextStyle(
                            fontFamily: 'Google Sans',
                            fontWeight: FontWeight.w600,
                            color: _selectedTab == 1 ? Colors.white : Colors.black87,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _selectedTab == 0 ? _buildEquipmentView() : _buildCostumesView(),
          ),
        ],
      ),
    );
  }

  Widget _buildEquipmentView() {
    final equipments = [
      {
        'title': 'ARRI Alexa Mini Kit',
        'price': '\$450/day',
        'location': 'Hollywood, CA',
        'status': 'Available',
      },
      {
        'title': 'Aputure 300d II LED Panel',
        'price': '\$75/day',
        'location': 'Burbank, CA',
        'status': 'Available',
      },
      {
        'title': 'Sennheiser MKH 416 Boom Mic',
        'price': '\$40/day',
        'location': 'New York, NY',
        'status': 'In Stock',
      },
      {
        'title': 'Sachtler V20 Tripod',
        'price': '\$120/day',
        'location': 'Los Angeles, CA',
        'status': 'Available',
      },
      {
        'title': 'DJI Ronin 2 Gimbal',
        'price': '\$300/day',
        'location': 'Atlanta, GA',
        'status': 'Available',
      },
    ];

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Rent Equipment',
                  style: TextStyle(
                    fontFamily: 'Google Sans',
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                    letterSpacing: -0.5,
                  ),
                ),
                Icon(Icons.search, size: 28, color: Colors.black),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Search Field
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: const TextField(
                decoration: InputDecoration(
                  hintText: 'Search equipment',
                  hintStyle: TextStyle(fontFamily: 'Google Sans', color: Colors.grey),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Horizontal Pills
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Row(
              children: [
                _buildFilterPill('Camera'),
                const SizedBox(width: 8),
                _buildFilterPill('Lighting'),
                const SizedBox(width: 8),
                _buildFilterPill('Audio'),
                const SizedBox(width: 8),
                _buildFilterPill('Grip'),
                const SizedBox(width: 8),
                _buildFilterPill('Lenses'),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // List Items
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            itemCount: equipments.length,
            itemBuilder: (context, index) {
              final eq = equipments[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.camera_alt, color: Colors.grey, size: 32),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            eq['title']!,
                            style: const TextStyle(
                              fontFamily: 'Google Sans',
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            eq['price']!,
                            style: const TextStyle(
                              fontFamily: 'Google Sans',
                              fontSize: 14,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Location: ${eq['location']}',
                            style: TextStyle(
                              fontFamily: 'Google Sans',
                              fontSize: 13,
                              color: Colors.grey.shade700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Status: ${eq['status']}',
                            style: TextStyle(
                              fontFamily: 'Google Sans',
                              fontSize: 13,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'Rent Now',
                        style: TextStyle(
                          fontFamily: 'Google Sans',
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildCostumesView() {
    final costumes = [
      {
        'title': 'Period Drama Outfit',
        'size': 'S, M, L',
        'price': '\$120/day',
        'deposit': '\$300',
      },
      {
        'title': 'Police Uniform Set',
        'size': 'M, L, XL',
        'price': '\$85/day',
        'deposit': '\$200',
      },
      {
        'title': 'Red Carpet Suit',
        'size': 'M, L',
        'price': '\$150/day',
        'deposit': '\$400',
      },
      {
        'title': 'Traditional Costume Pack',
        'size': 'Various',
        'price': '\$90/day',
        'deposit': '\$250',
      },
    ];

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.0),
            child: Text(
              'Rent Costumes',
              style: TextStyle(
                fontFamily: 'Google Sans',
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.black,
                letterSpacing: -0.5,
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Horizontal Pills
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Row(
              children: [
                _buildFilterPill('Men', isBordered: true),
                const SizedBox(width: 8),
                _buildFilterPill('Women', isBordered: true),
                const SizedBox(width: 8),
                _buildFilterPill('Period', isBordered: true),
                const SizedBox(width: 8),
                _buildFilterPill('Action', isBordered: true),
                const SizedBox(width: 8),
                _buildFilterPill('Formal', isBordered: true),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.0),
            child: Text(
              'Popular this week',
              style: TextStyle(
                fontFamily: 'Google Sans',
                fontSize: 18,
                color: Colors.black,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.7,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: costumes.length,
              itemBuilder: (context, index) {
                final cos = costumes[index];
                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        height: 100,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(
                          child: Icon(Icons.checkroom, color: Colors.grey, size: 40),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        cos['title']!,
                        style: const TextStyle(
                          fontFamily: 'Google Sans',
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'Size: ${cos['size']}',
                        style: const TextStyle(
                          fontFamily: 'Google Sans',
                          fontSize: 12,
                          color: Colors.black87,
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            cos['price']!,
                            style: const TextStyle(
                              fontFamily: 'Google Sans',
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            'Deposit: ${cos['deposit']}',
                            style: TextStyle(
                              fontFamily: 'Google Sans',
                              fontSize: 11,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'View Details',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'Google Sans',
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildFilterPill(String text, {bool isBordered = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isBordered ? Colors.white : Colors.grey.shade200,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isBordered ? Colors.black : Colors.transparent),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontFamily: 'Google Sans',
          fontSize: 14,
          color: Colors.black,
        ),
      ),
    );
  }
}
