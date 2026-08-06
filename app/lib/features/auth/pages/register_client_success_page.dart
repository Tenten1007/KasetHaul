import 'package:flutter/material.dart';
import '../../../core/config/app_config.dart';
import '../../../models/models.dart';
import 'client_home_page.dart';

class RegisterClientSuccessPage extends StatelessWidget {
  final ClientModel client;
  const RegisterClientSuccessPage({super.key, required this.client});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 120,
                  height: 120,
                  decoration: const BoxDecoration(
                    color: Color(0xFFE8F5E9),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Text('✓',
                        style: TextStyle(
                            fontSize: 60,
                            color: AppConfig.primaryColor,
                            fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 32),
                const Text(
                  'ลงทะเบียนสำเร็จ!',
                  style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: AppConfig.primaryColor),
                ),
                const SizedBox(height: 12),
                const Text(
                  'ยินดีต้อนรับสู่ KasetHaul\nคุณพร้อมเริ่มโพสต์งานได้แล้ว',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Color(0xFF757575)),
                ),
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(
                          builder: (_) =>
                              ClientHomePage(clientId: client.clientId),
                        ),
                        (_) => false,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppConfig.primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    child: const Text('เริ่มใช้งาน (เกษตรกร)',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
