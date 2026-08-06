import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_strings.dart';

class PhoneInputField extends StatelessWidget {
  final TextEditingController controller;
  const PhoneInputField({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.phone,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      maxLength: 10,
      decoration: const InputDecoration(
        // ไม่ใส่ labelText เพราะหน้าจอวาด label 'เบอร์โทรศัพท์' ไว้ด้านบนแล้ว
        // (ตาม Mockup: label อยู่นอกกล่อง, ในกล่องเป็น placeholder)
        hintText: '08X-XXX-XXXX',
        counterText: '',
      ),
      validator: (value) {
        if (value == null || value.isEmpty) return AppStrings.phoneRequired;
        if (value.length < 9 || value.length > 10) return AppStrings.invalidPhone;
        return null;
      },
    );
  }
}
