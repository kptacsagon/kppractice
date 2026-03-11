import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';
import '../../models/crop_listing_model.dart';
import '../../services/marketplace_service.dart';

class CropListingDetailScreen extends StatefulWidget {
  final CropListing listing;

  const CropListingDetailScreen({
    super.key,
    required this.listing,
  });

  @override
  State<CropListingDetailScreen> createState() => _CropListingDetailScreenState();
}

class _CropListingDetailScreenState extends State<CropListingDetailScreen> {
  final MarketplaceService _marketplaceService = MarketplaceService();
  final _formKey = GlobalKey<FormState>();
  final _quantityController = TextEditingController();
  final _notesController = TextEditingController();

  DateTime? _selectedPickupDate;
  bool _isLoading = false;
  CropListing? _currentListing;

  @override
  void initState() {
    super.initState();
    _currentListing = widget.listing;
    _quantityController.text = '1';
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  double get _requestedQuantity {
    return double.tryParse(_quantityController.text) ?? 0;
  }

  double get _totalAmount {
    return _requestedQuantity * (_currentListing?.pricePerKg ?? 0);
  }

  bool get _canReserve {
    return _requestedQuantity > 0 && 
           _requestedQuantity <= (_currentListing?.availableQuantityKg ?? 0);
  }

  Future<void> _selectPickupDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 30)),
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
      setState(() => _selectedPickupDate = picked);
    }
  }

  Future<void> _submitReservation() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_canReserve) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid quantity'),
          backgroundColor: AppTheme.error,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _marketplaceService.createReservation(
        listingId: widget.listing.id,
        quantityKg: _requestedQuantity,
        pickupDate: _selectedPickupDate,
        notes: _notesController.text.isEmpty ? null : _notesController.text,
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
                  'Reservation submitted successfully! The farmer will confirm soon.',
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
          content: Text('Failed to create reservation: ${e.toString()}'),
          backgroundColor: AppTheme.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final listing = _currentListing!;
    
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: CustomScrollView(
        slivers: [
          // App bar with crop header
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: _getSaturationColor(listing.saturationLevel),
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_back_rounded, color: Colors.white),
              ),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      _getSaturationColor(listing.saturationLevel),
                      _getSaturationColor(listing.saturationLevel).withOpacity(0.7),
                    ],
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 40),
                      Text(
                        listing.cropIcon ?? '🌾',
                        style: const TextStyle(fontSize: 60),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        listing.cropName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildSaturationBadge(listing.saturationLevel),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Content
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Pricing card
                _buildPricingCard(listing),
                const SizedBox(height: 16),

                // Details card
                _buildDetailsCard(listing),
                const SizedBox(height: 16),

                // Farmer info card
                _buildFarmerCard(listing),
                const SizedBox(height: 16),

                // Description
                if (listing.description != null) ...[
                  _buildDescriptionCard(listing),
                  const SizedBox(height: 16),
                ],

                // Reservation form
                _buildReservationForm(listing),
                const SizedBox(height: 100), // Space for bottom button
              ]),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildPricingCard(CropListing listing) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [AppTheme.cardShadow],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Price per kg',
                style: TextStyle(
                  color: AppTheme.textLight,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '₱${listing.pricePerKg.toStringAsFixed(2)}',
                style: const TextStyle(
                  color: AppTheme.primary,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: listing.saturationLevel == 'high'
                  ? Colors.orange.shade50
                  : AppTheme.background,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: listing.saturationLevel == 'high'
                    ? Colors.orange.shade200
                    : AppTheme.border,
              ),
            ),
            child: Column(
              children: [
                const Text(
                  'Available',
                  style: TextStyle(
                    color: AppTheme.textLight,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${listing.availableQuantityKg.toStringAsFixed(0)} kg',
                  style: TextStyle(
                    color: listing.saturationLevel == 'high'
                        ? Colors.orange.shade800
                        : AppTheme.textDark,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsCard(CropListing listing) {
    final dateFormat = DateFormat('MMM d, yyyy');
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [AppTheme.cardShadow],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Crop Details',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 16),
          _buildDetailRow(
            Icons.water_drop_outlined,
            'Saturation Level',
            _getSaturationLabel(listing.saturationLevel),
          ),
          _buildDetailRow(
            Icons.grade_outlined,
            'Quality Grade',
            listing.qualityDescription,
          ),
          _buildDetailRow(
            Icons.inventory_outlined,
            'Total Quantity',
            '${listing.quantityKg.toStringAsFixed(0)} kg',
          ),
          if (listing.harvestDate != null)
            _buildDetailRow(
              Icons.calendar_today_outlined,
              'Harvest Date',
              dateFormat.format(listing.harvestDate!),
            ),
          if (listing.expiryDate != null)
            _buildDetailRow(
              Icons.timer_outlined,
              'Best Before',
              dateFormat.format(listing.expiryDate!),
            ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppTheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: AppTheme.textMedium,
                fontSize: 14,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: AppTheme.textDark,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFarmerCard(CropListing listing) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [AppTheme.cardShadow],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Farmer Information',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: AppTheme.farmerColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.person_rounded,
                  color: AppTheme.farmerColor,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      listing.farmerName ?? 'Unknown Farmer',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textDark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (listing.farmLocation != null)
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on_outlined,
                            size: 14,
                            color: AppTheme.textLight,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              listing.farmLocation!,
                              style: const TextStyle(
                                color: AppTheme.textMedium,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDescriptionCard(CropListing listing) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [AppTheme.cardShadow],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Description',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            listing.description!,
            style: const TextStyle(
              color: AppTheme.textMedium,
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReservationForm(CropListing listing) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [AppTheme.cardShadow],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.shopping_cart_outlined, 
                    color: AppTheme.primary, size: 24),
                const SizedBox(width: 10),
                const Text(
                  'Make a Reservation',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Quantity input
            TextFormField(
              controller: _quantityController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Quantity (kg)',
                hintText: 'Enter amount to reserve',
                prefixIcon: const Icon(Icons.scale_outlined),
                suffixText: 'kg',
                helperText: 'Available: ${listing.availableQuantityKg.toStringAsFixed(0)} kg',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter quantity';
                }
                final qty = double.tryParse(value);
                if (qty == null || qty <= 0) {
                  return 'Please enter a valid quantity';
                }
                if (qty > listing.availableQuantityKg) {
                  return 'Exceeds available quantity';
                }
                return null;
              },
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 16),

            // Pickup date
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.calendar_month_rounded, 
                  color: AppTheme.primary),
              title: Text(
                _selectedPickupDate != null
                    ? DateFormat('EEEE, MMMM d, yyyy').format(_selectedPickupDate!)
                    : 'Select Pickup Date (Optional)',
                style: TextStyle(
                  color: _selectedPickupDate != null 
                      ? AppTheme.textDark 
                      : AppTheme.textLight,
                ),
              ),
              trailing: const Icon(Icons.arrow_drop_down_rounded),
              onTap: _selectPickupDate,
            ),
            const SizedBox(height: 16),

            // Notes input
            TextFormField(
              controller: _notesController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Notes (Optional)',
                hintText: 'Any special requests or instructions...',
                prefixIcon: Icon(Icons.note_outlined),
              ),
            ),
            const SizedBox(height: 24),

            // Total amount
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.primary.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total Amount',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textDark,
                    ),
                  ),
                  Text(
                    '₱${_totalAmount.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isLoading || !_canReserve ? null : _submitReservation,
            style: ElevatedButton.styleFrom(
              backgroundColor: _currentListing?.saturationLevel == 'high'
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
                      Icon(Icons.shopping_cart_checkout_rounded, size: 22),
                      SizedBox(width: 10),
                      Text(
                        'Reserve Now',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildSaturationBadge(String level) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        _getSaturationLabel(level),
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
      ),
    );
  }

  String _getSaturationLabel(String level) {
    switch (level.toLowerCase()) {
      case 'high':
        return '🔴 High Saturation - Discounted';
      case 'medium':
        return '🟡 Medium Saturation';
      case 'low':
        return '🟢 Low Saturation';
      default:
        return level;
    }
  }

  Color _getSaturationColor(String level) {
    switch (level.toLowerCase()) {
      case 'high':
        return Colors.orange.shade600;
      case 'medium':
        return Colors.amber.shade600;
      case 'low':
        return AppTheme.primary;
      default:
        return Colors.grey;
    }
  }
}
