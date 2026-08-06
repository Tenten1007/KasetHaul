import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/config/app_config.dart';
import '../../../core/repositories/repositories.dart';
import '../../../models/models.dart';
import '../bloc/admin_bloc.dart';
import '../../truck/bloc/truck_type_bloc.dart';
import 'admin_truck_approval_page.dart';

class AdminHomePage extends StatefulWidget {
  final AdministratorModel admin;
  const AdminHomePage({super.key, required this.admin});

  @override
  State<AdminHomePage> createState() => _AdminHomePageState();
}

class _AdminHomePageState extends State<AdminHomePage> {
  int _currentIndex = 0;

  late final AdminBloc _adminBloc;
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _adminBloc = AdminBloc(
      truckRepository: TruckRepository(),
      contractorRepository: ContractorRepository(),
      memberRepository: MemberRepository(),
      jobRepository: JobRepository(),
    );

    // แท็บตาม Mockup 09: หน้าหลัก / รถ / รายงาน / ตั้งค่า
    _pages = [
      BlocProvider.value(
        value: _adminBloc,
        child: _AdminDashboardPage(admin: widget.admin),
      ),
      BlocProvider.value(
        value: _adminBloc,
        child: const AdminTruckApprovalPage(),
      ),
      BlocProvider.value(
        value: _adminBloc,
        child: const _AdminReportsPage(),
      ),
      const _AdminSettingsPage(),
    ];
  }

  @override
  void dispose() {
    _adminBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) {
          setState(() => _currentIndex = i);
          // refresh ข้อมูลเมื่อเปลี่ยน tab
          if (i == 0) _adminBloc.add(const LoadDashboardEvent());
          if (i == 1) _adminBloc.add(const LoadAllTrucksEvent());
        },
        selectedItemColor: AppConfig.primaryColor,
        unselectedItemColor: AppConfig.textSecondaryColor,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined), label: 'หน้าหลัก'),
          BottomNavigationBarItem(
              icon: Icon(Icons.local_shipping_outlined), label: 'รถ'),
          BottomNavigationBarItem(
              icon: Icon(Icons.bar_chart_outlined), label: 'รายงาน'),
          BottomNavigationBarItem(
              icon: Icon(Icons.settings_outlined), label: 'ตั้งค่า'),
        ],
      ),
    );
  }
}

// ── Dashboard page ──────────────────────────────────────────────────────────────

class _AdminDashboardPage extends StatefulWidget {
  final AdministratorModel admin;
  const _AdminDashboardPage({required this.admin});

  @override
  State<_AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<_AdminDashboardPage> {
  @override
  void initState() {
    super.initState();
    context.read<AdminBloc>().add(const LoadDashboardEvent());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConfig.surfaceColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              color: AppConfig.primaryColor,
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'แอดมินแดชบอร์ด',
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Colors.white),
                    ),
                  ),
                  const Icon(Icons.notifications_outlined, color: Colors.white),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Welcome card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            AppConfig.primaryColor,
                            AppConfig.primaryDarkColor
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Center(
                              child: Text('👤',
                                  style: TextStyle(fontSize: 24)),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('สวัสดี',
                                  style: TextStyle(
                                      color: Colors.white70, fontSize: 13)),
                              Text(
                                widget.admin.username,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Stats + pending + quick actions
                    BlocBuilder<AdminBloc, AdminState>(
                      builder: (context, state) {
                        if (state is AdminLoading) {
                          return const Center(
                              child: CircularProgressIndicator(
                                  color: AppConfig.primaryColor));
                        }
                        if (state is DashboardLoaded) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // 4-cell stats grid (Mockup spec)
                              GridView.count(
                                crossAxisCount: 2,
                                shrinkWrap: true,
                                physics:
                                    const NeverScrollableScrollPhysics(),
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                                childAspectRatio: 1.8,
                                children: [
                                  _StatCard(
                                    value: '${state.pendingTrucks}',
                                    label: 'รอตรวจสอบรถ',
                                    borderColor:
                                        AppConfig.statusWarningColor,
                                    valueColor: AppConfig.statusWarningColor,
                                  ),
                                  _StatCard(
                                    value: '${state.totalUsers}',
                                    label: 'ผู้ใช้ทั้งหมด',
                                    borderColor: AppConfig.accentColor,
                                    valueColor: AppConfig.accentColor,
                                  ),
                                  _StatCard(
                                    value: '${state.approvedTrucks}',
                                    label: 'รถที่อนุมัติแล้ว',
                                    borderColor: const Color(0xFF4CAF50),
                                    valueColor: const Color(0xFF4CAF50),
                                  ),
                                  _StatCard(
                                    value: '${state.totalJobs}',
                                    label: 'งานทั้งหมด',
                                    borderColor: AppConfig.primaryColor,
                                    valueColor: AppConfig.primaryColor,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),

                              // Pending approvals section
                              if (state.pendingTruckList.isNotEmpty) ...[
                                const Text('รอตรวจสอบ',
                                    style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold)),
                                const SizedBox(height: 8),
                                ...state.pendingTruckList
                                    .take(2)
                                    .map((truck) =>
                                        _PendingTruckCard(truck: truck)),
                                const SizedBox(height: 20),
                              ],

                              // Quick actions section
                              const Text('จัดการระบบ',
                                  style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold)),
                              const SizedBox(height: 8),
                              _QuickActionList(
                                items: [
                                  _QuickActionItem(
                                    icon: '🚛',
                                    title: 'จัดการรถ',
                                    subtitle:
                                        'ดูรถทั้งหมด / ตรวจสอบรถใหม่',
                                    onTap: () =>
                                        _switchTab(context, 1),
                                    isFirst: true,
                                  ),
                                  _QuickActionItem(
                                    icon: '📊',
                                    title: 'รายงาน',
                                    subtitle: 'สถิติและรายงานต่างๆ',
                                    onTap: () =>
                                        _switchTab(context, 2),
                                  ),
                                  _QuickActionItem(
                                    icon: '⚙️',
                                    title: 'ตั้งค่าระบบ',
                                    subtitle: 'ค่าธรรมเนียม / ประเภทรถ',
                                    onTap: () =>
                                        _switchTab(context, 3),
                                    isLast: true,
                                  ),
                                ],
                              ),
                            ],
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _switchTab(BuildContext context, int index) {
    final homeState = context
        .findAncestorStateOfType<_AdminHomePageState>();
    homeState?.setState(() => homeState._currentIndex = index);
  }
}

// ── Pending truck card ──────────────────────────────────────────────────────────

class _PendingTruckCard extends StatelessWidget {
  final TruckModel truck;
  const _PendingTruckCard({required this.truck});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: const Border(
            left: BorderSide(color: AppConfig.statusWarningColor, width: 4)),
        boxShadow: const [
          BoxShadow(
              color: Color(0x1A000000), blurRadius: 8, offset: Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3E0),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text('รอตรวจสอบรถ',
                    style: TextStyle(
                        fontSize: 11,
                        color: Color(0xFFE65100),
                        fontWeight: FontWeight.w600)),
              ),
              const Text('รอดำเนินการ',
                  style:
                      TextStyle(fontSize: 12, color: Color(0xFF9E9E9E))),
            ],
          ),
          const SizedBox(height: 8),
          Text('${truck.brand} ${truck.model}',
              style: const TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 2),
          Text('โดย: ผู้รับจ้าง (${truck.contractorId.substring(0, 8)}...)',
              style:
                  const TextStyle(fontSize: 12, color: Color(0xFF757575))),
          const SizedBox(height: 10),
          SizedBox(
            child: ElevatedButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => BlocProvider.value(
                    value: context.read<AdminBloc>(),
                    child: const AdminTruckApprovalPage(),
                  ),
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConfig.primaryColor,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
                elevation: 0,
              ),
              child: const Text('ตรวจสอบ',
                  style: TextStyle(fontSize: 13)),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Quick actions ───────────────────────────────────────────────────────────────

class _QuickActionList extends StatelessWidget {
  final List<_QuickActionItem> items;
  const _QuickActionList({required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
              color: Color(0x1A000000), blurRadius: 8, offset: Offset(0, 2))
        ],
      ),
      child: Column(children: items),
    );
  }
}

class _QuickActionItem extends StatelessWidget {
  final String icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool isFirst;
  final bool isLast;

  const _QuickActionItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.isFirst = false,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.vertical(
            top: isFirst ? const Radius.circular(16) : Radius.zero,
            bottom: isLast ? const Radius.circular(16) : Radius.zero,
          ),
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Text(icon, style: const TextStyle(fontSize: 20)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: const TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w600)),
                      Text(subtitle,
                          style: const TextStyle(
                              fontSize: 12, color: Color(0xFF757575))),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right,
                    color: Color(0xFF9E9E9E)),
              ],
            ),
          ),
        ),
        if (!isLast)
          const Divider(height: 1, indent: 16, endIndent: 16),
      ],
    );
  }
}

// ── Stat card ───────────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final String value;
  final String label;
  final Color borderColor;
  final Color valueColor;

  const _StatCard({
    required this.value,
    required this.label,
    required this.borderColor,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border(left: BorderSide(color: borderColor, width: 4)),
        boxShadow: const [
          AppConfig.cardShadow,
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value,
            style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: valueColor),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
                fontSize: 12, color: AppConfig.textSecondaryColor),
          ),
        ],
      ),
    );
  }
}

// ── Reports page ────────────────────────────────────────────────────────────────

class _AdminReportsPage extends StatefulWidget {
  const _AdminReportsPage();

  @override
  State<_AdminReportsPage> createState() => _AdminReportsPageState();
}

class _AdminReportsPageState extends State<_AdminReportsPage> {
  @override
  void initState() {
    super.initState();
    final state = context.read<AdminBloc>().state;
    if (state is! DashboardLoaded) {
      context.read<AdminBloc>().add(const LoadDashboardEvent());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConfig.surfaceColor,
      appBar: AppBar(
        backgroundColor: AppConfig.primaryColor,
        foregroundColor: Colors.white,
        title: const Text('รายงาน'),
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: BlocBuilder<AdminBloc, AdminState>(
        builder: (context, state) {
          if (state is AdminLoading || state is AdminInitial) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is DashboardLoaded) {
            return _ReportsContent(state: state);
          }
          if (state is AdminError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(state.message,
                      style: const TextStyle(color: Color(0xFF757575))),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => context
                        .read<AdminBloc>()
                        .add(const LoadDashboardEvent()),
                    child: const Text('ลองใหม่'),
                  ),
                ],
              ),
            );
          }
          return const SizedBox();
        },
      ),
    );
  }
}

class _ReportsContent extends StatelessWidget {
  final DashboardLoaded state;
  const _ReportsContent({required this.state});

  String _fmtMoney(double v) => '฿${v.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}';

  @override
  Widget build(BuildContext context) {
    final successRate = state.totalJobs == 0
        ? 0.0
        : state.completedJobs / state.totalJobs * 100;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Platform revenue ──
          _SectionLabel('รายได้แพลตฟอร์ม'),
          _ReportStatCard(
            color: AppConfig.primaryColor,
            icon: Icons.monetization_on_outlined,
            label: 'รายได้รวม (ค่าธรรมเนียม 3%)',
            value: _fmtMoney(state.totalRevenue),
            large: true,
          ),
          const SizedBox(height: 16),

          // ── Job stats ──
          _SectionLabel('สถิติงานขนส่ง'),
          Row(children: [
            Expanded(
              child: _ReportStatCard(
                color: const Color(0xFF1E88E5),
                icon: Icons.work_outline,
                label: 'ทั้งหมด',
                value: '${state.totalJobs}',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ReportStatCard(
                color: const Color(0xFFFB8C00),
                icon: Icons.local_shipping_outlined,
                label: 'กำลังดำเนินการ',
                value: '${state.activeJobs}',
              ),
            ),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
              child: _ReportStatCard(
                color: const Color(0xFF43A047),
                icon: Icons.check_circle_outline,
                label: 'เสร็จสิ้น',
                value: '${state.completedJobs}',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ReportStatCard(
                color: const Color(0xFF8E24AA),
                icon: Icons.percent,
                label: 'อัตราสำเร็จ',
                value: '${successRate.toStringAsFixed(1)}%',
              ),
            ),
          ]),
          const SizedBox(height: 16),

          // ── User stats ──
          _SectionLabel('สถิติผู้ใช้งาน'),
          Row(children: [
            Expanded(
              child: _ReportStatCard(
                color: const Color(0xFF00897B),
                icon: Icons.people_outline,
                label: 'สมาชิกทั้งหมด',
                value: '${state.totalUsers}',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ReportStatCard(
                color: const Color(0xFFE53935),
                icon: Icons.drive_eta_outlined,
                label: 'ผู้รับจ้าง',
                value: '${state.totalContractors}',
              ),
            ),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
              child: _ReportStatCard(
                color: const Color(0xFF3949AB),
                icon: Icons.verified_outlined,
                label: 'รถผ่านตรวจสอบ',
                value: '${state.approvedTrucks}',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ReportStatCard(
                color: const Color(0xFFF4511E),
                icon: Icons.pending_outlined,
                label: 'รอตรวจสอบ',
                value: '${state.pendingTrucks}',
              ),
            ),
          ]),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(text,
          style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Color(0xFF424242))),
    );
  }
}

// ── Settings page (ตั้งค่าระบบ: ค่าธรรมเนียม / ประเภทรถ) ─────────────────────────

class _AdminSettingsPage extends StatelessWidget {
  const _AdminSettingsPage();

  @override
  Widget build(BuildContext context) {
    const feePercent = AppConfig.platformFeePercent; // 0.03
    const perSide = AppConfig.platformFeePerSide; // 0.015

    return BlocProvider(
      create: (_) => TruckTypeBloc()..add(const LoadTruckTypes()),
      child: Scaffold(
      backgroundColor: AppConfig.surfaceColor,
      appBar: AppBar(
        backgroundColor: AppConfig.primaryColor,
        foregroundColor: Colors.white,
        title: const Text('ตั้งค่าระบบ'),
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── ค่าธรรมเนียมแพลตฟอร์ม ──
            _SectionLabel('ค่าธรรมเนียมแพลตฟอร์ม'),
            _ReportStatCard(
              color: AppConfig.primaryColor,
              icon: Icons.percent,
              label: 'ค่าธรรมเนียมรวมต่อธุรกรรม',
              value: '${(feePercent * 100).toStringAsFixed(0)}%',
              large: true,
            ),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                child: _ReportStatCard(
                  color: AppConfig.accentColor,
                  icon: Icons.person_outline,
                  label: 'หักฝั่งผู้ว่าจ้าง',
                  value: '${(perSide * 100).toStringAsFixed(1)}%',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ReportStatCard(
                  color: const Color(0xFFFB8C00),
                  icon: Icons.local_shipping_outlined,
                  label: 'หักฝั่งผู้รับจ้าง',
                  value: '${(perSide * 100).toStringAsFixed(1)}%',
                ),
              ),
            ]),
            const SizedBox(height: 20),

            // ── ประเภทรถที่รองรับ (โหลดผ่าน TruckTypeBloc) ──
            _SectionLabel('ประเภทรถที่รองรับ'),
            BlocBuilder<TruckTypeBloc, TruckTypeListState>(
              builder: (context, state) {
                if (state is! TruckTypeListLoaded) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                final types = state.types;
                return Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: const [AppConfig.cardShadow],
                  ),
                  child: Column(
                    children: [
                      for (int i = 0; i < types.length; i++) ...[
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                          child: Row(
                            children: [
                              const Text('🚛',
                                  style: TextStyle(fontSize: 20)),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(types[i].typeName,
                                    style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600)),
                              ),
                              if (types[i].maxWeightCapacity != null)
                                Text(
                                    'สูงสุด ${types[i].maxWeightCapacity} กก.',
                                    style: const TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF757575))),
                            ],
                          ),
                        ),
                        if (i != types.length - 1)
                          const Divider(height: 1, indent: 16, endIndent: 16),
                      ],
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    ));
  }
}

class _ReportStatCard extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String label;
  final String value;
  final bool large;

  const _ReportStatCard({
    required this.color,
    required this.icon,
    required this.label,
    required this.value,
    this.large = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(large ? 20 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border(left: BorderSide(color: color, width: 4)),
        boxShadow: const [
          AppConfig.cardShadow,
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: large ? 32 : 26),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontSize: 12, color: Color(0xFF757575))),
                const SizedBox(height: 2),
                Text(value,
                    style: TextStyle(
                        fontSize: large ? 22 : 18,
                        fontWeight: FontWeight.bold,
                        color: color)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}



