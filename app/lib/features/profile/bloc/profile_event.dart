import 'dart:io';
import 'package:equatable/equatable.dart';

abstract class ProfileEvent extends Equatable {
  const ProfileEvent();
  @override
  List<Object?> get props => [];
}

class LoadClientProfileEvent extends ProfileEvent {
  final String clientId;
  const LoadClientProfileEvent(this.clientId);
  @override
  List<Object?> get props => [clientId];
}

class LoadContractorProfileEvent extends ProfileEvent {
  final String contractorId;
  const LoadContractorProfileEvent(this.contractorId);
  @override
  List<Object?> get props => [contractorId];
}

class SaveClientProfileEvent extends ProfileEvent {
  final String clientId;
  final String memberId;
  final String? prefix;
  final String firstName;
  final String lastName;
  final String? aboutMe;
  final String? mainProducts;
  final String? addressDetail;
  final String? province;
  final String? district;
  final String? subdistrict;
  final String? postalCode;
  final File? profileImage;
  final String? existingProfileImageUrl;

  const SaveClientProfileEvent({
    required this.clientId,
    required this.memberId,
    this.prefix,
    required this.firstName,
    required this.lastName,
    this.aboutMe,
    this.mainProducts,
    this.addressDetail,
    this.province,
    this.district,
    this.subdistrict,
    this.postalCode,
    this.profileImage,
    this.existingProfileImageUrl,
  });
  @override
  List<Object?> get props => [clientId, memberId, firstName, lastName];
}

class SaveContractorProfileEvent extends ProfileEvent {
  final String contractorId;
  final String memberId;
  final String? prefix;
  final String firstName;
  final String lastName;
  final String? aboutMe;
  final String? addressDetail;
  final String? province;
  final String? district;
  final String? subdistrict;
  final String? postalCode;
  final File? profileImage;
  final String? existingProfileImageUrl;

  const SaveContractorProfileEvent({
    required this.contractorId,
    required this.memberId,
    this.prefix,
    required this.firstName,
    required this.lastName,
    this.aboutMe,
    this.addressDetail,
    this.province,
    this.district,
    this.subdistrict,
    this.postalCode,
    this.profileImage,
    this.existingProfileImageUrl,
  });
  @override
  List<Object?> get props => [contractorId, memberId, firstName, lastName];
}
