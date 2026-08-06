import 'dart:io';
import 'package:equatable/equatable.dart';

abstract class TruckEvent extends Equatable {
  const TruckEvent();
  @override
  List<Object?> get props => [];
}

class LoadTrucksEvent extends TruckEvent {
  final String contractorId;
  const LoadTrucksEvent(this.contractorId);
  @override
  List<Object?> get props => [contractorId];
}

class LoadTruckDetailEvent extends TruckEvent {
  final String truckId;
  const LoadTruckDetailEvent(this.truckId);
  @override
  List<Object?> get props => [truckId];
}

class AddTruckEvent extends TruckEvent {
  final String contractorId;
  final String truckTypeId;
  final String brand;
  final String model;
  final String licensePlate;
  final String? registeredProvince;
  final int? capacity;
  final String? features;
  final File? registrationDoc;
  final File? insuranceDoc;
  final File? truckPhoto;

  const AddTruckEvent({
    required this.contractorId,
    required this.truckTypeId,
    required this.brand,
    required this.model,
    required this.licensePlate,
    this.registeredProvince,
    this.capacity,
    this.features,
    this.registrationDoc,
    this.insuranceDoc,
    this.truckPhoto,
  });
  @override
  List<Object?> get props => [contractorId, brand, model, licensePlate];
}

class EditTruckEvent extends TruckEvent {
  final String truckId;
  final String truckTypeId;
  final String brand;
  final String model;
  final String licensePlate;
  final String? registeredProvince;
  final int? capacity;
  final String? features;
  final File? registrationDoc;
  final File? insuranceDoc;
  final File? truckPhoto;
  final String? existingRegistrationDocUrl;
  final String? existingInsuranceDocUrl;
  final String? existingTruckPhotoUrl;

  const EditTruckEvent({
    required this.truckId,
    required this.truckTypeId,
    required this.brand,
    required this.model,
    required this.licensePlate,
    this.registeredProvince,
    this.capacity,
    this.features,
    this.registrationDoc,
    this.insuranceDoc,
    this.truckPhoto,
    this.existingRegistrationDocUrl,
    this.existingInsuranceDocUrl,
    this.existingTruckPhotoUrl,
  });
  @override
  List<Object?> get props => [truckId, brand, model, licensePlate];
}

class RemoveTruckEvent extends TruckEvent {
  final String truckId;
  const RemoveTruckEvent(this.truckId);
  @override
  List<Object?> get props => [truckId];
}

class LoadTruckTypesEvent extends TruckEvent {}
