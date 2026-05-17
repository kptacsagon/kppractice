import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../mock/agrisense_mock_data.dart';
import '../../models/agrisense_saturation_score.dart';
import '../../repositories/agrisense_repository.dart';

const _kGreen = Color(0xFF1B7737);
const _kGreenDark = Color(0xFF145C29);
const _kBackground = Color(0xFFF0F5F1);

// High-value pakbet crops
const _kCrops = [
  'Ampalaya',
  'Eggplant',
  'Okra',
  'Squash',
  'String Bean',
  'Tomato',
  'Garlic',
  'Onion',
];

const _kMonths = [
  'January', 'February', 'March', 'April', 'May', 'June',
  'July', 'August', 'September', 'October', 'November', 'December',
];

// Mock SRS fallback values — pakbet high-value crops
const _kMockSrs = {
  'Ampalaya': 43.0,
  'Eggplant': 68.0,
  'Okra': 40.0,
  'Squash': 50.0,
  'String Bean': 52.0,
  'Tomato': 78.0,
  'Garlic': 62.0,
  'Onion': 85.0,
};

class AgrisenseCpaScreen extends StatefulWidget {
  const AgrisenseCpaScreen({super.key});

  @override
  State<AgrisenseCpaScreen> createState() => _AgrisenseCpaScreenState();
}

class _AgrisenseCpaScreenState extends State<AgrisenseCpaScreen> {
  String? _selectedCrop;
  DateTime _plantingDate = DateTime.now();

  bool _isLoading = false;
  _AdvisorResult? _result;
  String _municipality = '';

  @override
  void initState() {
    super.initState();
    _loadMunicipality();
  }

  Future<void> _loadMunicipality() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) {
        setState(() => _municipality = AgrisenseMockData.profile.municipality);
        return;
      }
      final repo = AgrisenseRepository(Supabase.instance.client);
      final profile = await repo.getFarmerProfile(userId);
      if (mounted) {
        setState(() => _municipality = profile?.municipality ?? AgrisenseMockData.profile.municipality);
      }
    } catch (_) {
      if (mounted) setState(() => _municipality = AgrisenseMockData.profile.municipality);
    }
  }

  String _seasonLabel(DateTime date) {
    final month = date.month;
    final year = date.year;
    if (month >= 6 && month <= 10) return 'Wet Season $year';
    final y = month >= 11 ? year : year - 1;
    return 'Dry Season $y-${y + 1}';
  }

  Future<void> _pickDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _plantingDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(DateTime.now().year + 2, 12, 31),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: _kGreen, onPrimary: Colors.white),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() { _plantingDate = picked; _result = null; });
  }

  Future<void> _analyze() async {
    if (_selectedCrop == null) return;
    setState(() { _isLoading = true; _result = null; });

    try {
      final season = _seasonLabel(_plantingDate);
      final client = Supabase.instance.client;

      // Fetch all saturation scores for this municipality (any season)
      final response = await client
          .from('agrisense_saturation_scores')
          .select()
          .eq('municipality', _municipality)
          .order('srs_score', ascending: true);

      final allScores = (response as List)
          .map((j) => AgrisenseSaturationScore.fromJson(j))
          .toList();

      // Find this crop's score (case-insensitive)
      AgrisenseSaturationScore? match;
      for (final s in allScores) {
        if (s.cropType.toLowerCase() == _selectedCrop!.toLowerCase()) {
          match = s;
          break;
        }
      }

      final srs = match?.srsScore ?? (_kMockSrs[_selectedCrop] ?? 60.0);

      // Alternatives: other crops with lower SRS, sorted best first
      List<_CropOption> alternatives;
      final dbAlts = allScores
          .where((s) => s.cropType.toLowerCase() != _selectedCrop!.toLowerCase() && s.srsScore < srs)
          .map((s) => _CropOption(s.cropType, s.srsScore))
          .toList();

      alternatives = dbAlts.isNotEmpty ? dbAlts : _buildMockAlternatives(_selectedCrop!, srs);

      if (mounted) {
        setState(() {
          _result = _AdvisorResult(
            crop: _selectedCrop!,
            plantingDate: _plantingDate,
            season: season,
            srs: srs,
            supplyMt: match?.projectedSupplyMt,
            demandMt: match?.projectedDemandMt,
            priceMin: match?.priceForecastMin,
            priceMax: match?.priceForecastMax,
            alternatives: alternatives,
          );
          _isLoading = false;
        });
      }
    } catch (_) {
      // Full mock fallback
      final srs = _kMockSrs[_selectedCrop] ?? 60.0;
      if (mounted) {
        setState(() {
          _result = _AdvisorResult(
            crop: _selectedCrop!,
            plantingDate: _plantingDate,
            season: _seasonLabel(_plantingDate),
            srs: srs,
            alternatives: _buildMockAlternatives(_selectedCrop!, srs),
          );
          _isLoading = false;
        });
      }
    }
  }

  List<_CropOption> _buildMockAlternatives(String selected, double srs) {
    return _kMockSrs.entries
        .where((e) => e.key != selected && e.value < srs)
        .map((e) => _CropOption(e.key, e.value))
        .toList()
      ..sort((a, b) => a.srs.compareTo(b.srs));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBackground,
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInputCard(),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _selectedCrop == null || _isLoading ? null : _analyze,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _kGreen,
                        disabledBackgroundColor: const Color(0xFFB0B0B0),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20, width: 20,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : const Text('Analyze Saturation'),
                    ),
                  ),
                  if (_result != null) ...[
                    const SizedBox(height: 20),
                    _ResultCard(result: _result!),
                  ],
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    return Container(
      color: _kGreen,
      padding: EdgeInsets.fromLTRB(16, topPad + 12, 16, 14),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.maybePop(context),
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Crop Planting Advisor',
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700),
                ),
                Text(
                  'Check saturation before you plant',
                  style: TextStyle(color: Color(0xFFB2D9B8), fontSize: 12),
                ),
              ],
            ),
          ),
          const Icon(Icons.eco_rounded, color: Color(0xFFB2D9B8), size: 22),
        ],
      ),
    );
  }

  Widget _buildInputCard() {
    final dateLabel =
        '${_kMonths[_plantingDate.month - 1]} ${_plantingDate.day}, ${_plantingDate.year}';
    final season = _seasonLabel(_plantingDate);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 10, offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'What do you want to plant?',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF1A1A1A)),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFE5E7EB)),
              borderRadius: BorderRadius.circular(10),
              color: const Color(0xFFF9FAFB),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                isExpanded: true,
                value: _selectedCrop,
                hint: const Text('Select a crop', style: TextStyle(color: Color(0xFF9CA3AF))),
                items: _kCrops.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (v) => setState(() { _selectedCrop = v; _result = null; }),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'When do you plan to plant?',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF1A1A1A)),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () => _pickDate(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFE5E7EB)),
                borderRadius: BorderRadius.circular(10),
                color: const Color(0xFFF9FAFB),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today_rounded, size: 18, color: _kGreen),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          dateLabel,
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1A1A1A)),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          season,
                          style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF)),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded, size: 20, color: Color(0xFF9CA3AF)),
                ],
              ),
            ),
          ),
          if (_municipality.isNotEmpty) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.location_on_rounded, size: 14, color: Color(0xFF9CA3AF)),
                const SizedBox(width: 4),
                Text(
                  'Municipality: $_municipality',
                  style: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Result Card ──────────────────────────────────────────────────────────────

class _ResultCard extends StatelessWidget {
  final _AdvisorResult result;
  const _ResultCard({required this.result});

  @override
  Widget build(BuildContext context) {
    final tier = _srsTier(result.srs);
    final isSafe = result.srs <= 60;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Main result
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 10, offset: const Offset(0, 3)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: tier.color.withAlpha(20),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        result.srs.toStringAsFixed(0),
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: tier.color,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          result.crop,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF1A1A1A)),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${_kMonths[result.plantingDate.month - 1]} ${result.plantingDate.day}, ${result.plantingDate.year} · ${result.season}',
                          style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: tier.color.withAlpha(20),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            tier.label,
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: tier.color),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              // SRS bar
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Saturation Risk Score (SRS)', style: TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
                      Text('${result.srs.toStringAsFixed(1)} / 100', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: tier.color)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: (result.srs / 100).clamp(0.0, 1.0),
                      backgroundColor: const Color(0xFFE5E7EB),
                      valueColor: AlwaysStoppedAnimation<Color>(tier.color),
                      minHeight: 8,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Text('Safe', style: TextStyle(fontSize: 10, color: Color(0xFF16A34A))),
                      Text('Moderate', style: TextStyle(fontSize: 10, color: Color(0xFFF59E0B))),
                      Text('High', style: TextStyle(fontSize: 10, color: Color(0xFFDC2626))),
                      Text('Critical', style: TextStyle(fontSize: 10, color: Color(0xFF7F1D1D))),
                    ],
                  ),
                ],
              ),
              // Supply / Demand row
              if (result.supplyMt != null && result.demandMt != null) ...[
                const SizedBox(height: 14),
                const Divider(height: 1, color: Color(0xFFF3F4F6)),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(child: _InfoTile(label: 'Projected Supply', value: '${result.supplyMt!.toStringAsFixed(1)} MT')),
                    const SizedBox(width: 10),
                    Expanded(child: _InfoTile(label: 'Projected Demand', value: '${result.demandMt!.toStringAsFixed(1)} MT')),
                  ],
                ),
              ],
              // Price forecast
              if (result.priceMin != null && result.priceMax != null) ...[
                const SizedBox(height: 10),
                _InfoTile(
                  label: 'Price Forecast',
                  value: '₱${result.priceMin!.toStringAsFixed(2)} – ₱${result.priceMax!.toStringAsFixed(2)} / kg',
                ),
              ],
              // Verdict
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isSafe ? const Color(0xFFDCFCE7) : const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: isSafe ? const Color(0xFF86EFAC) : const Color(0xFFFCA5A5)),
                ),
                child: Row(
                  children: [
                    Icon(
                      isSafe ? Icons.check_circle_rounded : Icons.warning_rounded,
                      color: isSafe ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        isSafe
                            ? 'Good choice! ${result.crop} has manageable saturation for ${result.season}.'
                            : '${result.crop} is ${tier.label.toLowerCase()} for ${result.season}. Consider alternatives below.',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isSafe ? const Color(0xFF166534) : const Color(0xFF991B1B),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Alternatives section
        if (!isSafe && result.alternatives.isNotEmpty) ...[
          const SizedBox(height: 16),
          const Text(
            'Recommended Alternatives',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF1A1A1A)),
          ),
          const SizedBox(height: 4),
          const Text(
            'These crops have lower saturation risk for the same period.',
            style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
          ),
          const SizedBox(height: 10),
          ...result.alternatives.take(6).map((alt) => _AltCropTile(option: alt)),
        ],
      ],
    );
  }

  _TierData _srsTier(double srs) {
    if (srs > 100) return _TierData('Critical', const Color(0xFF7F1D1D));
    if (srs > 80) return _TierData('High Risk', const Color(0xFFDC2626));
    if (srs > 60) return _TierData('Moderate', const Color(0xFFF59E0B));
    return _TierData('Safe', const Color(0xFF16A34A));
  }
}

class _AltCropTile extends StatelessWidget {
  final _CropOption option;
  const _AltCropTile({required this.option});

  @override
  Widget build(BuildContext context) {
    final tier = _tier(option.srs);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withAlpha(8), blurRadius: 6, offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFDCFCE7),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.grass_rounded, color: _kGreen, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(option.crop, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1A1A1A))),
                const SizedBox(height: 2),
                Text(
                  'SRS ${option.srs.toStringAsFixed(0)} — ${tier.label}',
                  style: TextStyle(fontSize: 12, color: tier.color, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: tier.color.withAlpha(20),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Lower Risk',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: tier.color),
            ),
          ),
        ],
      ),
    );
  }

  _TierData _tier(double srs) {
    if (srs > 80) return _TierData('High Risk', const Color(0xFFDC2626));
    if (srs > 60) return _TierData('Moderate', const Color(0xFFF59E0B));
    return _TierData('Safe', const Color(0xFF16A34A));
  }
}

class _InfoTile extends StatelessWidget {
  final String label;
  final String value;
  const _InfoTile({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 10, color: Color(0xFF9CA3AF))),
          const SizedBox(height: 3),
          Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF1A1A1A))),
        ],
      ),
    );
  }
}

// ─── Data Models ─────────────────────────────────────────────────────────────

class _AdvisorResult {
  final String crop;
  final DateTime plantingDate;
  final String season;
  final double srs;
  final double? supplyMt;
  final double? demandMt;
  final double? priceMin;
  final double? priceMax;
  final List<_CropOption> alternatives;

  const _AdvisorResult({
    required this.crop,
    required this.plantingDate,
    required this.season,
    required this.srs,
    this.supplyMt,
    this.demandMt,
    this.priceMin,
    this.priceMax,
    required this.alternatives,
  });
}

class _CropOption {
  final String crop;
  final double srs;
  const _CropOption(this.crop, this.srs);
}

class _TierData {
  final String label;
  final Color color;
  const _TierData(this.label, this.color);
}
