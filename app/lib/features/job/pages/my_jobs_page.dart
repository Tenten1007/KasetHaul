import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/config/app_config.dart';
import '../../../core/repositories/repositories.dart';
import '../../../models/models.dart';
import '../../../shared/widgets/job_card_widget.dart';
import '../../../shared/widgets/stats_grid_widget.dart';
import '../../../shared/widgets/section_title_widget.dart';
import '../../review/pages/write_review_page.dart';
import '../bloc/job_bloc.dart';
import '../bloc/job_event.dart';
import '../bloc/job_state.dart';
import '../bloc/job_card_bloc.dart';
import 'job_detail_page.dart';
import 'post_job_page.dart';

class MyJobsPage extends StatelessWidget {
  final String clientId;
  const MyJobsPage({super.key, required this.clientId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => JobBloc(
        jobRepository: JobRepository(),
        biddingRepository: BiddingRepository(),
      )..add(LoadJobsEvent(clientId: clientId)),
      child: _MyJobsView(clientId: clientId),
    );
  }
}

class _MyJobsView extends StatefulWidget {
  final String clientId;
  const _MyJobsView({required this.clientId});

  @override
  State<_MyJobsView> createState() => _MyJobsViewState();
}

class _MyJobsViewState extends State<_MyJobsView>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConfig.surfaceColor,
      appBar: AppBar(
        backgroundColor: AppConfig.primaryColor,
        foregroundColor: Colors.white,
        title: const Text('งานขนส่งของฉัน'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add, size: 28),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => PostJobPage(clientId: widget.clientId),
              ),
            ),
          ),
        ],
      ),
      // แถบแท็บอยู่บนพื้นขาว (ตาม Mockup) active สีเขียว+เส้นใต้เขียว
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
                Tab(text: 'เปิดรับ'),
                // ตัด 2 บรรทัดให้พอดีช่อง (ตาม Mockup) ไม่ให้ถูกตัดเป็น '...'
                Tab(
                    child: Text('กำลัง\nดำเนินการ',
                        textAlign: TextAlign.center,
                        style: TextStyle(height: 1.15))),
                Tab(text: 'เสร็จสิ้น'),
              ],
            ),
          ),
          Expanded(
            child: _buildBody(),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    return BlocBuilder<JobBloc, JobState>(
        builder: (context, state) {
          if (state is JobLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is JobError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(state.message,
                      style: const TextStyle(color: Color(0xFF757575))),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => context.read<JobBloc>().add(
                          LoadJobsEvent(clientId: widget.clientId),
                        ),
                    child: const Text('ลองใหม่'),
                  ),
                ],
              ),
            );
          }
          if (state is JobsLoaded) {
            return RefreshIndicator(
              onRefresh: () async => context
                  .read<JobBloc>()
                  .add(LoadJobsEvent(clientId: widget.clientId)),
              child: _JobsTabView(
                jobs: state.jobs,
                clientId: widget.clientId,
                tabController: _tabController,
              ),
            );
          }
          return const SizedBox();
        },
    );
  }
}

class _JobsTabView extends StatelessWidget {
  final List<JobModel> jobs;
  final String clientId;
  final TabController tabController;

  const _JobsTabView({
    required this.jobs,
    required this.clientId,
    required this.tabController,
  });

  List<JobModel> _filterJobs(int tabIndex) {
    switch (tabIndex) {
      case 1:
        return jobs.where((j) => j.jobStatus == 'รอผู้รับจ้าง').toList();
      case 2:
        return jobs
            .where((j) =>
                j.jobStatus == 'มอบหมายแล้ว' ||
                j.jobStatus == 'ถึงจุดรับสินค้า' ||
                j.jobStatus == 'รับสินค้าเรียบร้อย' ||
                j.jobStatus == 'กำลังขนส่ง' ||
                j.jobStatus == 'ถึงจุดส่งสินค้า')
            .toList();
      case 3:
        return jobs
            .where((j) =>
                j.jobStatus == 'จัดส่งสำเร็จ' || j.jobStatus == 'ยกเลิก')
            .toList();
      default:
        return jobs;
    }
  }

  int get _openCount =>
      jobs.where((j) => j.jobStatus == 'รอผู้รับจ้าง').length;
  int get _activeCount => jobs
      .where((j) =>
          j.jobStatus == 'มอบหมายแล้ว' ||
          j.jobStatus == 'ถึงจุดรับสินค้า' ||
          j.jobStatus == 'รับสินค้าเรียบร้อย' ||
          j.jobStatus == 'กำลังขนส่ง' ||
          j.jobStatus == 'ถึงจุดส่งสินค้า')
      .length;

  @override
  Widget build(BuildContext context) {
    return TabBarView(
      controller: tabController,
      children: List.generate(4, (tabIndex) {
        final filtered = _filterJobs(tabIndex);
        return _JobListTab(
          jobs: filtered,
          clientId: clientId,
          showStats: tabIndex == 0,
          openCount: _openCount,
          activeCount: _activeCount,
        );
      }),
    );
  }
}

class _JobListTab extends StatelessWidget {
  final List<JobModel> jobs;
  final String clientId;
  final bool showStats;
  final int openCount;
  final int activeCount;

  const _JobListTab({
    required this.jobs,
    required this.clientId,
    required this.showStats,
    required this.openCount,
    required this.activeCount,
  });

  @override
  Widget build(BuildContext context) {
    if (jobs.isEmpty && !showStats) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('📦', style: TextStyle(fontSize: 64)),
            SizedBox(height: 16),
            Text('ไม่มีงานในหมวดนี้',
                style: TextStyle(color: Color(0xFF757575), fontSize: 16)),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Stats grid (only on "all" tab)
        if (showStats) ...[
          StatsGridWidget(
            items: [
              StatItem(
                value: '$openCount',
                label: 'งานที่เปิดอยู่',
                valueColor: AppConfig.primaryColor,
              ),
              StatItem(
                value: '$activeCount',
                label: 'กำลังดำเนินการ',
                valueColor: AppConfig.accentColor,
              ),
            ],
          ),
          const SizedBox(height: 20),
        ],

        if (jobs.isEmpty && showStats)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 40),
            child: Center(
              child: Text('ยังไม่มีงาน',
                  style: TextStyle(color: Color(0xFF757575), fontSize: 16)),
            ),
          )
        else ...[
          const SectionTitleWidget(title: 'งานล่าสุด'),
          ...jobs.map(
            (job) => _JobCardWithReview(job: job, clientId: clientId),
          ),
        ],
      ],
    );
  }
}

/// Widget สำหรับ job card ที่เพิ่ม logic รีวิว — โหลดข้อมูลเสริมผ่าน JobCardBloc
class _JobCardWithReview extends StatelessWidget {
  final JobModel job;
  final String clientId;

  const _JobCardWithReview({required this.job, required this.clientId});

  bool get _isDone => job.jobStatus == 'จัดส่งสำเร็จ';
  bool get _isOpen => job.jobStatus == 'รอผู้รับจ้าง';

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => JobCardBloc()
        ..add(LoadJobCard(
          job.jobId,
          loadBiddingCount: _isOpen,
          loadReview: _isDone,
        )),
      child: _JobCardWithReviewView(job: job, clientId: clientId),
    );
  }
}

class _JobCardWithReviewView extends StatelessWidget {
  final JobModel job;
  final String clientId;

  const _JobCardWithReviewView({required this.job, required this.clientId});

  bool get _isDone => job.jobStatus == 'จัดส่งสำเร็จ';
  bool get _isOpen => job.jobStatus == 'รอผู้รับจ้าง';

  Future<void> _navigateToReview(BuildContext context) async {
    final contractorId = context.read<JobCardBloc>().state.acceptedContractorId;
    if (contractorId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ไม่พบข้อมูลผู้รับจ้าง')),
      );
      return;
    }
    // capture bloc ก่อน navigate เพื่อไม่ใช้ context ข้าม async gap
    final cardBloc = context.read<JobCardBloc>();
    await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => WriteReviewPage(
          jobId: job.jobId,
          reviewerClientId: clientId,
          revieweeContractorId: contractorId,
          jobTitle: job.jobTitle,
        ),
      ),
    );
    // รีเฟรช status รีวิวหลังกลับมา
    cardBloc.add(RefreshReviewStatus(job.jobId));
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<JobCardBloc, JobCardState>(
      builder: (context, state) {
        final biddingCount = state.biddingCount;
        return Column(
          children: [
            JobCardWidget(
              job: job,
              biddingCount: biddingCount,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      JobDetailPage(jobId: job.jobId, isClient: true),
                ),
              ),
              onViewDetail: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      JobDetailPage(jobId: job.jobId, isClient: true),
                ),
              ),
              onViewBiddings: _isOpen && (biddingCount ?? 0) > 0
                  ? () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              JobDetailPage(jobId: job.jobId, isClient: true),
                        ),
                      )
                  : null,
            ),
            // แสดง review strip เฉพาะงาน "จัดส่งสำเร็จ"
            if (_isDone)
              _ReviewStrip(
                hasReviewed: state.hasReviewed,
                isChecking: state.checkingReview,
                onReview: () => _navigateToReview(context),
              ),
          ],
        );
      },
    );
  }
}

/// Strip แสดงสถานะรีวิวใต้ job card
class _ReviewStrip extends StatelessWidget {
  final bool hasReviewed;
  final bool isChecking;
  final VoidCallback onReview;

  const _ReviewStrip({
    required this.hasReviewed,
    required this.isChecking,
    required this.onReview,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12, left: 4, right: 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: hasReviewed
            ? const Color(0xFFE8F5E9)
            : const Color(0xFFFFF8E1),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
        boxShadow: const [
          AppConfig.cardShadow,
        ],
      ),
      child: isChecking
          ? const Center(
              child: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppConfig.primaryColor,
                ),
              ),
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  hasReviewed ? '★★★★★  รีวิวแล้ว' : 'ยังไม่ได้รีวิว',
                  style: TextStyle(
                    fontSize: 13,
                    color: hasReviewed
                        ? AppConfig.primaryColor
                        : const Color(0xFF9E9E9E),
                    fontWeight: hasReviewed
                        ? FontWeight.w600
                        : FontWeight.w400,
                  ),
                ),
                if (!hasReviewed)
                  GestureDetector(
                    onTap: onReview,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppConfig.primaryColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'ให้คะแนน',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}


