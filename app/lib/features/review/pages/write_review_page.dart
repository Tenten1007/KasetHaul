import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/config/app_config.dart';
import '../../../core/repositories/repositories.dart';
import '../../../shared/bloc/member_lookup_bloc.dart';
import '../bloc/review_bloc.dart';

class WriteReviewPage extends StatelessWidget {
  final String jobId;
  final String reviewerClientId;
  final String revieweeContractorId;
  final String jobTitle;

  const WriteReviewPage({
    super.key,
    required this.jobId,
    required this.reviewerClientId,
    required this.revieweeContractorId,
    required this.jobTitle,
  });

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
            create: (_) => ReviewBloc(reviewRepository: ReviewRepository())),
        BlocProvider(
            create: (_) =>
                MemberLookupBloc()..add(LookupContractor(revieweeContractorId))),
      ],
      child: _WriteReviewView(
        jobId: jobId,
        reviewerClientId: reviewerClientId,
        revieweeContractorId: revieweeContractorId,
        jobTitle: jobTitle,
      ),
    );
  }
}

class _WriteReviewView extends StatefulWidget {
  final String jobId;
  final String reviewerClientId;
  final String revieweeContractorId;
  final String jobTitle;

  const _WriteReviewView({
    required this.jobId,
    required this.reviewerClientId,
    required this.revieweeContractorId,
    required this.jobTitle,
  });

  @override
  State<_WriteReviewView> createState() => _WriteReviewViewState();
}

class _WriteReviewViewState extends State<_WriteReviewView> {
  int _selectedRating = 0;
  final _commentController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final Set<String> _selectedTags = {};

  static const _starLabels = [
    '', 'แย่มาก', 'ไม่ค่อยดี', 'พอใช้', 'ดี', 'ยอดเยี่ยม!'
  ];
  static const _quickTags = [
    'มาตรงเวลา',
    'ขับรถนิ่ม',
    'สุภาพ',
    'ดูแลสินค้าดี',
    'ช่วยยกของ',
    'สื่อสารดี',
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
          SubmitReviewEvent(
            jobId: widget.jobId,
            reviewerClientId: widget.reviewerClientId,
            revieweeContractorId: widget.revieweeContractorId,
            rating: _selectedRating,
            comment: _commentController.text.trim().isEmpty
                ? null
                : _commentController.text.trim(),
            quickTags: _selectedTags.toList(),
          ),
        );
  }

  Widget _buildHeroCard() {
    // ชื่อผู้รับจ้างจาก MemberLookupBloc (rebuild เมื่อโหลดเสร็จ)
    final c = context.watch<MemberLookupBloc>().state.contractor;
    final name = c != null
        ? '${c.member.prefix ?? ''}${c.member.firstName} ${c.member.lastName}'
            .trim()
        : 'ผู้รับจ้าง';
    final initial = name.isNotEmpty ? name.characters.first : '?';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
              color: Color(0x1A000000), blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              color: const Color(0xFFF57C00),
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Text(initial,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 44,
                    fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 12),
          Text(name,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF212121))),
          const SizedBox(height: 4),
          Text('งาน: ${widget.jobTitle}',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: Color(0xFF9E9E9E))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ReviewBloc, ReviewState>(
      listener: (context, state) {
        if (state is ReviewSubmitted) {
          Navigator.of(context).pop();
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
          title: const Text('รีวิวผู้รับจ้าง'),
          elevation: 0,
        ),
        body: BlocBuilder<ReviewBloc, ReviewState>(
          builder: (context, state) {
            final isLoading = state is ReviewLoading;
            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Hero card: avatar ผู้รับจ้าง + ชื่อ + งานที่รีวิว
                    _buildHeroCard(),

                    const SizedBox(height: 24),

                    // Prompt
                    const Text(
                      'คุณให้คะแนนผู้รับจ้างนี้เท่าไหร่?',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppConfig.textPrimaryColor,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Stars row
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
                    const SizedBox(height: 10),

                    // Rating label (สีเขียวเมื่อเลือกแล้ว ตาม Mockup)
                    Center(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child: Text(
                          _selectedRating == 0
                              ? 'แตะดาวเพื่อให้คะแนน'
                              : _starLabels[_selectedRating],
                          key: ValueKey(_selectedRating),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: _selectedRating == 0
                                ? AppConfig.textHintColor
                                : AppConfig.primaryColor,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // สิ่งที่ประทับใจ (chips)
                    const Text(
                      'สิ่งที่ประทับใจ (เลือกได้หลายข้อ)',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF424242),
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
                                horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              color: selected
                                  ? AppConfig.primaryColor
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: selected
                                    ? AppConfig.primaryColor
                                    : const Color(0xFFBDBDBD),
                              ),
                            ),
                            child: Text(
                              selected ? '✓ $tag' : tag,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: selected
                                    ? Colors.white
                                    : const Color(0xFF424242),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),

                    // ความคิดเห็นเพิ่มเติม
                    const Text(
                      'ความคิดเห็นเพิ่มเติม',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF424242),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _commentController,
                      maxLines: 4,
                      maxLength: 300,
                      decoration: InputDecoration(
                        hintText:
                            'เช่น ขนส่งตรงเวลา ดูแลสินค้าดี น่าจ้างอีก...',
                        hintStyle: const TextStyle(
                          color: AppConfig.textHintColor,
                          fontSize: 14,
                        ),
                        filled: true,
                        fillColor: Colors.white,
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
                        counterStyle: const TextStyle(
                            fontSize: 12,
                            color: AppConfig.textSecondaryColor),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Submit button
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: isLoading ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppConfig.primaryColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: isLoading
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'ส่งรีวิว',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
