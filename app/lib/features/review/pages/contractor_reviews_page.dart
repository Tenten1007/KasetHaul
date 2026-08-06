import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/config/app_config.dart';
import '../../../core/repositories/repositories.dart';
import '../../../models/models.dart';
import '../bloc/review_bloc.dart';

class ContractorReviewsPage extends StatelessWidget {
  final String contractorId;

  const ContractorReviewsPage({super.key, required this.contractorId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ReviewBloc(reviewRepository: ReviewRepository())
        ..add(LoadReviewsEvent(contractorId)),
      child: _ContractorReviewsView(contractorId: contractorId),
    );
  }
}

class _ContractorReviewsView extends StatelessWidget {
  final String contractorId;
  const _ContractorReviewsView({required this.contractorId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConfig.surfaceColor,
      appBar: AppBar(
        backgroundColor: AppConfig.primaryColor,
        foregroundColor: Colors.white,
        title: const Text('รีวิวที่ได้รับ'),
        elevation: 0,
      ),
      body: BlocBuilder<ReviewBloc, ReviewState>(
        builder: (context, state) {
          if (state is ReviewLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is ReviewError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    state.message,
                    style:
                        const TextStyle(color: AppConfig.textSecondaryColor),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => context
                        .read<ReviewBloc>()
                        .add(LoadReviewsEvent(contractorId)),
                    child: const Text('ลองใหม่'),
                  ),
                ],
              ),
            );
          }
          if (state is ReviewsLoaded) {
            return _ReviewsContent(
              reviews: state.reviews,
              averageRating: state.averageRating,
            );
          }
          return const SizedBox();
        },
      ),
    );
  }
}

class _ReviewsContent extends StatefulWidget {
  final List<ReviewModel> reviews;
  final double averageRating;

  const _ReviewsContent({
    required this.reviews,
    required this.averageRating,
  });

  @override
  State<_ReviewsContent> createState() => _ReviewsContentState();
}

class _ReviewsContentState extends State<_ReviewsContent> {
  int _filterStar = 0; // 0 = ทั้งหมด, 5/4/3 = กรองตามดาว

  @override
  Widget build(BuildContext context) {
    final reviews = _filterStar == 0
        ? widget.reviews
        : widget.reviews
            .where((r) => r.ratingScore == _filterStar)
            .toList();
    final averageRating = widget.averageRating;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Summary card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(
                color: Color(0x1A000000),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // คะแนนเฉลี่ย (ซ้าย)
              Column(
                children: [
                  Text(
                    averageRating.toStringAsFixed(1),
                    style: const TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFF57C00),
                      height: 1,
                    ),
                  ),
                  const SizedBox(height: 6),
                  _StarDisplay(rating: averageRating, size: 20),
                  const SizedBox(height: 6),
                  Text(
                    '${widget.reviews.length} รีวิว',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppConfig.textSecondaryColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 20),
              // แถบสัดส่วนดาว 5→1 (ขวา) ตาม Mockup 11 จอ 4
              Expanded(child: _RatingBars(reviews: widget.reviews)),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Filter chips ตามดาว (Mockup 11 จอ 4)
        SizedBox(
          height: 36,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              for (final star in [0, 5, 4, 3])
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => setState(() => _filterStar = star),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: _filterStar == star
                            ? AppConfig.primaryColor
                            : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _filterStar == star
                              ? AppConfig.primaryColor
                              : const Color(0xFFE0E0E0),
                        ),
                      ),
                      child: Text(
                        star == 0 ? 'ทั้งหมด' : '$star ดาว',
                        style: TextStyle(
                          fontSize: 13,
                          color: _filterStar == star
                              ? Colors.white
                              : const Color(0xFF424242),
                          fontWeight: _filterStar == star
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        if (reviews.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Column(
                children: [
                  Text('⭐', style: TextStyle(fontSize: 64)),
                  SizedBox(height: 16),
                  Text(
                    'ยังไม่มีรีวิว',
                    style: TextStyle(
                      fontSize: 16,
                      color: AppConfig.textSecondaryColor,
                    ),
                  ),
                ],
              ),
            ),
          )
        else ...[
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 12),
            child: Text(
              'รีวิวทั้งหมด',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF424242),
              ),
            ),
          ),
          ...reviews.map((r) => _ReviewCard(review: r)),
        ],
      ],
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final ReviewModel review;
  const _ReviewCard({required this.review});

  String _formatDate(DateTime dt) {
    const months = [
      '',
      'ม.ค.',
      'ก.พ.',
      'มี.ค.',
      'เม.ย.',
      'พ.ค.',
      'มิ.ย.',
      'ก.ค.',
      'ส.ค.',
      'ก.ย.',
      'ต.ค.',
      'พ.ย.',
      'ธ.ค.',
    ];
    return '${dt.day} ${months[dt.month]} ${dt.year - 543 + 2500}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _StarDisplay(rating: review.ratingScore.toDouble(), size: 18),
              const Spacer(),
              Text(
                _formatDate(review.reviewDate),
                style: const TextStyle(
                  fontSize: 12,
                  color: AppConfig.textSecondaryColor,
                ),
              ),
            ],
          ),
          if (review.reviewComment != null &&
              review.reviewComment!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              review.reviewComment!,
              style: const TextStyle(
                fontSize: 14,
                color: AppConfig.textPrimaryColor,
                height: 1.5,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// แถบสัดส่วนคะแนน 5→1 ดาว (จำนวนรีวิวแต่ละดาว) — ตาม Mockup 11 จอ 4
class _RatingBars extends StatelessWidget {
  final List<ReviewModel> reviews;
  const _RatingBars({required this.reviews});

  @override
  Widget build(BuildContext context) {
    final total = reviews.length;
    final counts = <int, int>{for (var s = 1; s <= 5; s++) s: 0};
    for (final r in reviews) {
      final s = r.ratingScore.clamp(1, 5);
      counts[s] = (counts[s] ?? 0) + 1;
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var star = 5; star >= 1; star--)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              children: [
                SizedBox(
                  width: 10,
                  child: Text('$star',
                      style: const TextStyle(
                          fontSize: 12, color: Color(0xFF757575))),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: total == 0 ? 0 : (counts[star]! / total),
                      minHeight: 8,
                      backgroundColor: const Color(0xFFEEEEEE),
                      valueColor: const AlwaysStoppedAnimation(
                          Color(0xFFFFC107)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 22,
                  child: Text('${counts[star]}',
                      textAlign: TextAlign.end,
                      style: const TextStyle(
                          fontSize: 12, color: Color(0xFF757575))),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// Widget แสดงดาว — รองรับทศนิยม (เช่น 4.3 ดาว)
class _StarDisplay extends StatelessWidget {
  final double rating;
  final double size;

  const _StarDisplay({required this.rating, required this.size});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        final star = i + 1;
        IconData icon;
        if (star <= rating.floor()) {
          icon = Icons.star_rounded;
        } else if (star == rating.ceil() && rating % 1 >= 0.5) {
          icon = Icons.star_half_rounded;
        } else {
          icon = Icons.star_outline_rounded;
        }
        return Icon(icon, size: size, color: const Color(0xFFFFC107));
      }),
    );
  }
}
