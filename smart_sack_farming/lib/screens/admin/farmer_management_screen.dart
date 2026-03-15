import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/crop_data.dart';
import '../../theme/app_theme.dart';

class FarmerManagementScreen extends StatefulWidget {
  const FarmerManagementScreen({super.key});

  @override
  State<FarmerManagementScreen> createState() => _FarmerManagementScreenState();
}

class _FarmerManagementScreenState extends State<FarmerManagementScreen> {
  final _searchController = TextEditingController();
  String _searchTerm = '';
  List<Map<String, dynamic>> _farmers = [];
  List<Map<String, dynamic>> _filteredFarmers = [];
  bool _isLoading = true;
  String? _error;
  String? _selectedAddress;

  @override
  void initState() {
    super.initState();
    _fetchFarmersAndCrops();
    _searchController.addListener(() {
      setState(() {
        _searchTerm = _searchController.text;
        _filterFarmers();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchFarmersAndCrops() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final client = Supabase.instance.client;
      
      // Try to fetch with all columns first, fallback to basic columns
      List<dynamic> profilesRes;
      try {
        profilesRes = await client
            .from('profiles')
            .select('id, full_name, address, sex, age, land_size_ha')
            .eq('role', 'farmer');
      } catch (e) {
        // If new columns don't exist, fetch only basic columns
        debugPrint('New columns not available yet, fetching basic columns: $e');
        profilesRes = await client
            .from('profiles')
            .select('id, full_name, address')
            .eq('role', 'farmer');
      }

      final List<Map<String, dynamic>> farmers = List<Map<String, dynamic>>.from(profilesRes);

      // Fetch associated crops for each farmer from production_reports
      for (var farmer in farmers) {
        try {
          final reportsRes = await client
              .from('production_reports')
              .select('crop_type')
              .eq('user_id', farmer['id']);
          
          final crops = reportsRes.map((report) => report['crop_type'] as String).toSet().toList();
          farmer['crops'] = crops;
        } catch (e) {
          debugPrint('Error fetching crops for farmer ${farmer['id']}: $e');
          farmer['crops'] = [];
        }
      }

      setState(() {
        _farmers = farmers;
        _filteredFarmers = farmers;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load farmer data: $e';
        _isLoading = false;
      });
      debugPrint(e.toString());
    }
  }

  void _filterFarmers() {
    List<Map<String, dynamic>> results = _farmers;

    if (_selectedAddress != null) {
      results = results.where((farmer) => farmer['address'] == _selectedAddress).toList();
    }

    if (_searchTerm.isNotEmpty) {
      results = results.where((farmer) {
        final farmerName = (farmer['full_name'] as String? ?? '').toLowerCase();
        final crops = (farmer['crops'] as List<dynamic>).join(' ').toLowerCase();
        final searchLower = _searchTerm.toLowerCase();
        return farmerName.contains(searchLower) || crops.contains(searchLower);
      }).toList();
    }

    setState(() {
      _filteredFarmers = results;
    });
  }

  @override
  Widget build(BuildContext context) {
    final uniqueAddresses = _farmers.map((f) => f['address'] as String?).where((a) => a != null).toSet().toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Farmer Management'),
        backgroundColor: AppTheme.primary,
      ),
      body: Column(
        children: [
          _buildSearchBarAndFilter(uniqueAddresses),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildSearchBarAndFilter(List<String?> addresses) {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by name or crop...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30.0),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[200],
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),
          const SizedBox(width: 10),
          _buildAddressFilter(addresses),
        ],
      ),
    );
  }

  Widget _buildAddressFilter(List<String?> addresses) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(30.0),
      ),
      child: DropdownButton<String>(
        value: _selectedAddress,
        hint: const Text('Filter by Address'),
        underline: const SizedBox(),
        onChanged: (String? newValue) {
          setState(() {
            _selectedAddress = newValue;
            _filterFarmers();
          });
        },
        items: [
          const DropdownMenuItem<String>(
            value: null,
            child: Text('All Addresses'),
          ),
          ...addresses.map<DropdownMenuItem<String>>((String? value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value ?? 'No Address'),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(child: Text(_error!, style: const TextStyle(color: Colors.red)));
    }
    if (_filteredFarmers.isEmpty) {
      return const Center(child: Text('No farmers found.'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8.0),
      itemCount: _filteredFarmers.length,
      itemBuilder: (context, index) {
        final farmer = _filteredFarmers[index];
        final crops = (farmer['crops'] as List<dynamic>).join(', ');
        return Card(
          elevation: 2,
          margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: AppTheme.primary,
              child: Text(
                farmer['full_name']?.substring(0, 1) ?? 'F',
                style: const TextStyle(color: Colors.white),
              ),
            ),
            title: Text(farmer['full_name'] ?? 'N/A', style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Address: ${farmer['address'] ?? 'N/A'}'),
                Text('Land Size: ${farmer['land_size_ha'] ?? 'N/A'} ha'),
                if (crops.isNotEmpty) Text('Crops: $crops'),
              ],
            ),
            isThreeLine: true,
          ),
        );
      },
    );
  }
}
