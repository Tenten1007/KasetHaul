import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/config/app_config.dart';
import '../../../models/models.dart';
import '../../job/bloc/contractor_job_bloc.dart';
import '../../job/bloc/contractor_job_event.dart';
import '../../job/bloc/contractor_job_state.dart';
import '../../../shared/widgets/section_title_widget.dart';
import '../../../shared/widgets/stats_grid_widget.dart';
import 'withdraw_page.dart';

class EarningsPage extends StatefulWidget {
  final String contractorId;

  const EarningsPage({super.key, required this.contractorId});

  @override
  State<EarningsPage> createState() => _EarningsPageState();
}

class _EarningsPageState extends State<EarningsPage> {
  int _selectedPeriod = 1; // index: 0=7วัน, 1=เดือนนี้, 2=3เดือน, 3=ปีนี้

  static const _periods = ['7 วัน', 'เดือนนี้', '3 เดือน', 'ปีนี้'];

  @override
  void initState() {
    super.initState();
    context.read<ContractorJobBloc>().add(LoadEarningsEvent(widget.contractorId));
  }

  List<TransactionModel> _filterByPeriod(List<TransactionModel> txs) {
    final now = DateTime.now();
    DateTime cutoff;
    switch (_selectedPeriod) {
      case 0:
        cutoff = now.subtract(const Duration(days: 7));
        break;
      case 2:
        cutoff = DateTime(now.year, now.month - 2, now.day);
        break;
      case 3:
        cutoff = DateTime(now.year, 1, 1);
        break;
      case 1:
      default:
        cutoff = DateTime(now.year, now.month, 1);
    }
    return txs.where((t) => t.transactionDate.isAfter(cutoff)).toList();
  }

  static const _monthsShort = [
    '', 'ม.ค.', 'ก.พ.', 'มี.ค.', 'เม.ย.', 'พ.ค.', 'มิ.ย.',
    'ก.ค.', 'ส.ค.', 'ก.ย.', 'ต.ค.', 'พ.ย.', 'ธ.ค.'
  ];

  /// จัดกลุ่มรายได้เป็นแท่งกราฟตามช่วงที่เลือก
  /// 7วัน→รายวัน, เดือนนี้→รายสัปดาห์, 3เดือน/ปีนี้→รายเดือน
  List<_ChartBar> _bucketize(List<TransactionModel> txs) {
    final now = DateTime.now();
    final bars = <_ChartBar>[];
    switch (_selectedPeriod) {
      case 0: // 7 วัน → รายวัน
        for (int i = 6; i >= 0; i--) {
          final day =
              DateTime(now.year, now.month, now.day).subtract(Duration(days: i));
          final sum = txs
              .where((t) =>
                  t.transactionDate.year == day.year &&
                  t.transactionDate.month == day.month &&
                  t.transactionDate.day == day.day)
              .fold<double>(0, (s, t) => s + t.amount);
          bars.add(_ChartBar(label: '${day.day}', value: sum));
        }
        break;
      case 2: // 3 เดือน → รายเดือน
        for (int i = 2; i >= 0; i--) {
          final m = DateTime(now.year, now.month - i, 1);
          final sum = txs
              .where((t) =>
                  t.transactionDate.year == m.year &&
                  t.transactionDate.month == m.month)
              .fold<double>(0, (s, t) => s + t.amount);
          bars.add(_ChartBar(label: _monthsShort[m.month], value: sum));
        }
        break;
      case 3: // ปีนี้ → รายเดือน (ม.ค.–เดือนปัจจุบัน)
        for (int mo = 1; mo <= now.month; mo++) {
          final sum = txs
              .where((t) =>
                  t.transactionDate.year == now.year &&
                  t.transactionDate.month == mo)
              .fold<double>(0, (s, t) => s + t.amount);
          bars.add(_ChartBar(label: _monthsShort[mo], value: sum));
        }
        break;
      case 1:
      default: // เดือนนี้ → รายสัปดาห์
        final weeks = <int, double>{};
        for (final t in txs) {
          final wk = ((t.transactionDate.day - 1) ~/ 7) + 1;
          weeks[wk] = (weeks[wk] ?? 0) + t.amount;
        }
        final maxWk = ((now.day - 1) ~/ 7) + 1;
        for (int w = 1; w <= maxWk; w++) {
          bars.add(_ChartBar(label: 'ส.$w', value: weeks[w] ?? 0));
        }
    }
    return bars;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConfig.surfaceColor,
      appBar: AppBar(
        backgroundColor: AppConfig.primaryColor,
        foregroundColor: Colors.white,
        title: const Text('รายได้'),
        elevation: 0,
      ),
      body: BlocBuilder<ContractorJobBloc, ContractorJobState>(
        buildWhen: (prev, curr) =>
            curr is EarningsLoaded ||
            curr is ContractorJobLoading ||
            curr is ContractorJobError,
        builder: (context, state) {
          if (state is ContractorJobLoading) {
            return const Center(
              child: CircularProgressIndicator(color: AppConfig.primaryColor),
            );
          }
          if (state is ContractorJobError) {
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
                    onPressed: () => context
                        .read<ContractorJobBloc>()
                        .add(LoadEarningsEvent(widget.contractorId)),
                    child: const Text('ลองใหม่'),
                  ),
                ],
              ),
            );
          }
          if (state is EarningsLoaded) {
            return _buildContent(context, state);
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildContent(BuildContext context, EarningsLoaded state) {
    final allTxs = state.transactions;
    final filtered = _filterByPeriod(allTxs);

    final periodEarnings = filtered.fold<double>(0.0, (s, t) => s + t.amount);
    final totalEarnings = allTxs.fold<double>(0.0, (s, t) => s + t.amount);
    final jobCount = filtered.length;

    // ระยะทางรวม + รายได้ต่อกม. ของช่วงที่เลือก (ตาม Mockup 08)
    final periodDistance = filtered.fold<int>(
        0, (s, t) => s + (state.distanceByBiddingId[t.biddingId] ?? 0));
    final perKm = periodDistance > 0 ? periodEarnings / periodDistance : 0.0;

    return RefreshIndicator(
      color: AppConfig.primaryColor,
      onRefresh: () async =>
          context.read<ContractorJobBloc>().add(LoadEarningsEvent(widget.contractorId)),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Earnings card
            _buildEarningsCard(totalEarnings, state.walletBalance),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  final bloc = context.read<ContractorJobBloc>();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => WithdrawPage(
                        contractorId: widget.contractorId,
                        currentBalance: state.walletBalance,
                      ),
                    ),
                  ).then((_) => bloc.add(LoadEarningsEvent(widget.contractorId)));
                },
                icon: const Icon(Icons.account_balance_wallet_outlined),
                label: Text('ถอนเงิน (฿${state.walletBalance.toStringAsFixed(2)})'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppConfig.primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  elevation: 0,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Period filter chips
            SizedBox(
              height: 38,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _periods.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (ctx, i) {
                  final sel = _selectedPeriod == i;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedPeriod = i),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: sel ? AppConfig.primaryColor : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: sel ? AppConfig.primaryColor : const Color(0xFFE0E0E0),
                        ),
                      ),
                      child: Text(
                        _periods[i],
                        style: TextStyle(
                          fontSize: 13,
                          color: sel ? Colors.white : const Color(0xFF424242),
                          fontWeight: sel ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),

            // กราฟรายได้ตามช่วงเวลา (UC 3.1.34)
            if (filtered.isNotEmpty) ...[
              _EarningsBarChart(bars: _bucketize(filtered)),
              const SizedBox(height: 20),
            ],

            // Stats for selected period
            StatsGridWidget(
              items: [
                StatItem(
                  value: _fmt(periodEarnings),
                  label: 'รายได้${_periods[_selectedPeriod]}',
                  valueColor: const Color(0xFF4CAF50),
                ),
                StatItem(
                  value: '$jobCount',
                  label: 'งานที่ทำ',
                  valueColor: AppConfig.primaryColor,
                ),
                StatItem(
                  value: '${_thousands(periodDistance)} กม.',
                  label: 'ระยะทางรวม',
                  valueColor: AppConfig.primaryColor,
                ),
                StatItem(
                  value: _fmt(perKm),
                  label: 'รายได้/กม.',
                  valueColor: const Color(0xFF4CAF50),
                ),
              ],
            ),
            const SizedBox(height: 20),

            SectionTitleWidget(title: 'รายการ${_periods[_selectedPeriod]}'),

            if (filtered.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Column(
                    children: [
                      const Icon(Icons.receipt_long_outlined,
                          size: 64, color: Color(0xFFBDBDBD)),
                      const SizedBox(height: 16),
                      const Text('ไม่มีรายการในช่วงเวลานี้',
                          style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF757575))),
                    ],
                  ),
                ),
              )
            else
              ...filtered.map((tx) => _TransactionItem(transaction: tx)),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildEarningsCard(double totalEarnings, double walletBalance) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppConfig.primaryColor, Color(0xFF1B5E20)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(color: Color(0x332E7D32), blurRadius: 16, offset: Offset(0, 6)),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('รายได้สะสมทั้งหมด',
                    style: TextStyle(fontSize: 13, color: Color(0xE6FFFFFF))),
                const SizedBox(height: 6),
                Text(_fmt(totalEarnings),
                    style: const TextStyle(
                        fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 2),
                const Text('หลังหักค่าธรรมเนียม 1.5%',
                    style: TextStyle(fontSize: 11, color: Color(0xBFFFFFFF))),
              ],
            ),
          ),
          Container(
            width: 1,
            height: 60,
            color: Colors.white24,
            margin: const EdgeInsets.symmetric(horizontal: 16),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text('ยอดในกระเป๋า',
                  style: TextStyle(fontSize: 12, color: Color(0xE6FFFFFF))),
              const SizedBox(height: 4),
              Text(_fmt(walletBalance),
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
            ],
          ),
        ],
      ),
    );
  }

  String _fmt(double amount) =>
      '฿${amount.toStringAsFixed(2).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}';

  String _thousands(int v) => v
      .toString()
      .replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');
}

class _ChartBar {
  final String label;
  final double value;
  const _ChartBar({required this.label, required this.value});
}

/// กราฟแท่งรายได้ วาดเองด้วย CustomPaint (ไม่พึ่ง chart library)
class _EarningsBarChart extends StatelessWidget {
  final List<_ChartBar> bars;
  const _EarningsBarChart({required this.bars});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 190,
      padding: const EdgeInsets.fromLTRB(12, 16, 12, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [AppConfig.cardShadow],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('กราฟรายได้',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Expanded(
            child: CustomPaint(
              size: Size.infinite,
              painter: _BarChartPainter(bars),
            ),
          ),
        ],
      ),
    );
  }
}

class _BarChartPainter extends CustomPainter {
  final List<_ChartBar> bars;
  _BarChartPainter(this.bars);

  @override
  void paint(Canvas canvas, Size size) {
    if (bars.isEmpty) return;
    const labelH = 18.0; // พื้นที่ label ด้านล่าง
    const valueH = 14.0; // พื้นที่ค่าด้านบน
    final chartH = size.height - labelH - valueH;
    final maxVal =
        bars.map((b) => b.value).fold<double>(0, (a, b) => a > b ? a : b);
    final slot = size.width / bars.length;
    final barW = (slot * 0.55).clamp(6.0, 40.0);

    final barPaint = Paint()..color = AppConfig.primaryColor;
    final zeroPaint = Paint()..color = const Color(0xFFE0E0E0);

    for (int i = 0; i < bars.length; i++) {
      final b = bars[i];
      final cx = slot * i + slot / 2;
      final ratio = maxVal <= 0 ? 0.0 : b.value / maxVal;
      final h = (chartH * ratio).clamp(b.value > 0 ? 3.0 : 0.0, chartH);
      final top = valueH + (chartH - h);
      final rect = RRect.fromRectAndCorners(
        Rect.fromLTWH(cx - barW / 2, top, barW, h),
        topLeft: const Radius.circular(4),
        topRight: const Radius.circular(4),
      );
      canvas.drawRRect(rect, b.value > 0 ? barPaint : zeroPaint);

      // ค่าบนแท่ง (เฉพาะที่ > 0)
      if (b.value > 0) {
        _drawText(canvas, _shortMoney(b.value), Offset(cx, top - 2),
            const TextStyle(fontSize: 9, color: Color(0xFF2E7D32)),
            anchorBottom: true);
      }
      // label ล่าง
      _drawText(canvas, b.label, Offset(cx, size.height - labelH + 2),
          const TextStyle(fontSize: 10, color: Color(0xFF757575)));
    }
  }

  void _drawText(Canvas canvas, String text, Offset center, TextStyle style,
      {bool anchorBottom = false}) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
    )..layout();
    final dy = anchorBottom ? center.dy - tp.height : center.dy;
    tp.paint(canvas, Offset(center.dx - tp.width / 2, dy));
  }

  String _shortMoney(double v) {
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}k';
    return v.toStringAsFixed(0);
  }

  @override
  bool shouldRepaint(_BarChartPainter old) => old.bars != bars;
}

class _TransactionItem extends StatelessWidget {
  final TransactionModel transaction;
  const _TransactionItem({required this.transaction});

  String _fmt(DateTime dt) {
    const months = ['', 'ม.ค.', 'ก.พ.', 'มี.ค.', 'เม.ย.', 'พ.ค.', 'มิ.ย.', 'ก.ค.', 'ส.ค.', 'ก.ย.', 'ต.ค.', 'พ.ย.', 'ธ.ค.'];
    return '${dt.day} ${months[dt.month]} ${dt.year + 543}';
  }

  @override
  Widget build(BuildContext context) {
    final fee = transaction.feeAmount ?? 0.0;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          AppConfig.cardShadow,
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: Color(0xFFE8F5E9),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.arrow_downward, color: Color(0xFF4CAF50), size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('รายได้จากงาน',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(_fmt(transaction.transactionDate),
                        style: const TextStyle(fontSize: 12, color: Color(0xFF9E9E9E))),
                    if (fee > 0) ...[
                      const SizedBox(width: 8),
                      Text('ค่าธรรมเนียม -฿${fee.toStringAsFixed(2)}',
                          style: const TextStyle(fontSize: 11, color: Color(0xFFEF5350))),
                    ],
                  ],
                ),
              ],
            ),
          ),
          Text(
            '+฿${transaction.amount.toStringAsFixed(2).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}',
            style: const TextStyle(
                fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF4CAF50)),
          ),
        ],
      ),
    );
  }
}


