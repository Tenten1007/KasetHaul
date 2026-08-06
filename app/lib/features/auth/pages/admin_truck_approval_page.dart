import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/config/app_config.dart';
import '../../../models/models.dart';
import '../bloc/admin_bloc.dart';

class AdminTruckApprovalPage extends StatefulWidget {
  const AdminTruckApprovalPage({super.key});

  @override
  State<AdminTruckApprovalPage> createState() => _AdminTruckApprovalPageState();
}

class _AdminTruckApprovalPageState extends State<AdminTruckApprovalPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    context.read<AdminBloc>().add(const LoadAllTrucksEvent());
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _showApproveDialog(TruckModel truck) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('ยืนยันการอนุมัติ'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(
                color: Color(0xFFE8F5E9),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: const Text('✓', style: TextStyle(fontSize: 32)),
            ),
            const SizedBox(height: 12),
            Text(
              '${truck.brand} ${truck.model}',
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
            ),
            const SizedBox(height: 4),
            Text(
              'ทะเบียน: ${truck.licensePlate}',
              style: const TextStyle(color: AppConfig.textSecondaryColor),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConfig.primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('ยืนยันอนุมัติ'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      context.read<AdminBloc>().add(
            ApproveTruckEvent(
              truckId: truck.truckId,
              contractorId: truck.contractorId,
            ),
          );
    }
  }

  Future<void> _showRejectDialog(TruckModel truck) async {
    final reasonCtrl = TextEditingController();
    String? selectedChip;
    final chips = ['เอกสารไม่ถูกต้อง', 'รูปไม่ชัดเจน', 'ประกันหมดอายุ', 'ข้อมูลไม่ตรงกัน'];

    final reason = await showDialog<String>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('ปฏิเสธการตรวจสอบ'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFFEBEE),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: const Text('✕', style: TextStyle(fontSize: 32)),
                ),
                const SizedBox(height: 12),
                Text(
                  '${truck.brand} ${truck.model}',
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                ),
                const SizedBox(height: 16),
                const Text('เหตุผลที่ปฏิเสธ',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: chips.map((chip) {
                    final active = selectedChip == chip;
                    return GestureDetector(
                      onTap: () {
                        setDialogState(() => selectedChip = chip);
                        reasonCtrl.text = chip;
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: active
                              ? AppConfig.primaryColor
                              : AppConfig.surfaceColor,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: active
                                ? AppConfig.primaryColor
                                : const Color(0xFFE0E0E0),
                          ),
                        ),
                        child: Text(
                          chip,
                          style: TextStyle(
                            fontSize: 13,
                            color: active ? Colors.white : AppConfig.textPrimaryColor,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
                const Text('รายละเอียดเพิ่มเติม'),
                const SizedBox(height: 6),
                TextField(
                  controller: reasonCtrl,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'อธิบายเหตุผลที่ปฏิเสธ',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.all(12),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('ยกเลิก'),
            ),
            ElevatedButton(
              onPressed: () {
                final text = reasonCtrl.text.trim();
                if (text.isEmpty) return;
                Navigator.pop(ctx, text);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConfig.statusErrorColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('ยืนยันปฏิเสธ'),
            ),
          ],
        ),
      ),
    );
    if (reason != null && reason.isNotEmpty && mounted) {
      context.read<AdminBloc>().add(
            RejectTruckEvent(
              truckId: truck.truckId,
              contractorId: truck.contractorId,
              reason: reason,
            ),
          );
    }
  }

  void _reload() => context.read<AdminBloc>().add(const LoadAllTrucksEvent());

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AdminBloc, AdminState>(
      listener: (context, state) {
        if (state is TruckApproved) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('อนุมัติรถสำเร็จ'),
              backgroundColor: AppConfig.primaryColor,
            ),
          );
          _reload();
        } else if (state is TruckRejected) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('ปฏิเสธรถแล้ว'),
              backgroundColor: AppConfig.statusErrorColor,
            ),
          );
          _reload();
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
        if (state is AdminLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is AllTrucksLoaded) {
          return Column(
            children: [
              // Tab bar
              Container(
                color: AppConfig.primaryColor,
                child: TabBar(
                  controller: _tabController,
                  indicatorColor: Colors.white,
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white70,
                  isScrollable: true,
                  tabAlignment: TabAlignment.start,
                  tabs: [
                    Tab(text: 'ทั้งหมด (${state.all.length})'),
                    Tab(text: 'รอตรวจสอบ (${state.pending.length})'),
                    Tab(text: 'อนุมัติแล้ว (${state.approved.length})'),
                    Tab(text: 'ปฏิเสธ (${state.rejected.length})'),
                  ],
                ),
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _TruckList(
                      trucks: state.all,
                      emptyMessage: 'ไม่มีรถในระบบ',
                      onApprove: _showApproveDialog,
                      onReject: _showRejectDialog,
                      onRefresh: _reload,
                    ),
                    _TruckList(
                      trucks: state.pending,
                      emptyMessage: 'ไม่มีรถรอตรวจสอบ',
                      onApprove: _showApproveDialog,
                      onReject: _showRejectDialog,
                      onRefresh: _reload,
                    ),
                    _TruckList(
                      trucks: state.approved,
                      emptyMessage: 'ยังไม่มีรถที่อนุมัติ',
                      onApprove: _showApproveDialog,
                      onReject: _showRejectDialog,
                      onRefresh: _reload,
                      readOnly: true,
                    ),
                    _TruckList(
                      trucks: state.rejected,
                      emptyMessage: 'ยังไม่มีรถที่ถูกปฏิเสธ',
                      onApprove: _showApproveDialog,
                      onReject: _showRejectDialog,
                      onRefresh: _reload,
                      readOnly: true,
                    ),
                  ],
                ),
              ),
            ],
          );
        }

        // Fallback: also handle legacy PendingTrucksLoaded
        if (state is PendingTrucksLoaded) {
          return _TruckList(
            trucks: state.trucks,
            emptyMessage: 'ไม่มีรถรอตรวจสอบ',
            onApprove: _showApproveDialog,
            onReject: _showRejectDialog,
            onRefresh: _reload,
          );
        }

        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('โหลดรายการรถ...',
                  style: TextStyle(color: AppConfig.textSecondaryColor)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _reload,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppConfig.primaryColor,
                  foregroundColor: Colors.white,
                ),
                child: const Text('โหลดใหม่'),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _TruckList extends StatelessWidget {
  final List<TruckModel> trucks;
  final String emptyMessage;
  final Future<void> Function(TruckModel) onApprove;
  final Future<void> Function(TruckModel) onReject;
  final VoidCallback onRefresh;
  final bool readOnly;

  const _TruckList({
    required this.trucks,
    required this.emptyMessage,
    required this.onApprove,
    required this.onReject,
    required this.onRefresh,
    this.readOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    if (trucks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🚛', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 12),
            Text(emptyMessage,
                style: const TextStyle(
                  fontSize: 16,
                  color: AppConfig.textSecondaryColor,
                )),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      color: AppConfig.primaryColor,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: trucks.length,
        itemBuilder: (context, index) {
          final truck = trucks[index];
          return _TruckCard(
            truck: truck,
            readOnly: readOnly,
            onApprove: () => onApprove(truck),
            onReject: () => onReject(truck),
          );
        },
      ),
    );
  }
}

class _TruckCard extends StatelessWidget {
  final TruckModel truck;
  final bool readOnly;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const _TruckCard({
    required this.truck,
    required this.readOnly,
    required this.onApprove,
    required this.onReject,
  });

  Color get _statusColor {
    switch (truck.approvalStatus) {
      case 'อนุมัติแล้ว':
        return AppConfig.primaryColor;
      case 'ถูกปฏิเสธ':
        return AppConfig.statusErrorColor;
      default:
        return AppConfig.statusWarningColor;
    }
  }

  Color get _statusBg {
    switch (truck.approvalStatus) {
      case 'อนุมัติแล้ว':
        return const Color(0xFFE8F5E9);
      case 'ถูกปฏิเสธ':
        return const Color(0xFFFFEBEE);
      default:
        return const Color(0xFFFFF3E0);
    }
  }

  String get _statusLabel {
    switch (truck.approvalStatus) {
      case 'อนุมัติแล้ว':
        return 'อนุมัติแล้ว';
      case 'ถูกปฏิเสธ':
        return 'ปฏิเสธ';
      default:
        return 'รอตรวจสอบ';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _statusColor, width: 2),
        boxShadow: const [
          AppConfig.cardShadow,
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('🚛', style: TextStyle(fontSize: 32)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${truck.brand} ${truck.model}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: _statusBg,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              _statusLabel,
                              style: TextStyle(
                                fontSize: 11,
                                color: _statusColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'ทะเบียน: ${truck.licensePlate}${truck.registeredProvince != null ? " ${truck.registeredProvince}" : ""}',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppConfig.textSecondaryColor,
                        ),
                      ),
                      if (truck.capacity != null)
                        Text(
                          'น้ำหนักบรรทุก: ${truck.capacity} กก.',
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppConfig.textSecondaryColor,
                          ),
                        ),
                      Text(
                        'ประเภท: ${truck.truckType.typeName}',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppConfig.textSecondaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // เอกสาร/รูปภาพรถ (ตาม Mockup 09 — admin ดูก่อนอนุมัติ)
            if (truck.truckPhotosUrl != null ||
                truck.registrationDocUrl != null ||
                truck.insuranceDocUrl != null) ...[
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 8),
              const Text('เอกสารและรูปภาพ',
                  style: TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              if (truck.truckPhotosUrl != null)
                _DocRow(
                    icon: Icons.photo_camera_outlined,
                    label: 'รูปถ่ายรถ',
                    url: truck.truckPhotosUrl!),
              if (truck.registrationDocUrl != null)
                _DocRow(
                    icon: Icons.description_outlined,
                    label: 'สำเนาทะเบียนรถ',
                    url: truck.registrationDocUrl!),
              if (truck.insuranceDocUrl != null)
                _DocRow(
                    icon: Icons.verified_user_outlined,
                    label: 'เอกสารประกันภัย',
                    url: truck.insuranceDocUrl!),
            ],
            if (!readOnly) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onReject,
                      icon: const Icon(Icons.close, size: 16),
                      label: const Text('ปฏิเสธ'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppConfig.statusErrorColor,
                        side: const BorderSide(color: AppConfig.statusErrorColor),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: onApprove,
                      icon: const Icon(Icons.check, size: 16),
                      label: const Text('อนุมัติ'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppConfig.primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// แถวเอกสาร 1 ชิ้น + ปุ่ม "ดู" เปิดดูภาพเต็มจอ
class _DocRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String url;
  const _DocRow({required this.icon, required this.label, required this.url});

  void _view(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _DocViewerPage(title: label, url: url),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppConfig.textSecondaryColor),
          const SizedBox(width: 8),
          Expanded(
            child: Text(label,
                style: const TextStyle(
                    fontSize: 13, color: AppConfig.textPrimaryColor)),
          ),
          TextButton.icon(
            onPressed: () => _view(context),
            icon: const Icon(Icons.visibility_outlined, size: 16),
            label: const Text('ดู', style: TextStyle(fontSize: 13)),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF1976D2),
              padding: const EdgeInsets.symmetric(horizontal: 10),
              minimumSize: const Size(0, 32),
            ),
          ),
        ],
      ),
    );
  }
}

/// หน้าดูเอกสาร/รูปภาพแบบเต็มจอ (ซูม/เลื่อนได้)
class _DocViewerPage extends StatelessWidget {
  final String title;
  final String url;
  const _DocViewerPage({required this.title, required this.url});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(title),
        elevation: 0,
      ),
      body: Center(
        child: InteractiveViewer(
          minScale: 0.5,
          maxScale: 4,
          child: Image.network(
            url,
            fit: BoxFit.contain,
            loadingBuilder: (ctx, child, progress) => progress == null
                ? child
                : const Center(
                    child: CircularProgressIndicator(color: Colors.white)),
            errorBuilder: (ctx, _, __) => const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.broken_image_outlined,
                      color: Colors.white54, size: 48),
                  SizedBox(height: 8),
                  Text('เปิดเอกสารไม่สำเร็จ',
                      style: TextStyle(color: Colors.white54)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}


