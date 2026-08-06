import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/config/app_config.dart';
import '../../../core/repositories/repositories.dart';
import '../../../models/models.dart';
import '../../../shared/widgets/status_badge_widget.dart';
import '../../../shared/widgets/section_title_widget.dart';
import '../../wallet/bloc/payment_bloc.dart';
import '../../wallet/bloc/payment_state.dart';
import '../bloc/job_bloc.dart';
import '../bloc/job_event.dart';
import '../bloc/job_state.dart';
import 'assign_confirm_page.dart';
import 'cancel_job_page.dart';
import 'edit_job_page.dart';
import 'location_view_page.dart';
import '../../profile/pages/contractor_profile_page.dart';

class JobDetailPage extends StatelessWidget {
  final String jobId;
  final bool isClient;
  const JobDetailPage({super.key, required this.jobId, required this.isClient});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => JobBloc(
        jobRepository: JobRepository(),
        biddingRepository: BiddingRepository(),
      )..add(LoadJobDetailEvent(jobId: jobId)),
      child: _JobDetailView(jobId: jobId, isClient: isClient),
    );
  }
}

class _JobDetailView extends StatefulWidget {
  final String jobId;
  final bool isClient;
  const _JobDetailView({required this.jobId, required this.isClient});

  @override
  State<_JobDetailView> createState() => _JobDetailViewState();
}

class _JobDetailViewState extends State<_JobDetailView> {
  // Cache job ไว้เพื่อไม่ให้จอว่างตอน BiddingsLoaded state เข้ามาแทน JobDetailLoaded
  JobModel? _job;

  @override
  Widget build(BuildContext context) {
    return BlocListener<JobBloc, JobState>(
      listener: (context, state) {
        if (state is JobCancelled) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('ยกเลิกงานเรียบร้อย')),
          );
          Navigator.of(context).pop();
        } else if (state is JobUpdated) {
          context.read<JobBloc>().add(LoadJobDetailEvent(jobId: widget.jobId));
        }
      },
      child: Scaffold(
        backgroundColor: AppConfig.surfaceColor,
        appBar: AppBar(
          backgroundColor: AppConfig.primaryColor,
          foregroundColor: Colors.white,
          title: const Text('รายละเอียดงาน'),
          elevation: 0,
          actions: [
            if (widget.isClient)
              BlocBuilder<JobBloc, JobState>(
                buildWhen: (_, s) => s is JobDetailLoaded,
                builder: (context, state) {
                  final job = state is JobDetailLoaded ? state.job : _job;
                  if (job != null && job.jobStatus == 'รอผู้รับจ้าง') {
                    return PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert, color: Colors.white),
                      onSelected: (value) {
                        if (value == 'edit') {
                          final bloc = context.read<JobBloc>();
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => EditJobPage(job: job),
                            ),
                          ).then((_) =>
                              bloc.add(LoadJobDetailEvent(jobId: widget.jobId)));
                        }
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem(
                          value: 'edit',
                          child: Text('แก้ไขงาน'),
                        ),
                      ],
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
          ],
        ),
        body: BlocBuilder<JobBloc, JobState>(
          builder: (context, state) {
            // อัปเดต cache เมื่อโหลดงานสำเร็จ
            if (state is JobDetailLoaded) {
              _job = state.job;
            }
            // ถ้ามี job ใน cache แล้ว แสดง content เสมอ
            // (ครอบคลุมกรณี BiddingsLoaded / JobLoading จาก biddings ที่ทำให้จอว่าง)
            if (_job != null) {
              return _JobDetailContent(job: _job!, isClient: widget.isClient);
            }
            if (state is JobError) {
              return Center(child: Text(state.message));
            }
            return const Center(child: CircularProgressIndicator());
          },
        ),
      ),
    );
  }
}

class _JobDetailContent extends StatelessWidget {
  final JobModel job;
  final bool isClient;

  const _JobDetailContent({required this.job, required this.isClient});

  String _formatDateTime(DateTime dt) {
    const months = [
      '', 'ม.ค.', 'ก.พ.', 'มี.ค.', 'เม.ย.', 'พ.ค.', 'มิ.ย.',
      'ก.ค.', 'ส.ค.', 'ก.ย.', 'ต.ค.', 'พ.ย.', 'ธ.ค.'
    ];
    return '${dt.day} ${months[dt.month]} ${dt.year - 543 + 2500} | '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  String _formatPrice(num price) {
    return price
        .toStringAsFixed(0)
        .replaceAllMapped(
            RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');
  }

  bool get _isOpen => job.jobStatus == 'รอผู้รับจ้าง';

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Map hero (ตาม Mockup 02 จอ 6 — placeholder แผนที่บนสุด)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Container(
              width: double.infinity,
              height: 160,
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(16),
              ),
              alignment: Alignment.center,
              child: const Text('🗺️', style: TextStyle(fontSize: 56)),
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title + badge
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
                                fontSize: 18, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${job.productType} • ${job.requiredTruckType.typeName}',
                            style: const TextStyle(
                                fontSize: 13, color: AppConfig.primaryColor),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    StatusBadgeWidget(status: job.jobStatus),
                  ],
                ),
                const SizedBox(height: 16),

                // Route timeline card
                _CardSection(
                  child: Column(
                    children: [
                      _TimelineItem(
                        icon: '📍',
                        active: true,
                        title: job.pickupAddress,
                        subtitle: _formatDateTime(job.pickupDatetime),
                        extra: job.pickupName != null && job.pickupPhone != null
                            ? '${job.pickupName} | ${job.pickupPhone}'
                            : null,
                      ),
                      _TimelineItem(
                        icon: '🏁',
                        active: false,
                        title: job.dropoffAddress,
                        subtitle:
                            'ส่งถึงก่อน ${_formatDateTime(job.dropoffDeadline)} น.',
                        extra: job.dropoffName != null &&
                                job.dropoffPhone != null
                            ? '${job.dropoffName} | ${job.dropoffPhone}'
                            : null,
                        isLast: true,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Quick info chips
                Row(
                  children: [
                    Expanded(
                      child: _InfoChip(
                          label: 'น้ำหนัก',
                          value: '${job.weight} กก.'),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _InfoChip(
                          label: 'ระยะทาง',
                          value: job.distance != null
                              ? '${job.distance} กม.'
                              : '-'),
                    ),
                    if (_isOpen) ...[
                      const SizedBox(width: 8),
                      Expanded(
                        child: BlocBuilder<JobBloc, JobState>(
                          buildWhen: (_, s) => s is BiddingsLoaded,
                          builder: (context, s) => _InfoChip(
                            label: 'ข้อเสนอ',
                            value: s is BiddingsLoaded
                                ? '${s.biddings.length}'
                                : '...',
                            valueColor: AppConfig.primaryColor,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 16),

                // Description
                if (job.description != null) ...[
                  const SectionTitleWidget(title: 'รายละเอียดงาน'),
                  _CardSection(
                    child: Text(
                      job.description!,
                      style: const TextStyle(fontSize: 14, height: 1.5),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Budget
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const SectionTitleWidget(title: 'งบประมาณ'),
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
                const SizedBox(height: 20),

                // Action buttons for client
                if (isClient) ...[
                  if (_isOpen) ...[
                    _BiddingsList(job: job),
                    const SizedBox(height: 12),
                  ],
                  // GPS tracking view สำหรับทุก active stages หลัง assign
                  if (job.jobStatus == 'มอบหมายแล้ว' ||
                      job.jobStatus == 'ถึงจุดรับสินค้า' ||
                      job.jobStatus == 'รับสินค้าเรียบร้อย' ||
                      job.jobStatus == 'กำลังขนส่ง' ||
                      job.jobStatus == 'ถึงจุดส่งสินค้า') ...[
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => LocationViewPage(
                              jobId: job.jobId,
                              jobTitle: job.jobTitle,
                              jobStatus: job.jobStatus,
                              pickupAddress: job.pickupAddress,
                              dropoffAddress: job.dropoffAddress,
                              distanceKm: job.distance,
                            ),
                          ),
                        ),
                        icon: const Icon(Icons.location_on_outlined,
                            color: AppConfig.primaryColor),
                        label: const Text('ดูตำแหน่งผู้รับจ้าง'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppConfig.primaryColor,
                          side: const BorderSide(color: AppConfig.primaryColor),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                  if (_isOpen ||
                      job.jobStatus == 'ยังไม่มีผู้รับจ้างยืนยันรับงาน') ...[
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () => _showCancelDialog(context),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppConfig.errorColor,
                          side: const BorderSide(color: AppConfig.errorColor),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('ยกเลิกงาน',
                            style: TextStyle(fontSize: 16)),
                      ),
                    ),
                  ],
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showCancelDialog(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: context.read<JobBloc>(),
          child: CancelJobPage(job: job),
        ),
      ),
    );
  }
}

// ── Timeline item ──────────────────────────────────────────────────────────────

class _TimelineItem extends StatelessWidget {
  final String icon;
  final bool active;
  final String title;
  final String subtitle;
  final String? extra;
  final bool isLast;

  const _TimelineItem({
    required this.icon,
    required this.active,
    required this.title,
    required this.subtitle,
    this.extra,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Dot + line
          Column(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: active ? AppConfig.primaryColor : const Color(0xFFE0E0E0),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(icon, style: const TextStyle(fontSize: 12)),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: const Color(0xFFE0E0E0),
                    margin: const EdgeInsets.symmetric(vertical: 4),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          // Content
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontWeight: FontWeight.w500, fontSize: 14)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: const TextStyle(
                          fontSize: 12, color: Color(0xFF757575))),
                  if (extra != null) ...[
                    const SizedBox(height: 2),
                    Text(extra!,
                        style: const TextStyle(
                            fontSize: 12, color: Color(0xFF9E9E9E))),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Biddings list ──────────────────────────────────────────────────────────────

class _BiddingsList extends StatefulWidget {
  final JobModel job;
  const _BiddingsList({required this.job});

  @override
  State<_BiddingsList> createState() => _BiddingsListState();
}

class _BiddingsListState extends State<_BiddingsList> {
  @override
  void initState() {
    super.initState();
    context.read<JobBloc>().add(LoadBiddingsEvent(jobId: widget.job.jobId));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const SectionTitleWidget(title: 'ข้อเสนอราคา'),
            TextButton(
              onPressed: () => context
                  .read<JobBloc>()
                  .add(LoadBiddingsEvent(jobId: widget.job.jobId)),
              child: const Text('รีเฟรช'),
            ),
          ],
        ),
        BlocBuilder<JobBloc, JobState>(
          buildWhen: (_, state) =>
              state is BiddingsLoaded ||
              state is JobLoading ||
              state is JobError,
          builder: (context, state) {
            if (state is JobLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is JobError) {
              return Container(
                padding: const EdgeInsets.all(20),
                alignment: Alignment.center,
                child: Text(state.message,
                    style: const TextStyle(color: Color(0xFFB71C1C)),
                    textAlign: TextAlign.center),
              );
            }
            if (state is BiddingsLoaded) {
              if (state.biddings.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(20),
                  alignment: Alignment.center,
                  child: const Text('ยังไม่มีผู้เสนอราคา',
                      style: TextStyle(color: Color(0xFF757575))),
                );
              }
              final allIds =
                  state.biddings.map((b) => b.biddingId).toList();
              return Column(
                children: state.biddings
                    .asMap()
                    .entries
                    .map((e) => _BiddingCard(
                          bidding: e.value,
                          job: widget.job,
                          truck: state.trucks[e.value.truckId],
                          contractor: state.contractors[e.value.contractorId],
                          isRecommended: e.key == 0,
                          allBiddingIds: allIds,
                        ))
                    .toList(),
              );
            }
            return const SizedBox();
          },
        ),
      ],
    );
  }
}

class _BiddingCard extends StatelessWidget {
  final BiddingModel bidding;
  final JobModel job;
  final bool isRecommended;
  final List<String> allBiddingIds;
  final TruckModel? truck;
  final ContractorModel? contractor;

  const _BiddingCard({
    required this.bidding,
    required this.job,
    required this.isRecommended,
    required this.allBiddingIds,
    this.truck,
    this.contractor,
  });

  String get _contractorName {
    final c = contractor;
    if (c == null) return 'ผู้รับจ้าง';
    final name = '${c.member.firstName} ${c.member.lastName}'.trim();
    return name.isEmpty ? 'ผู้รับจ้าง' : name;
  }

  String get _avatarInitial {
    final c = contractor;
    if (c != null && c.member.firstName.isNotEmpty) {
      return c.member.firstName.characters.first;
    }
    return 'ผ';
  }

  String _formatPrice(num price) => price
      .toStringAsFixed(0)
      .replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: isRecommended
            ? Border.all(color: AppConfig.primaryColor, width: 2)
            : null,
        boxShadow: const [
          BoxShadow(
              color: Color(0x1A000000), blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isRecommended) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: AppConfig.primaryColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'แนะนำ',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Contractor info + price
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isRecommended
                      ? AppConfig.primaryLightColor
                      : AppConfig.secondaryColor,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  _avatarInitial,
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_contractorName,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 14)),
                    Row(
                      children: [
                        Text(
                          contractor?.ratingScore != null
                              ? '★ ${contractor!.ratingScore!.toStringAsFixed(1)}'
                              : 'ยังไม่มีรีวิว',
                          style: const TextStyle(
                              color: Color(0xFFFFC107), fontSize: 13),
                        ),
                        if (contractor != null &&
                            contractor!.reviewCount > 0) ...[
                          const SizedBox(width: 4),
                          Text('(${contractor!.reviewCount} รีวิว)',
                              style: const TextStyle(
                                  color: Color(0xFF9E9E9E), fontSize: 12)),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              Text(
                '${_formatPrice(bidding.bidPrice)}฿',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppConfig.primaryColor,
                ),
              ),
            ],
          ),

          // Truck info card (ตาม Mockup Bidding card spec)
          Builder(builder: (context) {
            final t = truck;
            if (t == null) return const SizedBox.shrink();
            final capText = t.capacity != null ? '${t.capacity} กก.' : '-';
            return Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: AppConfig.surfaceColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.local_shipping_outlined,
                        size: 18, color: Color(0xFF757575)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            t.truckType.typeName,
                            style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF424242)),
                          ),
                          Text(
                            'ทะเบียน: ${t.licensePlate}  •  บรรทุกได้: $capText',
                            style: const TextStyle(
                                fontSize: 12, color: Color(0xFF757575)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),

          // Message
          if (bidding.messageToClient != null &&
              bidding.messageToClient!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppConfig.surfaceColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '"${bidding.messageToClient}"',
                style: const TextStyle(
                    fontSize: 14, color: Color(0xFF616161)),
              ),
            ),
          ],

          const SizedBox(height: 12),

          // Actions
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ContractorProfilePage(
                        contractorId: bidding.contractorId,
                        readOnly: true,
                      ),
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppConfig.primaryColor,
                    side: const BorderSide(color: AppConfig.primaryColor),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('ดูโปรไฟล์', style: TextStyle(fontSize: 13)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: BlocProvider(
                  create: (_) => PaymentBloc(
                    biddingRepository: BiddingRepository(),
                    jobRepository: JobRepository(),
                    clientRepository: ClientRepository(),
                    transactionRepository: TransactionRepository(),
                  ),
                  child: BlocBuilder<PaymentBloc, PaymentState>(
                    builder: (context, state) {
                      return ElevatedButton(
                        onPressed: state is PaymentLoading
                            ? null
                            : () => _confirmAccept(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppConfig.primaryColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                        child: state is PaymentLoading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2),
                              )
                            : const Text('เลือกผู้รับจ้างนี้',
                                style: TextStyle(fontSize: 13)),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _confirmAccept(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: context.read<PaymentBloc>(),
          child: AssignConfirmPage(
            bidding: bidding,
            job: job,
            truck: truck,
            allBiddingIds: allBiddingIds,
          ),
        ),
      ),
    );
  }
}

// ── Shared card section ────────────────────────────────────────────────────────

class _CardSection extends StatelessWidget {
  final Widget child;

  const _CardSection({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
              color: Color(0x1A000000), blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: child,
    );
  }
}

// ── Info chip ──────────────────────────────────────────────────────────────────

class _InfoChip extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _InfoChip({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
              color: Color(0x1A000000), blurRadius: 6, offset: Offset(0, 1)),
        ],
      ),
      child: Column(
        children: [
          Text(label,
              style: const TextStyle(fontSize: 12, color: Color(0xFF9E9E9E))),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: valueColor ?? AppConfig.textPrimaryColor,
            ),
          ),
        ],
      ),
    );
  }
}


