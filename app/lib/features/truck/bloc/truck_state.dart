import 'package:equatable/equatable.dart';
import '../../../models/models.dart';

abstract class TruckState extends Equatable {
  const TruckState();
  @override
  List<Object?> get props => [];
}

class TruckInitial extends TruckState {}

class TruckLoading extends TruckState {}

class TrucksLoaded extends TruckState {
  final List<TruckModel> trucks;
  const TrucksLoaded(this.trucks);
  @override
  List<Object?> get props => [trucks];
}

class TruckDetailLoaded extends TruckState {
  final TruckModel truck;
  const TruckDetailLoaded(this.truck);
  @override
  List<Object?> get props => [truck];
}

class TruckSaved extends TruckState {
  /// true = สถานะรถถูกรีเซ็ตเป็น "รอตรวจสอบ" (เพิ่มรถใหม่ หรือแก้ field สำคัญ)
  final bool statusReset;
  const TruckSaved({this.statusReset = true});

  @override
  List<Object?> get props => [statusReset];
}

class TruckRemoved extends TruckState {}

class TruckTypesLoaded extends TruckState {
  final List<TruckTypeModel> truckTypes;
  const TruckTypesLoaded(this.truckTypes);
  @override
  List<Object?> get props => [truckTypes];
}

class TruckError extends TruckState {
  final String message;
  const TruckError(this.message);
  @override
  List<Object?> get props => [message];
}
