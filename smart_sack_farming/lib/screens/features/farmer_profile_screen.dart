import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../repositories/farmer_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/yield_prediction_service.dart';

class FarmerProfileScreen extends StatefulWidget {
  final dynamic farmer;
  const FarmerProfileScreen({Key? key, required this.farmer}) : super(key: key);

  @override
  State<FarmerProfileScreen> createState() => _FarmerProfileScreenState();
}

class _FarmerProfileScreenState extends State<FarmerProfileScreen> {
  final FarmerRepository _repo = FarmerRepository();
  List<Map<String, dynamic>> _crops = [];
  Map<String, dynamic>? _farmerProfile;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadFarmerData();
  }

  Future<void> _loadFarmerData() async {
    setState(() => _loading = true);
    try {
      final farmerId = (widget.farmer.farmerId ?? widget.farmer.id ?? '').toString();

      if (farmerId.isEmpty) {
        if (mounted) {
          setState(() {
            _crops = [];
            _farmerProfile = null;
            _loading = false;
          });
        }
        return;
      }

      Map<String, dynamic>? profile;
      try {
        final profileResponse = await Supabase.instance.client
            .from('profiles')
            .select('id, full_name, email, address')
            .eq('id', farmerId)
            .maybeSingle();
        if (profileResponse is Map<String, dynamic>) {
          profile = profileResponse;
        }
      } catch (e) {
        print('Error loading farmer profile: $e');
      }

      final crops = await _repo.fetchCropsForFarmer(farmerId);
      final resolvedName = (profile?['full_name'] ?? profile?['email'] ?? widget.farmer.name ?? 'Farmer').toString();
      final resolvedAddress = (profile?['address'] ?? widget.farmer.address)?.toString();
    final resolvedLandSize = widget.farmer.landSizeHa;
      
      if (mounted) {
        setState(() {
          _farmerProfile = {
            'id': farmerId,
            'full_name': resolvedName,
            'address': resolvedAddress,
            'land_size_ha': resolvedLandSize,
          };
          _crops = crops;
          _loading = false;
        });
      }
    } catch (e) {
      print('Error loading farmer data: $e');
      if (mounted) {
        setState(() {
          _crops = [];
          _farmerProfile = widget.farmer != null ? {
            'full_name': widget.farmer.name ?? 'Unknown',
            'address': widget.farmer.address,
            'land_size_ha': widget.farmer.landSizeHa,
            'age': null,
          } : null;
          _loading = false;
        });
      }
    }
  }

  String? _getYieldForCrop(String cropName, DateTime? harvestDate) {
    final yieldMtHa = YieldPredictionService.getMonthlyYieldMtHa(cropName, harvestDate);
    if (yieldMtHa == null) return null;
    return '${yieldMtHa.toStringAsFixed(2)} MT/HA';
  }

  @override
  Widget build(BuildContext context) {
    final farmerInfo = widget.farmer;
    final displayName = (_farmerProfile?['full_name'] ?? farmerInfo.name ?? 'Farmer').toString();
    final displayAddress = (_farmerProfile?['address'] ?? farmerInfo.address)?.toString();
    final displayLandSize = _farmerProfile?['land_size_ha'] ?? farmerInfo.landSizeHa;
    
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(displayName),
        backgroundColor: AppTheme.primary,
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Farmer Info Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(6),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 40,
                              backgroundColor: AppTheme.primary.withAlpha(80),
                              child: const Icon(Icons.person, size: 50, color: Colors.white),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    displayName,
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Location
                        if (displayAddress != null && displayAddress.isNotEmpty)
                          _buildInfoRow(Icons.location_on, 'Location', displayAddress),
                        if (displayAddress != null && displayAddress.isNotEmpty && displayLandSize != null)
                          const SizedBox(height: 12),
                        // Land Size
                        if (displayLandSize != null)
                          _buildInfoRow(Icons.landscape, 'Land Size', '$displayLandSize ha'),
                        // Barangay
                        if (farmerInfo.barangay != null && farmerInfo.barangay!.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          _buildInfoRow(Icons.map, 'Barangay', farmerInfo.barangay),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Planted Crops Section
                  const Text(
                    'Planted Crops',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textDark,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _crops.isEmpty
                      ? Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Column(
                              children: [
                                Icon(Icons.eco_outlined, size: 32, color: AppTheme.textLight),
                                const SizedBox(height: 8),
                                const Text(
                                  'No crop records found',
                                  style: TextStyle(color: AppTheme.textMedium),
                                ),
                              ],
                            ),
                          ),
                        )
                      : ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _crops.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (context, idx) => _buildCropCard(_crops[idx]),
                        ),
                ],
              ),
            ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String? value) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.primary, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppTheme.textMedium,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value ?? 'N/A',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textDark,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCropCard(Map<String, dynamic> crop) {
    // Extract and safely convert crop name
    final cropName = (crop['cropName'] ?? crop['crop_name'] ?? 'Unknown Crop').toString().trim();
    
    // Extract date values
    final plantingDateValue = crop['plantingDate'] ?? crop['planting_date'];
    final harvestDateValue = crop['expectedHarvestDate'] ?? crop['expected_harvest_date'];
    final landAreaValue = crop['landArea'] ?? crop['area_planted_ha'];

    // Format planting date
    String plantingDateDisplay = 'N/A';
    DateTime? parsedPlantingDate;
    if (plantingDateValue != null) {
      try {
        final dateStr = plantingDateValue is String ? plantingDateValue : plantingDateValue.toString();
        parsedPlantingDate = DateTime.parse(dateStr);
        plantingDateDisplay = _formatDate(parsedPlantingDate);
      } catch (e) {
        print('Error parsing planting date: $e');
      }
    }

    // Format harvest date
    String harvestDateDisplay = 'N/A';
    DateTime? parsedHarvestDate;
    if (harvestDateValue != null) {
      try {
        final dateStr = harvestDateValue is String ? harvestDateValue : harvestDateValue.toString();
        parsedHarvestDate = DateTime.parse(dateStr);
        harvestDateDisplay = _formatDate(parsedHarvestDate);
      } catch (e) {
        print('Error parsing harvest date: $e');
      }
    }

    // Format land area
    String landAreaDisplay = 'N/A';
    double? areaHa;
    if (landAreaValue != null) {
      try {
        if (landAreaValue is num) {
          areaHa = landAreaValue.toDouble();
          landAreaDisplay = '${areaHa.toStringAsFixed(2)} ha';
        } else if (landAreaValue is String) {
          final parsed = double.tryParse(landAreaValue);
          if (parsed != null) {
            areaHa = parsed;
            landAreaDisplay = '${parsed.toStringAsFixed(2)} ha';
          } else {
            landAreaDisplay = '$landAreaValue ha';
          }
        } else {
          landAreaDisplay = '$landAreaValue ha';
        }
      } catch (e) {
        print('Error formatting land area: $e');
        landAreaDisplay = '$landAreaValue ha';
      }
    }

    final expectedYieldKg = (areaHa != null && parsedHarvestDate != null)
        ? YieldPredictionService.predictYieldKg(
            cropName: cropName,
            harvestDate: parsedHarvestDate,
            areaHa: areaHa,
          )
        : null;

    // Get monthly yield
    final monthlyYield = _getYieldForCrop(cropName, parsedHarvestDate);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.primary.withAlpha(50)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(4),
            blurRadius: 6,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Crop Name
          Text(
            cropName,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 12),
          // Planting Date
          _buildDetailRow('🌱 Planted', plantingDateDisplay),
          // Harvest Date
          _buildDetailRow('🚪 Expected Harvest', harvestDateDisplay),
          // Land Area
          _buildDetailRow('📏 Land Area', landAreaDisplay),
          if (expectedYieldKg != null)
            _buildDetailRow('📊 Expected Yield', '${expectedYieldKg.toStringAsFixed(0)} kg'),
          // Monthly Yield
          if (monthlyYield != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.success.withAlpha(15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.trending_up, color: AppTheme.success, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Monthly Yield: $monthlyYield',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.success,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  Widget _buildDetailRow(String label, dynamic value) {
    // Ensure value is a string
    final displayValue = (value ?? 'N/A').toString();
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.textMedium,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              displayValue,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.textDark,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
