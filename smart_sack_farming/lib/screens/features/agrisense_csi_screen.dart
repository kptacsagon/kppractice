import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../mock/agrisense_mock_data.dart';
import '../../models/agrisense_farmer_profile.dart';
import '../../models/agrisense_saturation_score.dart';
import '../../repositories/agrisense_repository.dart';

const _kGreen = Color(0xFF1B7737);

class AgrisenseCsiScreen extends StatefulWidget {
  const AgrisenseCsiScreen({super.key});

  @override
  State<AgrisenseCsiScreen> createState() => _AgrisenseCsiScreenState();
}

class _AgrisenseCsiScreenState extends State<AgrisenseCsiScreen> {
  AgrisenseFarmerProfile? _profile;
  List<AgrisenseSaturationScore> _scores = [];
  bool _loading = true;
  String? _error;
  String _selectedCrop = 'All';
  String _selectedSeason = 'Current';

  static const _cropFilters = ['All', 'Rice', 'Corn', 'Vegetables', 'Root Crops', 'Legumes'];
  static const _seasonFilters = ['Current', 'Upcoming', 'Previous'];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() { _loading = true; _error = null; });
    try {
      final client = Supabase.instance.client;
      final userId = client.auth.currentUser?.id;
      final profile = userId == null ? null : await AgrisenseRepository(client).getFarmerProfile(userId);
      final resolvedProfile = profile ?? AgrisenseMockData.profile;
      List<AgrisenseSaturationScore> scores = [];
      if (profile != null) {
        scores = await AgrisenseRepository(client).getSaturationScores(resolvedProfile.municipality, 'Wet');
      }
      if (!mounted) return;
      setState(() {
        _profile = resolvedProfile;
        _scores = scores.isNotEmpty ? scores : AgrisenseMockData.saturationScores;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _profile = AgrisenseMockData.profile;
        _scores = AgrisenseMockData.saturationScores;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F5F1),
      body: Column(
        children: [
          AgrisenseModuleHeader(
            title: 'Crop Saturation Intelligence',
            subtitle: 'Sub-Module 01 — CSI',
            icon: Icons.heat_pump_rounded,
          ),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) return const Center(child: CircularProgressIndicator(color: _kGreen));
    if (_error != null) {
      return Center(child: Text('Unable to load CSI data.\n$_error', textAlign: TextAlign.center,
          style: const TextStyle(color: Color(0xFF6B7280))));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SrsLegendCard(),
          const SizedBox(height: 14),
          _buildFilters(),
          const SizedBox(height: 14),
          _buildMapPlaceholder(),
          const SizedBox(height: 14),
          _buildZoneDetail(),
          const SizedBox(height: 14),
          _buildScoreList(),
          const SizedBox(height: 14),
          _buildNeighborAlert(),
          const SizedBox(height: 14),
          _buildUpdateCard(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Filter by Crop', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF6B7280))),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: _cropFilters.map((crop) {
              final selected = _selectedCrop == crop;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () => setState(() => _selectedCrop = crop),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: selected ? _kGreen : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: selected ? _kGreen : const Color(0xFFE5E7EB)),
                    ),
                    child: Text(
                      crop,
                      style: TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w600,
                        color: selected ? Colors.white : const Color(0xFF374151),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 12),
        const Text('Season', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF6B7280))),
        const SizedBox(height: 8),
        Row(
          children: _seasonFilters.map((s) {
            final selected = _selectedSeason == s;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () => setState(() => _selectedSeason = s),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: selected ? _kGreen : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: selected ? _kGreen : const Color(0xFFE5E7EB)),
                  ),
                  child: Text(
                    s,
                    style: TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w600,
                      color: selected ? Colors.white : const Color(0xFF374151),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildMapPlaceholder() {
    final municipality = _profile?.municipality ?? 'Your Municipality';
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(6), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Stack(
        children: [
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.map_rounded, size: 48, color: Colors.grey[300]),
                const SizedBox(height: 8),
                Text(
                  'CSI Heat Map — $municipality',
                  style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 13),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Tap a zone to view SRS details',
                  style: TextStyle(color: Color(0xFFD1D5DB), fontSize: 11),
                ),
              ],
            ),
          ),
          Positioned(
            top: 10,
            right: 10,
            child: _SrsBadge(srs: _scores.isEmpty ? null : _scores.first.srsScore),
          ),
        ],
      ),
    );
  }

  Widget _buildZoneDetail() {
    final top = _scores.isEmpty ? null : _scores.first;
    if (top == null) {
      return AgrisenseModuleCard(
        child: const Text('No zone data available. CSI data will appear after sync.',
            style: TextStyle(color: Color(0xFF6B7280), fontSize: 13)),
      );
    }

    final tier = _srsTier(top.srsScore);
    return AgrisenseModuleCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: tier.color.withAlpha(24),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(tier.label, style: TextStyle(color: tier.color, fontSize: 11, fontWeight: FontWeight.w700)),
              ),
              const Spacer(),
              Text(
                'SRS: ${top.srsScore.toStringAsFixed(0)}',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF1A1A1A)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _ZoneRow(label: 'Crop', value: top.cropType),
          _ZoneRow(label: 'Season', value: top.seasonName),
          _ZoneRow(label: 'Projected Supply', value: '${top.projectedSupplyMt.toStringAsFixed(1)} MT'),
          _ZoneRow(label: 'Projected Demand', value: '${top.projectedDemandMt.toStringAsFixed(1)} MT'),
          _ZoneRow(
            label: 'Price Forecast',
            value: top.priceForecastMin != null && top.priceForecastMax != null
                ? '₱${top.priceForecastMin!.toStringAsFixed(2)} – ₱${top.priceForecastMax!.toStringAsFixed(2)}/kg'
                : 'n/a',
          ),
          const SizedBox(height: 10),
          Text(
            tier.advice,
            style: TextStyle(fontSize: 12, color: tier.color, fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreList() {
    if (_scores.isEmpty) return const SizedBox.shrink();
    return AgrisenseModuleCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Latest CSI Scores', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          for (final score in _scores.take(5)) ...[
            _ScoreRow(score: score),
            if (score != _scores.take(5).last) const Divider(height: 16),
          ],
        ],
      ),
    );
  }

  Widget _buildNeighborAlert() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.people_rounded, color: Color(0xFFF59E0B), size: 18),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Neighbor Alert', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF92400E))),
                SizedBox(height: 4),
                Text(
                  'Multiple farmers in your barangay are planting the same crop in a similar harvest window. '
                  'Consider staggering your planting dates to reduce market flooding risk.',
                  style: TextStyle(fontSize: 12, color: Color(0xFF78350F)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUpdateCard() {
    return AgrisenseModuleCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Submit Market Update', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          const Text(
            'Report changes in supply or demand in your area to improve CSI accuracy for all farmers.',
            style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: _kGreen,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: _profile == null ? null : _openUpdateDialog,
            icon: const Icon(Icons.upload_rounded, size: 16),
            label: const Text('Submit Update'),
          ),
        ],
      ),
    );
  }

  _SrsTierData _srsTier(double srs) {
    if (srs >= 100) return _SrsTierData('Critical', const Color(0xFF7F1D1D), 'Supply significantly exceeds demand. Immediate action required.');
    if (srs >= 81) return _SrsTierData('High Risk', const Color(0xFFDC2626), 'Farm gate price expected to fall 15–30% below benchmark.');
    if (srs >= 61) return _SrsTierData('Moderate', const Color(0xFFF59E0B), 'Price softening likely at harvest. Monitor weekly.');
    return _SrsTierData('Safe', const Color(0xFF16A34A), 'Demand absorbs projected supply with headroom.');
  }

  Future<void> _openUpdateDialog() async {
    final cropController = TextEditingController(
      text: _profile?.primaryCrops.isNotEmpty == true ? _profile!.primaryCrops.first : '',
    );
    final noteController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('CSI Market Update'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: cropController, decoration: const InputDecoration(labelText: 'Crop')),
            const SizedBox(height: 12),
            TextField(controller: noteController, decoration: const InputDecoration(labelText: 'Update Notes'), maxLines: 3),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: _kGreen),
            onPressed: () {
              if (cropController.text.trim().isEmpty || noteController.text.trim().isEmpty) {
                ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Please fill all fields.')));
                return;
              }
              Navigator.pop(ctx, true);
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );

    if (result != true) return;
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Update submitted.')));
  }
}

class _SrsTierData {
  final String label;
  final Color color;
  final String advice;
  const _SrsTierData(this.label, this.color, this.advice);
}

class _SrsLegendCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AgrisenseModuleCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Saturation Risk Score (SRS)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          const Text('SRS = Projected Supply ÷ Estimated Local Demand × 100',
              style: TextStyle(fontSize: 11, color: Color(0xFF6B7280), fontStyle: FontStyle.italic)),
          const SizedBox(height: 12),
          const Row(
            children: [
              _LegendDot(color: Color(0xFF16A34A), label: '< 60 — Safe'),
              SizedBox(width: 12),
              _LegendDot(color: Color(0xFFF59E0B), label: '61–80 — Moderate'),
            ],
          ),
          const SizedBox(height: 6),
          const Row(
            children: [
              _LegendDot(color: Color(0xFFDC2626), label: '81–100 — High'),
              SizedBox(width: 12),
              _LegendDot(color: Color(0xFF7F1D1D), label: '> 100 — Critical'),
            ],
          ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF374151))),
      ],
    );
  }
}

class _SrsBadge extends StatelessWidget {
  final double? srs;
  const _SrsBadge({required this.srs});

  @override
  Widget build(BuildContext context) {
    if (srs == null) return const SizedBox.shrink();
    final color = srs! >= 100
        ? const Color(0xFF7F1D1D)
        : srs! >= 81
            ? const Color(0xFFDC2626)
            : srs! >= 61
                ? const Color(0xFFF59E0B)
                : const Color(0xFF16A34A);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(20)),
      child: Text('SRS ${srs!.toStringAsFixed(0)}',
          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
    );
  }
}

class _ZoneRow extends StatelessWidget {
  final String label;
  final String value;
  const _ZoneRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          SizedBox(
            width: 130,
            child: Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF))),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF1A1A1A))),
          ),
        ],
      ),
    );
  }
}

class _ScoreRow extends StatelessWidget {
  final AgrisenseSaturationScore score;
  const _ScoreRow({required this.score});

  @override
  Widget build(BuildContext context) {
    final color = score.srsScore >= 100
        ? const Color(0xFF7F1D1D)
        : score.srsScore >= 81
            ? const Color(0xFFDC2626)
            : score.srsScore >= 61
                ? const Color(0xFFF59E0B)
                : const Color(0xFF16A34A);

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(score.cropType, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              Text(score.seasonName, style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF))),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(color: color.withAlpha(20), borderRadius: BorderRadius.circular(8)),
          child: Text(
            score.srsScore.toStringAsFixed(0),
            style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 13),
          ),
        ),
      ],
    );
  }
}

// ─── Shared Widgets ───────────────────────────────────────────────────────────

class AgrisenseModuleHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;

  const AgrisenseModuleHeader({required this.title, required this.subtitle, required this.icon, super.key});

  @override
  Widget build(BuildContext context) {
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
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(color: Colors.white.withAlpha(30), borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
              Text(subtitle, style: const TextStyle(color: Color(0xFFB2D9B8), fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }
}

class AgrisenseModuleCard extends StatelessWidget {
  final Widget child;
  const AgrisenseModuleCard({required this.child, super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(8), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: child,
    );
  }
}
