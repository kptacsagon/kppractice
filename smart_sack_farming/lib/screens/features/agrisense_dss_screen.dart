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
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInputCard(),
            const SizedBox(height: 16),
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (_result != null)
              _buildResultCard(_result!)
            else
              _buildEmptyState(),
          ],
        ),
      ),
    );
  }

  Widget _buildInputCard() {
    return Container(
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
            'Planting Decision Input',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 12),
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
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            initialValue: _selectedRegion,
            decoration: const InputDecoration(
              labelText: 'Region',
              prefixIcon: Icon(Icons.location_on_outlined),
              isDense: true,
            ),
            items: AgriSenseDssService.supportedRegions
                .map(
                  (region) =>
                      DropdownMenuItem(value: region, child: Text(region)),
                )
                .toList(),
            onChanged: (value) {
              if (value == null) return;
              setState(() => _selectedRegion = value);
            },
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _areaController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Planned Farm Area (hectares)',
              prefixIcon: Icon(Icons.crop_square_rounded),
              isDense: true,
            ),
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            initialValue: _selectedSeason,
            decoration: const InputDecoration(
              labelText: 'Season',
              prefixIcon: Icon(Icons.calendar_month_rounded),
              isDense: true,
            ),
            items: AgriSenseDssService.supportedSeasons
                .map(
                  (season) =>
                      DropdownMenuItem(value: season, child: Text(season)),
                )
                .toList(),
            onChanged: (value) {
              if (value == null) return;
              setState(() => _selectedSeason = value);
            },
          ),
          const SizedBox(height: 12),
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
    );
  }

  Widget _buildResultCard(AgriSenseResult result) {
    final riskColor = _riskColor(result.recommendation.riskLevel);
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
          Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: riskColor),
              const SizedBox(width: 8),
              Text(
                'Risk: ${result.recommendation.riskLevel.toUpperCase()}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: riskColor,
                ),
              ),
              const Spacer(),
              Text(
                'OSI: ${result.recommendation.osi.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            result.recommendation.summary,
            style: const TextStyle(
              color: AppTheme.textDark,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            result.recommendation.primaryAction,
            style: const TextStyle(color: AppTheme.textMedium),
          ),
          const SizedBox(height: 12),
          const Divider(),
          const Text(
            'Forecast Output',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          _buildDetailRow(
            'Projected Demand',
            '${result.forecast.projectedDemandMt.toStringAsFixed(1)} MT',
          ),
          _buildDetailRow(
            'Projected Supply',
            '${result.forecast.projectedSupplyMt.toStringAsFixed(1)} MT',
          ),
          _buildDetailRow(
            'Projected Price',
            '₱${result.forecast.projectedPricePerKg.toStringAsFixed(2)}/kg',
          ),
          _buildDetailRow('Price Trend', result.forecast.priceTrend),
          _buildDetailRow(
            'Data Confidence',
            result.forecast.confidence.toUpperCase(),
          ),
          if (result.recommendation.triggeredRules.isNotEmpty) ...[
            const SizedBox(height: 10),
            const Divider(),
            const Text(
              'Triggered Decision Rules',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            ...result.recommendation.triggeredRules.map(
              (rule) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Text(
                  '• $rule',
                  style: const TextStyle(color: AppTheme.textMedium),
                ),
              ),
            ),
          ],
          const SizedBox(height: 10),
          const Divider(),
          const Text(
            'Top 3 Alternative Crops',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          ...result.recommendation.alternatives.map(
            (alternative) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.background,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    alternative.cropType,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Demand Stability: ${(alternative.demandStability * 100).toStringAsFixed(0)}% • '
                    'Seasonal Suitability: ${(alternative.seasonalSuitability * 100).toStringAsFixed(0)}% • '
                    'Trend: ${alternative.priceTrend}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textMedium,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    alternative.reason,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textMedium,
                    ),
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
      child: const Column(
        children: [
          Icon(Icons.insights_outlined, size: 48, color: AppTheme.textLight),
          SizedBox(height: 10),
          Text(
            'Enter your planting details to generate DSS output.',
            style: TextStyle(color: AppTheme.textMedium),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppTheme.textMedium)),
          Text(
            value,
            style: const TextStyle(
              color: AppTheme.textDark,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _runEvaluation() async {
    final area = double.tryParse(_areaController.text.trim());
    if (area == null || area <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid farm area.')),
      );
      return;
    }

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
