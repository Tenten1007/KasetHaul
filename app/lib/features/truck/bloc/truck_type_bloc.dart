import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/repositories/repositories.dart';
import '../../../models/models.dart';

/// BLoC ใช้ซ้ำสำหรับโหลด "รายการประเภทรถ" (dropdown/chips/หน้าตั้งค่า)
/// แทนการเรียก TruckTypeRepository().getAll() ตรงในหน้า
class LoadTruckTypes extends Equatable {
  const LoadTruckTypes();
  @override
  List<Object?> get props => [];
}

abstract class TruckTypeListState extends Equatable {
  const TruckTypeListState();
  @override
  List<Object?> get props => [];
}

class TruckTypeListInitial extends TruckTypeListState {}

class TruckTypeListLoaded extends TruckTypeListState {
  final List<TruckTypeModel> types;
  const TruckTypeListLoaded(this.types);
  @override
  List<Object?> get props => [types];
}

class TruckTypeBloc extends Bloc<LoadTruckTypes, TruckTypeListState> {
  final TruckTypeRepository _repo;

  TruckTypeBloc({TruckTypeRepository? repository})
      : _repo = repository ?? TruckTypeRepository(),
        super(TruckTypeListInitial()) {
    on<LoadTruckTypes>((e, emit) async {
      final types = await _repo.getAll();
      emit(TruckTypeListLoaded(types));
    });
  }
}
