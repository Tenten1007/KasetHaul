part of 'admin_bloc.dart';

abstract class AdminEvent {
  const AdminEvent();
}

class AdminLoginEvent extends AdminEvent {
  final String username;
  final String password;

  const AdminLoginEvent({required this.username, required this.password});
}

class LoadDashboardEvent extends AdminEvent {
  const LoadDashboardEvent();
}

class LoadPendingTrucksEvent extends AdminEvent {
  const LoadPendingTrucksEvent();
}

class LoadAllTrucksEvent extends AdminEvent {
  const LoadAllTrucksEvent();
}

class ApproveTruckEvent extends AdminEvent {
  final String truckId;
  final String contractorId;

  const ApproveTruckEvent({required this.truckId, required this.contractorId});
}

class RejectTruckEvent extends AdminEvent {
  final String truckId;
  final String contractorId;
  final String reason;

  const RejectTruckEvent({
    required this.truckId,
    required this.contractorId,
    required this.reason,
  });
}
