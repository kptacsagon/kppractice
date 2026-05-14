import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../mock/agrisense_mock_data.dart';
import '../../models/agrisense_farmer_profile.dart';
import '../../models/agrisense_market_price.dart';
import '../../models/agrisense_price_alert.dart';
import '../../repositories/agrisense_repository.dart';
import 'agrisense_csi_screen.dart' show AgrisenseModuleHeader, AgrisenseModuleCard;

const _kGreen = Color(0xFF1B7737);

class AgrisenseMpiScreen extends StatefulWidget {
  const AgrisenseMpiScreen({super.key});

  @override
  State<AgrisenseMpiScreen> createState() => _AgrisenseMpiScreenState();
}

class _AgrisenseMpiScreenState extends State<AgrisenseMpiScreen> {
  AgrisenseFarmerProfile? _profile;
  List<AgrisenseMarketPrice> _prices = [];
  List<AgrisensePriceAlert> _alerts = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() { _loading = true; _error = null; });
    try {
      final client = Supabase.instance.client;
      final userId = client.auth.currentUser?.id;
      final repo = AgrisenseRepository(client);
      final profile = userId == null ? null : await repo.getFarmerProfile(userId);
      final resolvedProfile = profile ?? AgrisenseMockData.profile;
      List<AgrisenseMarketPrice> prices = [];
      List<AgrisensePriceAlert> alerts = [];
      if (profile?.id != null) {
        final priceRows = await client
            .from('agrisense_market_prices')
            .select()
            .eq('municipality', resolvedProfile.municipality)
            .order('recorded_date', ascending: false)
            .limit(20);
        prices = (priceRows as List).map((j) => AgrisenseMarketPrice.fromJson(j)).toList();
        alerts = await repo.getPriceAlerts(profile!.id!);
      }
      if (!mounted) return;
      setState(() {
        _profile = resolvedProfile;
        _prices = prices.isNotEmpty ? prices : AgrisenseMockData.marketPrices;
        _alerts = alerts.isNotEmpty ? alerts : AgrisenseMockData.priceAlerts;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _profile = AgrisenseMockData.profile;
        _prices = AgrisenseMockData.marketPrices;
        _alerts = AgrisenseMockData.priceAlerts;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F5F1),
      body: Column(
        children: [
          AgrisenseModuleHeader(title: 'Market Price Intelligence', subtitle: 'Sub-Module 05 — MPI', icon: Icons.bar_chart_rounded),
          Expanded(child: _loading
            ? const Center(child: CircularProgressIndicator(color: _kGreen))
            : _error != null
              ? Center(child: Text('Unable to load MPI data.\n$_error', textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFF6B7280))))
              : _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPriceSummary(),
          const SizedBox(height: 14),
          _buildLivePricesCard(),
          const SizedBox(height: 14),
          _buildHarvestTimingAdvisor(),
          const SizedBox(height: 14),
          _buildPriceAlertCard(),
          const SizedBox(height: 14),
          _buildMyAlerts(),
          const SizedBox(height: 14),
          _buildBuyerDirectory(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildPriceSummary() {
    if (_prices.isEmpty) {
      return AgrisenseModuleCard(
        child: const Column(
          children: [
            Icon(Icons.info_outline_rounded, color: Color(0xFF6B7280), size: 32),
            SizedBox(height: 8),
            Text('No price data yet for your municipality.', style: TextStyle(fontWeight: FontWeight.w600)),
            SizedBox(height: 4),
            Text('Prices will appear once MAO records market data.', style: TextStyle(fontSize: 12, color: Color(0xFF9CA3AF))),
          ],
        ),
      );
    }

    final latest = _prices.first;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF1B7737), Color(0xFF2D9E4E)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Today\'s Top Price', style: TextStyle(color: Colors.white70, fontSize: 12)),
                const SizedBox(height: 4),
                Text(latest.cropType, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
                const SizedBox(height: 2),
                Text('₱${latest.pricePerKg.toStringAsFixed(2)}/kg', style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: Colors.white.withAlpha(30), borderRadius: BorderRadius.circular(8)),
                child: const Text('Live', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
              ),
              const SizedBox(height: 8),
              Text(_profile?.municipality ?? '', style: const TextStyle(color: Colors.white70, fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLivePricesCard() {
    return AgrisenseModuleCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.price_change_rounded, color: _kGreen, size: 18),
              SizedBox(width: 8),
              Text('Live Market Prices', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
              Spacer(),
              Text('₱/kg', style: TextStyle(fontSize: 11, color: Color(0xFF9CA3AF))),
            ],
          ),
          const SizedBox(height: 12),
          if (_prices.isEmpty)
            for (final p in _staticPrices) ...[
              _PriceRow(crop: p.crop, price: p.price, trend: p.trend, change: p.change),
              if (p != _staticPrices.last) const Divider(height: 14),
            ]
          else
            for (final p in _prices.take(6)) ...[
              _LivePriceRow(price: p),
              if (p != _prices.take(6).last) const Divider(height: 14),
            ],
        ],
      ),
    );
  }

  static const _staticPrices = [
    _StaticPrice('Sweet Corn', '18.50', true, '+₱1.20'),
    _StaticPrice('Eggplant', '35.00', false, '–₱2.50'),
    _StaticPrice('Chili', '75.00', true, '+₱5.00'),
    _StaticPrice('Rice (Dry)', '22.00', false, '–₱0.50'),
    _StaticPrice('Tomato', '42.00', true, '+₱3.00'),
    _StaticPrice('Bitter Gourd', '28.00', false, '–₱1.00'),
  ];

  Widget _buildHarvestTimingAdvisor() {
    return AgrisenseModuleCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.schedule_rounded, color: Color(0xFFF59E0B), size: 18),
              SizedBox(width: 8),
              Text('Harvest Timing Advisor', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: const Color(0xFFFFFBEB), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFFDE68A))),
            child: const Text(
              'Sweet Corn prices historically peak in the 3rd week of the month due to weekend market demand. '
              'Consider delaying harvest by 4–5 days for a 12–15% price premium.',
              style: TextStyle(fontSize: 12, color: Color(0xFF78350F)),
            ),
          ),
          const SizedBox(height: 10),
          const _TimingRow(crop: 'Sweet Corn', bestWindow: 'Jun 18 – Jun 22', expectedPrice: '₱20–22/kg', status: 'Wait'),
          const Divider(height: 14),
          const _TimingRow(crop: 'Eggplant', bestWindow: 'Jun 12 – Jun 15', expectedPrice: '₱36–38/kg', status: 'Harvest Now'),
          const Divider(height: 14),
          const _TimingRow(crop: 'Chili', bestWindow: 'Jun 25 – Jul 2', expectedPrice: '₱80–85/kg', status: 'Wait'),
        ],
      ),
    );
  }

  Widget _buildPriceAlertCard() {
    final cropLabel = _profile?.primaryCrops.isNotEmpty == true ? _profile!.primaryCrops.first : 'your crop';
    return AgrisenseModuleCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.notifications_active_rounded, color: Color(0xFF3B82F6), size: 18),
              SizedBox(width: 8),
              Text('Price Alert', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Set a target price for $cropLabel and get notified when the market hits it.',
            style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF3B82F6), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            onPressed: _profile == null ? null : _openAlertDialog,
            icon: const Icon(Icons.add_alert_rounded, size: 16),
            label: const Text('Set Price Alert'),
          ),
        ],
      ),
    );
  }

  Widget _buildMyAlerts() {
    if (_alerts.isEmpty) return const SizedBox.shrink();
    return AgrisenseModuleCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('My Active Alerts', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          for (final a in _alerts.take(4)) ...[
            Row(
              children: [
                const Icon(Icons.circle, size: 8, color: Color(0xFF3B82F6)),
                const SizedBox(width: 8),
                Expanded(child: Text(a.cropType, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
                Text('₱${a.targetPrice.toStringAsFixed(2)}/kg target', style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: a.isActive ? const Color(0xFFDCFCE7) : const Color(0xFFF3F4F6), borderRadius: BorderRadius.circular(4)),
                  child: Text(a.isActive ? 'Active' : 'Paused', style: TextStyle(fontSize: 9, color: a.isActive ? const Color(0xFF16A34A) : const Color(0xFF6B7280), fontWeight: FontWeight.w700)),
                ),
              ],
            ),
            if (a != _alerts.take(4).last) const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }

  Widget _buildBuyerDirectory() {
    return AgrisenseModuleCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Row(
            children: [
              Icon(Icons.storefront_rounded, color: _kGreen, size: 18),
              SizedBox(width: 8),
              Text('Verified Buyer Directory', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
            ],
          ),
          SizedBox(height: 12),
          _BuyerTile(name: 'LGU Trading Post', type: 'Municipal Buyer', crops: 'Rice, Corn, Vegetables', contact: '0917-123-4567'),
          Divider(height: 16),
          _BuyerTile(name: 'AgriMart Cooperative', type: 'Cooperative', crops: 'All crops', contact: '0928-987-6543'),
          Divider(height: 16),
          _BuyerTile(name: 'FreshLink Express', type: 'Trader / Hauler', crops: 'Eggplant, Chili, Tomato', contact: '0905-555-1234'),
          Divider(height: 16),
          _BuyerTile(name: 'NFA Warehouse', type: 'Government', crops: 'Palay (Rice)', contact: '(049) 531-2020'),
        ],
      ),
    );
  }

  Future<void> _openAlertDialog() async {
    final cropController = TextEditingController(text: _profile?.primaryCrops.isNotEmpty == true ? _profile!.primaryCrops.first : '');
    final priceController = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Set Price Alert'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: cropController, decoration: const InputDecoration(labelText: 'Crop Type *')),
            const SizedBox(height: 12),
            TextField(controller: priceController, decoration: const InputDecoration(labelText: 'Target Price (₱/kg) *'), keyboardType: const TextInputType.numberWithOptions(decimal: true)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF3B82F6)),
            onPressed: () {
              if (cropController.text.trim().isEmpty || priceController.text.trim().isEmpty) {
                ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('All fields are required.')));
                return;
              }
              Navigator.pop(ctx, true);
            },
            child: const Text('Save Alert'),
          ),
        ],
      ),
    );
    if (result != true || _profile == null) return;
    final parsed = double.tryParse(priceController.text.trim());
    if (parsed == null) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid price.')));
      return;
    }
    try {
      final repo = AgrisenseRepository(Supabase.instance.client);
      await repo.savePriceAlert(AgrisensePriceAlert(farmerId: _profile!.id!, cropType: cropController.text.trim(), targetPrice: parsed, createdAt: DateTime.now()));
      await _loadData();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Price alert saved.')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
    }
  }
}

class _StaticPrice {
  final String crop;
  final String price;
  final bool trend;
  final String change;
  const _StaticPrice(this.crop, this.price, this.trend, this.change);
}

class _PriceRow extends StatelessWidget {
  final String crop;
  final String price;
  final bool trend;
  final String change;
  const _PriceRow({required this.crop, required this.price, required this.trend, required this.change});

  @override
  Widget build(BuildContext context) {
    final color = trend ? const Color(0xFF16A34A) : const Color(0xFFDC2626);
    return Row(
      children: [
        Expanded(child: Text(crop, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600))),
        Text('₱$price', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
        const SizedBox(width: 8),
        Row(
          children: [
            Icon(trend ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded, size: 12, color: color),
            Text(change, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600)),
          ],
        ),
      ],
    );
  }
}

class _LivePriceRow extends StatelessWidget {
  final AgrisenseMarketPrice price;
  const _LivePriceRow({required this.price});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(price.cropType, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            Text(price.recordedDate.toIso8601String().split('T')[0], style: const TextStyle(fontSize: 10, color: Color(0xFF9CA3AF))),
          ],
        )),
        Text('₱${price.pricePerKg.toStringAsFixed(2)}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
      ],
    );
  }
}

class _TimingRow extends StatelessWidget {
  final String crop;
  final String bestWindow;
  final String expectedPrice;
  final String status;
  const _TimingRow({required this.crop, required this.bestWindow, required this.expectedPrice, required this.status});

  @override
  Widget build(BuildContext context) {
    final isNow = status == 'Harvest Now';
    final color = isNow ? const Color(0xFF16A34A) : const Color(0xFF3B82F6);
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(crop, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              Text('$bestWindow · $expectedPrice', style: const TextStyle(fontSize: 10, color: Color(0xFF9CA3AF))),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(color: color.withAlpha(20), borderRadius: BorderRadius.circular(6)),
          child: Text(status, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w700)),
        ),
      ],
    );
  }
}

class _BuyerTile extends StatelessWidget {
  final String name;
  final String type;
  final String crops;
  final String contact;
  const _BuyerTile({required this.name, required this.type, required this.crops, required this.contact});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: const Color(0xFFF0F5F1), borderRadius: BorderRadius.circular(8)),
          child: const Icon(Icons.storefront_rounded, size: 16, color: _kGreen),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
              Text(type, style: const TextStyle(fontSize: 10, color: Color(0xFF6B7280))),
              Text(crops, style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF))),
            ],
          ),
        ),
        Text(contact, style: const TextStyle(fontSize: 10, color: Color(0xFF3B82F6), fontWeight: FontWeight.w600)),
      ],
    );
  }
}
