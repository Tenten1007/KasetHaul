import 'package:flutter/material.dart';
import '../../../models/models.dart';
import 'contractor_home_page.dart';

class RegisterContractorSuccessPage extends StatelessWidget {
  final ContractorModel contractor;
  const RegisterContractorSuccessPage({super.key, required this.contractor});

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
                    color: Color(0xFFFFF3E0),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Text('🚛', style: TextStyle(fontSize: 60)),
                  ),
                ),
                const SizedBox(height: 32),
                const Text(
                  'ลงทะเบียนสำเร็จ!',
                  style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFFF9800)),
                ),
                const SizedBox(height: 12),
                const Text(
                  'ยินดีต้อนรับสู่ KasetHaul\nข้อมูลยืนยันตัวตนอยู่ระหว่างตรวจสอบ',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Color(0xFF757575)),
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE3F2FD),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    children: [
                      Text('⏳', style: TextStyle(fontSize: 24)),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('รอตรวจสอบ Thai ID',
                                style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF1565C0),
                                    fontSize: 14)),
                            SizedBox(height: 4),
                            Text('คุณจะได้รับแจ้งเตือนเมื่อผ่านการตรวจสอบ',
                                style: TextStyle(
                                    color: Color(0xFF757575), fontSize: 12)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF3E0),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'หมายเหตุ: กรุณาเพิ่มข้อมูลรถของคุณ\nเพื่อเตรียมพร้อมรับงานขนส่ง',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, color: Color(0xFFE65100)),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(
                          builder: (_) => ContractorHomePage(
                              contractorId: contractor.contractorId),
                        ),
                        (_) => false,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF9800),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    child: const Text('เริ่มใช้งาน (ผู้รับจ้าง)',
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
