import 'dart:math';
import 'package:flutter/material.dart';

const _kGreen = Color(0xFF1B7737);
const _kBackground = Color(0xFFF0F5F1);

// Tubungan, Iloilo — representative barangays
const _kBarangays = [
  'Alegre', 'Ayubo', 'Badiang', 'Bagunanay', 'Bantay',
  'Barasan', 'Bayuyan', 'Buenavista', 'Cadabdab', 'Calampitao',
  'Igcabidio', 'Igcabugao', 'Igdalaguit', 'Linaon', 'Molina',
  'Pinamacalan', 'Poblacion', 'Suclaran', 'Tigbawan', 'Victoria',
];

// Crops monitored by the MAO of Tubungan
const _kCrops = ['Rice', 'Corn', 'Eggplant', 'Tomato', 'Squash', 'Okra'];

// Simulated RSBSA-based saturation matrix (% — 0 = no production, 100 = severe oversupply)
final Map<String, Map<String, double>> _kSaturation = _buildSimulatedData();

// Production volume in MT — derived from RSBSA registrant counts and yield averages
final Map<String, Map<String, double>> _kVolume = _buildSimulatedVolumes();

Map<String, Map<String, double>> _buildSimulatedData() {
  final r = Random(2026);
  final result = <String, Map<String, double>>{};
  // Baseline saturation per crop (province-wide trend)
  const baselines = {
    'Rice': 78.0, 'Corn': 52.0, 'Eggplant': 65.0,
    'Tomato': 70.0, 'Squash': 45.0, 'Okra': 38.0,
  };
  for (final brgy in _kBarangays) {
    result[brgy] = {};
    for (final crop in _kCrops) {
      final base = baselines[crop]!;
      final jitter = (r.nextDouble() * 50) - 25; // ±25 variation
      final val = (base + jitter).clamp(5.0, 115.0);
      result[brgy]![crop] = val;
    }
  }
  return result;
}

Map<String, Map<String, double>> _buildSimulatedVolumes() {
  final r = Random(2027);
  final result = <String, Map<String, double>>{};
  for (final brgy in _kBarangays) {
    result[brgy] = {};
    for (final crop in _kCrops) {
      result[brgy]![crop] = 8 + r.nextDouble() * 75; // 8-83 MT
    }
  }
  return result;
}

Color _colorFor(double sat) {
  // 0 → green, 50 → yellow, 100+ → red
  if (sat <= 50) {
    final t = (sat / 50).clamp(0.0, 1.0);
    return Color.lerp(const Color(0xFF16A34A), const Color(0xFFFBBF24), t)!;
  }
  final t = ((sat - 50) / 50).clamp(0.0, 1.0);
  return Color.lerp(const Color(0xFFFBBF24), const Color(0xFFDC2626), t)!;
}

String _levelLabel(double sat) {
  if (sat < 40) return 'Low';
  if (sat < 65) return 'Moderate';
  if (sat < 85) return 'High';
  return 'Severe';
}

class AgrisenseSaturationHeatmapScreen extends StatefulWidget {
  const AgrisenseSaturationHeatmapScreen({super.key});

  @override
  State<AgrisenseSaturationHeatmapScreen> createState() => _AgrisenseSaturationHeatmapScreenState();
}

class _AgrisenseSaturationHeatmapScreenState extends State<AgrisenseSaturationHeatmapScreen> {
  String _cropFilter = 'All';

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
                  _buildTitleCard(),
                  const SizedBox(height: 14),
                  _buildSummaryStats(),
                  const SizedBox(height: 14),
                  _buildCropFilter(),
                  const SizedBox(height: 14),
                  _buildHeatmap(),
                  const SizedBox(height: 14),
                  _buildLegend(),
                  const SizedBox(height: 14),
                  _buildMethodologyNote(),
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
                  'Crop Saturation Heatmap',
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700),
                ),
                Text(
                  'Tubungan, Iloilo · MAO Records',
                  style: TextStyle(color: Color(0xFFB2D9B8), fontSize: 12),
                ),
              ],
            ),
          ),
          const Icon(Icons.map_rounded, color: Color(0xFFB2D9B8), size: 22),
        ],
      ),
    );
  }

  Widget _buildTitleCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_kGreen, Color(0xFF145C29)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Crop Market Saturation Index',
            style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          const Text(
            'Barangay-level oversupply concentration across Tubungan, Iloilo',
            style: TextStyle(color: Color(0xFFE4F1E7), fontSize: 12),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _HeaderStat(label: 'Barangays', value: '${_kBarangays.length}'),
              const SizedBox(width: 14),
              _HeaderStat(label: 'Crops Tracked', value: '${_kCrops.length}'),
              const SizedBox(width: 14),
              _HeaderStat(label: 'Source', value: 'RSBSA / MAO'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryStats() {
    int severe = 0, high = 0, moderate = 0, low = 0;
    for (final b in _kBarangays) {
      for (final c in _kCrops) {
        final v = _kSaturation[b]![c]!;
        if (v >= 85) severe++;
        else if (v >= 65) high++;
        else if (v >= 40) moderate++;
        else low++;
      }
    }
    final total = _kBarangays.length * _kCrops.length;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(8), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Saturation Distribution',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF1A1A1A)),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _StatPill(label: 'Severe', count: severe, total: total, color: const Color(0xFFDC2626))),
              const SizedBox(width: 6),
              Expanded(child: _StatPill(label: 'High', count: high, total: total, color: const Color(0xFFF59E0B))),
              const SizedBox(width: 6),
              Expanded(child: _StatPill(label: 'Moderate', count: moderate, total: total, color: const Color(0xFFFBBF24))),
              const SizedBox(width: 6),
              Expanded(child: _StatPill(label: 'Low', count: low, total: total, color: const Color(0xFF16A34A))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCropFilter() {
    final options = ['All', ..._kCrops];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(8), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          const Icon(Icons.filter_alt_rounded, size: 18, color: _kGreen),
          const SizedBox(width: 8),
          const Text('Filter:', style: TextStyle(fontSize: 13, color: Color(0xFF6B7280))),
          const SizedBox(width: 8),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                isExpanded: true,
                value: _cropFilter,
                items: options.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (v) => setState(() => _cropFilter = v ?? 'All'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeatmap() {
    final visibleCrops = _cropFilter == 'All' ? _kCrops : [_cropFilter];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(8), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row: crop names
            Row(
              children: [
                const SizedBox(width: 90),
                ...visibleCrops.map((c) => Container(
                      width: 60,
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      alignment: Alignment.center,
                      child: Text(
                        c,
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF374151)),
                      ),
                    )),
              ],
            ),
            const Divider(height: 1, color: Color(0xFFE5E7EB)),
            // Data rows
            ..._kBarangays.map((brgy) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    SizedBox(
                      width: 90,
                      child: Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: Text(
                          brgy,
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF1A1A1A)),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    ...visibleCrops.map((c) {
                      final sat = _kSaturation[brgy]![c]!;
                      final vol = _kVolume[brgy]![c]!;
                      return _HeatCell(saturation: sat, volumeMt: vol, crop: c, barangay: brgy);
                    }),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildLegend() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(8), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Saturation Legend',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF1A1A1A)),
          ),
          const SizedBox(height: 10),
          Container(
            height: 18,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              gradient: const LinearGradient(
                colors: [Color(0xFF16A34A), Color(0xFFFBBF24), Color(0xFFDC2626)],
                stops: [0.0, 0.5, 1.0],
              ),
            ),
          ),
          const SizedBox(height: 6),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('0%', style: TextStyle(fontSize: 10, color: Color(0xFF6B7280))),
              Text('50%', style: TextStyle(fontSize: 10, color: Color(0xFF6B7280))),
              Text('100%+', style: TextStyle(fontSize: 10, color: Color(0xFF6B7280))),
            ],
          ),
          const SizedBox(height: 10),
          const Row(
            children: [
              _LegendChip(color: Color(0xFF16A34A), label: 'Low — undersupply'),
              SizedBox(width: 8),
              _LegendChip(color: Color(0xFFFBBF24), label: 'Moderate — balanced'),
            ],
          ),
          const SizedBox(height: 6),
          const Row(
            children: [
              _LegendChip(color: Color(0xFFF59E0B), label: 'High — supply rising'),
              SizedBox(width: 8),
              _LegendChip(color: Color(0xFFDC2626), label: 'Severe — oversupply'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMethodologyNote() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.science_rounded, size: 16, color: Color(0xFFB45309)),
              SizedBox(width: 8),
              Text('Methodology', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF78350F))),
            ],
          ),
          SizedBox(height: 6),
          Text(
            'Saturation values are computed as the ratio of projected production (from RSBSA-registered farmer records and seasonal crop submissions) to estimated local market demand reported by the Municipal Agriculture Office (MAO) of Tubungan. Values above 85% indicate oversupply risk. Data shown here is simulated for demonstration; live deployment binds to agrisense_saturation_scores and agrisense_market_demands tables.',
            style: TextStyle(fontSize: 11, height: 1.4, color: Color(0xFF78350F)),
          ),
        ],
      ),
    );
  }
}

// ─── Components ───────────────────────────────────────────────────────────────

class _HeatCell extends StatelessWidget {
  final double saturation;
  final double volumeMt;
  final String crop;
  final String barangay;

  const _HeatCell({
    required this.saturation,
    required this.volumeMt,
    required this.crop,
    required this.barangay,
  });

  @override
  Widget build(BuildContext context) {
    final color = _colorFor(saturation);
    final textColor = saturation > 55 ? Colors.white : const Color(0xFF1A1A1A);
    return GestureDetector(
      onTap: () => _showCellDetail(context),
      child: Container(
        width: 56,
        height: 32,
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(6),
        ),
        alignment: Alignment.center,
        child: Text(
          saturation.toStringAsFixed(0),
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: textColor),
        ),
      ),
    );
  }

  void _showCellDetail(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(color: _colorFor(saturation), shape: BoxShape.circle),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('$crop in Brgy. $barangay',
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 2),
                      Text('Tubungan, Iloilo',
                          style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _DetailRow(label: 'Saturation Index', value: '${saturation.toStringAsFixed(1)}%'),
            _DetailRow(label: 'Saturation Level', value: _levelLabel(saturation)),
            _DetailRow(label: 'Projected Volume', value: '${volumeMt.toStringAsFixed(1)} MT'),
            _DetailRow(label: 'Recommendation', value: saturation >= 85
                ? 'Avoid planting — diversify crop'
                : saturation >= 65
                    ? 'Plan carefully — coordinate with neighbors'
                    : 'Safe to plant'),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Close'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
          Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1A1A1A))),
        ],
      ),
    );
  }
}

class _HeaderStat extends StatelessWidget {
  final String label;
  final String value;
  const _HeaderStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
        Text(label, style: const TextStyle(color: Color(0xFFB2D9B8), fontSize: 10)),
      ],
    );
  }
}

class _StatPill extends StatelessWidget {
  final String label;
  final int count;
  final int total;
  final Color color;
  const _StatPill({required this.label, required this.count, required this.total, required this.color});

  @override
  Widget build(BuildContext context) {
    final pct = total == 0 ? 0 : (count / total * 100).round();
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text('$count', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: color)),
          Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color)),
          Text('$pct%', style: const TextStyle(fontSize: 9, color: Color(0xFF6B7280))),
        ],
      ),
    );
  }
}

class _LegendChip extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendChip({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Row(
        children: [
          Container(
            width: 12, height: 12,
            decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3)),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(label, style: const TextStyle(fontSize: 10, color: Color(0xFF374151)), overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }
}
