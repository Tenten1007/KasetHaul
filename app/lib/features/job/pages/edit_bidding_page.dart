import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/config/app_config.dart';
import '../../../core/repositories/repositories.dart';
import '../../../models/models.dart';
import '../bloc/contractor_bid_bloc.dart';
import '../bloc/contractor_bid_event.dart';
import '../bloc/contractor_bid_state.dart';

class EditBiddingPage extends StatelessWidget {
  final BiddingModel bidding;

  const EditBiddingPage({super.key, required this.bidding});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ContractorBidBloc(
        jobRepository: JobRepository(),
        biddingRepository: BiddingRepository(),
      ),
      child: _EditBiddingView(bidding: bidding),
    );
  }
}

class _EditBiddingView extends StatefulWidget {
  final BiddingModel bidding;
  const _EditBiddingView({required this.bidding});

  @override
  State<_EditBiddingView> createState() => _EditBiddingViewState();
}

class _EditBiddingViewState extends State<_EditBiddingView> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _priceCtrl;
  late final TextEditingController _noteCtrl;

  @override
  void initState() {
    super.initState();
    _priceCtrl =
        TextEditingController(text: widget.bidding.bidPrice.toString());
    _noteCtrl =
        TextEditingController(text: widget.bidding.messageToClient ?? '');
  }

  @override
  void dispose() {
    _priceCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  String _formatPrice(int price) => price
      .toString()
      .replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');

  @override
  Widget build(BuildContext context) {
    return BlocListener<ContractorBidBloc, ContractorBidState>(
      listener: (context, state) {
        if (state is BidUpdated) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('แก้ไขการเสนอราคาสำเร็จ'),
              backgroundColor: AppConfig.primaryColor,
            ),
          );
          Navigator.of(context).pop(true);
        } else if (state is ContractorBidError) {
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
          title: const Text('แก้ไขการเสนอราคา'),
          elevation: 0,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ===== ราคาเดิม card =====
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: const [
                      BoxShadow(color: Color(0x1A000000), blurRadius: 8, offset: Offset(0, 2)),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('ราคาที่เสนอเดิม',
                          style: TextStyle(fontSize: 12, color: Color(0xFF9E9E9E))),
                      const SizedBox(height: 4),
                      Text(
                        '฿${_formatPrice(widget.bidding.bidPrice)}',
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF424242),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE3F2FD),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'สถานะ: ${widget.bidding.biddingStatus}',
                          style: const TextStyle(fontSize: 12, color: Color(0xFF1565C0)),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // ===== status note =====
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF8E1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFFFCC02)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline, size: 16, color: Color(0xFFF57F17)),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'แก้ไขได้เฉพาะการเสนอที่ยัง "รอการตอบรับ" เท่านั้น',
                          style: TextStyle(fontSize: 12, color: Color(0xFFF57F17)),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                const _Label(text: 'ราคาที่เสนอใหม่'),
                TextFormField(
                  controller: _priceCtrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: AppConfig.primaryColor,
                  ),
                  decoration: InputDecoration(
                    suffixText: 'บาท',
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
                      borderSide: const BorderSide(
                          color: AppConfig.primaryColor, width: 2),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'กรุณากรอกราคา';
                    final price = int.tryParse(v);
                    if (price == null || price <= 0) return 'ราคาต้องมากกว่า 0';
                    return null;
                  },
                  onChanged: (_) => setState(() {}),
                ),

                // ===== Price comparison =====
                const SizedBox(height: 12),
                StatefulBuilder(
                  builder: (context, _) {
                    final newPrice = int.tryParse(_priceCtrl.text.trim()) ?? 0;
                    final oldPrice = widget.bidding.bidPrice;
                    final diff = newPrice - oldPrice;
                    final pct = oldPrice > 0 ? (diff / oldPrice * 100) : 0.0;
                    final isHigher = diff > 0;
                    final isSame = diff == 0;

                    return Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isSame
                            ? AppConfig.surfaceColor
                            : isHigher
                                ? const Color(0xFFFBE9E7)
                                : const Color(0xFFE8F5E9),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSame
                              ? const Color(0xFFE0E0E0)
                              : isHigher
                                  ? const Color(0xFFEF9A9A)
                                  : const Color(0xFFA5D6A7),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isSame
                                ? Icons.remove
                                : isHigher
                                    ? Icons.arrow_upward
                                    : Icons.arrow_downward,
                            size: 18,
                            color: isSame
                                ? const Color(0xFF9E9E9E)
                                : isHigher
                                    ? AppConfig.errorColor
                                    : const Color(0xFF2E7D32),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              isSame
                                  ? 'ราคาเท่าเดิม'
                                  : '${isHigher ? 'เพิ่มขึ้น' : 'ลดลง'} ฿${_formatPrice(diff.abs())} (${pct.abs().toStringAsFixed(1)}%)',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: isSame
                                    ? const Color(0xFF9E9E9E)
                                    : isHigher
                                        ? AppConfig.errorColor
                                        : const Color(0xFF2E7D32),
                              ),
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '฿${_formatPrice(oldPrice)}',
                                style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF9E9E9E),
                                    decoration: TextDecoration.lineThrough),
                              ),
                              Text(
                                '฿${_formatPrice(newPrice)}',
                                style: const TextStyle(
                                    fontSize: 14, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),

                const SizedBox(height: 20),

                const _Label(text: 'ข้อความถึงลูกค้า (ไม่บังคับ)'),
                TextFormField(
                  controller: _noteCtrl,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: 'แนะนำตัว หรือระบุข้อมูลเพิ่มเติม...',
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
                      borderSide: const BorderSide(
                          color: AppConfig.primaryColor, width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                BlocBuilder<ContractorBidBloc, ContractorBidState>(
                  builder: (context, state) {
                    final isLoading = state is ContractorBidLoading;
                    return SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: isLoading
                            ? null
                            : () {
                                if (_formKey.currentState!.validate()) {
                                  context.read<ContractorBidBloc>().add(
                                        EditBidEvent(
                                          biddingId:
                                              widget.bidding.biddingId,
                                          bidPrice: int.parse(
                                              _priceCtrl.text.trim()),
                                          note:
                                              _noteCtrl.text.trim().isEmpty
                                                  ? null
                                                  : _noteCtrl.text.trim(),
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
                            : const Text('บันทึกการแก้ไข',
                                style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600)),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
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


