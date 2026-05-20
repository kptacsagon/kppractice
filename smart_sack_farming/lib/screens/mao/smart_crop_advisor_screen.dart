import 'package:flutter/material.dart';
import '../../data/tubungan_barangays.dart';

// ─── Color System ─────────────────────────────────────────────────────────────
const _kNavy = Color(0xFF0F2747);
const _kGreen = Color(0xFF1B7737);
const _kGold = Color(0xFFF59E0B);
const _kRed = Color(0xFFDC2626);
const _kBlue = Color(0xFF2563EB);
const _kTeal = Color(0xFF0891B2);
const _kOrange = Color(0xFFEA580C);
const _kBg = Color(0xFFF1F5F9);
const _kCard = Colors.white;
const _kBorder = Color(0xFFE2E8F0);
const _kMuted = Color(0xFF64748B);
const _kText = Color(0xFF0F172A);

// ─── Data Models ──────────────────────────────────────────────────────────────
class _CropRec {
  final String crop;
  final int score;
  final String riskLevel;
  final double pricePerKg;
  final int daysToMaturity;
  final List<String> reasons;
  final IconData icon;
  const _CropRec({
    required this.crop,
    required this.score,
    required this.riskLevel,
    required this.pricePerKg,
    required this.daysToMaturity,
    required this.reasons,
    required this.icon,
  });
}

class _CropRisk {
  final String crop;
  final int oversupplyPct;
  final String detail;
  final String level;
  const _CropRisk(this.crop, this.oversupplyPct, this.detail, this.level);
}

// ─── Widget ───────────────────────────────────────────────────────────────────
class SmartCropAdvisorScreen extends StatefulWidget {
  const SmartCropAdvisorScreen({super.key});

  @override
  State<SmartCropAdvisorScreen> createState() => _SmartCropAdvisorScreenState();
}

class _SmartCropAdvisorScreenState extends State<SmartCropAdvisorScreen> {
  String? _selectedBarangay;
  String _season = 'Wet Season (Jun-Nov)';
  String _budget = 'Medium (₱5K-15K)';
  String _farmSize = 'Small (<0.5 ha)';

  static const _seasons = [
    'Wet Season (Jun-Nov)',
    'Dry Season (Dec-May)',
  ];
  static const _budgets = [
    'Low (<₱5K)',
    'Medium (₱5K-15K)',
    'High (>₱15K)',
  ];
  static const _farmSizes = [
    'Small (<0.5 ha)',
    'Medium (0.5-1 ha)',
    'Large (>1 ha)',
  ];

  static const _cropRisks = [
    _CropRisk('Tomato', 89,
        'Declared 4,820 kg vs 2,500 kg demand', 'CRITICAL'),
    _CropRisk('Pechay', 60,
        'Declared 3,200 kg vs 2,000 kg demand', 'WARNING'),
    _CropRisk('Cabbage', 17,
        'Declared 2,800 kg vs 2,400 kg demand', 'CAUTION'),
  ];

  static const _recommendations = [
    _CropRec(
      crop: 'Onion',
      score: 92,
      riskLevel: 'Low',
      pricePerKg: 95.0,
      daysToMaturity: 120,
      reasons: [
        'Only 23% of local demand covered',
        'Strong institutional buyer demand',
        'Good farmgate price trend (+8.5%)',
      ],
      icon: Icons.bubble_chart_rounded,
    ),
    _CropRec(
      crop: 'Eggplant',
      score: 87,
      riskLevel: 'Low',
      pricePerKg: 25.0,
      daysToMaturity: 75,
      reasons: [
        'Consistent year-round demand',
        'Low current planting competition',
        'Suitable for Tubungan soil conditions',
      ],
      icon: Icons.eco_rounded,
    ),
    _CropRec(
      crop: 'Ampalaya',
      score: 81,
      riskLevel: 'Low',
      pricePerKg: 38.0,
      daysToMaturity: 65,
      reasons: [
        'High institutional demand (school feeding)',
        'MAO buyer linkage available',
        'Fast-growing, low input cost',
      ],
      icon: Icons.spa_rounded,
    ),
    _CropRec(
      crop: 'Okra',
      score: 74,
      riskLevel: 'Low',
      pricePerKg: 22.0,
      daysToMaturity: 55,
      reasons: [
        'Drought-tolerant crop',
        'Low competition in current season',
        'Good for small farms',
      ],
      icon: Icons.grass_rounded,
    ),
    _CropRec(
      crop: 'Sweet Corn',
      score: 68,
      riskLevel: 'Medium',
      pricePerKg: 15.0,
      daysToMaturity: 90,
      reasons: [
        'Growing demand from food processors',
        'Moderate competition',
        'Good as intercrop',
      ],
      icon: Icons.grain_rounded,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kNavy,
        foregroundColor: Colors.white,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Smart Crop Advisor', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
            Text('AI-powered crop planning recommendations', style: TextStyle(fontSize: 10.5, color: Color(0xFF93C5FD))),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPlanningParams(),
            const SizedBox(height: 4),
            _buildRiskCard(),
            const SizedBox(height: 4),
            _buildRecommendationsCard(),
            const SizedBox(height: 4),
            _buildAdvisoryNote(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // ─── Section 1: Planning Parameters ────────────────────────────────────────
  Widget _buildPlanningParams() {
    return _card(
      title: 'Planning Parameters',
      child: Column(
        children: [
          // Row 1
          LayoutBuilder(builder: (ctx, c) {
            final wide = c.maxWidth >= 500;
            return wide
                ? Row(
                    children: [
                      Expanded(child: _barangayDropdown()),
                      const SizedBox(width: 12),
                      Expanded(child: _paramDropdown('Season', _season, _seasons, (v) => setState(() => _season = v!))),
                    ],
                  )
                : Column(children: [
                    _barangayDropdown(),
                    const SizedBox(height: 10),
                    _paramDropdown('Season', _season, _seasons, (v) => setState(() => _season = v!)),
                  ]);
          }),
          const SizedBox(height: 10),
          // Row 2
          LayoutBuilder(builder: (ctx, c) {
            final wide = c.maxWidth >= 500;
            return wide
                ? Row(
                    children: [
                      Expanded(child: _paramDropdown('Budget Range', _budget, _budgets, (v) => setState(() => _budget = v!))),
                      const SizedBox(width: 12),
                      Expanded(child: _paramDropdown('Farm Size', _farmSize, _farmSizes, (v) => setState(() => _farmSize = v!))),
                    ],
                  )
                : Column(children: [
                    _paramDropdown('Budget Range', _budget, _budgets, (v) => setState(() => _budget = v!)),
                    const SizedBox(height: 10),
                    _paramDropdown('Farm Size', _farmSize, _farmSizes, (v) => setState(() => _farmSize = v!)),
                  ]);
          }),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: _kGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              icon: const Icon(Icons.auto_awesome_rounded, size: 18),
              label: const Text('Generate Recommendations', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
              onPressed: () => setState(() {}),
            ),
          ),
        ],
      ),
    );
  }

  Widget _barangayDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedBarangay,
      decoration: _inputDecoration('Barangay'),
      isExpanded: true,
      items: [
        const DropdownMenuItem<String>(value: null, child: Text('All Barangays', style: TextStyle(fontSize: 13))),
        ...kTubunganBarangays.map((b) => DropdownMenuItem(value: b, child: Text(b, style: const TextStyle(fontSize: 13)))),
      ],
      onChanged: (v) => setState(() => _selectedBarangay = v),
    );
  }

  Widget _paramDropdown(String label, String value, List<String> options, ValueChanged<String?> onChanged) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: _inputDecoration(label),
      isExpanded: true,
      items: options.map((o) => DropdownMenuItem(value: o, child: Text(o, style: const TextStyle(fontSize: 12)))).toList(),
      onChanged: onChanged,
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(fontSize: 12, color: _kMuted),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: _kBorder),
      ),
      isDense: true,
    );
  }

  // ─── Section 2: Crop Risk Analysis ─────────────────────────────────────────
  Widget _buildRiskCard() {
    return _card(
      title: '⚠️ Crops to Avoid This Season',
      child: Column(
        children: _cropRisks.map((r) {
          final levelColor = r.level == 'CRITICAL' ? _kRed : r.level == 'WARNING' ? _kOrange : _kGold;
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: levelColor.withAlpha(10),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: levelColor.withAlpha(60)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(color: levelColor, borderRadius: BorderRadius.circular(4)),
                      child: Text(r.level, style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w800)),
                    ),
                    const SizedBox(width: 8),
                    Text(r.crop, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: levelColor)),
                    const Spacer(),
                    Text(
                      '${r.oversupplyPct}% oversupplied',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: levelColor),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(r.detail, style: const TextStyle(fontSize: 11, color: _kMuted)),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: r.oversupplyPct / 100,
                    minHeight: 6,
                    backgroundColor: const Color(0xFFE2E8F0),
                    valueColor: AlwaysStoppedAnimation<Color>(levelColor),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // ─── Section 3: Recommendations ────────────────────────────────────────────
  Widget _buildRecommendationsCard() {
    final barangayLabel = _selectedBarangay ?? 'All Barangays';
    return _card(
      title: '✅ Recommended Crops for $barangayLabel',
      child: Column(
        children: _recommendations.map((rec) {
          final scoreColor = rec.score >= 80 ? _kGreen : rec.score >= 60 ? _kGold : _kRed;
          final riskColor = rec.riskLevel == 'Low' ? _kGreen : rec.riskLevel == 'Medium' ? _kGold : _kRed;

          return Container(
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _kCard,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: scoreColor.withAlpha(50)),
              boxShadow: [BoxShadow(color: Colors.black.withAlpha(6), blurRadius: 6, offset: const Offset(0, 2))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Score gauge
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: scoreColor,
                        shape: BoxShape.circle,
                        boxShadow: [BoxShadow(color: scoreColor.withAlpha(60), blurRadius: 8, spreadRadius: 2)],
                      ),
                      alignment: Alignment.center,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('${rec.score}', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900, height: 1)),
                          const Text('/100', style: TextStyle(color: Colors.white70, fontSize: 8, height: 1.2)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(rec.icon, size: 15, color: scoreColor),
                              const SizedBox(width: 5),
                              Text(rec.crop, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: _kText)),
                              const Spacer(),
                              _badge(rec.riskLevel + ' Risk', riskColor),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(children: [
                            _infoBadge(Icons.attach_money_rounded, '₱${rec.pricePerKg.toStringAsFixed(0)}/kg', _kGreen),
                            const SizedBox(width: 10),
                            _infoBadge(Icons.schedule_rounded, '${rec.daysToMaturity} days', _kTeal),
                          ]),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const Divider(height: 1, color: _kBorder),
                const SizedBox(height: 10),
                ...rec.reasons.map((r) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.check_circle_rounded, size: 13, color: scoreColor),
                      const SizedBox(width: 6),
                      Expanded(child: Text(r, style: const TextStyle(fontSize: 11.5, color: _kText, height: 1.4))),
                    ],
                  ),
                )),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: scoreColor,
                      side: BorderSide(color: scoreColor),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    icon: const Icon(Icons.add_rounded, size: 16),
                    label: Text('Add to Declaration', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: scoreColor)),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Declaration planning noted for ${rec.crop}'),
                          behavior: SnackBarBehavior.floating,
                          backgroundColor: _kGreen,
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // ─── Section 4: Advisory Note ───────────────────────────────────────────────
  Widget _buildAdvisoryNote() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kBlue.withAlpha(12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kBlue.withAlpha(60)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline_rounded, color: _kBlue, size: 20),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'These recommendations are generated from current crop declaration data, market demand records, historical price trends, and seasonal patterns. Consult your BAW before making final planting decisions.',
              style: TextStyle(fontSize: 12, color: _kText, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Helpers ────────────────────────────────────────────────────────────────
  Widget _card({required String title, required Widget child}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(8), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Text(title, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: _kText)),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: child,
          ),
        ],
      ),
    );
  }

  Widget _badge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withAlpha(60)),
      ),
      child: Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color)),
    );
  }

  Widget _infoBadge(IconData icon, String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 3),
        Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
      ],
    );
  }
}
