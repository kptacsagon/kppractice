import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/report_model.dart';
import '../../theme/app_theme.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<CalamityReport> _calamityReports = [];
  List<ProductionReport> _productionReports = [];
  bool _isLoading = true;
  String? _userId;

  final List<String> _calamityTypes = [
    'Typhoon (Bagyo)',
    'Flooding (Baha)',
    'Drought (El Niño)',
    'Pest Infestation',
    'Disease Outbreak',
    'Landslide',
    'Volcanic Eruption',
    'Fire',
    'Other',
  ];

  final List<String> _cropTypes = [
    'Rice (Palay)',
    'Corn (Mais)',
    'Coconut (Niyog)',
    'Sugarcane (Tubo)',
    'Banana (Saging)',
    'Vegetables (Gulay)',
    'Root Crops (Kamote/Gabi)',
    'Mango',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    _userId = user.id;

    setState(() => _isLoading = true);
    try {
      final calamityResponse = await Supabase.instance.client
          .from('calamity_reports')
          .select()
          .eq('farmer_id', _userId!)
          .order('date_occurred', ascending: false);

      final productionResponse = await Supabase.instance.client
          .from('production_reports')
          .select()
          .eq('farmer_id', _userId!)
          .order('harvest_date', ascending: false);

      setState(() {
        _calamityReports = List<CalamityReport>.from((calamityResponse as List)
            .map((r) => CalamityReport.fromJson(r as Map<String, dynamic>)));
        _productionReports = List<ProductionReport>.from((productionResponse as List)
            .map((r) => ProductionReport.fromJson(r as Map<String, dynamic>)));
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading reports: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        elevation: 0,
        title: const Text(
          'Farm Reports',
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
            Tab(text: 'Calamity Reports'),
            Tab(text: 'Production Reports'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
        controller: _tabController,
        children: [
          _buildCalamityReportsTab(),
          _buildProductionReportsTab(),
        ],
      ),
    );
  }

  Widget _buildCalamityReportsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _showCalamityReportDialog(),
              icon: const Icon(Icons.add),
              label: const Text('Report Calamity'),
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
          // Summary cards
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                SizedBox(
                  width: 160,
                  child: _buildSummaryCard(
                    'Total Reports',
                    _calamityReports.length.toString(),
                    Icons.warning_rounded,
                    const Color(0xFFFF9800),
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 160,
                  child: _buildSummaryCard(
                    'High Severity',
                    _calamityReports
                        .where((r) => r.severity == 'high')
                        .length
                        .toString(),
                    Icons.priority_high,
                    Colors.red,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (_calamityReports.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.cloud_done_rounded,
                        size: 64, color: AppTheme.textLight),
                    const SizedBox(height: 16),
                    const Text(
                      'No calamity reports yet',
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
              itemCount: _calamityReports.length,
              itemBuilder: (context, index) {
                return _buildCalamityCard(_calamityReports[index], index);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildCalamityCard(CalamityReport report, int index) {
    final Color severityColor = report.severity == 'high'
        ? Colors.red
        : report.severity == 'medium'
            ? Colors.orange
            : Colors.yellow;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Text(
                  report.imageUrl,
                  style: const TextStyle(fontSize: 32),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        report.type,
                        style: const TextStyle(
                          color: AppTheme.textDark,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: severityColor.withAlpha(25),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              report.severity.toUpperCase(),
                              style: TextStyle(
                                color: severityColor,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: _getStatusColor(report.status)
                                  .withAlpha(25),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              report.status.toUpperCase(),
                              style: TextStyle(
                                color: _getStatusColor(report.status),
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.more_vert,
                      color: AppTheme.textMedium, size: 20),
                  onPressed: () => _showReportOptions(report, index),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Description
            Text(
              report.description,
              style: const TextStyle(
                color: AppTheme.textMedium,
                fontSize: 13,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 12),
            // Details grid
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.inputBackground,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDetailRow(
                    'Date Occurred',
                    '${report.dateOccurred.day}/${report.dateOccurred.month}/${report.dateOccurred.year}',
                    'Affected Area',
                    '${report.affectedArea} ha',
                  ),
                  const SizedBox(height: 12),
                  _buildDetailRow(
                    'Crop Stage',
                    report.cropStage.isNotEmpty ? report.cropStage : 'N/A',
                    'Est. Financial Loss',
                    '₱${report.estimatedFinancialLoss.toStringAsFixed(0)}',
                  ),
                  const SizedBox(height: 12),
                  _buildDetailItem('Farmer', report.farmerName),
                  const SizedBox(height: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Affected Crops',
                        style: TextStyle(
                          color: AppTheme.textLight,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: report.affectedCrops
                            .map((crop) => Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primary.withAlpha(25),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    crop,
                                    style: const TextStyle(
                                      color: AppTheme.primary,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ))
                            .toList(),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Show image if available
            if (report.imageUrl.isNotEmpty) ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  report.imageUrl,
                  height: 150,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: 60,
                    decoration: BoxDecoration(
                      color: AppTheme.inputBackground,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.image_not_supported, size: 16, color: AppTheme.textLight),
                          SizedBox(width: 6),
                          Text('Photo unavailable', style: TextStyle(fontSize: 11, color: AppTheme.textLight)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildProductionReportsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _showProductionReportDialog(),
              icon: const Icon(Icons.add),
              label: const Text('Add Production Report'),
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
          if (_productionReports.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.trending_up_rounded,
                        size: 64, color: AppTheme.textLight),
                    const SizedBox(height: 16),
                    const Text(
                      'No production reports yet',
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
              itemCount: _productionReports.length,
              itemBuilder: (context, index) {
                return _buildProductionCard(_productionReports[index]);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildProductionCard(ProductionReport report) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: AppTheme.inputBackground,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Center(
                    child: Icon(Icons.grass, color: Colors.green, size: 28),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        report.cropType,
                        style: const TextStyle(
                          color: AppTheme.textDark,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Reported: ${report.reportDate.day}/${report.reportDate.month}/${report.reportDate.year}',
                        style: const TextStyle(
                          color: AppTheme.textLight,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Stats grid
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.inputBackground,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDetailRow('Area', '${report.area} ha', 'Yield/Hectare',
                      '${report.yieldPerHectare.toStringAsFixed(1)} kg'),
                  const SizedBox(height: 12),
                  _buildDetailRow('Total Yield', '${report.totalYield} kg',
                      'Quality', _getQualityLabel(report.qualityRating)),
                  const SizedBox(height: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Notes',
                        style: TextStyle(
                          color: AppTheme.textLight,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        report.notes,
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
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withAlpha(20),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              color: AppTheme.textMedium,
              fontSize: 12,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppTheme.textLight,
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            color: AppTheme.textDark,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildDetailRow(
      String label1, String value1, String label2, String value2) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(child: _buildDetailItem(label1, value1)),
        const SizedBox(width: 16),
        Flexible(child: _buildDetailItem(label2, value2)),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'verified':
        return Colors.green;
      case 'resolved':
        return Colors.blue;
      default:
        return Colors.orange;
    }
  }

  void _showReportOptions(CalamityReport report, int index) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit, color: AppTheme.primary),
              title: const Text('Edit Report'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Edit functionality coming soon')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Delete Report'),
              onTap: () async {
                Navigator.pop(context);
                try {
                  await Supabase.instance.client
                      .from('calamity_reports')
                      .delete()
                      .eq('id', report.id);
                  _loadData();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Report deleted')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error deleting: $e'), backgroundColor: Colors.red),
                  );
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.close, color: AppTheme.textMedium),
              title: const Text('Cancel'),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  void _showCalamityReportDialog() {
    final formKey = GlobalKey<FormState>();
    String? type = _calamityTypes.first;
    String? description;
    String severity = 'medium';
    double? area;
    List<String> selectedCrops = [];
    String cropStage = 'Seedling';
    double? estimatedFinancialLoss;
    DateTime selectedDate = DateTime.now();
    XFile? pickedImage;
    String? pickedImageName;
    String? selectedProjectId;
    List<Map<String, dynamic>> activeProjects = [];

    final cropStages = ['Seedling', 'Vegetative', 'Flowering', 'Ready for Harvest'];

    // Fetch active projects for optional linking
    Future<void> loadActiveProjects() async {
      if (_userId == null) return;
      try {
        final data = await Supabase.instance.client
            .from('farming_projects')
            .select('id, crop_type, area_hectares, status')
            .eq('farmer_id', _userId!)
            .eq('status', 'active');
        activeProjects = List<Map<String, dynamic>>.from(data);
      } catch (_) {}
    }
    loadActiveProjects();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
        title: const Text('Report Calamity'),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: type,
                  decoration: const InputDecoration(labelText: 'Calamity Type'),
                  items: _calamityTypes
                      .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                      .toList(),
                  onChanged: (value) => type = value,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    hintText: 'Describe the calamity and its impact',
                  ),
                  maxLines: 3,
                  validator: (value) =>
                      value?.isEmpty ?? true ? 'Required' : null,
                  onSaved: (value) => description = value,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: severity,
                  decoration: const InputDecoration(labelText: 'Severity'),
                  items: ['low', 'medium', 'high']
                      .map((s) => DropdownMenuItem(
                            value: s,
                            child: Text(s.toUpperCase()),
                          ))
                      .toList(),
                  onChanged: (value) => severity = value ?? 'medium',
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: 'Crop Affected'),
                  items: _cropTypes
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  validator: (value) =>
                      value?.isEmpty ?? true ? 'Required' : null,
                  onChanged: (value) {
                    if (value != null) selectedCrops = [value];
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: cropStage,
                  decoration: const InputDecoration(labelText: 'Crop Stage'),
                  items: cropStages
                      .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                      .toList(),
                  onChanged: (value) => cropStage = value ?? 'Seedling',
                ),
                const SizedBox(height: 12),
                // Link to active farming project (optional)
                if (activeProjects.isNotEmpty) ...[
                  DropdownButtonFormField<String>(
                    value: selectedProjectId,
                    decoration: const InputDecoration(
                      labelText: 'Link to Farming Project (Optional)',
                      hintText: 'Select project affected',
                    ),
                    items: [
                      const DropdownMenuItem<String>(
                        value: null,
                        child: Text('None — General Report'),
                      ),
                      ...activeProjects.map((p) => DropdownMenuItem<String>(
                        value: p['id']?.toString(),
                        child: Text('${p['crop_type']} (${p['area_hectares']} ha)'),
                      )),
                    ],
                    onChanged: (value) => selectedProjectId = value,
                  ),
                  const SizedBox(height: 12),
                ],
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Affected Area (hectares)',
                  ),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  validator: (value) =>
                      value?.isEmpty ?? true ? 'Required' : null,
                  onSaved: (value) => area = double.parse(value ?? '0'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Estimated Financial Loss (₱)',
                    prefixText: '₱ ',
                  ),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  validator: (value) =>
                      value?.isEmpty ?? true ? 'Required' : null,
                  onSaved: (value) => estimatedFinancialLoss = double.parse(value ?? '0'),
                ),
                const SizedBox(height: 12),
                // Image upload
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppTheme.border),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      if (pickedImageName != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              const Icon(Icons.check_circle, color: Colors.green, size: 16),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  pickedImageName!,
                                  style: const TextStyle(fontSize: 12, color: AppTheme.textMedium),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      OutlinedButton.icon(
                        onPressed: () async {
                          final picker = ImagePicker();
                          final image = await picker.pickImage(
                            source: ImageSource.gallery,
                            maxWidth: 1200,
                            maxHeight: 1200,
                            imageQuality: 80,
                          );
                          if (image != null) {
                            setDialogState(() {
                              pickedImage = image;
                              pickedImageName = image.name;
                            });
                          }
                        },
                        icon: const Icon(Icons.camera_alt, size: 18),
                        label: Text(pickedImageName != null ? 'Change Photo' : 'Upload Photo Evidence'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Date of Occurrence',
                  style: TextStyle(fontSize: 12, color: AppTheme.textMedium),
                ),
                const SizedBox(height: 6),
                GestureDetector(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) {
                      selectedDate = picked;
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppTheme.border),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                    ),
                  ),
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
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                formKey.currentState!.save();

                if (_userId == null) return;

                try {
                  // Upload image if picked
                  String imageUrl = '';
                  if (pickedImage != null) {
                    try {
                      final bytes = await pickedImage!.readAsBytes();
                      final fileName = 'calamity_${DateTime.now().millisecondsSinceEpoch}_${pickedImage!.name}';
                      await Supabase.instance.client.storage
                          .from('calamity-images')
                          .uploadBinary(fileName, bytes);
                      imageUrl = Supabase.instance.client.storage
                          .from('calamity-images')
                          .getPublicUrl(fileName);
                    } catch (uploadError) {
                      // Continue without image if upload fails
                      debugPrint('Image upload failed: $uploadError');
                    }
                  }

                  final data = {
                    'farmer_id': _userId!,
                    'calamity_type': type ?? 'Typhoon (Bagyo)',
                    'description': description ?? '',
                    'severity': severity.toUpperCase(),
                    'date_occurred': selectedDate.toIso8601String().split('T').first,
                    'affected_area_acres': area ?? 0,
                    'affected_crops': selectedCrops.join(','),
                    'crop_stage': cropStage,
                    'estimated_financial_loss': estimatedFinancialLoss ?? 0,
                    'damage_estimate': estimatedFinancialLoss ?? 0,
                    'image_url': imageUrl,
                    'farmer_name': Supabase.instance.client.auth.currentUser?.userMetadata?['full_name'] ?? 'Farmer',
                    'status': 'reported',
                    if (selectedProjectId != null) 'project_id': selectedProjectId,
                  };

                  await Supabase.instance.client
                      .from('calamity_reports')
                      .insert(data);

                  // Auto-recalculate project P&L if HIGH severity calamity linked to project
                  if (selectedProjectId != null && severity.toUpperCase() == 'HIGH') {
                    try {
                      final project = await Supabase.instance.client
                          .from('farming_projects')
                          .select()
                          .eq('id', selectedProjectId)
                          .single();
                      
                      final currentExpectedRevenue = (project['expected_revenue'] as num?)?.toDouble() ?? 0.0;
                      final loss = (estimatedFinancialLoss ?? 0).toDouble();
                      
                      // Reduce expected revenue by loss amount (capped at 50%)
                      final newExpectedRevenue = (currentExpectedRevenue - loss).clamp(0.0, currentExpectedRevenue);
                      
                      await Supabase.instance.client
                          .from('farming_projects')
                          .update({'expected_revenue': newExpectedRevenue})
                          .eq('id', selectedProjectId);
                    } catch (e) {
                      debugPrint('Failed to auto-recalc project P&L: $e');
                    }
                  }

                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Calamity reported successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  _loadData(); // Reload from Supabase
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error saving report: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Submit Report'),
          ),
        ],
      ),
      ),
    );
  }

  void _showProductionReportDialog() {
    final formKey = GlobalKey<FormState>();
    String? cropType;
    double? area;
    double? totalYield;
    String qualityClass = 'Class A (Premium)';
    String? notes;
    DateTime plantingDate = DateTime.now().subtract(const Duration(days: 120));
    DateTime harvestDate = DateTime.now();

    final qualityClasses = [
      'Class A (Premium)',
      'Class B (Standard)',
      'Class C (Substandard/Damaged)',
    ];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Production Report'),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: 'Crop Type'),
                  items: _cropTypes
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  validator: (value) =>
                      value?.isEmpty ?? true ? 'Required' : null,
                  onChanged: (value) => cropType = value,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Area (hectares)',
                  ),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  validator: (value) =>
                      value?.isEmpty ?? true ? 'Required' : null,
                  onSaved: (value) => area = double.parse(value ?? '0'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Total Yield (kg)',
                  ),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  validator: (value) =>
                      value?.isEmpty ?? true ? 'Required' : null,
                  onSaved: (value) => totalYield = double.parse(value ?? '0'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: qualityClass,
                  decoration: const InputDecoration(labelText: 'Quality Classification'),
                  items: qualityClasses
                      .map((q) => DropdownMenuItem(value: q, child: Text(q)))
                      .toList(),
                  onChanged: (value) => qualityClass = value ?? 'Class A (Premium)',
                ),
                const SizedBox(height: 12),
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Notes',
                  ),
                  maxLines: 2,
                  onSaved: (value) => notes = value,
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
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                formKey.currentState!.save();

                if (_userId == null) return;

                // Map quality class to numeric value for DB
                int qualityRating;
                if (qualityClass.startsWith('Class A')) {
                  qualityRating = 5;
                } else if (qualityClass.startsWith('Class B')) {
                  qualityRating = 3;
                } else {
                  qualityRating = 1;
                }

                try {
                  final data = {
                    'farmer_id': _userId!,
                    'crop_type': cropType ?? '',
                    'area_hectares': area ?? 0,
                    'planting_date': plantingDate.toIso8601String().split('T').first,
                    'harvest_date': harvestDate.toIso8601String().split('T').first,
                    'yield_kg': totalYield ?? 0,
                    'quality_rating': qualityRating,
                    'quality_class': qualityClass,
                    'notes': notes ?? '',
                  };

                  await Supabase.instance.client
                      .from('production_reports')
                      .insert(data);

                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Production report added successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  _loadData(); // Reload from Supabase
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error saving report: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Add Report'),
          ),
        ],
      ),
    );
  }

  String _getIconForCalamity(String type) {
    switch (type) {
      case 'Typhoon (Bagyo)':
        return '🌀';
      case 'Flooding (Baha)':
        return '🌊';
      case 'Drought (El Niño)':
        return '🏜️';
      case 'Pest Infestation':
        return '🐛';
      case 'Disease Outbreak':
        return '🦠';
      case 'Landslide':
        return '⛰️';
      case 'Volcanic Eruption':
        return '🌋';
      case 'Fire':
        return '🔥';
      default:
        return '⚠️';
    }
  }

  String _getQualityLabel(double rating) {
    if (rating >= 4) return 'Class A';
    if (rating >= 2) return 'Class B';
    return 'Class C';
  }
}
