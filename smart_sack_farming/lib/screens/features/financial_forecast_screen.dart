import 'package:flutter/material.dart';
import '../../services/financial_forecast_service.dart';
import '../../theme/app_theme.dart';

/// Financial forecasting screen that simulates profit margins, compares
/// crops economically, and provides risk assessment with scenario analysis.
class FinancialForecastScreen extends StatefulWidget {
  const FinancialForecastScreen({super.key});

  @override
  State<FinancialForecastScreen> createState() =>
      _FinancialForecastScreenState();
}

class _FinancialForecastScreenState extends State<FinancialForecastScreen> {
  final _service = FinancialForecastService();
  final _areaController = TextEditingController(text: '1.0');
  double _areaHa = 1.0;
  List<CropForecast> _forecasts = [];
  bool _isLoading = false;
  String? _selectedCrop;
  CropForecast? _detailedForecast;

  final _cropOptions = [
    'Rice', 'Corn', 'Tomato', 'Lettuce', 'Eggplant', 'Sweet Potato',
    'Carrot', 'Cabbage', 'Watermelon', 'Basil', 'Pepper', 'Spinach',
    // PSA OpenSTAT crops - Iloilo Region
    'Squash', 'Radish', 'Potato', 'Banana Saba', 'Banana Lakatan', 'Onion',
  ];
  final _selectedCrops = <String>{'Rice', 'Eggplant', 'Tomato'};

  @override
  void dispose() {
    _areaController.dispose();
    super.dispose();
  }

  Future<void> _runComparison() async {
    if (_selectedCrops.isEmpty) return;
    setState(() => _isLoading = true);
    try {
      _forecasts = await _service.compareCrops(
        cropTypes: _selectedCrops.toList(),
        areaHa: _areaHa,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _showDetail(String cropType) async {
    setState(() {
      _selectedCrop = cropType;
      _isLoading = true;
    });
    try {
      _detailedForecast = await _service.forecastCrop(
        cropType: cropType,
        areaHa: _areaHa,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Financial Forecast'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInputSection(),
            const SizedBox(height: 16),
            _buildCropSelector(),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _runComparison,
                icon: const Icon(Icons.compare_arrows, size: 18),
                label: const Text('Compare Crops'),
              ),
            ),
            if (_isLoading) ...[
              const SizedBox(height: 32),
              const Center(child: CircularProgressIndicator()),
            ],
            if (_forecasts.isNotEmpty && !_isLoading) ...[
              const SizedBox(height: 20),
              _buildComparisonTable(),
              const SizedBox(height: 20),
              ..._forecasts.map(_buildForecastCard),
            ],
            if (_detailedForecast != null && !_isLoading) ...[
              const SizedBox(height: 20),
              _buildDetailedAnalysis(_detailedForecast!),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInputSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Farm Area',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textDark)),
          const SizedBox(height: 8),
          TextField(
            controller: _areaController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Area in hectares',
              prefixIcon: Icon(Icons.landscape),
              isDense: true,
            ),
            onChanged: (v) => _areaHa = double.tryParse(v) ?? 1.0,
          ),
        ],
      ),
    );
  }

  Widget _buildCropSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Select Crops to Compare',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textDark)),
          const SizedBox(height: 4),
          const Text('Tap to select/deselect',
              style: TextStyle(fontSize: 12, color: AppTheme.textLight)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _cropOptions.map((crop) {
              final selected = _selectedCrops.contains(crop);
              return FilterChip(
                label: Text(crop,
                    style: TextStyle(
                      fontSize: 13,
                      color: selected ? Colors.white : AppTheme.textDark,
                    )),
                selected: selected,
                selectedColor: AppTheme.primary,
                checkmarkColor: Colors.white,
                onSelected: (val) {
                  setState(() {
                    if (val) {
                      _selectedCrops.add(crop);
                    } else {
                      _selectedCrops.remove(crop);
                    }
                  });
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildComparisonTable() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.leaderboard_rounded,
                  color: AppTheme.primary, size: 20),
              const SizedBox(width: 8),
              const Text('Profitability Ranking',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textDark)),
            ],
          ),
          const SizedBox(height: 12),
          ...List.generate(_forecasts.length, (i) {
            final f = _forecasts[i];
            final isProfit = f.expectedProfit >= 0;
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: i == 0
                    ? AppTheme.success.withAlpha(10)
                    : AppTheme.background,
                borderRadius: BorderRadius.circular(10),
                border: i == 0
                    ? Border.all(color: AppTheme.success.withAlpha(40))
                    : null,
              ),
              child: Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: i == 0
                          ? AppTheme.success
                          : AppTheme.textLight.withAlpha(30),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        '${i + 1}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: i == 0 ? Colors.white : AppTheme.textMedium,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(f.cropType,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 14)),
                        Text(
                          'ROI: ${f.roiPercent.toStringAsFixed(1)}% | ${f.trendEmoji} ${f.priceTrend}',
                          style: const TextStyle(
                              fontSize: 11, color: AppTheme.textMedium),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '₱${_formatNum(f.expectedProfit)}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: isProfit ? AppTheme.success : AppTheme.error,
                        ),
                      ),
                      Text(
                        isProfit ? 'profit' : 'loss',
                        style: TextStyle(
                          fontSize: 11,
                          color: isProfit ? AppTheme.success : AppTheme.error,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () => _showDetail(f.cropType),
                    icon: const Icon(Icons.info_outline, size: 20),
                    color: AppTheme.primary,
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildForecastCard(CropForecast f) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(6),
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
              Text(f.cropType,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600)),
              const Spacer(),
              Text(f.trendEmoji, style: const TextStyle(fontSize: 18)),
            ],
          ),
          const SizedBox(height: 12),
          // Scenario analysis
          Row(
            children: [
              _buildScenarioChip(
                  'Best', f.bestCaseProfit, AppTheme.success),
              const SizedBox(width: 8),
              _buildScenarioChip(
                  'Expected', f.expectedProfit, AppTheme.primary),
              const SizedBox(width: 8),
              _buildScenarioChip(
                  'Worst', f.worstCaseProfit, AppTheme.error),
            ],
          ),
          const SizedBox(height: 12),
          _buildMiniRow('Market Price', '₱${f.currentPricePerKg}/kg'),
          _buildMiniRow(
              'Projected Price', '₱${f.projectedPricePerKg.toStringAsFixed(1)}/kg'),
          _buildMiniRow('Break-even Yield',
              '${f.breakEvenYieldKg.toStringAsFixed(0)} kg'),
          _buildMiniRow('Break-even Price',
              '₱${f.breakEvenPricePerKg.toStringAsFixed(1)}/kg'),
          _buildMiniRow(
              'Profit Margin', '${f.profitMargin.toStringAsFixed(1)}%'),
        ],
      ),
    );
  }

  Widget _buildScenarioChip(String label, double profit, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
        decoration: BoxDecoration(
          color: color.withAlpha(15),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(label,
                style: TextStyle(
                    fontSize: 11,
                    color: color,
                    fontWeight: FontWeight.w500)),
            const SizedBox(height: 2),
            Text(
              '₱${_formatNum(profit)}',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: profit >= 0 ? color : AppTheme.error,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailedAnalysis(CropForecast f) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primary.withAlpha(60)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.analytics_rounded,
                  color: AppTheme.primary),
              const SizedBox(width: 8),
              Text('${f.cropType} — Detailed Cost Breakdown',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 16),
          ...f.costBreakdown.entries.map((e) {
            final pct = f.totalCost > 0 ? (e.value / f.totalCost * 100) : 0;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(e.key,
                          style: const TextStyle(
                              fontSize: 13, color: AppTheme.textMedium)),
                      Text('₱${_formatNum(e.value)} (${pct.toStringAsFixed(0)}%)',
                          style: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: pct / 100,
                      backgroundColor: AppTheme.border,
                      valueColor:
                          const AlwaysStoppedAnimation(AppTheme.primary),
                      minHeight: 6,
                    ),
                  ),
                ],
              ),
            );
          }),
          const Divider(height: 24),
          _buildMiniRow('Total Investment', '₱${_formatNum(f.totalCost)}'),
          _buildMiniRow('Expected Yield',
              '${f.expectedYieldKg.toStringAsFixed(0)} kg'),
          _buildMiniRow('Expected Revenue',
              '₱${_formatNum(f.expectedRevenue)}'),
          _buildMiniRow('Net Profit', '₱${_formatNum(f.expectedProfit)}',
              valueColor: f.expectedProfit >= 0
                  ? AppTheme.success
                  : AppTheme.error),
          _buildMiniRow('ROI', '${f.roiPercent.toStringAsFixed(1)}%',
              valueColor: f.roiPercent >= 0
                  ? AppTheme.success
                  : AppTheme.error),
        ],
      ),
    );
  }

  Widget _buildMiniRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 13, color: AppTheme.textMedium)),
          Text(value,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: valueColor ?? AppTheme.textDark)),
        ],
      ),
    );
  }

  String _formatNum(double value) {
    if (value.abs() >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M';
    }
    if (value.abs() >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}K';
    }
    return value.toStringAsFixed(0);
  }
}
