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
import '../../../shared/widgets/stats_grid_widget.dart';
import '../../../shared/widgets/recent_reviews_section.dart';
import '../../wallet/pages/client_statistics_page.dart';
import 'settings_page.dart';

class ClientProfilePage extends StatelessWidget {
  final String clientId;
  // readOnly = ผู้รับจ้างเปิดดูโปรไฟล์ผู้ว่าจ้าง — ซ่อนปุ่มแก้ไข/ตั้งค่า
  final bool readOnly;
  const ClientProfilePage({
    super.key,
    required this.clientId,
    this.readOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ProfileBloc(
        memberRepository: MemberRepository(),
        clientRepository: ClientRepository(),
        contractorRepository: ContractorRepository(),
        storageRepository: StorageRepository(),
      )..add(LoadClientProfileEvent(clientId)),
      child: _ClientProfileView(clientId: clientId, readOnly: readOnly),
    );
  }
}

class _ClientProfileView extends StatefulWidget {
  final String clientId;
  final bool readOnly;
  const _ClientProfileView({required this.clientId, this.readOnly = false});

  @override
  State<_ClientProfileView> createState() => _ClientProfileViewState();
}

class _ClientProfileViewState extends State<_ClientProfileView> {
  bool _isEditing = false;
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _firstNameCtrl;
  late TextEditingController _lastNameCtrl;
  late TextEditingController _aboutMeCtrl;
  Set<String> _selectedProducts = {};
  static const _productOptions = [
    'กะหล่ำปลี', 'ข้าวโพด', 'ผักกาด', 'สตรอว์เบอร์รี่', 'มะเขือเทศ',
    'ข้าว', 'มันสำปะหลัง', 'ลำไย', 'ลิ้นจี่', 'กาแฟ',
  ];
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

  void _fillForm(ClientModel client) {
    _firstNameCtrl.text = client.member.firstName;
    _lastNameCtrl.text = client.member.lastName;
    _aboutMeCtrl.text = client.member.aboutMe ?? '';
    _selectedProducts = Set.from((client.mainProducts ?? '').split(',').map((s) => s.trim()).where((s) => s.isNotEmpty));
    _addressCtrl.text = client.member.addressDetail ?? '';
    _provinceCtrl.text = client.member.province ?? '';
    _districtCtrl.text = client.member.district ?? '';
    _subdistrictCtrl.text = client.member.subdistrict ?? '';
    _postalCodeCtrl.text = client.member.postalCode ?? '';
    _selectedPrefix = client.member.prefix;
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked != null) setState(() => _newProfileImage = File(picked.path));
  }

  void _save(ClientModel client) {
    if (!_formKey.currentState!.validate()) return;
    context.read<ProfileBloc>().add(SaveClientProfileEvent(
          clientId: widget.clientId,
          memberId: client.member.memberId,
          prefix: _selectedPrefix,
          firstName: _firstNameCtrl.text.trim(),
          lastName: _lastNameCtrl.text.trim(),
          aboutMe: _aboutMeCtrl.text.trim().isEmpty ? null : _aboutMeCtrl.text.trim(),
          mainProducts: _selectedProducts.isEmpty ? null : _selectedProducts.join(','),
          addressDetail: _addressCtrl.text.trim().isEmpty ? null : _addressCtrl.text.trim(),
          province: _provinceCtrl.text.trim().isEmpty ? null : _provinceCtrl.text.trim(),
          district: _districtCtrl.text.trim().isEmpty ? null : _districtCtrl.text.trim(),
          subdistrict: _subdistrictCtrl.text.trim().isEmpty ? null : _subdistrictCtrl.text.trim(),
          postalCode: _postalCodeCtrl.text.trim().isEmpty ? null : _postalCodeCtrl.text.trim(),
          profileImage: _newProfileImage,
          existingProfileImageUrl: client.member.profileImageUrl,
        ));
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ProfileBloc, ProfileState>(
      listener: (context, state) {
        if (state is ClientProfileLoaded) {
          _fillForm(state.client);
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
          context.read<ProfileBloc>().add(LoadClientProfileEvent(widget.clientId));
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

        ClientModel? client;
        if (state is ClientProfileLoaded) client = state.client;

        return Scaffold(
          backgroundColor: AppConfig.surfaceColor,
          appBar: AppBar(
            backgroundColor: AppConfig.primaryColor,
            foregroundColor: Colors.white,
            title: Text(widget.readOnly ? 'โปรไฟล์ผู้ว่าจ้าง' : 'โปรไฟล์ของฉัน'),
            elevation: 0,
            automaticallyImplyLeading: widget.readOnly,
            actions: [
              if (!widget.readOnly && !_isEditing)
                IconButton(
                  icon: const Text('⚙️', style: TextStyle(fontSize: 20)),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const SettingsPage(role: SettingsRole.client),
                    ),
                  ),
                ),
              if (!widget.readOnly && client != null)
                TextButton(
                  onPressed: () {
                    if (_isEditing) {
                      _save(client!);
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
                      if (client != null) _fillForm(client);
                    });
                  },
                  child: const Text('ยกเลิก', style: TextStyle(color: Colors.white70)),
                ),
            ],
          ),
          body: client == null
              ? const Center(child: CircularProgressIndicator(color: AppConfig.primaryColor))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        _buildAvatar(client.member),
                        const SizedBox(height: 16),
                        if (!_isEditing) _buildViewMode(client) else _buildEditMode(),
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
            backgroundColor: const Color(0xFFE8F5E9),
            backgroundImage: _newProfileImage != null
                ? FileImage(_newProfileImage!) as ImageProvider
                : member.profileImageUrl != null
                    ? NetworkImage(member.profileImageUrl!)
                    : null,
            child: (_newProfileImage == null && member.profileImageUrl == null)
                ? const Icon(Icons.person, size: 52, color: AppConfig.primaryColor)
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

  Widget _buildViewMode(ClientModel client) {
    final m = client.member;
    final locationParts = [m.district, m.province].whereType<String>().join(', ');
    return Column(
      children: [
        // Name header (ชื่อ + role + location + badges)
        Text(
          '${m.prefix ?? ''} ${m.firstName} ${m.lastName}'.trim(),
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Color(0xFF212121)),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          locationParts.isNotEmpty ? 'เกษตรกร • $locationParts' : 'เกษตรกร',
          style: const TextStyle(fontSize: 13, color: Color(0xFF9E9E9E)),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          alignment: WrapAlignment.center,
          children: [
            _ProfileBadge('ยืนยันตัวตนแล้ว', const Color(0xFFE8F5E9), const Color(0xFF2E7D32)),
            if (m.memberSince != null)
              _ProfileBadge('สมาชิกตั้งแต่ ${m.memberSince!.year + 543}',
                  const Color(0xFFE3F2FD), const Color(0xFF1565C0)),
          ],
        ),
        const SizedBox(height: 20),

        // Stats grid
        StatsGridWidget(items: [
          StatItem(
            value: client.ratingScore != null
                ? '⭐ ${client.ratingScore!.toStringAsFixed(1)}'
                : '⭐ -',
            label: 'คะแนนรีวิว',
            valueColor: const Color(0xFFF57C00),
          ),
          StatItem(value: '${client.totalJobs}', label: 'งานทั้งหมด'),
          StatItem(
            value: client.successRate != null
                ? '${(client.successRate! * 100).toStringAsFixed(0)}%'
                : '-',
            label: 'สำเร็จ',
            valueColor: const Color(0xFF4CAF50),
          ),
          StatItem(value: '${client.reviewCount}', label: 'รีวิวที่ได้รับ'),
        ]),
        const SizedBox(height: 12),

        // ปุ่มดูสถิติการใช้งาน (ซ่อนเมื่อดูโปรไฟล์คนอื่น)
        if (!widget.readOnly) ...[
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ClientStatisticsPage(clientId: widget.clientId),
                ),
              ),
              icon: const Icon(Icons.bar_chart, size: 18),
              label: const Text('ดูสถิติการใช้งาน'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppConfig.primaryColor,
                side: const BorderSide(color: AppConfig.primaryColor),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],

        // Contact info card (phone/products/address)
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('ข้อมูลติดต่อ',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
              const Divider(height: 16),
              _ContactRow(emoji: '📱', subtitle: 'เบอร์โทรศัพท์', value: m.phoneNumber),
              if (m.province != null) ...[
                const SizedBox(height: 12),
                _ContactRow(
                  emoji: '📍',
                  subtitle: 'ที่อยู่หลัก',
                  value: [
                    if (m.district != null) m.district!,
                    m.province!,
                  ].join(', '),
                ),
              ],
              if (client.mainProducts != null) ...[
                const SizedBox(height: 12),
                _ContactRow(emoji: '🌾', subtitle: 'ประเภทสินค้าหลัก', value: client.mainProducts!),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Reviews preview card
        if (client.reviewCount > 0) ...[
          RecentReviewsSection(
              revieweeId: widget.clientId, isContractor: false),
          const SizedBox(height: 0),
        ],

        // การ์ด 'บัญชี' (ยอดเงิน) — แสดงเฉพาะเจ้าของ ไม่โชว์ตอนคนอื่นเปิดดู (privacy)
        if (!widget.readOnly) ...[
          const SizedBox(height: 12),
          _InfoCard(title: 'บัญชี', rows: [
            _InfoRow('ยอดเงินคงเหลือ', '฿${client.walletBalance.toStringAsFixed(2)}'),
          ]),
        ],

        // ปุ่มโทรหา — เฉพาะเมื่อผู้รับจ้างเปิดดูโปรไฟล์ผู้ว่าจ้าง (ตาม Mockup)
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

  Widget _buildEditMode() {
    return Container(
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
            maxLines: 2,
            decoration: _inputDecor('แนะนำตัวเองสั้นๆ...'),
          ),
          const SizedBox(height: 12),
          _label('ประเภทสินค้าหลัก'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _productOptions.map((product) {
              final selected = _selectedProducts.contains(product);
              return FilterChip(
                label: Text(product),
                selected: selected,
                onSelected: (val) {
                  setState(() {
                    if (val) {
                      _selectedProducts.add(product);
                    } else {
                      _selectedProducts.remove(product);
                    }
                  });
                },
                selectedColor: AppConfig.primaryColor.withAlpha(51),
                checkmarkColor: AppConfig.primaryColor,
                labelStyle: TextStyle(
                  color: selected ? AppConfig.primaryColor : const Color(0xFF424242),
                  fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                ),
                side: BorderSide(
                  color: selected ? AppConfig.primaryColor : const Color(0xFFE0E0E0),
                ),
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          _label('ที่อยู่'),
          TextFormField(
            controller: _addressCtrl,
            decoration: _inputDecor('บ้านเลขที่, ถนน, หมู่บ้าน'),
          ),
          const SizedBox(height: 12),
          _label('ตำบล/แขวง'),
          TextFormField(controller: _subdistrictCtrl, decoration: _inputDecor('ตำบล/แขวง')),
          const SizedBox(height: 12),
          _label('อำเภอ/เขต'),
          TextFormField(controller: _districtCtrl, decoration: _inputDecor('อำเภอ/เขต')),
          const SizedBox(height: 12),
          _label('จังหวัด'),
          TextFormField(controller: _provinceCtrl, decoration: _inputDecor('จังหวัด')),
          const SizedBox(height: 12),
          _label('รหัสไปรษณีย์'),
          TextFormField(
            controller: _postalCodeCtrl,
            keyboardType: TextInputType.number,
            decoration: _inputDecor('รหัสไปรษณีย์'),
          ),
        ],
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

class _InfoCard extends StatelessWidget {
  final String title;
  final List<_InfoRow> rows;
  const _InfoCard({required this.title, required this.rows});

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) return const SizedBox.shrink();
    return Container(
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
          Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          const Divider(height: 16),
          ...rows.map((r) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 120,
                      child: Text(r.label,
                          style: const TextStyle(fontSize: 13, color: Color(0xFF757575))),
                    ),
                    Expanded(
                      child: Text(r.value,
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}

class _InfoRow {
  final String label;
  final String value;
  const _InfoRow(this.label, this.value);
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
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF212121))),
              ],
            ),
          ),
        ],
      );
}


