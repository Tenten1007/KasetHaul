import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/config/app_config.dart';
import '../../../core/repositories/repositories.dart';
import '../bloc/truck_bloc.dart';
import '../bloc/truck_event.dart';
import '../bloc/truck_state.dart';
import '../../../models/models.dart';
import 'edit_truck_page.dart';

class ViewTruckPage extends StatelessWidget {
  final String truckId;
  final String contractorId;
  const ViewTruckPage({super.key, required this.truckId, required this.contractorId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => TruckBloc(
        truckRepository: TruckRepository(),
        truckTypeRepository: TruckTypeRepository(),
        storageRepository: StorageRepository(),
      )..add(LoadTruckDetailEvent(truckId)),
      child: _ViewTruckContent(truckId: truckId, contractorId: contractorId),
    );
  }
}

class _ViewTruckContent extends StatelessWidget {
  final String truckId;
  final String contractorId;
  const _ViewTruckContent({required this.truckId, required this.contractorId});

  Color _statusColor(String status) {
    switch (status) {
      case 'อนุมัติแล้ว':
        return const Color(0xFF4CAF50);
      case 'ถูกปฏิเสธ':
        return const Color(0xFFD32F2F);
      default:
        return const Color(0xFFFF9800);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<TruckBloc, TruckState>(
      listener: (context, state) {
        if (state is TruckRemoved) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('ลบรถบรรทุกสำเร็จ'),
              backgroundColor: Color(0xFF4CAF50),
            ),
          );
          Navigator.pop(context, true);
        } else if (state is TruckError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message), backgroundColor: AppConfig.errorColor),
          );
        }
      },
      builder: (context, state) {
        if (state is TruckLoading) {
          return Scaffold(
            appBar: AppBar(
              backgroundColor: AppConfig.primaryColor,
              foregroundColor: Colors.white,
              title: const Text('รายละเอียดรถ'),
            ),
            body: const Center(
              child: CircularProgressIndicator(color: AppConfig.primaryColor),
            ),
          );
        }

        if (state is TruckDetailLoaded) {
          final truck = state.truck;
          return Scaffold(
            backgroundColor: AppConfig.surfaceColor,
            appBar: AppBar(
              backgroundColor: AppConfig.primaryColor,
              foregroundColor: Colors.white,
              title: const Text('รายละเอียดรถ'),
              elevation: 0,
              actions: [
                if (truck.approvalStatus != 'กำลังรับงานขนส่ง')
                  IconButton(
                    icon: const Icon(Icons.edit_outlined),
                    tooltip: 'แก้ไข',
                    onPressed: () async {
                      final result = await Navigator.push<bool>(
                        context,
                        MaterialPageRoute(
                          builder: (_) => EditTruckPage(truck: truck),
                        ),
                      );
                      if (result == true && context.mounted) {
                        context.read<TruckBloc>().add(LoadTruckDetailEvent(truckId));
                      }
                    },
                  ),
              ],
            ),
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status banner
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    decoration: BoxDecoration(
                      color: _statusColor(truck.approvalStatus).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _statusColor(truck.approvalStatus)),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          truck.approvalStatus == 'อนุมัติแล้ว'
                              ? Icons.check_circle
                              : truck.approvalStatus == 'ถูกปฏิเสธ'
                                  ? Icons.cancel
                                  : Icons.pending,
                          color: _statusColor(truck.approvalStatus),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'สถานะ: ${truck.approvalStatus}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: _statusColor(truck.approvalStatus),
                              ),
                            ),
                            if (truck.approvalNote != null)
                              Text(
                                'หมายเหตุ: ${truck.approvalNote}',
                                style: const TextStyle(fontSize: 12, color: Color(0xFF757575)),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Photo
                  if (truck.truckPhotosUrl != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.network(
                        truck.truckPhotosUrl!,
                        width: double.infinity,
                        height: 200,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          height: 200,
                          color: const Color(0xFFEEEEEE),
                          child: const Icon(Icons.local_shipping, size: 64, color: Color(0xFFBDBDBD)),
                        ),
                      ),
                    )
                  else
                    Container(
                      width: double.infinity,
                      height: 160,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5E9),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(Icons.local_shipping, size: 72, color: AppConfig.primaryColor),
                    ),
                  const SizedBox(height: 16),

                  // Info card
                  _InfoCard(
                    title: 'ข้อมูลรถบรรทุก',
                    rows: [
                      _InfoRow('ประเภทรถ', truck.truckType.typeName),
                      _InfoRow('ยี่ห้อ', truck.brand),
                      _InfoRow('รุ่น', truck.model),
                      _InfoRow('ป้ายทะเบียน', truck.licensePlate),
                      if (truck.registeredProvince != null)
                        _InfoRow('จังหวัดที่จด', truck.registeredProvince!),
                      if (truck.capacity != null)
                        _InfoRow('น้ำหนักสูงสุด', '${truck.capacity} กก.'),
                      if (truck.features != null)
                        _InfoRow('คุณสมบัติเสริม', truck.features!),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Documents
                  _InfoCard(
                    title: 'เอกสารประกอบ',
                    rows: [
                      _InfoRow(
                        'สำเนาทะเบียน',
                        truck.registrationDocUrl != null ? 'มีเอกสาร' : 'ยังไม่มีเอกสาร',
                      ),
                      _InfoRow(
                        'ประกันภัย',
                        truck.insuranceDocUrl != null ? 'มีเอกสาร' : 'ยังไม่มีเอกสาร',
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Remove button
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppConfig.errorColor,
                      side: const BorderSide(color: AppConfig.errorColor),
                      minimumSize: const Size(double.infinity, 48),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () => _confirmRemove(context, truck),
                    child: const Text('ลบรถบรรทุกนี้'),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          );
        }

        if (state is TruckError) {
          return Scaffold(
            appBar: AppBar(
              backgroundColor: AppConfig.primaryColor,
              foregroundColor: Colors.white,
              title: const Text('รายละเอียดรถ'),
            ),
            body: Center(child: Text(state.message)),
          );
        }

        return const Scaffold();
      },
    );
  }

  void _confirmRemove(BuildContext context, TruckModel truck) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('ยืนยันการลบรถ'),
        content: Text(
          'คุณต้องการลบรถ ${truck.brand} ${truck.model} (${truck.licensePlate}) ออกจากระบบ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ยกเลิก', style: TextStyle(color: Color(0xFF757575))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConfig.errorColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              Navigator.pop(context);
              context.read<TruckBloc>().add(RemoveTruckEvent(truck.truckId));
            },
            child: const Text('ลบรถ'),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final List<_InfoRow> rows;
  const _InfoCard({required this.title, required this.rows});

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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


