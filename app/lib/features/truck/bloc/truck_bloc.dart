import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import '../../../core/repositories/repositories.dart';
import '../../../models/models.dart';
import 'truck_event.dart';
import 'truck_state.dart';

class TruckBloc extends Bloc<TruckEvent, TruckState> {
  final TruckRepository _truckRepository;
  final TruckTypeRepository _truckTypeRepository;
  final StorageRepository _storageRepository;
  final BiddingRepository _biddingRepository;

  TruckBloc({
    required TruckRepository truckRepository,
    required TruckTypeRepository truckTypeRepository,
    required StorageRepository storageRepository,
    BiddingRepository? biddingRepository,
  })  : _truckRepository = truckRepository,
        _truckTypeRepository = truckTypeRepository,
        _storageRepository = storageRepository,
        _biddingRepository = biddingRepository ?? BiddingRepository(),
        super(TruckInitial()) {
    on<LoadTruckTypesEvent>(_onLoadTruckTypes);
    on<LoadTrucksEvent>(_onLoadTrucks);
    on<LoadTruckDetailEvent>(_onLoadTruckDetail);
    on<AddTruckEvent>(_onAddTruck);
    on<EditTruckEvent>(_onEditTruck);
    on<RemoveTruckEvent>(_onRemoveTruck);
  }

  Future<void> _onLoadTruckTypes(LoadTruckTypesEvent event, Emitter<TruckState> emit) async {
    emit(TruckLoading());
    try {
      final types = await _truckTypeRepository.getAll();
      emit(TruckTypesLoaded(types));
    } catch (e) {
      emit(const TruckError('โหลดประเภทรถไม่สำเร็จ'));
    }
  }

  Future<void> _onLoadTrucks(LoadTrucksEvent event, Emitter<TruckState> emit) async {
    emit(TruckLoading());
    try {
      final trucks = await _truckRepository.getByContractorId(event.contractorId);
      final visible = trucks.where((t) => t.approvalStatus != 'ถูกลบ').toList();
      emit(TrucksLoaded(visible));
    } catch (e) {
      emit(const TruckError('โหลดรายการรถไม่สำเร็จ'));
    }
  }

  Future<void> _onLoadTruckDetail(LoadTruckDetailEvent event, Emitter<TruckState> emit) async {
    emit(TruckLoading());
    try {
      final truck = await _truckRepository.getById(event.truckId);
      if (truck == null) {
        emit(const TruckError('ไม่พบข้อมูลรถบรรทุก'));
        return;
      }
      emit(TruckDetailLoaded(truck));
    } catch (e) {
      emit(const TruckError('โหลดข้อมูลรถไม่สำเร็จ'));
    }
  }

  Future<void> _onAddTruck(AddTruckEvent event, Emitter<TruckState> emit) async {
    emit(TruckLoading());
    try {
      final truckType = await _truckTypeRepository.getById(event.truckTypeId);
      if (truckType == null) {
        emit(const TruckError('ประเภทรถไม่ถูกต้อง'));
        return;
      }

      const uuid = Uuid();
      final truckId = uuid.v4();

      String? registrationDocUrl;
      String? insuranceDocUrl;
      String? truckPhotosUrl;

      if (event.registrationDoc != null) {
        registrationDocUrl = await _storageRepository.uploadFile(
          file: event.registrationDoc!,
          path: 'trucks/$truckId/registration_doc',
        );
      }
      if (event.insuranceDoc != null) {
        insuranceDocUrl = await _storageRepository.uploadFile(
          file: event.insuranceDoc!,
          path: 'trucks/$truckId/insurance_doc',
        );
      }
      if (event.truckPhoto != null) {
        truckPhotosUrl = await _storageRepository.uploadFile(
          file: event.truckPhoto!,
          path: 'trucks/$truckId/photo',
        );
      }

      final truck = TruckModel(
        truckId: truckId,
        brand: event.brand,
        model: event.model,
        licensePlate: event.licensePlate,
        registeredProvince: event.registeredProvince,
        capacity: event.capacity,
        features: event.features,
        registrationDocUrl: registrationDocUrl,
        insuranceDocUrl: insuranceDocUrl,
        truckPhotosUrl: truckPhotosUrl,
        approvalStatus: 'รอตรวจสอบ',
        contractorId: event.contractorId,
        truckType: truckType,
      );

      await _truckRepository.save(truck);
      emit(TruckSaved());
    } catch (e) {
      emit(const TruckError('เพิ่มรถบรรทุกไม่สำเร็จ กรุณาลองใหม่อีกครั้ง'));
    }
  }

  Future<void> _onEditTruck(EditTruckEvent event, Emitter<TruckState> emit) async {
    emit(TruckLoading());
    try {
      final truckType = await _truckTypeRepository.getById(event.truckTypeId);
      if (truckType == null) {
        emit(const TruckError('ประเภทรถไม่ถูกต้อง'));
        return;
      }

      final existing = await _truckRepository.getById(event.truckId);
      if (existing == null) {
        emit(const TruckError('ไม่พบข้อมูลรถ'));
        return;
      }

      String? registrationDocUrl = event.existingRegistrationDocUrl;
      String? insuranceDocUrl = event.existingInsuranceDocUrl;
      String? truckPhotosUrl = event.existingTruckPhotoUrl;

      if (event.registrationDoc != null) {
        registrationDocUrl = await _storageRepository.uploadFile(
          file: event.registrationDoc!,
          path: 'trucks/${event.truckId}/registration_doc',
        );
      }
      if (event.insuranceDoc != null) {
        insuranceDocUrl = await _storageRepository.uploadFile(
          file: event.insuranceDoc!,
          path: 'trucks/${event.truckId}/insurance_doc',
        );
      }
      if (event.truckPhoto != null) {
        truckPhotosUrl = await _storageRepository.uploadFile(
          file: event.truckPhoto!,
          path: 'trucks/${event.truckId}/photo',
        );
      }

      // reset สถานะเป็น "รอตรวจสอบ" เฉพาะเมื่อแก้ field สำคัญ (UC 3.1.23)
      final criticalChanged = existing.licensePlate != event.licensePlate ||
          existing.truckType.truckTypeId != truckType.truckTypeId ||
          existing.capacity != event.capacity ||
          existing.registrationDocUrl != registrationDocUrl ||
          existing.insuranceDocUrl != insuranceDocUrl;
      final newStatus =
          criticalChanged ? 'รอตรวจสอบ' : existing.approvalStatus;

      final truck = TruckModel(
        truckId: event.truckId,
        brand: event.brand,
        model: event.model,
        licensePlate: event.licensePlate,
        registeredProvince: event.registeredProvince,
        capacity: event.capacity,
        features: event.features,
        registrationDocUrl: registrationDocUrl,
        insuranceDocUrl: insuranceDocUrl,
        truckPhotosUrl: truckPhotosUrl,
        approvalStatus: newStatus,
        contractorId: existing.contractorId,
        truckType: truckType,
      );

      await _truckRepository.save(truck);
      emit(TruckSaved(statusReset: criticalChanged));
    } catch (e) {
      emit(const TruckError('แก้ไขรถบรรทุกไม่สำเร็จ กรุณาลองใหม่อีกครั้ง'));
    }
  }

  Future<void> _onRemoveTruck(RemoveTruckEvent event, Emitter<TruckState> emit) async {
    emit(TruckLoading());
    try {
      final hasActiveJob = await _biddingRepository.hasActiveBidForTruck(event.truckId);
      if (hasActiveJob) {
        emit(const TruckError('ไม่สามารถลบรถที่กำลังอยู่ในงานได้ กรุณารอให้งานเสร็จสิ้นก่อน'));
        return;
      }
      await _truckRepository.softDelete(event.truckId);
      emit(TruckRemoved());
    } catch (e) {
      emit(const TruckError('ลบรถบรรทุกไม่สำเร็จ กรุณาลองใหม่อีกครั้ง'));
    }
  }
}
