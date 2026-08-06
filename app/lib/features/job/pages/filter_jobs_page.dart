import 'package:flutter/material.dart';
import '../../../core/config/app_config.dart';

class JobFilter {
  final int maxDistance;
  final Set<String> selectedTruckTypes;
  final double? minWeight;
  final double? maxWeight;
  final int? minBudget;
  final int? maxBudget;
  final Set<String> selectedProductTypes;

  const JobFilter({
    this.maxDistance = 500,
    this.selectedTruckTypes = const {},
    this.minWeight,
    this.maxWeight,
    this.minBudget,
    this.maxBudget,
    this.selectedProductTypes = const {},
  });

  bool get isEmpty =>
      maxDistance == 500 &&
      selectedTruckTypes.isEmpty &&
      minWeight == null &&
      maxWeight == null &&
      minBudget == null &&
      maxBudget == null &&
      selectedProductTypes.isEmpty;
}

class FilterJobsPage extends StatefulWidget {
  final JobFilter initial;
  const FilterJobsPage({super.key, required this.initial});

  @override
  State<FilterJobsPage> createState() => _FilterJobsPageState();
}

class _FilterJobsPageState extends State<FilterJobsPage> {
  late double _maxDistance;
  late Set<String> _selectedTruckTypes;
  late Set<String> _selectedProductTypes;

  final _minWeightCtrl = TextEditingController();
  final _maxWeightCtrl = TextEditingController();
  final _minBudgetCtrl = TextEditingController();
  final _maxBudgetCtrl = TextEditingController();

  static const _truckTypes = [
    'รถกระบะบรรทุก',
    'รถ 6 ล้อ',
    'รถ 10 ล้อ',
    'รถห้องเย็น',
  ];

  static const _productTypes = [
    'ผักสด',
    'ผลไม้',
    'ธัญพืช',
    'กาแฟ',
    'สินค้าแช่เย็น',
  ];

  @override
  void initState() {
    super.initState();
    _maxDistance = widget.initial.maxDistance.toDouble();
    _selectedTruckTypes = Set.from(widget.initial.selectedTruckTypes);
    _selectedProductTypes = Set.from(widget.initial.selectedProductTypes);
    _minWeightCtrl.text = widget.initial.minWeight?.toString() ?? '';
    _maxWeightCtrl.text = widget.initial.maxWeight?.toString() ?? '';
    _minBudgetCtrl.text = widget.initial.minBudget?.toString() ?? '';
    _maxBudgetCtrl.text = widget.initial.maxBudget?.toString() ?? '';
  }

  @override
  void dispose() {
    _minWeightCtrl.dispose();
    _maxWeightCtrl.dispose();
    _minBudgetCtrl.dispose();
    _maxBudgetCtrl.dispose();
    super.dispose();
  }

  void _reset() {
    setState(() {
      _maxDistance = 500;
      _selectedTruckTypes = {};
      _selectedProductTypes = {};
      _minWeightCtrl.clear();
      _maxWeightCtrl.clear();
      _minBudgetCtrl.clear();
      _maxBudgetCtrl.clear();
    });
  }

  void _apply() {
    Navigator.of(context).pop(JobFilter(
      maxDistance: _maxDistance.round(),
      selectedTruckTypes: Set.from(_selectedTruckTypes),
      minWeight: double.tryParse(_minWeightCtrl.text),
      maxWeight: double.tryParse(_maxWeightCtrl.text),
      minBudget: int.tryParse(_minBudgetCtrl.text),
      maxBudget: int.tryParse(_maxBudgetCtrl.text),
      selectedProductTypes: Set.from(_selectedProductTypes),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConfig.surfaceColor,
      appBar: AppBar(
        backgroundColor: AppConfig.primaryColor,
        foregroundColor: Colors.white,
        title: const Text('กรองงาน'),
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _reset,
            child: const Text(
              'รีเซ็ต',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ระยะทาง
            _SectionTitle(title: 'ระยะทาง'),
            _Card(
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('ระยะทางสูงสุด',
                          style: TextStyle(fontSize: 14)),
                      Text(
                        '${_maxDistance.round()} กม.',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppConfig.primaryColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: AppConfig.primaryColor,
                      thumbColor: AppConfig.primaryColor,
                      overlayColor: AppConfig.primaryColor.withAlpha(30),
                      inactiveTrackColor: const Color(0xFFE0E0E0),
                    ),
                    child: Slider(
                      value: _maxDistance,
                      min: 50,
                      max: 1000,
                      divisions: 19,
                      onChanged: (v) => setState(() => _maxDistance = v),
                    ),
                  ),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('50 กม.',
                          style: TextStyle(fontSize: 12, color: Color(0xFF9E9E9E))),
                      Text('1,000 กม.',
                          style: TextStyle(fontSize: 12, color: Color(0xFF9E9E9E))),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ประเภทรถ
            _SectionTitle(title: 'ประเภทรถ'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _truckTypes.map((t) {
                final sel = _selectedTruckTypes.contains(t);
                return _ToggleChip(
                  label: t,
                  selected: sel,
                  onTap: () => setState(() {
                    if (sel) {
                      _selectedTruckTypes.remove(t);
                    } else {
                      _selectedTruckTypes.add(t);
                    }
                  }),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // น้ำหนักสินค้า
            _SectionTitle(title: 'น้ำหนักสินค้า'),
            _Card(
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('ต่ำสุด (ตัน)',
                            style: TextStyle(
                                fontSize: 12, color: Color(0xFF757575))),
                        const SizedBox(height: 6),
                        _NumberInput(controller: _minWeightCtrl, hint: '1'),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('สูงสุด (ตัน)',
                            style: TextStyle(
                                fontSize: 12, color: Color(0xFF757575))),
                        const SizedBox(height: 6),
                        _NumberInput(controller: _maxWeightCtrl, hint: '8'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // งบประมาณ
            _SectionTitle(title: 'งบประมาณ'),
            _Card(
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('ต่ำสุด (บาท)',
                            style: TextStyle(
                                fontSize: 12, color: Color(0xFF757575))),
                        const SizedBox(height: 6),
                        _NumberInput(controller: _minBudgetCtrl, hint: '1,000'),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('สูงสุด (บาท)',
                            style: TextStyle(
                                fontSize: 12, color: Color(0xFF757575))),
                        const SizedBox(height: 6),
                        _NumberInput(
                            controller: _maxBudgetCtrl, hint: '20,000'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ประเภทสินค้า
            _SectionTitle(title: 'ประเภทสินค้า'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _productTypes.map((p) {
                final sel = _selectedProductTypes.contains(p);
                return _ToggleChip(
                  label: p,
                  selected: sel,
                  onTap: () => setState(() {
                    if (sel) {
                      _selectedProductTypes.remove(p);
                    } else {
                      _selectedProductTypes.add(p);
                    }
                  }),
                );
              }).toList(),
            ),
            const SizedBox(height: 32),

            // Apply button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _apply,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppConfig.primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: const Text(
                  'แสดงผลลัพธ์',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF424242),
          ),
        ),
      );
}

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            AppConfig.cardShadow,
          ],
        ),
        child: child,
      );
}

class _ToggleChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _ToggleChip(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: selected
                ? AppConfig.primaryColor.withAlpha(26)
                : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected ? AppConfig.primaryColor : const Color(0xFFE0E0E0),
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight:
                  selected ? FontWeight.w600 : FontWeight.normal,
              color: selected
                  ? AppConfig.primaryColor
                  : const Color(0xFF424242),
            ),
          ),
        ),
      );
}

class _NumberInput extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  const _NumberInput({required this.controller, required this.hint});

  @override
  Widget build(BuildContext context) => TextFormField(
        controller: controller,
        keyboardType: TextInputType.number,
        style: const TextStyle(fontSize: 14),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Color(0xFFBDBDBD)),
          filled: true,
          fillColor: const Color(0xFFFAFAFA),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide:
                const BorderSide(color: AppConfig.primaryColor, width: 2),
          ),
        ),
      );
}


