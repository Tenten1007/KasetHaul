import 'package:flutter/material.dart';
import '../../../core/config/app_config.dart';
import '../../job/pages/my_jobs_page.dart';
import '../../job/pages/post_job_page.dart';
import '../../profile/pages/client_profile_page.dart';
import '../../wallet/pages/wallet_page.dart';

class ClientHomePage extends StatefulWidget {
  final String clientId;
  const ClientHomePage({super.key, required this.clientId});

  @override
  State<ClientHomePage> createState() => _ClientHomePageState();
}

class _ClientHomePageState extends State<ClientHomePage> {
  int _currentIndex = 0;

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      MyJobsPage(clientId: widget.clientId),
      WalletPage(clientId: widget.clientId),
      ClientProfilePage(clientId: widget.clientId),
    ];
  }

  Future<void> _openPostJob() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PostJobPage(clientId: widget.clientId),
      ),
    );
    // กลับมาที่ "งานของฉัน" เพื่อแสดงงานที่สร้างใหม่
    if (mounted) setState(() => _currentIndex = 0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Color(0xFFE0E0E0))),
        ),
        child: SafeArea(
          child: SizedBox(
            height: 64,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _NavItem(
                  icon: '📦',
                  label: 'งานของฉัน',
                  active: _currentIndex == 0,
                  onTap: () => setState(() => _currentIndex = 0),
                ),
                _NavItem(
                  icon: '➕',
                  label: 'โพสต์งาน',
                  active: false,
                  onTap: _openPostJob,
                ),
                _NavItem(
                  icon: '💰',
                  label: 'กระเป๋าเงิน',
                  active: _currentIndex == 1,
                  onTap: () => setState(() => _currentIndex = 1),
                ),
                _NavItem(
                  icon: '👤',
                  label: 'โปรไฟล์',
                  active: _currentIndex == 2,
                  onTap: () => setState(() => _currentIndex = 2),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final String icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 72,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(icon, style: const TextStyle(fontSize: 24)),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: active ? AppConfig.primaryColor : const Color(0xFF9E9E9E),
                fontWeight: active ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
