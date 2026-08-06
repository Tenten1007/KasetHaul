import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/config/app_config.dart';
import '../../../core/repositories/repositories.dart';
import '../bloc/review_bloc.dart';

class ReviewClientPage extends StatelessWidget {
  final String jobId;
  final String reviewerContractorId;
  final String revieweeClientId;
  final String jobTitle;

  const ReviewClientPage({
    super.key,
    required this.jobId,
    required this.reviewerContractorId,
    required this.revieweeClientId,
    required this.jobTitle,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ReviewBloc(reviewRepository: ReviewRepository()),
      child: _ReviewClientView(
        jobId: jobId,
        reviewerContractorId: reviewerContractorId,
        revieweeClientId: revieweeClientId,
        jobTitle: jobTitle,
      ),
    );
  }
}

class _ReviewClientView extends StatefulWidget {
  final String jobId;
  final String reviewerContractorId;
  final String revieweeClientId;
  final String jobTitle;

  const _ReviewClientView({
    required this.jobId,
    required this.reviewerContractorId,
    required this.revieweeClientId,
    required this.jobTitle,
  });

  @override
  State<_ReviewClientView> createState() => _ReviewClientViewState();
}

class _ReviewClientViewState extends State<_ReviewClientView> {
  int _selectedRating = 0;
  final _commentController = TextEditingController();
  final Set<String> _selectedTags = {};

  static const _starLabels = [
    '', 'แย่มาก', 'ไม่ค่อยดี', 'พอใช้', 'ดี', 'ยอดเยี่ยม!'
  ];

  // ตาม Mockup 07 จอ 6 — สิ่งที่ประทับใจในตัวผู้ว่าจ้าง
  static const _quickTags = [
    'ของพร้อม',
    'สื่อสารดี',
    'จ่ายไว',
    'สถานที่หาง่าย',
  ];

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_selectedRating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณาเลือกคะแนนดาว')),
      );
      return;
    }
    context.read<ReviewBloc>().add(
          SubmitContractorReviewEvent(
            jobId: widget.jobId,
            reviewerContractorId: widget.reviewerContractorId,
            revieweeClientId: widget.revieweeClientId,
            rating: _selectedRating,
            comment: _commentController.text.trim().isEmpty
                ? null
                : _commentController.text.trim(),
            quickTags: _selectedTags.toList(),
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ReviewBloc, ReviewState>(
      listener: (context, state) {
        if (state is ReviewSubmitted) {
          Navigator.of(context).pop(true);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('ขอบคุณสำหรับรีวิว'),
              backgroundColor: AppConfig.primaryColor,
            ),
          );
        } else if (state is ReviewError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppConfig.errorColor,
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor: AppConfig.surfaceColor,
        appBar: AppBar(
          backgroundColor: AppConfig.primaryColor,
          foregroundColor: Colors.white,
          title: const Text('รีวิวลูกค้า'),
          elevation: 0,
        ),
        body: BlocBuilder<ReviewBloc, ReviewState>(
          builder: (context, state) {
            final isLoading = state is ReviewLoading;
            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Job info card
                  Container(
                    width: double.infinity,
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
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8F5E9),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.business_center_outlined,
                            color: AppConfig.primaryColor,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'งานที่รีวิว',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppConfig.textSecondaryColor,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                widget.jobTitle,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: AppConfig.textPrimaryColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Star rating
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
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
                      children: [
                        const Text(
                          'ให้คะแนนโดยรวม',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(5, (index) {
                            final star = index + 1;
                            return GestureDetector(
                              onTap: () =>
                                  setState(() => _selectedRating = star),
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 6),
                                child: Icon(
                                  star <= _selectedRating
                                      ? Icons.star_rounded
                                      : Icons.star_outline_rounded,
                                  size: 48,
                                  color: star <= _selectedRating
                                      ? const Color(0xFFFFC107)
                                      : const Color(0xFFBDBDBD),
                                ),
                              ),
                            );
                          }),
                        ),
                        const SizedBox(height: 12),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          child: Text(
                            _selectedRating == 0
                                ? 'แตะดาวเพื่อให้คะแนน'
                                : _starLabels[_selectedRating],
                            key: ValueKey(_selectedRating),
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: _selectedRating == 0
                                  ? AppConfig.textHintColor
                                  : const Color(0xFFFFC107),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Quick tags — สิ่งที่ประทับใจ (เลือกได้หลายข้อ)
                  Container(
                    width: double.infinity,
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
                        const Text(
                          'สิ่งที่ประทับใจ (เลือกได้หลายข้อ)',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: AppConfig.textSecondaryColor,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _quickTags.map((tag) {
                            final selected = _selectedTags.contains(tag);
                            return GestureDetector(
                              onTap: () => setState(() {
                                if (selected) {
                                  _selectedTags.remove(tag);
                                } else {
                                  _selectedTags.add(tag);
                                }
                              }),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 8),
                                decoration: BoxDecoration(
                                  color: selected
                                      ? AppConfig.primaryColor
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: selected
                                        ? AppConfig.primaryColor
                                        : const Color(0xFFBDBDBD),
                                  ),
                                ),
                                child: Text(
                                  selected ? '✓ $tag' : tag,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: selected
                                        ? Colors.white
                                        : const Color(0xFF616161),
                                    fontWeight: selected
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Comment
                  Container(
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
                        const Text(
                          'ความคิดเห็น (ไม่บังคับ)',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: AppConfig.textSecondaryColor,
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _commentController,
                          maxLines: 4,
                          maxLength: 300,
                          decoration: InputDecoration(
                            hintText: 'เช่น ให้ข้อมูลครบถ้วน ชำระเงินตรงเวลา...',
                            hintStyle: const TextStyle(
                                color: AppConfig.textHintColor, fontSize: 14),
                            filled: true,
                            fillColor: const Color(0xFFFAFAFA),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide:
                                  const BorderSide(color: Color(0xFFE0E0E0)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide:
                                  const BorderSide(color: Color(0xFFE0E0E0)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                  color: AppConfig.primaryColor),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppConfig.primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2.5, color: Colors.white),
                            )
                          : const Text('ส่งรีวิว',
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
