import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/config/app_config.dart';
import '../../../core/constants/app_routes.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';
import 'register_client_page.dart';
import 'register_contractor_page.dart';
import 'role_select_page.dart';

class OtpVerifyPage extends StatefulWidget {
  final String phoneNumber;
  // null = login flow, 'client'/'contractor' = register flow
  final String? role;
  final bool sendOtpOnStart;
  final VoidCallback? onRegistrationVerified;
  const OtpVerifyPage({
    super.key,
    required this.phoneNumber,
    this.role,
    this.sendOtpOnStart = false,
    this.onRegistrationVerified,
  });

  @override
  State<OtpVerifyPage> createState() => _OtpVerifyPageState();
}

class _OtpVerifyPageState extends State<OtpVerifyPage> {
  final _otpControllers = List.generate(6, (_) => TextEditingController());
  final _focusNodes = List.generate(6, (_) => FocusNode());

  static const _totalSeconds = 180;
  static const _maxAttempts = 5;
  static const _lockoutSeconds = 300; // 5 minutes
  int _secondsLeft = _totalSeconds;
  int _attempts = 0;
  int _lockoutSecondsLeft = 0;
  Timer? _timer;
  Timer? _lockoutTimer;

  @override
  void initState() {
    super.initState();
    _startTimer();
    if (widget.sendOtpOnStart) {
      context
          .read<AuthBloc>()
          .add(SendOtpEvent(phoneNumber: widget.phoneNumber, role: widget.role));
    }
  }

  bool get _isLockedOut => _lockoutSecondsLeft > 0;

  @override
  void dispose() {
    _timer?.cancel();
    _lockoutTimer?.cancel();
    for (final c in _otpControllers) { c.dispose(); }
    for (final f in _focusNodes) { f.dispose(); }
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() => _secondsLeft = _totalSeconds);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      if (_secondsLeft <= 0) {
        _timer?.cancel();
      } else {
        setState(() => _secondsLeft--);
      }
    });
  }

  void _startLockout() {
    _lockoutTimer?.cancel();
    setState(() => _lockoutSecondsLeft = _lockoutSeconds);
    _lockoutTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      if (_lockoutSecondsLeft <= 1) {
        _lockoutTimer?.cancel();
        setState(() {
          _lockoutSecondsLeft = 0;
          _attempts = 0;
        });
      } else {
        setState(() => _lockoutSecondsLeft--);
      }
    });
  }

  String get _otpCode => _otpControllers.map((c) => c.text).join();

  String get _timerText {
    final m = _secondsLeft ~/ 60;
    final s = _secondsLeft % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  String get _lockoutText {
    final m = _lockoutSecondsLeft ~/ 60;
    final s = _lockoutSecondsLeft % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  void _fillTestOtp() {
    if (_isLockedOut) return;
    const code = '123456';
    for (var i = 0; i < 6; i++) {
      _otpControllers[i].text = code[i];
    }
    context.read<AuthBloc>().add(const VerifyOtpEvent(smsCode: code));
  }

  void _resend() {
    if (_isLockedOut) return;
    setState(() => _attempts = 0);
    context
        .read<AuthBloc>()
        .add(SendOtpEvent(phoneNumber: widget.phoneNumber, role: widget.role));
    _startTimer();
  }

  void _submitOtp() {
    if (_isLockedOut || _otpCode.length != 6) return;
    context.read<AuthBloc>().add(VerifyOtpEvent(smsCode: _otpCode));
  }

  void _onChanged(int index, String value) {
    if (_isLockedOut) return;
    if (value.length == 1 && index < 5) {
      _focusNodes[index + 1].requestFocus();
    } else if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
    if (_otpCode.length == 6) {
      _submitOtp();
    }
  }

  void _onAuthError() {
    setState(() => _attempts++);
    for (final c in _otpControllers) { c.clear(); }
    _focusNodes[0].requestFocus();
    if (_attempts >= _maxAttempts) {
      _startLockout();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'กรอกรหัสผิดครบ $_maxAttempts ครั้ง กรุณารอ ${_lockoutSeconds ~/ 60} นาที'),
          backgroundColor: AppConfig.errorColor,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthRegistered) {
          final route = state.role == 'client'
              ? AppRoutes.clientHome
              : AppRoutes.contractorHome;
          Navigator.of(context).pushNamedAndRemoveUntil(
              route, (_) => false, arguments: state.userId);
        } else if (state is AuthNotRegistered) {
          if (widget.onRegistrationVerified != null) {
            Navigator.of(context).pop();
            widget.onRegistrationVerified!();
            return;
          }
          if (state.role == 'client') {
            Navigator.of(context).push(MaterialPageRoute(
              builder: (_) =>
                  RegisterClientPage(
                    phoneNumber: state.phoneNumber,
                    phoneVerified: true,
                  ),
            ));
          } else if (state.role == 'contractor') {
            Navigator.of(context).push(MaterialPageRoute(
              builder: (_) =>
                  RegisterContractorPage(
                    phoneNumber: state.phoneNumber,
                    phoneVerified: true,
                  ),
            ));
          } else {
            // Login flow: เบอร์ยืนยัน OTP แล้วแต่ยังไม่มีบัญชี
            // → แจ้ง + พาไปหน้าเลือกประเภทเพื่อลงทะเบียน (ส่งเบอร์ที่ยืนยันแล้วไปด้วย
            //   register page จะข้ามขั้นกรอกเบอร์/OTP)
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content:
                    Text('เบอร์นี้ยังไม่มีบัญชี — พาไปลงทะเบียนให้เลย'),
                backgroundColor: AppConfig.primaryColor,
              ),
            );
            Navigator.of(context).pushReplacement(MaterialPageRoute(
              builder: (_) => RolePickPage(verifiedPhone: state.phoneNumber),
            ));
          }
        } else if (state is AuthError) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(state.message)));
          _onAuthError();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          titleTextStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF212121)),
          elevation: 0,
          foregroundColor: const Color(0xFF212121),
          title: const Text('ยืนยัน OTP'),
          centerTitle: true,
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                const SizedBox(height: 40),
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: widget.role == 'contractor'
                        ? const Color(0xFFFFF3E0)
                        : const Color(0xFFE8F5E9),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Text('📱', style: TextStyle(fontSize: 36)),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'ยืนยันเบอร์โทรศัพท์',
                  style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF212121)),
                ),
                const SizedBox(height: 8),
                Text.rich(
                  TextSpan(
                    text: 'เราได้ส่งรหัส OTP 6 หลักไปที่\n',
                    style: const TextStyle(
                        color: Color(0xFF757575), fontSize: 14),
                    children: [
                      TextSpan(
                        text: widget.phoneNumber,
                        style: const TextStyle(
                            color: Color(0xFF212121),
                            fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                // Lockout banner
                if (_isLockedOut) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFEBEE),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppConfig.errorColor),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.lock_outline,
                            color: AppConfig.errorColor, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          'ถูกล็อคชั่วคราว กรุณารอ $_lockoutText',
                          style: const TextStyle(
                              color: AppConfig.errorColor,
                              fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(
                    6,
                    (i) => _OtpBox(
                      controller: _otpControllers[i],
                      focusNode: _focusNodes[i],
                      onChanged: (v) => _onChanged(i, v),
                      enabled: !_isLockedOut,
                    ),
                  ),
                ),
                if (!_isLockedOut && _attempts > 0) ...[
                  const SizedBox(height: 8),
                  Text(
                    'กรอกผิด $_attempts/$_maxAttempts ครั้ง',
                    style: const TextStyle(
                        fontSize: 12, color: AppConfig.errorColor),
                  ),
                ],
                if (kDebugMode) ...[
                  const SizedBox(height: 12),
                  GestureDetector(
                    key: const Key('btn_fill_test_otp'),
                    onTap: _fillTestOtp,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade100,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.amber.shade400),
                      ),
                      child: const Text('🧪 ทดสอบ: กรอก 123456',
                          style:
                              TextStyle(fontSize: 12, color: Colors.black87)),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                Text.rich(
                  TextSpan(
                    text: 'รหัสจะหมดอายุใน ',
                    style: const TextStyle(
                        color: Color(0xFF757575), fontSize: 14),
                    children: [
                      TextSpan(
                        text: _secondsLeft > 0 ? _timerText : 'หมดอายุแล้ว',
                        style: const TextStyle(
                          color: Color(0xFFF44336),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                BlocBuilder<AuthBloc, AuthState>(
                  builder: (context, state) {
                    final loading = state is AuthLoading;
                    return SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: loading || _isLockedOut
                            ? null
                            : () {
                                if (_otpCode.length == 6) {
                                  _submitOtp();
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: widget.role == 'contractor'
                              ? AppConfig.secondaryColor
                              : AppConfig.primaryColor,
                          foregroundColor: Colors.white,
                          padding:
                              const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                        child: loading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2))
                            : const Text('ยืนยัน',
                                style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600)),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 24),
                Text.rich(
                  TextSpan(
                    text: 'ไม่ได้รับรหัส? ',
                    style: const TextStyle(
                        color: Color(0xFF757575), fontSize: 14),
                    children: [
                      WidgetSpan(
                        alignment: PlaceholderAlignment.middle,
                        child: GestureDetector(
                          onTap: _secondsLeft == 0 ? _resend : null,
                          child: Text(
                            'ส่งอีกครั้ง',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: _secondsLeft == 0
                                  ? (widget.role == 'contractor'
                                      ? AppConfig.secondaryColor
                                      : AppConfig.primaryColor)
                                  : const Color(0xFFBDBDBD),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OtpBox extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final bool enabled;

  const _OtpBox({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 46,
      height: 56,
      child: TextFormField(
        controller: controller,
        focusNode: focusNode,
        enabled: enabled,
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        maxLength: 1,
        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        decoration: InputDecoration(
          counterText: '',
          contentPadding: EdgeInsets.zero,
          filled: true,
          fillColor: enabled ? AppConfig.surfaceColor : const Color(0xFFEEEEEE),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
          ),
          disabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFEEEEEE)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide:
                const BorderSide(color: AppConfig.primaryColor, width: 2),
          ),
        ),
        onChanged: onChanged,
      ),
    );
  }
}
