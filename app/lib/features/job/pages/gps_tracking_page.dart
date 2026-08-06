import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../core/config/app_config.dart';
import '../../../core/repositories/repositories.dart';
import '../bloc/contractor_job_bloc.dart';
import '../bloc/contractor_job_event.dart';
import '../bloc/contractor_job_state.dart';

class GpsTrackingPage extends StatelessWidget {
  final String jobId;
  final String truckId;
  final String jobTitle;

  const GpsTrackingPage({
    super.key,
    required this.jobId,
    required this.truckId,
    required this.jobTitle,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ContractorJobBloc(
        jobRepository: JobRepository(),
        biddingRepository: BiddingRepository(),
        transactionRepository: TransactionRepository(),
        contractorRepository: ContractorRepository(),
      ),
      child: _GpsTrackingView(jobId: jobId, truckId: truckId, jobTitle: jobTitle),
    );
  }
}

class _GpsTrackingView extends StatefulWidget {
  final String jobId;
  final String truckId;
  final String jobTitle;

  const _GpsTrackingView({
    required this.jobId,
    required this.truckId,
    required this.jobTitle,
  });

  @override
  State<_GpsTrackingView> createState() => _GpsTrackingViewState();
}

class _GpsTrackingViewState extends State<_GpsTrackingView> {
  Position? _lastPosition;
  DateTime? _lastUpdateTime;
  String _statusText = 'กำลังเริ่มติดตามตำแหน่งอัตโนมัติ...';
  bool _isGettingLocation = false;
  GoogleMapController? _mapController;

  // อัปเดตตำแหน่งอัตโนมัติทุก 20 วินาที (UC 3.1.13)
  static const _autoInterval = Duration(seconds: 20);
  Timer? _autoTimer;

  @override
  void initState() {
    super.initState();
    // ดึงตำแหน่งครั้งแรกทันที แล้วตั้ง timer อัปเดตซ้ำอัตโนมัติ
    _updateLocation();
    _autoTimer =
        Timer.periodic(_autoInterval, (_) => _updateLocation(silent: true));
  }

  @override
  void dispose() {
    _autoTimer?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  Future<bool> _checkPermission() async {
    LocationPermission perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    if (perm == LocationPermission.deniedForever) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text('ต้องการสิทธิ์ตำแหน่ง'),
            content: const Text(
              'แอปถูกปฏิเสธสิทธิ์ตำแหน่งถาวร\nกรุณาไปที่การตั้งค่าเพื่อเปิดใช้งาน',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('ยกเลิก',
                    style: TextStyle(color: Color(0xFF757575))),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppConfig.primaryColor,
                  foregroundColor: Colors.white,
                ),
                onPressed: () {
                  Navigator.pop(ctx);
                  Geolocator.openAppSettings();
                },
                child: const Text('ไปที่การตั้งค่า'),
              ),
            ],
          ),
        );
      }
      return false;
    }
    return perm == LocationPermission.always ||
        perm == LocationPermission.whileInUse;
  }

  Future<void> _updateLocation({bool silent = false}) async {
    if (_isGettingLocation) return;
    setState(() {
      _isGettingLocation = true;
      _statusText = 'กำลังหาตำแหน่ง...';
    });

    final hasPermission = await _checkPermission();
    if (!hasPermission) {
      setState(() {
        _isGettingLocation = false;
        _statusText = 'ไม่ได้รับสิทธิ์เข้าถึงตำแหน่ง';
      });
      return;
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );

      if (mounted) {
        setState(() {
          _lastPosition = position;
          _lastUpdateTime = DateTime.now();
          _isGettingLocation = false;
          _statusText = 'อัปเดตตำแหน่งสำเร็จ';
        });

        _mapController?.animateCamera(
          CameraUpdate.newLatLng(LatLng(position.latitude, position.longitude)),
        );

        context.read<ContractorJobBloc>().add(
              UpdateLocationEvent(
                jobId: widget.jobId,
                truckId: widget.truckId,
                lat: position.latitude,
                lng: position.longitude,
              ),
            );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isGettingLocation = false;
          _statusText = 'ไม่สามารถหาตำแหน่งได้';
        });
        if (!silent) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('เกิดข้อผิดพลาด: $e'),
              backgroundColor: AppConfig.errorColor,
            ),
          );
        }
      }
    }
  }

  String _formatTime(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}:${dt.second.toString().padLeft(2, '0')} น.';
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ContractorJobBloc, ContractorJobState>(
      listener: (context, state) {
        if (state is LocationUpdated) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('ส่งตำแหน่งไปยังระบบสำเร็จ'),
              backgroundColor: AppConfig.primaryColor,
            ),
          );
        } else if (state is ContractorJobError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppConfig.errorColor,
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor: AppConfig.surfaceColor,
        appBar: AppBar(
          backgroundColor: AppConfig.primaryColor,
          foregroundColor: Colors.white,
          title: const Text('ติดตาม GPS'),
          elevation: 0,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Job banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppConfig.primaryColor),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.local_shipping,
                        color: AppConfig.primaryColor),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        widget.jobTitle,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Mini-map แสดงตำแหน่งปัจจุบัน
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: SizedBox(
                  height: 220,
                  child: _lastPosition != null
                      ? GoogleMap(
                          initialCameraPosition: CameraPosition(
                            target: LatLng(
                              _lastPosition!.latitude,
                              _lastPosition!.longitude,
                            ),
                            zoom: 15.0,
                          ),
                          markers: {
                            Marker(
                              markerId: const MarkerId('me'),
                              position: LatLng(
                                _lastPosition!.latitude,
                                _lastPosition!.longitude,
                              ),
                              infoWindow: const InfoWindow(title: '🚛 ตำแหน่งของฉัน'),
                              icon: BitmapDescriptor.defaultMarkerWithHue(
                                  BitmapDescriptor.hueGreen),
                            ),
                          },
                          myLocationButtonEnabled: false,
                          zoomControlsEnabled: false,
                          mapToolbarEnabled: false,
                          onMapCreated: (c) => _mapController = c,
                        )
                      : Container(
                          color: AppConfig.surfaceColor,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.map_outlined,
                                  size: 56, color: const Color(0xFFBDBDBD)),
                              const SizedBox(height: 8),
                              const Text(
                                'กดอัปเดตตำแหน่งเพื่อแสดงแผนที่',
                                style: TextStyle(
                                    fontSize: 13, color: Color(0xFF9E9E9E)),
                              ),
                            ],
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 12),

              // Status + accuracy row
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _lastPosition != null
                        ? Icons.gps_fixed
                        : Icons.gps_not_fixed,
                    size: 16,
                    color: _lastPosition != null
                        ? AppConfig.primaryColor
                        : const Color(0xFF9E9E9E),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _statusText,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: _lastPosition != null
                          ? AppConfig.primaryColor
                          : const Color(0xFF757575),
                    ),
                  ),
                  if (_lastPosition != null) ...[
                    const Text(' • ',
                        style: TextStyle(color: Color(0xFF9E9E9E))),
                    Text(
                      '±${_lastPosition!.accuracy.toStringAsFixed(0)} ม.',
                      style: const TextStyle(
                          fontSize: 13, color: Color(0xFF9E9E9E)),
                    ),
                  ],
                ],
              ),
              if (_lastUpdateTime != null) ...[
                const SizedBox(height: 4),
                Text(
                  'อัปเดต ${_formatTime(_lastUpdateTime!)}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 12, color: Color(0xFF9E9E9E)),
                ),
              ],
              const SizedBox(height: 20),

              // Update button
              BlocBuilder<ContractorJobBloc, ContractorJobState>(
                builder: (context, state) {
                  final isSending = state is ContractorJobLoading;
                  final isLoading = _isGettingLocation || isSending;
                  return SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: isLoading ? null : _updateLocation,
                      icon: isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2.5),
                            )
                          : const Icon(Icons.gps_fixed),
                      label: Text(
                        isLoading ? 'กำลังอัปเดต...' : 'อัปเดตตำแหน่งปัจจุบัน',
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppConfig.primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
              const Text(
                'ตำแหน่งของคุณจะถูกส่งให้ผู้ว่าจ้างเพื่อติดตามสถานะการขนส่ง',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Color(0xFF9E9E9E)),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}



