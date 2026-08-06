import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/config/app_config.dart';
import '../../../core/repositories/repositories.dart';
import '../../../models/models.dart';
import '../bloc/profile_bloc.dart';
import '../bloc/profile_event.dart';
import '../bloc/profile_state.dart';
import '../../truck/bloc/truck_bloc.dart';
import '../../truck/bloc/truck_event.dart';
import '../../truck/bloc/truck_state.dart';
import '../../../shared/widgets/stats_grid_widget.dart';
import '../../../shared/widgets/recent_reviews_section.dart';
import '../../truck/pages/truck_list_page.dart';
import '../../review/pages/contractor_reviews_page.dart';
import 'verify_identity_page.dart';
import 'settings_page.dart';

class ContractorProfilePage extends StatelessWidget {
  final String contractorId;
  // readOnly = เปิดดูโปรไฟล์ผู้รับจ้างคนอื่น (เช่น client ดูจากข้อเสนอ) — ซ่อนปุ่มแก้ไข/ตั้งค่า
  final bool readOnly;
  const ContractorProfilePage({
    super.key,
    required this.contractorId,
    this.readOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => ProfileBloc(
            memberRepository: MemberRepository(),
            clientRepository: ClientRepository(),
            contractorRepository: ContractorRepository(),
            storageRepository: StorageRepository(),
          )..add(LoadContractorProfileEvent(contractorId)),
        ),
        BlocProvider(
          create: (_) => TruckBloc(
            truckRepository: TruckRepository(),
            truckTypeRepository: TruckTypeRepository(),
            storageRepository: StorageRepository(),
          )..add(LoadTrucksEvent(contractorId)),
        ),
      ],
      child: _ContractorProfileView(contractorId: contractorId, readOnly: readOnly),
    );
  }
}

class _ContractorProfileView extends StatefulWidget {
  final String contractorId;
  final bool readOnly;
  const _ContractorProfileView({required this.contractorId, this.readOnly = false});

  @override
  State<_ContractorProfileView> createState() => _ContractorProfileViewState();
}

class _ContractorProfileViewState extends State<_ContractorProfileView> {
  bool _isEditing = false;
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _firstNameCtrl;
  late TextEditingController _lastNameCtrl;
  late TextEditingController _aboutMeCtrl;
  late TextEditingController _addressCtrl;
  late TextEditingController _provinceCtrl;
  late TextEditingController _districtCtrl;
  late TextEditingController _subdistrictCtrl;
  late TextEditingController _postalCodeCtrl;
  String? _selectedPrefix;
  File? _newProfileImage;

  static const _prefixes = ['นาย', 'นาง', 'นางสาว'];

  @override
  void initState() {
    super.initState();
    _firstNameCtrl = TextEditingController();
    _lastNameCtrl = TextEditingController();
    _aboutMeCtrl = TextEditingController();
    _addressCtrl = TextEditingController();
    _provinceCtrl = TextEditingController();
    _districtCtrl = TextEditingController();
    _subdistrictCtrl = TextEditingController();
    _postalCodeCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _aboutMeCtrl.dispose();
    _addressCtrl.dispose();
    _provinceCtrl.dispose();
    _districtCtrl.dispose();
    _subdistrictCtrl.dispose();
    _postalCodeCtrl.dispose();
    super.dispose();
  }

  void _fillForm(MemberModel member) {
    _firstNameCtrl.text = member.firstName;
    _lastNameCtrl.text = member.lastName;
    _aboutMeCtrl.text = member.aboutMe ?? '';
    _addressCtrl.text = member.addressDetail ?? '';
    _provinceCtrl.text = member.province ?? '';
    _districtCtrl.text = member.district ?? '';
    _subdistrictCtrl.text = member.subdistrict ?? '';
    _postalCodeCtrl.text = member.postalCode ?? '';
    _selectedPrefix = member.prefix;
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked != null) setState(() => _newProfileImage = File(picked.path));
  }

  void _save(ContractorModel contractor) {
    if (!_formKey.currentState!.validate()) return;
    context.read<ProfileBloc>().add(SaveContractorProfileEvent(
          contractorId: widget.contractorId,
          memberId: contractor.member.memberId,
          prefix: _selectedPrefix,
          firstName: _firstNameCtrl.text.trim(),
          lastName: _lastNameCtrl.text.trim(),
          aboutMe: _aboutMeCtrl.text.trim().isEmpty ? null : _aboutMeCtrl.text.trim(),
          addressDetail: _addressCtrl.text.trim().isEmpty ? null : _addressCtrl.text.trim(),
          province: _provinceCtrl.text.trim().isEmpty ? null : _provinceCtrl.text.trim(),
          district: _districtCtrl.text.trim().isEmpty ? null : _districtCtrl.text.trim(),
          subdistrict: _subdistrictCtrl.text.trim().isEmpty ? null : _subdistrictCtrl.text.trim(),
          postalCode: _postalCodeCtrl.text.trim().isEmpty ? null : _postalCodeCtrl.text.trim(),
          profileImage: _newProfileImage,
          existingProfileImageUrl: contractor.member.profileImageUrl,
        ));
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ProfileBloc, ProfileState>(
      listener: (context, state) {
        if (state is ContractorProfileLoaded) {
          _fillForm(state.contractor.member);
        } else if (state is ProfileSaved) {
          setState(() {
            _isEditing = false;
            _newProfileImage = null;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('บันทึกโปรไฟล์สำเร็จ'),
              backgroundColor: Color(0xFF4CAF50),
            ),
          );
          context.read<ProfileBloc>().add(LoadContractorProfileEvent(widget.contractorId));
        } else if (state is ProfileError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message), backgroundColor: AppConfig.errorColor),
          );
        }
      },
      builder: (context, state) {
        if (state is ProfileLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator(color: AppConfig.primaryColor)),
          );
        }

        ContractorModel? contractor;
        if (state is ContractorProfileLoaded) contractor = state.contractor;

        return Scaffold(
          backgroundColor: AppConfig.surfaceColor,
          appBar: AppBar(
            backgroundColor: AppConfig.primaryColor,
            foregroundColor: Colors.white,
            title: Text(widget.readOnly ? 'โปรไฟล์ผู้รับจ้าง' : 'โปรไฟล์ของฉัน'),
            elevation: 0,
            automaticallyImplyLeading: widget.readOnly,
            actions: [
              if (!widget.readOnly && !_isEditing)
                IconButton(
                  icon: const Text('⚙️', style: TextStyle(fontSize: 20)),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SettingsPage(
                        role: SettingsRole.contractor,
                        contractorId: widget.contractorId,
                      ),
                    ),
                  ),
                ),
              if (!widget.readOnly && contractor != null)
                TextButton(
                  onPressed: () {
                    if (_isEditing) {
                      _save(contractor!);
                    } else {
                      setState(() => _isEditing = true);
                    }
                  },
                  child: Text(
                    _isEditing ? 'บันทึก' : 'แก้ไข',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              if (!widget.readOnly && _isEditing)
                TextButton(
                  onPressed: () {
                    setState(() {
                      _isEditing = false;
                      _newProfileImage = null;
                      if (contractor != null) _fillForm(contractor.member);
                    });
                  },
                  child: const Text('ยกเลิก', style: TextStyle(color: Colors.white70)),
                ),
            ],
          ),
          body: contractor == null
              ? const Center(child: CircularProgressIndicator(color: AppConfig.primaryColor))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        _buildAvatar(contractor.member),
                        const SizedBox(height: 16),
                        if (!_isEditing) _buildViewMode(contractor) else _buildEditMode(),
                      ],
                    ),
                  ),
                ),
        );
      },
    );
  }

  Widget _buildAvatar(MemberModel member) {
    return GestureDetector(
      onTap: _isEditing ? _pickImage : null,
      child: Stack(
        children: [
          CircleAvatar(
            radius: 52,
            backgroundColor: AppConfig.secondaryColor,
            backgroundImage: _newProfileImage != null
                ? FileImage(_newProfileImage!) as ImageProvider
                : member.profileImageUrl != null
                    ? NetworkImage(member.profileImageUrl!)
                    : null,
            child: (_newProfileImage == null && member.profileImageUrl == null)
                ? const Icon(Icons.person, size: 52, color: Colors.white)
                : null,
          ),
          if (_isEditing)
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: AppConfig.primaryColor,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.camera_alt, size: 16, color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildViewMode(ContractorModel contractor) {
    final m = contractor.member;
    final locationParts = [m.district, m.province].whereType<String>().join(', ');
    final shortAddress = [m.district, m.province].whereType<String>().join(', ');
    return Column(
      children: [
        // Name header
        Text(
          '${m.prefix ?? ''} ${m.firstName} ${m.lastName}'.trim(),
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Color(0xFF212121)),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          locationParts.isNotEmpty ? 'คนขับรถ • $locationParts' : 'คนขับรถ',
          style: const TextStyle(fontSize: 13, color: Color(0xFF9E9E9E)),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          alignment: WrapAlignment.center,
          children: [
            if (contractor.isIdentityVerified)
              _ProfileBadge('ยืนยันตัวตนแล้ว', const Color(0xFFE8F5E9), const Color(0xFF2E7D32))
            else
              _ProfileBadge('ยังไม่ยืนยันตัวตน', const Color(0xFFFFF3E0), const Color(0xFFE65100)),
            if (m.memberSince != null)
              _ProfileBadge('สมาชิกตั้งแต่ ${m.memberSince!.year + 543}',
                  const Color(0xFFE3F2FD), const Color(0xFF1565C0)),
          ],
        ),
        const SizedBox(height: 20),

        // Stats grid
        StatsGridWidget(items: [
          StatItem(
            value: contractor.ratingScore != null
                ? '⭐ ${contractor.ratingScore!.toStringAsFixed(1)}'
                : '⭐ -',
            label: 'คะแนนรีวิว',
            valueColor: const Color(0xFFF57C00),
          ),
          StatItem(value: '${contractor.totalJobs}', label: 'งานทั้งหมด'),
          StatItem(
            value: contractor.successRate != null
                ? '${(contractor.successRate! * 100).toStringAsFixed(0)}%'
                : '-',
            label: 'สำเร็จ',
            valueColor: const Color(0xFF4CAF50),
          ),
          StatItem(value: '${contractor.reviewCount}', label: 'รีวิวที่ได้รับ'),
        ]),
        const SizedBox(height: 12),

        // Contact card (ข้อมูลติดต่อ)
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [BoxShadow(color: Color(0x1A000000), blurRadius: 8, offset: Offset(0, 2))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('ข้อมูลติดต่อ',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
              const Divider(height: 16),
              _ContactRow(emoji: '📱', subtitle: 'เบอร์โทรศัพท์', value: m.phoneNumber),
              if (shortAddress.isNotEmpty) ...[
                const SizedBox(height: 12),
                _ContactRow(emoji: '📍', subtitle: 'ที่อยู่', value: shortAddress),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),
        _buildTrucksSection(),
        if (contractor.reviewCount > 0) ...[
          const SizedBox(height: 12),
          RecentReviewsSection(
            revieweeId: widget.contractorId,
            isContractor: true,
            onSeeAll: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    ContractorReviewsPage(contractorId: widget.contractorId),
              ),
            ),
          ),
        ],
        if (!widget.readOnly && !contractor.isIdentityVerified) ...[
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => VerifyIdentityPage(
                    contractorId: widget.contractorId,
                  ),
                ),
              ),
              icon: const Icon(Icons.verified_user_outlined),
              label: const Text('ยืนยันตัวตน',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConfig.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
            ),
          ),
        ],
        // ปุ่มโทรหา — เฉพาะเมื่อผู้ว่าจ้างเปิดดูโปรไฟล์ผู้รับจ้าง (ตาม Mockup)
        if (widget.readOnly) ...[
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _showCallDialog(m.phoneNumber, m.firstName),
              icon: const Icon(Icons.phone),
              label: const Text('โทรหา',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConfig.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
            ),
          ),
        ],
      ],
    );
  }

  void _showCallDialog(String phone, String name) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('โทรหา $name'),
        content: Text(phone,
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 2)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('ปิด',
                style: TextStyle(color: Color(0xFF757575))),
          ),
        ],
      ),
    );
  }

  Widget _buildTrucksSection() {
    return BlocBuilder<TruckBloc, TruckState>(
      builder: (context, state) {
        final trucks = state is TrucksLoaded ? state.trucks : <TruckModel>[];
        final first = trucks.isNotEmpty ? trucks.first : null;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(widget.readOnly ? 'รถของผู้รับจ้าง' : 'รถของฉัน',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                if (!widget.readOnly)
                  TextButton(
                    onPressed: () {
                      // capture bloc ก่อน navigate เพื่อไม่ใช้ context ข้าม async gap
                      final truckBloc = context.read<TruckBloc>();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              TruckListPage(contractorId: widget.contractorId),
                        ),
                      ).then((_) =>
                          truckBloc.add(LoadTrucksEvent(widget.contractorId)));
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: AppConfig.primaryColor,
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text('จัดการรถ',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(color: Color(0x1A000000), blurRadius: 8, offset: Offset(0, 2))
                ],
              ),
              child: first == null
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                            widget.readOnly
                                ? 'ยังไม่มีรถ'
                                : 'ยังไม่มีรถ กด "จัดการรถ" เพื่อเพิ่ม',
                            style: const TextStyle(
                                fontSize: 13, color: Color(0xFF9E9E9E))),
                      ),
                    )
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: AppConfig.surfaceColor,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Center(
                            child: Text('🚛', style: TextStyle(fontSize: 28)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('${first.brand} ${first.model}',
                                  style: const TextStyle(
                                      fontSize: 14, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 2),
                              Text(
                                '${first.truckType.typeName} • ทะเบียน ${first.licensePlate}'
                                    '${first.registeredProvince != null ? ' ${first.registeredProvince}' : ''}',
                                style: const TextStyle(
                                    fontSize: 12, color: Color(0xFF757575)),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  _TruckStatusBadge(first.approvalStatus),
                                  if (first.capacity != null) ...[
                                    const SizedBox(width: 8),
                                    Text(
                                      'บรรทุกได้ ${(first.capacity! / 1000).toStringAsFixed(0)} ตัน',
                                      style: const TextStyle(
                                          fontSize: 12, color: Color(0xFF757575)),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildEditMode() {
    return _EditCard(
      children: [
        _label('คำนำหน้า'),
        DropdownButtonFormField<String>(
          value: _prefixes.contains(_selectedPrefix) ? _selectedPrefix : null,
          decoration: _inputDecor('เลือกคำนำหน้า'),
          items: _prefixes.map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
          onChanged: (v) => setState(() => _selectedPrefix = v),
        ),
        const SizedBox(height: 12),
        _label('ชื่อจริง *'),
        TextFormField(
          controller: _firstNameCtrl,
          decoration: _inputDecor('ชื่อจริง'),
          validator: (v) => v == null || v.trim().isEmpty ? 'กรุณากรอกชื่อจริง' : null,
        ),
        const SizedBox(height: 12),
        _label('นามสกุล *'),
        TextFormField(
          controller: _lastNameCtrl,
          decoration: _inputDecor('นามสกุล'),
          validator: (v) => v == null || v.trim().isEmpty ? 'กรุณากรอกนามสกุล' : null,
        ),
        const SizedBox(height: 12),
        _label('เกี่ยวกับฉัน'),
        TextFormField(
          controller: _aboutMeCtrl,
          maxLines: 3,
          decoration: _inputDecor('แนะนำตัวเองสั้นๆ...'),
        ),
        const SizedBox(height: 12),
        _label('ที่อยู่'),
        TextFormField(
          controller: _addressCtrl,
          decoration: _inputDecor('บ้านเลขที่, ถนน, หมู่บ้าน'),
        ),
        const SizedBox(height: 12),
        _label('ตำบล/แขวง'),
        TextFormField(
          controller: _subdistrictCtrl,
          decoration: _inputDecor('ตำบล/แขวง'),
        ),
        const SizedBox(height: 12),
        _label('อำเภอ/เขต'),
        TextFormField(
          controller: _districtCtrl,
          decoration: _inputDecor('อำเภอ/เขต'),
        ),
        const SizedBox(height: 12),
        _label('จังหวัด'),
        TextFormField(
          controller: _provinceCtrl,
          decoration: _inputDecor('จังหวัด'),
        ),
        const SizedBox(height: 12),
        _label('รหัสไปรษณีย์'),
        TextFormField(
          controller: _postalCodeCtrl,
          keyboardType: TextInputType.number,
          decoration: _inputDecor('รหัสไปรษณีย์'),
        ),
      ],
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

class _EditCard extends StatelessWidget {
  final List<Widget> children;
  const _EditCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Color(0x1A000000), blurRadius: 8, offset: Offset(0, 2))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
    );
  }
}

class _ProfileBadge extends StatelessWidget {
  final String label;
  final Color bg;
  final Color fg;
  const _ProfileBadge(this.label, this.bg, this.fg);

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
        child: Text(label, style: TextStyle(fontSize: 12, color: fg, fontWeight: FontWeight.w500)),
      );
}

class _ContactRow extends StatelessWidget {
  final String emoji;
  final String subtitle;
  final String value;
  const _ContactRow({required this.emoji, required this.subtitle, required this.value});

  @override
  Widget build(BuildContext context) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(subtitle,
                    style: const TextStyle(fontSize: 12, color: Color(0xFF9E9E9E))),
                const SizedBox(height: 2),
                Text(value,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF212121))),
              ],
            ),
          ),
        ],
      );
}

class _TruckStatusBadge extends StatelessWidget {
  final String status;
  const _TruckStatusBadge(this.status);

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (status) {
      'อนุมัติแล้ว' => (const Color(0xFFE8F5E9), const Color(0xFF2E7D32)),
      'รอตรวจสอบ' => (const Color(0xFFFFF3E0), const Color(0xFFE65100)),
      'ถูกปฏิเสธ' => (const Color(0xFFFFEBEE), const Color(0xFFC62828)),
      _ => (AppConfig.surfaceColor, const Color(0xFF757575)),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(status, style: TextStyle(fontSize: 11, color: fg, fontWeight: FontWeight.w600)),
    );
  }
}


