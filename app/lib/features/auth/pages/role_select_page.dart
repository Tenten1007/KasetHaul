import 'package:flutter/material.dart';
import '../../../core/config/app_config.dart';
import 'phone_input_page.dart';
import 'register_client_page.dart';
import 'register_contractor_page.dart';
import 'seed_data_page.dart';

/// หน้าแรก: Splash/Welcome screen ตาม mockup 01-auth.html (Screen 1)
/// กดเข้าสู่ระบบ → PhoneInputPage (login)
/// กดลงทะเบียน → RolePickPage (เลือก role)
/// กดที่ logo 5 ครั้ง → SeedDataPage (debug only)
class RoleSelectPage extends StatefulWidget {
  const RoleSelectPage({super.key});

  @override
  State<RoleSelectPage> createState() => _RoleSelectPageState();
}

class _RoleSelectPageState extends State<RoleSelectPage> {
  int _tapCount = 0;

  void _onLogoTap() {
    _tapCount++;
    if (_tapCount >= 5) {
      _tapCount = 0;
      Navigator.push(context, MaterialPageRoute(builder: (_) => const SeedDataPage()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppConfig.primaryColor, AppConfig.primaryDarkColor],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // Center content
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo — กด 5 ครั้งเพื่อเข้า Dev Seed
                    GestureDetector(
                      onTap: _onLogoTap,
                      child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x33000000),
                            blurRadius: 16,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: const Text('🌾', style: TextStyle(fontSize: 56)),
                    ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'KasetHaul',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'แอปจ้างขนส่งสินค้าเกษตร',
                      style: TextStyle(fontSize: 16, color: Color(0xE6FFFFFF)),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'อ.แม่แจ่ม จ.เชียงใหม่',
                      style: TextStyle(fontSize: 14, color: Color(0xB3FFFFFF)),
                    ),
                  ],
                ),
              ),

              // Bottom buttons
              Positioned(
                bottom: 48,
                left: 40,
                right: 40,
                child: Column(
                  children: [
                    // เข้าสู่ระบบ
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const PhoneInputPage(),
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AppConfig.primaryColor,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                        child: const Text(
                          'เข้าสู่ระบบ',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // ลงทะเบียน
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const RolePickPage(),
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white, width: 2),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text(
                          'ลงทะเบียน',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// หน้าเลือก role ตาม mockup Screen 3
/// [verifiedPhone] = เบอร์ที่ผ่าน OTP มาแล้ว (มาจากหน้า login เมื่อเบอร์ยังไม่มีบัญชี)
/// → ส่งต่อให้ register page ข้ามขั้นกรอกเบอร์/OTP
class RolePickPage extends StatefulWidget {
  final String? verifiedPhone;
  const RolePickPage({super.key, this.verifiedPhone});

  @override
  State<RolePickPage> createState() => _RolePickPageState();
}

class _RolePickPageState extends State<RolePickPage> {
  String _selectedRole = 'client';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        titleTextStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF212121)),
        foregroundColor: AppConfig.textPrimaryColor,
        elevation: 0,
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: Color(0xFFE0E0E0)),
        ),
        title: const Text(
          'ลงทะเบียน',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const SizedBox(height: 20),
              const Text(
                'คุณต้องการใช้งานเป็น',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              const Text(
                'เลือกประเภทผู้ใช้งาน',
                style: TextStyle(color: Color(0xFF757575), fontSize: 14),
              ),
              const SizedBox(height: 32),

              // Client card
              _RoleCard(
                emoji: '👨‍🌾',
                emojiBackground: const Color(0xFFE8F5E9),
                title: 'เกษตรกร',
                subtitle: 'เกษตรกร / พ่อค้าคนกลาง\nต้องการจ้างขนส่งสินค้าเกษตร',
                titleColor: AppConfig.primaryColor,
                selected: _selectedRole == 'client',
                onTap: () => setState(() => _selectedRole = 'client'),
              ),
              const SizedBox(height: 12),

              // Contractor card
              _RoleCard(
                emoji: '🚛',
                emojiBackground: const Color(0xFFFFF3E0),
                title: 'ผู้รับจ้าง (Contractor)',
                subtitle: 'เจ้าของรถบรรทุก\nรับจ้างขนส่งสินค้า',
                titleColor: const Color(0xFF424242),
                selectedColor: AppConfig.secondaryColor,
                selected: _selectedRole == 'contractor',
                onTap: () => setState(() => _selectedRole = 'contractor'),
              ),

              const Spacer(),

              // ถัดไป button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => _selectedRole == 'client'
                          ? RegisterClientPage(
                              phoneNumber: widget.verifiedPhone,
                              phoneVerified: widget.verifiedPhone != null,
                            )
                          : RegisterContractorPage(
                              phoneNumber: widget.verifiedPhone,
                              phoneVerified: widget.verifiedPhone != null,
                            ),
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppConfig.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text(
                    'ถัดไป',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final String emoji;
  final Color emojiBackground;
  final String title;
  final String subtitle;
  final Color titleColor;
  final Color selectedColor;
  final bool selected;
  final VoidCallback onTap;

  const _RoleCard({
    required this.emoji,
    required this.emojiBackground,
    required this.title,
    required this.subtitle,
    required this.titleColor,
    this.selectedColor = AppConfig.primaryColor,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedOpacity(
        opacity: selected ? 1.0 : 0.7,
        duration: const Duration(milliseconds: 200),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? selectedColor : const Color(0xFFE0E0E0),
              width: selected ? 2 : 1,
            ),
            boxShadow: const [
              BoxShadow(color: Color(0x1A000000), blurRadius: 8, offset: Offset(0, 2)),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: emojiBackground,
                  borderRadius: BorderRadius.circular(16),
                ),
                alignment: Alignment.center,
                child: Text(emoji, style: const TextStyle(fontSize: 28)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: titleColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF757575),
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                selected ? '✓' : '○',
                style: TextStyle(
                  fontSize: 24,
                  color: selected ? selectedColor : const Color(0xFFBDBDBD),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
