import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';
import '../../models/crop_data.dart';
import '../../services/marketplace_service.dart';

class CreateCropListingScreen extends StatefulWidget {
  final CropData? crop;
  final String? saturationLevel;

  const CreateCropListingScreen({
    super.key,
    this.crop,
    this.saturationLevel,
  });

  @override
  State<CreateCropListingScreen> createState() => _CreateCropListingScreenState();
}

class _CreateCropListingScreenState extends State<CreateCropListingScreen> {
  final MarketplaceService _marketplaceService = MarketplaceService();
  final _formKey = GlobalKey<FormState>();
  
  final _quantityController = TextEditingController();
  final _priceController = TextEditingController();
  final _locationController = TextEditingController();
  final _descriptionController = TextEditingController();

  String _selectedCropName = '';
  String _selectedCropIcon = '🌾';
  String _selectedQualityGrade = 'B';
  String _selectedSaturationLevel = 'high';
  DateTime? _harvestDate;
  DateTime? _expiryDate;
  bool _isLoading = false;

  final List<String> _qualityGrades = ['A', 'B', 'C'];
  final List<String> _saturationLevels = ['high', 'medium', 'low'];

  @override
  void initState() {
    super.initState();
    if (widget.crop != null) {
      _selectedCropName = widget.crop!.name;
      _selectedCropIcon = widget.crop!.icon;
    }
    if (widget.saturationLevel != null) {
      _selectedSaturationLevel = widget.saturationLevel!;
    }
    // Set default description for oversaturated crops
    if (_selectedSaturationLevel == 'high') {
      _descriptionController.text = 
          'Selling at a discount due to high soil saturation conditions. Fresh harvest from a well-maintained farm.';
    }
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _priceController.dispose();
    _locationController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _selectHarvestDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _harvestDate ?? now,
      firstDate: now.subtract(const Duration(days: 30)),
      lastDate: now.add(const Duration(days: 90)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.primary,
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _harvestDate = picked);
    }
  }

  Future<void> _selectExpiryDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _expiryDate ?? now.add(const Duration(days: 14)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 90)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.primary,
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _expiryDate = picked);
    }
  }

  void _showCropPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CropPickerSheet(
        selectedCrop: _selectedCropName,
        onSelect: (crop) {
          setState(() {
            _selectedCropName = crop.name;
            _selectedCropIcon = crop.icon;
          });
        },
      ),
    );
  }

  Future<void> _submitListing() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_selectedCropName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a crop'),
          backgroundColor: AppTheme.error,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _marketplaceService.createListing(
        cropName: _selectedCropName,
        cropIcon: _selectedCropIcon,
        quantityKg: double.parse(_quantityController.text),
        pricePerKg: double.parse(_priceController.text),
        saturationLevel: _selectedSaturationLevel,
        qualityGrade: _selectedQualityGrade,
        harvestDate: _harvestDate,
        expiryDate: _expiryDate,
        farmLocation: _locationController.text.isEmpty ? null : _locationController.text,
        description: _descriptionController.text.isEmpty ? null : _descriptionController.text,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: const [
              Icon(Icons.check_circle_rounded, color: Colors.white),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Your crop has been listed on the marketplace!',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
          backgroundColor: AppTheme.success,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to create listing: ${e.toString()}'),
          backgroundColor: AppTheme.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: AppTheme.textDark),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Sell Your Crop',
          style: TextStyle(
            color: AppTheme.textDark,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Info banner
              if (_selectedSaturationLevel == 'high')
                _buildInfoBanner(),
              
              const SizedBox(height: 20),

              // Crop selection
              _buildSectionTitle('Crop Details'),
              const SizedBox(height: 12),
              _buildCropSelector(),
              const SizedBox(height: 20),

              // Quantity & Price
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _quantityController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Quantity',
                        suffixText: 'kg',
                        prefixIcon: Icon(Icons.scale_outlined),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Required';
                        if (double.tryParse(value) == null) return 'Invalid';
                        if (double.parse(value) <= 0) return 'Must be > 0';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _priceController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Price per kg',
                        prefixText: '₱',
                        prefixIcon: Icon(Icons.payments_outlined),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Required';
                        if (double.tryParse(value) == null) return 'Invalid';
                        if (double.parse(value) <= 0) return 'Must be > 0';
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Quality & Saturation
              Row(
                children: [
                  Expanded(
                    child: _buildDropdownField(
                      'Quality Grade',
                      _selectedQualityGrade,
                      _qualityGrades.map((g) => DropdownMenuItem(
                        value: g,
                        child: Text('Grade $g'),
                      )).toList(),
                      (value) => setState(() => _selectedQualityGrade = value!),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildDropdownField(
                      'Saturation',
                      _selectedSaturationLevel,
                      _saturationLevels.map((s) => DropdownMenuItem(
                        value: s,
                        child: Row(
                          children: [
                            Text(_getSaturationEmoji(s)),
                            const SizedBox(width: 8),
                            Text(s[0].toUpperCase() + s.substring(1)),
                          ],
                        ),
                      )).toList(),
                      (value) => setState(() => _selectedSaturationLevel = value!),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Dates
              _buildSectionTitle('Dates (Optional)'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildDateField(
                      'Harvest Date',
                      _harvestDate,
                      _selectHarvestDate,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildDateField(
                      'Best Before',
                      _expiryDate,
                      _selectExpiryDate,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Location
              _buildSectionTitle('Location'),
              const SizedBox(height: 12),
              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(
                  labelText: 'Farm Location (Optional)',
                  hintText: 'e.g., Barangay Poblacion, San Fernando',
                  prefixIcon: Icon(Icons.location_on_outlined),
                ),
              ),
              const SizedBox(height: 20),

              // Description
              _buildSectionTitle('Description'),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Description (Optional)',
                  hintText: 'Describe your crop, its condition, etc.',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 32),

              // Submit button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitListing,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _selectedSaturationLevel == 'high'
                        ? Colors.orange.shade600
                        : AppTheme.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation(Colors.white),
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.storefront_rounded, size: 22),
                            SizedBox(width: 10),
                            Text(
                              'List on Marketplace',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.orange.shade100,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.sell_rounded,
              color: Colors.orange.shade700,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Selling Oversaturated Crops',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.orange.shade800,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'List your high-saturation crops at a discount to attract buyers looking for deals!',
                  style: TextStyle(
                    color: Colors.orange.shade700,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: AppTheme.textDark,
      ),
    );
  }

  Widget _buildCropSelector() {
    return GestureDetector(
      onTap: _showCropPicker,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.border),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppTheme.primary.withAlpha(20),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  _selectedCropIcon,
                  style: const TextStyle(fontSize: 26),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _selectedCropName.isEmpty ? 'Select Crop' : _selectedCropName,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: _selectedCropName.isEmpty 
                          ? AppTheme.textLight 
                          : AppTheme.textDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Tap to change',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textLight,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, 
                size: 16, color: AppTheme.textLight),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdownField<T>(
    String label,
    T value,
    List<DropdownMenuItem<T>> items,
    void Function(T?) onChanged,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border),
      ),
      child: DropdownButtonFormField<T>(
        initialValue: value,
        items: items,
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: label,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
        ),
      ),
    );
  }

  Widget _buildDateField(
    String label,
    DateTime? date,
    VoidCallback onTap,
  ) {
    final dateFormat = DateFormat('MMM d, yyyy');
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.textLight,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  Icons.calendar_today_outlined,
                  size: 18,
                  color: date != null ? AppTheme.primary : AppTheme.textLight,
                ),
                const SizedBox(width: 8),
                Text(
                  date != null ? dateFormat.format(date) : 'Not set',
                  style: TextStyle(
                    fontSize: 14,
                    color: date != null ? AppTheme.textDark : AppTheme.textLight,
                    fontWeight: date != null ? FontWeight.w500 : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getSaturationEmoji(String level) {
    switch (level.toLowerCase()) {
      case 'high':
        return '🔴';
      case 'medium':
        return '🟡';
      case 'low':
        return '🟢';
      default:
        return '⚪';
    }
  }
}

// Bottom sheet for crop picker
class CropPickerSheet extends StatefulWidget {
  final String selectedCrop;
  final void Function(CropData) onSelect;

  const CropPickerSheet({
    super.key,
    required this.selectedCrop,
    required this.onSelect,
  });

  @override
  State<CropPickerSheet> createState() => _CropPickerSheetState();
}

class _CropPickerSheetState extends State<CropPickerSheet> {
  String _searchQuery = '';

  List<CropData> get _filteredCrops {
    if (_searchQuery.isEmpty) return CropData.allCrops;
    return CropData.allCrops.where((crop) =>
      crop.name.toLowerCase().contains(_searchQuery.toLowerCase())
    ).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppTheme.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          
          // Title
          const Text(
            'Select Crop',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 16),
          
          // Search
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              onChanged: (v) => setState(() => _searchQuery = v),
              decoration: InputDecoration(
                hintText: 'Search crops...',
                prefixIcon: const Icon(Icons.search_rounded),
                filled: true,
                fillColor: AppTheme.background,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // Crop list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _filteredCrops.length,
              itemBuilder: (context, index) {
                final crop = _filteredCrops[index];
                final isSelected = crop.name == widget.selectedCrop;
                
                return ListTile(
                  leading: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: isSelected 
                          ? AppTheme.primary.withAlpha(20) 
                          : AppTheme.background,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(crop.icon, style: const TextStyle(fontSize: 24)),
                    ),
                  ),
                  title: Text(
                    crop.name,
                    style: TextStyle(
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? AppTheme.primary : AppTheme.textDark,
                    ),
                  ),
                  subtitle: Text(
                    crop.category,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textLight,
                    ),
                  ),
                  trailing: isSelected 
                      ? const Icon(Icons.check_circle_rounded, 
                          color: AppTheme.primary)
                      : null,
                  onTap: () {
                    widget.onSelect(crop);
                    Navigator.pop(context);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
