import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:app/core/repositories/repositories.dart';
import 'package:app/features/truck/bloc/truck_bloc.dart';
import 'package:app/features/truck/bloc/truck_event.dart';
import 'package:app/features/truck/bloc/truck_state.dart';
import 'package:app/models/models.dart';

// ─── Mocks ────────────────────────────────────────────────────────────────────
class MockTruckRepository extends Mock implements TruckRepository {}
class MockTruckTypeRepository extends Mock implements TruckTypeRepository {}
class MockStorageRepository extends Mock implements StorageRepository {}
class MockBiddingRepository extends Mock implements BiddingRepository {}

// Fake values สำหรับ registerFallbackValue
class FakeTruckModel extends Fake implements TruckModel {}

// ─── Helpers: ข้อมูลตัวอย่าง ──────────────────────────────────────────────────
const _kTruckType = TruckTypeModel(
  truckTypeId: 'tt-6wheel',
  typeName: 'รถบรรทุก 6 ล้อ',
  maxWeightCapacity: 6000,
);

TruckModel _makeTruck({
  String id = 'truck-1',
  String approvalStatus = 'รอตรวจสอบ',
  String contractorId = 'contractor-1',
}) {
  return TruckModel(
    truckId: id,
    brand: 'อีซูซุ',
    model: 'NQR',
    licensePlate: 'กข 1234 เชียงใหม่',
    approvalStatus: approvalStatus,
    contractorId: contractorId,
    truckType: _kTruckType,
  );
}

TruckTypeModel _makeTruckType({
  String id = 'tt-6wheel',
  String name = 'รถบรรทุก 6 ล้อ',
}) {
  return TruckTypeModel(
    truckTypeId: id,
    typeName: name,
    maxWeightCapacity: 6000,
  );
}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeTruckModel());
  });

  late MockTruckRepository truckRepo;
  late MockTruckTypeRepository truckTypeRepo;
  late MockStorageRepository storageRepo;
  late MockBiddingRepository biddingRepo;

  setUp(() {
    truckRepo = MockTruckRepository();
    truckTypeRepo = MockTruckTypeRepository();
    storageRepo = MockStorageRepository();
    biddingRepo = MockBiddingRepository();
  });

  TruckBloc makeBloc() => TruckBloc(
        truckRepository: truckRepo,
        truckTypeRepository: truckTypeRepo,
        storageRepository: storageRepo,
        biddingRepository: biddingRepo,
      );

  // ─── LoadTruckTypesEvent ───────────────────────────────────────────────────

  group('LoadTruckTypesEvent', () {
    blocTest<TruckBloc, TruckState>(
      'emits [Loading, TruckTypesLoaded] เมื่อโหลดประเภทรถสำเร็จ',
      build: () {
        when(() => truckTypeRepo.getAll()).thenAnswer((_) async => [
              _makeTruckType(id: 'tt-pickup', name: 'รถกระบะบรรทุก'),
              _makeTruckType(id: 'tt-6wheel', name: 'รถบรรทุก 6 ล้อ'),
              _makeTruckType(id: 'tt-10wheel', name: 'รถบรรทุก 10 ล้อ'),
            ]);
        return makeBloc();
      },
      act: (bloc) => bloc.add(LoadTruckTypesEvent()),
      expect: () => [
        isA<TruckLoading>(),
        isA<TruckTypesLoaded>()
            .having((s) => s.truckTypes.length, 'truckTypes.length', 3),
      ],
    );

    blocTest<TruckBloc, TruckState>(
      'emits [Loading, TruckError] เมื่อ truckTypeRepository throw',
      build: () {
        when(() => truckTypeRepo.getAll())
            .thenThrow(Exception('Firestore error'));
        return makeBloc();
      },
      act: (bloc) => bloc.add(LoadTruckTypesEvent()),
      expect: () => [
        isA<TruckLoading>(),
        isA<TruckError>()
            .having((s) => s.message, 'message', contains('โหลดประเภทรถไม่สำเร็จ')),
      ],
    );
  });

  // ─── LoadTrucksEvent ───────────────────────────────────────────────────────

  group('LoadTrucksEvent', () {
    blocTest<TruckBloc, TruckState>(
      'emits [Loading, TrucksLoaded] และกรองรถที่ approvalStatus="ถูกลบ" ออก',
      build: () {
        when(() => truckRepo.getByContractorId('contractor-1'))
            .thenAnswer((_) async => [
                  _makeTruck(id: 'truck-1', approvalStatus: 'อนุมัติแล้ว'),
                  _makeTruck(id: 'truck-2', approvalStatus: 'รอตรวจสอบ'),
                  _makeTruck(id: 'truck-deleted', approvalStatus: 'ถูกลบ'),
                ]);
        return makeBloc();
      },
      act: (bloc) => bloc.add(const LoadTrucksEvent('contractor-1')),
      expect: () => [
        isA<TruckLoading>(),
        isA<TrucksLoaded>()
            .having((s) => s.trucks.length, 'trucks.length', 2),
      ],
    );

    blocTest<TruckBloc, TruckState>(
      'TrucksLoaded ว่างเปล่าเมื่อรถทุกคันถูกลบ',
      build: () {
        when(() => truckRepo.getByContractorId('contractor-1'))
            .thenAnswer((_) async => [
                  _makeTruck(id: 'truck-1', approvalStatus: 'ถูกลบ'),
                  _makeTruck(id: 'truck-2', approvalStatus: 'ถูกลบ'),
                ]);
        return makeBloc();
      },
      act: (bloc) => bloc.add(const LoadTrucksEvent('contractor-1')),
      expect: () => [
        isA<TruckLoading>(),
        isA<TrucksLoaded>().having((s) => s.trucks, 'trucks', isEmpty),
      ],
    );

    blocTest<TruckBloc, TruckState>(
      'emits [Loading, TruckError] เมื่อ truckRepository throw',
      build: () {
        when(() => truckRepo.getByContractorId(any()))
            .thenThrow(Exception('Permission denied'));
        return makeBloc();
      },
      act: (bloc) => bloc.add(const LoadTrucksEvent('contractor-1')),
      expect: () => [
        isA<TruckLoading>(),
        isA<TruckError>()
            .having((s) => s.message, 'message', contains('โหลดรายการรถไม่สำเร็จ')),
      ],
    );
  });

  // ─── LoadTruckDetailEvent ──────────────────────────────────────────────────

  group('LoadTruckDetailEvent', () {
    blocTest<TruckBloc, TruckState>(
      'emits [Loading, TruckDetailLoaded] เมื่อพบรถ',
      build: () {
        when(() => truckRepo.getById('truck-1'))
            .thenAnswer((_) async => _makeTruck(id: 'truck-1'));
        return makeBloc();
      },
      act: (bloc) => bloc.add(const LoadTruckDetailEvent('truck-1')),
      expect: () => [
        isA<TruckLoading>(),
        isA<TruckDetailLoaded>()
            .having((s) => s.truck.truckId, 'truckId', 'truck-1'),
      ],
    );

    blocTest<TruckBloc, TruckState>(
      'emits [Loading, TruckError("ไม่พบข้อมูลรถบรรทุก")] เมื่อ getById คืน null',
      build: () {
        when(() => truckRepo.getById('truck-ghost'))
            .thenAnswer((_) async => null);
        return makeBloc();
      },
      act: (bloc) => bloc.add(const LoadTruckDetailEvent('truck-ghost')),
      expect: () => [
        isA<TruckLoading>(),
        isA<TruckError>()
            .having((s) => s.message, 'message', 'ไม่พบข้อมูลรถบรรทุก'),
      ],
    );

    blocTest<TruckBloc, TruckState>(
      'emits [Loading, TruckError] เมื่อ getById throw',
      build: () {
        when(() => truckRepo.getById(any()))
            .thenThrow(Exception('Firestore error'));
        return makeBloc();
      },
      act: (bloc) => bloc.add(const LoadTruckDetailEvent('truck-1')),
      expect: () => [
        isA<TruckLoading>(),
        isA<TruckError>(),
      ],
    );
  });

  // ─── AddTruckEvent ─────────────────────────────────────────────────────────

  group('AddTruckEvent', () {
    blocTest<TruckBloc, TruckState>(
      'emits [Loading, TruckSaved] เมื่อเพิ่มรถสำเร็จ',
      build: () {
        when(() => truckTypeRepo.getById('tt-6wheel'))
            .thenAnswer((_) async => _kTruckType);
        when(() => truckRepo.save(any())).thenAnswer((_) async {});
        return makeBloc();
      },
      act: (bloc) => bloc.add(const AddTruckEvent(
        contractorId: 'contractor-1',
        truckTypeId: 'tt-6wheel',
        brand: 'อีซูซุ',
        model: 'NQR',
        licensePlate: 'กข 1234 เชียงใหม่',
      )),
      expect: () => [
        isA<TruckLoading>(),
        isA<TruckSaved>(),
      ],
    );

    blocTest<TruckBloc, TruckState>(
      'รถที่บันทึกมี approvalStatus = "รอตรวจสอบ" เสมอ',
      build: () {
        when(() => truckTypeRepo.getById('tt-6wheel'))
            .thenAnswer((_) async => _kTruckType);
        when(() => truckRepo.save(any())).thenAnswer((_) async {});
        return makeBloc();
      },
      act: (bloc) => bloc.add(const AddTruckEvent(
        contractorId: 'contractor-1',
        truckTypeId: 'tt-6wheel',
        brand: 'ฮีโน่',
        model: 'XZU',
        licensePlate: 'คง 5678 เชียงราย',
      )),
      verify: (_) {
        final captured = verify(() => truckRepo.save(captureAny())).captured;
        final truck = captured.first as TruckModel;
        expect(truck.approvalStatus, 'รอตรวจสอบ');
      },
    );

    blocTest<TruckBloc, TruckState>(
      'emits [Loading, TruckError("ประเภทรถไม่ถูกต้อง")] เมื่อ truckType เป็น null',
      build: () {
        when(() => truckTypeRepo.getById('tt-invalid'))
            .thenAnswer((_) async => null);
        return makeBloc();
      },
      act: (bloc) => bloc.add(const AddTruckEvent(
        contractorId: 'contractor-1',
        truckTypeId: 'tt-invalid',
        brand: 'โตโยต้า',
        model: 'Dyna',
        licensePlate: 'งจ 0001 ลำปาง',
      )),
      expect: () => [
        isA<TruckLoading>(),
        isA<TruckError>()
            .having((s) => s.message, 'message', 'ประเภทรถไม่ถูกต้อง'),
      ],
      verify: (_) {
        verifyNever(() => truckRepo.save(any()));
      },
    );

    blocTest<TruckBloc, TruckState>(
      'emits [Loading, TruckError] เมื่อ truckRepo.save throw',
      build: () {
        when(() => truckTypeRepo.getById('tt-6wheel'))
            .thenAnswer((_) async => _kTruckType);
        when(() => truckRepo.save(any()))
            .thenThrow(Exception('Firestore write failed'));
        return makeBloc();
      },
      act: (bloc) => bloc.add(const AddTruckEvent(
        contractorId: 'contractor-1',
        truckTypeId: 'tt-6wheel',
        brand: 'อีซูซุ',
        model: 'NQR',
        licensePlate: 'กข 9999 เชียงใหม่',
      )),
      expect: () => [
        isA<TruckLoading>(),
        isA<TruckError>()
            .having((s) => s.message, 'message', contains('เพิ่มรถบรรทุกไม่สำเร็จ')),
      ],
    );
  });

  // ─── EditTruckEvent ────────────────────────────────────────────────────────

  group('EditTruckEvent', () {
    blocTest<TruckBloc, TruckState>(
      'emits [Loading, TruckSaved] เมื่อแก้ไขรถสำเร็จ',
      build: () {
        when(() => truckTypeRepo.getById('tt-6wheel'))
            .thenAnswer((_) async => _kTruckType);
        when(() => truckRepo.getById('truck-1'))
            .thenAnswer((_) async => _makeTruck(id: 'truck-1'));
        when(() => truckRepo.save(any())).thenAnswer((_) async {});
        return makeBloc();
      },
      act: (bloc) => bloc.add(const EditTruckEvent(
        truckId: 'truck-1',
        truckTypeId: 'tt-6wheel',
        brand: 'อีซูซุ',
        model: 'NQR 2026',
        licensePlate: 'กข 1234 เชียงใหม่',
      )),
      expect: () => [
        isA<TruckLoading>(),
        isA<TruckSaved>(),
      ],
    );

    blocTest<TruckBloc, TruckState>(
      'แก้ field สำคัญ (ทะเบียน) → รีเซ็ต approvalStatus เป็น "รอตรวจสอบ" (UC 3.1.23)',
      build: () {
        when(() => truckTypeRepo.getById('tt-6wheel'))
            .thenAnswer((_) async => _kTruckType);
        when(() => truckRepo.getById('truck-approved'))
            .thenAnswer((_) async => _makeTruck(
                id: 'truck-approved', approvalStatus: 'อนุมัติแล้ว'));
        when(() => truckRepo.save(any())).thenAnswer((_) async {});
        return makeBloc();
      },
      act: (bloc) => bloc.add(const EditTruckEvent(
        truckId: 'truck-approved',
        truckTypeId: 'tt-6wheel',
        brand: 'ฮีโน่',
        model: 'XZU 2026',
        licensePlate: 'คง 5678 เชียงราย', // ทะเบียนเปลี่ยน = field สำคัญ
      )),
      verify: (_) {
        final truck =
            verify(() => truckRepo.save(captureAny())).captured.first
                as TruckModel;
        expect(truck.approvalStatus, 'รอตรวจสอบ');
      },
    );

    blocTest<TruckBloc, TruckState>(
      'แก้เฉพาะ field ไม่สำคัญ (ยี่ห้อ/รุ่น) → คงสถานะเดิม ไม่รีเซ็ต (UC 3.1.23)',
      build: () {
        when(() => truckTypeRepo.getById('tt-6wheel'))
            .thenAnswer((_) async => _kTruckType);
        when(() => truckRepo.getById('truck-approved'))
            .thenAnswer((_) async => _makeTruck(
                id: 'truck-approved', approvalStatus: 'อนุมัติแล้ว'));
        when(() => truckRepo.save(any())).thenAnswer((_) async {});
        return makeBloc();
      },
      act: (bloc) => bloc.add(const EditTruckEvent(
        truckId: 'truck-approved',
        truckTypeId: 'tt-6wheel', // เหมือนเดิม
        brand: 'อีซูซุ ใหม่', // แก้ยี่ห้อ (ไม่สำคัญ)
        model: 'NQR ใหม่',
        licensePlate: 'กข 1234 เชียงใหม่', // ทะเบียนเดิม
      )),
      verify: (_) {
        final truck =
            verify(() => truckRepo.save(captureAny())).captured.first
                as TruckModel;
        expect(truck.approvalStatus, 'อนุมัติแล้ว');
      },
    );

    blocTest<TruckBloc, TruckState>(
      'emits [Loading, TruckError("ประเภทรถไม่ถูกต้อง")] เมื่อ truckType เป็น null',
      build: () {
        when(() => truckTypeRepo.getById('tt-nonexistent'))
            .thenAnswer((_) async => null);
        return makeBloc();
      },
      act: (bloc) => bloc.add(const EditTruckEvent(
        truckId: 'truck-1',
        truckTypeId: 'tt-nonexistent',
        brand: 'โตโยต้า',
        model: 'Dyna',
        licensePlate: 'งจ 0001 ลำปาง',
      )),
      expect: () => [
        isA<TruckLoading>(),
        isA<TruckError>()
            .having((s) => s.message, 'message', 'ประเภทรถไม่ถูกต้อง'),
      ],
    );

    blocTest<TruckBloc, TruckState>(
      'emits [Loading, TruckError] เมื่อ truckRepo.save throw',
      build: () {
        when(() => truckTypeRepo.getById('tt-6wheel'))
            .thenAnswer((_) async => _kTruckType);
        when(() => truckRepo.getById('truck-1'))
            .thenAnswer((_) async => _makeTruck());
        when(() => truckRepo.save(any()))
            .thenThrow(Exception('Firestore error'));
        return makeBloc();
      },
      act: (bloc) => bloc.add(const EditTruckEvent(
        truckId: 'truck-1',
        truckTypeId: 'tt-6wheel',
        brand: 'อีซูซุ',
        model: 'NQR',
        licensePlate: 'กข 1234 เชียงใหม่',
      )),
      expect: () => [
        isA<TruckLoading>(),
        isA<TruckError>()
            .having((s) => s.message, 'message', contains('แก้ไขรถบรรทุกไม่สำเร็จ')),
      ],
    );
  });

  // ─── RemoveTruckEvent ──────────────────────────────────────────────────────

  group('RemoveTruckEvent', () {
    blocTest<TruckBloc, TruckState>(
      'emits [Loading, TruckRemoved] เมื่อลบรถสำเร็จ (ไม่มีงานค้างอยู่)',
      build: () {
        when(() => biddingRepo.hasActiveBidForTruck('truck-1'))
            .thenAnswer((_) async => false);
        when(() => truckRepo.softDelete('truck-1')).thenAnswer((_) async {});
        return makeBloc();
      },
      act: (bloc) => bloc.add(const RemoveTruckEvent('truck-1')),
      expect: () => [
        isA<TruckLoading>(),
        isA<TruckRemoved>(),
      ],
      verify: (_) {
        verify(() => truckRepo.softDelete('truck-1')).called(1);
      },
    );

    blocTest<TruckBloc, TruckState>(
      'emits [Loading, TruckError] เมื่อรถกำลังอยู่ในงาน (hasActiveBid = true)',
      build: () {
        when(() => biddingRepo.hasActiveBidForTruck('truck-busy'))
            .thenAnswer((_) async => true);
        return makeBloc();
      },
      act: (bloc) => bloc.add(const RemoveTruckEvent('truck-busy')),
      expect: () => [
        isA<TruckLoading>(),
        isA<TruckError>()
            .having((s) => s.message, 'message', contains('ไม่สามารถลบรถที่กำลังอยู่ในงาน')),
      ],
      verify: (_) {
        verifyNever(() => truckRepo.softDelete(any()));
      },
    );

    blocTest<TruckBloc, TruckState>(
      'softDelete ไม่ถูกเรียกเมื่อรถมีงานค้างอยู่',
      build: () {
        when(() => biddingRepo.hasActiveBidForTruck(any()))
            .thenAnswer((_) async => true);
        return makeBloc();
      },
      act: (bloc) => bloc.add(const RemoveTruckEvent('truck-in-job')),
      verify: (_) {
        verifyNever(() => truckRepo.softDelete(any()));
      },
    );

    blocTest<TruckBloc, TruckState>(
      'emits [Loading, TruckError] เมื่อ hasActiveBidForTruck throw exception',
      build: () {
        when(() => biddingRepo.hasActiveBidForTruck(any()))
            .thenThrow(Exception('Firestore error'));
        return makeBloc();
      },
      act: (bloc) => bloc.add(const RemoveTruckEvent('truck-1')),
      expect: () => [
        isA<TruckLoading>(),
        isA<TruckError>()
            .having((s) => s.message, 'message', contains('ลบรถบรรทุกไม่สำเร็จ')),
      ],
    );

    blocTest<TruckBloc, TruckState>(
      'emits [Loading, TruckError] เมื่อ softDelete throw exception',
      build: () {
        when(() => biddingRepo.hasActiveBidForTruck(any()))
            .thenAnswer((_) async => false);
        when(() => truckRepo.softDelete(any()))
            .thenThrow(Exception('Permission denied'));
        return makeBloc();
      },
      act: (bloc) => bloc.add(const RemoveTruckEvent('truck-1')),
      expect: () => [
        isA<TruckLoading>(),
        isA<TruckError>()
            .having((s) => s.message, 'message', contains('ลบรถบรรทุกไม่สำเร็จ')),
      ],
    );
  });
}
