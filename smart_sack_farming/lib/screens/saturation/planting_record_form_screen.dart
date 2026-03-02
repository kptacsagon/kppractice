import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/crop_data.dart';

class PlantingRecordFormScreen extends StatefulWidget {
  final CropData primaryCrop;
  final DateTime plantingDate;
  final SaturationLevel saturationLevel;
  final double soilMoisture;
  final List<CropData> companionCrops; // from Mix & Match

  const PlantingRecordFormScreen({
    super.key,
    required this.primaryCrop,
    required this.plantingDate,
    required this.saturationLevel,
    required this.soilMoisture,
    this.companionCrops = const [],
  });

  @override
  State<PlantingRecordFormScreen> createState() =>
      _PlantingRecordFormScreenState();
}

class _PlantingRecordFormScreenState extends State<PlantingRecordFormScreen> {
  final _formKey = GlobalKey<FormState>();

  // Basic info
  late DateTime _plantingDate;
  DateTime? _harvestDate;
  final _fieldSizeController = TextEditingController();

  // Treatment & Protection
  final _pesticidesController = TextEditingController();
  String _fertilizerType = 'Organic';
  String _irrigationMethod = 'Drip';

  // Additional
  String _soilType = 'Loamy';
  final _expectedYieldController = TextEditingController();
  final _notesController = TextEditingController();

  bool _isSaving = false;

  static const _fertilizerOptions = [
    'Organic',
    'Inorganic',
    'Bio-fertilizer',
    'Mixed',
    'None',
  ];
  static const _irrigationOptions = [
    'Drip',
    'Sprinkler',
    'Flood',
    'Furrow',
    'Manual',
    'Rainwater',
  ];
  static const _soilTypeOptions = [
    'Loamy',
    'Sandy',
    'Clay',
    'Silty',
    'Peaty',
    'Chalky',
    'Sandy Loam',
  ];

  @override
  void initState() {
    super.initState();
    _plantingDate = widget.plantingDate;
    // Auto-estimate harvest date based on crop growth duration
    final months = _parseGrowthMonths(widget.primaryCrop.growthDuration);
    if (months > 0) {
      _harvestDate = DateTime(_plantingDate.year,
          _plantingDate.month + months, _plantingDate.day);
    }
  }

  int _parseGrowthMonths(String duration) {
    final match = RegExp(r'(\d+)').firstMatch(duration);
    if (match != null) return int.tryParse(match.group(1) ?? '0') ?? 0;
    return 0;
  }

  @override
  void dispose() {
    _fieldSizeController.dispose();
    _pesticidesController.dispose();
    _expectedYieldController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F0FF),
      appBar: AppBar(
        backgroundColor: const Color(0xFF5C6BC0),
        elevation: 0,
        leading: IconButton(
          icon:
              const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Planting Record',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          TextButton.icon(
            onPressed: _isSaving ? null : _saveRecord,
            icon: const Icon(Icons.save_rounded, color: Colors.white, size: 18),
            label: const Text('Save',
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 600;
          final isWide = constraints.maxWidth >= 900;

          return Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF7986CB), Color(0xFF5C6BC0)],
              ),
            ),
            child: SafeArea(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: isWide
                      ? (constraints.maxWidth - 800) / 2
                      : isMobile
                          ? 12
                          : 20,
                  vertical: 16,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // --- Crop banner ---
                      _buildCropBanner(isMobile),
                      const SizedBox(height: 16),

                      // --- Saturation warning (if high/low) ---
                      if (widget.saturationLevel != SaturationLevel.medium)
                        _buildSaturationWarning(),

                      if (widget.saturationLevel != SaturationLevel.medium)
                        const SizedBox(height: 16),

                      // --- Basic Information ---
                      _buildSection(
                        title: 'Basic Information',
                        children: [
                          _buildDateField(
                            label: 'Planting Date',
                            icon: Icons.calendar_today_rounded,
                            date: _plantingDate,
                            onTap: () => _pickDate(
                              initial: _plantingDate,
                              onPicked: (d) =>
                                  setState(() => _plantingDate = d),
                            ),
                          ),
                          const SizedBox(height: 12),
                          _buildDateField(
                            label: 'Expected Harvest Date',
                            icon: Icons.agriculture_rounded,
                            date: _harvestDate,
                            hint: 'Tap to set harvest date',
                            onTap: () => _pickDate(
                              initial: _harvestDate ??
                                  _plantingDate
                                      .add(const Duration(days: 60)),
                              firstDate: _plantingDate,
                              onPicked: (d) =>
                                  setState(() => _harvestDate = d),
                            ),
                          ),
                          const SizedBox(height: 12),
                          _buildTextField(
                            controller: _fieldSizeController,
                            label: 'Field Size (hectares)',
                            icon: Icons.straighten_rounded,
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                  RegExp(r'^\d*\.?\d*')),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // --- Treatment & Protection ---
                      _buildSection(
                        title: 'Treatment & Protection',
                        children: [
                          _buildTextField(
                            controller: _pesticidesController,
                            label: 'Pesticides to Use',
                            icon: Icons.science_rounded,
                          ),
                          const SizedBox(height: 12),
                          _buildDropdownField(
                            label: 'Fertilizer Type',
                            icon: Icons.eco_rounded,
                            value: _fertilizerType,
                            items: _fertilizerOptions,
                            onChanged: (v) =>
                                setState(() => _fertilizerType = v!),
                          ),
                          const SizedBox(height: 12),
                          _buildDropdownField(
                            label: 'Irrigation Method',
                            icon: Icons.water_drop_rounded,
                            value: _irrigationMethod,
                            items: _irrigationOptions,
                            onChanged: (v) =>
                                setState(() => _irrigationMethod = v!),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // --- Additional Details ---
                      _buildSection(
                        title: 'Additional Details',
                        children: [
                          _buildDropdownField(
                            label: 'Soil Type',
                            icon: Icons.layers_rounded,
                            value: _soilType,
                            items: _soilTypeOptions,
                            onChanged: (v) =>
                                setState(() => _soilType = v!),
                          ),
                          const SizedBox(height: 12),
                          _buildTextField(
                            controller: _expectedYieldController,
                            label: 'Expected Yield (tons)',
                            icon: Icons.balance_rounded,
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                  RegExp(r'^\d*\.?\d*')),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _buildTextField(
                            controller: _notesController,
                            label: 'Additional Notes',
                            icon: Icons.notes_rounded,
                            maxLines: 3,
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // --- Companion crops summary (if mix & match) ---
                      if (widget.companionCrops.isNotEmpty) ...[
                        _buildSection(
                          title: 'Mix & Match Plan',
                          children: [
                            _buildMixMatchSummary(),
                          ],
                        ),
                        const SizedBox(height: 24),
                      ],

                      // --- Save button ---
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _isSaving ? null : _saveRecord,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF5C6BC0),
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: Colors.grey.shade400,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 2,
                          ),
                          child: _isSaving
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2.5,
                                  ),
                                )
                              : const Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.save_rounded, size: 20),
                                    SizedBox(width: 10),
                                    Text(
                                      'Save Planting Record',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ─── Builder helpers ───────────────────────────────────────────────────────

  Widget _buildCropBanner(bool isMobile) {
    final companions = widget.companionCrops;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(20),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withAlpha(40)),
      ),
      child: Row(
        children: [
          Text(widget.primaryCrop.icon,
              style: const TextStyle(fontSize: 32)),
          if (companions.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4),
              child:
                  Icon(Icons.add_circle_outline, color: Colors.white70, size: 16),
            ),
            ...companions.take(3).map((c) =>
                Text(c.icon, style: const TextStyle(fontSize: 22))),
          ],
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  companions.isEmpty
                      ? widget.primaryCrop.name
                      : '${widget.primaryCrop.name} + ${companions.map((c) => c.name).join(', ')}',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isMobile ? 14 : 16,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  companions.isEmpty
                      ? '${widget.primaryCrop.category} · ${widget.primaryCrop.growthDuration}'
                      : 'Mix & Match plan · ${companions.length + 1} crops',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSaturationWarning() {
    final isHigh = widget.saturationLevel == SaturationLevel.high;
    final label = isHigh ? 'High Saturation Risk Confirmed' : 'Low Saturation Risk Confirmed';
    final sub = isHigh
        ? "You're proceeding with ${widget.primaryCrop.name} despite"
            ' ${widget.soilMoisture.toStringAsFixed(0)}% soil moisture'
        : "You're proceeding with ${widget.primaryCrop.name} despite"
            ' low ${widget.soilMoisture.toStringAsFixed(0)}% soil moisture';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFFCDD2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_rounded,
              color: Color(0xFFE53935), size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Color(0xFFE53935),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  sub,
                  style: const TextStyle(
                    color: Color(0xFFE53935),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(
      {required String title, required List<Widget> children}) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(15),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A1A2E),
            ),
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }

  Widget _buildDateField({
    required String label,
    required IconData icon,
    required DateTime? date,
    String hint = '',
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFBDBDBD)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF616161), size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      color: Color(0xFF9E9E9E),
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    date != null ? _formatDate(date) : hint,
                    style: TextStyle(
                      color: date != null
                          ? const Color(0xFF1A1A2E)
                          : const Color(0xFF9E9E9E),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.keyboard_arrow_down_rounded,
                color: Color(0xFF9E9E9E)),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      maxLines: maxLines,
      style: const TextStyle(
        fontSize: 14,
        color: Color(0xFF1A1A2E),
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Color(0xFF9E9E9E), fontSize: 13),
        prefixIcon: Icon(icon, color: const Color(0xFF616161), size: 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFBDBDBD)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFBDBDBD)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF5C6BC0), width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 14,
        ),
      ),
    );
  }

  Widget _buildDropdownField({
    required String label,
    required IconData icon,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      onChanged: onChanged,
      items: items
          .map((item) => DropdownMenuItem(
                value: item,
                child: Text(item,
                    style: const TextStyle(
                        fontSize: 14, color: Color(0xFF1A1A2E))),
              ))
          .toList(),
      style: const TextStyle(fontSize: 14, color: Color(0xFF1A1A2E)),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Color(0xFF9E9E9E), fontSize: 13),
        prefixIcon: Icon(icon, color: const Color(0xFF616161), size: 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFBDBDBD)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFBDBDBD)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF5C6BC0), width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 14,
        ),
      ),
    );
  }

  Widget _buildMixMatchSummary() {
    final allCrops = [widget.primaryCrop, ...widget.companionCrops];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${allCrops.length} crops will be planted together',
          style: const TextStyle(
            color: Color(0xFF9E9E9E),
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 10),
        ...allCrops.asMap().entries.map((entry) {
          final i = entry.key;
          final crop = entry.value;
          return Column(
            children: [
              if (i > 0) const SizedBox(height: 8),
              Row(
                children: [
                  Text(crop.icon,
                      style: const TextStyle(fontSize: 20)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          crop.name,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF1A1A2E),
                          ),
                        ),
                        Text(
                          crop.category,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF9E9E9E),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (i == 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE3F2FD),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'Primary',
                        style: TextStyle(
                          color: Color(0xFF1565C0),
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5E9),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'Companion',
                        style: TextStyle(
                          color: Color(0xFF2E7D32),
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
              if (i < allCrops.length - 1)
                const Padding(
                  padding: EdgeInsets.only(left: 30, top: 8),
                  child: Divider(height: 1, color: Color(0xFFEEEEEE)),
                ),
            ],
          );
        }),
      ],
    );
  }

  // ─── Actions ───────────────────────────────────────────────────────────────

  Future<void> _pickDate({
    required DateTime initial,
    DateTime? firstDate,
    required ValueChanged<DateTime> onPicked,
  }) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: firstDate ?? DateTime.now(),
      lastDate: DateTime(DateTime.now().year + 5),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary: Color(0xFF5C6BC0),
            onPrimary: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) onPicked(picked);
  }

  String _formatDate(DateTime date) {
    final y = date.year.toString();
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  Future<void> _saveRecord() async {
    setState(() => _isSaving = true);

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) throw Exception('Not logged in');

      final data = {
        'farmer_id': user.id,
        'primary_crop': widget.primaryCrop.name,
        'companion_crops': widget.companionCrops.map((c) => c.name).toList(),
        'soil_moisture': widget.soilMoisture,
        'saturation_level': widget.saturationLevel.name,
        'planting_date': _formatDate(_plantingDate),
        'expected_harvest': _harvestDate != null ? _formatDate(_harvestDate!) : null,
        'field_size_ha': double.tryParse(_fieldSizeController.text) ?? 0,
        'pesticides': _pesticidesController.text,
        'fertilizer_type': _fertilizerType,
        'irrigation_method': _irrigationMethod,
        'soil_type': _soilType,
        'expected_yield_kg': double.tryParse(_expectedYieldController.text) ?? 0,
        'notes': _notesController.text,
      };

      await Supabase.instance.client
          .from('saturation_records')
          .insert(data);

      if (!mounted) return;
      setState(() => _isSaving = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded,
                  color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Planting record for ${widget.primaryCrop.name} saved successfully! 🌱',
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF43A047),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          duration: const Duration(seconds: 3),
        ),
      );

      Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving record: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
