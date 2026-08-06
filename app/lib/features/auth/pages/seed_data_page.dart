import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../../core/config/app_config.dart';
import '../../../core/services/firebase_service.dart';
import '../../../models/models.dart';
import 'admin_login_page.dart';

class SeedDataPage extends StatefulWidget {
  const SeedDataPage({super.key});

  @override
  State<SeedDataPage> createState() => _SeedDataPageState();
}

class _SeedDataPageState extends State<SeedDataPage> {
  final _clientPhoneCtrl = TextEditingController(text: '0894561232');
  final _contractorPhoneCtrl = TextEditingController(text: '0891234567');
  final _formKey = GlobalKey<FormState>();

  bool _seeding = false;
  _SeedResult? _result;
  String? _error;

  @override
  void dispose() {
    _clientPhoneCtrl.dispose();
    _contractorPhoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _seed() async {
    if (!_formKey.currentState!.validate()) return;
    final clientPhone = _clientPhoneCtrl.text.trim();
    final contractorPhone = _contractorPhoneCtrl.text.trim();

    setState(() {
      _seeding = true;
      _error = null;
      _result = null;
    });

    try {
      // sign in anonymously เพื่อผ่าน isAuth() ใน Firestore rules
      if (FirebaseService.auth.currentUser == null) {
        await FirebaseService.auth.signInAnonymously();
      }

      const uuid = Uuid();
      final now = DateTime.now();
      final db = FirebaseService.firestore;

      // ── 1. สร้าง / ดึง Client ──────────────────────────────────────────────
      String clientId;
      final existingClientSnap = await FirebaseService.clients
          .where('member.phoneNumber', isEqualTo: clientPhone)
          .limit(1)
          .get();

      if (existingClientSnap.docs.isNotEmpty) {
        clientId = existingClientSnap.docs.first.id;
      } else {
        clientId = uuid.v4();
        final memberId = uuid.v4();
        final client = ClientModel(
          clientId: clientId,
          member: MemberModel(
            memberId: memberId,
            phoneNumber: clientPhone,
            firstName: 'ทดสอบ',
            lastName: 'ผู้ว่าจ้าง',
            province: 'เชียงใหม่',
            memberSince: now,
          ),
          walletBalance: 20000,
          pendingBalance: 0,
        );
        await FirebaseService.clients.doc(clientId).set(client.toJson());
      }

      // ── 2. สร้าง / ดึง Contractor ─────────────────────────────────────────
      String contractorId;
      final existingContSnap = await FirebaseService.contractors
          .where('member.phoneNumber', isEqualTo: contractorPhone)
          .limit(1)
          .get();

      if (existingContSnap.docs.isNotEmpty) {
        contractorId = existingContSnap.docs.first.id;
      } else {
        contractorId = uuid.v4();
        final memberId = uuid.v4();
        final contractor = ContractorModel(
          contractorId: contractorId,
          member: MemberModel(
            memberId: memberId,
            phoneNumber: contractorPhone,
            firstName: 'ทดสอบ',
            lastName: 'ผู้รับจ้าง',
            province: 'เชียงใหม่',
            memberSince: now,
          ),
          isIdentityVerified: true,
          driverTier: 'ทั่วไป',
          walletBalance: 0,
          pendingBalance: 0,
        );
        await FirebaseService.contractors.doc(contractorId).set(contractor.toJson());
      }

      // ── 3. สร้าง / ดึง Truck ──────────────────────────────────────────────
      String truckId;
      TruckTypeModel truckType;
      final existingTruckSnap = await FirebaseService.trucks
          .where('contractorId', isEqualTo: contractorId)
          .where('approvalStatus', isEqualTo: 'อนุมัติแล้ว')
          .limit(1)
          .get();

      if (existingTruckSnap.docs.isNotEmpty) {
        truckId = existingTruckSnap.docs.first.id;
        final truckData = existingTruckSnap.docs.first.data() as Map<String, dynamic>;
        truckType = TruckTypeModel.fromJson(truckData['truckType'] as Map<String, dynamic>);
      } else {
        truckId = uuid.v4();
        truckType = const TruckTypeModel(
          truckTypeId: 'type_pickup',
          typeName: 'รถกระบะ',
          maxWeightCapacity: 1000,
        );
        final truck = TruckModel(
          truckId: truckId,
          brand: 'Toyota',
          model: 'Hilux Revo',
          licensePlate: 'ทด 0001',
          registeredProvince: 'เชียงใหม่',
          capacity: 1000,
          approvalStatus: 'อนุมัติแล้ว',
          contractorId: contractorId,
          truckType: truckType,
        );
        await FirebaseService.trucks.doc(truckId).set(truck.toJson());
      }

      // ── 4. สร้าง Job (มอบหมายแล้ว) ───────────────────────────────────────
      final jobId = uuid.v4();
      final job = JobModel(
        jobId: jobId,
        jobTitle: 'ทดสอบ GPS — ขนข้าวโพด',
        productType: 'ข้าวโพด',
        weight: 800,
        description: 'ข้อมูลทดสอบระบบ GPS Tracking',
        distance: 80,
        pickupAddress: 'ตลาดเกษตรกร อ.สันทราย จ.เชียงใหม่',
        pickupName: 'คุณทดสอบ ระบบ',
        pickupPhone: '0800000000',
        pickupDatetime: now.add(const Duration(hours: 2)),
        dropoffAddress: 'โรงงานแปรรูป อ.เมือง จ.ลำปาง',
        dropoffName: 'บริษัท ทดสอบจีพีเอส จำกัด',
        dropoffPhone: '0800000001',
        dropoffDeadline: now.add(const Duration(days: 1)),
        budgetPrice: 4500,
        agreedPrice: 4000,
        jobStatus: 'มอบหมายแล้ว',
        createdDate: now,
        clientId: clientId,
        requiredTruckType: truckType,
      );

      // ── 5. สร้าง Bidding (ได้รับเลือก) ──────────────────────────────────
      final biddingId = uuid.v4();
      final bidding = BiddingModel(
        biddingId: biddingId,
        bidPrice: 4000,
        messageToClient: 'พร้อมออกเดินทางทันทีครับ',
        biddingStatus: 'ได้รับเลือก',
        biddingDate: now,
        jobId: jobId,
        contractorId: contractorId,
        truckId: truckId,
      );

      final batch = db.batch()
        ..set(FirebaseService.jobs.doc(jobId), job.toJson())
        ..set(FirebaseService.biddings.doc(biddingId), bidding.toJson());
      await batch.commit();

      if (mounted) {
        setState(() {
          _seeding = false;
          _result = _SeedResult(
            clientPhone: clientPhone,
            contractorPhone: contractorPhone,
            jobTitle: job.jobTitle,
            jobId: jobId,
          );
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _seeding = false;
          _error = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConfig.surfaceColor,
      appBar: AppBar(
        title: const Text('Dev: สร้างข้อมูลทดสอบ GPS'),
        backgroundColor: const Color(0xFF6200EA),
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Result card
            if (_result != null) ...[
              _ResultCard(result: _result!),
              const SizedBox(height: 20),
            ],

            // Error card
            if (_error != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEBEE),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppConfig.errorColor),
                ),
                child: Text(_error!, style: const TextStyle(fontSize: 12, color: Color(0xFFB71C1C))),
              ),
              const SizedBox(height: 16),
            ],

            // Phone input fields
            const Text('เบอร์ผู้ว่าจ้าง (Client)',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            TextFormField(
              controller: _clientPhoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                hintText: 'เช่น 0894561232',
                prefixIcon: const Icon(Icons.person_outline),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'กรุณากรอกเบอร์';
                if (v.trim() == _contractorPhoneCtrl.text.trim()) return 'เบอร์ต้องไม่ซ้ำกัน';
                return null;
              },
            ),
            const SizedBox(height: 14),
            const Text('เบอร์ผู้รับจ้าง (Contractor)',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            TextFormField(
              controller: _contractorPhoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                hintText: 'เช่น 0891234567',
                prefixIcon: const Icon(Icons.drive_eta_outlined),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'กรุณากรอกเบอร์';
                if (v.trim() == _clientPhoneCtrl.text.trim()) return 'เบอร์ต้องไม่ซ้ำกัน';
                return null;
              },
            ),
            const SizedBox(height: 20),

            // What will be created
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF3E5F5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF9C27B0)),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('จะสร้างใน Firestore:',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF6A1B9A))),
                  SizedBox(height: 8),
                  _InfoRow(icon: Icons.person, text: 'Client (ยอดเงิน ฿20,000) — ถ้ายังไม่มีในระบบ'),
                  _InfoRow(icon: Icons.drive_eta, text: 'Contractor + รถ Toyota Hilux อนุมัติแล้ว — ถ้ายังไม่มี'),
                  _InfoRow(icon: Icons.work, text: 'งาน: ทดสอบ GPS — ขนข้าวโพด (มอบหมายแล้ว)'),
                  _InfoRow(icon: Icons.handshake, text: 'ข้อเสนอ: ฿4,000 (ได้รับเลือก)'),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Seed button
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton.icon(
                onPressed: _seeding ? null : _seed,
                icon: _seeding
                    ? const SizedBox(
                        width: 20, height: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                      )
                    : const Icon(Icons.science),
                label: Text(
                  _seeding ? 'กำลังสร้าง...' : 'สร้างข้อมูลทดสอบ GPS',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6200EA),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Center(
              child: Text(
                'กดซ้ำได้ — ถ้า account มีอยู่แล้วจะข้ามไปสร้างแค่งานใหม่',
                style: TextStyle(fontSize: 11, color: Color(0xFF9E9E9E)),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 12),
            // ── เข้าสู่ระบบผู้ดูแลระบบ (แยก portal ตาม Mockup 09-admin) ──
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AdminLoginPage()),
                ),
                icon: const Icon(Icons.admin_panel_settings_outlined),
                label: const Text('เข้าสู่ระบบผู้ดูแลระบบ (Admin)',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF6200EA),
                  side: const BorderSide(color: Color(0xFF6200EA)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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


class _ResultCard extends StatelessWidget {
  final _SeedResult result;
  const _ResultCard({required this.result});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppConfig.primaryColor, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.check_circle, color: AppConfig.primaryColor, size: 20),
              SizedBox(width: 8),
              Text('สร้างข้อมูลสำเร็จ!',
                  style: TextStyle(fontWeight: FontWeight.bold, color: AppConfig.primaryColor, fontSize: 15)),
            ],
          ),
          const Divider(height: 20),
          const Text('วิธีทดสอบ GPS:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 8),
          _ResultStep(
            n: '1',
            text: 'Login ผู้ว่าจ้าง\nเบอร์: ${result.clientPhone} → OTP: ${123456}\n→ เปิดงาน "${result.jobTitle}" → กดดูแผนที่',
          ),
          _ResultStep(
            n: '2',
            text: 'Login ผู้รับจ้าง\nเบอร์: ${result.contractorPhone} → OTP: ${123456}\n→ แท็บ "งานของฉัน" → เปิดงาน → กด "อัปเดตสถานะ"',
          ),
          _ResultStep(
            n: '3',
            text: 'กด "อัปเดตตำแหน่ง GPS" ใน GPS Tracking page\n→ ดูแผนที่ฝั่ง client อัปเดตแบบ real-time',
          ),
        ],
      ),
    );
  }
}

class _ResultStep extends StatelessWidget {
  final String n;
  final String text;
  const _ResultStep({required this.n, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 22, height: 22,
            decoration: const BoxDecoration(color: AppConfig.primaryColor, shape: BoxShape.circle),
            alignment: Alignment.center,
            child: Text(n, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 12, height: 1.5))),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 15, color: const Color(0xFF6A1B9A)),
          const SizedBox(width: 6),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 12, color: Color(0xFF424242)))),
        ],
      ),
    );
  }
}

class _SeedResult {
  final String clientPhone;
  final String contractorPhone;
  final String jobTitle;
  final String jobId;

  const _SeedResult({
    required this.clientPhone,
    required this.contractorPhone,
    required this.jobTitle,
    required this.jobId,
  });
}
