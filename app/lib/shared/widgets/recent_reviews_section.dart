import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/config/app_config.dart';
import '../../features/review/bloc/recent_reviews_bloc.dart';

export '../../features/review/bloc/recent_reviews_bloc.dart' show ReviewWithName;

/// section "รีวิวล่าสุด" (ตาม Mockup โปรไฟล์ผู้ว่าจ้าง/ผู้รับจ้าง)
/// แสดงรีวิวล่าสุดไม่เกิน [maxItems] รายการ + ปุ่ม "ดูทั้งหมด"
/// โหลดผ่าน RecentReviewsBloc — [isContractor] true = ผู้ถูกรีวิวเป็น contractor
class RecentReviewsSection extends StatelessWidget {
  final String revieweeId;
  final bool isContractor;
  final VoidCallback? onSeeAll;
  final int maxItems;

  const RecentReviewsSection({
    super.key,
    required this.revieweeId,
    required this.isContractor,
    this.onSeeAll,
    this.maxItems = 2,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => RecentReviewsBloc()
        ..add(LoadRecentReviews(
            revieweeId: revieweeId, isContractor: isContractor)),
      child: BlocBuilder<RecentReviewsBloc, RecentReviewsState>(
        builder: (context, state) {
          // ยังโหลดอยู่ / ไม่มีรีวิว → ไม่ต้องแสดง section
          if (state is! RecentReviewsLoaded || state.reviews.isEmpty) {
            return const SizedBox.shrink();
          }
          final shown = state.reviews.take(maxItems).toList();
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('รีวิวล่าสุด',
                      style: TextStyle(
                          fontSize: 15, fontWeight: FontWeight.bold)),
                  if (onSeeAll != null)
                    TextButton(
                      onPressed: onSeeAll,
                      style: TextButton.styleFrom(
                        foregroundColor: AppConfig.primaryColor,
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text('ดูทั้งหมด',
                          style: TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w600)),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              ...shown.map((e) => _RecentReviewCard(item: e)),
            ],
          );
        },
      ),
    );
  }
}

class _RecentReviewCard extends StatelessWidget {
  final ReviewWithName item;
  const _RecentReviewCard({required this.item});

  static const _months = [
    '', 'ม.ค.', 'ก.พ.', 'มี.ค.', 'เม.ย.', 'พ.ค.', 'มิ.ย.',
    'ก.ค.', 'ส.ค.', 'ก.ย.', 'ต.ค.', 'พ.ย.', 'ธ.ค.'
  ];

  String _fmtDate(DateTime dt) =>
      '${dt.day} ${_months[dt.month]} ${dt.year + 543}';

  // สีอวตารสุ่มจากชื่อ (คงที่ต่อชื่อ)
  Color _avatarColor(String name) {
    const palette = [
      Color(0xFF2E7D32),
      Color(0xFF1565C0),
      Color(0xFFE65100),
      Color(0xFF6A1B9A),
      Color(0xFF00838F),
    ];
    return palette[name.hashCode.abs() % palette.length];
  }

  @override
  Widget build(BuildContext context) {
    final r = item.review;
    final initial = item.reviewerName.isNotEmpty
        ? item.reviewerName.characters.first
        : '?';
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
              color: Color(0x1A000000), blurRadius: 8, offset: Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: _avatarColor(item.reviewerName),
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: Text(initial,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.reviewerName,
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w600)),
                    Text(_fmtDate(r.reviewDate),
                        style: const TextStyle(
                            fontSize: 12, color: Color(0xFF9E9E9E))),
                  ],
                ),
              ),
              Row(
                children: [
                  const Icon(Icons.star_rounded,
                      size: 18, color: Color(0xFFFFC107)),
                  const SizedBox(width: 2),
                  Text(r.ratingScore.toStringAsFixed(1),
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFF57C00))),
                ],
              ),
            ],
          ),
          if (r.reviewComment != null && r.reviewComment!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text('"${r.reviewComment!}"',
                style: const TextStyle(
                    fontSize: 14, color: Color(0xFF424242), height: 1.5)),
          ],
        ],
      ),
    );
  }
}
