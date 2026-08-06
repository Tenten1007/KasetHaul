import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/repositories/repositories.dart';
import '../../../models/models.dart';
import '../pages/filter_jobs_page.dart';
import 'search_job_event.dart';
import 'search_job_state.dart';

class SearchJobBloc extends Bloc<SearchJobEvent, SearchJobState> {
  final JobRepository jobRepository;
  final TruckTypeRepository truckTypeRepository;
  final TruckRepository truckRepository;
  final TransactionRepository transactionRepository;

  SearchJobBloc({
    required this.jobRepository,
    required this.truckTypeRepository,
    required this.truckRepository,
    required this.transactionRepository,
  }) : super(SearchJobInitial()) {
    on<LoadSearchDataEvent>(_onLoadSearchData);
    on<ChangeTruckTypeFilterEvent>(_onChangeTruckTypeFilter);
    on<ApplySearchFilterEvent>(_onApplySearchFilter);
  }

  Future<void> _onLoadSearchData(
    LoadSearchDataEvent event,
    Emitter<SearchJobState> emit,
  ) async {
    emit(SearchJobLoading());
    try {
      // 1. Fetch open jobs
      final jobs = await jobRepository.getOpenJobsForContractor();

      // 2. Fetch truck types
      final truckTypes = await truckTypeRepository.getAll();

      // 3. Fetch approved truck types for this contractor
      final myTrucks = await truckRepository.getByContractorId(event.contractorId);
      final approvedTypeIds = myTrucks
          .where((t) => t.approvalStatus == 'อนุมัติแล้ว')
          .map((t) => t.truckType.truckTypeId)
          .toSet();

      // 4. Calculate weekly income
      double weeklyIncome = 0;
      try {
        final txs = await transactionRepository.getByContractorId(event.contractorId);
        final cutoff = DateTime.now().subtract(const Duration(days: 7));
        weeklyIncome = txs
            .where((t) => t.transactionType == 'รับค่างาน' && t.transactionDate.isAfter(cutoff))
            .fold<double>(0.0, (sum, t) => sum + t.amount);
      } catch (_) {
        // Fallback if transaction fails
      }

      emit(SearchJobLoaded(
        allJobs: jobs,
        filteredJobs: jobs,
        truckTypes: truckTypes,
        myApprovedTruckTypeIds: approvedTypeIds,
        weeklyIncome: weeklyIncome,
        searchQuery: '',
        activeFilter: const JobFilter(),
        contractorId: event.contractorId,
      ));
    } catch (e) {
      if (e.toString().contains('FAILED_PRECONDITION')) {
        emit(const SearchJobError('ระบบกำลังสร้าง index กรุณารอ 1-2 นาที แล้วลองใหม่'));
      } else {
        emit(const SearchJobError('โหลดรายการงานไม่สำเร็จ กรุณาลองใหม่อีกครั้ง'));
      }
    }
  }

  Future<void> _onChangeTruckTypeFilter(
    ChangeTruckTypeFilterEvent event,
    Emitter<SearchJobState> emit,
  ) async {
    final currentState = state;
    if (currentState is SearchJobLoaded) {
      emit(SearchJobLoading());
      try {
        final jobs = await jobRepository.getOpenJobsForContractor(truckTypeId: event.truckTypeId);
        
        final filtered = _applyFilters(
          jobs: jobs,
          searchQuery: currentState.searchQuery,
          activeFilter: currentState.activeFilter,
        );

        emit(currentState.copyWith(
          allJobs: jobs,
          filteredJobs: filtered,
          selectedTruckTypeId: event.truckTypeId,
          clearTruckTypeFilter: event.truckTypeId == null,
        ));
      } catch (e) {
        emit(const SearchJobError('ไม่สามารถโหลดข้อมูลตามตัวกรองได้'));
      }
    }
  }

  void _onApplySearchFilter(
    ApplySearchFilterEvent event,
    Emitter<SearchJobState> emit,
  ) {
    final currentState = state;
    if (currentState is SearchJobLoaded) {
      final filtered = _applyFilters(
        jobs: currentState.allJobs,
        searchQuery: event.searchQuery,
        activeFilter: event.activeFilter,
      );

      emit(currentState.copyWith(
        searchQuery: event.searchQuery,
        activeFilter: event.activeFilter,
        filteredJobs: filtered,
      ));
    }
  }

  List<JobModel> _applyFilters({
    required List<JobModel> jobs,
    required String searchQuery,
    required JobFilter activeFilter,
  }) {
    // 1. Search Query Filter
    final searched = searchQuery.isEmpty
        ? jobs
        : jobs.where((j) {
            return j.jobTitle.toLowerCase().contains(searchQuery) ||
                j.productType.toLowerCase().contains(searchQuery) ||
                j.pickupAddress.toLowerCase().contains(searchQuery) ||
                j.dropoffAddress.toLowerCase().contains(searchQuery);
          }).toList();

    // 2. Active JobFilter
    if (activeFilter.isEmpty) return searched;

    return searched.where((j) {
      if (activeFilter.selectedTruckTypes.isNotEmpty) {
        final match = activeFilter.selectedTruckTypes.any(
          (t) => j.requiredTruckType.typeName.toLowerCase().contains(t.toLowerCase()),
        );
        if (!match) return false;
      }
      if (activeFilter.minWeight != null && j.weight < activeFilter.minWeight!) {
        return false;
      }
      if (activeFilter.maxWeight != null && j.weight > activeFilter.maxWeight!) {
        return false;
      }
      if (activeFilter.minBudget != null && j.budgetPrice < activeFilter.minBudget!) {
        return false;
      }
      if (activeFilter.maxBudget != null && j.budgetPrice > activeFilter.maxBudget!) {
        return false;
      }
      if (activeFilter.selectedProductTypes.isNotEmpty) {
        final match = activeFilter.selectedProductTypes.any(
          (p) => j.productType.toLowerCase().contains(p.toLowerCase()),
        );
        if (!match) return false;
      }
      return true;
    }).toList();
  }
}
