import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../core/config/app_config.dart';
import '../../../models/models.dart';
import '../bloc/tracking_bloc.dart';

class LocationViewPage extends StatelessWidget {
  final String jobId;
  final String jobTitle;
  final String jobStatus;
  final String pickupAddress;
  final String dropoffAddress;
  final int? distanceKm;

  const LocationViewPage({
    super.key,
    required this.jobId,
    required this.jobTitle,
    required this.jobStatus,
    required this.pickupAddress,
    required this.dropoffAddress,
    this.distanceKm,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => TrackingBloc()..add(LoadTracking(jobId)),
      child: _LocationView(
        jobId: jobId,
        jobStatus: jobStatus,
        pickupAddress: pickupAddress,
        dropoffAddress: dropoffAddress,
        distanceKm: distanceKm,
      ),
    );
  }
}

class _LocationView extends StatelessWidget {
  final String jobId;
  final String jobStatus;
  final String pickupAddress;
  final String dropoffAddress;
  final int? distanceKm;

  const _LocationView({
    required this.jobId,
    required this.jobStatus,
    required this.pickupAddress,
    required this.dropoffAddress,
    this.distanceKm,
  });

  void _reload(BuildContext context) =>
      context.read<TrackingBloc>().add(LoadTracking(jobId));

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TrackingBloc, TrackingState>(
      builder: (context, state) {
        final isLoading = state is TrackingLoading || state is TrackingInitial;
        final snap = state is TrackingLoaded ? state.data : null;
        return Scaffold(
          backgroundColor: AppConfig.surfaceColor,
          appBar: AppBar(
            backgroundColor: AppConfig.primaryColor,
            foregroundColor: Colors.white,
            title: const Text('ติดตาม GPS'),
            elevation: 0,
            actions: [
              if (snap?.contractor != null)
                IconButton(
                  icon: const Icon(Icons.phone),
                  tooltip: 'โทรหาผู้รับจ้าง',
                  onPressed: () => _showPhoneDialog(
                      context,
                      snap!.contractor!.member.phoneNumber,
                      snap.contractor!.member.firstName),
                ),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: isLoading ? null : () => _reload(context),
              ),
            ],
          ),
          body: isLoading
              ? const Center(child: CircularProgressIndicator())
              : state is TrackingError
                  ? _buildError(context, state.message)
                  : _buildContent(context, snap),
        );
      },
    );
  }

  Widget _buildError(BuildContext context, String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppConfig.errorColor),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center,
                style: const TextStyle(color: AppConfig.errorColor)),
            const SizedBox(height: 16),
            ElevatedButton(
                onPressed: () => _reload(context),
                child: const Text('ลองใหม่')),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, TrackingData? snap) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Map + Contractor card (overlapping)
          Stack(
            clipBehavior: Clip.none,
            children: [
              _MapWidget(
                location: snap?.location,
                jobStatus: jobStatus,
                pickupAddress: pickupAddress,
                dropoffAddress: dropoffAddress,
              ),
              if (snap?.contractor != null)
                Positioned(
                  bottom: -44,
                  left: 16,
                  right: 16,
                  child: _ContractorCard(
                    contractor: snap!.contractor!,
                    truck: snap.truck,
                    onCallTap: () => _showPhoneDialog(
                        context,
                        snap.contractor!.member.phoneNumber,
                        snap.contractor!.member.firstName),
                  ),
                ),
            ],
          ),
          SizedBox(height: snap?.contractor != null ? 60 : 16),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Timeline card
                _TimelineCard(
                  jobStatus: jobStatus,
                  eta: snap?.location != null
                      ? _formatEta(snap!.location!.timestamp)
                      : null,
                ),
                const SizedBox(height: 16),

                // ETA card
                _EtaCard(
                  location: snap?.location,
                  distanceKm: distanceKm,
                ),
                const SizedBox(height: 16),

                // Refresh button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _reload(context),
                    icon: const Icon(Icons.refresh,
                        color: AppConfig.primaryColor),
                    label: const Text('รีเฟรชตำแหน่ง'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppConfig.primaryColor,
                      side: const BorderSide(color: AppConfig.primaryColor),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'ตำแหน่งจะอัปเดตเมื่อผู้รับจ้างส่งข้อมูล GPS ใหม่',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: Color(0xFF9E9E9E)),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatEta(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')} น.';

  void _showPhoneDialog(BuildContext context, String phone, String name) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('โทรหา $name'),
        content: Text(
          phone,
          style: const TextStyle(
              fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 2),
          textAlign: TextAlign.center,
        ),
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
}

// ── Map Widget (Google Maps) ──────────────────────────────────────────────────

// ค่า default เมื่อยังไม่มี GPS — กลางประเทศไทย
const _kThailandCenter = LatLng(13.7563, 100.5018);

class _MapWidget extends StatefulWidget {
  final LocationTrackingModel? location;
  final String jobStatus;
  final String pickupAddress;
  final String dropoffAddress;

  const _MapWidget({
    required this.location,
    required this.jobStatus,
    required this.pickupAddress,
    required this.dropoffAddress,
  });

  @override
  State<_MapWidget> createState() => _MapWidgetState();
}

class _MapWidgetState extends State<_MapWidget> {
  GoogleMapController? _controller;

  LatLng get _center {
    final loc = widget.location;
    if (loc != null) return LatLng(loc.lat, loc.lng);
    return _kThailandCenter;
  }

  Set<Marker> get _markers {
    final loc = widget.location;
    if (loc == null) return {};
    return {
      Marker(
        markerId: const MarkerId('truck'),
        position: LatLng(loc.lat, loc.lng),
        infoWindow: InfoWindow(
          title: '🚛 ผู้รับจ้าง',
          snippet: widget.jobStatus,
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
      ),
    };
  }

  @override
  void didUpdateWidget(_MapWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    final loc = widget.location;
    if (loc != null && loc != oldWidget.location) {
      _controller?.animateCamera(
        CameraUpdate.newLatLng(LatLng(loc.lat, loc.lng)),
      );
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasLocation = widget.location != null;
    return SizedBox(
      height: 350,
      child: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _center,
              zoom: hasLocation ? 14.0 : 6.0,
            ),
            markers: _markers,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
            onMapCreated: (c) => _controller = c,
          ),

          // ป้ายจุดรับสินค้า (บนซ้าย)
          Positioned(
            top: 12,
            left: 12,
            child: _MapLabel(
              emoji: '📍',
              text: _shortAddr(widget.pickupAddress),
              color: AppConfig.primaryColor,
            ),
          ),

          // ป้ายจุดส่งสินค้า (ล่างขวา)
          Positioned(
            bottom: 12,
            right: 12,
            child: _MapLabel(
              emoji: '🏁',
              text: _shortAddr(widget.dropoffAddress),
              color: AppConfig.secondaryColor,
            ),
          ),

          // แสดง overlay เมื่อยังรอ GPS
          if (!hasLocation)
            Positioned(
              bottom: 12,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    '🚛 รอรับตำแหน่ง GPS จากผู้รับจ้าง',
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _shortAddr(String addr) {
    final parts = addr.split(' ');
    return parts.take(3).join(' ');
  }
}

class _MapLabel extends StatelessWidget {
  final String emoji;
  final String text;
  final Color color;

  const _MapLabel({
    required this.emoji,
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [AppConfig.cardShadowLg],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 4),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 120),
            child: Text(
              text,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Contractor Card ──────────────────────────────────────────────────────────

class _ContractorCard extends StatelessWidget {
  final ContractorModel contractor;
  final TruckModel? truck;
  final VoidCallback onCallTap;

  const _ContractorCard({
    required this.contractor,
    required this.truck,
    required this.onCallTap,
  });

  String get _initial {
    final f = contractor.member.firstName;
    return f.isNotEmpty ? f.characters.first : '?';
  }

  String get _truckInfo {
    if (truck == null) return '';
    final prov = truck!.registeredProvince ?? '';
    return '${truck!.brand} ${truck!.model} • ${truck!.licensePlate}${prov.isNotEmpty ? ' $prov' : ''}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
              color: Color(0x1A000000), blurRadius: 12, offset: Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppConfig.primaryColor,
            ),
            alignment: Alignment.center,
            child: Text(
              _initial,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${contractor.member.firstName} ${contractor.member.lastName}',
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.bold),
                ),
                if (_truckInfo.isNotEmpty)
                  Text(
                    _truckInfo,
                    style: const TextStyle(
                        fontSize: 12, color: Color(0xFF757575)),
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          IconButton(
            onPressed: onCallTap,
            icon: const Icon(Icons.phone, color: Colors.white),
            style: IconButton.styleFrom(
              backgroundColor: AppConfig.primaryColor,
              shape: const CircleBorder(),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Status Timeline ──────────────────────────────────────────────────────────

class _TimelineCard extends StatelessWidget {
  final String jobStatus;
  final String? eta; // เวลาถึงโดยประมาณ (แสดงใต้สถานะ "กำลังขนส่ง")

  // (ค่าสถานะจริงในข้อมูล, ข้อความที่แสดง) — label "รับงาน" ตรง Mockup
  static const _stages = [
    ('มอบหมายแล้ว', 'รับงาน'),
    ('ถึงจุดรับสินค้า', 'ถึงจุดรับสินค้า'),
    ('รับสินค้าเรียบร้อย', 'รับสินค้าเรียบร้อย'),
    ('กำลังขนส่ง', 'กำลังขนส่ง'),
    ('ถึงจุดส่งสินค้า', 'ถึงจุดส่งสินค้า'),
    ('จัดส่งสำเร็จ', 'จัดส่งสำเร็จ'),
  ];

  const _TimelineCard({required this.jobStatus, this.eta});

  @override
  Widget build(BuildContext context) {
    final currentIndex = _stages.indexWhere((s) => s.$1 == jobStatus);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          AppConfig.cardShadow,
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'สถานะการขนส่ง',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          ...List.generate(_stages.length, (i) {
            final isDone = i < currentIndex;
            final isActive = i == currentIndex;
            // subtitle: เสร็จแล้ว→เสร็จสิ้น, กำลังทำ→ETA/กำลังดำเนินการ, ยังไม่ถึง→รอดำเนินการ
            String subtitle;
            if (isDone) {
              subtitle = 'เสร็จสิ้น';
            } else if (isActive) {
              subtitle = (_stages[i].$1 == 'กำลังขนส่ง' && eta != null)
                  ? 'ถึงประมาณ $eta'
                  : 'กำลังดำเนินการ';
            } else {
              subtitle = 'รอดำเนินการ';
            }
            return _TimelineRow(
              label: _stages[i].$2,
              subtitle: subtitle,
              index: i + 1,
              isDone: isDone,
              isActive: isActive,
              isLast: i == _stages.length - 1,
            );
          }),
        ],
      ),
    );
  }
}

class _TimelineRow extends StatelessWidget {
  final String label;
  final String subtitle;
  final int index;
  final bool isDone;
  final bool isActive;
  final bool isLast;

  const _TimelineRow({
    required this.label,
    required this.subtitle,
    required this.index,
    required this.isDone,
    required this.isActive,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    final dotColor = isDone
        ? AppConfig.primaryColor
        : isActive
            ? AppConfig.primaryColor
            : const Color(0xFFE0E0E0);
    final textColor = isDone || isActive
        ? const Color(0xFF212121)
        : const Color(0xFFBDBDBD);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Dot + line column
          SizedBox(
            width: 24,
            child: Column(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: dotColor,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: isDone
                      ? const Icon(Icons.check, color: Colors.white, size: 14)
                      : isActive
                          ? const Text('🚛',
                              style: TextStyle(fontSize: 11))
                          : Text(
                              '$index',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold),
                            ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 2),
                      color: isDone
                          ? AppConfig.primaryColor
                          : const Color(0xFFE0E0E0),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight:
                          isActive ? FontWeight.w700 : FontWeight.w600,
                      color: isActive ? AppConfig.primaryColor : textColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: isActive
                          ? const Color(0xFF757575)
                          : const Color(0xFF9E9E9E),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── ETA Card ─────────────────────────────────────────────────────────────────

class _EtaCard extends StatelessWidget {
  final LocationTrackingModel? location;
  final int? distanceKm;

  const _EtaCard({this.location, this.distanceKm});

  String _formatTime(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')} น.';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppConfig.primaryColor, Color(0xFF1B5E20)],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'ถึงจุดหมายโดยประมาณ',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(height: 4),
                Text(
                  location != null
                      ? _formatTime(location!.timestamp)
                      : 'รอรับข้อมูล GPS',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text(
                'เหลืออีก',
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
              const SizedBox(height: 4),
              Text(
                distanceKm != null ? '$distanceKm กม.' : '-- กม.',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
      ),
    );
  }
}


