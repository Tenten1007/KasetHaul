import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/config/app_config.dart';
import '../../../core/repositories/repositories.dart';
import '../bloc/admin_bloc.dart';
import 'admin_home_page.dart';

class AdminLoginPage extends StatefulWidget {
  const AdminLoginPage({super.key});

  @override
  State<AdminLoginPage> createState() => _AdminLoginPageState();
}

class _AdminLoginPageState extends State<AdminLoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AdminBloc(
        truckRepository: TruckRepository(),
        contractorRepository: ContractorRepository(),
        memberRepository: MemberRepository(),
        jobRepository: JobRepository(),
      ),
      child: BlocConsumer<AdminBloc, AdminState>(
        listener: (context, state) {
          if (state is AdminLoginSuccess) {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(
                builder: (_) => AdminHomePage(admin: state.admin),
              ),
              (_) => false,
            );
          } else if (state is AdminError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppConfig.errorColor,
              ),
            );
          }
        },
        builder: (context, state) {
          final loading = state is AdminLoading;
          return Scaffold(
            backgroundColor: Colors.white,
            body: SafeArea(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        const SizedBox(height: 40),
                        // Logo
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [AppConfig.primaryColor, AppConfig.primaryDarkColor],
                            ),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          alignment: Alignment.center,
                          child: const Text('🛡️', style: TextStyle(fontSize: 36)),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'KasetHaul',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: AppConfig.primaryColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Admin Dashboard',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppConfig.textSecondaryColor,
                          ),
                        ),
                        const SizedBox(height: 40),
                        // Username
                        TextFormField(
                          key: const Key('field_admin_username'),
                          controller: _usernameCtrl,
                          decoration: InputDecoration(
                            labelText: 'ชื่อผู้ใช้งาน',
                            hintText: 'username',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            prefixIcon: const Icon(Icons.person_outline),
                          ),
                          validator: (v) {
                            if (v == null || v.isEmpty) {
                              return 'กรุณากรอกชื่อผู้ใช้งาน';
                            }
                            // debug creds ผ่านได้ตอนพัฒนา
                            if (kDebugMode && v == 'admin') return null;
                            if (!RegExp(r'^[a-zA-Z0-9]{6,20}$').hasMatch(v)) {
                              return 'ชื่อผู้ใช้ต้องเป็น a-z A-Z 0-9 ยาว 6-20 ตัว';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        // Password
                        TextFormField(
                          key: const Key('field_admin_password'),
                          controller: _passwordCtrl,
                          obscureText: _obscure,
                          decoration: InputDecoration(
                            labelText: 'รหัสผ่าน',
                            hintText: '••••••••',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscure ? Icons.visibility_off : Icons.visibility,
                              ),
                              onPressed: () => setState(() => _obscure = !_obscure),
                            ),
                          ),
                          validator: (v) {
                            if (v == null || v.isEmpty) {
                              return 'กรุณากรอกรหัสผ่าน';
                            }
                            if (kDebugMode && v == 'admin123') return null;
                            final ok = RegExp(r'[a-z]').hasMatch(v) &&
                                RegExp(r'[A-Z]').hasMatch(v) &&
                                RegExp(r'\d').hasMatch(v) &&
                                RegExp(r'[^A-Za-z0-9]').hasMatch(v) &&
                                v.length >= 8;
                            if (!ok) {
                              return 'รหัสผ่าน ≥8 ตัว มีพิมพ์เล็ก พิมพ์ใหญ่ ตัวเลข อักขระพิเศษ';
                            }
                            return null;
                          },
                        ),
                        if (kDebugMode) ...[
                          const SizedBox(height: 8),
                          GestureDetector(
                            key: const Key('btn_debug_admin_fill'),
                            onTap: () => setState(() {
                              _usernameCtrl.text = 'admin';
                              _passwordCtrl.text = 'admin123';
                            }),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.amber.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.amber.shade300),
                              ),
                              child: const Text('🧪 ทดสอบ: กรอก admin/admin123',
                                  style: TextStyle(fontSize: 12, color: Colors.black87)),
                            ),
                          ),
                        ],
                        const SizedBox(height: 24),
                        // Login button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            key: const Key('btn_admin_login'),
                            onPressed: loading
                                ? null
                                : () {
                                    if (_formKey.currentState!.validate()) {
                                      context.read<AdminBloc>().add(
                                            AdminLoginEvent(
                                              username: _usernameCtrl.text.trim(),
                                              password: _passwordCtrl.text,
                                            ),
                                          );
                                    }
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppConfig.primaryColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: loading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text(
                                    'เข้าสู่ระบบ',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 32),
                        const Text(
                          'KasetHaul Admin v1.0.0\nสงวนสิทธิ์เฉพาะผู้ดูแลระบบ',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            color: AppConfig.textSecondaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
