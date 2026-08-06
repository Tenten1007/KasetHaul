import 'package:flutter/material.dart';
import '../../../core/config/app_config.dart';
import '../../../models/models.dart';

class TransactionHistoryPage extends StatefulWidget {
  final List<TransactionModel> transactions;

  const TransactionHistoryPage({super.key, required this.transactions});

  @override
  State<TransactionHistoryPage> createState() => _TransactionHistoryPageState();
}

class _TransactionHistoryPageState extends State<TransactionHistoryPage> {
  int _filterIndex = 0; // 0=ทั้งหมด 1=เติมเงิน 2=ชำระเงิน 3=คืนเงิน
  late DateTime _selectedMonth;

  static const _tabs = ['ทั้งหมด', 'เติมเงิน', 'ชำระเงิน', 'คืนเงิน'];

  @override
  void initState() {
    super.initState();
    _selectedMonth = DateTime.now();
  }

  List<TransactionModel> get _filtered {
    final inMonth = widget.transactions.where((t) =>
        t.transactionDate.year == _selectedMonth.year &&
        t.transactionDate.month == _selectedMonth.month);

    if (_filterIndex == 0) return inMonth.toList();
    if (_filterIndex == 1) {
      return inMonth.where((t) => t.transactionType == 'เติมเงิน').toList();
    }
    if (_filterIndex == 2) {
      return inMonth.where((t) => t.transactionType == 'จ่ายค่างาน').toList();
    }
    return inMonth.where((t) => t.transactionType == 'คืนเงิน').toList();
  }

  // Group transactions by date (yyyy-mm-dd)
  Map<String, List<TransactionModel>> get _grouped {
    final result = <String, List<TransactionModel>>{};
    for (final t in _filtered) {
      final key =
          '${t.transactionDate.year}-${t.transactionDate.month.toString().padLeft(2, '0')}-${t.transactionDate.day.toString().padLeft(2, '0')}';
      result.putIfAbsent(key, () => []).add(t);
    }
    return result;
  }

  String _formatMonthThai(DateTime dt) {
    const months = [
      '', 'มกราคม', 'กุมภาพันธ์', 'มีนาคม', 'เมษายน', 'พฤษภาคม', 'มิถุนายน',
      'กรกฎาคม', 'สิงหาคม', 'กันยายน', 'ตุลาคม', 'พฤศจิกายน', 'ธันวาคม',
    ];
    return '${months[dt.month]} ${dt.year + 543}';
  }

  String _formatDayThai(String key) {
    final parts = key.split('-');
    final day = int.parse(parts[2]);
    final month = int.parse(parts[1]);
    final year = int.parse(parts[0]);
    const months = [
      '', 'มกราคม', 'กุมภาพันธ์', 'มีนาคม', 'เมษายน', 'พฤษภาคม', 'มิถุนายน',
      'กรกฎาคม', 'สิงหาคม', 'กันยายน', 'ตุลาคม', 'พฤศจิกายน', 'ธันวาคม',
    ];
    return '$day ${months[month]} ${year + 543}';
  }

  void _changeMonth() async {
    final picked = await showDialog<DateTime>(
      context: context,
      builder: (ctx) => _MonthPickerDialog(selected: _selectedMonth),
    );
    if (picked != null) setState(() => _selectedMonth = picked);
  }

  @override
  Widget build(BuildContext context) {
    final grouped = _grouped;

    return Scaffold(
      backgroundColor: AppConfig.surfaceColor,
      appBar: AppBar(
        backgroundColor: AppConfig.primaryColor,
        foregroundColor: Colors.white,
        title: const Text('ประวัติธุรกรรม'),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Filter tabs
          Container(
            color: Colors.white,
            child: Row(
              children: List.generate(_tabs.length, (i) {
                final selected = _filterIndex == i;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _filterIndex = i),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: selected
                                ? AppConfig.primaryColor
                                : Colors.transparent,
                            width: 2,
                          ),
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        _tabs[i],
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: selected
                              ? FontWeight.w600
                              : FontWeight.normal,
                          color: selected
                              ? AppConfig.primaryColor
                              : const Color(0xFF757575),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),

          // Month filter
          Container(
            color: AppConfig.surfaceColor,
            padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _formatMonthThai(_selectedMonth),
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 14),
                ),
                GestureDetector(
                  onTap: _changeMonth,
                  child: Text(
                    'เปลี่ยนเดือน ▼',
                    style: TextStyle(
                        color: AppConfig.primaryColor, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),

          // Transaction list
          Expanded(
            child: grouped.isEmpty
                ? const Center(
                    child: Text('ไม่มีรายการในเดือนนี้',
                        style: TextStyle(color: Color(0xFF757575))),
                  )
                : ListView(
                    children: grouped.entries.map((entry) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Date header
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 8),
                            color: const Color(0xFFF0F0F0),
                            child: Text(
                              _formatDayThai(entry.key),
                              style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF616161)),
                            ),
                          ),
                          ...entry.value.map(
                            (tx) => _TransactionTile(transaction: tx),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
          ),
        ],
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  final TransactionModel transaction;
  const _TransactionTile({required this.transaction});

  bool get _isIncome =>
      transaction.transactionType == 'เติมเงิน' ||
      transaction.transactionType == 'รับค่างาน';

  bool get _isPending => transaction.transactionStatus == 'กำลังขนส่ง';

  Color get _iconBg {
    if (_isPending) return const Color(0xFFFFF3E0);
    if (_isIncome) return const Color(0xFFE8F5E9);
    return const Color(0xFFFFEBEE);
  }

  String get _iconEmoji {
    if (_isPending) return '🔒';
    if (_isIncome) return '📥';
    return '📤';
  }

  String get _timeText {
    final t = transaction.transactionDate;
    final h = t.hour.toString().padLeft(2, '0');
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m น.';
  }

  String get _subtitle {
    final method = transaction.bankName;
    if (method != null) return '$_timeText | $method';
    return _timeText;
  }

  String get _amountText {
    final formatted = transaction.amount
        .toStringAsFixed(0)
        .replaceAllMapped(
            RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');
    return _isIncome ? '+฿$formatted' : '-฿$formatted';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: _iconBg,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(_iconEmoji, style: const TextStyle(fontSize: 18)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.transactionType +
                      (transaction.referenceNo != null
                          ? ' ${transaction.referenceNo}'
                          : ''),
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 2),
                Text(
                  _subtitle,
                  style: const TextStyle(
                      fontSize: 12, color: Color(0xFF9E9E9E)),
                ),
              ],
            ),
          ),
          Text(
            _amountText,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: _isIncome
                  ? const Color(0xFF4CAF50)
                  : const Color(0xFFF44336),
            ),
          ),
        ],
      ),
    );
  }
}

class _MonthPickerDialog extends StatefulWidget {
  final DateTime selected;
  const _MonthPickerDialog({required this.selected});

  @override
  State<_MonthPickerDialog> createState() => _MonthPickerDialogState();
}

class _MonthPickerDialogState extends State<_MonthPickerDialog> {
  late int _year;

  @override
  void initState() {
    super.initState();
    _year = widget.selected.year;
  }

  static const _months = [
    'มกราคม', 'กุมภาพันธ์', 'มีนาคม', 'เมษายน',
    'พฤษภาคม', 'มิถุนายน', 'กรกฎาคม', 'สิงหาคม',
    'กันยายน', 'ตุลาคม', 'พฤศจิกายน', 'ธันวาคม',
  ];

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () => setState(() => _year--),
          ),
          Text('$_year', style: const TextStyle(fontWeight: FontWeight.bold)),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () => setState(() => _year++),
          ),
        ],
      ),
      content: SizedBox(
        width: 280,
        child: GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          childAspectRatio: 1.8,
          children: List.generate(12, (i) {
            final selected = _year == widget.selected.year &&
                (i + 1) == widget.selected.month;
            return GestureDetector(
              onTap: () {
                Navigator.pop(context, DateTime(_year, i + 1));
              },
              child: Container(
                margin: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color:
                      selected ? AppConfig.primaryColor : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: Text(
                  _months[i],
                  style: TextStyle(
                    fontSize: 12,
                    color:
                        selected ? Colors.white : const Color(0xFF424242),
                    fontWeight: selected
                        ? FontWeight.w600
                        : FontWeight.normal,
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}


