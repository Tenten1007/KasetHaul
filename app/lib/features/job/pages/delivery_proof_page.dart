import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/config/app_config.dart';
import '../../../core/repositories/repositories.dart';
import '../bloc/contractor_job_bloc.dart';
import '../bloc/contractor_job_event.dart';
import '../bloc/contractor_job_state.dart';

class DeliveryProofPage extends StatelessWidget {
  final String jobId;
  final String jobTitle;

  const DeliveryProofPage({
    super.key,
    required this.jobId,
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
      child: _DeliveryProofView(jobId: jobId, jobTitle: jobTitle),
    );
  }
}

class _DeliveryProofView extends StatefulWidget {
  final String jobId;
  final String jobTitle;
  const _DeliveryProofView({required this.jobId, required this.jobTitle});

  @override
  State<_DeliveryProofView> createState() => _DeliveryProofViewState();
}

class _DeliveryProofViewState extends State<_DeliveryProofView> {
  final _formKey = GlobalKey<FormState>();
  final _receiverCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  final List<File?> _photos = [null, null, null];
  bool _isLoading = false;

  // ลายเซ็นผู้รับสินค้า (ตาม SRS field receiverSignatureUrl + Mockup 07 จอ 4)
  final GlobalKey _sigBoundaryKey = GlobalKey();
  final List<Offset?> _sigStrokes = [];
  bool get _hasSignature => _sigStrokes.any((p) => p != null);

  /// แปลงลายเซ็นบนแคนวาสเป็นไฟล์ PNG เพื่ออัปโหลด
  Future<File?> _captureSignature() async {
    if (!_hasSignature) return null;
    try {
      final boundary = _sigBoundaryKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) return null;
      final image = await boundary.toImage(pixelRatio: 2.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return null;
      final bytes = byteData.buffer.asUint8List();
      final file = File(
        '${Directory.systemTemp.path}/signature_${DateTime.now().millisecondsSinceEpoch}.png',
      );
      await file.writeAsBytes(bytes);
      return file;
    } catch (_) {
      return null;
    }
  }

  /// แปลงพิกัดนิ้วบนจอ → พิกัดภายในกล่องลายเซ็น
  Offset? _toLocal(Offset global) {
    final box =
        _sigBoundaryKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return null;
    return box.globalToLocal(global);
  }

  static const _conditions = [
    'สมบูรณ์ ไม่มีความเสียหาย',
    'สภาพดี มีรอยขีดข่วนเล็กน้อย',
    'สภาพพอใช้ มีความเสียหายบางส่วน',
    'อื่นๆ (ระบุเพิ่มเติม)',
  ];
  String _selectedCondition = 'สมบูรณ์ ไม่มีความเสียหาย';
  final _conditionCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _conditionCtrl.text = _selectedCondition;
  }

  @override
  void dispose() {
    _conditionCtrl.dispose();
    _receiverCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto(int slot) async {
    final picker = ImagePicker();
    final xfile = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 75,
    );
    if (xfile != null) {
      setState(() => _photos[slot] = File(xfile.path));
    }
  }

  bool get _hasAtLeastOnePhoto => _photos.any((p) => p != null);

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_hasAtLeastOnePhoto) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('กรุณาถ่ายรูปหลักฐานการส่งมอบอย่างน้อย 1 รูป'),
          backgroundColor: AppConfig.errorColor,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final storage = StorageRepository();
      final List<String> uploadedUrls = [];
      for (int i = 0; i < _photos.length; i++) {
        final photo = _photos[i];
        if (photo != null) {
          final url = await storage.uploadFile(
            file: photo,
            path: 'delivery_proofs/${widget.jobId}/${DateTime.now().millisecondsSinceEpoch}_$i.jpg',
          );
          uploadedUrls.add(url);
        }
      }

      if (uploadedUrls.isEmpty) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      // อัปโหลดลายเซ็น (ถ้ามี)
      String? signatureUrl;
      final sigFile = await _captureSignature();
      if (sigFile != null) {
        signatureUrl = await storage.uploadFile(
          file: sigFile,
          path: 'delivery_proofs/${widget.jobId}/signature_${DateTime.now().millisecondsSinceEpoch}.png',
        );
      }

      if (mounted) {
        context.read<ContractorJobBloc>().add(
              UploadDeliveryProofEvent(
                jobId: widget.jobId,
                condition: _conditionCtrl.text.trim(),
                receiverName: _receiverCtrl.text.trim(),
                photoUrls: uploadedUrls,
                notes: _notesCtrl.text.trim().isEmpty
                    ? null
                    : _notesCtrl.text.trim(),
                signatureUrl: signatureUrl,
              ),
            );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('อัปโหลดรูปไม่สำเร็จ: $e'),
            backgroundColor: AppConfig.errorColor,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ContractorJobBloc, ContractorJobState>(
      listener: (context, state) {
        if (state is DeliveryProofUploaded) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('บันทึกหลักฐานส่งมอบสำเร็จ'),
              backgroundColor: AppConfig.primaryColor,
            ),
          );
          Navigator.of(context).pop(true);
        } else if (state is ContractorJobError) {
          setState(() => _isLoading = false);
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
          title: const Text('ยืนยันการส่งมอบ'),
          elevation: 0,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
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
                const SizedBox(height: 20),

                // 3-Photo grid
                _buildCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _Label(text: 'รูปหลักฐานการส่งมอบ *'),
                      const Text(
                        'ถ่ายได้สูงสุด 3 รูป (ต้องมีอย่างน้อย 1 รูป)',
                        style: TextStyle(fontSize: 12, color: Color(0xFF9E9E9E)),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: List.generate(3, (i) => _buildPhotoSlot(i)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Condition
                _buildCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _Label(text: 'สภาพสินค้าตอนส่งมอบ'),
                      DropdownButtonFormField<String>(
                        value: _selectedCondition,
                        decoration: _inputDeco(''),
                        items: _conditions
                            .map((c) => DropdownMenuItem(
                                value: c,
                                child: Text(c,
                                    style: const TextStyle(fontSize: 13))))
                            .toList(),
                        onChanged: (v) {
                          if (v != null) {
                            setState(() => _selectedCondition = v);
                            _conditionCtrl.text = v;
                          }
                        },
                      ),
                      if (_selectedCondition == 'อื่นๆ (ระบุเพิ่มเติม)') ...[
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _conditionCtrl,
                          decoration: _inputDeco('ระบุสภาพสินค้า...'),
                          validator: (v) => v == null || v.trim().isEmpty
                              ? 'กรุณาระบุสภาพสินค้า'
                              : null,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Receiver name
                _buildCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _Label(text: 'ชื่อผู้รับสินค้า *'),
                      TextFormField(
                        controller: _receiverCtrl,
                        decoration: _inputDeco('ชื่อ-นามสกุล ผู้รับ'),
                        validator: (v) => v == null || v.trim().isEmpty
                            ? 'กรุณากรอกชื่อผู้รับ'
                            : null,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Signature pad
                _buildCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const _Label(text: 'ลายเซ็นผู้รับสินค้า'),
                          if (_hasSignature)
                            GestureDetector(
                              onTap: () => setState(() => _sigStrokes.clear()),
                              child: const Row(
                                children: [
                                  Icon(Icons.refresh,
                                      size: 16, color: AppConfig.primaryColor),
                                  SizedBox(width: 2),
                                  Text('ล้าง',
                                      style: TextStyle(
                                          fontSize: 13,
                                          color: AppConfig.primaryColor)),
                                ],
                              ),
                            ),
                        ],
                      ),
                      RepaintBoundary(
                        key: _sigBoundaryKey,
                        child: Container(
                          height: 150,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _hasSignature
                                  ? AppConfig.primaryColor
                                  : const Color(0xFFBDBDBD),
                              width: _hasSignature ? 2 : 1,
                            ),
                          ),
                          child: GestureDetector(
                            onPanStart: (d) => setState(() => _sigStrokes
                                .add(_toLocal(d.globalPosition))),
                            onPanUpdate: (d) => setState(() => _sigStrokes
                                .add(_toLocal(d.globalPosition))),
                            onPanEnd: (_) =>
                                setState(() => _sigStrokes.add(null)),
                            child: CustomPaint(
                              painter: _SignaturePainter(_sigStrokes),
                              child: _hasSignature
                                  ? null
                                  : const Center(
                                      child: Text(
                                        '✍️ แตะเพื่อลงลายเซ็น',
                                        style: TextStyle(
                                            color: Color(0xFF9E9E9E),
                                            fontSize: 13),
                                      ),
                                    ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Notes textarea
                _buildCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _Label(text: 'หมายเหตุ (ถ้ามี)'),
                      TextFormField(
                        controller: _notesCtrl,
                        maxLines: 3,
                        decoration: _inputDeco('บันทึกเพิ่มเติม เช่น ปัญหาระหว่างส่งมอบ...'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                BlocBuilder<ContractorJobBloc, ContractorJobState>(
                  builder: (context, state) {
                    final loading = state is ContractorJobLoading || _isLoading;
                    return SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: loading ? null : _submit,
                        icon: loading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2.5),
                              )
                            : const Icon(Icons.check_circle_outline),
                        label: Text(
                          loading ? 'กำลังบันทึก...' : 'ยืนยันการส่งมอบ',
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
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPhotoSlot(int index) {
    final photo = _photos[index];
    return Expanded(
      child: GestureDetector(
        onTap: () => _pickPhoto(index),
        child: Container(
          height: 100,
          margin: EdgeInsets.only(right: index < 2 ? 8 : 0),
          decoration: BoxDecoration(
            color: AppConfig.surfaceColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: photo != null
                  ? AppConfig.primaryColor
                  : const Color(0xFFE0E0E0),
              width: photo != null ? 2 : 1,
            ),
          ),
          child: photo != null
              ? Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(9),
                      child: Image.file(photo,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity),
                    ),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: GestureDetector(
                        onTap: () => setState(() => _photos[index] = null),
                        child: Container(
                          width: 20,
                          height: 20,
                          decoration: const BoxDecoration(
                            color: Colors.black54,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.close,
                              size: 12, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_a_photo_outlined,
                        size: 28,
                        color: index == 0
                            ? AppConfig.primaryColor
                            : const Color(0xFFBDBDBD)),
                    const SizedBox(height: 4),
                    Text(
                      index == 0 ? 'รูปหลัก' : 'รูป ${index + 1}',
                      style: TextStyle(
                          fontSize: 11,
                          color: index == 0
                              ? AppConfig.primaryColor
                              : const Color(0xFFBDBDBD)),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  InputDecoration _inputDeco(String hint) => InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE0E0E0))),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE0E0E0))),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide:
                const BorderSide(color: AppConfig.primaryColor, width: 2)),
      );

  Widget _buildCard({required Widget child}) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
                color: Color(0x1A000000), blurRadius: 8, offset: Offset(0, 2))
          ],
        ),
        child: child,
      );
}

class _SignaturePainter extends CustomPainter {
  final List<Offset?> strokes;
  const _SignaturePainter(this.strokes);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF212121)
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    for (int i = 0; i < strokes.length - 1; i++) {
      final p1 = strokes[i];
      final p2 = strokes[i + 1];
      if (p1 != null && p2 != null) {
        canvas.drawLine(p1, p2, paint);
      } else if (p1 != null && p2 == null) {
        canvas.drawPoints(ui.PointMode.points, [p1], paint);
      }
    }
  }

  @override
  bool shouldRepaint(_SignaturePainter old) => old.strokes != strokes;
}

class _Label extends StatelessWidget {
  final String text;
  const _Label({required this.text});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text,
            style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF424242))),
      );
}


