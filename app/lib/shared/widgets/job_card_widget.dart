import 'package:flutter/material.dart';
import '../../core/config/app_config.dart';
import '../../models/models.dart';
import 'job_route_widget.dart';
import 'status_badge_widget.dart';

class JobCardWidget extends StatelessWidget {
  final JobModel job;
  final int? biddingCount;
  final VoidCallback? onTap;
  final VoidCallback? onViewDetail;
  final VoidCallback? onViewBiddings;

  const JobCardWidget({
    super.key,
    required this.job,
    this.biddingCount,
    this.onTap,
    this.onViewDetail,
    this.onViewBiddings,
  });

  String _formatPrice(num price) {
    return price
        .toStringAsFixed(0)
        .replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');
  }

  String _formatDate(DateTime dt) {
    const months = [
      '', 'ม.ค.', 'ก.พ.', 'มี.ค.', 'เม.ย.', 'พ.ค.', 'มิ.ย.',
      'ก.ค.', 'ส.ค.', 'ก.ย.', 'ต.ค.', 'พ.ย.', 'ธ.ค.'
    ];
    return '${dt.day} ${months[dt.month]} ${dt.year - 543 + 2500}';
  }

  bool get _hasBiddings => (biddingCount ?? 0) > 0;
  bool get _isOpen => job.jobStatus == 'รอผู้รับจ้าง';

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: ValueKey('job_card_${job.jobId}'),
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(color: Color(0x1A000000), blurRadius: 8, offset: Offset(0, 2)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        job.jobTitle,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF212121),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        job.productType,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppConfig.primaryColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                StatusBadgeWidget(status: job.jobStatus),
              ],
            ),

            const SizedBox(height: 12),

            // Route
            JobRouteWidget(
              from: job.pickupAddress.length > 20
                  ? job.pickupAddress.substring(0, 20)
                  : job.pickupAddress,
              to: job.dropoffAddress.length > 20
                  ? job.dropoffAddress.substring(0, 20)
                  : job.dropoffAddress,
            ),

            const SizedBox(height: 10),

            // Details row
            Row(
              children: [
                if (job.distance != null) ...[
                  Text(
                    '${job.distance!.toStringAsFixed(0)} กม.',
                    style: const TextStyle(fontSize: 13, color: Color(0xFF757575)),
                  ),
                  const SizedBox(width: 16),
                ],
                Text(
                  _formatDate(job.pickupDatetime),
                  style: const TextStyle(fontSize: 13, color: Color(0xFF757575)),
                ),
                const SizedBox(width: 16),
                if (_isOpen && biddingCount != null)
                  Text(
                    biddingCount == 0 ? 'ยังไม่มีคนเสนอ' : '$biddingCount คนเสนอ',
                    style: TextStyle(
                      fontSize: 13,
                      color: biddingCount == 0
                          ? const Color(0xFF757575)
                          : AppConfig.primaryColor,
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 12),

            // Price + Actions
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      job.agreedPrice != null ? 'ราคาตกลง' : 'งบประมาณ',
                      style: const TextStyle(fontSize: 12, color: Color(0xFF9E9E9E)),
                    ),
                    Text(
                      '${_formatPrice(job.agreedPrice ?? job.budgetPrice)} บาท',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppConfig.primaryColor,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                // Action buttons
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (onViewDetail != null)
                      _OutlineBtn(label: 'ดูรายละเอียด', onTap: onViewDetail),
                    if (_isOpen && _hasBiddings && onViewBiddings != null) ...[
                      const SizedBox(width: 8),
                      _PrimaryBtn(label: 'ดูข้อเสนอ', onTap: onViewBiddings),
                    ],
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _OutlineBtn extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  const _OutlineBtn({required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: AppConfig.primaryColor),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: AppConfig.primaryColor,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _PrimaryBtn extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  const _PrimaryBtn({required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppConfig.primaryColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
