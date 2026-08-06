import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/config/app_config.dart';
import '../../../models/models.dart';
import '../bloc/client_stats_bloc.dart';

/// สถิติการใช้งานของผู้ว่าจ้าง (ตาม Mockup 05 จอ 6)
/// การ์ด งานทั้งหมด/สำเร็จ/ค่าขนส่งรวม/น้ำหนักรวม + กราฟค่าใช้จ่าย
/// + สินค้าที่ขนส่งบ่อย + ผู้รับจ้างที่ใช้บ่อย
class ClientStatisticsPage extends StatelessWidget {
  final String clientId;
  const ClientStatisticsPage({super.key, required this.clientId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ClientStatsBloc()..add(LoadClientStats(clientId)),
      child: _ClientStatisticsView(clientId: clientId),
    );
  }
}

class _ClientStatisticsView extends StatefulWidget {
  final String clientId;
  const _ClientStatisticsView({required this.clientId});

  @override
  State<_ClientStatisticsView> createState() => _ClientStatisticsViewState();
}

class _ClientStatisticsViewState extends State<_ClientStatisticsView> {
  int _selectedPeriod = 1; // 0=7วัน 1=เดือนนี้ 2=3เดือน 3=ปีนี้
  static const _periods = ['7 วัน', 'เดือนนี้', '3 เดือน', 'ปีนี้'];
  static const _monthsShort = [
    '', 'ม.ค.', 'ก.พ.', 'มี.ค.', 'เม.ย.', 'พ.ค.', 'มิ.ย.',
    'ก.ค.', 'ส.ค.', 'ก.ย.', 'ต.ค.', 'พ.ย.', 'ธ.ค.'
  ];

  void _reload() =>
      context.read<ClientStatsBloc>().add(LoadClientStats(widget.clientId));

  DateTime get _cutoff {
    final now = DateTime.now();
    switch (_selectedPeriod) {
      case 0:
        return now.subtract(const Duration(days: 7));
      case 2:
        return DateTime(now.year, now.month - 2, now.day);
      case 3:
        return DateTime(now.year, 1, 1);
      case 1:
      default:
        return DateTime(now.year, now.month, 1);
    }
  }

  String _fmtMoney(double v) =>
      '฿${v.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}';

  String _fmtWeight(int kg) {
    if (kg >= 1000) {
      final t = kg / 1000;
      return '${t.toStringAsFixed(t % 1 == 0 ? 0 : 1)} ตัน';
    }
    return '$kg กก.';
  }

  /// จัดกลุ่มค่าใช้จ่ายเป็นแท่งกราฟตามช่วง (7วัน→รายวัน, เดือน→รายสัปดาห์, อื่นๆ→รายเดือน)
  List<_Bar> _bucketize(List<TransactionModel> txs) {
    final now = DateTime.now();
    final bars = <_Bar>[];
    switch (_selectedPeriod) {
      case 0:
        for (int i = 6; i >= 0; i--) {
          final d = DateTime(now.year, now.month, now.day)
              .subtract(Duration(days: i));
          final sum = txs
              .where((t) =>
                  t.transactionDate.year == d.year &&
                  t.transactionDate.month == d.month &&
                  t.transactionDate.day == d.day)
              .fold<double>(0, (s, t) => s + t.amount);
          bars.add(_Bar('${d.day}', sum));
        }
        break;
      case 2:
        for (int i = 2; i >= 0; i--) {
          final m = DateTime(now.year, now.month - i, 1);
          final sum = txs
              .where((t) =>
                  t.transactionDate.year == m.year &&
                  t.transactionDate.month == m.month)
              .fold<double>(0, (s, t) => s + t.amount);
          bars.add(_Bar(_monthsShort[m.month], sum));
        }
        break;
      case 3:
        for (int mo = 1; mo <= now.month; mo++) {
          final sum = txs
              .where((t) =>
                  t.transactionDate.year == now.year &&
                  t.transactionDate.month == mo)
              .fold<double>(0, (s, t) => s + t.amount);
          bars.add(_Bar(_monthsShort[mo], sum));
        }
        break;
      case 1:
      default:
        final weeks = <int, double>{};
        for (final t in txs) {
          final wk = ((t.transactionDate.day - 1) ~/ 7) + 1;
          weeks[wk] = (weeks[wk] ?? 0) + t.amount;
        }
        final maxWk = ((now.day - 1) ~/ 7) + 1;
        for (int w = 1; w <= maxWk; w++) {
          bars.add(_Bar('ส.$w', weeks[w] ?? 0));
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
        title: const Text('สถิติการใช้งาน'),
        elevation: 0,
      ),
      body: BlocBuilder<ClientStatsBloc, ClientStatsState>(
        builder: (context, state) {
          if (state is ClientStatsLoading || state is ClientStatsInitial) {
            return const Center(
                child:
                    CircularProgressIndicator(color: AppConfig.primaryColor));
          }
          if (state is ClientStatsError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(state.message,
                      style: const TextStyle(color: Color(0xFF757575))),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppConfig.primaryColor,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: _reload,
                    child: const Text('ลองใหม่'),
                  ),
                ],
              ),
            );
          }
          return _buildContent((state as ClientStatsLoaded).data);
        },
      ),
    );
  }

  Widget _buildContent(ClientStatsData raw) {
    final cutoff = _cutoff;
    // งานในช่วงที่เลือก (ตามวันโพสต์งาน) ที่ไม่ถูกยกเลิก
    final periodJobs = raw.jobs
        .where((j) =>
            j.createdDate.isAfter(cutoff) && j.jobStatus != 'ยกเลิก')
        .toList();
    final completed = periodJobs
        .where((j) => j.jobStatus == 'จัดส่งสำเร็จ')
        .toList();

    final totalJobs = periodJobs.length;
    final completedCount = completed.length;
    final totalCost = completed.fold<double>(
        0, (s, j) => s + (j.agreedPrice ?? j.budgetPrice).toDouble());
    final totalWeight = completed.fold<int>(0, (s, j) => s + j.weight);

    // สินค้าที่ขนส่งบ่อย (รวมน้ำหนักตามชนิดสินค้า) top 3
    final byProduct = <String, int>{};
    for (final j in completed) {
      byProduct[j.productType] = (byProduct[j.productType] ?? 0) + j.weight;
    }
    final topProducts = byProduct.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final maxProduct =
        topProducts.isEmpty ? 1 : topProducts.first.value;

    // ผู้รับจ้างที่ใช้บ่อย top 3
    final byContractor = <String, int>{};
    for (final j in periodJobs) {
      final cid = raw.contractorIdByJob[j.jobId];
      if (cid != null) byContractor[cid] = (byContractor[cid] ?? 0) + 1;
    }
    final topContractors = byContractor.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // ธุรกรรมค่าใช้จ่ายในช่วง (สำหรับกราฟ)
    final periodPay =
        raw.payTxs.where((t) => t.transactionDate.isAfter(cutoff)).toList();
    final bars = _bucketize(periodPay);

    return RefreshIndicator(
      color: AppConfig.primaryColor,
      onRefresh: () async => _reload(),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
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
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: sel ? AppConfig.primaryColor : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: sel
                            ? AppConfig.primaryColor
                            : const Color(0xFFE0E0E0),
                      ),
                    ),
                    child: Text(
                      _periods[i],
                      style: TextStyle(
                        fontSize: 13,
                        color:
                            sel ? Colors.white : const Color(0xFF424242),
                        fontWeight:
                            sel ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),

          // Stat cards 2x2 (งานทั้งหมด/สำเร็จ/ค่าขนส่งรวม/น้ำหนักรวม)
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.7,
            children: [
              _StatCell(
                  value: '$totalJobs',
                  label: 'งานทั้งหมด',
                  color: AppConfig.accentColor),
              _StatCell(
                  value: '$completedCount',
                  label: 'สำเร็จ',
                  color: const Color(0xFF43A047)),
              _StatCell(
                  value: _fmtMoney(totalCost),
                  label: 'ค่าขนส่งรวม',
                  color: AppConfig.primaryColor),
              _StatCell(
                  value: _fmtWeight(totalWeight),
                  label: 'น้ำหนักรวม',
                  color: const Color(0xFFFB8C00)),
            ],
          ),
          const SizedBox(height: 24),

          // กราฟค่าใช้จ่าย
          _SectionLabel(_selectedPeriod == 1
              ? 'ค่าใช้จ่ายรายสัปดาห์'
              : 'ค่าใช้จ่าย${_periods[_selectedPeriod]}'),
          Container(
            width: double.infinity,
            height: 180,
            padding: const EdgeInsets.fromLTRB(12, 16, 12, 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [AppConfig.cardShadow],
            ),
            child: bars.every((b) => b.value == 0)
                ? const Center(
                    child: Text('ยังไม่มีค่าใช้จ่ายในช่วงนี้',
                        style: TextStyle(
                            color: Color(0xFF9E9E9E), fontSize: 13)),
                  )
                : CustomPaint(
                    size: Size.infinite,
                    painter: _BarChartPainter(bars),
                  ),
          ),
          const SizedBox(height: 24),

          // สินค้าที่ขนส่งบ่อย
          if (topProducts.isNotEmpty) ...[
            _SectionLabel('สินค้าที่ขนส่งบ่อย'),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [AppConfig.cardShadow],
              ),
              child: Column(
                children: [
                  for (final e in topProducts.take(3))
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        children: [
                          const Text('🌾',
                              style: TextStyle(fontSize: 18)),
                          const SizedBox(width: 10),
                          SizedBox(
                            width: 90,
                            child: Text(e.key,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600)),
                          ),
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: e.value / maxProduct,
                                minHeight: 8,
                                backgroundColor: const Color(0xFFEEEEEE),
                                valueColor: const AlwaysStoppedAnimation(
                                    AppConfig.primaryColor),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(_fmtWeight(e.value),
                              style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF616161))),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],

          // ผู้รับจ้างที่ใช้บ่อย
          if (topContractors.isNotEmpty) ...[
            _SectionLabel('ผู้รับจ้างที่ใช้บ่อย'),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [AppConfig.cardShadow],
              ),
              child: Column(
                children: [
                  for (int i = 0; i < topContractors.take(3).length; i++) ...[
                    _ContractorRow(
                      contractor: raw.contractors[topContractors[i].key],
                      jobCount: topContractors[i].value,
                    ),
                    if (i != topContractors.take(3).length - 1)
                      const Divider(height: 1, indent: 16, endIndent: 16),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
        ],
      ),
    );
  }
}

class _Bar {
  final String label;
  final double value;
  const _Bar(this.label, this.value);
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(text,
            style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Color(0xFF424242))),
      );
}

class _StatCell extends StatelessWidget {
  final String value;
  final String label;
  final Color color;
  const _StatCell(
      {required this.value, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [AppConfig.cardShadow],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(value,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color)),
          const SizedBox(height: 4),
          Text(label,
              style: const TextStyle(
                  fontSize: 12, color: Color(0xFF9E9E9E))),
        ],
      ),
    );
  }
}

class _ContractorRow extends StatelessWidget {
  final ContractorModel? contractor;
  final int jobCount;
  const _ContractorRow({required this.contractor, required this.jobCount});

  @override
  Widget build(BuildContext context) {
    final name = contractor != null
        ? '${contractor!.member.prefix ?? ''}${contractor!.member.firstName} ${contractor!.member.lastName}'
            .trim()
        : 'ผู้รับจ้าง';
    final initial = name.isNotEmpty ? name.characters.first : '?';
    final rating = contractor?.ratingScore;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppConfig.primaryColor,
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: Text(initial,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w600)),
                Text('$jobCount งาน',
                    style: const TextStyle(
                        fontSize: 12, color: Color(0xFF9E9E9E))),
              ],
            ),
          ),
          if (rating != null)
            Row(
              children: [
                const Icon(Icons.star_rounded,
                    size: 18, color: Color(0xFFFFC107)),
                const SizedBox(width: 2),
                Text(rating.toStringAsFixed(1),
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFF57C00))),
              ],
            ),
        ],
      ),
    );
  }
}

/// กราฟแท่งค่าใช้จ่าย วาดเองด้วย CustomPaint (สไตล์เดียวกับหน้ารายได้)
class _BarChartPainter extends CustomPainter {
  final List<_Bar> bars;
  _BarChartPainter(this.bars);

  @override
  void paint(Canvas canvas, Size size) {
    if (bars.isEmpty) return;
    const labelH = 18.0;
    const valueH = 14.0;
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
      if (b.value > 0) {
        _text(canvas, _short(b.value), Offset(cx, top - 2),
            const TextStyle(fontSize: 9, color: Color(0xFF2E7D32)),
            bottom: true);
      }
      _text(canvas, b.label, Offset(cx, size.height - labelH + 2),
          const TextStyle(fontSize: 10, color: Color(0xFF757575)));
    }
  }

  void _text(Canvas canvas, String s, Offset center, TextStyle style,
      {bool bottom = false}) {
    final tp = TextPainter(
        text: TextSpan(text: s, style: style),
        textDirection: TextDirection.ltr)
      ..layout();
    final dy = bottom ? center.dy - tp.height : center.dy;
    tp.paint(canvas, Offset(center.dx - tp.width / 2, dy));
  }

  String _short(double v) {
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}k';
    return v.toStringAsFixed(0);
  }

  @override
  bool shouldRepaint(_BarChartPainter old) => old.bars != bars;
}
