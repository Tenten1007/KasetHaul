import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/config/app_config.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/repositories/repositories.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';
import '../widgets/phone_input_field.dart';
import 'otp_verify_page.dart';
import  'role_select_page.dart';

class PhoneInputPage extends StatelessWidget {
  // null = login flow (auto-detect role จาก DB หลัง OTP)
  // 'client' | 'contractor' = register flow
  final String? role;
  const PhoneInputPage({super.key, this.role});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AuthBloc(
        clientRepository: ClientRepository(),
        contractorRepository: ContractorRepository(),
      ),
      child: _PhoneInputView(role: role),
    );
  }
}

class _PhoneInputView extends StatefulWidget {
  final String? role;
  const _PhoneInputView({required this.role});

  @override
  State<_PhoneInputView> createState() => _PhoneInputViewState();
}

class _PhoneInputViewState extends State<_PhoneInputView> {
  final _phoneController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool get _isLoginFlow => widget.role == null;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isClient = widget.role == 'client';
    final themeData = isClient || _isLoginFlow
        ? AppTheme.clientTheme
        : AppTheme.contractorTheme;

    return Theme(
      data: themeData,
      child: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is OtpSent) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => BlocProvider.value(
                  value: context.read<AuthBloc>(),
                  child: OtpVerifyPage(
                    phoneNumber: state.phoneNumber,
                    role: widget.role,
                  ),
                ),
              ),
            );
          } else if (state is AuthError) {
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text(state.message)));
          }
        },
        child: Scaffold(
          appBar: AppBar(
            title: Text(_isLoginFlow
                ? 'เข้าสู่ระบบ'
                : (isClient ? 'ลงทะเบียน - เกษตรกร' : 'ลงทะเบียน - ผู้รับจ้าง')),
            centerTitle: true,
            elevation: 0,
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_isLoginFlow) ...[
                      const SizedBox(height: 16),
                      // ไอคอนรถบรรทุกพร้อมพื้นหลังตาม Mockup
                      Center(
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppConfig.primaryColor,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Text('🚛', style: TextStyle(fontSize: 32)),
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      // ข้อความต้อนรับ
                      const Center(
                        child: Text(
                          'ยินดีต้อนรับกลับ',
                          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Center(
                        child: Text(
                          _isLoginFlow
                              ? 'เข้าสู่ระบบด้วยเบอร์โทรศัพท์'
                              : 'กรอกเบอร์โทรศัพท์เพื่อเริ่มการลงทะเบียน',
                          style: TextStyle(color: AppConfig.textSecondaryColor, fontSize: 14),
                        ),
                      ),
                      const SizedBox(height: 40),
                    ],

                    // ฟอร์มกรอกเบอร์โทรศัพท์
                    const Text(
                      'เบอร์โทรศัพท์',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 8),
                    PhoneInputField(controller: _phoneController),
                    const SizedBox(height: 8),
                    Text(
                      'เราจะส่งรหัส OTP ไปยังเบอร์โทรศัพท์ของคุณ',
                      style: TextStyle(color: AppConfig.textSecondaryColor, fontSize: 12),
                    ),
                    const SizedBox(height: 24),

                    if (kDebugMode) ...[
                      _DebugAccountPicker(
                        onSelect: (phone) =>
                            setState(() => _phoneController.text = phone),
                      ),
                      const SizedBox(height: 24),
                    ],

                    BlocBuilder<AuthBloc, AuthState>(
                      builder: (context, state) {
                        return ElevatedButton(
                          key: const Key('btn_send_otp'),
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size.fromHeight(48),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            )
                          ),
                          onPressed: state is AuthLoading
                              ? null
                              : () {
                                  if (_formKey.currentState!.validate()) {
                                    context.read<AuthBloc>().add(SendOtpEvent(
                                          phoneNumber:
                                              _phoneController.text.trim(),
                                          role: widget.role,
                                        ));
                                  }
                                },
                          child: state is AuthLoading
                              ? const CircularProgressIndicator(color: Colors.white)
                              : const Text('ขอรหัส OTP', style: TextStyle(fontSize: 16)),
                        );
                      },
                    ),

                    if (_isLoginFlow) ...[
                      const SizedBox(height: 32),
                      Row(
                        children: [
                          const Expanded(child: Divider()),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text('หรือ', style: TextStyle(color: AppConfig.textSecondaryColor)),
                          ),
                          const Expanded(child: Divider()),
                        ],
                      ),
                      const SizedBox(height: 32),
Center(
  child: RichText(
    text: TextSpan(
      style: TextStyle(
        fontSize: 14,
        color: AppConfig.textSecondaryColor,
        fontFamily: 'Prompt', // Ensure consistent font
      ),
      children: [
        const TextSpan(
          text: 'ยังไม่มีบัญชี? ',
        ),
        TextSpan(
          text: 'ลงทะเบียน',
          style: const TextStyle(
            color: AppConfig.primaryColor,
            fontWeight: FontWeight.bold,
          ),
          recognizer: TapGestureRecognizer()
            ..onTap = () => Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const RolePickPage()),
                ),
        ),
      ],
    ),
  )
),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DebugAccountPicker extends StatelessWidget {
  final ValueChanged<String> onSelect;
  const _DebugAccountPicker({required this.onSelect});

  static const _accounts = [
    ('0891234567', 'เบอร์ 1 (contractor)'),
    ('0894561232', 'เบอร์ 2 (client)'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '🧪 ทดสอบ — กด OTP: 123456',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black87),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              for (final (phone, label) in _accounts) ...[
                Expanded(
                  child: GestureDetector(
                    key: Key(phone == '0891234567' ? 'debug_pick_contractor' : 'debug_pick_client'),
                    onTap: () => onSelect(phone),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.amber.shade400),
                      ),
                      child: Column(
                        children: [
                          Text(label,
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.black87)),
                          Text(phone,
                              style: const TextStyle(fontSize: 11, color: Colors.black54)),
                        ],
                      ),
                    ),
                  ),
                ),
                if (phone != _accounts.last.$1) const SizedBox(width: 8),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
