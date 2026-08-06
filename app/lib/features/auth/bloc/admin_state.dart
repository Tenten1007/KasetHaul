part of 'admin_bloc.dart';

abstract class AdminState {
  const AdminState();
}

class AdminInitial extends AdminState {
  const AdminInitial();
}

class AdminLoading extends AdminState {
  const AdminLoading();
}

class AdminLoginSuccess extends AdminState {
  final AdministratorModel admin;

  const AdminLoginSuccess(this.admin);
}

class DashboardLoaded extends AdminState {
  final int pendingTrucks;
  final List<TruckModel> pendingTruckList;
  final int totalUsers;
  final int approvedTrucks;
  final int totalJobs;
  final int activeJobs;
  final int completedJobs;
  final int totalContractors;
  final double totalRevenue;

  const DashboardLoaded({
    required this.pendingTrucks,
    required this.pendingTruckList,
    required this.totalUsers,
    required this.approvedTrucks,
    required this.totalJobs,
    required this.activeJobs,
    required this.completedJobs,
    required this.totalContractors,
    required this.totalRevenue,
  });
}

class PendingTrucksLoaded extends AdminState {
  final List<TruckModel> trucks;

  const PendingTrucksLoaded(this.trucks);
}

class AllTrucksLoaded extends AdminState {
  final List<TruckModel> all;
  final List<TruckModel> pending;
  final List<TruckModel> approved;
  final List<TruckModel> rejected;

  const AllTrucksLoaded({
    required this.all,
    required this.pending,
    required this.approved,
    required this.rejected,
  });
}

class TruckApproved extends AdminState {
  final TruckModel truck;

  const TruckApproved(this.truck);
}

class TruckRejected extends AdminState {
  final TruckModel truck;

  const TruckRejected(this.truck);
}

class AdminError extends AdminState {
  final String message;

  const AdminError(this.message);
}
