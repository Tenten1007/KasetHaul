import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();
  @override
  List<Object?> get props => [];
}

class SendOtpEvent extends AuthEvent {
  final String phoneNumber;
  // null = login flow (auto-detect role จาก DB หลัง OTP)
  // 'client' | 'contractor' = register flow
  final String? role;
  const SendOtpEvent({required this.phoneNumber, this.role});
  @override
  List<Object?> get props => [phoneNumber, role];
}

class VerifyOtpEvent extends AuthEvent {
  final String smsCode;
  const VerifyOtpEvent({required this.smsCode});
  @override
  List<Object?> get props => [smsCode];
}

class CheckRegistrationEvent extends AuthEvent {
  final String phoneNumber;
  final String role;
  const CheckRegistrationEvent({required this.phoneNumber, required this.role});
  @override
  List<Object?> get props => [phoneNumber, role];
}
