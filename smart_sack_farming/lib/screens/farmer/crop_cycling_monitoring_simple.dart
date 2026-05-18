import 'package:flutter/material.dart';

/// Simplified Crop Cycling Monitor - High Value Crops (Pakbet Ingredients)
class CropCyclingMonitoringSimple extends StatefulWidget {
  const CropCyclingMonitoringSimple({Key? key}) : super(key: key);

  @override
  State<CropCyclingMonitoringSimple> createState() =>
      _CropCyclingMonitoringSimpleState();
}

class _CropCyclingMonitoringSimpleState extends State<CropCyclingMonitoringSimple> {
  // High-value pakbet crops
  final List<Map<String, dynamic>> highValueCrops = [
    {
      'name': 'Okra',
      'icon': '🫘',
      'color': Colors.green,
      'value': '₱150-200/kg',
      'season': 'Year-round',
      'rotationTip': 'Follow with legumes or leafy greens',
    },
    {
      'name': 'Eggplant',
      'icon': '🍆',
      'color': Colors.purple,
      'value': '₱80-120/kg',
      'season': 'October - May',
      'rotationTip': 'Alternate with squash or beans',
    },
    {
      'name': 'Bitter Melon (Ampalaya)',
      'icon': '🥒',
      'color': Colors.green.shade700,
      'value': '₱100-150/kg',
      'season': 'March - November',
      'rotationTip': 'Great after rice or corn',
    },
    {
      'name': 'Squash (Calabaza)',
      'icon': '🎃',
      'color': Colors.orange,
      'value': '₱30-50/kg',
      'season': 'August - December',
      'rotationTip': 'Plant after leafy greens',
    },
    {
      'name': 'Green Beans',
      'icon': '🫘',
      'color': Colors.green.shade600,
      'value': '₱120-180/kg',
      'season': 'November - March',
      'rotationTip': 'Nitrogen fixer, good for soil',
    },
    {
      'name': 'Tomato',
      'icon': '🍅',
      'color': Colors.red,
      'value': '₱60-100/kg',
      'season': 'November - May',
      'rotationTip': 'Rotate with cucurbits or legumes',
    },
  ];

  int _selectedCropIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Crop Cycling Monitor'),
            Text(
              'High-Value Pakbet Crops',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        elevation: 0,
        backgroundColor: Colors.teal,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header Card
            Container(
              color: Colors.teal.shade50,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Strategic Crop Rotation',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.teal,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Maximize yields with high-value crops from pakbet ingredients. Rotate seasonally for optimal soil health.',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),

            // Crop Cards
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.all(12),
              itemCount: highValueCrops.length,
              itemBuilder: (context, index) {
                final crop = highValueCrops[index];
                final isSelected = _selectedCropIndex == index;

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    border: isSelected
                        ? Border.all(color: Colors.teal, width: 2)
                        : Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(12),
                    color: isSelected ? Colors.teal.shade50 : Colors.white,
                  ),
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _selectedCropIndex = index;
                      });
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                crop['icon'],
                                style: const TextStyle(fontSize: 32),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      crop['name'],
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.amber.shade100,
                                            borderRadius:
                                                BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            crop['value'],
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.amber.shade900,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          crop['season'],
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                isSelected
                                    ? Icons.check_circle
                                    : Icons.radio_button_unchecked,
                                color: isSelected ? Colors.teal : Colors.grey,
                              ),
                            ],
                          ),
                          if (isSelected) ...[
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.teal.shade100,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    '💡 Rotation Recommendation',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.teal,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    crop['rotationTip'],
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.teal.shade800,
                                      height: 1.4,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),

            // Rotation Schedule Section
            Container(
              margin: const EdgeInsets.all(12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '📅 Recommended Rotation Schedule',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildRotationItem('Q1 (Jan-Mar)', 'Tomato, Green Beans'),
                  _buildRotationItem('Q2 (Apr-Jun)', 'Bitter Melon, Squash'),
                  _buildRotationItem('Q3 (Jul-Sep)', 'Okra, Eggplant'),
                  _buildRotationItem('Q4 (Oct-Dec)', 'Squash, Tomato'),
                ],
              ),
            ),

            // Benefits Section
            Container(
              margin: const EdgeInsets.all(12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '✨ Benefits of Crop Rotation',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildBenefit('Soil Health', 'Reduces disease buildup & pest cycles'),
                  _buildBenefit(
                      'Higher Yields', 'Balanced nutrients from different crops'),
                  _buildBenefit(
                      'Nitrogen Fixation', 'Legumes restore nitrogen naturally'),
                  _buildBenefit(
                      'Market Advantage', 'Year-round high-value crop availability'),
                ],
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildRotationItem(String period, String crops) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.blue,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              period,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              crops,
              style: TextStyle(
                fontSize: 12,
                color: Colors.blue.shade900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBenefit(String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.green,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
}
