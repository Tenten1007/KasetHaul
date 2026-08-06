import 'package:flutter/material.dart';
import '../../../core/config/app_config.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/services/firebase_service.dart';
import '../../truck/pages/truck_list_page.dart';

enum SettingsRole { client, contractor }

class SettingsPage extends StatefulWidget {
  final SettingsRole role;
  final String? contractorId;

  const SettingsPage({
    super.key,
    required this.role,
    this.contractorId,
  });

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _notificationsEnabled = true;

  Color get _primaryColor => AppConfig.primaryColor;

  Future<void> _confirmLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('ออกจากระบบ'),
        content: const Text('ยืนยันออกจากระบบ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('ยกเลิก'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: const Color(0xFFF44336)),
            child: const Text('ออกจากระบบ'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await FirebaseService.auth.signOut();
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          AppRoutes.roleSelect,
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConfig.surfaceColor,
      appBar: AppBar(
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
        title: const Text('ตั้งค่า'),
        elevation: 0,
      ),
      body: ListView(
        children: [
          _SectionHeader('บัญชี'),
          _buildAccountSection(),
          _SectionHeader(
            widget.role == SettingsRole.contractor ? 'รถและเอกสาร' : 'ทั่วไป',
          ),
          if (widget.role == SettingsRole.contractor) ...[
            _buildTruckSection(),
            _SectionHeader('ทั่วไป'),
          ],
          _buildGeneralSection(),
          const SizedBox(height: 24),
          _buildLogoutButton(),
          const SizedBox(height: 24),
          const Center(
            child: Text(
              'KasetHaul v1.0.0',
              style: TextStyle(color: Color(0xFF9E9E9E), fontSize: 12),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildAccountSection() {
    return _SettingsGroup(children: [
      if (widget.role == SettingsRole.client)
        _SettingsItem(
          icon: '📱',
          title: 'เปลี่ยนเบอร์โทรศัพท์',
          onTap: () {},
        )
      else
        _SettingsItem(
          icon: '🔒',
          title: 'เปลี่ยนรหัสผ่าน',
          onTap: () {},
        ),
      _SettingsToggleItem(
        icon: '🔔',
        title: 'การแจ้งเตือน',
        value: _notificationsEnabled,
        activeColor: _primaryColor,
        onChanged: (v) => setState(() => _notificationsEnabled = v),
      ),
      _SettingsItem(
        icon: '🌐',
        title: 'ภาษา',
        subtitle: 'ไทย',
        onTap: () {},
      ),
    ]);
  }

  Widget _buildTruckSection() {
    return _SettingsGroup(children: [
      _SettingsItem(
        icon: '🚛',
        title: 'จัดการรถของฉัน',
        onTap: () {
          if (widget.contractorId != null) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => TruckListPage(contractorId: widget.contractorId!),
              ),
            );
          }
        },
      ),
      _SettingsItem(
        icon: '📄',
        title: 'เอกสารและใบอนุญาต',
        onTap: () {},
      ),
    ]);
  }

  Widget _buildGeneralSection() {
    return _SettingsGroup(children: [
      _SettingsItem(
        icon: '❓',
        title: 'ศูนย์ช่วยเหลือ',
        onTap: () {},
      ),
      _SettingsItem(
        icon: '📄',
        title: 'ข้อกำหนดและเงื่อนไข',
        onTap: () {},
      ),
    ]);
  }

  Widget _buildLogoutButton() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFFCDD2)),
      ),
      child: ListTile(
        leading: const Text('🚪', style: TextStyle(fontSize: 20)),
        title: const Text(
          'ออกจากระบบ',
          style: TextStyle(
            color: Color(0xFFF44336),
            fontWeight: FontWeight.w500,
          ),
        ),
        trailing: const Icon(Icons.chevron_right, color: Color(0xFFF44336)),
        onTap: _confirmLogout,
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Color(0xFF757575),
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  final List<Widget> children;
  const _SettingsGroup({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          for (int i = 0; i < children.length; i++) ...[
            children[i],
            if (i < children.length - 1)
              const Divider(height: 1, indent: 52, endIndent: 0),
          ],
        ],
      ),
    );
  }
}

class _SettingsItem extends StatelessWidget {
  final String icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  const _SettingsItem({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Text(icon, style: const TextStyle(fontSize: 20)),
      title: Text(title, style: const TextStyle(fontSize: 15)),
      subtitle: subtitle != null
          ? Text(subtitle!, style: const TextStyle(color: Color(0xFF9E9E9E), fontSize: 13))
          : null,
      trailing: const Icon(Icons.chevron_right, color: Color(0xFFBDBDBD)),
      onTap: onTap,
    );
  }
}

class _SettingsToggleItem extends StatelessWidget {
  final String icon;
  final String title;
  final bool value;
  final Color activeColor;
  final ValueChanged<bool> onChanged;

  const _SettingsToggleItem({
    required this.icon,
    required this.title,
    required this.value,
    required this.activeColor,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Text(icon, style: const TextStyle(fontSize: 20)),
      title: Text(title, style: const TextStyle(fontSize: 15)),
      trailing: Switch(
        value: value,
        activeColor: activeColor,
        onChanged: onChanged,
      ),
    );
  }
}


