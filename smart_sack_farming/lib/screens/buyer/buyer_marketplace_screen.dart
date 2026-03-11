import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../theme/app_theme.dart';
import '../../models/crop_listing_model.dart';
import '../../services/marketplace_service.dart';
import '../auth/login_screen.dart';
import 'crop_listing_detail_screen.dart';
import 'buyer_reservations_screen.dart';

class BuyerMarketplaceScreen extends StatefulWidget {
  const BuyerMarketplaceScreen({super.key});

  @override
  State<BuyerMarketplaceScreen> createState() => _BuyerMarketplaceScreenState();
}

class _BuyerMarketplaceScreenState extends State<BuyerMarketplaceScreen> {
  final MarketplaceService _marketplaceService = MarketplaceService();
  final TextEditingController _searchController = TextEditingController();

  List<CropListing> _listings = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _selectedFilter = 'all'; // 'all', 'high', 'medium', 'low'
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadListings();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadListings() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      List<CropListing> listings;
      
      if (_selectedFilter == 'high') {
        listings = await _marketplaceService.getOversaturatedListings();
      } else {
        listings = await _marketplaceService.getAvailableListings(
          saturationLevel: _selectedFilter == 'all' ? null : _selectedFilter,
        );
      }

      // Apply search filter
      if (_searchQuery.isNotEmpty) {
        listings = listings.where((l) => 
          l.cropName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (l.farmLocation?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false)
        ).toList();
      }

      setState(() {
        _listings = listings;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load listings: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _logout() async {
    await Supabase.instance.client.auth.signOut();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        elevation: 0,
        title: const Text(
          'Crop Marketplace',
          style: TextStyle(
            color: AppTheme.textDark,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: Stack(
              children: [
                const Icon(Icons.receipt_long_rounded, color: AppTheme.textMedium),
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      color: AppTheme.primary,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(minWidth: 8, minHeight: 8),
                  ),
                ),
              ],
            ),
            tooltip: 'My Reservations',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const BuyerReservationsScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: AppTheme.textMedium),
            onPressed: _logout,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Search and filter bar
          _buildSearchAndFilterBar(),
          
          // Content
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                    ? _buildErrorView()
                    : _listings.isEmpty
                        ? _buildEmptyView()
                        : _buildListingsGrid(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilterBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Search bar
          TextField(
            controller: _searchController,
            onChanged: (value) {
              setState(() => _searchQuery = value);
              _loadListings();
            },
            decoration: InputDecoration(
              hintText: 'Search crops or locations...',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                        _loadListings();
                      },
                    )
                  : null,
              filled: true,
              fillColor: AppTheme.background,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
          const SizedBox(height: 12),
          
          // Filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('all', 'All', Icons.grid_view_rounded, null),
                const SizedBox(width: 8),
                _buildFilterChip('high', 'Oversaturated', Icons.warning_amber_rounded, Colors.red),
                const SizedBox(width: 8),
                _buildFilterChip('medium', 'Medium', Icons.remove_circle_outline, Colors.orange),
                const SizedBox(width: 8),
                _buildFilterChip('low', 'Low', Icons.check_circle_outline, Colors.green),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String value, String label, IconData icon, Color? indicatorColor) {
    final isSelected = _selectedFilter == value;
    return FilterChip(
      selected: isSelected,
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (indicatorColor != null) ...[
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: indicatorColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
          ] else ...[
            Icon(
              icon,
              size: 16,
              color: isSelected ? Colors.white : AppTheme.textMedium,
            ),
            const SizedBox(width: 4),
          ],
          Text(label),
        ],
      ),
      onSelected: (_) {
        setState(() => _selectedFilter = value);
        _loadListings();
      },
      selectedColor: value == 'high' 
          ? Colors.red.shade600 
          : value == 'medium'
              ? Colors.orange.shade600
              : AppTheme.primary,
      backgroundColor: AppTheme.background,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : AppTheme.textMedium,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 64,
              color: AppTheme.error.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppTheme.textMedium),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadListings,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.shopping_basket_outlined,
              size: 80,
              color: AppTheme.textLight.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            const Text(
              'No crops available',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _selectedFilter == 'high'
                  ? 'No oversaturated crops are currently listed'
                  : 'Check back later for new listings',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppTheme.textMedium),
            ),
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: _loadListings,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Refresh'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListingsGrid() {
    return RefreshIndicator(
      onRefresh: _loadListings,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final crossAxisCount = constraints.maxWidth < 600 ? 1 : 
                                 constraints.maxWidth < 900 ? 2 : 3;
          
          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              childAspectRatio: crossAxisCount == 1 ? 1.4 : 0.85,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: _listings.length,
            itemBuilder: (context, index) {
              return _buildListingCard(_listings[index]);
            },
          );
        },
      ),
    );
  }

  Widget _buildListingCard(CropListing listing) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CropListingDetailScreen(listing: listing),
          ),
        ).then((_) => _loadListings());
      },
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [AppTheme.cardShadow],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with crop icon and saturation badge
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _getSaturationColor(listing.saturationLevel).withOpacity(0.1),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  // Crop icon
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        listing.cropIcon ?? '🌾',
                        style: const TextStyle(fontSize: 28),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          listing.cropName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textDark,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            _buildSaturationBadge(listing.saturationLevel),
                            const SizedBox(width: 8),
                            _buildQualityBadge(listing.qualityGrade),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // Details
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Price
                    Row(
                      children: [
                        const Icon(Icons.sell_rounded, 
                            size: 18, color: AppTheme.primary),
                        const SizedBox(width: 6),
                        Text(
                          '₱${listing.pricePerKg.toStringAsFixed(2)}/kg',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    
                    // Available quantity
                    Row(
                      children: [
                        const Icon(Icons.inventory_2_outlined, 
                            size: 16, color: AppTheme.textLight),
                        const SizedBox(width: 6),
                        Text(
                          '${listing.availableQuantityKg.toStringAsFixed(0)} kg available',
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppTheme.textMedium,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    
                    // Location
                    if (listing.farmLocation != null) ...[
                      Row(
                        children: [
                          const Icon(Icons.location_on_outlined, 
                              size: 16, color: AppTheme.textLight),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              listing.farmLocation!,
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppTheme.textMedium,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                    ],
                    
                    // Farmer name
                    if (listing.farmerName != null) ...[
                      Row(
                        children: [
                          const Icon(Icons.person_outline_rounded, 
                              size: 16, color: AppTheme.textLight),
                          const SizedBox(width: 6),
                          Text(
                            listing.farmerName!,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppTheme.textMedium,
                            ),
                          ),
                        ],
                      ),
                    ],
                    
                    const Spacer(),
                    
                    // Reserve button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => CropListingDetailScreen(listing: listing),
                            ),
                          ).then((_) => _loadListings());
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: listing.saturationLevel == 'high'
                              ? Colors.orange.shade600
                              : AppTheme.primary,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text(
                          'View & Reserve',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSaturationBadge(String level) {
    Color bgColor;
    Color textColor;
    String label;
    
    switch (level.toLowerCase()) {
      case 'high':
        bgColor = Colors.orange.shade100;
        textColor = Colors.orange.shade800;
        label = '🔴 High';
        break;
      case 'medium':
        bgColor = Colors.yellow.shade100;
        textColor = Colors.yellow.shade800;
        label = '🟡 Medium';
        break;
      case 'low':
        bgColor = Colors.green.shade100;
        textColor = Colors.green.shade800;
        label = '🟢 Low';
        break;
      default:
        bgColor = Colors.grey.shade100;
        textColor = Colors.grey.shade800;
        label = level;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }

  Widget _buildQualityBadge(String grade) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.border,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        'Grade $grade',
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: AppTheme.textMedium,
        ),
      ),
    );
  }

  Color _getSaturationColor(String level) {
    switch (level.toLowerCase()) {
      case 'high':
        return Colors.orange;
      case 'medium':
        return Colors.yellow.shade700;
      case 'low':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}
