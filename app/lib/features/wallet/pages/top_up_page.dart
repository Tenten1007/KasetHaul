import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/config/app_config.dart';
import '../../../core/repositories/repositories.dart';
import '../bloc/wallet_bloc.dart';
import '../bloc/wallet_event.dart';
import '../bloc/wallet_state.dart';

class TopUpPage extends StatefulWidget {
  final String clientId;
  const TopUpPage({super.key, required this.clientId});

  @override
  State<TopUpPage> createState() => _TopUpPageState();
}

class _TopUpPageState extends State<TopUpPage> {
  int _step = 1; // 1 = enter amount, 2 = bank transfer details + slip upload
  final _amountCtrl = TextEditingController();
  double _amount = 0;
  File? _slipPhoto;
  bool _isUploading = false;

  Future<void> _pickSlip() async {
    final picker = ImagePicker();
    final xfile = await picker.pickImage(
        source: ImageSource.gallery, imageQuality: 85);
    if (xfile != null) setState(() => _slipPhoto = File(xfile.path));
  }

  static const String _bankName = 'ธนาคารกสิกรไทย';
  static const String _accountNumber = '123-4-56789-0';
  static const String _accountName = 'บจก. เกษตรฮอล';

  String get _refNo {
    final now = DateTime.now();
    return 'DEP${now.year - 543}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}${now.hour.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<WalletBloc, WalletState>(
      listener: (context, state) {
        if (state is TopUpSuccess) {
          _showSuccessDialog(context, state.newBalance);
        } else if (state is WalletError) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(state.message)));
        }
      },
      builder: (context, state) {
        return Scaffold(
          backgroundColor: AppConfig.surfaceColor,
          appBar: AppBar(
            backgroundColor: AppConfig.primaryColor,
            foregroundColor: Colors.white,
            title: Text(_step == 1 ? 'เติมเงิน' : 'โอนผ่านธนาคาร'),
            elevation: 0,
          ),
          body: _step == 1 ? _buildStep1(context) : _buildStep2(context, state),
        );
      },
    );
  }

  Widget _buildStep1(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          Center(
            child: Column(
              children: [
                const Text(
                  'ระบุจำนวนเงินที่ต้องการเติม',
                  style: TextStyle(color: Color(0xFF757575)),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      '฿',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: AppConfig.primaryColor,
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 200,
                      child: TextField(
                        key: const Key('field_amount'),
                        controller: _amountCtrl,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: AppConfig.primaryColor,
                        ),
                        decoration: const InputDecoration(
                          hintText: '0.00',
                          hintStyle: TextStyle(color: Color(0xFFBDBDBD), fontSize: 32),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(12)),
                          ),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                        ),
                        onChanged: (v) {
                          setState(() {
                            _amount = double.tryParse(v) ?? 0;
                          });
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'ขั้นต่ำ ฿100 | สูงสุด ฿100,000',
                  style: TextStyle(fontSize: 13, color: Color(0xFF757575)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          const Text(
            'ช่องทางการชำระเงิน',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF424242)),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppConfig.primaryColor, width: 2),
              boxShadow: const [
                BoxShadow(color: Color(0x1A000000), blurRadius: 8, offset: Offset(0, 2)),
              ],
            ),
            child: Row(
              children: [
                const Text('🏦', style: TextStyle(fontSize: 32)),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('โอนผ่านธนาคาร',
                          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                      Text('ฟรีค่าธรรมเนียม',
                          style: TextStyle(fontSize: 13, color: Color(0xFF757575))),
                    ],
                  ),
                ),
                const Text('✓',
                    style: TextStyle(color: AppConfig.primaryColor, fontSize: 20)),
              ],
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              key: const Key('btn_next_step'),
              onPressed: _amount >= 100 && _amount <= 100000
                  ? () => setState(() => _step = 2)
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConfig.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('ดำเนินการเติมเงิน', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep2(BuildContext context, WalletState state) {
    final refNo = _refNo;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Amount summary
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppConfig.surfaceColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('จำนวนที่ต้องโอน',
                    style: TextStyle(color: Color(0xFF757575))),
                Text(
                  '฿${_amount.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppConfig.primaryColor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Bank account
          const Text(
            'โอนเงินไปยังบัญชี',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF424242)),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(color: Color(0x1A000000), blurRadius: 8, offset: Offset(0, 2)),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 48, height: 48,
                      decoration: BoxDecoration(
                        color: AppConfig.primaryColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      alignment: Alignment.center,
                      child: const Text('K',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20)),
                    ),
                    const SizedBox(width: 12),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_bankName, style: TextStyle(fontWeight: FontWeight.w600)),
                        Text('บัญชีออมทรัพย์',
                            style: TextStyle(fontSize: 13, color: Color(0xFF757575))),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _CopyRow(label: 'เลขบัญชี', value: _accountNumber),
                const SizedBox(height: 8),
                _CopyRow(label: 'ชื่อบัญชี', value: _accountName),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Reference No
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF3E0),
              border: Border.all(color: AppConfig.secondaryColor),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Text('⚠️', style: TextStyle(fontSize: 24)),
                    SizedBox(width: 8),
                    Text('สำคัญ: ระบุรหัสอ้างอิง',
                        style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFFE65100))),
                  ],
                ),
                const SizedBox(height: 4),
                const Text(
                  'กรุณาใส่รหัสนี้ในช่องหมายเหตุการโอน',
                  style: TextStyle(fontSize: 13, color: Color(0xFF757575)),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        refNo,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('คัดลอกรหัสแล้ว')),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppConfig.secondaryColor,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text('คัดลอก',
                              style: TextStyle(color: Colors.white, fontSize: 12)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Slip upload
          const Text(
            'แนบหลักฐานการโอนเงิน',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF424242)),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: _pickSlip,
            child: Container(
              width: double.infinity,
              height: 160,
              decoration: BoxDecoration(
                color: AppConfig.surfaceColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _slipPhoto != null ? AppConfig.primaryColor : const Color(0xFFE0E0E0),
                  width: _slipPhoto != null ? 2 : 1,
                ),
              ),
              child: _slipPhoto != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(11),
                      child: Image.file(_slipPhoto!, fit: BoxFit.cover),
                    )
                  : const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.upload_file_outlined, size: 40, color: Color(0xFF9E9E9E)),
                        SizedBox(height: 6),
                        Text('กดเพื่อเลือกสลิปการโอน',
                            style: TextStyle(color: Color(0xFF9E9E9E))),
                      ],
                    ),
            ),
          ),
          if (_slipPhoto != null) ...[
            const SizedBox(height: 4),
            TextButton.icon(
              onPressed: _pickSlip,
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('เปลี่ยนสลิป'),
              style: TextButton.styleFrom(foregroundColor: AppConfig.primaryColor),
            ),
          ],
          const SizedBox(height: 24),

          // Confirm button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: (state is WalletLoading || _isUploading || _slipPhoto == null)
                  ? null
                  : () async {
                      setState(() => _isUploading = true);
                      final bloc = context.read<WalletBloc>();
                      final messenger = ScaffoldMessenger.of(context);
                      try {
                        final storage = StorageRepository();
                        final slipUrl = await storage.uploadFile(
                          file: _slipPhoto!,
                          path: 'payment_slips/${widget.clientId}/${DateTime.now().millisecondsSinceEpoch}.jpg',
                        );
                        if (mounted) {
                          bloc.add(TopUpEvent(
                            clientId: widget.clientId,
                            amount: _amount,
                            bankName: _bankName,
                            accountNumber: _accountNumber,
                            accountName: _accountName,
                            referenceNo: refNo,
                            slipUrl: slipUrl,
                          ));
                        }
                      } catch (_) {
                        messenger.showSnackBar(
                          const SnackBar(content: Text('อัปโหลดสลิปไม่สำเร็จ')),
                        );
                      } finally {
                        if (mounted) setState(() => _isUploading = false);
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConfig.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: (state is WalletLoading || _isUploading)
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : Text(
                      _slipPhoto == null ? 'กรุณาแนบสลิปก่อน' : 'ยืนยันการโอนเงิน',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog(BuildContext context, double newBalance) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: const BoxDecoration(
                color: Color(0xFFE8F5E9),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: const Text('✓', style: TextStyle(fontSize: 48, color: AppConfig.primaryColor)),
            ),
            const SizedBox(height: 24),
            const Text('เติมเงินสำเร็จ!',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('ยอดเงินได้รับการอัพเดทเรียบร้อยแล้ว',
                style: TextStyle(color: Color(0xFF757575))),
            const SizedBox(height: 16),
            Text(
              'ยอดเงินคงเหลือใหม่\n฿${newBalance.toStringAsFixed(2)}',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppConfig.primaryColor,
              ),
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(context)
                  ..pop()  // close dialog
                  ..pop(); // back to wallet page
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConfig.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('กลับหน้ากระเป๋าเงิน'),
            ),
          ),
        ],
      ),
    );
  }
}

class _CopyRow extends StatelessWidget {
  final String label;
  final String value;
  const _CopyRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppConfig.surfaceColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(fontSize: 12, color: Color(0xFF757575))),
                Text(value,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1)),
              ],
            ),
          ),
          GestureDetector(
            onTap: () {
              ScaffoldMessenger.of(context)
                  .showSnackBar(const SnackBar(content: Text('คัดลอกแล้ว')));
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppConfig.primaryColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text('คัดลอก',
                  style: TextStyle(color: Colors.white, fontSize: 13)),
            ),
          ),
        ],
      ),
    );
  }
}


