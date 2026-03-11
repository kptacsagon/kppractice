import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../models/crop_data.dart';
import '../farmer/create_crop_listing_screen.dart';
import 'mix_match_screen.dart';
import 'saturation_meter_screen.dart';
import 'planting_record_form_screen.dart';

class SaturationResultScreen extends StatelessWidget {
  final CropData crop;
  final DateTime plantingDate;
  final double waterAvailability;
  final SaturationLevel saturationLevel;
  final bool isRecommendedMonth;

  const SaturationResultScreen({
    super.key,
    required this.crop,
    required this.plantingDate,
    required this.waterAvailability,
    required this.saturationLevel,
    required this.isRecommendedMonth,
  });

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
          'Analysis Result',
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
          return SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: constraints.maxWidth < 600 ? 16 : 20,
              vertical: 20,
            ),
            child: Column(
              children: [
                // Main result card
                _buildResultCard(context),
                const SizedBox(height: 20),

            // Details card
            _buildDetailsCard(),
            const SizedBox(height: 20),

            // Recommendation card
            _buildRecommendationCard(),
            const SizedBox(height: 24),

            // Action buttons based on saturation level
            if (saturationLevel == SaturationLevel.high)
              _buildHighSaturationActions(context)
            else if (saturationLevel == SaturationLevel.low)
              _buildLowSaturationActions(context)
            else
              _buildMediumSaturationActions(context),

            const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildResultCard(BuildContext context) {
    final color = _getSaturationColor();
    final label = _getSaturationLabel();
    final emoji = _getSaturationEmoji();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withAlpha(20),
            color.withAlpha(8),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withAlpha(40)),
      ),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 48)),
          const SizedBox(height: 12),
          Text(
            '$label Saturation',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _getSaturationDescription(),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppTheme.textMedium,
              fontSize: 14,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: color.withAlpha(20),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(crop.icon, style: const TextStyle(fontSize: 18)),
                const SizedBox(width: 8),
                Text(
                  crop.name,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsCard() {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Analysis Details',
            style: TextStyle(
              color: AppTheme.textDark,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 14),
          _buildDetailRow(
            Icons.eco_rounded,
            'Crop',
            '${crop.icon} ${crop.name}',
          ),
          _buildDetailRow(
            Icons.category_rounded,
            'Category',
            crop.category,
          ),
          _buildSeasonDetailRow(),
          _buildDetailRow(
            Icons.calendar_today_rounded,
            'Planting Date',
            '${months[plantingDate.month - 1]} ${plantingDate.day}, ${plantingDate.year}',
          ),
          _buildDetailRow(
            Icons.timer_outlined,
            'Growth Duration',
            crop.growthDuration,
          ),
          _buildDetailRow(
            Icons.water_drop_outlined,
            'Water Availability Index',
            '${waterAvailability.toStringAsFixed(1)}%',
          ),
          _buildDetailRow(
            Icons.check_circle_outline,
            'Planting Month',
            isRecommendedMonth ? '✅ Recommended' : '⚠️ Not ideal',
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.primary, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: AppTheme.textLight,
                fontSize: 12,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: AppTheme.textDark,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSeasonDetailRow() {
    final season = SeasonHelper.getSeasonFromMonth(plantingDate.month);
    final seasonName = SeasonHelper.getSeasonName(season);
    final seasonEmoji = SeasonHelper.getSeasonEmoji(season);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(Icons.calendar_today_rounded, color: AppTheme.primary, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Planting Season',
              style: const TextStyle(
                color: AppTheme.textLight,
                fontSize: 12,
              ),
            ),
          ),
          Row(
            children: [
              Text(seasonEmoji, style: const TextStyle(fontSize: 14)),
              const SizedBox(width: 4),
              Text(
                seasonName,
                style: const TextStyle(
                  color: AppTheme.textDark,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationCard() {
    final color = _getSaturationColor();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withAlpha(10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withAlpha(30)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.lightbulb_rounded, color: color, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Recommendation',
                  style: TextStyle(
                    color: color,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _getRecommendation(),
                  style: const TextStyle(
                    color: AppTheme.textMedium,
                    fontSize: 12,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---- HIGH SATURATION ACTIONS ----
  Widget _buildHighSaturationActions(BuildContext context) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF3E0),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFFFE0B2)),
          ),
          child: const Column(
            children: [
              Icon(Icons.warning_amber_rounded,
                  color: Color(0xFFF57C00), size: 28),
              SizedBox(height: 8),
              Text(
                'High saturation detected!',
                style: TextStyle(
                  color: Color(0xFFE65100),
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'You have 3 options to choose from:',
                style: TextStyle(
                  color: Color(0xFFBF360C),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Option 1: Proceed Anyway
        _buildActionButton(
          context,
          icon: Icons.arrow_forward_rounded,
          label: 'Proceed Anyway',
          subtitle: 'Plant despite high saturation (risky)',
          color: AppTheme.warning,
          onTap: () {
            _showProceedDialog(context);
          },
        ),
        const SizedBox(height: 10),

        // Option 2: Select Another Crop
        _buildActionButton(
          context,
          icon: Icons.swap_horiz_rounded,
          label: 'Select Another Crop',
          subtitle: 'Go back and choose a different crop',
          color: AppTheme.primary,
          onTap: () {
            // Navigate back to crop selection
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => const SaturationMeterScreen(),
              ),
            );
          },
        ),
        const SizedBox(height: 10),

        // Option 3: Mix & Match
        _buildActionButton(
          context,
          icon: Icons.grid_view_rounded,
          label: 'Mix & Match Crops',
          subtitle: 'Find complementary crops for this soil condition',
          color: const Color(0xFF7C4DFF),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => MixMatchScreen(
                  primaryCrop: crop,
                  waterAvailability: waterAvailability,
                  plantingDate: plantingDate,
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 10),

        // Option 4: Sell on Marketplace
        _buildActionButton(
          context,
          icon: Icons.storefront_rounded,
          label: 'Sell on Marketplace',
          subtitle: 'List your oversaturated crops for buyers',
          color: AppTheme.buyerColor,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => CreateCropListingScreen(
                  crop: crop,
                  saturationLevel: 'high',
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  // ---- MEDIUM SATURATION ACTIONS ----
  Widget _buildMediumSaturationActions(BuildContext context) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFE8F5E9),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFC8E6C9)),
          ),
          child: const Column(
            children: [
              Icon(Icons.check_circle_rounded,
                  color: Color(0xFF388E3C), size: 28),
              SizedBox(height: 8),
              Text(
                'Ideal conditions! Ready to plant.',
                style: TextStyle(
                  color: Color(0xFF1B5E20),
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton.icon(
            onPressed: () {
              _showProceedDialog(context);
            },
            icon: const Icon(Icons.agriculture_rounded, size: 20),
            label: const Text(
              'Proceed to Plant',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.success,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 0,
            ),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: OutlinedButton.icon(
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => const SaturationMeterScreen(),
                ),
              );
            },
            icon: const Icon(Icons.swap_horiz_rounded, size: 18),
            label: const Text('Try Another Crop'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.primary,
              side: const BorderSide(color: AppTheme.primary),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ---- LOW SATURATION ACTIONS ----
  Widget _buildLowSaturationActions(BuildContext context) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFFFEBEE),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFFFCDD2)),
          ),
          child: const Column(
            children: [
              Icon(Icons.water_drop_outlined,
                  color: Color(0xFFD32F2F), size: 28),
              SizedBox(height: 8),
              Text(
                'Low saturation — soil is too dry',
                style: TextStyle(
                  color: Color(0xFFB71C1C),
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Consider irrigating before planting.',
                style: TextStyle(
                  color: Color(0xFFC62828),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _buildActionButton(
          context,
          icon: Icons.arrow_forward_rounded,
          label: 'Proceed Anyway',
          subtitle: 'Plant despite low moisture (risky)',
          color: AppTheme.warning,
          onTap: () {
            _showProceedDialog(context);
          },
        ),
        const SizedBox(height: 10),
        _buildActionButton(
          context,
          icon: Icons.swap_horiz_rounded,
          label: 'Select Another Crop',
          subtitle: 'Pick a drought-tolerant crop instead',
          color: AppTheme.primary,
          onTap: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => const SaturationMeterScreen(),
              ),
            );
          },
        ),
        const SizedBox(height: 10),
        _buildActionButton(
          context,
          icon: Icons.grid_view_rounded,
          label: 'Mix & Match Crops',
          subtitle: 'Find crops suited for current conditions',
          color: const Color(0xFF7C4DFF),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => MixMatchScreen(
                  primaryCrop: crop,
                  waterAvailability: waterAvailability,
                  plantingDate: plantingDate,
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withAlpha(40)),
          boxShadow: [
            BoxShadow(
              color: color.withAlpha(10),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withAlpha(15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: color,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: AppTheme.textLight,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: color.withAlpha(80)),
          ],
        ),
      ),
    );
  }

  void _showProceedDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Text(crop.icon, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Proceed to Plant',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'You are about to proceed with planting ${crop.name}.',
              style: const TextStyle(
                color: AppTheme.textMedium,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.background,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                children: [
                  _buildDialogInfo('Water Availability Index', '${waterAvailability.toStringAsFixed(1)}%'),
                  const SizedBox(height: 4),
                  _buildDialogInfo('Saturation', _getSaturationLabel()),
                  const SizedBox(height: 4),
                  _buildDialogInfo('Risk Level',
                      saturationLevel == SaturationLevel.medium ? 'Low' : 'Moderate'),
                ],
              ),
            ),
            if (saturationLevel != SaturationLevel.medium) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.warning.withAlpha(15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, color: AppTheme.warning, size: 16),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Planting under non-ideal conditions may affect yield.',
                        style: TextStyle(
                          color: AppTheme.textMedium,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PlantingRecordFormScreen(
                    primaryCrop: crop,
                    plantingDate: plantingDate,
                    saturationLevel: saturationLevel,
                    waterAvailability: waterAvailability,
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  Widget _buildDialogInfo(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style:
                const TextStyle(color: AppTheme.textLight, fontSize: 12)),
        Text(value,
            style: const TextStyle(
                color: AppTheme.textDark,
                fontSize: 12,
                fontWeight: FontWeight.w600)),
      ],
    );
  }

  // ---- Helpers ----
  Color _getSaturationColor() {
    switch (saturationLevel) {
      case SaturationLevel.low:
        return const Color(0xFFE53935); // Red
      case SaturationLevel.medium:
        return const Color(0xFF43A047); // Green
      case SaturationLevel.high:
        return const Color(0xFF1E88E5); // Blue
    }
  }

  String _getSaturationLabel() {
    switch (saturationLevel) {
      case SaturationLevel.low:
        return 'Low';
      case SaturationLevel.medium:
        return 'Medium';
      case SaturationLevel.high:
        return 'High';
    }
  }

  String _getSaturationEmoji() {
    switch (saturationLevel) {
      case SaturationLevel.low:
        return '🏜️';
      case SaturationLevel.medium:
        return '✅';
      case SaturationLevel.high:
        return '💧';
    }
  }

  String _getSaturationDescription() {
    switch (saturationLevel) {
      case SaturationLevel.low:
        return 'The water availability is below the ideal range for ${crop.name}. The ground may be too dry for optimal growth.';
      case SaturationLevel.medium:
        return 'The water availability is within the ideal range for ${crop.name}. Conditions are favorable for planting!';
      case SaturationLevel.high:
        return 'The water availability exceeds the ideal range for ${crop.name}. The ground is oversaturated and may cause root issues.';
    }
  }

  String _getRecommendation() {
    final season = SeasonHelper.getSeasonFromMonth(plantingDate.month);
    final seasonName = SeasonHelper.getSeasonName(season).toLowerCase();
    final seasonRecommendation = _getSeasonSpecificTip(season);
    final monthWarning = !isRecommendedMonth
        ? ' Note: The selected planting month is not among the recommended months for this crop.'
        : '';

    switch (saturationLevel) {
      case SaturationLevel.low:
        return 'Consider irrigating the soil before planting during $seasonName. Or choose a drought-resistant crop that tolerates lower moisture levels. $seasonRecommendation$monthWarning';
      case SaturationLevel.medium:
        return 'Great conditions! You can proceed with planting ${crop.name} during $seasonName. Monitor moisture regularly. $seasonRecommendation$monthWarning';
      case SaturationLevel.high:
        return 'The soil is oversaturated for ${crop.name} during $seasonName. You can proceed with caution, select a water-loving crop, or try Mix & Match. $seasonRecommendation$monthWarning';
    }
  }

  String _getSeasonSpecificTip(PlantingSeason season) {
    switch (season) {
      case PlantingSeason.monsoon:
        return 'During monsoon, ensure proper drainage to prevent waterlogging.';
      case PlantingSeason.summer:
        return 'During summer, maintain consistent irrigation to combat heat stress.';
      case PlantingSeason.winter:
        return 'During winter, reduce watering frequency as evaporation is lower.';
      case PlantingSeason.autumn:
        return 'During autumn, gradually adjust watering as moisture patterns change.';
    }
  }
}
