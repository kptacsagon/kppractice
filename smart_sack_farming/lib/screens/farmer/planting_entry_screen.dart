import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/crop.dart';
import '../../providers/planting_provider.dart';

class PlantingEntryScreen extends ConsumerStatefulWidget {
  const PlantingEntryScreen({super.key});

  @override
  ConsumerState<PlantingEntryScreen> createState() => _PlantingEntryScreenState();
}

class _PlantingEntryScreenState extends ConsumerState<PlantingEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _areaController = TextEditingController();
  final _yieldController = TextEditingController();

  @override
  void dispose() {
    _areaController.dispose();
    _yieldController.dispose();
    super.dispose();
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

                TextFormField(
                  controller: _yieldController,
                  decoration: const InputDecoration(
                    labelText: 'Estimated yield (MT)',
                    hintText: 'e.g., 0.8',
                  ),
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Enter estimated yield';
                    final parsed = double.tryParse(v);
                    if (parsed == null) return 'Invalid number';
                    if (parsed < 0) return 'Cannot be negative';
                    return null;
                  },
                ),

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
                                final estYield = double.parse(_yieldController.text);
                                notifier.setAreaPlantedHa(area);
                                notifier.setEstimatedYieldMt(estYield);

                                try {
                                  // TODO: replace with actual farmer id from auth
                                  await notifier.submitPlantingRecord(farmerId: 'farmer-123');
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Planting record submitted')),
                                    );
                                  }
                                } catch (e) {
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Error: $e')),
                                    );
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
                            // Placeholder: show confirmation. Real implementation will call MarketService.requestEndorsement
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Requested endorsement (start \u20B1${starting.toStringAsFixed(2)})')));
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
