import 'package:equatable/equatable.dart';
import '../../../models/models.dart';

abstract class JobState extends Equatable {
  const JobState();
  @override
  List<Object?> get props => [];
}

class JobInitial extends JobState {}
class JobLoading extends JobState {}

class PostJobSuccess extends JobState {
  final JobModel job;
  const PostJobSuccess({required this.job});
  @override
  List<Object?> get props => [job];
}

class JobsLoaded extends JobState {
  final List<JobModel> jobs;
  const JobsLoaded({required this.jobs});
  @override
  List<Object?> get props => [jobs];
}

class JobError extends JobState {
  final String message;
  const JobError({required this.message});
  @override
  List<Object?> get props => [message];
}

class JobDetailLoaded extends JobState {
  final JobModel job;
  const JobDetailLoaded({required this.job});
  @override
  List<Object?> get props => [job];
}

class BiddingsLoaded extends JobState {
  final List<BiddingModel> biddings;
  final Map<String, TruckModel?> trucks; // truckId → TruckModel
  final Map<String, ContractorModel?> contractors; // contractorId → Contractor
  const BiddingsLoaded({
    required this.biddings,
    this.trucks = const {},
    this.contractors = const {},
  });
  @override
  List<Object?> get props => [biddings, trucks, contractors];
}

class JobCancelled extends JobState {}

class JobUpdated extends JobState {}
