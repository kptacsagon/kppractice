import 'package:flutter/material.dart';
import '../../models/agrisense_dss_model.dart';
import '../../services/agrisense_dss_service.dart';
import '../../theme/app_theme.dart';

class AgriSenseDssScreen extends StatefulWidget {
  const AgriSenseDssScreen({super.key});

  @override
  State<AgriSenseDssScreen> createState() => _AgriSenseDssScreenState();
}

class _AgriSenseDssScreenState extends State<AgriSenseDssScreen> {
  final AgriSenseDssService _service = AgriSenseDssService();
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _areaController = TextEditingController(
    text: '1.0',
  );

  late String _selectedCrop;
  late String _selectedRegion;
  late String _selectedSeason;
  AgriSenseResult? _result;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final crops = _service.supportedCrops;
    _selectedCrop = crops.first;
    _selectedRegion = AgriSenseDssService.supportedRegions.first;
    _selectedSeason = AgriSenseDssService.supportedSeasons.first;
  }

  @override
  void dispose() {
    _areaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('AgriSense DSS'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeroHeader(),
            const SizedBox(height: 16),
            _buildInputCard(),
            const SizedBox(height: 16),
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (_result != null)
              _buildResultSection(_result!)
            else
              _buildEmptyState(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0F2618), Color(0xFF123120)],
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(18),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(20),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.insights_rounded, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Planting Intelligence Center',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Generate season-aware supply forecasts and crop guidance for your area.',
                  style: TextStyle(color: Colors.white.withAlpha(180), fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputCard() {
    return Form(
      key: _formKey,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(8),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Scenario Inputs',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Fine-tune your planting plan to receive risk scoring and crop alternatives.',
              style: TextStyle(color: AppTheme.textMedium, fontSize: 12),
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              initialValue: _selectedCrop,
              decoration: const InputDecoration(
                labelText: 'Crop Type',
                prefixIcon: Icon(Icons.grass_rounded),
                isDense: true,
              ),
              items: _service.supportedCrops
                  .map((crop) => DropdownMenuItem(value: crop, child: Text(crop)))
                  .toList(),
              onChanged: (value) {
                if (value == null) return;
                setState(() => _selectedCrop = value);
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _selectedRegion,
              decoration: const InputDecoration(
                labelText: 'Region',
                prefixIcon: Icon(Icons.location_on_outlined),
                isDense: true,
              ),
              items: AgriSenseDssService.supportedRegions
                  .map(
                    (region) => DropdownMenuItem(value: region, child: Text(region)),
                  )
                  .toList(),
              onChanged: (value) {
                if (value == null) return;
                setState(() => _selectedRegion = value);
              },
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _areaController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Planned Area (ha)',
                      prefixIcon: Icon(Icons.crop_square_rounded),
                      isDense: true,
                    ),
                    validator: (value) {
                      final parsed = double.tryParse(value?.trim() ?? '');
                      if (parsed == null || parsed <= 0) {
                        return 'Enter a valid area';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _selectedSeason,
                    decoration: const InputDecoration(
                      labelText: 'Season',
                      prefixIcon: Icon(Icons.calendar_month_rounded),
                      isDense: true,
                    ),
                    items: AgriSenseDssService.supportedSeasons
                        .map(
                          (season) => DropdownMenuItem(value: season, child: Text(season)),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() => _selectedSeason = value);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _runEvaluation,
                icon: const Icon(Icons.insights_rounded, size: 18),
                label: const Text('Generate Forecast & Recommendation'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultSection(AgriSenseResult result) {
    return Column(
      children: [
        _buildRiskBanner(result),
        const SizedBox(height: 12),
        _buildKpiGrid(result),
        const SizedBox(height: 12),
        _buildRecommendationCard(result),
        const SizedBox(height: 12),
        _buildAlternativesList(result),
      ],
    );
  }

  Widget _buildRiskBanner(AgriSenseResult result) {
    final riskColor = _riskColor(result.recommendation.riskLevel);
    final tint = riskColor.withAlpha(18);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: tint,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: riskColor.withAlpha(90)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.warning_amber_rounded, color: riskColor, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Oversupply Risk: ${result.recommendation.riskLevel.toUpperCase()}',
                  style: TextStyle(color: riskColor, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  result.recommendation.summary,
                  style: const TextStyle(color: AppTheme.textDark),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                const Text(
                  'OSI',
                  style: TextStyle(fontSize: 10, color: AppTheme.textMedium),
                ),
                Text(
                  result.recommendation.osi.toStringAsFixed(2),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKpiGrid(AgriSenseResult result) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 520;
        final items = [
          _KpiItem(
            label: 'Projected Demand',
            value: '${result.forecast.projectedDemandMt.toStringAsFixed(1)} MT',
            icon: Icons.trending_up,
            color: const Color(0xFF1F7A5C),
          ),
          _KpiItem(
            label: 'Projected Supply',
            value: '${result.forecast.projectedSupplyMt.toStringAsFixed(1)} MT',
            icon: Icons.inventory_2_outlined,
            color: const Color(0xFF2E6FD3),
          ),
          _KpiItem(
            label: 'Projected Price',
            value: '₱${result.forecast.projectedPricePerKg.toStringAsFixed(2)}/kg',
            icon: Icons.payments_outlined,
            color: const Color(0xFF9B4F22),
          ),
          _KpiItem(
            label: 'Confidence',
            value: result.forecast.confidence.toUpperCase(),
            icon: Icons.verified_outlined,
            color: const Color(0xFF6A5ACD),
          ),
        ];

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: isWide ? 4 : 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: isWide ? 1.4 : 1.35,
          ),
          itemCount: items.length,
          itemBuilder: (context, index) => _buildKpiCard(items[index]),
        );
      },
    );
  }

  Widget _buildKpiCard(_KpiItem item) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: item.color.withAlpha(24),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(item.icon, color: item.color, size: 18),
          ),
          const SizedBox(height: 10),
          Text(
            item.label,
            style: const TextStyle(color: AppTheme.textMedium, fontSize: 11),
          ),
          const SizedBox(height: 6),
          Text(
            item.value,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationCard(AgriSenseResult result) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Decision Guidance',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            result.recommendation.primaryAction,
            style: const TextStyle(color: AppTheme.textDark, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          Text(
            'Price trend: ${result.forecast.priceTrend.toUpperCase()} • Confidence: ${result.forecast.confidence.toUpperCase()}',
            style: const TextStyle(color: AppTheme.textMedium, fontSize: 12),
          ),
          if (result.recommendation.triggeredRules.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 6),
            const Text('Triggered Rules', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            ...result.recommendation.triggeredRules.map(
              (rule) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text('• $rule', style: const TextStyle(color: AppTheme.textMedium, fontSize: 12)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAlternativesList(AgriSenseResult result) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Top 3 Alternative Crops',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          ...result.recommendation.alternatives.map(
            (alternative) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.background,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    alternative.cropType,
                    style: const TextStyle(fontWeight: FontWeight.w700, color: AppTheme.textDark),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Demand stability ${(alternative.demandStability * 100).toStringAsFixed(0)}% • '
                    'Season fit ${(alternative.seasonalSuitability * 100).toStringAsFixed(0)}% • '
                    'Trend ${alternative.priceTrend}',
                    style: const TextStyle(fontSize: 12, color: AppTheme.textMedium),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    alternative.reason,
                    style: const TextStyle(fontSize: 12, color: AppTheme.textMedium),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Icon(Icons.insights_outlined, size: 48, color: AppTheme.textLight),
          const SizedBox(height: 10),
          const Text(
            'Run a scenario to see demand, supply, and recommendation signals.',
            style: TextStyle(color: AppTheme.textMedium),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'Tip: adjust crop, region, and season to compare market pressure levels.',
            style: TextStyle(color: AppTheme.textLight, fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  

  Future<void> _runEvaluation() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final area = double.tryParse(_areaController.text.trim());
    if (area == null || area <= 0) return;

    setState(() => _isLoading = true);

    try {
      final input = AgriSenseInput(
        cropType: _selectedCrop,
        region: _selectedRegion,
        plannedAreaHa: area,
        season: _selectedSeason,
      );
      final result = _service.evaluate(input);
      if (!mounted) return;
      setState(() => _result = result);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to generate DSS output: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Color _riskColor(String risk) {
    switch (risk) {
      case 'high':
        return AppTheme.error;
      case 'moderate':
        return AppTheme.warning;
      default:
        return AppTheme.success;
    }
  }
}

class _KpiItem {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _KpiItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });
}
