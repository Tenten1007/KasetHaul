import 'package:flutter/material.dart';
import '../../core/config/app_config.dart';

class WalletBalanceCard extends StatelessWidget {
  final double balance;
  final double pendingBalance;
  final VoidCallback? onTopUp;
  final VoidCallback? onWithdraw;

  const WalletBalanceCard({
    super.key,
    required this.balance,
    required this.pendingBalance,
    this.onTopUp,
    this.onWithdraw,
  });

  String _formatAmount(double amount) {
    return '฿${amount.toStringAsFixed(2).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppConfig.primaryColor, AppConfig.primaryDarkColor],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          const Text(
            'ยอดที่ใช้ได้',
            style: TextStyle(fontSize: 14, color: Color(0xE6FFFFFF)),
          ),
          const SizedBox(height: 8),
          Text(
            _formatAmount(balance),
            style: const TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'ยอดมัดจำที่ถูกกัน',
                style: TextStyle(fontSize: 13, color: Color(0xBFFFFFFF)),
              ),
              const SizedBox(width: 6),
              Text(
                _formatAmount(pendingBalance),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFFFD54F),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _ActionButton(
                label: '+ เติมเงิน',
                onTap: onTopUp,
              ),
              // ปุ่มถอนเงินแสดงเฉพาะเมื่อมี callback (ผู้รับจ้าง — UC 3.1.33)
              // ฝั่งผู้ว่าจ้างไม่มีการถอนเงินตาม SRS จึงส่ง onWithdraw = null
              if (onWithdraw != null) ...[
                const SizedBox(width: 16),
                _ActionButton(
                  label: 'ถอนเงิน',
                  onTap: onWithdraw,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;

  const _ActionButton({required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
