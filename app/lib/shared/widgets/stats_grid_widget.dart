import 'package:flutter/material.dart';
import '../../core/config/app_config.dart';

class StatsGridWidget extends StatelessWidget {
  final List<StatItem> items;

  const StatsGridWidget({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    // ใช้ 4 cols เมื่อมี >= 4 items (Mockup spec: ⭐ งาน ✓ รีวิว)
    final cols = items.length >= 4 ? 4 : 2;
    return GridView.count(
      crossAxisCount: cols,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 8,
      mainAxisSpacing: 8,
      childAspectRatio: cols == 4 ? 0.9 : 1.8,
      children: items.map((item) => _StatCard(item: item)).toList(),
    );
  }
}

class _StatCard extends StatelessWidget {
  final StatItem item;
  const _StatCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Color(0x1A000000), blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              item.value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: item.valueColor ?? AppConfig.primaryColor,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            item.label,
            style: const TextStyle(fontSize: 11, color: Color(0xFF9E9E9E)),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class StatItem {
  final String value;
  final String label;
  final Color? valueColor;

  const StatItem({
    required this.value,
    required this.label,
    this.valueColor,
  });
}
