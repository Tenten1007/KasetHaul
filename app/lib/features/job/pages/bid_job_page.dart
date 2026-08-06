import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/config/app_config.dart';
import '../../../core/repositories/repositories.dart';
import '../../../models/models.dart';
import '../bloc/contractor_bid_bloc.dart';
import '../bloc/contractor_bid_event.dart';
import '../bloc/contractor_bid_state.dart';
import '../../../shared/bloc/member_lookup_bloc.dart';
import 'edit_bidding_page.dart';
import '../../profile/pages/client_profile_page.dart';

class BidJobPage extends StatelessWidget {
  final String jobId;
  final String contractorId;

  const BidJobPage({
    super.key,
    required this.jobId,
    required this.contractorId,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ContractorBidBloc(
        jobRepository: JobRepository(),
        biddingRepository: BiddingRepository(),
      )..add(LoadJobDetailForBidEvent(jobId: jobId, contractorId: contractorId)),
      child: _BidJobView(jobId: jobId, contractorId: contractorId),
    );
  }
}

class _BidJobView extends StatefulWidget {
  final String jobId;
  final String contractorId;
  const _BidJobView({required this.jobId, required this.contractorId});

  @override
  State<_BidJobView> createState() => _BidJobViewState();
}

class _BidJobViewState extends State<_BidJobView> {
  final _formKey = GlobalKey<FormState>();
  final _priceCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();

  // รถที่เลือกใช้เสนอราคา (ข้อมูลรถ + สถานะยืนยันตัวตนโหลดผ่าน ContractorBidBloc)
  TruckModel? _selectedTruck;

  @override
  void dispose() {
    _priceCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  String _formatPrice(int price) => price
      .toString()
      .replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');

  String _formatDate(DateTime dt) {
    const months = [
      '', 'ม.ค.', 'ก.พ.', 'มี.ค.', 'เม.ย.', 'พ.ค.', 'มิ.ย.',
      'ก.ค.', 'ส.ค.', 'ก.ย.', 'ต.ค.', 'พ.ย.', 'ธ.ค.'
    ];
    final buddhistYear = dt.year + 543;
    return '${dt.day} ${months[dt.month]} $buddhistYear';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConfig.surfaceColor,
      appBar: AppBar(
        backgroundColor: AppConfig.primaryColor,
        foregroundColor: Colors.white,
        title: const Text('รายละเอียดงาน'),
        elevation: 0,
      ),
      body: BlocConsumer<ContractorBidBloc, ContractorBidState>(
        listener: (context, state) {
          if (state is JobDetailForBidLoaded) {
            // auto-select เมื่อมีรถอนุมัติแล้วเพียงคันเดียว (เดิมอยู่ใน _loadMyTrucks)
            if (state.myTrucks.length == 1 && _selectedTruck == null) {
              setState(() => _selectedTruck = state.myTrucks.first);
            }
          } else if (state is BidSubmitted) {
            _showSuccessDialog(context, state);
          } else if (state is BidCancelled) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('ยกเลิกการเสนอราคาแล้ว')),
            );
            Navigator.of(context).pop();
          } else if (state is ContractorBidError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppConfig.errorColor,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is ContractorBidLoading) {
            return const Center(
              child: CircularProgressIndicator(color: AppConfig.primaryColor),
            );
          }
          if (state is ContractorBidError && state is! BidSubmitted) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Color(0xFF9E9E9E)),
                  const SizedBox(height: 12),
                  Text(state.message, style: const TextStyle(color: Color(0xFF757575))),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppConfig.primaryColor,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () => context.read<ContractorBidBloc>().add(
                          LoadJobDetailForBidEvent(
                            jobId: widget.jobId,
                            contractorId: widget.contractorId,
                          ),
                        ),
                    child: const Text('ลองใหม่'),
                  ),
                ],
              ),
            );
          }
          if (state is JobDetailForBidLoaded) {
            final job = state.job;
            final existing = state.myExistingBid;
            final bidCount = state.bidCount;
            final myTrucks = state.myTrucks;
            final isIdentityVerified = state.isIdentityVerified;

            // pre-fill ราคา
            if (_priceCtrl.text.isEmpty) {
              _priceCtrl.text = job.budgetPrice.toString();
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ===== Map hero (ตาม Mockup 06 จอ 2 — บนสุด) =====
                    Container(
                      width: double.infinity,
                      height: 160,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5E9),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      alignment: Alignment.center,
                      child: const Text('🗺️', style: TextStyle(fontSize: 56)),
                    ),
                    const SizedBox(height: 16),

                    // ===== Title + badge (บนพื้น ไม่อยู่ในการ์ด ตาม Mockup) =====
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
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF212121),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${job.productType} • ${job.requiredTruckType.typeName}',
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppConfig.primaryColor,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE3F2FD),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'เปิดรับข้อเสนอ',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF1565C0),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // ===== Client info + ดูโปรไฟล์ (ใต้ชื่อ ตาม Mockup) =====
                    _ClientInfoCard(clientId: job.clientId),
                    const SizedBox(height: 12),

                    // ===== Route timeline card (แยกการ์ด ตาม Mockup) =====
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
                              offset: Offset(0, 2)),
                        ],
                      ),
                      child: _RouteTimeline(
                        pickupAddress: job.pickupAddress,
                        dropoffAddress: job.dropoffAddress,
                        pickupDatetime: job.pickupDatetime,
                        formatDate: _formatDate,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // ===== 3 stat chips: น้ำหนัก / ระยะทาง / ข้อเสนอ (ตาม Mockup) =====
                    Row(
                      children: [
                        _StatChip(label: 'น้ำหนัก', value: '${job.weight} กก.'),
                        const SizedBox(width: 8),
                        _StatChip(
                            label: 'ระยะทาง',
                            value: job.distance != null
                                ? '${job.distance} กม.'
                                : '-'),
                        const SizedBox(width: 8),
                        _StatChip(
                            label: 'ข้อเสนอ',
                            value: '$bidCount',
                            valueColor: AppConfig.primaryColor),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // ===== Description =====
                    if (job.description != null && job.description!.isNotEmpty) ...[
                      const _SectionLabel(label: 'รายละเอียดงาน'),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          job.description!,
                          style: const TextStyle(fontSize: 14, color: Color(0xFF424242)),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],

                    // ===== Budget card =====
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5E9),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppConfig.primaryColor),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'งบประมาณ',
                                style: TextStyle(
                                    fontSize: 13, color: Color(0xFF9E9E9E)),
                              ),
                              Text(
                                '฿${_formatPrice(job.budgetPrice)}',
                                style: const TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.bold,
                                  color: AppConfig.primaryColor,
                                ),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Text(
                                'ราคาแนะนำ',
                                style: TextStyle(
                                    fontSize: 13, color: Color(0xFF9E9E9E)),
                              ),
                              Text(
                                '฿${_formatPrice(job.budgetPrice)}',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppConfig.primaryColor,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ===== ถ้าเสนอราคาแล้ว แสดง badge =====
                    if (existing != null) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F5E9),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFF4CAF50)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.check_circle, color: Color(0xFF2E7D32)),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'คุณเสนอ ฿${_formatPrice(existing.bidPrice)} แล้ว',
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF2E7D32),
                                  ),
                                ),
                                Text(
                                  'สถานะ: ${existing.biddingStatus}',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFF388E3C),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      // ปุ่ม Edit/Cancel เฉพาะเมื่อสถานะ 'รอการตอบรับ'
                      if (existing.biddingStatus == 'รอการตอบรับ') ...[
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () async {
                                  final result = await Navigator.push<bool>(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          EditBiddingPage(bidding: existing),
                                    ),
                                  );
                                  if (result == true && context.mounted) {
                                    context.read<ContractorBidBloc>().add(
                                          LoadJobDetailForBidEvent(
                                            jobId: widget.jobId,
                                            contractorId: widget.contractorId,
                                          ),
                                        );
                                  }
                                },
                                icon: const Icon(Icons.edit_outlined, size: 18),
                                label: const Text('แก้ไข'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppConfig.primaryColor,
                                  side: const BorderSide(
                                      color: AppConfig.primaryColor),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10)),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => _confirmCancelBid(
                                    context, existing.biddingId),
                                icon: const Icon(Icons.cancel_outlined, size: 18),
                                label: const Text('ยกเลิก'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppConfig.errorColor,
                                  side: const BorderSide(
                                      color: AppConfig.errorColor),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10)),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 20),
                    ],

                    // ===== ฟอร์มเสนอราคา (แสดงเฉพาะเมื่อยังไม่เคยเสนอ) =====
                    if (existing == null) ...[
                      // ===== เลือกรถที่จะใช้ =====
                      const _SectionLabel(label: 'เลือกรถที่ใช้งาน'),
                      if (myTrucks.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF3E0),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFFF9800)),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.warning_amber, color: Color(0xFFF57C00)),
                              SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'คุณยังไม่มีรถที่ผ่านการอนุมัติ กรุณาเพิ่มรถก่อนเสนอราคา',
                                  style: TextStyle(fontSize: 13, color: Color(0xFFF57C00)),
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        Column(
                          children: myTrucks.map((truck) {
                            final selected = _selectedTruck?.truckId == truck.truckId;
                            return GestureDetector(
                              onTap: () => setState(() => _selectedTruck = truck),
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 10),
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: selected ? const Color(0xFFE8F5E9) : Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: selected ? AppConfig.primaryColor : const Color(0xFFE0E0E0),
                                    width: selected ? 2 : 1,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 44,
                                      height: 44,
                                      decoration: BoxDecoration(
                                        color: selected
                                            ? AppConfig.primaryColor
                                            : AppConfig.surfaceColor,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Icon(Icons.local_shipping,
                                          color: selected ? Colors.white : const Color(0xFF9E9E9E),
                                          size: 22),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            truck.licensePlate,
                                            style: const TextStyle(
                                                fontSize: 15, fontWeight: FontWeight.w600),
                                          ),
                                          Text(
                                            truck.truckType.typeName,
                                            style: const TextStyle(
                                                fontSize: 12, color: Color(0xFF757575)),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (selected)
                                      const Icon(Icons.check_circle,
                                          color: AppConfig.primaryColor, size: 22),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),

                      const SizedBox(height: 16),
                      const _SectionLabel(label: 'ราคาที่เสนอ'),
                      TextFormField(
                        key: const Key('field_bid_price'),
                        controller: _priceCtrl,
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: AppConfig.primaryColor,
                        ),
                        decoration: InputDecoration(
                          hintText: '0',
                          suffixText: 'บาท',
                          suffixStyle: const TextStyle(
                            fontSize: 16,
                            color: Color(0xFF9E9E9E),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppConfig.primaryColor, width: 2),
                          ),
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'กรุณากรอกราคา';
                          final price = int.tryParse(v);
                          if (price == null || price <= 0) return 'ราคาต้องมากกว่า 0';
                          return null;
                        },
                        onChanged: (_) => setState(() {}),
                      ),

                      // ===== Profit analysis card =====
                      const SizedBox(height: 12),
                      StatefulBuilder(
                        builder: (context, setSelf) {
                          final raw = int.tryParse(_priceCtrl.text.trim()) ?? 0;
                          final fee = (raw * AppConfig.platformFeePerSide).round();
                          final net = raw - fee;
                          return Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F8E9),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFF8BC34A)),
                            ),
                            child: Column(
                              children: [
                                _ProfitRow(label: 'ราคาที่เสนอ', value: '฿${_formatPrice(raw)}', bold: false),
                                const SizedBox(height: 6),
                                _ProfitRow(
                                  label: 'ค่าธรรมเนียมแพลตฟอร์ม (1.5%)',
                                  value: '- ฿${_formatPrice(fee)}',
                                  valueColor: AppConfig.errorColor,
                                  bold: false,
                                ),
                                const Divider(height: 16, color: Color(0xFFBBDEFB)),
                                _ProfitRow(
                                  label: 'รายได้สุทธิที่ได้รับ',
                                  value: '฿${_formatPrice(net)}',
                                  valueColor: const Color(0xFF2E7D32),
                                  bold: true,
                                ),
                              ],
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 16),
                      const _SectionLabel(label: 'ข้อความถึงลูกค้า (ไม่บังคับ)'),
                      TextFormField(
                        controller: _noteCtrl,
                        maxLines: 3,
                        decoration: InputDecoration(
                          hintText: 'แนะนำตัว หรือระบุข้อมูลเพิ่มเติม...',
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppConfig.primaryColor, width: 2),
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: BlocBuilder<ContractorBidBloc, ContractorBidState>(
                          builder: (context, s) {
                            final isLoading = s is ContractorBidLoading;
                            final canSubmit = myTrucks.isNotEmpty && _selectedTruck != null;
                            return ElevatedButton(
                              key: const Key('btn_submit_bid'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppConfig.primaryColor,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 0,
                              ),
                              onPressed: (isLoading || !canSubmit)
                                  ? null
                                  : () {
                                      if (_formKey.currentState!.validate()) {
                                        context.read<ContractorBidBloc>().add(
                                              SubmitBidEvent(
                                                jobId: widget.jobId,
                                                contractorId: widget.contractorId,
                                                bidPrice: int.parse(_priceCtrl.text.trim()),
                                                note: _noteCtrl.text.trim().isEmpty
                                                    ? null
                                                    : _noteCtrl.text.trim(),
                                                truckId: _selectedTruck?.truckId ?? '',
                                                isIdentityVerified: isIdentityVerified,
                                              ),
                                            );
                                      }
                                    },
                              child: isLoading
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Text(
                                      'ส่งข้อเสนอ',
                                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                    ),
                            );
                          },
                        ),
                      ),
                    ],

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  void _confirmCancelBid(BuildContext context, String biddingId) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('ยืนยันการยกเลิก'),
        content: const Text('ต้องการยกเลิกการเสนอราคานี้ใช่หรือไม่?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ไม่ยกเลิก'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context
                  .read<ContractorBidBloc>()
                  .add(CancelBidEvent(biddingId: biddingId));
            },
            child: Text('ยืนยัน',
                style: TextStyle(color: AppConfig.errorColor)),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog(BuildContext context, BidSubmitted state) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                color: Color(0xFFE8F5E9),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check, color: Color(0xFF2E7D32), size: 48),
            ),
            const SizedBox(height: 16),
            const Text(
              'ส่งข้อเสนอสำเร็จ!',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'รอลูกค้าพิจารณา คุณจะได้รับการแจ้งเตือนเมื่อมีการตอบกลับ',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Color(0xFF757575)),
            ),
            const SizedBox(height: 16),
            Text(
              'ราคาที่เสนอ: ฿${_formatPrice(state.bidding.bidPrice)}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppConfig.primaryColor,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // close dialog
              Navigator.pop(context); // back to search
            },
            child: const Text(
              'ค้นหางานอื่น',
              style: TextStyle(color: Color(0xFF757575)),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConfig.primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.pop(context),
            child: const Text('รับทราบ'),
          ),
        ],
      ),
    );
  }
}

// ===== Sub-widgets =====

class _RouteTimeline extends StatelessWidget {
  final String pickupAddress;
  final String dropoffAddress;
  final DateTime pickupDatetime;
  final String Function(DateTime) formatDate;

  const _RouteTimeline({
    required this.pickupAddress,
    required this.dropoffAddress,
    required this.pickupDatetime,
    required this.formatDate,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _TimelineRow(
          dot: Container(
            width: 12,
            height: 12,
            decoration: const BoxDecoration(
              color: AppConfig.primaryColor,
              shape: BoxShape.circle,
            ),
          ),
          title: pickupAddress,
          subtitle: 'รับสินค้า ${formatDate(pickupDatetime)}',
        ),
        Padding(
          padding: const EdgeInsets.only(left: 5),
          child: Row(
            children: [
              Container(width: 2, height: 24, color: const Color(0xFFE0E0E0)),
            ],
          ),
        ),
        _TimelineRow(
          dot: Container(
            width: 12,
            height: 12,
            decoration: const BoxDecoration(
              color: AppConfig.secondaryColor,
              shape: BoxShape.circle,
            ),
          ),
          title: dropoffAddress,
          subtitle: 'จุดส่งสินค้า',
        ),
      ],
    );
  }
}

class _TimelineRow extends StatelessWidget {
  final Widget dot;
  final String title;
  final String subtitle;

  const _TimelineRow({
    required this.dot,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 3),
          child: dot,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 12, color: Color(0xFF9E9E9E)),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _StatChip({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            AppConfig.cardShadow,
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(label,
                style: const TextStyle(fontSize: 12, color: Color(0xFF9E9E9E))),
            const SizedBox(height: 2),
            Text(value,
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: valueColor ?? const Color(0xFF212121))),
          ],
        ),
      ),
    );
  }
}

/// การ์ดข้อมูลผู้ว่าจ้าง + ปุ่มดูโปรไฟล์ (โหลดครั้งเดียว cache ไว้)
class _ClientInfoCard extends StatelessWidget {
  final String clientId;
  const _ClientInfoCard({required this.clientId});

  @override
  Widget build(BuildContext context) {
    // โหลดข้อมูลผู้ว่าจ้างผ่าน MemberLookupBloc (ไม่เรียก Repository ตรงในหน้า)
    return BlocProvider(
      create: (_) => MemberLookupBloc()..add(LookupClient(clientId)),
      child: BlocBuilder<MemberLookupBloc, MemberLookupState>(
        builder: (context, state) {
          final client = state.client;
          final name = client != null
            ? '${client.member.firstName} ${client.member.lastName}'.trim()
            : 'ผู้ว่าจ้าง';
        final initial = (client != null && client.member.firstName.isNotEmpty)
            ? client.member.firstName.characters.first
            : 'ว';
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: const [
              BoxShadow(
                  color: Color(0x1A000000), blurRadius: 8, offset: Offset(0, 2)),
            ],
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: AppConfig.primaryColor,
                child: Text(initial,
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name.isEmpty ? 'ผู้ว่าจ้าง' : name,
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(
                          client?.ratingScore != null
                              ? '★ ${client!.ratingScore!.toStringAsFixed(1)}'
                              : 'ยังไม่มีรีวิว',
                          style: const TextStyle(
                              color: Color(0xFFFFC107), fontSize: 12),
                        ),
                        if (client != null && client.reviewCount > 0) ...[
                          const SizedBox(width: 4),
                          Text('(${client.reviewCount} รีวิว)',
                              style: const TextStyle(
                                  color: Color(0xFF9E9E9E), fontSize: 12)),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              OutlinedButton(
                onPressed: client == null
                    ? null
                    : () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ClientProfilePage(
                              clientId: clientId,
                              readOnly: true,
                            ),
                          ),
                        ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppConfig.primaryColor,
                  side: const BorderSide(color: AppConfig.primaryColor),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('ดูโปรไฟล์', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
        );
        },
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Color(0xFF424242),
        ),
      ),
    );
  }
}

class _ProfitRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final bool bold;

  const _ProfitRow({
    required this.label,
    required this.value,
    this.valueColor,
    this.bold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: TextStyle(
                fontSize: 13,
                color: const Color(0xFF616161),
                fontWeight: bold ? FontWeight.w600 : FontWeight.normal)),
        Text(value,
            style: TextStyle(
                fontSize: bold ? 15 : 13,
                color: valueColor ?? const Color(0xFF212121),
                fontWeight: bold ? FontWeight.bold : FontWeight.w500)),
      ],
    );
  }
}


