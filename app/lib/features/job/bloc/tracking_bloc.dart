import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/repositories/repositories.dart';
import '../../../models/models.dart';

/// BLoC สำหรับหน้า "ติดตาม GPS" (UC ติดตามการขนส่ง)
/// โหลดตำแหน่งล่าสุด + ข้อมูลผู้รับจ้าง/รถที่ได้รับเลือก ผ่าน BLoC (ไม่เรียก Repository ตรงในหน้า)

// ── Data ────────────────────────────────────────────────────────────────────
class TrackingData extends Equatable {
  final LocationTrackingModel? location;
  final ContractorModel? contractor;
  final TruckModel? truck;
  const TrackingData({this.location, this.contractor, this.truck});

  @override
  List<Object?> get props => [location, contractor, truck];
}

// ── Events ──────────────────────────────────────────────────────────────────
abstract class TrackingEvent extends Equatable {
  const TrackingEvent();
  @override
  List<Object?> get props => [];
}

class LoadTracking extends TrackingEvent {
  final String jobId;
  const LoadTracking(this.jobId);
  @override
  List<Object?> get props => [jobId];
}

// ── States ──────────────────────────────────────────────────────────────────
abstract class TrackingState extends Equatable {
  const TrackingState();
  @override
  List<Object?> get props => [];
}

class TrackingInitial extends TrackingState {}

class TrackingLoading extends TrackingState {}

class TrackingLoaded extends TrackingState {
  final TrackingData data;
  const TrackingLoaded(this.data);
  @override
  List<Object?> get props => [data];
}

class TrackingError extends TrackingState {
  final String message;
  const TrackingError(this.message);
  @override
  List<Object?> get props => [message];
}

// ── Bloc ────────────────────────────────────────────────────────────────────
class TrackingBloc extends Bloc<TrackingEvent, TrackingState> {
  final LocationTrackingRepository _locationRepo;
  final BiddingRepository _biddingRepo;
  final ContractorRepository _contractorRepo;
  final TruckRepository _truckRepo;

  TrackingBloc({
    LocationTrackingRepository? locationRepository,
    BiddingRepository? biddingRepository,
    ContractorRepository? contractorRepository,
    TruckRepository? truckRepository,
  })  : _locationRepo = locationRepository ?? LocationTrackingRepository(),
        _biddingRepo = biddingRepository ?? BiddingRepository(),
        _contractorRepo = contractorRepository ?? ContractorRepository(),
        _truckRepo = truckRepository ?? TruckRepository(),
        super(TrackingInitial()) {
    on<LoadTracking>(_onLoadTracking);
  }

  Future<void> _onLoadTracking(
    LoadTracking event,
    Emitter<TrackingState> emit,
  ) async {
    emit(TrackingLoading());
    try {
      final results = await Future.wait([
        _locationRepo.getLatestByJobId(event.jobId),
        _biddingRepo.getByJobId(event.jobId),
      ]);
      final loc = results[0] as LocationTrackingModel?;
      final bids = results[1] as List<BiddingModel>;

      ContractorModel? contractor;
      TruckModel? truck;
      final accepted =
          bids.where((b) => b.biddingStatus == 'ได้รับเลือก').firstOrNull;
      if (accepted != null) {
        final cr = await Future.wait([
          _contractorRepo.getById(accepted.contractorId),
          _truckRepo.getById(accepted.truckId),
        ]);
        contractor = cr[0] as ContractorModel?;
        truck = cr[1] as TruckModel?;
      }

      emit(TrackingLoaded(
        TrackingData(location: loc, contractor: contractor, truck: truck),
      ));
    } catch (e) {
      emit(TrackingError('โหลดข้อมูลไม่สำเร็จ: $e'));
    }
  }
}
