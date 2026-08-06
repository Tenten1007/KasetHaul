import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/config/app_config.dart';
import '../../../core/repositories/repositories.dart';
import '../../../models/models.dart';
import '../../../shared/widgets/wallet_balance_card.dart';
import '../../../shared/widgets/stats_grid_widget.dart';
import '../../../shared/widgets/section_title_widget.dart';
import '../bloc/wallet_bloc.dart';
import '../bloc/wallet_event.dart';
import '../bloc/wallet_state.dart';
import 'top_up_page.dart';
import 'client_statistics_page.dart';
import 'transaction_history_page.dart';

class WalletPage extends StatelessWidget {
  final String clientId;
  const WalletPage({super.key, required this.clientId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => WalletBloc(
        clientRepository: ClientRepository(),
        transactionRepository: TransactionRepository(),
      )..add(LoadWalletEvent(clientId: clientId)),
      child: _WalletView(clientId: clientId),
    );
  }
}

class _WalletView extends StatelessWidget {
  final String clientId;
  const _WalletView({required this.clientId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConfig.surfaceColor,
      appBar: AppBar(
        backgroundColor: AppConfig.primaryColor,
        foregroundColor: Colors.white,
        title: const Text('กระเป๋าเงิน'),
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'สถิติการใช้จ่าย',
            icon: const Text('⚙️', style: TextStyle(fontSize: 20)),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ClientStatisticsPage(clientId: clientId),
              ),
            ),
          ),
        ],
      ),
      body: BlocBuilder<WalletBloc, WalletState>(
        builder: (context, state) {
          if (state is WalletLoading || state is WalletInitial) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is WalletError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(state.message,
                      style: const TextStyle(color: Color(0xFF757575))),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => context
                        .read<WalletBloc>()
                        .add(LoadWalletEvent(clientId: clientId)),
                    child: const Text('ลองใหม่'),
                  ),
                ],
              ),
            );
          }
          if (state is WalletLoaded) {
            return _WalletContent(
              client: state.client,
              transactions: state.transactions,
              clientId: clientId,
            );
          }
          return const SizedBox();
        },
      ),
    );
  }
}

class _WalletContent extends StatelessWidget {
  final ClientModel client;
  final List<TransactionModel> transactions;
  final String clientId;

  const _WalletContent({
    required this.client,
    required this.transactions,
    required this.clientId,
  });

  double get _thisMonthSpend {
    final now = DateTime.now();
    return transactions
        .where((t) =>
            t.transactionType != 'เติมเงิน' &&
            t.transactionDate.month == now.month &&
            t.transactionDate.year == now.year)
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  double get _totalSpend {
    return transactions
        .where((t) => t.transactionType != 'เติมเงิน')
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  @override
  Widget build(BuildContext context) {
    final pendingTxs = transactions
        .where((t) => t.transactionStatus == 'กำลังขนส่ง')
        .toList();
    final recentTxs = transactions.take(5).toList();

    return RefreshIndicator(
      onRefresh: () async {
        context
            .read<WalletBloc>()
            .add(LoadWalletEvent(clientId: clientId));
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Balance card
            WalletBalanceCard(
              balance: client.walletBalance,
              pendingBalance: client.pendingBalance,
              onTopUp: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => BlocProvider(
                      create: (_) => WalletBloc(
                        clientRepository: ClientRepository(),
                        transactionRepository: TransactionRepository(),
                      ),
                      child: TopUpPage(clientId: clientId),
                    ),
                  ),
                );
                if (context.mounted) {
                  context
                      .read<WalletBloc>()
                      .add(LoadWalletEvent(clientId: clientId));
                }
              },
              // ผู้ว่าจ้างไม่มีการถอนเงินตาม SRS (UC 3.1.33 ถอนเงิน = ผู้รับจ้าง)
              onWithdraw: null,
            ),
            const SizedBox(height: 20),

            // Stats grid
            StatsGridWidget(
              items: [
                StatItem(
                  value:
                      '฿${_thisMonthSpend.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}',
                  label: 'จ่ายเดือนนี้',
                  valueColor: const Color(0xFFF44336),
                ),
                StatItem(
                  value:
                      '฿${_totalSpend.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}',
                  label: 'ยอดรวมทั้งหมด',
                  valueColor: const Color(0xFFFFC107),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Pending holds
            if (pendingTxs.isNotEmpty) ...[
              const SectionTitleWidget(title: 'เงินที่ถูกกันไว้'),
              ...pendingTxs.map((tx) => _PendingHoldItem(transaction: tx)),
              const SizedBox(height: 8),
            ],

            // Recent transactions
            const SectionTitleWidget(title: 'ประวัติล่าสุด'),
            if (recentTxs.isEmpty)
              Container(
                padding: const EdgeInsets.all(32),
                alignment: Alignment.center,
                child: const Text(
                  'ยังไม่มีรายการ',
                  style: TextStyle(color: Color(0xFF757575)),
                ),
              )
            else
              ...recentTxs.map((tx) => _TransactionItem(transaction: tx)),

            const SizedBox(height: 16),
            if (transactions.length > 5)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => TransactionHistoryPage(
                        transactions: transactions,
                      ),
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppConfig.primaryColor,
                    side: const BorderSide(color: AppConfig.primaryColor),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('ดูประวัติทั้งหมด'),
                ),
              ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class _PendingHoldItem extends StatelessWidget {
  final TransactionModel transaction;
  const _PendingHoldItem({required this.transaction});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: const Border(
          left: BorderSide(color: Color(0xFFFFC107), width: 4),
        ),
        boxShadow: const [
          BoxShadow(color: Color(0x1A000000), blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.transactionType,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  transaction.transactionStatus,
                  style: const TextStyle(fontSize: 13, color: Color(0xFF757575)),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '-฿${transaction.amount.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFFFC107),
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3E0),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'กำลังขนส่ง',
                  style: TextStyle(fontSize: 11, color: Color(0xFFE65100), fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TransactionItem extends StatelessWidget {
  final TransactionModel transaction;
  const _TransactionItem({required this.transaction});

  bool get _isIncome => transaction.transactionType == 'เติมเงิน';

  String _formatDate(DateTime dt) {
    const months = [
      '', 'ม.ค.', 'ก.พ.', 'มี.ค.', 'เม.ย.', 'พ.ค.', 'มิ.ย.',
      'ก.ค.', 'ส.ค.', 'ก.ย.', 'ต.ค.', 'พ.ย.', 'ธ.ค.'
    ];
    return '${dt.day} ${months[dt.month]} ${dt.year - 543 + 2500} | ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')} น.';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
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
            decoration: BoxDecoration(
              color: _isIncome
                  ? const Color(0xFFE8F5E9)
                  : const Color(0xFFFFEBEE),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              _isIncome ? '📥' : '📤',
              style: const TextStyle(fontSize: 20),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.transactionType,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 2),
                Text(
                  _formatDate(transaction.transactionDate),
                  style: const TextStyle(fontSize: 12, color: Color(0xFF757575)),
                ),
              ],
            ),
          ),
          Text(
            '${_isIncome ? '+' : '-'}฿${transaction.amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}',
            style: TextStyle(
              fontSize: 16,
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


