import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/config/app_config.dart';
import '../../../models/job_model.dart';
import '../bloc/job_bloc.dart';
import '../bloc/job_event.dart';
import '../bloc/job_state.dart';

const _kCancelReasons = [
  'เปลี่ยนแผนการขนส่ง',
  'ไม่มีสินค้าพร้อมส่งแล้ว',
  'หาผู้รับจ้างได้เองแล้ว',
  'อื่นๆ',
];

class CancelJobPage extends StatefulWidget {
  final JobModel job;
  const CancelJobPage({super.key, required this.job});

  @override
  State<CancelJobPage> createState() => _CancelJobPageState();
}

class _CancelJobPageState extends State<CancelJobPage> {
  int _selectedReason = 0;
  final _noteCtrl = TextEditingController();

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  void _confirm() {
    final reason = _selectedReason < _kCancelReasons.length - 1
        ? _kCancelReasons[_selectedReason]
        : _noteCtrl.text.trim().isNotEmpty
            ? '${_kCancelReasons[_selectedReason]}: ${_noteCtrl.text.trim()}'
            : _kCancelReasons[_selectedReason];
    context.read<JobBloc>().add(CancelJobEvent(
          jobId: widget.job.jobId,
          cancelReason: reason,
          clientId: widget.job.clientId,
        ));
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<JobBloc, JobState>(
      listener: (context, state) {
        if (state is JobCancelled) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('ยกเลิกงานเรียบร้อย'),
              backgroundColor: Color(0xFF4CAF50),
            ),
          );
          Navigator.of(context).pop(true);
        } else if (state is JobError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message),
                backgroundColor: AppConfig.errorColor),
          );
        }
      },
      child: Scaffold(
        backgroundColor: AppConfig.surfaceColor,
        appBar: AppBar(
          backgroundColor: Colors.white,
          titleTextStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF212121)),
          elevation: 0,
          foregroundColor: const Color(0xFF212121),
          title: const Text('ยกเลิกงาน'),
          centerTitle: true,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Warning icon + title
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: const BoxDecoration(
                        color: Color(0xFFFFEBEE),
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Text('⚠️', style: TextStyle(fontSize: 40)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text('ต้องการยกเลิกงานนี้?',
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    const Text('กรุณาเลือกเหตุผลในการยกเลิก',
                        style: TextStyle(
                            fontSize: 14, color: Color(0xFF757575))),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // Job summary card
              _JobSummaryCard(job: widget.job),
              const SizedBox(height: 16),
              // Cancel reasons
              const Text('เหตุผลในการยกเลิก',
                  style: TextStyle(
                      fontSize: 15, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [
                    BoxShadow(
                        color: Color(0x1A000000),
                        blurRadius: 8,
                        offset: Offset(0, 2))
                  ],
                ),
                child: Column(
                  children: List.generate(_kCancelReasons.length, (i) {
                    final isLast = i == _kCancelReasons.length - 1;
                    return Column(
                      children: [
                        RadioListTile<int>(
                          value: i,
                          groupValue: _selectedReason,
                          onChanged: (v) =>
                              setState(() => _selectedReason = v!),
                          activeColor: AppConfig.primaryColor,
                          title: Text(_kCancelReasons[i],
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14)),
                          contentPadding:
                              const EdgeInsets.symmetric(horizontal: 16),
                        ),
                        if (!isLast)
                          const Divider(height: 1, indent: 16, endIndent: 16),
                      ],
                    );
                  }),
                ),
              ),
              const SizedBox(height: 16),
              // Additional note
              const Text('หมายเหตุเพิ่มเติม (ไม่บังคับ)',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF424242))),
              const SizedBox(height: 8),
              TextField(
                controller: _noteCtrl,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'ระบุรายละเอียดเพิ่มเติม...',
                  hintStyle: const TextStyle(color: Color(0xFFBDBDBD)),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.all(14),
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
                        color: AppConfig.primaryColor, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Refund policy
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3E0),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFFB74D)),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('💡', style: TextStyle(fontSize: 20)),
                    SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('เงื่อนไขการคืนเงิน',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFE65100),
                                  fontSize: 13)),
                          SizedBox(height: 4),
                          Text(
                            'หากยกเลิกก่อนมอบหมายงาน จะได้รับเงินคืนเต็มจำนวน '
                            'หากยกเลิกหลังมอบหมายงานแล้ว อาจมีค่าธรรมเนียมการยกเลิก',
                            style: TextStyle(
                                fontSize: 12, color: Color(0xFF757575)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // Action buttons
              BlocBuilder<JobBloc, JobState>(
                builder: (context, state) {
                  final loading = state is JobLoading;
                  return Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: loading ? null : _confirm,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppConfig.errorColor,
                            foregroundColor: Colors.white,
                            padding:
                                const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            elevation: 0,
                          ),
                          child: loading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                      color: Colors.white, strokeWidth: 2))
                              : const Text('ยืนยันยกเลิกงาน',
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600)),
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF424242),
                            side: const BorderSide(
                                color: Color(0xFFBDBDBD)),
                            padding:
                                const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('ไม่ยกเลิก',
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600)),
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _JobSummaryCard extends StatelessWidget {
  final JobModel job;
  const _JobSummaryCard({required this.job});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF9F9F9),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
              color: Color(0x1A000000), blurRadius: 8, offset: Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(job.jobTitle,
              style: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Row(
            children: [
              const _RouteDot(isStart: true),
              const SizedBox(width: 8),
              Expanded(
                child: Text(job.pickupAddress,
                    style: const TextStyle(fontSize: 13),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(left: 6),
            child: Container(width: 2, height: 12, color: const Color(0xFFBDBDBD)),
          ),
          Row(
            children: [
              const _RouteDot(isStart: false),
              const SizedBox(width: 8),
              Expanded(
                child: Text(job.dropoffAddress,
                    style: const TextStyle(fontSize: 13),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('งบประมาณ',
                  style: TextStyle(fontSize: 13, color: Color(0xFF757575))),
              Text(
                '${job.budgetPrice.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')} บาท',
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RouteDot extends StatelessWidget {
  final bool isStart;
  const _RouteDot({required this.isStart});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 14,
      height: 14,
      decoration: BoxDecoration(
        color: isStart ? AppConfig.primaryColor : AppConfig.errorColor,
        shape: BoxShape.circle,
      ),
    );
  }
}


