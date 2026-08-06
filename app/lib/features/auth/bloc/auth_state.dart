import 'package:equatable/equatable.dart';

abstract class AuthState extends Equatable {
  const AuthState();
  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class OtpSent extends AuthState {
  final String phoneNumber;
  final String verificationId;
  const OtpSent({required this.phoneNumber, required this.verificationId});
  @override
  List<Object?> get props => [phoneNumber, verificationId];
}

class OtpVerified extends AuthState {
  final String uid;
  final String phoneNumber;
  const OtpVerified({required this.uid, required this.phoneNumber});
  @override
  List<Object?> get props => [uid, phoneNumber];
}

// ยืนยัน OTP แล้ว และมีบัญชีอยู่แล้ว → ไปหน้า home
class AuthRegistered extends AuthState {
  final String role; // 'client' | 'contractor'
  final String userId; // clientId หรือ contractorId
  const AuthRegistered({required this.role, required this.userId});
  @override
  List<Object?> get props => [role, userId];
}

// ยืนยัน OTP แล้ว แต่ยังไม่มีบัญชี → ไปหน้า register
class AuthNotRegistered extends AuthState {
  final String phoneNumber;
  // null = มาจาก login flow (ยังไม่เลือก role)
  // 'client' | 'contractor' = มาจาก register flow
  final String? role;
  const AuthNotRegistered({required this.phoneNumber, this.role});
  @override
  List<Object?> get props => [phoneNumber, role];
}

class AuthError extends AuthState {
  final String message;
  const AuthError({required this.message});
  @override
  List<Object?> get props => [message];
}
