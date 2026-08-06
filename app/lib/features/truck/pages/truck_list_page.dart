import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/config/app_config.dart';
import '../../../core/repositories/repositories.dart';
import '../bloc/truck_bloc.dart';
import '../bloc/truck_event.dart';
import '../bloc/truck_state.dart';
import '../../../models/models.dart';
import 'add_truck_page.dart';
import 'view_truck_page.dart';

class TruckListPage extends StatelessWidget {
  final String contractorId;
  const TruckListPage({super.key, required this.contractorId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => TruckBloc(
        truckRepository: TruckRepository(),
        truckTypeRepository: TruckTypeRepository(),
        storageRepository: StorageRepository(),
      )..add(LoadTrucksEvent(contractorId)),
      child: _TruckListView(contractorId: contractorId),
    );
  }
}

class _TruckListView extends StatelessWidget {
  final String contractorId;
  const _TruckListView({required this.contractorId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConfig.surfaceColor,
      appBar: AppBar(
        backgroundColor: AppConfig.primaryColor,
        foregroundColor: Colors.white,
        title: const Text('รถบรรทุกของฉัน'),
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppConfig.primaryColor,
        foregroundColor: Colors.white,
        onPressed: () async {
          final result = await Navigator.push<bool>(
            context,
            MaterialPageRoute(
              builder: (_) => AddTruckPage(contractorId: contractorId),
            ),
          );
          if (result == true && context.mounted) {
            context.read<TruckBloc>().add(LoadTrucksEvent(contractorId));
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('เพิ่มรถ'),
      ),
      body: BlocBuilder<TruckBloc, TruckState>(
        builder: (context, state) {
          if (state is TruckLoading) {
            return const Center(
              child: CircularProgressIndicator(color: AppConfig.primaryColor),
            );
          }
          if (state is TruckError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Color(0xFF9E9E9E)),
                  const SizedBox(height: 12),
                  Text(state.message, style: const TextStyle(color: Color(0xFF757575))),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppConfig.primaryColor,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () =>
                        context.read<TruckBloc>().add(LoadTrucksEvent(contractorId)),
                    child: const Text('ลองใหม่'),
                  ),
                ],
              ),
            );
          }
          if (state is TrucksLoaded) {
            if (state.trucks.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: const BoxDecoration(
                        color: Color(0xFFE8F5E9),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.local_shipping_outlined,
                          size: 52, color: AppConfig.primaryColor),
                    ),
                    const SizedBox(height: 16),
                    const Text('ยังไม่มีรถบรรทุก',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    const Text(
                      'กรุณาเพิ่มรถบรรทุกของคุณ\nเพื่อเริ่มรับงานขนส่ง',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Color(0xFF757575)),
                    ),
                  ],
                ),
              );
            }
            return RefreshIndicator(
              color: AppConfig.primaryColor,
              onRefresh: () async =>
                  context.read<TruckBloc>().add(LoadTrucksEvent(contractorId)),
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: state.trucks.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (ctx, i) =>
                    _TruckCard(truck: state.trucks[i], contractorId: contractorId),
              ),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}

class _TruckCard extends StatelessWidget {
  final TruckModel truck;
  final String contractorId;
  const _TruckCard({required this.truck, required this.contractorId});

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

  String _statusLabel(String status) {
    switch (status) {
      case 'อนุมัติแล้ว':
        return 'อนุมัติแล้ว';
      case 'ถูกปฏิเสธ':
        return 'ถูกปฏิเสธ';
      default:
        return 'รอตรวจสอบ';
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final result = await Navigator.push<bool>(
          context,
          MaterialPageRoute(
            builder: (_) => ViewTruckPage(
              truckId: truck.truckId,
              contractorId: contractorId,
            ),
          ),
        );
        if (result == true && context.mounted) {
          context.read<TruckBloc>().add(LoadTrucksEvent(contractorId));
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(color: Color(0x1A000000), blurRadius: 8, offset: Offset(0, 2)),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3E0),
                borderRadius: BorderRadius.circular(12),
              ),
              child: truck.truckPhotosUrl != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(truck.truckPhotosUrl!, fit: BoxFit.cover),
                    )
                  : const Icon(Icons.local_shipping, color: AppConfig.primaryColor, size: 32),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${truck.brand} ${truck.model}',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'ทะเบียน: ${truck.licensePlate} • ${truck.truckType.typeName}',
                    style: const TextStyle(fontSize: 13, color: Color(0xFF757575)),
                  ),
                  if (truck.capacity != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      'น้ำหนักสูงสุด: ${truck.capacity} กก.',
                      style: const TextStyle(fontSize: 12, color: Color(0xFF9E9E9E)),
                    ),
                  ],
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: _statusColor(truck.approvalStatus).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _statusColor(truck.approvalStatus)),
              ),
              child: Text(
                _statusLabel(truck.approvalStatus),
                style: TextStyle(
                  fontSize: 11,
                  color: _statusColor(truck.approvalStatus),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


