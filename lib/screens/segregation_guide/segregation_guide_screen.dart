import 'package:flutter/material.dart';

class SegregationGuideScreen extends StatelessWidget {
  const SegregationGuideScreen({super.key});

  static const _green = Color(0xFF015704);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8F8),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 3,
        iconTheme: const IconThemeData(color: _green),
        title: const Text(
          'Segregation Guide',
          style: TextStyle(
            color: _green,
            fontWeight: FontWeight.w800,
            fontSize: 20,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
        children: [
          _buildIntroCard(),
          const SizedBox(height: 16),
          _buildWasteCard(
            icon: Icons.soup_kitchen_rounded,
            iconColor: Colors.brown.shade600,
            title: 'Kitchen Waste',
            description:
                'Waste generated during food preparation before cooking. '
                'This includes raw materials that are discarded or unusable.',
            examples: const [
              'Vegetable peels and trimmings',
              'Raw food scraps',
              'Spoiled or expired ingredients',
              'Preparation waste (bones, shells, seeds)',
            ],
          ),
          const SizedBox(height: 16),
          _buildWasteCard(
            icon: Icons.restaurant_rounded,
            iconColor: Colors.orange.shade700,
            title: 'Food Waste',
            description:
                'Cooked or prepared food that was not consumed or sold. '
                'Proper segregation helps track overproduction and reduce losses.',
            examples: const [
              'Leftover cooked food',
              'Unsold meals at end of service',
              'Expired prepared food items',
              'Spoiled ready-to-eat products',
            ],
          ),
          const SizedBox(height: 16),
          _buildWasteCard(
            icon: Icons.people_rounded,
            iconColor: Colors.teal.shade600,
            title: 'Customer Waste',
            description:
                'Waste from dining customers after meals are served. '
                'This helps measure portion appropriateness and packaging impact.',
            examples: const [
              'Plate leftovers and uneaten food',
              'Used napkins and paper products',
              'Disposable food containers and cups',
              'Single-use utensils and straws',
            ],
          ),
          const SizedBox(height: 24),
          _buildReminderCard(),
        ],
      ),
    );
  }

  Widget _buildIntroCard() {
    return Container(
      decoration: BoxDecoration(
        color: _green,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4)),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.menu_book_rounded,
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Waste Classification',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 17,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Learn how to properly sort and classify waste from your restaurant.',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWasteCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String description,
    required List<String> examples,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4)),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 26),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  color: _green,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            description,
            style: const TextStyle(
              color: Colors.black87,
              fontSize: 13.5,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Examples:',
            style: TextStyle(
              color: _green,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 6),
          ...examples.map(
            (e) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 5),
                    child: Icon(
                      Icons.circle,
                      color: _green,
                      size: 6,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      e,
                      style: const TextStyle(
                        color: Colors.black87,
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReminderCard() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _green.withOpacity(0.3), width: 1.2),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline_rounded, color: _green, size: 22),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Proper segregation improves waste collection accuracy and analytics reporting.',
              style: TextStyle(
                color: _green,
                fontWeight: FontWeight.w600,
                fontSize: 13.5,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
