import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/config/app_config.dart';
import '../../../core/repositories/repositories.dart';
import '../../../core/services/firebase_service.dart';
import '../../../models/models.dart';
import '../../job/bloc/contractor_job_bloc.dart';
import '../../job/bloc/job_bloc.dart';
import '../../wallet/bloc/wallet_bloc.dart';
import '../bloc/admin_bloc.dart';
import '../bloc/auth_bloc.dart';
import '../../job/pages/bid_job_page.dart';
import '../../job/pages/cancel_job_page.dart';
import '../../job/pages/contractor_job_detail_page.dart';
import '../../job/pages/contractor_my_jobs_page.dart';
import '../../job/pages/delivery_proof_page.dart';
import '../../job/pages/edit_job_page.dart';
import '../../job/pages/filter_jobs_page.dart';
import '../../job/pages/gps_tracking_page.dart';
import '../../job/pages/job_detail_page.dart';
import '../../job/pages/location_view_page.dart';
import '../../job/pages/my_jobs_page.dart';
import '../../job/pages/post_job_page.dart';
import '../../job/pages/search_jobs_page.dart';
import '../../notification/pages/notification_list_page.dart';
import '../../profile/pages/client_profile_page.dart';
import '../../profile/pages/contractor_profile_page.dart';
import '../../profile/pages/settings_page.dart';
import '../../profile/pages/verify_identity_page.dart';
import '../../review/pages/contractor_reviews_page.dart';
import '../../review/pages/review_client_page.dart';
import '../../review/pages/write_review_page.dart';
import '../../truck/pages/add_truck_page.dart';
import '../../truck/pages/edit_truck_page.dart';
import '../../truck/pages/truck_list_page.dart';
import '../../truck/pages/view_truck_page.dart';
import '../../wallet/pages/client_statistics_page.dart';
import '../../wallet/pages/earnings_page.dart';
import '../../wallet/pages/top_up_page.dart';
import '../../wallet/pages/transaction_history_page.dart';
import '../../wallet/pages/wallet_page.dart';
import '../../wallet/pages/withdraw_page.dart';
import 'admin_home_page.dart';
import 'admin_login_page.dart';
import 'admin_truck_approval_page.dart';
import 'seed_data_page.dart';
import 'client_home_page.dart';
import 'contractor_home_page.dart';
import 'otp_verify_page.dart';
import 'register_client_page.dart';
import 'register_client_success_page.dart';
import 'register_contractor_page.dart';
import 'register_contractor_success_page.dart';

/// หน้า Dev สำหรับพรีวิว/ตรวจ UI — โดยเฉพาะบน Flutter Web ที่ล็อกอิน OTP ไม่ได้
/// (Firebase บังคับ reCAPTCHA) จึงเข้าหน้าจอด้านในตรงๆ ด้วยบัญชีที่ seed ไว้
///
/// ใช้ได้ 2 แบบ:
///  - กดปุ่มในหน้านี้
///  - เปิดตรงจอผ่าน URL:  ?s=KEY#/dev/preview   เช่น ?s=driver-withdraw
///    (query ต้องอยู่ "ก่อน" # ไม่งั้น route ไม่ match แล้ว Navigator ซ้อนกัน)
class DevPreviewPage extends StatefulWidget {
  const DevPreviewPage({super.key});

  @override
  State<DevPreviewPage> createState() => _DevPreviewPageState();
}

class _DevPreviewPageState extends State<DevPreviewPage> {
  static const _clientPhone = '0894561232';
  static const _contractorPhone = '0891234567';

  bool _busy = false;
  String? _error;

  ClientModel? _client;
  ContractorModel? _contractor;

  /// key -> [ป้ายชื่อ, กลุ่ม]
  static const screens = <String, List<String>>{
    'auth-otp': ['ยืนยัน OTP', 'auth'],
    'auth-reg-client': ['ฟอร์มลงทะเบียน เกษตรกร', 'auth'],
    'auth-reg-contractor': ['ฟอร์มลงทะเบียน ผู้รับจ้าง', 'auth'],
    'auth-success-client': ['ลงทะเบียนสำเร็จ (เกษตรกร)', 'auth'],
    'auth-success-contractor': ['ลงทะเบียนสำเร็จ (ผู้รับจ้าง)', 'auth'],
    'client-home': ['หน้าหลัก (งานขนส่งของฉัน)', 'client'],
    'client-myjobs': ['รายการงาน (MyJobs)', 'client'],
    'client-jobdetail': ['รายละเอียดงาน', 'client'],
    'client-post': ['โพสต์งานใหม่', 'client'],
    'client-editjob': ['แก้ไขงาน', 'client'],
    'client-canceljob': ['ยกเลิกงาน', 'client'],
    'client-tracking': ['ติดตาม GPS (ฝั่งผู้ว่าจ้าง)', 'client'],
    'client-writereview': ['เขียนรีวิวผู้รับจ้าง', 'client'],
    'client-wallet': ['กระเป๋าเงิน', 'client'],
    'client-topup': ['เติมเงิน', 'client'],
    'client-txhistory': ['ประวัติธุรกรรม', 'client'],
    'client-stats': ['สถิติการใช้งาน', 'client'],
    'client-profile': ['โปรไฟล์ผู้ว่าจ้าง', 'client'],
    'client-profile-ro': ['โปรไฟล์ผู้ว่าจ้าง (มุมมองคนอื่น)', 'client'],
    'client-notifications': ['การแจ้งเตือน', 'client'],
    'client-settings': ['ตั้งค่า (ผู้ว่าจ้าง)', 'client'],
    'driver-home': ['หน้าหลัก (ค้นหางาน)', 'contractor'],
    'driver-search': ['ค้นหางาน', 'contractor'],
    'driver-filter': ['กรองงาน', 'contractor'],
    'driver-bid': ['รายละเอียดงาน + เสนอราคา', 'contractor'],
    'driver-myjobs': ['งานของฉัน', 'contractor'],
    'driver-jobdetail': ['งานปัจจุบัน (ผู้รับจ้าง)', 'contractor'],
    'driver-gps': ['ส่งตำแหน่ง GPS', 'contractor'],
    'driver-deliveryproof': ['ยืนยันการส่งมอบ', 'contractor'],
    'driver-reviewclient': ['รีวิวลูกค้า', 'contractor'],
    'driver-earnings': ['รายได้', 'contractor'],
    'driver-withdraw': ['ถอนเงิน', 'contractor'],
    'driver-trucks': ['รายการรถของฉัน', 'contractor'],
    'driver-addtruck': ['เพิ่มรถใหม่', 'contractor'],
    'driver-viewtruck': ['ดูรายละเอียดรถ', 'contractor'],
    'driver-edittruck': ['แก้ไขข้อมูลรถ', 'contractor'],
    'driver-verifyid': ['ยืนยันตัวตน Thai ID', 'contractor'],
    'driver-profile': ['โปรไฟล์ผู้รับจ้าง', 'contractor'],
    'driver-profile-ro': ['โปรไฟล์ผู้รับจ้าง (มุมมองเกษตรกร)', 'contractor'],
    'driver-reviews': ['รีวิวที่ได้รับ', 'contractor'],
    'driver-settings': ['ตั้งค่า (ผู้รับจ้าง)', 'contractor'],
    'admin-login': ['Admin Login', 'admin'],
    'admin-home': ['แดชบอร์ดผู้ดูแล', 'admin'],
    'admin-trucks': ['ตรวจสอบรถ (Admin)', 'admin'],
    'seed': ['Seed ข้อมูลทดสอบ', 'dev'],
  };

  @override
  void initState() {
    super.initState();
    final s = Uri.base.queryParameters['s'];
    if (s != null && screens.containsKey(s)) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _open(s));
    }
  }

  Future<void> _ensureAccounts() async {
    if (FirebaseService.auth.currentUser == null) {
      await FirebaseService.auth.signInAnonymously();
    }
    _client ??= await ClientRepository().getByPhone(_clientPhone);
    _contractor ??= await ContractorRepository().getByPhone(_contractorPhone);
  }

  Future<JobModel?> _firstJob() async {
    if (_client == null) return null;
    final jobs = await JobRepository().getByClientId(_client!.clientId);
    return jobs.isEmpty ? null : jobs.first;
  }

  Future<TruckModel?> _firstTruck() async {
    if (_contractor == null) return null;
    final t =
        await TruckRepository().getByContractorId(_contractor!.contractorId);
    return t.isEmpty ? null : t.first;
  }

  Widget _withJobBloc(Widget child) => BlocProvider(
        create: (_) => ContractorJobBloc(
          jobRepository: JobRepository(),
          biddingRepository: BiddingRepository(),
          transactionRepository: TransactionRepository(),
          contractorRepository: ContractorRepository(),
        ),
        child: child,
      );

  Widget _withAuthBloc(Widget child) => BlocProvider(
        create: (_) => AuthBloc(
          clientRepository: ClientRepository(),
          contractorRepository: ContractorRepository(),
        ),
        child: child,
      );

  Widget _withClientJobBloc(Widget child) => BlocProvider(
        create: (_) => JobBloc(
          jobRepository: JobRepository(),
          biddingRepository: BiddingRepository(),
          clientRepository: ClientRepository(),
          truckRepository: TruckRepository(),
          contractorRepository: ContractorRepository(),
        ),
        child: child,
      );

  Widget _withWalletBloc(Widget child) => BlocProvider(
        create: (_) => WalletBloc(
          clientRepository: ClientRepository(),
          transactionRepository: TransactionRepository(),
        ),
        child: child,
      );

  Widget _withAdminBloc(Widget child) => BlocProvider(
        create: (_) => AdminBloc(
          truckRepository: TruckRepository(),
          contractorRepository: ContractorRepository(),
          memberRepository: MemberRepository(),
          jobRepository: JobRepository(),
          transactionRepository: TransactionRepository(),
          notificationRepository: NotificationRepository(),
        ),
        child: child,
      );

  Future<Widget?> _build(String key) async {
    final c = _client, d = _contractor;
    switch (key) {
      case 'auth-otp':
        return _withAuthBloc(
            const OtpVerifyPage(phoneNumber: '0894561232', role: 'client'));
      case 'auth-reg-client':
        return const RegisterClientPage(
            phoneNumber: '0899999999', phoneVerified: true);
      case 'auth-reg-contractor':
        return const RegisterContractorPage(
            phoneNumber: '0899999999', phoneVerified: true);
      case 'auth-success-client':
        return c == null ? null : RegisterClientSuccessPage(client: c);
      case 'auth-success-contractor':
        return d == null ? null : RegisterContractorSuccessPage(contractor: d);
      case 'client-home':
        return c == null ? null : ClientHomePage(clientId: c.clientId);
      case 'client-myjobs':
        return c == null ? null : MyJobsPage(clientId: c.clientId);
      case 'client-jobdetail':
        final j = await _firstJob();
        return j == null ? null : JobDetailPage(jobId: j.jobId, isClient: true);
      case 'client-post':
        return c == null ? null : PostJobPage(clientId: c.clientId);
      case 'client-editjob':
        final j = await _firstJob();
        return j == null ? null : EditJobPage(job: j);
      case 'client-canceljob':
        final j = await _firstJob();
        return j == null ? null : _withClientJobBloc(CancelJobPage(job: j));
      case 'client-tracking':
        final j = await _firstJob();
        return j == null
            ? null
            : LocationViewPage(
                jobId: j.jobId,
                jobTitle: j.jobTitle,
                jobStatus: j.jobStatus,
                pickupAddress: j.pickupAddress,
                dropoffAddress: j.dropoffAddress,
                distanceKm: j.distance);
      case 'client-writereview':
        final j = await _firstJob();
        return (j == null || c == null || d == null)
            ? null
            : WriteReviewPage(
                jobId: j.jobId,
                reviewerClientId: c.clientId,
                revieweeContractorId: d.contractorId,
                jobTitle: j.jobTitle);
      case 'client-wallet':
        return c == null ? null : WalletPage(clientId: c.clientId);
      case 'client-topup':
        return c == null
            ? null
            : _withWalletBloc(TopUpPage(clientId: c.clientId));
      case 'client-txhistory':
        if (c == null) return null;
        final tx = await TransactionRepository().getByClientId(c.clientId);
        return TransactionHistoryPage(transactions: tx);
      case 'client-stats':
        return c == null ? null : ClientStatisticsPage(clientId: c.clientId);
      case 'client-profile':
        return c == null ? null : ClientProfilePage(clientId: c.clientId);
      case 'client-profile-ro':
        return c == null
            ? null
            : ClientProfilePage(clientId: c.clientId, readOnly: true);
      case 'client-notifications':
        return c == null ? null : NotificationListPage(recipientId: c.clientId);
      case 'client-settings':
        return const SettingsPage(role: SettingsRole.client);
      case 'driver-home':
        return d == null
            ? null
            : ContractorHomePage(contractorId: d.contractorId);
      case 'driver-search':
        return d == null ? null : SearchJobsPage(contractorId: d.contractorId);
      case 'driver-filter':
        return const FilterJobsPage(initial: JobFilter());
      case 'driver-bid':
        final j = await _firstJob();
        return (j == null || d == null)
            ? null
            : BidJobPage(jobId: j.jobId, contractorId: d.contractorId);
      case 'driver-myjobs':
        return d == null
            ? null
            : _withJobBloc(ContractorMyJobsPage(contractorId: d.contractorId));
      case 'driver-jobdetail':
        final j = await _firstJob();
        final t = await _firstTruck();
        if (j == null || d == null) return null;
        // พรีวิว QA เท่านั้น: ถ้างานจริงไม่มีระยะทาง/ยังไม่เริ่มขนส่ง
        // ใส่ค่าตัวอย่าง (distance=120, สถานะ 'กำลังขนส่ง') ให้เห็น hero + timeline
        var demo = j;
        if (j.distance == null || j.jobStatus == 'รอผู้รับจ้าง') {
          final m = j.toJson();
          m['distance'] = j.distance ?? 120;
          m['jobStatus'] = 'กำลังขนส่ง';
          demo = JobModel.fromJson(m);
        }
        return _withJobBloc(ContractorJobDetailPage(
            job: demo, contractorId: d.contractorId, truckId: t?.truckId));
      case 'driver-gps':
        final j = await _firstJob();
        final t = await _firstTruck();
        return (j == null || t == null)
            ? null
            : GpsTrackingPage(
                jobId: j.jobId, truckId: t.truckId, jobTitle: j.jobTitle);
      case 'driver-deliveryproof':
        final j = await _firstJob();
        return j == null
            ? null
            : _withJobBloc(
                DeliveryProofPage(jobId: j.jobId, jobTitle: j.jobTitle));
      case 'driver-reviewclient':
        final j = await _firstJob();
        return (j == null || c == null || d == null)
            ? null
            : ReviewClientPage(
                jobId: j.jobId,
                reviewerContractorId: d.contractorId,
                revieweeClientId: c.clientId,
                jobTitle: j.jobTitle);
      case 'driver-earnings':
        return d == null
            ? null
            : _withJobBloc(EarningsPage(contractorId: d.contractorId));
      case 'driver-withdraw':
        return d == null
            ? null
            : WithdrawPage(
                contractorId: d.contractorId, currentBalance: d.walletBalance);
      case 'driver-trucks':
        return d == null ? null : TruckListPage(contractorId: d.contractorId);
      case 'driver-addtruck':
        return d == null ? null : AddTruckPage(contractorId: d.contractorId);
      case 'driver-viewtruck':
        final t = await _firstTruck();
        return (t == null || d == null)
            ? null
            : ViewTruckPage(truckId: t.truckId, contractorId: d.contractorId);
      case 'driver-edittruck':
        final t = await _firstTruck();
        return t == null ? null : EditTruckPage(truck: t);
      case 'driver-verifyid':
        return d == null
            ? null
            : VerifyIdentityPage(contractorId: d.contractorId);
      case 'driver-profile':
        return d == null
            ? null
            : ContractorProfilePage(contractorId: d.contractorId);
      case 'driver-profile-ro':
        return d == null
            ? null
            : ContractorProfilePage(
                contractorId: d.contractorId, readOnly: true);
      case 'driver-reviews':
        return d == null
            ? null
            : ContractorReviewsPage(contractorId: d.contractorId);
      case 'driver-settings':
        return d == null
            ? null
            : SettingsPage(
                role: SettingsRole.contractor, contractorId: d.contractorId);
      case 'admin-login':
        return const AdminLoginPage();
      case 'admin-home':
        return const AdminHomePage(
          admin: AdministratorModel(
              administratorId: 'dev-admin', username: 'admin', role: 'admin'),
        );
      case 'admin-trucks':
        // หน้านี้เป็นเนื้อในแท็บของ AdminHomePage (ไม่มี Scaffold ของตัวเอง)
        // → ต้องห่อ Scaffold ให้ TabBar หา Material ancestor เจอ
        return _withAdminBloc(const Scaffold(
          backgroundColor: Colors.white,
          body: SafeArea(child: AdminTruckApprovalPage()),
        ));
      case 'seed':
        return const SeedDataPage();
    }
    return null;
  }

  Future<void> _open(String key) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await _ensureAccounts();
      final page = await _build(key);
      if (!mounted) return;
      setState(() => _busy = false);
      if (page == null) {
        setState(() => _error = 'ไม่พบข้อมูลสำหรับจอ "$key" (seed ไม่ครบ?)');
        return;
      }
      Navigator.push(context, MaterialPageRoute<void>(builder: (_) => page));
    } catch (e) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = 'ผิดพลาด: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final groups = <String, List<MapEntry<String, List<String>>>>{};
    for (final e in screens.entries) {
      groups.putIfAbsent(e.value[1], () => []).add(e);
    }
    const colors = {
      'auth': Color(0xFF455A64),
      'client': AppConfig.primaryColor,
      'contractor': Color(0xFFFF9800),
      'admin': Color(0xFF6200EA),
    };
    const titles = {
      'auth': 'Auth / ลงทะเบียน',
      'client': 'ผู้ว่าจ้าง (Client)',
      'contractor': 'ผู้รับจ้าง (Contractor)',
      'admin': 'ผู้ดูแลระบบ (Admin)',
    };

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        titleTextStyle: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Color(0xFF212121)),
        foregroundColor: const Color(0xFF212121),
        elevation: 0,
        title: Text('Dev: พรีวิว UI (${screens.length} จอ)'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'เข้าหน้าจอด้านในโดยไม่ต้องล็อกอิน · เปิดตรงจอ: ?s=KEY#/dev/preview',
            style: TextStyle(fontSize: 12, color: Color(0xFF757575)),
          ),
          const SizedBox(height: 12),
          if (_busy) const LinearProgressIndicator(minHeight: 2),
          if (_error != null)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                  color: const Color(0xFFFFEBEE),
                  borderRadius: BorderRadius.circular(8)),
              child: Text(_error!,
                  style:
                      const TextStyle(fontSize: 12, color: Color(0xFFB71C1C))),
            ),
          for (final g in ['auth', 'client', 'contractor', 'admin']) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(2, 10, 2, 8),
              child: Text(titles[g]!,
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: colors[g])),
            ),
            for (final e in groups[g]!)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: SizedBox(
                  height: 42,
                  child: ElevatedButton(
                    onPressed: _busy ? null : () => _open(e.key),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colors[g],
                      foregroundColor: Colors.white,
                      elevation: 0,
                      alignment: Alignment.centerLeft,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    child: Text('${e.value[0]}   ·   ${e.key}',
                        style: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w600)),
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}
