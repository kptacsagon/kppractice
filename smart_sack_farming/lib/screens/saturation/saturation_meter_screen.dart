import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../models/crop_data.dart';
import 'saturation_result_screen.dart';

class SaturationMeterScreen extends StatefulWidget {
  const SaturationMeterScreen({super.key});

  @override
  State<SaturationMeterScreen> createState() => _SaturationMeterScreenState();
}

class _SaturationMeterScreenState extends State<SaturationMeterScreen> {
  CropData? _selectedCrop;
  DateTime? _selectedPlantingDate;
  final TextEditingController _customCropController = TextEditingController();
  bool _isCustomCrop = false;
  String _searchQuery = '';
  String _selectedCategory = 'All';

  final List<String> _categories = [
    'All',
    'Vegetable',
    'Fruit',
    'Grain',
    'Herb',
    'Root Crop',
  ];

  List<CropData> get _filteredCrops {
    return CropData.allCrops.where((crop) {
      final matchesCategory =
          _selectedCategory == 'All' || crop.category == _selectedCategory;
      final matchesSearch =
          crop.name.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesCategory && matchesSearch;
    }).toList();
  }

  @override
  void dispose() {
    _customCropController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppTheme.textDark),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Saturation Meter',
          style: TextStyle(
            color: AppTheme.textDark,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 600;
          final padding = isMobile ? 16.0 : 20.0;

          return SingleChildScrollView(
            padding: EdgeInsets.all(padding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header card
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(padding),
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white.withAlpha(40),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.opacity_rounded,
                                color: Colors.white, size: 24),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Soil Saturation Analysis',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: isMobile ? 16 : 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Choose your crop and planting date to analyze soil moisture conditions.',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: isMobile ? 11 : 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Step  1: Select crop
                _buildStepHeader('1', 'Select Your Crop'),
                const SizedBox(height: 12),

                // Toggle: predefined vs custom
                Row(
                  children: [
                    _buildToggleChip('Choose Crop', !_isCustomCrop, () {
                      setState(() => _isCustomCrop = false);
                    }),
                    const SizedBox(width: 8),
                    _buildToggleChip('Custom Input', _isCustomCrop, () {
                      setState(() {
                        _isCustomCrop = true;
                        _selectedCrop = null;
                      });
                    }),
                  ],
                ),
                const SizedBox(height: 12),

                if (_isCustomCrop) ...[
                  // Custom crop input
                  Container(
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppTheme.border),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextField(
                          controller: _customCropController,
                          decoration: InputDecoration(
                            hintText: 'Enter crop name...',
                            hintStyle: const TextStyle(color: AppTheme.textLight),
                            prefixIcon: const Icon(Icons.eco_rounded,
                                color: AppTheme.primary),
                            filled: true,
                            fillColor: AppTheme.background,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'The system will estimate saturation based on general crop data.',
                          style: TextStyle(
                            color: AppTheme.textLight,
                            fontSize: 11,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  // Search bar
                  TextField(
                    onChanged: (v) => setState(() => _searchQuery = v),
                    decoration: InputDecoration(
                      hintText: 'Search crops...',
                      hintStyle: const TextStyle(color: AppTheme.textLight),
                      prefixIcon:
                          const Icon(Icons.search_rounded, color: AppTheme.primary),
                      filled: true,
                      fillColor: AppTheme.surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppTheme.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppTheme.border),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Category filter
                  SizedBox(
                    height: 36,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _categories.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 6),
                      itemBuilder: (context, index) {
                        final cat = _categories[index];
                        final isSelected = cat == _selectedCategory;
                        return GestureDetector(
                          onTap: () => setState(() => _selectedCategory = cat),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppTheme.primary
                                  : AppTheme.surface,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isSelected
                                    ? AppTheme.primary
                                    : AppTheme.border,
                              ),
                            ),
                            child: Text(
                              cat,
                              style: TextStyle(
                                color: isSelected
                                    ? Colors.white
                                    : AppTheme.textMedium,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Crop grid - responsive
                  _buildResponsiveCropGrid(constraints),
                ],

                const SizedBox(height: 24),

                // Step 2: Select planting date
                _buildStepHeader('2', 'When Do You Plan to Plant?'),
                const SizedBox(height: 12),
                _buildPlantingDateCard(),

                // Planting season card (if date selected)
                if (_selectedPlantingDate != null) ...[
                  const SizedBox(height: 20),
                  _buildSeasonCard(_selectedPlantingDate!),
                ],

                // Crop details card (if selected)
                if (_selectedCrop != null && !_isCustomCrop) ...[
                  const SizedBox(height: 20),
                  _buildCropInfoCard(_selectedCrop!),
                ],

                const SizedBox(height: 32),

                // Analyze button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _canAnalyze() ? _analyzeSaturation : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: AppTheme.border,
                      disabledForegroundColor: AppTheme.textLight,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.analytics_rounded, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Analyze Saturation',
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
          );
        },
      ),
    );
  }

  Widget _buildResponsiveCropGrid(BoxConstraints constraints) {
    // Determine grid columns based on screen width
    int crossAxisCount;
    if (constraints.maxWidth < 600) {
      crossAxisCount = 2; // Mobile: 2 columns
    } else if (constraints.maxWidth < 1000) {
      crossAxisCount = 3; // Tablet: 3 columns
    } else {
      crossAxisCount = 4; // Web: 4 columns
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 0.9,
      ),
      itemCount: _filteredCrops.length,
      itemBuilder: (context, index) {
        final crop = _filteredCrops[index];
        final isSelected = _selectedCrop?.name == crop.name;
        return GestureDetector(
          onTap: () => setState(() => _selectedCrop = crop),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppTheme.primary.withAlpha(15)
                  : AppTheme.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isSelected
                    ? AppTheme.primary
                    : AppTheme.border,
                width: isSelected ? 2 : 1,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: AppTheme.primary.withAlpha(30),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  crop.icon,
                  style: const TextStyle(fontSize: 28),
                ),
                const SizedBox(height: 6),
                Text(
                  crop.name,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected
                        ? FontWeight.w600
                        : FontWeight.w500,
                    color: isSelected
                        ? AppTheme.primary
                        : AppTheme.textDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  crop.category,
                  style: const TextStyle(
                    fontSize: 9,
                    color: AppTheme.textLight,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStepHeader(String step, String title) {
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: AppTheme.primary,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              step,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            color: AppTheme.textDark,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildToggleChip(String label, bool isActive, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? AppTheme.primary : AppTheme.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isActive ? AppTheme.primary : AppTheme.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.white : AppTheme.textMedium,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildPlantingDateCard() {
    return GestureDetector(
      onTap: _pickPlantingDate,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.border),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.primary.withAlpha(15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.calendar_today_rounded,
                  color: AppTheme.primary, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Planting Date',
                    style: TextStyle(
                      color: AppTheme.textLight,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _selectedPlantingDate != null
                        ? _formatDate(_selectedPlantingDate!)
                        : 'Tap to select a date',
                    style: TextStyle(
                      color: _selectedPlantingDate != null
                          ? AppTheme.textDark
                          : AppTheme.textLight,
                      fontSize: 14,
                      fontWeight: _selectedPlantingDate != null
                          ? FontWeight.w600
                          : FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                color: AppTheme.textLight),
          ],
        ),
      ),
    );
  }

  Widget _buildSeasonCard(DateTime plantingDate) {
    final season = SeasonHelper.getSeasonFromMonth(plantingDate.month);
    final seasonName = SeasonHelper.getSeasonName(season);
    final seasonEmoji = SeasonHelper.getSeasonEmoji(season);
    final seasonDesc = SeasonHelper.getSeasonDescription(season);
    final expectedMoisture = SeasonHelper.getExpectedMoisture(season);

    Color seasonColor;
    switch (season) {
      case PlantingSeason.monsoon:
        seasonColor = const Color(0xFF1E88E5);
      case PlantingSeason.summer:
        seasonColor = const Color(0xFFF57C00);
      case PlantingSeason.winter:
        seasonColor = const Color(0xFF00897B);
      case PlantingSeason.autumn:
        seasonColor = const Color(0xFFD4AF37);
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: seasonColor.withAlpha(12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: seasonColor.withAlpha(40)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(seasonEmoji, style: const TextStyle(fontSize: 28)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      seasonName,
                      style: TextStyle(
                        color: seasonColor,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      seasonDesc,
                      style: const TextStyle(
                        color: AppTheme.textMedium,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.background,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.water_drop_outlined, color: seasonColor, size: 18),
                const SizedBox(width: 8),
                Text(
                  'Expected soil moisture: ${expectedMoisture.toStringAsFixed(0)}%',
                  style: TextStyle(
                    color: seasonColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          if (_selectedCrop != null && !_isCustomCrop) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  SeasonHelper.isCropSuitableForSeason(_selectedCrop!, season)
                      ? Icons.check_circle_rounded
                      : Icons.info_rounded,
                  color: SeasonHelper.isCropSuitableForSeason(
                              _selectedCrop!, season)
                      ? AppTheme.success
                      : AppTheme.warning,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    SeasonHelper.isCropSuitableForSeason(_selectedCrop!, season)
                        ? '${_selectedCrop!.name} is ideal for ${seasonName.toLowerCase()}'
                        : '${_selectedCrop!.name} is not typically planted in ${seasonName.toLowerCase()}',
                    style: TextStyle(
                      color: SeasonHelper.isCropSuitableForSeason(
                                  _selectedCrop!, season)
                          ? AppTheme.success
                          : AppTheme.warning,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCropInfoCard(CropData crop) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(crop.icon, style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      crop.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textDark,
                      ),
                    ),
                    Text(
                      crop.description,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppTheme.textLight,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(color: AppTheme.divider),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildInfoChip(Icons.water_drop_outlined,
                  '${crop.idealMoistureMin.toInt()}–${crop.idealMoistureMax.toInt()}%', 'Ideal Moisture'),
              const SizedBox(width: 12),
              _buildInfoChip(Icons.timer_outlined, crop.growthDuration, 'Growth'),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildInfoChip(Icons.calendar_month_outlined,
                  crop.bestPlantingMonths.take(3).join(', '), 'Best Months'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: AppTheme.background,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppTheme.primary, size: 16),
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      color: AppTheme.textLight,
                      fontSize: 9,
                    ),
                  ),
                  Text(
                    value,
                    style: const TextStyle(
                      color: AppTheme.textDark,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _canAnalyze() {
    if (_isCustomCrop) {
      return _customCropController.text.trim().isNotEmpty &&
          _selectedPlantingDate != null;
    }
    return _selectedCrop != null && _selectedPlantingDate != null;
  }

  Future<void> _pickPlantingDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedPlantingDate ?? now,
      firstDate: now,
      lastDate: DateTime(now.year + 2),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.primary,
              onPrimary: Colors.white,
              surface: AppTheme.surface,
              onSurface: AppTheme.textDark,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedPlantingDate = picked);
    }
  }

  String _formatDate(DateTime date) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  String _getMonthAbbr(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[month - 1];
  }

  void _analyzeSaturation() {
    final month = _selectedPlantingDate!.month;
    final monthAbbr = _getMonthAbbr(month);

    CropData cropToAnalyze;

    if (_isCustomCrop) {
      cropToAnalyze = CropData(
        name: _customCropController.text.trim(),
        icon: '🌱',
        category: 'Custom',
        idealMoistureMin: 45,
        idealMoistureMax: 65,
        bestPlantingMonths: [],
        growthDuration: 'Varies',
        description: 'Custom crop entered by farmer.',
      );
    } else {
      cropToAnalyze = _selectedCrop!;
    }

    double simulatedMoisture;
    if ([6, 7, 8, 9, 10, 11].contains(month)) {
      simulatedMoisture = 65 + (month % 3) * 8.0;
    } else {
      simulatedMoisture = 35 + (month % 4) * 7.0;
    }

    final saturationLevel = cropToAnalyze.analyzeSaturation(simulatedMoisture);
    final isRecommendedMonth =
        cropToAnalyze.bestPlantingMonths.contains(monthAbbr);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SaturationResultScreen(
          crop: cropToAnalyze,
          plantingDate: _selectedPlantingDate!,
          soilMoisture: simulatedMoisture,
          saturationLevel: saturationLevel,
          isRecommendedMonth: isRecommendedMonth,
        ),
      ),
    );
  }
}
