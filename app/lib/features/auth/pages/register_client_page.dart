import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/config/app_config.dart';
import '../../../core/repositories/repositories.dart';
import '../../../shared/widgets/cascading_address_widget.dart';
import '../bloc/register_bloc.dart';
import '../bloc/register_event.dart';
import '../bloc/register_state.dart';
import '../bloc/auth_bloc.dart';
import 'register_client_success_page.dart';
import 'otp_verify_page.dart';

class RegisterClientPage extends StatelessWidget {
  final String? phoneNumber;
  final bool phoneVerified;
  const RegisterClientPage({
    super.key,
    this.phoneNumber,
    this.phoneVerified = false,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => RegisterBloc(
        memberRepository: MemberRepository(),
        clientRepository: ClientRepository(),
        contractorRepository: ContractorRepository(),
      ),
      child: _RegisterClientView(
        phoneNumber: phoneNumber,
        phoneVerified: phoneVerified,
      ),
    );
  }
}

class _RegisterClientView extends StatefulWidget {
  final String? phoneNumber;
  final bool phoneVerified;
  const _RegisterClientView({this.phoneNumber, required this.phoneVerified});

  @override
  State<_RegisterClientView> createState() => _RegisterClientViewState();
}

class _RegisterClientViewState extends State<_RegisterClientView> {
  final _formKey = GlobalKey<FormState>();

  final _addressDetailCtrl = TextEditingController();
  final _postalCodeCtrl = TextEditingController();
  late final TextEditingController _phoneCtrl;
  String? _province;
  String? _district;
  String? _subdistrict;

  String _prefix = 'นาย';
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();

  File? _profileImage;
  bool _isUploading = false;

  static const _prefixes = ['นาย', 'นาง', 'นางสาว'];

  @override
  void initState() {
    super.initState();
    _phoneCtrl = TextEditingController(text: widget.phoneNumber ?? '');
  }

  @override
  void dispose() {
    _addressDetailCtrl.dispose();
    _postalCodeCtrl.dispose();
    _phoneCtrl.dispose();
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source, imageQuality: 80);
    if (picked != null && mounted) {
      setState(() => _profileImage = File(picked.path));
    }
  }

  void _showImagePicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('เลือกรูปโปรไฟล์',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                    color: AppConfig.primaryColor.withAlpha(26),
                    shape: BoxShape.circle),
                child: const Icon(Icons.camera_alt,
                    color: AppConfig.primaryColor),
              ),
              title: const Text('ถ่ายรูป'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                    color: AppConfig.primaryColor.withAlpha(26),
                    shape: BoxShape.circle),
                child: const Icon(Icons.photo_library,
                    color: AppConfig.primaryColor),
              ),
              title: const Text('เลือกจากคลัง'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            if (_profileImage != null)
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                      color: AppConfig.errorColor.withAlpha(26),
                      shape: BoxShape.circle),
                  child: const Icon(Icons.delete_outline,
                      color: AppConfig.errorColor),
                ),
                title: const Text('ลบรูป'),
                onTap: () {
                  Navigator.pop(context);
                  setState(() => _profileImage = null);
                },
              ),
          ],
        ),
      ),
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    if (widget.phoneVerified) {
      _register();
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider(
          create: (_) => AuthBloc(
            clientRepository: ClientRepository(),
            contractorRepository: ContractorRepository(),
          ),
          child: OtpVerifyPage(
            phoneNumber: _phoneCtrl.text.trim(),
            role: 'client',
            sendOtpOnStart: true,
            onRegistrationVerified: _register,
          ),
        ),
      ),
    );
  }

  Future<void> _register() async {
    setState(() => _isUploading = true);
    try {
      String? imageUrl;
      if (_profileImage != null) {
        imageUrl = await StorageRepository().uploadFile(
          file: _profileImage!,
          path: 'profiles/${DateTime.now().millisecondsSinceEpoch}.jpg',
        );
      }
      if (mounted) {
        context.read<RegisterBloc>().add(
              RegisterClientEvent(
                phoneNumber: _phoneCtrl.text.trim(),
                prefix: _prefix,
                firstName: _firstNameCtrl.text.trim(),
                lastName: _lastNameCtrl.text.trim(),
                addressDetail: _addressDetailCtrl.text.trim().isEmpty
                    ? null
                    : _addressDetailCtrl.text.trim(),
                province: _province,
                district: _district,
                subdistrict: _subdistrict,
                postalCode: _postalCodeCtrl.text.trim().isEmpty
                    ? null
                    : _postalCodeCtrl.text.trim(),
                profileImageUrl: imageUrl,
              ),
            );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUploading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('อัปโหลดรูปไม่สำเร็จ: $e'),
              backgroundColor: AppConfig.errorColor),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<RegisterBloc, RegisterState>(
      listener: (context, state) {
        if (state is RegisterClientSuccess) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (_) =>
                  RegisterClientSuccessPage(client: state.client),
            ),
            (_) => false,
          );
        } else if (state is RegisterError) {
          setState(() => _isUploading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(state.message),
                backgroundColor: AppConfig.errorColor),
          );
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          titleTextStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF212121)),
          foregroundColor: const Color(0xFF212121),
          title: const Text('ลงทะเบียน - เกษตรกร'),
          elevation: 0,
          surfaceTintColor: Colors.transparent,
        ),
        body: BlocBuilder<RegisterBloc, RegisterState>(
          builder: (context, state) {
            final isLoading = state is RegisterLoading || _isUploading;
            return SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 16),

                      // รูปโปรไฟล์
                      Center(
                        child: Column(
                          children: [
                            GestureDetector(
                              onTap: _showImagePicker,
                              child: Container(
                                width: 100,
                                height: 100,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE8F5E9),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                      color: AppConfig.primaryColor,
                                      width: 3,
                                      style: BorderStyle.solid),
                                ),
                                child: _profileImage != null
                                    ? ClipOval(
                                        child: Image.file(_profileImage!,
                                            fit: BoxFit.cover))
                                    : const Center(
                                        child: Text('📷',
                                            style: TextStyle(fontSize: 40))),
                              ),
                            ),
                            const SizedBox(height: 8),
                            GestureDetector(
                              onTap: _showImagePicker,
                              child: const Text('เพิ่มรูปโปรไฟล์',
                                  style: TextStyle(
                                      fontSize: 14,
                                      color: AppConfig.primaryColor)),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // รายละเอียดที่อยู่ (cascading dropdowns)
                      CascadingAddressWidget(
                        addressDetailCtrl: _addressDetailCtrl,
                        postalCodeCtrl: _postalCodeCtrl,
                        onProvinceChanged: (v) =>
                            setState(() => _province = v.isEmpty ? null : v),
                        onDistrictChanged: (v) =>
                            setState(() => _district = v.isEmpty ? null : v),
                        onSubdistrictChanged: (v) =>
                            setState(() => _subdistrict = v.isEmpty ? null : v),
                      ),
                      const SizedBox(height: 4),

                      // คำนำหน้า
                      _label('คำนำหน้า *'),
                      DropdownButtonFormField<String>(
                        value: _prefix,
                        decoration: _deco('เลือกคำนำหน้า'),
                        items: _prefixes
                            .map((p) =>
                                DropdownMenuItem(value: p, child: Text(p)))
                            .toList(),
                        onChanged: (v) => setState(() => _prefix = v!),
                      ),
                      const SizedBox(height: 16),

                      // ชื่อ
                      _label('ชื่อ *'),
                      TextFormField(
                        controller: _firstNameCtrl,
                        decoration: _deco('ชื่อ'),
                        validator: (v) =>
                            (v == null || v.isEmpty) ? 'กรุณากรอก' : null,
                      ),
                      const SizedBox(height: 16),

                      // นามสกุล
                      _label('นามสกุล *'),
                      TextFormField(
                        controller: _lastNameCtrl,
                        decoration: _deco('นามสกุล'),
                        validator: (v) =>
                            (v == null || v.isEmpty) ? 'กรุณากรอก' : null,
                      ),
                      const SizedBox(height: 16),

                      // เบอร์โทรศัพท์
                      _label('เบอร์โทรศัพท์ *'),
                      TextFormField(
                        controller: _phoneCtrl,
                        readOnly: widget.phoneVerified,
                        decoration: _deco('08X-XXX-XXXX'),
                        keyboardType: TextInputType.phone,
                        validator: (v) =>
                            (v == null || !RegExp(r'^0[0-9]{9}$')
                                    .hasMatch(v.trim()))
                                ? 'กรุณากรอกเบอร์โทรศัพท์ 10 หลัก'
                                : null,
                      ),
                      const SizedBox(height: 24),

                      // หมายเหตุ
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F5E9),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          '💡 หมายเหตุ: เราจะส่งรหัส OTP เพื่อยืนยันเบอร์โทรศัพท์ในขั้นตอนถัดไป',
                          style: TextStyle(
                              fontSize: 13, color: Color(0xFF2E7D32)),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // ปุ่มลงทะเบียน
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: isLoading ? null : _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppConfig.primaryColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                            elevation: 0,
                          ),
                          child: isLoading
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                      color: Colors.white, strokeWidth: 2.5))
                              : const Text('ลงทะเบียน',
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600)),
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text,
            style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF424242))),
      );

  InputDecoration _deco(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFFBDBDBD)),
        filled: true,
        fillColor: const Color(0xFFFAFAFA),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFFE0E0E0))),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFFE0E0E0))),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide:
                const BorderSide(color: AppConfig.primaryColor, width: 2)),
        disabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFFE0E0E0))),
      );
}
