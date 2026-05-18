import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/agri_ure_service.dart';

class AgriUreScreen extends StatefulWidget {
  const AgriUreScreen({super.key});

  @override
  State<AgriUreScreen> createState() => _AgriUreScreenState();
}

class _AgriUreScreenState extends State<AgriUreScreen> {
  static const _green = Color(0xFF1B7737);

  final _formKey = GlobalKey<FormState>();
  final _descController = TextEditingController();
  final _impactController = TextEditingController();

  String _selectedCrop = 'Ampalaya';
  String _selectedEventType = 'Pest/Disease';
  bool _submitting = false;
  bool _submitted = false;

  final _crops = ['Ampalaya', 'Eggplant', 'Tomato', 'Cabbage', 'Pepper', 'Squash', 'Other'];
  final _eventTypes = ['Pest/Disease', 'Flooding', 'Drought', 'Typhoon/Wind Damage', 'Market Price Crash', 'Other'];

  @override
  void dispose() {
    _descController.dispose();
    _impactController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) throw Exception('Not authenticated');

      final svc = AgriUreService();
      await svc.submitUreEvent(
        farmerId: user.id,
        cropType: _selectedCrop,
        eventType: _selectedEventType,
        description: _descController.text.trim(),
        financialImpact: double.tryParse(_impactController.text.trim()),
      );

      if (!mounted) return;
      setState(() { _submitting = false; _submitted = true; });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Report submitted successfully! MAO will review your report.'),
          backgroundColor: _green,
          duration: Duration(seconds: 4),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Submit failed: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        backgroundColor: _green,
        foregroundColor: Colors.white,
        title: const Text('Report Uncontrolled Risk Event'),
        elevation: 0,
      ),
      body: _submitted ? _buildSuccessView() : _buildForm(),
    );
  }

  Widget _buildSuccessView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: _green.withAlpha(20),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle_rounded, color: _green, size: 64),
            ),
            const SizedBox(height: 24),
            const Text('Report Submitted!',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Color(0xFF1a1a1a))),
            const SizedBox(height: 12),
            const Text(
              'Your URE report has been sent to the MAO office for review. You will be notified once it is verified.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Color(0xFF6B7280), height: 1.5),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  setState(() {
                    _submitted = false;
                    _descController.clear();
                    _impactController.clear();
                    _selectedCrop = 'Ampalaya';
                    _selectedEventType = 'Pest/Disease';
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Submit Another Report', style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Back to Dashboard', style: TextStyle(color: _green)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _infoCard(),
            const SizedBox(height: 16),
            _section('Event Details', [
              _dropdownField('Affected Crop', _selectedCrop, _crops, (v) => setState(() => _selectedCrop = v!)),
              const SizedBox(height: 12),
              _dropdownField('Event Type', _selectedEventType, _eventTypes, (v) => setState(() => _selectedEventType = v!)),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descController,
                maxLines: 4,
                decoration: _inputDeco('Description', 'Describe the event and its effects on your crop...'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Please describe the event' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _impactController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: _inputDeco('Estimated Financial Impact (₱)', 'Optional — estimated loss in pesos'),
              ),
            ]),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: _submitting
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Submit Report', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      child: const Row(
        children: [
          Icon(Icons.info_outline_rounded, color: Color(0xFF3B82F6), size: 20),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Uncontrolled Risk Events (UREs) are sudden events affecting your crops. Reports are reviewed by the MAO office.',
              style: TextStyle(fontSize: 12, color: Color(0xFF1E40AF), height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _section(String title, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(8), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF1a1a1a))),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }

  Widget _dropdownField(String label, String value, List<String> items, ValueChanged<String?> onChanged) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: _inputDeco(label, ''),
      items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
      onChanged: onChanged,
    );
  }

  InputDecoration _inputDeco(String label, String hint) {
    return InputDecoration(
      labelText: label,
      hintText: hint.isEmpty ? null : hint,
      hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFD1D5DB))),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFD1D5DB))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: _green)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      filled: true,
      fillColor: const Color(0xFFFAFAFA),
    );
  }
}
