import 'package:equatable/equatable.dart';
import '../../../models/models.dart';
import '../pages/filter_jobs_page.dart';

abstract class SearchJobState extends Equatable {
  const SearchJobState();

  @override
  List<Object?> get props => [];
}

class SearchJobInitial extends SearchJobState {}

class SearchJobLoading extends SearchJobState {}

class SearchJobLoaded extends SearchJobState {
  final List<JobModel> allJobs;
  final List<JobModel> filteredJobs;
  final List<TruckTypeModel> truckTypes;
  final Set<String> myApprovedTruckTypeIds;
  final double weeklyIncome;
  final String? selectedTruckTypeId;
  final String searchQuery;
  final JobFilter activeFilter;
  final String contractorId;

  const SearchJobLoaded({
    required this.allJobs,
    required this.filteredJobs,
    required this.truckTypes,
    required this.myApprovedTruckTypeIds,
    required this.weeklyIncome,
    this.selectedTruckTypeId,
    required this.searchQuery,
    required this.activeFilter,
    required this.contractorId,
  });

  SearchJobLoaded copyWith({
    List<JobModel>? allJobs,
    List<JobModel>? filteredJobs,
    List<TruckTypeModel>? truckTypes,
    Set<String>? myApprovedTruckTypeIds,
    double? weeklyIncome,
    String? selectedTruckTypeId,
    String? searchQuery,
    JobFilter? activeFilter,
    String? contractorId,
    bool clearTruckTypeFilter = false,
  }) {
    return SearchJobLoaded(
      allJobs: allJobs ?? this.allJobs,
      filteredJobs: filteredJobs ?? this.filteredJobs,
      truckTypes: truckTypes ?? this.truckTypes,
      myApprovedTruckTypeIds: myApprovedTruckTypeIds ?? this.myApprovedTruckTypeIds,
      weeklyIncome: weeklyIncome ?? this.weeklyIncome,
      selectedTruckTypeId: clearTruckTypeFilter ? null : (selectedTruckTypeId ?? this.selectedTruckTypeId),
      searchQuery: searchQuery ?? this.searchQuery,
      activeFilter: activeFilter ?? this.activeFilter,
      contractorId: contractorId ?? this.contractorId,
    );
  }

  @override
  List<Object?> get props => [
        allJobs,
        filteredJobs,
        truckTypes,
        myApprovedTruckTypeIds,
        weeklyIncome,
        selectedTruckTypeId,
        searchQuery,
        activeFilter,
        contractorId,
      ];
}

class SearchJobError extends SearchJobState {
  final String message;

  const SearchJobError(this.message);

  @override
  List<Object?> get props => [message];
}
