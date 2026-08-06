import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/config/app_config.dart';
import '../../../core/repositories/repositories.dart';
import '../../../models/models.dart';
import '../../truck/bloc/truck_type_bloc.dart';
import '../bloc/job_bloc.dart';
import '../bloc/job_event.dart';
import '../bloc/job_state.dart';

class EditJobPage extends StatelessWidget {
  final JobModel job;
  const EditJobPage({super.key, required this.job});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => JobBloc(
            jobRepository: JobRepository(),
            biddingRepository: BiddingRepository(),
          ),
        ),
        BlocProvider(
            create: (_) => TruckTypeBloc()..add(const LoadTruckTypes())),
      ],
      child: _EditJobView(job: job),
    );
  }
}

class _EditJobView extends StatefulWidget {
  final JobModel job;
  const _EditJobView({required this.job});

  @override
  State<_EditJobView> createState() => _EditJobViewState();
}

class _EditJobViewState extends State<_EditJobView> {
  int _step = 0; // 0=cargo, 1=location, 2=schedule, 3=confirm

  // Step 1
  final _step1Key = GlobalKey<FormState>();
  late final TextEditingController _titleCtrl;
  late String? _productType;
  late final TextEditingController _weightCtrl;
  TruckTypeModel? _selectedTruckType; // ค่าเริ่ม = job.requiredTruckType, re-select เมื่อโหลด types
  late final TextEditingController _descCtrl;

  // Step 2
  final _step2Key = GlobalKey<FormState>();
  late final TextEditingController _pickupAddrCtrl;
  late final TextEditingController _pickupNameCtrl;
  late final TextEditingController _pickupPhoneCtrl;
  late final TextEditingController _dropoffAddrCtrl;
  late final TextEditingController _dropoffNameCtrl;
  late final TextEditingController _dropoffPhoneCtrl;
  late final TextEditingController _distanceCtrl;

  // Step 3
  final _step3Key = GlobalKey<FormState>();
  DateTime? _pickupDate;
  TimeOfDay? _pickupTime;
  DateTime? _dropoffDate;
  TimeOfDay? _dropoffTime;
  late final TextEditingController _budgetCtrl;

  static const _productTypes = [
    'ผักสด', 'ผลไม้', 'ธัญพืช', 'กาแฟ', 'สินค้าแช่เย็น', 'อื่นๆ',
  ];

  static int _ratePerKm(TruckTypeModel t) {
    final name = t.typeName.toLowerCase();
    if (name.contains('กระบะ')) return 5;
    if (name.contains('10 ล้อ') || name.contains('10ล้อ')) return 12;
    if (name.contains('ห้องเย็น')) return 10;
    if (name.contains('6 ล้อ') || name.contains('6ล้อ')) return 8;
    final cap = t.maxWeightCapacity ?? 0;
    if (cap <= 2000) return 5;
    if (cap <= 8000) return 8;
    return 12;
  }

  static int _laborCost(int km) {
    final rt = km * 2;
    if (rt < 50) return 800;
    if (rt < 200) return 1500;
    if (rt < 400) return 2000;
    if (rt < 800) return 2800;
    return 4000;
  }

  ({int distanceCost, int weightCost, int laborCost, int total})? get _suggestedPrice {
    final w = int.tryParse(_weightCtrl.text);
    final d = int.tryParse(_distanceCtrl.text);
    final truck = _selectedTruckType;
    if (w == null || w <= 0 || d == null || d <= 0 || truck == null) return null;
    final dc = d * _ratePerKm(truck);
    final wc = (w * 0.25).round();
    final lc = _laborCost(d);
    return (distanceCost: dc, weightCost: wc, laborCost: lc, total: dc + wc + lc);
  }

  String _fmt(int v) => v.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');

  DateTime? get _pickupDatetime {
    if (_pickupDate == null || _pickupTime == null) return null;
    return DateTime(_pickupDate!.year, _pickupDate!.month, _pickupDate!.day,
        _pickupTime!.hour, _pickupTime!.minute);
  }

  DateTime? get _dropoffDatetime {
    if (_dropoffDate == null || _dropoffTime == null) return null;
    return DateTime(_dropoffDate!.year, _dropoffDate!.month, _dropoffDate!.day,
        _dropoffTime!.hour, _dropoffTime!.minute);
  }

  String _fmtDate(DateTime? d) => d == null
      ? 'เลือกวันที่'
      : '${d.day}/${d.month}/${d.year}';

  String _fmtTime(TimeOfDay? t) => t == null
      ? 'เลือกเวลา'
      : '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  @override
  void initState() {
    super.initState();
    final j = widget.job;
    _titleCtrl = TextEditingController(text: j.jobTitle);
    _productType = _productTypes.contains(j.productType) ? j.productType : 'อื่นๆ';
    _weightCtrl = TextEditingController(text: j.weight.toString());
    _descCtrl = TextEditingController(text: j.description ?? '');
    _pickupAddrCtrl = TextEditingController(text: j.pickupAddress);
    _pickupNameCtrl = TextEditingController(text: j.pickupName ?? '');
    _pickupPhoneCtrl = TextEditingController(text: j.pickupPhone ?? '');
    _dropoffAddrCtrl = TextEditingController(text: j.dropoffAddress);
    _dropoffNameCtrl = TextEditingController(text: j.dropoffName ?? '');
    _dropoffPhoneCtrl = TextEditingController(text: j.dropoffPhone ?? '');
    _distanceCtrl = TextEditingController(text: j.distance?.toString() ?? '');
    _budgetCtrl = TextEditingController(text: j.budgetPrice.toString());

    final pu = j.pickupDatetime;
    _pickupDate = DateTime(pu.year, pu.month, pu.day);
    _pickupTime = TimeOfDay(hour: pu.hour, minute: pu.minute);
    final dd = j.dropoffDeadline;
    _dropoffDate = DateTime(dd.year, dd.month, dd.day);
    _dropoffTime = TimeOfDay(hour: dd.hour, minute: dd.minute);

    _selectedTruckType = j.requiredTruckType;

    _weightCtrl.addListener(() => setState(() {}));
    _distanceCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    for (final c in [
      _titleCtrl, _weightCtrl, _descCtrl,
      _pickupAddrCtrl, _pickupNameCtrl, _pickupPhoneCtrl,
      _dropoffAddrCtrl, _dropoffNameCtrl, _dropoffPhoneCtrl,
      _distanceCtrl, _budgetCtrl,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  void _nextStep() {
    bool valid = false;
    if (_step == 0) valid = _step1Key.currentState?.validate() ?? false;
    if (_step == 1) valid = _step2Key.currentState?.validate() ?? false;
    if (_step == 2) {
      valid = _step3Key.currentState?.validate() ?? false;
      if (valid && (_pickupDatetime == null || _dropoffDatetime == null)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('กรุณาเลือกวันและเวลารับ/ส่งสินค้า')),
        );
        return;
      }
    }
    if (valid) setState(() => _step++);
  }

  void _saveJob() {
    context.read<JobBloc>().add(EditJobEvent(
          jobId: widget.job.jobId,
          jobTitle: _titleCtrl.text.trim(),
          productType: _productType!,
          weight: int.parse(_weightCtrl.text.trim()),
          description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
          distance: _distanceCtrl.text.trim().isEmpty
              ? null
              : int.tryParse(_distanceCtrl.text.trim()),
          pickupAddress: _pickupAddrCtrl.text.trim(),
          pickupName: _pickupNameCtrl.text.trim().isEmpty ? null : _pickupNameCtrl.text.trim(),
          pickupPhone: _pickupPhoneCtrl.text.trim().isEmpty ? null : _pickupPhoneCtrl.text.trim(),
          pickupDatetime: _pickupDatetime!,
          dropoffAddress: _dropoffAddrCtrl.text.trim(),
          dropoffName: _dropoffNameCtrl.text.trim().isEmpty ? null : _dropoffNameCtrl.text.trim(),
          dropoffPhone: _dropoffPhoneCtrl.text.trim().isEmpty ? null : _dropoffPhoneCtrl.text.trim(),
          dropoffDeadline: _dropoffDatetime!,
          budgetPrice: int.parse(_budgetCtrl.text.trim()),
          requiredTruckType: _selectedTruckType!,
        ));
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<JobBloc, JobState>(
          listener: (context, state) {
            if (state is JobUpdated) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('แก้ไขงานสำเร็จ'),
                  backgroundColor: AppConfig.primaryColor,
                ),
              );
              Navigator.pop(context, true);
            } else if (state is JobError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content: Text(state.message),
                    backgroundColor: AppConfig.errorColor),
              );
            }
          },
        ),
        // re-select ประเภทรถให้ตรงกับงานที่แก้ เมื่อโหลด types เสร็จ
        BlocListener<TruckTypeBloc, TruckTypeListState>(
          listener: (context, state) {
            if (state is TruckTypeListLoaded && state.types.isNotEmpty) {
              setState(() {
                _selectedTruckType = state.types.firstWhere(
                  (t) =>
                      t.truckTypeId ==
                      widget.job.requiredTruckType.truckTypeId,
                  orElse: () => state.types.first,
                );
              });
            }
          },
        ),
      ],
      child: Scaffold(
        backgroundColor: AppConfig.surfaceColor,
        appBar: AppBar(
          backgroundColor: AppConfig.primaryColor,
          foregroundColor: Colors.white,
          title: Text(_step == 3 ? 'ยืนยันการแก้ไข' : 'แก้ไขประกาศงาน'),
          elevation: 0,
          leading: _step == 0
              ? null
              : IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => setState(() => _step--),
                ),
        ),
        body: SafeArea(
          child: Column(
            children: [
              // Progress bar
              if (_step < 3)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Row(
                    children: List.generate(3, (i) => Expanded(
                      child: Container(
                        height: 4,
                        margin: EdgeInsets.only(right: i < 2 ? 8 : 0),
                        decoration: BoxDecoration(
                          color: i <= _step
                              ? AppConfig.primaryColor
                              : const Color(0xFFE0E0E0),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    )),
                  ),
                ),

              Expanded(
                child: _step == 0
                    ? _buildStep1()
                    : _step == 1
                        ? _buildStep2()
                        : _step == 2
                            ? _buildStep3()
                            : _buildConfirm(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────── STEP 1 ───────────────────────────────────────

  Widget _buildStep1() {
    return Form(
      key: _step1Key,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            const Text('ข้อมูลสินค้า',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),

            _label('ชื่องาน *'),
            TextFormField(
              controller: _titleCtrl,
              decoration: _deco('เช่น ขนส่งผักกาดขาว'),
              validator: (v) => (v == null || v.isEmpty) ? 'กรุณากรอกชื่องาน' : null,
            ),
            const SizedBox(height: 16),

            _label('ประเภทสินค้า *'),
            DropdownButtonFormField<String>(
              value: _productType,
              decoration: _deco('เลือกประเภทสินค้า'),
              isExpanded: true,
              items: _productTypes
                  .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                  .toList(),
              onChanged: (v) => setState(() => _productType = v),
              validator: (v) => v == null ? 'กรุณาเลือกประเภทสินค้า' : null,
            ),
            const SizedBox(height: 16),

            _label('น้ำหนัก (กิโลกรัม) *'),
            TextFormField(
              controller: _weightCtrl,
              decoration: _deco('เช่น 6000'),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: (v) {
                if (v == null || v.isEmpty) return 'กรุณากรอกน้ำหนัก';
                if ((int.tryParse(v) ?? 0) <= 0) return 'น้ำหนักต้องมากกว่า 0';
                return null;
              },
            ),
            const SizedBox(height: 16),

            _label('ประเภทรถที่ต้องการ *'),
            BlocBuilder<TruckTypeBloc, TruckTypeListState>(
              builder: (context, state) {
                if (state is! TruckTypeListLoaded) {
                  return const Center(child: CircularProgressIndicator());
                }
                return DropdownButtonFormField<TruckTypeModel>(
                  value: _selectedTruckType,
                  decoration: _deco('เลือกประเภทรถ'),
                  isExpanded: true,
                  items: state.types
                      .map((t) =>
                          DropdownMenuItem(value: t, child: Text(t.typeName)))
                      .toList(),
                  onChanged: (v) => setState(() => _selectedTruckType = v),
                  validator: (v) => v == null ? 'กรุณาเลือกประเภทรถ' : null,
                );
              },
            ),
            const SizedBox(height: 16),

            _label('รายละเอียดเพิ่มเติม'),
            TextFormField(
              controller: _descCtrl,
              decoration: _deco('อธิบายรายละเอียดสินค้า...'),
              maxLines: 3,
            ),
            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _nextStep,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppConfig.primaryColor,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(0, 52),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('ถัดไป',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────── STEP 2 ───────────────────────────────────────

  Widget _buildStep2() {
    return Form(
      key: _step2Key,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            const Text('สถานที่รับ-ส่ง',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),

            _locationCard(
              dotColor: AppConfig.primaryColor,
              label: 'จุดรับสินค้า',
              addressCtrl: _pickupAddrCtrl,
              nameCtrl: _pickupNameCtrl,
              phoneCtrl: _pickupPhoneCtrl,
            ),
            const SizedBox(height: 16),

            _locationCard(
              dotColor: const Color(0xFFE53935),
              label: 'จุดส่งสินค้า',
              addressCtrl: _dropoffAddrCtrl,
              nameCtrl: _dropoffNameCtrl,
              phoneCtrl: _dropoffPhoneCtrl,
            ),
            const SizedBox(height: 16),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF9F9F9),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE0E0E0)),
              ),
              child: Row(
                children: [
                  const Expanded(
                    child: Text('ระยะทางโดยประมาณ (กม.)',
                        style: TextStyle(color: Color(0xFF757575), fontSize: 14)),
                  ),
                  SizedBox(
                    width: 100,
                    child: TextFormField(
                      controller: _distanceCtrl,
                      decoration: _deco('กม.').copyWith(
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _nextStep,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppConfig.primaryColor,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(0, 52),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('ถัดไป',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _locationCard({
    required Color dotColor,
    required String label,
    required TextEditingController addressCtrl,
    required TextEditingController nameCtrl,
    required TextEditingController phoneCtrl,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
              color: Color(0x14000000), blurRadius: 8, offset: Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 12, height: 12,
                decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Text(label,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            ],
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: addressCtrl,
            decoration: _deco('ที่อยู่$label'),
            validator: (v) =>
                (v == null || v.isEmpty) ? 'กรุณากรอกที่อยู่' : null,
          ),
          const SizedBox(height: 12),
          Container(
            height: 100,
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE0E0E0)),
            ),
            child: const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.location_on, size: 36, color: Color(0xFF9E9E9E)),
                  Text('ปักหมุดบนแผนที่',
                      style: TextStyle(fontSize: 12, color: Color(0xFF9E9E9E))),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                  child: TextFormField(
                      controller: nameCtrl, decoration: _deco('ชื่อผู้ติดต่อ'))),
              const SizedBox(width: 12),
              Expanded(
                  child: TextFormField(
                      controller: phoneCtrl,
                      decoration: _deco('เบอร์โทร'),
                      keyboardType: TextInputType.phone)),
            ],
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────── STEP 3 ───────────────────────────────────────

  Widget _buildStep3() {
    final suggested = _suggestedPrice;
    return Form(
      key: _step3Key,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            const Text('กำหนดการและราคา',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),

            _label('กำหนดการรับสินค้า'),
            Row(children: [
              Expanded(child: _dateTile(_pickupDate, () async {
                final d = await showDatePicker(
                  context: context,
                  initialDate: _pickupDate ?? DateTime.now().add(const Duration(days: 1)),
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (d != null && mounted) setState(() => _pickupDate = d);
              })),
              const SizedBox(width: 8),
              Expanded(child: _timeTile(_pickupTime, () async {
                final t = await showTimePicker(
                    context: context,
                    initialTime: _pickupTime ?? TimeOfDay.now());
                if (t != null && mounted) setState(() => _pickupTime = t);
              })),
            ]),
            const SizedBox(height: 16),

            _label('ต้องส่งถึงภายใน'),
            Row(children: [
              Expanded(child: _dateTile(_dropoffDate, () async {
                final d = await showDatePicker(
                  context: context,
                  initialDate: _dropoffDate ?? DateTime.now().add(const Duration(days: 1)),
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (d != null && mounted) setState(() => _dropoffDate = d);
              })),
              const SizedBox(width: 8),
              Expanded(child: _timeTile(_dropoffTime, () async {
                final t = await showTimePicker(
                    context: context,
                    initialTime: _dropoffTime ?? TimeOfDay.now());
                if (t != null && mounted) setState(() => _dropoffTime = t);
              })),
            ]),
            const SizedBox(height: 24),

            const Divider(),
            const SizedBox(height: 8),
            const Text('งบประมาณ',
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppConfig.primaryColor)),
            const SizedBox(height: 16),

            if (suggested != null) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFE3F2FD),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF1976D2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(children: [
                      Icon(Icons.bar_chart, color: Color(0xFF1976D2)),
                      SizedBox(width: 8),
                      Text('รายละเอียดราคาแนะนำ',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1976D2))),
                    ]),
                    const SizedBox(height: 12),
                    _priceRow(
                        'ค่าระยะทาง (${_distanceCtrl.text} กม. × ฿${_ratePerKm(_selectedTruckType!)})',
                        '฿${_fmt(suggested.distanceCost)}'),
                    _priceRow(
                        'ค่าน้ำหนัก (${_weightCtrl.text} กก. × ฿0.25)',
                        '฿${_fmt(suggested.weightCost)}'),
                    _priceRow('ค่าแรงคนขับ', '฿${_fmt(suggested.laborCost)}'),
                    const Divider(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('💰 ราคาแนะนำ',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        Text('฿${_fmt(suggested.total)}',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppConfig.primaryColor,
                                fontSize: 16)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () => setState(
                            () => _budgetCtrl.text = suggested.total.toString()),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppConfig.primaryColor,
                          side: const BorderSide(color: AppConfig.primaryColor),
                          minimumSize: const Size(0, 40),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text('ใช้ราคาแนะนำ',
                            style: TextStyle(fontSize: 13)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFA5D6A7)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('ระบุงบประมาณที่ต้องการ',
                      style: TextStyle(fontSize: 13, color: Color(0xFF757575))),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _budgetCtrl,
                    decoration: _deco('งบประมาณ (บาท)'),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'กรุณากรอกงบประมาณ';
                      if ((int.tryParse(v) ?? 0) <= 0) return 'งบประมาณต้องมากกว่า 0';
                      return null;
                    },
                  ),
                  const SizedBox(height: 8),
                  const Text('* ผู้รับจ้างสามารถเสนอราคาต่างจากนี้ได้',
                      style: TextStyle(fontSize: 12, color: Color(0xFF757575))),
                ],
              ),
            ),
            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _nextStep,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppConfig.primaryColor,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(0, 52),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('ตรวจสอบการแก้ไข',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────── CONFIRM ───────────────────────────────────────

  Widget _buildConfirm() {
    return BlocBuilder<JobBloc, JobState>(
      builder: (context, state) {
        final isLoading = state is JobLoading;
        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: const [
                    BoxShadow(
                        color: Color(0x14000000),
                        blurRadius: 8,
                        offset: Offset(0, 2))
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_titleCtrl.text.trim(),
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE3F2FD),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(_selectedTruckType?.typeName ?? '',
                          style: const TextStyle(
                              fontSize: 12, color: Color(0xFF1976D2))),
                    ),
                    const Divider(height: 24),
                    const Text('เส้นทาง',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppConfig.primaryColor)),
                    const SizedBox(height: 12),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                            width: 10, height: 10,
                            margin: const EdgeInsets.only(top: 4),
                            decoration: const BoxDecoration(
                                color: AppConfig.primaryColor,
                                shape: BoxShape.circle)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(_pickupAddrCtrl.text,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w500)),
                              if (_pickupNameCtrl.text.isNotEmpty)
                                Text(
                                    '${_pickupNameCtrl.text}  ${_pickupPhoneCtrl.text}',
                                    style: const TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF757575))),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                            width: 10, height: 10,
                            margin: const EdgeInsets.only(top: 4),
                            decoration: const BoxDecoration(
                                color: Color(0xFFE53935),
                                shape: BoxShape.circle)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(_dropoffAddrCtrl.text,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w500)),
                              if (_dropoffNameCtrl.text.isNotEmpty)
                                Text(
                                    '${_dropoffNameCtrl.text}  ${_dropoffPhoneCtrl.text}',
                                    style: const TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF757575))),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    _infoGrid([
                      ('น้ำหนัก', '${_weightCtrl.text} กก.'),
                      ('ระยะทาง',
                          _distanceCtrl.text.isEmpty ? '-' : '${_distanceCtrl.text} กม.'),
                      ('วันรับสินค้า', _fmtDate(_pickupDate)),
                      ('เวลารับ', _fmtTime(_pickupTime)),
                      ('วันส่งสินค้า', _fmtDate(_dropoffDate)),
                      ('เวลาส่ง', _fmtTime(_dropoffTime)),
                    ]),
                    const Divider(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('งบประมาณ',
                            style: TextStyle(color: Color(0xFF757575))),
                        Text(
                            '${_fmt(int.tryParse(_budgetCtrl.text) ?? 0)} บาท',
                            style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: AppConfig.primaryColor)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => setState(() => _step = 2),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppConfig.primaryColor,
                        side: const BorderSide(color: AppConfig.primaryColor),
                        minimumSize: const Size(0, 52),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('แก้ไข',
                          style: TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: isLoading ? null : _saveJob,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppConfig.primaryColor,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(0, 52),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: isLoading
                          ? const SizedBox(
                              width: 22, height: 22,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2.5))
                          : const Text('บันทึกการแก้ไข',
                              style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // ─────────────────────────────────────── Helpers ───────────────────────────────────────

  Widget _dateTile(DateTime? date, VoidCallback onTap) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFBDBDBD)),
          ),
          child: Row(
            children: [
              const Icon(Icons.calendar_today,
                  size: 16, color: Color(0xFF757575)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(_fmtDate(date),
                    style: TextStyle(
                        fontSize: 13,
                        color: date == null
                            ? const Color(0xFFBDBDBD)
                            : const Color(0xFF212121))),
              ),
            ],
          ),
        ),
      );

  Widget _timeTile(TimeOfDay? time, VoidCallback onTap) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFBDBDBD)),
          ),
          child: Row(
            children: [
              const Icon(Icons.access_time,
                  size: 16, color: Color(0xFF757575)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(_fmtTime(time),
                    style: TextStyle(
                        fontSize: 13,
                        color: time == null
                            ? const Color(0xFFBDBDBD)
                            : const Color(0xFF212121))),
              ),
            ],
          ),
        ),
      );

  Widget _priceRow(String label, String value) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
                child: Text(label,
                    style: const TextStyle(
                        fontSize: 13, color: Color(0xFF757575)))),
            Text(value,
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w500)),
          ],
        ),
      );

  Widget _infoGrid(List<(String, String)> items) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 2.8,
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      children: items
          .map((item) => Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppConfig.surfaceColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(item.$1,
                        style: const TextStyle(
                            fontSize: 11, color: Color(0xFF757575))),
                    Text(item.$2,
                        style: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.bold)),
                  ],
                ),
              ))
          .toList(),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(text,
            style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF424242))),
      );

  InputDecoration _deco(String hint) => InputDecoration(
        hintText: hint,
        hintStyle:
            const TextStyle(color: Color(0xFFBDBDBD), fontSize: 14),
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFFBDBDBD))),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFFBDBDBD))),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide:
                const BorderSide(color: AppConfig.primaryColor, width: 2)),
      );
}


