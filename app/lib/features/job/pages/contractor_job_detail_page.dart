import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/config/app_config.dart';
import '../../../models/models.dart';
import '../../../shared/bloc/member_lookup_bloc.dart';
import '../bloc/contractor_job_bloc.dart';
import '../bloc/contractor_job_event.dart';
import '../bloc/contractor_job_state.dart';
import '../../review/pages/review_client_page.dart';
import 'delivery_proof_page.dart';
import 'gps_tracking_page.dart';

class ContractorJobDetailPage extends StatelessWidget {
  final JobModel job;
  final String contractorId;
  final String? truckId;

  const ContractorJobDetailPage({
    super.key,
    required this.job,
    required this.contractorId,
    this.truckId,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => MemberLookupBloc()..add(LookupClient(job.clientId)),
      child: _ContractorJobDetailView(
        job: job,
        contractorId: contractorId,
        truckId: truckId,
      ),
    );
  }
}

class _ContractorJobDetailView extends StatefulWidget {
  final JobModel job;
  final String contractorId;
  final String? truckId;

  const _ContractorJobDetailView({
    required this.job,
    required this.contractorId,
    this.truckId,
  });

  @override
  State<_ContractorJobDetailView> createState() =>
      _ContractorJobDetailViewState();
}

class _ContractorJobDetailViewState extends State<_ContractorJobDetailView> {
  late JobModel _currentJob;

  // 6-stage flow ตาม Mockup
  static const List<String> _statusOrder = [
    'มอบหมายแล้ว',
    'ถึงจุดรับสินค้า',
    'รับสินค้าเรียบร้อย',
    'กำลังขนส่ง',
    'ถึงจุดส่งสินค้า',
    'จัดส่งสำเร็จ',
  ];

  // ข้อมูลลูกค้าจาก MemberLookupBloc (โหลดผ่าน bloc — ไม่เรียก repo ตรง)
  ClientModel? get _client => context.read<MemberLookupBloc>().state.client;

  @override
  void initState() {
    super.initState();
    _currentJob = widget.job;
  }

  String get _clientName => _client != null
      ? '${_client!.member.firstName} ${_client!.member.lastName}'.trim()
      : (_currentJob.pickupName ?? 'ผู้ว่าจ้าง');

  String get _clientPhone =>
      _client?.member.phoneNumber ?? _currentJob.pickupPhone ?? '';

  // ย่อที่อยู่สำหรับหัวข้อ (เอาส่วนแรกก่อนคอมมา/สั้นๆ)
  String _shortLoc(String addr) {
    final first = addr.split(',').first.trim();
    final words = first.split(' ');
    return words.length > 3 ? words.take(3).join(' ') : first;
  }

  void _showCallDialog(String phone, String name) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('โทรหา $name'),
        content: Text(
          phone,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'ปิด',
              style: TextStyle(color: Color(0xFF757575)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClientCard() {
    final name = _clientName;
    final phone = _clientPhone;
    final initial = name.isNotEmpty ? name.characters.first : 'ว';
    return Container(
      padding: const EdgeInsets.all(14),
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
          CircleAvatar(
            radius: 22,
            backgroundColor: AppConfig.primaryColor,
            child: Text(
              initial,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name.isEmpty ? 'ผู้ว่าจ้าง' : name,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'ลูกค้า',
                  style: TextStyle(fontSize: 12, color: Color(0xFF757575)),
                ),
              ],
            ),
          ),
          if (phone.isNotEmpty)
            IconButton(
              onPressed: () => _showCallDialog(phone, name),
              icon: const Icon(Icons.phone, color: Colors.white),
              style: IconButton.styleFrom(
                backgroundColor: AppConfig.primaryColor,
                shape: const CircleBorder(),
              ),
            ),
        ],
      ),
    );
  }

  String? get _nextStatus {
    final idx = _statusOrder.indexOf(_currentJob.jobStatus);
    if (idx < 0 || idx >= _statusOrder.length - 1) return null;
    return _statusOrder[idx + 1];
  }

  bool get _canUpdate => _nextStatus != null;

  String _formatPrice(int price) => price.toString().replaceAllMapped(
    RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
    (m) => '${m[1]},',
  );

  void _showUpdateDialog(BuildContext context) {
    final next = _nextStatus;
    if (next == null) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'ยืนยันการอัปเดตสถานะ',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
        ),
        content: RichText(
          text: TextSpan(
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF424242),
              height: 1.5,
            ),
            children: [
              const TextSpan(text: 'ต้องการเปลี่ยนสถานะงานเป็น\n'),
              TextSpan(
                text: '"$next"',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppConfig.primaryColor,
                ),
              ),
              const TextSpan(text: '\nใช่หรือไม่?'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'ยกเลิก',
              style: TextStyle(color: Color(0xFF757575)),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConfig.primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              context.read<ContractorJobBloc>().add(
                UpdateJobStatusEvent(jobId: _currentJob.jobId, newStatus: next),
              );
            },
            child: const Text('ยืนยัน'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    context.watch<MemberLookupBloc>(); // rebuild เมื่อโหลดข้อมูลลูกค้าเสร็จ
    return BlocListener<ContractorJobBloc, ContractorJobState>(
      listener: (context, state) {
        if (state is JobStatusUpdated) {
          setState(() => _currentJob = state.updatedJob);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'อัปเดตสถานะเป็น "${state.updatedJob.jobStatus}" สำเร็จ',
              ),
              backgroundColor: AppConfig.primaryColor,
              behavior: SnackBarBehavior.floating,
            ),
          );
          if (state.updatedJob.jobStatus == 'จัดส่งสำเร็จ') {
            _showCompletionSheet(context, state.updatedJob);
          }
        }
        if (state is ContractorJobError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppConfig.errorColor,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor: AppConfig.surfaceColor,
        appBar: AppBar(
          backgroundColor: AppConfig.primaryColor,
          foregroundColor: Colors.white,
          title: const Text('งานปัจจุบัน'),
          elevation: 0,
          actions: [
            if (_clientPhone.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.phone),
                tooltip: 'โทรหาลูกค้า',
                onPressed: () => _showCallDialog(_clientPhone, _clientName),
              ),
          ],
          // subtitle: ชื่องาน + เส้นทาง (ตาม Mockup 07 จอ 2)
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(46),
            child: Container(
              width: double.infinity,
              color: AppConfig.primaryColor,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _currentJob.jobTitle,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${_shortLoc(_currentJob.pickupAddress)} → ${_shortLoc(_currentJob.dropoffAddress)}',
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Route hero (แผนที่ย่อ + timeline รถ + ระยะทาง) — Mockup 07 จอ 2
              _buildRouteHero(),
              const SizedBox(height: 16),

              // Client info + call (อยู่บน ใต้ hero ตาม Mockup)
              _buildClientCard(),
              const SizedBox(height: 16),

              // Progress stepper
              _buildStepper(),
              const SizedBox(height: 16),

              // Stat cards 2x2 (สินค้า/ระยะทาง/ส่งถึงก่อน/รายได้)
              _buildStatCards(),
              const SizedBox(height: 24),

              // GPS button สำหรับทุก active stage (1-5)
              if (_currentJob.jobStatus != 'จัดส่งสำเร็จ' &&
                  _statusOrder.contains(_currentJob.jobStatus)) ...[
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => GpsTrackingPage(
                          jobId: _currentJob.jobId,
                          truckId: widget.truckId ?? widget.contractorId,
                          jobTitle: _currentJob.jobTitle,
                        ),
                      ),
                    ),
                    icon: const Icon(
                      Icons.gps_fixed,
                      color: AppConfig.primaryColor,
                    ),
                    label: const Text('ส่งตำแหน่งปัจจุบัน'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppConfig.primaryColor,
                      side: const BorderSide(color: AppConfig.primaryColor),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // Delivery Proof button เมื่อถึงจุดส่งสินค้า (stage 5) → ส่งมอบสินค้าเรียบร้อย (stage 6)
              if (_currentJob.jobStatus == 'ถึงจุดส่งสินค้า') ...[
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final nav = Navigator.of(context);
                      final result = await Navigator.push<bool>(
                        context,
                        MaterialPageRoute(
                          builder: (_) => DeliveryProofPage(
                            jobId: _currentJob.jobId,
                            jobTitle: _currentJob.jobTitle,
                          ),
                        ),
                      );
                      if (result == true) {
                        nav.pop();
                      }
                    },
                    icon: const Icon(Icons.camera_alt_outlined),
                    label: const Text(
                      'บันทึกหลักฐานส่งมอบ',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1976D2),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // Update button ยกเว้น stage 5 ที่ใช้ DeliveryProof
              if (_canUpdate && _currentJob.jobStatus != 'ถึงจุดส่งสินค้า')
                BlocBuilder<ContractorJobBloc, ContractorJobState>(
                  builder: (context, state) {
                    final loading = state is ContractorJobLoading;
                    return SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppConfig.primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        onPressed: loading
                            ? null
                            : () => _showUpdateDialog(context),
                        icon: loading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.update),
                        label: Text(
                          loading ? 'กำลังอัปเดต...' : 'อัพเดทสถานะ',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    );
                  },
                ),

              if (!_canUpdate && _currentJob.jobStatus == 'จัดส่งสำเร็จ') ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.check_circle,
                        color: Color(0xFF4CAF50),
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'งานเสร็จสมบูรณ์',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF4CAF50),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ReviewClientPage(
                          jobId: _currentJob.jobId,
                          reviewerContractorId: widget.contractorId,
                          revieweeClientId: _currentJob.clientId,
                          jobTitle: _currentJob.jobTitle,
                        ),
                      ),
                    ),
                    icon: const Icon(
                      Icons.star_outline,
                      color: AppConfig.primaryColor,
                    ),
                    label: const Text('ให้คะแนนผู้ว่าจ้าง'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppConfig.primaryColor,
                      side: const BorderSide(color: AppConfig.primaryColor),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  /// สัดส่วนระยะทางที่ขับไปแล้ว ประเมินจากสถานะการส่ง (0.0–1.0)
  /// หมายเหตุ: "เหลืออีก" เป็นค่าประมาณจากขั้นตอนการส่ง เพราะยังไม่มีพิกัดปลายทาง
  /// ในฐานข้อมูล (เวอร์ชัน production ควรคำนวณจาก GPS + Maps Directions API)
  double get _traveledFraction {
    switch (_currentJob.jobStatus) {
      case 'กำลังขนส่ง':
        return 0.5;
      case 'ถึงจุดส่งสินค้า':
      case 'จัดส่งสำเร็จ':
        return 1.0;
      default: // มอบหมายแล้ว / ถึงจุดรับสินค้า / รับสินค้าเรียบร้อย = ยังไม่ออกเดินทาง
        return 0.0;
    }
  }

  /// ข้อความบน badge ระยะทาง: "🚚 X กม. · เหลืออีก Y กม." (ตาม Mockup 07 จอ 2)
  String _routeBadgeText() {
    final d = _currentJob.distance;
    if (d == null) {
      return _traveledFraction > 0 && _traveledFraction < 1
          ? '🚚 กำลังขนส่ง'
          : '🚚 เส้นทางขนส่ง';
    }
    // งานเสร็จแล้ว → ถึงปลายทาง
    if (_currentJob.jobStatus == 'จัดส่งสำเร็จ') {
      return '🚚 ระยะทาง $d กม. · ถึงปลายทางแล้ว';
    }
    final remaining = (d * (1 - _traveledFraction)).round();
    return '🚚 $d กม. · เหลืออีก $remaining กม.';
  }

  /// hero เส้นทาง (พื้นฟ้าอ่อน) + timeline รถ + ระยะทาง — ตาม Mockup 07 จอ 2
  Widget _buildRouteHero() {
    return Container(
      width: double.infinity,
      height: 150,
      decoration: BoxDecoration(
        color: const Color(0xFFE3F2FD),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // route dots: จุดรับ (เขียว) — รถ — จุดส่ง (แดง)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Row(
              children: [
                _routeDot(AppConfig.primaryColor),
                _routeLine(),
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppConfig.primaryColor, width: 2),
                  ),
                  alignment: Alignment.center,
                  child: const Text('🚚', style: TextStyle(fontSize: 18)),
                ),
                _routeLine(),
                _routeDot(const Color(0xFFE53935)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // ระยะทาง badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x1A000000),
                  blurRadius: 6,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              _routeBadgeText(),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Color(0xFF212121),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _routeDot(Color color) => Container(
    width: 16,
    height: 16,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
  );

  Widget _routeLine() =>
      Expanded(child: Container(height: 3, color: AppConfig.primaryColor));

  Widget _buildStepper() {
    return Container(
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
            'ความคืบหน้า',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Color(0xFF212121),
            ),
          ),
          const SizedBox(height: 16),
          ..._statusOrder.asMap().entries.map((entry) {
            final i = entry.key;
            final status = entry.value;
            final currentIdx = _statusOrder.indexOf(_currentJob.jobStatus);
            final isDone = i < currentIdx;
            final isCurrent = i == currentIdx;
            final isPending = i > currentIdx;
            final isLast = i == _statusOrder.length - 1;

            return _StepItem(
              stepNumber: i + 1,
              label: status,
              isDone: isDone,
              isCurrent: isCurrent,
              isPending: isPending,
              isLast: isLast,
            );
          }),
        ],
      ),
    );
  }

  /// การ์ดสถิติ 2×2: สินค้า / ระยะทาง / ส่งถึงก่อน / รายได้ (ตาม Mockup 07 จอ 2)
  Widget _buildStatCards() {
    final price = _currentJob.agreedPrice ?? _currentJob.budgetPrice;
    final deadline = _currentJob.dropoffDeadline;
    final timeStr =
        '${deadline.hour.toString().padLeft(2, '0')}:${deadline.minute.toString().padLeft(2, '0')} น.';
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 2.0,
      children: [
        _StatCell(
          label: 'สินค้า',
          value:
              '${_currentJob.productType} '
              '${(_currentJob.weight / 1000) >= 1 ? '${(_currentJob.weight / 1000).toStringAsFixed(_currentJob.weight % 1000 == 0 ? 0 : 1)} ตัน' : '${_currentJob.weight} กก.'}',
        ),
        _StatCell(
          label: 'ระยะทาง',
          value: _currentJob.distance != null
              ? '${_currentJob.distance} กม.'
              : '-',
        ),
        _StatCell(label: 'ส่งถึงก่อน', value: timeStr),
        _StatCell(label: 'รายได้', value: '฿${_formatPrice(price)}'),
      ],
    );
  }

  void _showCompletionSheet(BuildContext context, JobModel job) {
    final price = job.agreedPrice ?? job.budgetPrice;
    final fee = (price * AppConfig.platformFeePerSide).round();
    final net = price - fee;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 48,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE0E0E0),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                color: Color(0xFFE8F5E9),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.celebration,
                size: 40,
                color: Color(0xFF4CAF50),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'งานเสร็จสมบูรณ์!',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF212121),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'คุณได้ส่งมอบสินค้าเรียบร้อยแล้ว',
              style: TextStyle(fontSize: 14, color: Color(0xFF757575)),
            ),
            const SizedBox(height: 24),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppConfig.surfaceColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  _SummaryRow(
                    label: 'ค่าขนส่ง',
                    value: '฿${_formatPrice(price)}',
                  ),
                  const SizedBox(height: 8),
                  _SummaryRow(
                    label: 'ค่าธรรมเนียม (1.5%)',
                    value: '-฿${_formatPrice(fee)}',
                    valueColor: AppConfig.errorColor,
                  ),
                  const Divider(height: 20),
                  _SummaryRow(
                    label: 'รายได้สุทธิ',
                    value: '+฿${_formatPrice(net)}',
                    valueColor: const Color(0xFF4CAF50),
                    bold: true,
                    fontSize: 20,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppConfig.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  Navigator.pop(context); // close sheet
                  Navigator.pop(context); // back to job list
                },
                child: const Text(
                  'กลับหน้างานของฉัน',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

// ---- Helper widgets ----

class _StepItem extends StatelessWidget {
  final int stepNumber;
  final String label;
  final bool isDone;
  final bool isCurrent;
  final bool isPending;
  final bool isLast;

  const _StepItem({
    required this.stepNumber,
    required this.label,
    required this.isDone,
    required this.isCurrent,
    required this.isPending,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left: circle + line
          Column(
            children: [
              _buildCircle(),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: isDone
                        ? AppConfig.primaryColor
                        : const Color(0xFFE0E0E0),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 14),
          // Right: label + subtitle
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: isCurrent
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: isPending
                          ? const Color(0xFFBDBDBD)
                          : isCurrent
                          ? AppConfig.primaryColor
                          : const Color(0xFF424242),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      isDone
                          ? 'เสร็จแล้ว'
                          : isCurrent
                          ? 'อยู่ระหว่างดำเนินการ'
                          : 'รอดำเนินการ',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDone
                            ? const Color(0xFF4CAF50)
                            : isCurrent
                            ? AppConfig.primaryColor
                            : const Color(0xFF9E9E9E),
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

  Widget _buildCircle() {
    if (isDone) {
      return Container(
        width: 28,
        height: 28,
        decoration: const BoxDecoration(
          color: AppConfig.primaryColor,
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.check, size: 16, color: Colors.white),
      );
    }
    if (isCurrent) {
      return Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: AppConfig.primaryColor,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppConfig.primaryColor.withValues(alpha: 0.4),
              blurRadius: 8,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Center(
          child: Text(
            '$stepNumber',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ),
      );
    }
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: AppConfig.surfaceColor,
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFFE0E0E0), width: 2),
      ),
      child: Center(
        child: Text(
          '$stepNumber',
          style: const TextStyle(color: Color(0xFFBDBDBD), fontSize: 13),
        ),
      ),
    );
  }
}

/// การ์ดสถิติ 1 ช่อง (label เล็กบน, value ใหญ่เขียวล่าง) — Mockup 07 จอ 2
class _StatCell extends StatelessWidget {
  final String label;
  final String value;
  const _StatCell({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
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
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: Color(0xFF9E9E9E)),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppConfig.primaryColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final bool bold;
  final double fontSize;

  const _SummaryRow({
    required this.label,
    required this.value,
    this.valueColor,
    this.bold = false,
    this.fontSize = 14,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: fontSize,
            color: const Color(0xFF757575),
            fontWeight: bold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: bold ? FontWeight.bold : FontWeight.w500,
            color: valueColor ?? const Color(0xFF212121),
          ),
        ),
      ],
    );
  }
}
