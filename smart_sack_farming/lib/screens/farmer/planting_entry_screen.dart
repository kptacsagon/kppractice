import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/crop.dart';
import '../../providers/planting_provider.dart';
import '../home/farmer_profile_screen.dart';

class PlantingEntryScreen extends ConsumerStatefulWidget {
  const PlantingEntryScreen({super.key});

  @override
  ConsumerState<PlantingEntryScreen> createState() => _PlantingEntryScreenState();
}

class _PlantingEntryScreenState extends ConsumerState<PlantingEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedFarmerId;
  List<Map<String, dynamic>> _farmerOptions = [];
  bool _showFarmerSelect = false;
  final _areaController = TextEditingController();

  @override
  void dispose() {
    _areaController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _determineRoleAndLoadFarmers();
  }

  Future<void> _determineRoleAndLoadFarmers() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    try {
      final profile = await Supabase.instance.client
          .from('profiles')
          .select('role')
          .eq('id', user.id)
          .maybeSingle();
      final role = (profile != null && profile['role'] != null) ? profile['role'] as String : 'farmer';
      if (role != 'farmer') {
        // admin or extension worker: show farmer select
        _showFarmerSelect = true;
        final res = await Supabase.instance.client
            .from('profiles')
            .select('id, full_name')
            .eq('role', 'farmer');
        _farmerOptions = List<Map<String, dynamic>>.from(res as List<dynamic>);
        if (_farmerOptions.isNotEmpty) _selectedFarmerId = _farmerOptions.first['id'] as String;
        if (mounted) setState(() {});
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(plantingFormProvider);
    final notifier = ref.read(plantingFormProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Planting Entry')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DropdownButtonFormField<CropName>(
                  value: state.crop,
                  decoration: const InputDecoration(labelText: 'Crop'),
                  items: CropName.values
                      .map((c) => DropdownMenuItem(value: c, child: Text(c.name)))
                      .toList(),
                  onChanged: (c) {
                    if (c != null) notifier.setCrop(c);
                  },
                ),

                const SizedBox(height: 12),

                GestureDetector(
                  onTap: () async {
                    final selected = await showDatePicker(
                      context: context,
                      initialDate: state.plantingDate,
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    if (selected != null) notifier.setPlantingDate(selected);
                  },
                  child: AbsorbPointer(
                    child: TextFormField(
                      decoration: InputDecoration(labelText: 'Planting Date'),
                      controller: TextEditingController(
                          text: '${state.plantingDate.toLocal()}'.split(' ')[0]),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                TextFormField(
                  controller: _areaController,
                  decoration: const InputDecoration(
                    labelText: 'Area planted (ha)',
                    hintText: 'e.g., 0.5',
                  ),
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Enter area';
                    final parsed = double.tryParse(v);
                    if (parsed == null) return 'Invalid number';
                    if (parsed <= 0) return 'Must be > 0';
                    return null;
                  },
                ),

                const SizedBox(height: 12),

                if (_showFarmerSelect) ...[
                  DropdownButtonFormField<String>(
                    value: _selectedFarmerId,
                    decoration: const InputDecoration(labelText: 'Select Farmer'),
                    items: _farmerOptions
                        .map((f) => DropdownMenuItem(value: f['id'] as String, child: Text(f['full_name'] ?? f['id'])))
                        .toList(),
                    onChanged: (v) => setState(() => _selectedFarmerId = v),
                  ),
                  const SizedBox(height: 12),
                ],

                const SizedBox(height: 20),

                Row(
                  children: [
                    Expanded(
                      child: FilledButton.tonal(
                        onPressed: state.isSubmitting
                            ? null
                            : () async {
                                if (!_formKey.currentState!.validate()) return;
                                final area = double.parse(_areaController.text);
                                notifier.setAreaPlantedHa(area);

                                try {
                                  final user = Supabase.instance.client.auth.currentUser;
                                  final farmerId = _showFarmerSelect
                                      ? (_selectedFarmerId ?? '')
                                      : (user?.id ?? '');

                                  if (farmerId.isEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select or login as a farmer')));
                                    return;
                                  }

                                  final created = await notifier.submitPlantingRecord(farmerId: farmerId);
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Planting record submitted')));
                                    // redirect to the farmer profile we just recorded for
                                    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => FarmerProfileScreen(farmerId: farmerId)));
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                                  }
                                }
                              },
                        child: state.isSubmitting
                            ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator())
                            : const Text('Submit'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () async {
                          // Request endorsement for latest planting record.
                          // In a full implementation, you'd get the created record id from the backend.
                          // Here we simulate by showing a dialog to input starting bid and calling a placeholder.
                          final starting = await showDialog<double?>(
                            context: context,
                            builder: (c) {
                              final controller = TextEditingController(text: '50.00');
                              return AlertDialog(
                                title: const Text('Request Endorsement'),
                                content: TextField(
                                  controller: controller,
                                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                                  decoration: const InputDecoration(labelText: 'Starting bid price'),
                                ),
                                actions: [
                                  TextButton(onPressed: () => Navigator.of(c).pop(null), child: const Text('Cancel')),
                                  FilledButton(onPressed: () => Navigator.of(c).pop(double.tryParse(controller.text)), child: const Text('Request')),
                                ],
                              );
                            },
                          );

                          if (starting != null) {
                            if (!mounted) return;
                            // Placeholder: show confirmation. Real implementation will call MarketService.requestEndorsement
                            ScaffoldMessenger.of(this.context).showSnackBar(SnackBar(content: Text('Requested endorsement (start \u20B1${starting.toStringAsFixed(2)})')));
                          }
                        },
                        child: const Text('Request Endorsement'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
