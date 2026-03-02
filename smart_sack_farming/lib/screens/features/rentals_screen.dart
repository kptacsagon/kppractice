import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/equipment_model.dart';
import '../../theme/app_theme.dart';

class RentalsScreen extends StatefulWidget {
  const RentalsScreen({super.key});

  @override
  State<RentalsScreen> createState() => _RentalsScreenState();
}

class _RentalsScreenState extends State<RentalsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Equipment> _myEquipment = [];
  List<Equipment> _availableEquipment = [];
  bool _isLoading = true;
  String? _userId;

  String _searchQuery = '';
  String _selectedCategory = 'All';

  final List<String> _categories = [
    'All',
    'Tractor',
    'Harvester',
    'Pump',
    'Sprayer',
    'Tiller',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadEquipment();
  }

  Future<void> _loadEquipment() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    _userId = user.id;

    setState(() => _isLoading = true);
    try {
      // Load all equipment
      final allResponse = await Supabase.instance.client
          .from('equipment')
          .select();

      final allEquipment = (allResponse as List)
          .map((e) => Equipment.fromJson(e as Map<String, dynamic>))
          .toList();

      setState(() {
        _myEquipment = allEquipment.where((e) => e.ownerId == _userId).toList();
        _availableEquipment = allEquipment.where((e) => e.ownerId != _userId).toList();
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading equipment: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<Equipment> get _filteredEquipment {
    return _availableEquipment.where((equipment) {
      final matchesSearch = equipment.name
              .toLowerCase()
              .contains(_searchQuery.toLowerCase()) ||
          equipment.description
              .toLowerCase()
              .contains(_searchQuery.toLowerCase());
      final matchesCategory =
          _selectedCategory == 'All' || equipment.category == _selectedCategory;
      return matchesSearch && matchesCategory;
    }).toList();
  }

  Future<void> _addEquipmentToSupabase(Equipment equipment) async {
    if (_userId == null) return;
    try {
      final userName = Supabase.instance.client.auth.currentUser?.userMetadata?['full_name'] ?? 'Farmer';
      final data = {
        'owner_id': _userId!,
        'name': equipment.name,
        'description': equipment.description,
        'category': equipment.category,
        'daily_rental_price': equipment.dailyRentalPrice,
        'quantity': equipment.quantity,
        'condition': equipment.condition.isNotEmpty ? equipment.condition : 'Good',
        'is_available': true,
        'image_url': equipment.imageUrl,
        'owner_name': userName,
        'owner_phone': '',
      };

      await Supabase.instance.client.from('equipment').insert(data);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Equipment added successfully'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 1),
        ),
      );
      _loadEquipment();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error adding equipment: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _deleteEquipment(Equipment equipment) async {
    try {
      await Supabase.instance.client
          .from('equipment')
          .delete()
          .eq('id', equipment.id);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Equipment removed'),
          duration: Duration(seconds: 1),
        ),
      );
      _loadEquipment();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error removing: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void _contactOwner(Equipment equipment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Contact Owner'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Equipment: ${equipment.name}',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Text(
              'Owner: ${equipment.ownerName}',
              style: const TextStyle(color: AppTheme.textMedium),
            ),
            const SizedBox(height: 8),
            Text(
              'Phone: ${equipment.ownerPhone}',
              style: const TextStyle(
                color: AppTheme.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Daily Rate: ₹${equipment.dailyRentalPrice.toStringAsFixed(2)}',
              style: const TextStyle(color: Colors.green),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content:
                      Text('Rental request sent to ${equipment.ownerName}'),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            child: const Text('Request Rental'),
          ),
        ],
      ),
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
          'Equipment Rentals',
          style: TextStyle(
            color: AppTheme.textDark,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.textMedium),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.primary,
          unselectedLabelColor: AppTheme.textMedium,
          indicatorColor: AppTheme.primary,
          tabs: const [
            Tab(text: 'Browse Equipment'),
            Tab(text: 'My Equipment'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildBrowseTab(),
                _buildMyEquipmentTab(),
              ],
            ),
    );
  }

  Widget _buildBrowseTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search bar
          TextField(
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
            decoration: InputDecoration(
              hintText: 'Search equipment...',
              prefixIcon: const Icon(Icons.search, color: AppTheme.textMedium),
              fillColor: AppTheme.inputBackground,
              filled: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppTheme.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppTheme.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppTheme.primary),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Category filter
          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final category = _categories[index];
                final isSelected = _selectedCategory == category;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(category),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedCategory = category;
                      });
                    },
                    backgroundColor: AppTheme.inputBackground,
                    selectedColor: AppTheme.primary.withAlpha(100),
                    labelStyle: TextStyle(
                      color: isSelected ? AppTheme.primary : AppTheme.textMedium,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Available Equipment (${_filteredEquipment.length})',
            style: const TextStyle(
              color: AppTheme.textDark,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          if (_filteredEquipment.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.no_meals_rounded,
                        size: 64, color: AppTheme.textLight),
                    const SizedBox(height: 16),
                    const Text(
                      'No equipment found',
                      style: TextStyle(
                        color: AppTheme.textMedium,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _filteredEquipment.length,
              itemBuilder: (context, index) {
                final equipment = _filteredEquipment[index];
                return _buildEquipmentCard(equipment, false);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildMyEquipmentTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _showAddEquipmentDialog(),
              icon: const Icon(Icons.add),
              label: const Text('Add Equipment'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (_myEquipment.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.agriculture_rounded,
                        size: 64, color: AppTheme.textLight),
                    const SizedBox(height: 16),
                    const Text(
                      'No equipment listed yet',
                      style: TextStyle(
                        color: AppTheme.textMedium,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Add your equipment to start earning',
                      style: TextStyle(
                        color: AppTheme.textLight,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            Column(
              children: List.generate(
                _myEquipment.length,
                (index) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildMyEquipmentCard(_myEquipment[index]),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEquipmentCard(Equipment equipment, bool isMyEquipment) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Equipment image/icon
          Container(
            width: double.infinity,
            height: 140,
            decoration: BoxDecoration(
              color: AppTheme.inputBackground,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Center(
              child: Text(
                equipment.imageUrl,
                style: const TextStyle(fontSize: 48),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            equipment.name,
                            style: const TextStyle(
                              color: AppTheme.textDark,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppTheme.primary.withAlpha(20),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              equipment.category,
                              style: const TextStyle(
                                color: AppTheme.primary,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (equipment.isAvailable)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green.withAlpha(20),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'Available',
                          style: TextStyle(
                            color: Colors.green,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  equipment.description,
                  style: const TextStyle(
                    color: AppTheme.textMedium,
                    fontSize: 12,
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                if (!isMyEquipment) ...[
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.inputBackground,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Owner Details',
                          style: TextStyle(
                            color: AppTheme.textDark,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          equipment.ownerName,
                          style: const TextStyle(
                            color: AppTheme.textDark,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          equipment.ownerPhone,
                          style: const TextStyle(
                            color: AppTheme.primary,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Daily Rate',
                          style: TextStyle(
                            color: AppTheme.textLight,
                            fontSize: 11,
                          ),
                        ),
                        Text(
                          '₹${equipment.dailyRentalPrice.toStringAsFixed(0)}/day',
                          style: const TextStyle(
                            color: Colors.green,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    if (!isMyEquipment)
                      ElevatedButton(
                        onPressed: () => _contactOwner(equipment),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        child: const Text(
                          'Rent Now',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
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
    );
  }

  Widget _buildMyEquipmentCard(Equipment equipment) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppTheme.inputBackground,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                equipment.imageUrl,
                style: const TextStyle(fontSize: 32),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  equipment.name,
                  style: const TextStyle(
                    color: AppTheme.textDark,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  equipment.category,
                  style: const TextStyle(
                    color: AppTheme.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.currency_rupee,
                        size: 14, color: Colors.green),
                    Text(
                      '${equipment.dailyRentalPrice.toStringAsFixed(0)}/day',
                      style: const TextStyle(
                        color: Colors.green,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Qty: ${equipment.quantity}',
                      style: const TextStyle(
                        color: AppTheme.textMedium,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => _deleteEquipment(equipment),
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.red.withAlpha(15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(
                Icons.delete_outline,
                color: Colors.red,
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddEquipmentDialog() {
    final formKey = GlobalKey<FormState>();
    String? name;
    String? description;
    String category = 'Tractor';
    double? rentalPrice;
    int quantity = 1;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Equipment'),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Equipment Name',
                    hintText: 'e.g., Tractor, Harvester',
                  ),
                  validator: (value) =>
                      value?.isEmpty ?? true ? 'Required' : null,
                  onSaved: (value) => name = value,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    hintText: 'Describe your equipment',
                  ),
                  maxLines: 2,
                  onSaved: (value) => description = value,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: category,
                  decoration: const InputDecoration(labelText: 'Category'),
                  items: _categories
                      .where((c) => c != 'All')
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (value) => category = value ?? 'Tractor',
                ),
                const SizedBox(height: 12),
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Daily Rental Price (₹)',
                  ),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  validator: (value) =>
                      value?.isEmpty ?? true ? 'Required' : null,
                  onSaved: (value) => rentalPrice = double.parse(value ?? '0'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  initialValue: '1',
                  decoration: const InputDecoration(
                    labelText: 'Quantity Available',
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) =>
                      quantity = int.tryParse(value) ?? 1,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                formKey.currentState!.save();
                final newEquipment = Equipment(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  name: name ?? '',
                  description: description ?? '',
                  category: category,
                  dailyRentalPrice: rentalPrice ?? 0,
                  ownerId: 'current_farmer',
                  ownerName: 'Your Name',
                  ownerPhone: '9876543215',
                  dateAdded: DateTime.now(),
                  isAvailable: true,
                  imageUrl: _getIconForCategory(category),
                  quantity: quantity,
                );
                _addEquipmentToSupabase(newEquipment);
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  String _getIconForCategory(String category) {
    switch (category) {
      case 'Tractor':
        return '🚜';
      case 'Harvester':
        return '⚙️';
      case 'Pump':
        return '💧';
      case 'Sprayer':
        return '🌊';
      case 'Tiller':
        return '🔧';
      default:
        return '🔨';
    }
  }
}
