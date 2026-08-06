import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/config/app_config.dart';
import '../../../core/repositories/repositories.dart';
import '../../../models/models.dart';
import '../bloc/search_job_bloc.dart';
import '../bloc/search_job_event.dart';
import '../bloc/search_job_state.dart';
import '../bloc/job_card_bloc.dart';
import 'bid_job_page.dart';
import 'filter_jobs_page.dart';
import '../../notification/pages/notification_list_page.dart';

class SearchJobsPage extends StatelessWidget {
  final String contractorId;
  const SearchJobsPage({super.key, required this.contractorId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => SearchJobBloc(
        jobRepository: JobRepository(),
        truckTypeRepository: TruckTypeRepository(),
        truckRepository: TruckRepository(),
        transactionRepository: TransactionRepository(),
      )..add(LoadSearchDataEvent(contractorId: contractorId)),
      child: _SearchJobsView(contractorId: contractorId),
    );
  }
}

class _SearchJobsView extends StatefulWidget {
  final String contractorId;
  const _SearchJobsView({required this.contractorId});

  @override
  State<_SearchJobsView> createState() => _SearchJobsViewState();
}

class _SearchJobsViewState extends State<_SearchJobsView> {
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _openFilter(SearchJobLoaded state) async {
    final result = await Navigator.push<JobFilter>(
      context,
      MaterialPageRoute(
        builder: (_) => FilterJobsPage(initial: state.activeFilter),
      ),
    );
    if (result != null && mounted) {
      context.read<SearchJobBloc>().add(ApplySearchFilterEvent(
            searchQuery: state.searchQuery,
            activeFilter: result,
          ));
    }
  }

  String _formatPrice(int price) {
    return price
        .toString()
        .replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');
  }

  String _formatDate(DateTime dt) {
    const months = [
      '', 'ม.ค.', 'ก.พ.', 'มี.ค.', 'เม.ย.', 'พ.ค.', 'มิ.ย.',
      'ก.ค.', 'ส.ค.', 'ก.ย.', 'ต.ค.', 'พ.ย.', 'ธ.ค.'
    ];
    return '${dt.day} ${months[dt.month]} ${dt.year + 543}';
  }

  String _getFitStatus(JobModel job, Set<String> approvedTruckTypeIds) {
    if (approvedTruckTypeIds.isEmpty) return 'open';
    final matches = approvedTruckTypeIds.contains(job.requiredTruckType.truckTypeId);
    if (!matches) return 'nomatch';
    if (job.distance != null && job.distance! > 300) return 'far';
    return 'match';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConfig.surfaceColor,
      appBar: AppBar(
        backgroundColor: AppConfig.primaryColor,
        foregroundColor: Colors.white,
        title: const Text('ค้นหางาน'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Text('🔔', style: TextStyle(fontSize: 20)),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => NotificationListPage(recipientId: widget.contractorId),
              ),
            ),
          ),
        ],
      ),
      body: BlocBuilder<SearchJobBloc, SearchJobState>(
        builder: (context, state) {
          if (state is SearchJobInitial || state is SearchJobLoading) {
            return const Center(
              child: CircularProgressIndicator(color: AppConfig.primaryColor),
            );
          }

          if (state is SearchJobError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Color(0xFF9E9E9E)),
                  const SizedBox(height: 12),
                  Text(state.message, style: const TextStyle(color: Color(0xFF757575))),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppConfig.primaryColor,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () {
                      context.read<SearchJobBloc>().add(LoadSearchDataEvent(contractorId: widget.contractorId));
                    },
                    child: const Text('ลองใหม่'),
                  ),
                ],
              ),
            );
          }

          if (state is SearchJobLoaded) {
            return Column(
              children: [
                // Search bar
                Container(
                  color: AppConfig.primaryColor,
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TextField(
                      key: const Key('search_field'),
                      controller: _searchCtrl,
                      decoration: InputDecoration(
                        hintText: 'ค้นหางาน, สินค้า, สถานที่...',
                        prefixIcon: const Icon(Icons.search, color: Color(0xFF9E9E9E)),
                        suffixIcon: GestureDetector(
                          onTap: () => _openFilter(state),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              const Icon(Icons.tune_rounded, color: Color(0xFF9E9E9E)),
                              if (!state.activeFilter.isEmpty)
                                Positioned(
                                  top: 10,
                                  right: 10,
                                  child: Container(
                                    width: 8,
                                    height: 8,
                                    decoration: const BoxDecoration(
                                      color: AppConfig.primaryColor,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onChanged: (v) {
                        context.read<SearchJobBloc>().add(ApplySearchFilterEvent(
                              searchQuery: v.toLowerCase(),
                              activeFilter: state.activeFilter,
                            ));
                      },
                    ),
                  ),
                ),

                // Horizontal filter chips
                Container(
                  color: AppConfig.primaryColor,
                  child: SizedBox(
                    height: 44,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 10),
                      children: [
                        _FilterChip(
                          label: 'ทั้งหมด',
                          selected: state.selectedTruckTypeId == null,
                          onTap: () => context
                              .read<SearchJobBloc>()
                              .add(const ChangeTruckTypeFilterEvent(truckTypeId: null)),
                        ),
                        const SizedBox(width: 8),
                        ...state.truckTypes.map((t) => Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: _FilterChip(
                                label: t.typeName,
                                selected: state.selectedTruckTypeId == t.truckTypeId,
                                onTap: () => context
                                    .read<SearchJobBloc>()
                                    .add(ChangeTruckTypeFilterEvent(truckTypeId: t.truckTypeId)),
                              ),
                            )),
                      ],
                    ),
                  ),
                ),

                // Job list
                Expanded(
                  child: state.filteredJobs.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.work_off_outlined,
                                  size: 64, color: Color(0xFFBDBDBD)),
                              const SizedBox(height: 16),
                              const Text(
                                'ไม่พบงานที่เปิดรับขณะนี้',
                                style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF757575)),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'ลองเปลี่ยนตัวกรองหรือค้นหาใหม่อีกครั้ง',
                                style: TextStyle(fontSize: 13, color: Color(0xFF9E9E9E)),
                              ),
                              const SizedBox(height: 24),
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppConfig.primaryColor,
                                  foregroundColor: Colors.white,
                                ),
                                onPressed: () {
                                  context.read<SearchJobBloc>().add(
                                      LoadSearchDataEvent(contractorId: widget.contractorId));
                                },
                                icon: const Icon(Icons.refresh),
                                label: const Text('รีเฟรช'),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          color: AppConfig.primaryColor,
                          onRefresh: () async {
                            context.read<SearchJobBloc>().add(
                                LoadSearchDataEvent(contractorId: widget.contractorId));
                          },
                          child: ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: state.filteredJobs.length + 1,
                            itemBuilder: (ctx, i) {
                              if (i == 0) {
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Stats card — gradient green
                                    Container(
                                      margin: const EdgeInsets.only(bottom: 16),
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
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              const Text('งานที่เปิดรับ',
                                                  style: TextStyle(
                                                      color: Colors.white70, fontSize: 13)),
                                              Text('${state.filteredJobs.length} งาน',
                                                  style: const TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 28,
                                                      fontWeight: FontWeight.w700)),
                                            ],
                                          ),
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.end,
                                            children: [
                                              const Text('รายได้สัปดาห์นี้',
                                                  style: TextStyle(
                                                      color: Colors.white70, fontSize: 13)),
                                              Text(
                                                  '฿${_formatPrice(state.weeklyIncome.round())}',
                                                  style: const TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 20,
                                                      fontWeight: FontWeight.w700)),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    const Text('งานแนะนำสำหรับคุณ',
                                        style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF424242))),
                                    const SizedBox(height: 12),
                                  ],
                                );
                              }
                              final job = state.filteredJobs[i - 1];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: _JobCard(
                                  job: job,
                                  fitStatus: _getFitStatus(job, state.myApprovedTruckTypeIds),
                                  formatPrice: _formatPrice,
                                  formatDate: _formatDate,
                                  onTap: () async {
                                    await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => BidJobPage(
                                          jobId: job.jobId,
                                          contractorId: widget.contractorId,
                                        ),
                                      ),
                                    );
                                    if (!context.mounted) return;
                                    context.read<SearchJobBloc>().add(
                                        LoadSearchDataEvent(contractorId: widget.contractorId));
                                  },
                                ),
                              );
                            },
                          ),
                        ),
                ),
              ],
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.white.withAlpha(51),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? Colors.white : Colors.white.withAlpha(102),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: selected ? AppConfig.primaryColor : Colors.white,
            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

class _JobCard extends StatefulWidget {
  final JobModel job;
  final String fitStatus;
  final String Function(int) formatPrice;
  final String Function(DateTime) formatDate;
  final VoidCallback onTap;

  const _JobCard({
    required this.job,
    required this.fitStatus,
    required this.formatPrice,
    required this.formatDate,
    required this.onTap,
  });

  @override
  State<_JobCard> createState() => _JobCardState();
}

class _JobCardState extends State<_JobCard> {
  Widget _buildBadge() {
    switch (widget.fitStatus) {
      case 'match':
        return _badge('✓ ตรงกับรถคุณ', const Color(0xFFE8F5E9), const Color(0xFF2E7D32));
      case 'far':
        return _badge('⚠️ ระยะไกล', const Color(0xFFFFF3E0), const Color(0xFFE65100));
      case 'nomatch':
        return _badge('✗ รถไม่ตรง', const Color(0xFFFFEBEE), const Color(0xFFC62828));
      default:
        return _badge('เปิดรับข้อเสนอ', const Color(0xFFE8F5E9), const Color(0xFF2E7D32));
    }
  }

  Widget _badge(String text, Color bg, Color fg) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
        child: Text(text, style: TextStyle(fontSize: 11, color: fg, fontWeight: FontWeight.w600)),
      );

  @override
  Widget build(BuildContext context) {
    // โหลดจำนวนข้อเสนอผ่าน JobCardBloc (ไม่เรียก Repository ตรงในหน้า)
    return BlocProvider(
      create: (_) =>
          JobCardBloc()..add(LoadJobCard(widget.job.jobId, loadBiddingCount: true)),
      child: GestureDetector(
      onTap: widget.onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [AppConfig.cardShadow],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
               crossAxisAlignment: CrossAxisAlignment.start,
               children: [
                 Expanded(
                   child: Column(
                     crossAxisAlignment: CrossAxisAlignment.start,
                     children: [
                       Text(
                         widget.job.jobTitle,
                         style: const TextStyle(
                           fontSize: 15,
                           fontWeight: FontWeight.w600,
                           color: Color(0xFF212121),
                         ),
                       ),
                       const SizedBox(height: 2),
                       Text(
                         '${widget.job.productType} • ${widget.job.requiredTruckType.typeName}',
                         style: const TextStyle(
                           fontSize: 13,
                           color: AppConfig.primaryDarkColor,
                           fontWeight: FontWeight.w500,
                         ),
                       ),
                     ],
                   ),
                 ),
                 const SizedBox(width: 8),
                 _buildBadge(),
               ],
             ),

             const SizedBox(height: 12),

             // Route
             Row(
               children: [
                 Container(width: 8, height: 8,
                   decoration: const BoxDecoration(color: AppConfig.primaryColor, shape: BoxShape.circle)),
                 Expanded(child: Container(height: 2, margin: const EdgeInsets.symmetric(horizontal: 6), color: const Color(0xFFE0E0E0))),
                 Container(width: 8, height: 8,
                   decoration: BoxDecoration(color: Colors.red.shade400, shape: BoxShape.circle)),
               ],
             ),
             const SizedBox(height: 4),
             Row(
               mainAxisAlignment: MainAxisAlignment.spaceBetween,
               children: [
                 Flexible(
                   child: Text(_shortenAddr(widget.job.pickupAddress),
                       style: const TextStyle(fontSize: 12, color: Color(0xFF616161)),
                       overflow: TextOverflow.ellipsis),
                 ),
                 Flexible(
                   child: Text(_shortenAddr(widget.job.dropoffAddress),
                       style: const TextStyle(fontSize: 12, color: Color(0xFF616161)),
                       overflow: TextOverflow.ellipsis, textAlign: TextAlign.end),
                 ),
               ],
             ),

             const SizedBox(height: 10),

             // Meta row: 📏 distance, 📅 date, 👥 bid count
             Wrap(
               spacing: 12,
               runSpacing: 4,
               children: [
                 if (widget.job.distance != null)
                   _MetaItem(emoji: '📏', label: '${widget.job.distance} กม.'),
                 _MetaItem(emoji: '📅', label: widget.formatDate(widget.job.pickupDatetime)),
                 BlocBuilder<JobCardBloc, JobCardState>(
                   builder: (context, s) => _MetaItem(
                     emoji: '👥',
                     label: s.biddingCount != null
                         ? '${s.biddingCount} คนเสนอ'
                         : '...',
                   ),
                 ),
               ],
             ),

             const SizedBox(height: 12),
             const Divider(height: 1, color: AppConfig.surfaceColor),
             const SizedBox(height: 12),

             Row(
               mainAxisAlignment: MainAxisAlignment.spaceBetween,
               children: [
                 Column(
                   crossAxisAlignment: CrossAxisAlignment.start,
                   children: [
                     const Text('งบประมาณ',
                         style: TextStyle(fontSize: 11, color: Color(0xFF9E9E9E))),
                     Text(
                       '฿${widget.formatPrice(widget.job.budgetPrice)}',
                       style: const TextStyle(
                         fontSize: 18,
                         fontWeight: FontWeight.bold,
                         color: AppConfig.primaryColor,
                       ),
                     ),
                   ],
                 ),
                 OutlinedButton(
                   style: OutlinedButton.styleFrom(
                     foregroundColor: AppConfig.primaryColor,
                     side: const BorderSide(color: AppConfig.primaryColor),
                     padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                   ),
                   onPressed: widget.onTap,
                   child: const Text('ดูรายละเอียด',
                       style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                 ),
               ],
             ),
           ],
         ),
       ),
     ),
    );
  }

   String _shortenAddr(String addr) =>
       addr.length > 22 ? '${addr.substring(0, 22)}...' : addr;
}

class _MetaItem extends StatelessWidget {
  final String emoji;
  final String label;
  const _MetaItem({required this.emoji, required this.label});

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 13)),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF757575))),
        ],
      );
}
