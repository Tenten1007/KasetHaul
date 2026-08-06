import 'package:equatable/equatable.dart';

import '../pages/filter_jobs_page.dart';

abstract class SearchJobEvent extends Equatable {
  const SearchJobEvent();

  @override
  List<Object?> get props => [];
}

class LoadSearchDataEvent extends SearchJobEvent {
  final String contractorId;

  const LoadSearchDataEvent({required this.contractorId});

  @override
  List<Object?> get props => [contractorId];
}

class ChangeTruckTypeFilterEvent extends SearchJobEvent {
  final String? truckTypeId;

  const ChangeTruckTypeFilterEvent({this.truckTypeId});

  @override
  List<Object?> get props => [truckTypeId];
}

class ApplySearchFilterEvent extends SearchJobEvent {
  final String searchQuery;
  final JobFilter activeFilter;

  const ApplySearchFilterEvent({
    required this.searchQuery,
    required this.activeFilter,
  });

  @override
  List<Object?> get props => [searchQuery, activeFilter];
}
