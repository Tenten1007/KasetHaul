import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/repositories/repositories.dart';
import '../../../core/services/firebase_service.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final ClientRepository _clientRepository;
  final ContractorRepository _contractorRepository;

  String? _verificationId;
  String? _pendingRole;
  String? _pendingPhone;

  AuthBloc({
    required ClientRepository clientRepository,
    required ContractorRepository contractorRepository,
  })  : _clientRepository = clientRepository,
        _contractorRepository = contractorRepository,
        super(AuthInitial()) {
    on<SendOtpEvent>(_onSendOtp);
    on<VerifyOtpEvent>(_onVerifyOtp);
    on<CheckRegistrationEvent>(_onCheckRegistration);
  }

  Future<void> _onSendOtp(SendOtpEvent event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    _pendingRole = event.role;
    _pendingPhone = event.phoneNumber;

    final phone = event.phoneNumber.startsWith('0')
        ? '+66${event.phoneNumber.substring(1)}'
        : event.phoneNumber;

    // ใช้ Completer เพื่อให้ handler return ทันทีที่ codeSent/verificationFailed ถูกเรียก
    // ถ้า await verifyPhoneNumber(...) โดยตรง handler จะติด 60 วิ จน timeout
    // ทำให้ VerifyOtpEvent ที่ตามมาถูก queue ไว้และ app แฮงค์
    final completer = Completer<void>();
    String? errorMessage;

    try {
      FirebaseService.auth.verifyPhoneNumber(
        phoneNumber: phone,
        verificationCompleted: (PhoneAuthCredential credential) async {
          await FirebaseService.auth.signInWithCredential(credential);
          if (!completer.isCompleted) completer.complete();
        },
        verificationFailed: (FirebaseAuthException e) {
          errorMessage = 'ส่ง OTP ไม่สำเร็จ: ${e.message}';
          if (!completer.isCompleted) completer.complete();
        },
        codeSent: (String verificationId, int? resendToken) {
          _verificationId = verificationId;
          if (!completer.isCompleted) completer.complete();
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          _verificationId = verificationId;
          if (!completer.isCompleted) completer.complete();
        },
      );

      await completer.future.timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          errorMessage = 'หมดเวลา กรุณาลองใหม่อีกครั้ง';
        },
      );

      if (errorMessage != null) {
        emit(AuthError(message: errorMessage!));
      } else if (_verificationId != null) {
        emit(OtpSent(
          phoneNumber: event.phoneNumber,
          verificationId: _verificationId!,
        ));
      }
    } catch (e) {
      emit(AuthError(message: 'เกิดข้อผิดพลาด กรุณาลองใหม่อีกครั้ง'));
    }
  }

  Future<void> _onVerifyOtp(VerifyOtpEvent event, Emitter<AuthState> emit) async {
    if (_verificationId == null) {
      emit(const AuthError(message: 'รหัส OTP ไม่ถูกต้อง หรือหมดอายุ กรุณาลองใหม่อีกครั้ง'));
      return;
    }
    emit(AuthLoading());

    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: event.smsCode,
      );
      await FirebaseService.auth.signInWithCredential(credential);
      await _resolveRole(_pendingPhone!, emit);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'invalid-verification-code') {
        emit(const AuthError(message: 'รหัส OTP ไม่ถูกต้อง หรือหมดอายุ กรุณาลองใหม่อีกครั้ง'));
      } else {
        emit(AuthError(message: 'เกิดข้อผิดพลาด: ${e.message}'));
      }
    } catch (e) {
      emit(const AuthError(message: 'เกิดข้อผิดพลาด กรุณาลองใหม่อีกครั้ง'));
    }
  }

  // ตรวจสอบ role จาก DB โดย query clients/contractors โดยตรง (ไม่ผ่าน members)
  // เพื่อหลีกเลี่ยง Firestore rule "uid() == memberId" บน members collection
  Future<void> _resolveRole(String phone, Emitter<AuthState> emit) async {
    if (_pendingRole == 'client') {
      final client = await _clientRepository.getByPhone(phone);
      if (client != null) {
        emit(AuthRegistered(role: 'client', userId: client.clientId));
      } else {
        emit(AuthNotRegistered(phoneNumber: phone, role: 'client'));
      }
    } else if (_pendingRole == 'contractor') {
      final contractor = await _contractorRepository.getByPhone(phone);
      if (contractor != null) {
        emit(AuthRegistered(role: 'contractor', userId: contractor.contractorId));
      } else {
        emit(AuthNotRegistered(phoneNumber: phone, role: 'contractor'));
      }
    } else {
      // Login flow: เช็ค client ก่อน แล้วค่อย contractor
      final client = await _clientRepository.getByPhone(phone);
      if (client != null) {
        emit(AuthRegistered(role: 'client', userId: client.clientId));
        return;
      }
      final contractor = await _contractorRepository.getByPhone(phone);
      if (contractor != null) {
        emit(AuthRegistered(role: 'contractor', userId: contractor.contractorId));
        return;
      }
      emit(AuthNotRegistered(phoneNumber: phone, role: null));
    }
  }

  Future<void> _onCheckRegistration(CheckRegistrationEvent event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    _pendingRole = event.role;
    _pendingPhone = event.phoneNumber;
    try {
      await _resolveRole(event.phoneNumber, emit);
    } catch (e) {
      emit(const AuthError(message: 'เกิดข้อผิดพลาด กรุณาลองใหม่อีกครั้ง'));
    }
  }
}
