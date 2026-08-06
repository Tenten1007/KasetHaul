import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/config/app_config.dart';
import '../../../models/models.dart';
import '../../../shared/bloc/member_lookup_bloc.dart';
import '../../wallet/bloc/payment_bloc.dart';
import '../../wallet/bloc/payment_event.dart';
import '../../wallet/bloc/payment_state.dart';

class AssignConfirmPage extends StatelessWidget {
  final BiddingModel bidding;
  final JobModel job;
  final TruckModel? truck;
  final List<String> allBiddingIds;

  const AssignConfirmPage({
    super.key,
    required this.bidding,
    required this.job,
    required this.truck,
    required this.allBiddingIds,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => MemberLookupBloc()
        ..add(LookupClient(job.clientId))
        ..add(LookupContractor(bidding.contractorId)),
      child: _AssignConfirmView(
        bidding: bidding,
        job: job,
        truck: truck,
        allBiddingIds: allBiddingIds,
      ),
    );
  }
}

class _AssignConfirmView extends StatefulWidget {
  final BiddingModel bidding;
  final JobModel job;
  final TruckModel? truck;
  final List<String> allBiddingIds;

  const _AssignConfirmView({
    required this.bidding,
    required this.job,
    required this.truck,
    required this.allBiddingIds,
  });

  @override
  State<_AssignConfirmView> createState() => _AssignConfirmViewState();
}

class _AssignConfirmViewState extends State<_AssignConfirmView> {
  // ข้อมูล client/contractor จาก MemberLookupBloc (ไม่เรียก repo ตรง)
  ClientModel? get _client => context.read<MemberLookupBloc>().state.client;
  ContractorModel? get _contractor =>
      context.read<MemberLookupBloc>().state.contractor;
  bool get _loading => _client == null || _contractor == null;

  double get _fee =>
      widget.bidding.bidPrice * AppConfig.platformFeePerSide;
  double get _total => widget.bidding.bidPrice + _fee;

  void _confirm() {
    context.read<PaymentBloc>().add(AcceptBiddingEvent(
          biddingId: widget.bidding.biddingId,
          jobId: widget.job.jobId,
          clientId: widget.job.clientId,
          contractorId: widget.bidding.contractorId,
          jobTitle: widget.job.jobTitle,
          bidPrice: widget.bidding.bidPrice,
          clientWalletBalance: _client?.walletBalance ?? 0,
          clientPendingBalance: _client?.pendingBalance ?? 0,
          otherBiddingIds: widget.allBiddingIds
              .where((id) => id != widget.bidding.biddingId)
              .toList(),
        ));
  }

  String _fmt(num v) => v
      .toStringAsFixed(2)
      .replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');

  @override
  Widget build(BuildContext context) {
    context.watch<MemberLookupBloc>(); // rebuild เมื่อโหลด client/contractor เสร็จ
    return BlocListener<PaymentBloc, PaymentState>(
      listener: (context, state) {
        if (state is AcceptBiddingSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('มอบหมายงานสำเร็จ!'),
              backgroundColor: Color(0xFF4CAF50),
            ),
          );
          // pop twice: confirm page + bidding list
          Navigator.of(context)
            ..pop(true)
            ..pop(true);
        } else if (state is InsufficientBalance) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'ยอดเงินไม่เพียงพอ ต้องการ ฿${_fmt(state.required)}'),
              backgroundColor: AppConfig.errorColor,
            ),
          );
        } else if (state is PaymentError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(state.message),
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
          title: const Text('ยืนยันการมอบหมาย'),
          centerTitle: true,
        ),
        body: _loading
            ? const Center(
                child: CircularProgressIndicator(
                    color: AppConfig.primaryColor))
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Contractor avatar
                    Center(
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 40,
                            backgroundColor: AppConfig.primaryLightColor,
                            child: Text(
                              _contractor != null
                                  ? _contractor!.member.firstName.isNotEmpty
                                      ? _contractor!.member.firstName
                                          .characters.first
                                          .toUpperCase()
                                      : 'ผ'
                                  : 'ผ',
                              style: const TextStyle(
                                  fontSize: 30,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _contractor != null
                                ? '${_contractor!.member.firstName} ${_contractor!.member.lastName}'
                                : 'ผู้รับจ้าง',
                            style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text('★★★★★',
                                  style: TextStyle(
                                      color: Color(0xFFFFC107),
                                      fontSize: 18)),
                              if (_contractor?.ratingScore != null) ...[
                                const SizedBox(width: 6),
                                Text(
                                  _contractor!.ratingScore!.toStringAsFixed(1),
                                  style: const TextStyle(
                                      fontSize: 14,
                                      color: Color(0xFF757575)),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Job summary
                    _Card(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('รายละเอียดงาน',
                              style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Text(widget.job.jobTitle,
                              style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600)),
                          const SizedBox(height: 8),
                          _RouteRow(
                            from: widget.job.pickupAddress,
                            to: widget.job.dropoffAddress,
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 16,
                            children: [
                              _DetailChip(
                                  '${widget.job.pickupDatetime.day}/${widget.job.pickupDatetime.month}/${widget.job.pickupDatetime.year}'),
                              if (widget.job.distance != null)
                                _DetailChip(
                                    '${widget.job.distance} กม.'),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Truck info
                    if (widget.truck != null)
                      _Card(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('รถที่ใช้',
                                style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Text('🚛',
                                    style: TextStyle(fontSize: 32)),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${widget.truck!.brand} ${widget.truck!.model}',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold),
                                      ),
                                      Text(
                                        'ทะเบียน: ${widget.truck!.licensePlate}',
                                        style: const TextStyle(
                                            fontSize: 12,
                                            color: Color(0xFF757575)),
                                      ),
                                      if (widget.truck!.capacity != null)
                                        Text(
                                          'บรรทุกได้ ${(widget.truck!.capacity! / 1000).toStringAsFixed(0)} ตัน',
                                          style: const TextStyle(
                                              fontSize: 12,
                                              color:
                                                  AppConfig.primaryColor),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    if (widget.truck != null) const SizedBox(height: 12),

                    // Price summary
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5E9),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: const [
                          BoxShadow(
                              color: Color(0x1A000000),
                              blurRadius: 8,
                              offset: Offset(0, 2))
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('สรุปค่าใช้จ่าย',
                              style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold)),
                          const SizedBox(height: 12),
                          _SummaryRow(
                            label: 'ราคาที่เสนอ',
                            value:
                                '${_fmt(widget.bidding.bidPrice)} บาท',
                          ),
                          const SizedBox(height: 8),
                          _SummaryRow(
                            label: 'ค่าธรรมเนียม (1.5%)',
                            value: '-${_fmt(_fee)} บาท',
                            valueColor: AppConfig.errorColor,
                          ),
                          const Divider(height: 24),
                          Row(
                            mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('ยอดที่ต้องชำระ',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14)),
                              Text(
                                '${_fmt(_total)} บาท',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: AppConfig.primaryColor,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Wallet balance
                    if (_client != null)
                      _Card(
                        child: Row(
                          mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('ยอดเงินในกระเป๋า',
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF757575))),
                                Text(
                                  '${_fmt(_client!.walletBalance)} บาท',
                                  style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: AppConfig.primaryColor),
                                ),
                              ],
                            ),
                            _client!.walletBalance >= _total
                                ? _Badge(
                                    label: 'เพียงพอ',
                                    bg: const Color(0xFFE8F5E9),
                                    fg: const Color(0xFF2E7D32),
                                  )
                                : _Badge(
                                    label: 'ไม่เพียงพอ',
                                    bg: const Color(0xFFFFEBEE),
                                    fg: const Color(0xFFC62828),
                                  ),
                          ],
                        ),
                      ),
                    if (_client != null) const SizedBox(height: 12),

                    // Notice
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF3E0),
                        borderRadius: BorderRadius.circular(12),
                        border:
                            Border.all(color: const Color(0xFFFFB74D)),
                      ),
                      child: const Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('ℹ️', style: TextStyle(fontSize: 20)),
                          SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('หมายเหตุ',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFFE65100),
                                        fontSize: 13)),
                                SizedBox(height: 4),
                                Text(
                                  'เงินจะถูกกันไว้ในระบบจนกว่างานจะเสร็จสิ้น '
                                  'หากยกเลิกงาน จะได้รับเงินคืนตามเงื่อนไข',
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF757575)),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Action buttons
                    BlocBuilder<PaymentBloc, PaymentState>(
                      builder: (context, state) {
                        final loading = state is PaymentLoading;
                        return Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: loading
                                    ? null
                                    : () => Navigator.pop(context),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor:
                                      const Color(0xFF424242),
                                  side: const BorderSide(
                                      color: Color(0xFFBDBDBD)),
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 14),
                                  shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(12)),
                                ),
                                child: const Text('ยกเลิก',
                                    style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600)),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: loading ? null : _confirm,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppConfig.primaryColor,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 14),
                                  shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(12)),
                                  elevation: 0,
                                ),
                                child: loading
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2))
                                    : const Text('ยืนยัน',
                                        style: TextStyle(
                                            fontSize: 15,
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

// ── Helper widgets ─────────────────────────────────────────────────────────────

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

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
              color: Color(0x1A000000), blurRadius: 8, offset: Offset(0, 2))
        ],
      ),
      child: child,
    );
  }
}

class _RouteRow extends StatelessWidget {
  final String from;
  final String to;
  const _RouteRow({required this.from, required this.to});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Column(
          children: [
            Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                    color: AppConfig.primaryColor, shape: BoxShape.circle)),
            Container(width: 2, height: 20, color: const Color(0xFFBDBDBD)),
            Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                    color: AppConfig.errorColor, shape: BoxShape.circle)),
          ],
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(from,
                  style: const TextStyle(fontSize: 13),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
              const SizedBox(height: 12),
              Text(to,
                  style: const TextStyle(fontSize: 13),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ],
    );
  }
}

class _DetailChip extends StatelessWidget {
  final String label;
  const _DetailChip(this.label);

  @override
  Widget build(BuildContext context) {
    return Text(label,
        style: const TextStyle(fontSize: 12, color: Color(0xFF757575)));
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  const _SummaryRow({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 13)),
        Text(value,
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: valueColor ?? const Color(0xFF212121))),
      ],
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color bg;
  final Color fg;
  const _Badge({required this.label, required this.bg, required this.fg});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(label,
          style: TextStyle(
              fontSize: 12, fontWeight: FontWeight.w600, color: fg)),
    );
  }
}


