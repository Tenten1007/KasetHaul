import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/config/app_config.dart';
import '../../../core/repositories/repositories.dart';
import '../../../core/services/thai_id_service.dart';

class VerifyIdentityPage extends StatefulWidget {
  final String contractorId;

  const VerifyIdentityPage({super.key, required this.contractorId});

  @override
  State<VerifyIdentityPage> createState() => _VerifyIdentityPageState();
}

class _VerifyIdentityPageState extends State<VerifyIdentityPage> {
  bool _isLoading = false;

  // QR countdown: 4:58 = 298 seconds
  static const _qrTotalSeconds = 298;
  int _qrSecondsLeft = _qrTotalSeconds;
  Timer? _qrTimer;

  final _thaiDAuth = createThaiDAuthService();

  @override
  void initState() {
    super.initState();
    _startQrTimer();
  }

  @override
  void dispose() {
    _qrTimer?.cancel();
    super.dispose();
  }

  void _startQrTimer() {
    _qrTimer?.cancel();
    setState(() => _qrSecondsLeft = _qrTotalSeconds);
    _qrTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      if (_qrSecondsLeft <= 0) {
        _qrTimer?.cancel();
        setState(() => _qrSecondsLeft = 0);
      } else {
        setState(() => _qrSecondsLeft--);
      }
    });
  }

  String get _qrTimerText {
    final m = _qrSecondsLeft ~/ 60;
    final s = _qrSecondsLeft % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  Future<void> _openThaiDApp() async {
    setState(() => _isLoading = true);
    try {
      final user = await _thaiDAuth.authenticate();
      if (mounted) {
        setState(() => _isLoading = false);
        // บันทึกผลยืนยันตัวตน
        await ContractorRepository().updateIdCardPhoto(
          widget.contractorId,
          'verified:${user.pid}',
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('ยืนยันตัวตนสำเร็จ'),
              backgroundColor: Color(0xFF4CAF50),
            ),
          );
          Navigator.of(context).pop(true);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('ยืนยันตัวตนไม่สำเร็จ: $e'),
            backgroundColor: AppConfig.errorColor,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        titleTextStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF212121)),
        foregroundColor: const Color(0xFF212121),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: const Text('ยืนยันตัวตน'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),

            // Icon circle
            Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                color: Color(0xFFE3F2FD),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: const Text('🪪', style: TextStyle(fontSize: 36)),
            ),
            const SizedBox(height: 16),

            // Title
            const Text(
              'ยืนยันตัวตนด้วย Thai ID',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Color(0xFF212121),
              ),
            ),
            const SizedBox(height: 8),

            // Subtitle
            const Text(
              'กรุณายืนยันตัวตนเพื่อเริ่มรับงานขนส่ง\nข้อมูลของคุณจะถูกเก็บรักษาอย่างปลอดภัย',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Color(0xFF757575), height: 1.5),
            ),
            const SizedBox(height: 24),

            // ThaID Logo badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF1565C0), Color(0xFF0D47A1)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.all(Radius.circular(16)),
              ),
              child: const Text(
                'ThaID',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // QR Code card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppConfig.surfaceColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  const Text(
                    'สแกน QR Code ด้วยแอป ThaID',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF424242),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // QR placeholder
                  Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE0E0E0), width: 2),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: CustomPaint(
                        painter: _QrPatternPainter(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Timer
                  RichText(
                    text: TextSpan(
                      text: 'หมดอายุใน ',
                      style: const TextStyle(fontSize: 12, color: Color(0xFF757575)),
                      children: [
                        TextSpan(
                          text: _qrSecondsLeft > 0 ? _qrTimerText : 'หมดอายุแล้ว',
                          style: const TextStyle(
                            color: Color(0xFFF44336),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_qrSecondsLeft == 0) ...[
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: _startQrTimer,
                      child: const Text('สร้าง QR ใหม่'),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),

            // How to use
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFE3F2FD),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '📱 วิธีใช้งาน',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1565C0),
                    ),
                  ),
                  SizedBox(height: 8),
                  _StepItem(number: 1, text: 'เปิดแอป ThaID บนโทรศัพท์'),
                  _StepItem(number: 2, text: 'กดปุ่ม "สแกน QR Code"'),
                  _StepItem(number: 3, text: 'สแกน QR Code ด้านบน'),
                  _StepItem(number: 4, text: 'ยืนยันข้อมูลในแอป ThaID'),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Divider "หรือ"
            const Row(
              children: [
                Expanded(child: Divider()),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Text('หรือ', style: TextStyle(color: Color(0xFF9E9E9E))),
                ),
                Expanded(child: Divider()),
              ],
            ),
            const SizedBox(height: 24),

            // Open ThaID app button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _openThaiDApp,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1565C0),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2.5),
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('📱', style: TextStyle(fontSize: 20)),
                          SizedBox(width: 8),
                          Text(
                            'เปิดแอป ThaID',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 16),

            // Notice card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3E0),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                '💡 ยังไม่มีแอป ThaID? ดาวน์โหลดได้ที่ App Store หรือ Google Play และลงทะเบียนที่สำนักงานเขตหรือท้องถิ่นใกล้บ้าน',
                style: TextStyle(fontSize: 12, color: Color(0xFFE65100), height: 1.5),
              ),
            ),
            const SizedBox(height: 16),

            // Skip button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton(
                onPressed: () => Navigator.of(context).pop(false),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF424242),
                  side: const BorderSide(color: Color(0xFFBDBDBD)),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text(
                  'ข้ามไปก่อน (รับงานไม่ได้)',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _StepItem extends StatelessWidget {
  final int number;
  final String text;
  const _StepItem({required this.number, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$number. ',
            style: const TextStyle(fontSize: 12, color: Color(0xFF424242)),
          ),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 12, color: Color(0xFF424242)),
            ),
          ),
        ],
      ),
    );
  }
}

// QR code visual placeholder using CustomPainter
class _QrPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.black;
    const block = 10.0;

    // Corner squares (3 finder patterns)
    _drawFinderPattern(canvas, paint, 4, 4, block);
    _drawFinderPattern(canvas, paint, size.width - 4 - 7 * block, 4, block);
    _drawFinderPattern(canvas, paint, 4, size.height - 4 - 7 * block, block);

    // Scattered data blocks (visual only)
    final positions = [
      [9, 9], [11, 9], [12, 10], [9, 12], [10, 13],
      [13, 9], [14, 10], [13, 12], [15, 11], [12, 14],
      [9, 15], [11, 16], [14, 14], [15, 15], [16, 12],
      [10, 16], [13, 16], [16, 16],
    ];
    for (final p in positions) {
      canvas.drawRect(
        Rect.fromLTWH(
            p[0] * block.toDouble(), p[1] * block.toDouble(), block - 1, block - 1),
        paint,
      );
    }
  }

  void _drawFinderPattern(Canvas canvas, Paint paint, double x, double y, double b) {
    // Outer 7x7 black
    canvas.drawRect(Rect.fromLTWH(x, y, 7 * b, 7 * b), paint);
    // Inner 5x5 white
    final white = Paint()..color = Colors.white;
    canvas.drawRect(Rect.fromLTWH(x + b, y + b, 5 * b, 5 * b), white);
    // Center 3x3 black
    canvas.drawRect(Rect.fromLTWH(x + 2 * b, y + 2 * b, 3 * b, 3 * b), paint);
  }

  @override
  bool shouldRepaint(_QrPatternPainter old) => false;
}


