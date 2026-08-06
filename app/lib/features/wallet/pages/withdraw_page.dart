import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/config/app_config.dart';
import '../../../core/repositories/repositories.dart';
import '../../job/bloc/contractor_job_bloc.dart';
import '../../job/bloc/contractor_job_event.dart';
import '../../job/bloc/contractor_job_state.dart';

class WithdrawPage extends StatelessWidget {
  final String contractorId;
  final double currentBalance;

  const WithdrawPage({
    super.key,
    required this.contractorId,
    required this.currentBalance,
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
      child: _WithdrawView(
        contractorId: contractorId,
        currentBalance: currentBalance,
      ),
    );
  }
}

class _WithdrawView extends StatefulWidget {
  final String contractorId;
  final double currentBalance;
  const _WithdrawView(
      {required this.contractorId, required this.currentBalance});

  @override
  State<_WithdrawView> createState() => _WithdrawViewState();
}

class _WithdrawViewState extends State<_WithdrawView> {
  final _formKey = GlobalKey<FormState>();
  final _amountCtrl = TextEditingController();
  final _bankNameCtrl = TextEditingController();
  final _accountNumberCtrl = TextEditingController();
  final _accountNameCtrl = TextEditingController();

  static const _banks = [
    'ธนาคารกสิกรไทย (KBank)',
    'ธนาคารไทยพาณิชย์ (SCB)',
    'ธนาคารกรุงเทพ (BBL)',
    'ธนาคารกรุงไทย (KTB)',
    'ธนาคารกรุงศรีอยุธยา (BAY)',
    'ธนาคารออมสิน (GSB)',
    'ธนาคารทหารไทยธนชาต (TTB)',
    'ธนาคารเกียรตินาคินภัทร (KKP)',
  ];

  String _selectedBank = 'ธนาคารกสิกรไทย (KBank)';
  bool _setAsDefault = false;

  @override
  void dispose() {
    _amountCtrl.dispose();
    _bankNameCtrl.dispose();
    _accountNumberCtrl.dispose();
    _accountNameCtrl.dispose();
    super.dispose();
  }

  String _formatBalance(double amount) {
    return amount
        .toStringAsFixed(2)
        .replaceAllMapped(
            RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ContractorJobBloc, ContractorJobState>(
      listener: (context, state) {
        if (state is WithdrawnState) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('ถอนเงินสำเร็จ'),
              backgroundColor: AppConfig.primaryColor,
            ),
          );
          Navigator.of(context).pop(true);
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
          title: const Text('ถอนเงิน'),
          elevation: 0,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ยอดเงินคงเหลือ
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppConfig.primaryColor,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'ยอดเงินคงเหลือ',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '฿${_formatBalance(widget.currentBalance)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                _buildCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _Label(text: 'จำนวนเงินที่ต้องการถอน (บาท)'),
                      TextFormField(
                        controller: _amountCtrl,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                              RegExp(r'^\d+\.?\d{0,2}')),
                        ],
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: AppConfig.primaryColor,
                        ),
                        decoration: InputDecoration(
                          hintText: '0.00',
                          suffixText: 'บาท',
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide:
                                const BorderSide(color: Color(0xFFE0E0E0)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide:
                                const BorderSide(color: Color(0xFFE0E0E0)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                                color: AppConfig.primaryColor, width: 2),
                          ),
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) {
                            return 'กรุณากรอกจำนวนเงิน';
                          }
                          final amount = double.tryParse(v);
                          if (amount == null || amount <= 0) {
                            return 'จำนวนเงินต้องมากกว่า 0';
                          }
                          if (amount > widget.currentBalance) {
                            return 'ยอดเงินไม่เพียงพอ (มี ฿${_formatBalance(widget.currentBalance)})';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                _buildCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _Label(text: 'ธนาคาร'),
                      DropdownButtonFormField<String>(
                        value: _selectedBank,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide:
                                const BorderSide(color: Color(0xFFE0E0E0)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide:
                                const BorderSide(color: Color(0xFFE0E0E0)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                                color: AppConfig.primaryColor, width: 2),
                          ),
                        ),
                        items: _banks
                            .map((b) =>
                                DropdownMenuItem(value: b, child: Text(b)))
                            .toList(),
                        onChanged: (v) {
                          if (v != null) setState(() => _selectedBank = v);
                        },
                      ),
                      const SizedBox(height: 16),
                      const _Label(text: 'เลขบัญชี'),
                      TextFormField(
                        controller: _accountNumberCtrl,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(15),
                        ],
                        decoration: _inputDecoration('เช่น 1234567890'),
                        validator: (v) {
                          if (v == null || v.length < 10) {
                            return 'กรุณากรอกเลขบัญชีที่ถูกต้อง';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      const _Label(text: 'ชื่อบัญชี'),
                      TextFormField(
                        controller: _accountNameCtrl,
                        decoration: _inputDecoration('ชื่อ-นามสกุล เจ้าของบัญชี'),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'กรุณากรอกชื่อบัญชี';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 4),
                      // ตั้งเป็นบัญชีหลัก (UC 3.1.33)
                      Padding(
                        padding: EdgeInsets.zero,
                        child: Row(
                          children: [
                            Checkbox(
                              value: _setAsDefault,
                              activeColor: AppConfig.primaryColor,
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                              onChanged: (v) =>
                                  setState(() => _setAsDefault = v ?? false),
                            ),
                            const Expanded(
                              child: Text('ตั้งเป็นบัญชีหลัก',
                                  style: TextStyle(
                                      fontSize: 14, color: Color(0xFF424242))),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // ===== Fee breakdown card =====
                StatefulBuilder(
                  builder: (ctx, _) {
                    final raw = double.tryParse(_amountCtrl.text.trim()) ?? 0.0;
                    final received = raw;
                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F8E9),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFF8BC34A)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('สรุปการถอนเงิน',
                              style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF33691E))),
                          const SizedBox(height: 10),
                          _SummaryRow(
                            label: 'จำนวนที่ถอน',
                            value: '฿${_formatBalance(raw)}',
                          ),
                          const SizedBox(height: 4),
                          _SummaryRow(
                            label: 'ค่าธรรมเนียม',
                            value: 'ฟรี',
                            valueColor: const Color(0xFF2E7D32),
                          ),
                          const Divider(height: 16, color: Color(0xFFA5D6A7)),
                          _SummaryRow(
                            label: 'ยอดที่จะได้รับ',
                            value: '฿${_formatBalance(received)}',
                            bold: true,
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),

                // ===== Bank account preview card =====
                StatefulBuilder(
                  builder: (ctx, _) {
                    final accountNum = _accountNumberCtrl.text.trim();
                    final accountName = _accountNameCtrl.text.trim();
                    final masked = accountNum.length >= 4
                        ? '${'*' * (accountNum.length - 4)}${accountNum.substring(accountNum.length - 4)}'
                        : accountNum;
                    final initials = accountName.isNotEmpty
                        ? accountName.characters.first.toUpperCase()
                        : '?';

                    if (accountNum.isEmpty && accountName.isEmpty) {
                      return const SizedBox.shrink();
                    }

                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFE0E0E0)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: AppConfig.secondaryColor,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(initials,
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold)),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(accountName.isEmpty ? 'ชื่อบัญชี' : accountName,
                                    style: const TextStyle(
                                        fontSize: 14, fontWeight: FontWeight.w600)),
                                const SizedBox(height: 2),
                                Text(_selectedBank,
                                    style: const TextStyle(
                                        fontSize: 12, color: Color(0xFF757575))),
                                if (accountNum.isNotEmpty)
                                  Text(masked,
                                      style: const TextStyle(
                                          fontSize: 12, color: Color(0xFF9E9E9E))),
                              ],
                            ),
                          ),
                          const Icon(Icons.check_circle,
                              color: AppConfig.primaryColor, size: 20),
                        ],
                      ),
                    );
                  },
                ),

                const SizedBox(height: 24),

                BlocBuilder<ContractorJobBloc, ContractorJobState>(
                  builder: (context, state) {
                    final isLoading = state is ContractorJobLoading;
                    return SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: isLoading
                            ? null
                            : () {
                                if (_formKey.currentState!.validate()) {
                                  context.read<ContractorJobBloc>().add(
                                        WithdrawEvent(
                                          contractorId: widget.contractorId,
                                          amount: double.parse(
                                              _amountCtrl.text.trim()),
                                          bankName: _selectedBank,
                                          accountNumber:
                                              _accountNumberCtrl.text.trim(),
                                          accountName:
                                              _accountNameCtrl.text.trim(),
                                          isDefault: _setAsDefault,
                                        ),
                                      );
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppConfig.primaryColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                        child: isLoading
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2.5),
                              )
                            : const Text('ยืนยันการถอนเงิน',
                                style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600)),
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

  InputDecoration _inputDecoration(String hint) => InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: AppConfig.primaryColor, width: 2),
        ),
      );

  Widget _buildCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
              color: Color(0x1A000000), blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: child,
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text,
          style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF424242))),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final bool bold;

  const _SummaryRow({
    required this.label,
    required this.value,
    this.valueColor,
    this.bold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: TextStyle(
                fontSize: 13,
                color: const Color(0xFF616161),
                fontWeight: bold ? FontWeight.w600 : FontWeight.normal)),
        Text(value,
            style: TextStyle(
                fontSize: bold ? 15 : 13,
                color: valueColor ?? const Color(0xFF212121),
                fontWeight: bold ? FontWeight.bold : FontWeight.w500)),
      ],
    );
  }
}


