import 'package:flutter/material.dart';
import '../../core/data/thai_address_data.dart';

class CascadingAddressWidget extends StatefulWidget {
  final TextEditingController addressDetailCtrl;
  final TextEditingController postalCodeCtrl;
  final ValueChanged<String>? onProvinceChanged;
  final ValueChanged<String>? onDistrictChanged;
  final ValueChanged<String>? onSubdistrictChanged;
  final String? initialProvince;
  final String? initialDistrict;
  final String? initialSubdistrict;
  final bool isRequired;

  const CascadingAddressWidget({
    super.key,
    required this.addressDetailCtrl,
    required this.postalCodeCtrl,
    this.onProvinceChanged,
    this.onDistrictChanged,
    this.onSubdistrictChanged,
    this.initialProvince,
    this.initialDistrict,
    this.initialSubdistrict,
    this.isRequired = true,
  });

  @override
  State<CascadingAddressWidget> createState() => _CascadingAddressWidgetState();
}

class _CascadingAddressWidgetState extends State<CascadingAddressWidget> {
  String? _province;
  String? _district;
  String? _subdistrict;
  List<String> _districts = [];
  List<List<String>> _subdistricts = [];

  @override
  void initState() {
    super.initState();
    if (widget.initialProvince != null) {
      _province = widget.initialProvince;
      _districts = ThaiAddressData.getDistricts(_province!);
    }
    if (widget.initialDistrict != null && _districts.contains(widget.initialDistrict)) {
      _district = widget.initialDistrict;
      _subdistricts = ThaiAddressData.getSubdistricts(_district!);
    }
    if (widget.initialSubdistrict != null) {
      final match = _subdistricts.where((s) => s[0] == widget.initialSubdistrict);
      if (match.isNotEmpty) _subdistrict = widget.initialSubdistrict;
    }
  }

  void _onProvinceChanged(String? value) {
    setState(() {
      _province = value;
      _district = null;
      _subdistrict = null;
      _districts = value != null ? ThaiAddressData.getDistricts(value) : [];
      _subdistricts = [];
    });
    widget.onProvinceChanged?.call(value ?? '');
    widget.postalCodeCtrl.clear();
  }

  void _onDistrictChanged(String? value) {
    setState(() {
      _district = value;
      _subdistrict = null;
      _subdistricts = value != null ? ThaiAddressData.getSubdistricts(value) : [];
    });
    widget.onDistrictChanged?.call(value ?? '');
    widget.postalCodeCtrl.clear();
  }

  void _onSubdistrictChanged(String? value) {
    setState(() => _subdistrict = value);
    widget.onSubdistrictChanged?.call(value ?? '');
    if (value != null && _district != null) {
      final postal = ThaiAddressData.getPostalCode(_district!, value);
      if (postal != null) {
        widget.postalCodeCtrl.text = postal;
      }
    }
  }

  InputDecoration _deco(String hint) => InputDecoration(
        hintText: hint,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFBDBDBD)),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        isDense: true,
      );

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(text,
            style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF424242))),
      );

  @override
  Widget build(BuildContext context) {
    final star = widget.isRequired ? ' *' : '';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // บ้านเลขที่
        _label('รายละเอียดที่อยู่$star'),
        TextFormField(
          controller: widget.addressDetailCtrl,
          decoration: _deco('บ้านเลขที่ หมู่ ซอย ถนน...'),
          validator: widget.isRequired
              ? (v) => (v == null || v.isEmpty) ? 'กรุณากรอกที่อยู่' : null
              : null,
        ),
        const SizedBox(height: 12),

        // จังหวัด
        _label('จังหวัด$star'),
        DropdownButtonFormField<String>(
          value: _province,
          decoration: _deco('เลือกจังหวัด'),
          isExpanded: true,
          items: ThaiAddressData.provinces
              .map((p) => DropdownMenuItem(value: p, child: Text(p)))
              .toList(),
          onChanged: _onProvinceChanged,
          validator: widget.isRequired
              ? (v) => v == null ? 'กรุณาเลือกจังหวัด' : null
              : null,
        ),
        const SizedBox(height: 12),

        // อำเภอ
        _label('อำเภอ/เขต$star'),
        _districts.isNotEmpty
            ? DropdownButtonFormField<String>(
                value: _district,
                decoration: _deco('เลือกอำเภอ/เขต'),
                isExpanded: true,
                items: _districts
                    .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                    .toList(),
                onChanged: _onDistrictChanged,
                validator: widget.isRequired
                    ? (v) => v == null ? 'กรุณาเลือกอำเภอ' : null
                    : null,
              )
            : TextFormField(
                decoration: _deco(_province == null
                    ? 'กรุณาเลือกจังหวัดก่อน'
                    : 'พิมพ์ชื่ออำเภอ/เขต'),
                enabled: _province != null,
                onChanged: (v) {
                  _district = v.isEmpty ? null : v;
                  widget.onDistrictChanged?.call(v);
                },
                validator: widget.isRequired
                    ? (v) => (v == null || v.isEmpty) ? 'กรุณากรอกอำเภอ' : null
                    : null,
              ),
        const SizedBox(height: 12),

        // ตำบล
        _label('ตำบล/แขวง$star'),
        _subdistricts.isNotEmpty
            ? DropdownButtonFormField<String>(
                value: _subdistrict,
                decoration: _deco('เลือกตำบล/แขวง'),
                isExpanded: true,
                items: _subdistricts
                    .map((s) => DropdownMenuItem(value: s[0], child: Text(s[0])))
                    .toList(),
                onChanged: _onSubdistrictChanged,
                validator: widget.isRequired
                    ? (v) => v == null ? 'กรุณาเลือกตำบล' : null
                    : null,
              )
            : TextFormField(
                decoration: _deco(_district == null
                    ? 'กรุณาเลือกอำเภอก่อน'
                    : 'พิมพ์ชื่อตำบล/แขวง'),
                enabled: _district != null,
                onChanged: (v) {
                  _subdistrict = v.isEmpty ? null : v;
                  widget.onSubdistrictChanged?.call(v);
                },
                validator: widget.isRequired
                    ? (v) => (v == null || v.isEmpty) ? 'กรุณากรอกตำบล' : null
                    : null,
              ),
        const SizedBox(height: 12),

        // รหัสไปรษณีย์
        _label('รหัสไปรษณีย์$star'),
        TextFormField(
          controller: widget.postalCodeCtrl,
          decoration: _deco('รหัสไปรษณีย์ 5 หลัก'),
          keyboardType: TextInputType.number,
          maxLength: 5,
          buildCounter: (_, {required currentLength, required isFocused, maxLength}) => null,
          validator: widget.isRequired
              ? (v) {
                  if (v == null || v.isEmpty) return 'กรุณากรอกรหัสไปรษณีย์';
                  if (v.length != 5) return 'รหัสไปรษณีย์ต้องมี 5 หลัก';
                  return null;
                }
              : null,
        ),
      ],
    );
  }

  String? get province => _province;
  String? get district => _district;
  String? get subdistrict => _subdistrict;
}
