import 'package:equatable/equatable.dart';

abstract class RegisterEvent extends Equatable {
  const RegisterEvent();
  @override
  List<Object?> get props => [];
}

class RegisterClientEvent extends RegisterEvent {
  final String phoneNumber;
  final String prefix;
  final String firstName;
  final String lastName;
  final String? aboutMe;
  final String? mainProducts;
  final String? addressDetail;
  final String? province;
  final String? district;
  final String? subdistrict;
  final String? postalCode;
  final String? profileImageUrl;

  const RegisterClientEvent({
    required this.phoneNumber,
    required this.prefix,
    required this.firstName,
    required this.lastName,
    this.aboutMe,
    this.mainProducts,
    this.addressDetail,
    this.province,
    this.district,
    this.subdistrict,
    this.postalCode,
    this.profileImageUrl,
  });

  @override
  List<Object?> get props => [phoneNumber, prefix, firstName, lastName];
}

class RegisterContractorEvent extends RegisterEvent {
  final String phoneNumber;
  final String prefix;
  final String firstName;
  final String lastName;
  final String? aboutMe;
  final String? addressDetail;
  final String? province;
  final String? district;
  final String? subdistrict;
  final String? postalCode;
  final String? profileImageUrl;

  const RegisterContractorEvent({
    required this.phoneNumber,
    required this.prefix,
    required this.firstName,
    required this.lastName,
    this.aboutMe,
    this.addressDetail,
    this.province,
    this.district,
    this.subdistrict,
    this.postalCode,
    this.profileImageUrl,
  });

  @override
  List<Object?> get props => [phoneNumber, firstName, lastName];
}
