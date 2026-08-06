import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/config/app_config.dart';
import '../../../core/repositories/repositories.dart';
import '../bloc/truck_bloc.dart';
import '../bloc/truck_event.dart';
import '../bloc/truck_state.dart';
import '../../../models/models.dart';

class EditTruckPage extends StatelessWidget {
  final TruckModel truck;
  const EditTruckPage({super.key, required this.truck});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => TruckBloc(
        truckRepository: TruckRepository(),
        truckTypeRepository: TruckTypeRepository(),
        storageRepository: StorageRepository(),
      )..add(LoadTruckTypesEvent()),
      child: _EditTruckView(truck: truck),
    );
  }
}

class _EditTruckView extends StatefulWidget {
  final TruckModel truck;
  const _EditTruckView({required this.truck});

  @override
  State<_EditTruckView> createState() => _EditTruckViewState();
}

class _EditTruckViewState extends State<_EditTruckView> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _brandCtrl;
  late final TextEditingController _modelCtrl;
  late final TextEditingController _licensePlateCtrl;
  late final TextEditingController _provinceCtrl;
  late final TextEditingController _capacityCtrl;
  late final TextEditingController _featuresCtrl;

  TruckTypeModel? _selectedTruckType;
  List<TruckTypeModel> _truckTypes = [];

  File? _registrationDoc;
  File? _insuranceDoc;
  File? _truckPhoto;

  @override
  void initState() {
    super.initState();
    _brandCtrl = TextEditingController(text: widget.truck.brand);
    _modelCtrl = TextEditingController(text: widget.truck.model);
    _licensePlateCtrl = TextEditingController(text: widget.truck.licensePlate);
    _provinceCtrl = TextEditingController(text: widget.truck.registeredProvince ?? '');
    _capacityCtrl = TextEditingController(
        text: widget.truck.capacity != null ? widget.truck.capacity.toString() : '');
    _featuresCtrl = TextEditingController(text: widget.truck.features ?? '');
    _selectedTruckType = widget.truck.truckType;
  }

  @override
  void dispose() {
    _brandCtrl.dispose();
    _modelCtrl.dispose();
    _licensePlateCtrl.dispose();
    _provinceCtrl.dispose();
    _capacityCtrl.dispose();
    _featuresCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickFile(String type) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked == null) return;
    setState(() {
      final file = File(picked.path);
      if (type == 'registration') _registrationDoc = file;
      if (type == 'insurance') _insuranceDoc = file;
      if (type == 'photo') _truckPhoto = file;
    });
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedTruckType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณาเลือกประเภทรถบรรทุก')),
      );
      return;
    }
    context.read<TruckBloc>().add(EditTruckEvent(
          truckId: widget.truck.truckId,
          truckTypeId: _selectedTruckType!.truckTypeId,
          brand: _brandCtrl.text.trim(),
          model: _modelCtrl.text.trim(),
          licensePlate: _licensePlateCtrl.text.trim(),
          registeredProvince:
              _provinceCtrl.text.trim().isEmpty ? null : _provinceCtrl.text.trim(),
          capacity: _capacityCtrl.text.trim().isEmpty
              ? null
              : int.tryParse(_capacityCtrl.text.trim()),
          features:
              _featuresCtrl.text.trim().isEmpty ? null : _featuresCtrl.text.trim(),
          registrationDoc: _registrationDoc,
          insuranceDoc: _insuranceDoc,
          truckPhoto: _truckPhoto,
          existingRegistrationDocUrl: widget.truck.registrationDocUrl,
          existingInsuranceDocUrl: widget.truck.insuranceDocUrl,
          existingTruckPhotoUrl: widget.truck.truckPhotosUrl,
        ));
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<TruckBloc, TruckState>(
      listener: (context, state) {
        if (state is TruckTypesLoaded) {
          setState(() {
            _truckTypes = state.truckTypes;
            _selectedTruckType = _truckTypes.firstWhere(
              (t) => t.truckTypeId == widget.truck.truckType.truckTypeId,
              orElse: () => state.truckTypes.first,
            );
          });
        } else if (state is TruckSaved) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.statusReset
                  ? 'แก้ไขรถบรรทุกสำเร็จ! สถานะถูกรีเซ็ตเป็น "รอตรวจสอบ"'
                  : 'แก้ไขรถบรรทุกสำเร็จ!'),
              backgroundColor: const Color(0xFF4CAF50),
            ),
          );
          Navigator.pop(context, true);
        } else if (state is TruckError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message), backgroundColor: AppConfig.errorColor),
          );
        }
      },
      child: Scaffold(
        backgroundColor: AppConfig.surfaceColor,
        appBar: AppBar(
          backgroundColor: AppConfig.primaryColor,
          foregroundColor: Colors.white,
          title: const Text('แก้ไขข้อมูลรถ'),
          elevation: 0,
        ),
        body: BlocBuilder<TruckBloc, TruckState>(
          builder: (context, state) {
            final isLoading = state is TruckLoading;
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SectionCard(
                      title: 'ข้อมูลรถบรรทุก',
                      children: [
                        _label('ประเภทรถบรรทุก *'),
                        DropdownButtonFormField<TruckTypeModel>(
                          value: _selectedTruckType,
                          decoration: _inputDecor('เลือกประเภทรถ'),
                          items: _truckTypes
                              .map((t) => DropdownMenuItem(value: t, child: Text(t.typeName)))
                              .toList(),
                          onChanged: (v) => setState(() => _selectedTruckType = v),
                          validator: (v) => v == null ? 'กรุณาเลือกประเภทรถ' : null,
                        ),
                        const SizedBox(height: 12),
                        _label('ยี่ห้อรถ *'),
                        TextFormField(
                          controller: _brandCtrl,
                          decoration: _inputDecor('เช่น Isuzu, Hino'),
                          validator: (v) =>
                              v == null || v.trim().isEmpty ? 'กรุณากรอกยี่ห้อรถ' : null,
                        ),
                        const SizedBox(height: 12),
                        _label('รุ่นรถ *'),
                        TextFormField(
                          controller: _modelCtrl,
                          decoration: _inputDecor('เช่น FRR, FL'),
                          validator: (v) =>
                              v == null || v.trim().isEmpty ? 'กรุณากรอกรุ่นรถ' : null,
                        ),
                        const SizedBox(height: 12),
                        _label('ป้ายทะเบียน *'),
                        TextFormField(
                          controller: _licensePlateCtrl,
                          decoration: _inputDecor('เช่น กข-1234'),
                          validator: (v) =>
                              v == null || v.trim().isEmpty ? 'กรุณากรอกป้ายทะเบียน' : null,
                        ),
                        const SizedBox(height: 12),
                        _label('จังหวัดที่จดทะเบียน'),
                        TextFormField(
                          controller: _provinceCtrl,
                          decoration: _inputDecor('เช่น เชียงใหม่'),
                        ),
                        const SizedBox(height: 12),
                        _label('น้ำหนักบรรทุกสูงสุด (กก.)'),
                        TextFormField(
                          controller: _capacityCtrl,
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          decoration: _inputDecor('เช่น 5000'),
                        ),
                        const SizedBox(height: 12),
                        _label('คุณสมบัติเสริม'),
                        TextFormField(
                          controller: _featuresCtrl,
                          maxLines: 2,
                          decoration: _inputDecor('เช่น มีตู้แช่เย็น, มีผ้าใบกันฝน'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _SectionCard(
                      title: 'อัพเดตเอกสาร (ไม่บังคับ)',
                      children: [
                        _FilePicker(
                          label: 'สำเนาทะเบียนรถ',
                          file: _registrationDoc,
                          hasExisting: widget.truck.registrationDocUrl != null,
                          onPick: () => _pickFile('registration'),
                        ),
                        const SizedBox(height: 12),
                        _FilePicker(
                          label: 'กรมธรรม์ประกันภัยรถ',
                          file: _insuranceDoc,
                          hasExisting: widget.truck.insuranceDocUrl != null,
                          onPick: () => _pickFile('insurance'),
                        ),
                        const SizedBox(height: 12),
                        _FilePicker(
                          label: 'รูปถ่ายรถบรรทุก',
                          file: _truckPhoto,
                          hasExisting: widget.truck.truckPhotosUrl != null,
                          onPick: () => _pickFile('photo'),
                          isPhoto: true,
                          existingUrl: widget.truck.truckPhotosUrl,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5E9),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppConfig.primaryColor),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.info_outline, color: AppConfig.primaryColor, size: 20),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'การแก้ไขข้อมูลสำคัญจะรีเซ็ตสถานะรถเป็น "รอตรวจสอบ" อีกครั้ง',
                              style: TextStyle(fontSize: 13, color: Color(0xFF5D4037)),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppConfig.primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                        onPressed: isLoading ? null : _submit,
                        child: isLoading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : const Text('บันทึกการแก้ไข',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(text,
            style: const TextStyle(
                fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF424242))),
      );

  InputDecoration _inputDecor(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFFBDBDBD)),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFFE0E0E0))),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFFE0E0E0))),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppConfig.primaryColor, width: 2)),
      );
}

class _SectionCard extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _SectionCard({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Color(0x1A000000), blurRadius: 8, offset: Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const Divider(height: 20),
          ...children,
        ],
      ),
    );
  }
}

class _FilePicker extends StatelessWidget {
  final String label;
  final File? file;
  final bool hasExisting;
  final VoidCallback onPick;
  final bool isPhoto;
  final String? existingUrl;

  const _FilePicker({
    required this.label,
    this.file,
    required this.hasExisting,
    required this.onPick,
    this.isPhoto = false,
    this.existingUrl,
  });

  @override
  Widget build(BuildContext context) {
    final hasFile = file != null;
    return GestureDetector(
      onTap: onPick,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppConfig.surfaceColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: hasFile
                ? AppConfig.primaryColor
                : hasExisting
                    ? const Color(0xFF4CAF50)
                    : const Color(0xFFE0E0E0),
            width: hasFile ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: hasFile
                    ? const Color(0xFFE8F5E9)
                    : hasExisting
                        ? const Color(0xFFE8F5E9)
                        : const Color(0xFFEEEEEE),
                borderRadius: BorderRadius.circular(8),
              ),
              child: hasFile && isPhoto
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(file!, fit: BoxFit.cover),
                    )
                  : hasExisting && isPhoto && existingUrl != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(existingUrl!, fit: BoxFit.cover),
                        )
                      : Icon(
                          hasFile
                              ? Icons.upload_file
                              : hasExisting
                                  ? Icons.check_circle
                                  : Icons.upload_file,
                          color: hasFile
                              ? AppConfig.primaryColor
                              : hasExisting
                                  ? const Color(0xFF4CAF50)
                                  : const Color(0xFF9E9E9E),
                        ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                  Text(
                    hasFile
                        ? 'เลือกไฟล์ใหม่แล้ว'
                        : hasExisting
                            ? 'มีเอกสารอยู่แล้ว (แตะเพื่อเปลี่ยน)'
                            : 'แตะเพื่อเลือกไฟล์',
                    style: TextStyle(
                      fontSize: 12,
                      color: hasFile
                          ? AppConfig.primaryColor
                          : hasExisting
                              ? const Color(0xFF4CAF50)
                              : const Color(0xFF9E9E9E),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Color(0xFFBDBDBD)),
          ],
        ),
      ),
    );
  }
}


