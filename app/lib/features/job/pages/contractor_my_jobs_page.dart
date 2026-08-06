import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/config/app_config.dart';
import '../../../models/models.dart';
import '../bloc/contractor_job_bloc.dart';
import '../bloc/contractor_job_event.dart';
import '../bloc/contractor_job_state.dart';
import 'contractor_job_detail_page.dart';

class ContractorMyJobsPage extends StatefulWidget {
  final String contractorId;

  const ContractorMyJobsPage({super.key, required this.contractorId});

  @override
  State<ContractorMyJobsPage> createState() => _ContractorMyJobsPageState();
}

class _ContractorMyJobsPageState extends State<ContractorMyJobsPage> {
  @override
  void initState() {
    super.initState();
    context.read<ContractorJobBloc>().add(LoadMyJobsEvent(widget.contractorId));
  }

  @override
  Widget build(BuildContext context) {
    return _ContractorMyJobsView(contractorId: widget.contractorId);
  }
}

class _ContractorMyJobsView extends StatefulWidget {
  final String contractorId;
  const _ContractorMyJobsView({required this.contractorId});

  @override
  State<_ContractorMyJobsView> createState() => _ContractorMyJobsViewState();
}

class _ContractorMyJobsViewState extends State<_ContractorMyJobsView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  static const _pendingStatuses = {'มอบหมายแล้ว'};
  static const _inTransitStatuses = {
    'ถึงจุดรับสินค้า',
    'รับสินค้าเรียบร้อย',
    'กำลังขนส่ง',
    'ถึงจุดส่งสินค้า',
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime dt) {
    const months = [
      '',
      'ม.ค.',
      'ก.พ.',
      'มี.ค.',
      'เม.ย.',
      'พ.ค.',
      'มิ.ย.',
      'ก.ค.',
      'ส.ค.',
      'ก.ย.',
      'ต.ค.',
      'พ.ย.',
      'ธ.ค.'
    ];
    final buddhistYear = dt.year + 543;
    return '${dt.day} ${months[dt.month]} $buddhistYear';
  }

  String _formatPrice(int price) {
    return price
        .toString()
        .replaceAllMapped(
            RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConfig.surfaceColor,
      appBar: AppBar(
        backgroundColor: AppConfig.primaryColor,
        foregroundColor: Colors.white,
        title: const Text('งานของฉัน'),
        elevation: 0,
      ),
      // แถบแท็บบนพื้นขาว (ตาม Mockup) active สีเขียว + เส้นใต้เขียว
      body: Column(
        children: [
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              indicatorColor: AppConfig.primaryColor,
              indicatorWeight: 2,
              labelColor: AppConfig.primaryColor,
              unselectedLabelColor: const Color(0xFF757575),
              labelStyle:
                  const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              unselectedLabelStyle:
                  const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
              labelPadding: const EdgeInsets.symmetric(horizontal: 4),
              tabs: const [
                Tab(text: 'ทั้งหมด'),
                // ตัด 2 บรรทัดให้พอดีช่อง (ตาม Mockup)
                Tab(
                    child: Text('รอดำเนิน\nการ',
                        textAlign: TextAlign.center,
                        style: TextStyle(height: 1.15))),
                Tab(text: 'กำลังขนส่ง'),
                Tab(text: 'เสร็จสิ้น'),
              ],
            ),
          ),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    return BlocBuilder<ContractorJobBloc, ContractorJobState>(
        builder: (context, state) {
          if (state is ContractorJobLoading) {
            return const Center(
              child: CircularProgressIndicator(
                  color: AppConfig.primaryColor),
            );
          }
          if (state is ContractorJobError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline,
                      size: 48, color: Color(0xFF9E9E9E)),
                  const SizedBox(height: 12),
                  Text(state.message,
                      style: const TextStyle(color: Color(0xFF757575))),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppConfig.primaryColor,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () => context
                        .read<ContractorJobBloc>()
                        .add(LoadMyJobsEvent(widget.contractorId)),
                    child: const Text('ลองใหม่'),
                  ),
                ],
              ),
            );
          }
          if (state is MyJobsLoaded) {
            final pendingJobs = state.activeJobs
                .where((j) => _pendingStatuses.contains(j.jobStatus))
                .toList();
            final inTransitJobs = state.activeJobs
                .where((j) => _inTransitStatuses.contains(j.jobStatus))
                .toList();
            return TabBarView(
              controller: _tabController,
              children: [
                // Tab 0: ทั้งหมด — จัดกลุ่ม งานวันนี้/งานที่จะมาถึง/เสร็จสิ้นล่าสุด (Mockup 07)
                _GroupedJobsView(
                  inTransitJobs: inTransitJobs,
                  pendingJobs: pendingJobs,
                  completedJobs: state.completedJobs,
                  formatDate: _formatDate,
                  formatPrice: _formatPrice,
                  contractorId: widget.contractorId,
                ),
                // Tab 1: รอดำเนินการ
                _JobList(
                  jobs: pendingJobs,
                  emptyMessage: 'ไม่มีงานรอดำเนินการ',
                  emptySubMessage: 'งานที่เพิ่งได้รับมอบหมายจะแสดงที่นี่',
                  formatDate: _formatDate,
                  formatPrice: _formatPrice,
                  contractorId: widget.contractorId,
                  isCompleted: false,
                ),
                // Tab 2: กำลังขนส่ง
                _JobList(
                  jobs: inTransitJobs,
                  emptyMessage: 'ไม่มีงานที่กำลังขนส่ง',
                  emptySubMessage: 'งานที่กำลังดำเนินการจะแสดงที่นี่',
                  formatDate: _formatDate,
                  formatPrice: _formatPrice,
                  contractorId: widget.contractorId,
                  isCompleted: false,
                ),
                // Tab 3: เสร็จสิ้น
                _JobList(
                  jobs: state.completedJobs,
                  emptyMessage: 'ยังไม่มีงานที่เสร็จสิ้น',
                  emptySubMessage: 'งานที่ดำเนินการเสร็จแล้วจะแสดงที่นี่',
                  formatDate: _formatDate,
                  formatPrice: _formatPrice,
                  contractorId: widget.contractorId,
                  isCompleted: true,
                ),
              ],
            );
          }
          return const SizedBox.shrink();
        },
    );
  }
}

class _JobList extends StatelessWidget {
  final List<JobModel> jobs;
  final String emptyMessage;
  final String emptySubMessage;
  final String Function(DateTime) formatDate;
  final String Function(int) formatPrice;
  final String contractorId;
  final bool isCompleted;

  const _JobList({
    required this.jobs,
    required this.emptyMessage,
    required this.emptySubMessage,
    required this.formatDate,
    required this.formatPrice,
    required this.contractorId,
    required this.isCompleted,
  });

  @override
  Widget build(BuildContext context) {
    if (jobs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isCompleted ? Icons.check_circle_outline : Icons.work_off_outlined,
              size: 64,
              color: const Color(0xFFBDBDBD),
            ),
            const SizedBox(height: 16),
            Text(
              emptyMessage,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF757575),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              emptySubMessage,
              style: const TextStyle(
                  fontSize: 13, color: Color(0xFF9E9E9E)),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: AppConfig.primaryColor,
      onRefresh: () async {
        context
            .read<ContractorJobBloc>()
            .add(LoadMyJobsEvent(contractorId));
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: jobs.length,
        itemBuilder: (context, index) {
          final job = jobs[index];
          return _JobCard(
            job: job,
            formatDate: formatDate,
            formatPrice: formatPrice,
            isCompleted: isCompleted,
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => BlocProvider.value(
                    value: context.read<ContractorJobBloc>(),
                    child: ContractorJobDetailPage(
                      job: job,
                      contractorId: contractorId,
                    ),
                  ),
                ),
              );
              if (context.mounted) {
                context
                    .read<ContractorJobBloc>()
                    .add(LoadMyJobsEvent(contractorId));
              }
            },
          );
        },
      ),
    );
  }
}

/// Tab "ทั้งหมด" — จัดกลุ่มตาม Mockup 07: งานวันนี้ / งานที่จะมาถึง / เสร็จสิ้นล่าสุด
class _GroupedJobsView extends StatelessWidget {
  final List<JobModel> inTransitJobs;
  final List<JobModel> pendingJobs;
  final List<JobModel> completedJobs;
  final String Function(DateTime) formatDate;
  final String Function(int) formatPrice;
  final String contractorId;

  const _GroupedJobsView({
    required this.inTransitJobs,
    required this.pendingJobs,
    required this.completedJobs,
    required this.formatDate,
    required this.formatPrice,
    required this.contractorId,
  });

  Future<void> _openDetail(BuildContext context, JobModel job) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: context.read<ContractorJobBloc>(),
          child: ContractorJobDetailPage(job: job, contractorId: contractorId),
        ),
      ),
    );
    if (context.mounted) {
      context.read<ContractorJobBloc>().add(LoadMyJobsEvent(contractorId));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (inTransitJobs.isEmpty &&
        pendingJobs.isEmpty &&
        completedJobs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.work_off_outlined, size: 64, color: Color(0xFFBDBDBD)),
            SizedBox(height: 16),
            Text('ยังไม่มีงาน',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF757575))),
            SizedBox(height: 8),
            Text('งานที่ได้รับมอบหมายจะแสดงที่นี่',
                style: TextStyle(fontSize: 13, color: Color(0xFF9E9E9E))),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: AppConfig.primaryColor,
      onRefresh: () async => context
          .read<ContractorJobBloc>()
          .add(LoadMyJobsEvent(contractorId)),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (inTransitJobs.isNotEmpty) ...[
            const _SectionHeader('งานวันนี้'),
            ...inTransitJobs.map((j) => _ActiveJobCard(
                  job: j,
                  formatPrice: formatPrice,
                  onUpdate: () => _openDetail(context, j),
                )),
            const SizedBox(height: 8),
          ],
          if (pendingJobs.isNotEmpty) ...[
            const _SectionHeader('งานที่จะมาถึง'),
            ...pendingJobs.map((j) => _JobCard(
                  job: j,
                  formatDate: formatDate,
                  formatPrice: formatPrice,
                  isCompleted: false,
                  onTap: () => _openDetail(context, j),
                )),
            const SizedBox(height: 8),
          ],
          if (completedJobs.isNotEmpty) ...[
            const _SectionHeader('เสร็จสิ้นล่าสุด'),
            ...completedJobs.map((j) => _JobCard(
                  job: j,
                  formatDate: formatDate,
                  formatPrice: formatPrice,
                  isCompleted: true,
                  onTap: () => _openDetail(context, j),
                )),
          ],
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10, top: 4),
        child: Text(title,
            style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: Color(0xFF212121))),
      );
}

/// การ์ด "งานปัจจุบัน" (กำลังขนส่ง) — เน้นเขียว + ปุ่ม "อัพเดทสถานะ" (Mockup 07)
class _ActiveJobCard extends StatelessWidget {
  final JobModel job;
  final String Function(int) formatPrice;
  final VoidCallback onUpdate;

  const _ActiveJobCard({
    required this.job,
    required this.formatPrice,
    required this.onUpdate,
  });

  @override
  Widget build(BuildContext context) {
    final price = job.agreedPrice ?? job.budgetPrice;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F8F1),
        borderRadius: BorderRadius.circular(16),
        border: const Border(
            left: BorderSide(color: AppConfig.primaryColor, width: 4)),
        boxShadow: const [
          BoxShadow(
              color: Color(0x1A000000), blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // status + "งานปัจจุบัน"
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(job.jobStatus,
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppConfig.primaryColor)),
              const Text('งานปัจจุบัน',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppConfig.primaryColor)),
            ],
          ),
          const SizedBox(height: 8),
          Text(job.jobTitle,
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF212121))),
          const SizedBox(height: 8),
          // route
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                    color: AppConfig.primaryColor, shape: BoxShape.circle),
              ),
              Expanded(
                child: Container(
                  height: 2,
                  margin: const EdgeInsets.symmetric(horizontal: 6),
                  color: const Color(0xFFCADFCA),
                ),
              ),
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                    color: AppConfig.secondaryColor, shape: BoxShape.circle),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(_shorten(job.pickupAddress),
                    style: const TextStyle(
                        fontSize: 12, color: Color(0xFF616161)),
                    overflow: TextOverflow.ellipsis),
              ),
              Flexible(
                child: Text(_shorten(job.dropoffAddress),
                    style: const TextStyle(
                        fontSize: 12, color: Color(0xFF616161)),
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.end),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // distance/customer/price + update button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    [
                      if (job.distance != null) '${job.distance} กม.',
                      if (job.dropoffName != null &&
                          job.dropoffName!.isNotEmpty)
                        'ลูกค้า: ${job.dropoffName}',
                    ].join('   '),
                    style: const TextStyle(
                        fontSize: 12, color: Color(0xFF757575)),
                  ),
                  const SizedBox(height: 2),
                  const Text('ราคาตกลง',
                      style: TextStyle(
                          fontSize: 11, color: Color(0xFF9E9E9E))),
                  Text('฿${formatPrice(price)}',
                      style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppConfig.primaryColor)),
                ],
              ),
              ElevatedButton(
                onPressed: onUpdate,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppConfig.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 18, vertical: 12),
                  minimumSize: Size.zero,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  elevation: 0,
                ),
                child: const Text('อัพเดทสถานะ',
                    style: TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _shorten(String addr) =>
      addr.length > 22 ? '${addr.substring(0, 22)}...' : addr;
}

class _JobCard extends StatelessWidget {
  final JobModel job;
  final String Function(DateTime) formatDate;
  final String Function(int) formatPrice;
  final bool isCompleted;
  final VoidCallback onTap;

  const _JobCard({
    required this.job,
    required this.formatDate,
    required this.formatPrice,
    required this.isCompleted,
    required this.onTap,
  });

  Color get _statusColor {
    switch (job.jobStatus) {
      case 'มอบหมายแล้ว':
        return const Color(0xFFFF9800);
      case 'ถึงจุดรับสินค้า':
      case 'รับสินค้าเรียบร้อย':
        return const Color(0xFF1976D2);
      case 'กำลังขนส่ง':
        return AppConfig.primaryColor;
      case 'ถึงจุดส่งสินค้า':
        return const Color(0xFF7B1FA2);
      case 'จัดส่งสำเร็จ':
        return const Color(0xFF4CAF50);
      default:
        return const Color(0xFF757575);
    }
  }

  Color get _statusBgColor {
    switch (job.jobStatus) {
      case 'มอบหมายแล้ว':
        return const Color(0xFFFFF3E0);
      case 'ถึงจุดรับสินค้า':
      case 'รับสินค้าเรียบร้อย':
        return const Color(0xFFE3F2FD);
      case 'กำลังขนส่ง':
        return const Color(0xFFE8F5E9);
      case 'ถึงจุดส่งสินค้า':
        return const Color(0xFFF3E5F5);
      case 'จัดส่งสำเร็จ':
        return const Color(0xFFE8F5E9);
      default:
        return AppConfig.surfaceColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    final price = job.agreedPrice ?? job.budgetPrice;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: isCompleted
              ? null
              : Border(
                  left: BorderSide(
                    color: _statusColor,
                    width: 4,
                  ),
                ),
          boxShadow: const [
            BoxShadow(
                color: Color(0x1A000000), blurRadius: 8, offset: Offset(0, 2)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: status + date
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _statusBgColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    job.jobStatus,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _statusColor,
                    ),
                  ),
                ),
                Text(
                  formatDate(job.pickupDatetime),
                  style: const TextStyle(
                      fontSize: 12, color: Color(0xFF9E9E9E)),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Job title
            Text(
              job.jobTitle,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Color(0xFF212121),
              ),
            ),
            const SizedBox(height: 8),

            // Route
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppConfig.primaryColor,
                    shape: BoxShape.circle,
                  ),
                ),
                Expanded(
                  child: Container(
                    height: 2,
                    margin: const EdgeInsets.symmetric(horizontal: 6),
                    color: const Color(0xFFE0E0E0),
                  ),
                ),
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppConfig.secondaryColor,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    _shorten(job.pickupAddress),
                    style: const TextStyle(
                        fontSize: 12, color: Color(0xFF616161)),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Flexible(
                  child: Text(
                    _shorten(job.dropoffAddress),
                    style: const TextStyle(
                        fontSize: 12, color: Color(0xFF616161)),
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.end,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Price + detail hint
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isCompleted ? 'รายได้สุทธิ' : 'ราคาตกลง',
                      style: const TextStyle(
                          fontSize: 11, color: Color(0xFF9E9E9E)),
                    ),
                    Text(
                      isCompleted
                          ? '+฿${formatPrice((price * (1 - AppConfig.platformFeePerSide)).round())}'
                          : '฿${formatPrice(price)}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isCompleted
                            ? const Color(0xFF4CAF50)
                            : AppConfig.primaryColor,
                      ),
                    ),
                  ],
                ),
                const Row(
                  children: [
                    Text(
                      'ดูรายละเอียด',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppConfig.primaryColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(width: 4),
                    Icon(Icons.chevron_right,
                        color: AppConfig.primaryColor, size: 18),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _shorten(String addr) =>
      addr.length > 22 ? '${addr.substring(0, 22)}...' : addr;
}


