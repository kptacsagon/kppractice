import 'package:flutter/material.dart';
import 'agrisense_csi_screen.dart' show AgrisenseModuleHeader, AgrisenseModuleCard;

const _kGreen = Color(0xFF1B7737);

class AgrisenseWcraScreen extends StatelessWidget {
  const AgrisenseWcraScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F5F1),
      body: Column(
        children: [
          AgrisenseModuleHeader(
            title: 'Weather & Climate Risk',
            subtitle: 'Sub-Module 03 — WCRA',
            icon: Icons.cloud_rounded,
          ),
          const Expanded(child: _WcraBody()),
        ],
      ),
    );
  }
}

class _WcraBody extends StatelessWidget {
  const _WcraBody();

  static const _forecast = [
    _DayForecast('Today', Icons.cloud_rounded, '28°C', '72%', 'Cloudy'),
    _DayForecast('Wed', Icons.thunderstorm_rounded, '26°C', '90%', 'Stormy'),
    _DayForecast('Thu', Icons.thunderstorm_rounded, '25°C', '85%', 'Heavy Rain'),
    _DayForecast('Fri', Icons.cloudy_snowing, '27°C', '60%', 'Light Rain'),
    _DayForecast('Sat', Icons.wb_sunny_rounded, '30°C', '20%', 'Sunny'),
    _DayForecast('Sun', Icons.wb_sunny_rounded, '31°C', '15%', 'Clear'),
    _DayForecast('Mon', Icons.cloud_rounded, '29°C', '40%', 'Partly Cloudy'),
  ];

  static const _plantingCal = [
    _CalEntry('Rice (NSIC Rc222)', 'Jun 12 – Jul 3', 'Optimal', Color(0xFF16A34A)),
    _CalEntry('Sweet Corn', 'Jun 1 – Jun 20', 'Good', Color(0xFF3B82F6)),
    _CalEntry('Eggplant', 'May 15 – Jun 10', 'Caution — dry spell risk', Color(0xFFF59E0B)),
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTyphoonAlert(),
          const SizedBox(height: 14),
          _build7DayForecast(),
          const SizedBox(height: 14),
          _buildSeasonalOutlook(),
          const SizedBox(height: 14),
          _buildPlantingCalendar(),
          const SizedBox(height: 14),
          _buildDrySpellWarning(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildTyphoonAlert() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFF97316), Color(0xFFDC2626)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Text('PAGASA — Typhoon Signal 1', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
            ],
          ),
          SizedBox(height: 8),
          Text(
            'Heavy rainfall expected within 48 hours. Protect crops: secure netting, clear drainage canals, '
            'and avoid pesticide application. Harvest mature crops if possible.',
            style: TextStyle(color: Color(0xFFFFE4C4), fontSize: 12),
          ),
          SizedBox(height: 10),
          _CropProtectionChecklist(),
        ],
      ),
    );
  }

  Widget _build7DayForecast() {
    return AgrisenseModuleCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.wb_sunny_rounded, color: _kGreen, size: 18),
              SizedBox(width: 8),
              Text('7-Day Forecast', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
              Spacer(),
              Text('Your Municipality', style: TextStyle(fontSize: 11, color: Color(0xFF9CA3AF))),
            ],
          ),
          const SizedBox(height: 14),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _forecast.map((d) => _DayCard(day: d)).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSeasonalOutlook() {
    return AgrisenseModuleCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('3-Month Seasonal Outlook', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          _OutlookRow(label: 'ENSO Status', value: 'El Niño Watch', color: const Color(0xFFF59E0B)),
          _OutlookRow(label: 'Rainfall Deviation', value: '–12% below normal', color: const Color(0xFFDC2626)),
          _OutlookRow(label: 'Dry Spell Probability', value: 'Moderate (40%)', color: const Color(0xFFF59E0B)),
          _OutlookRow(label: 'Season Type', value: 'Wet Season (Transitioning)', color: const Color(0xFF3B82F6)),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFBEB),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFFDE68A)),
            ),
            child: const Text(
              'Advisory: Expect reduced rainfall in July. Consider drought-tolerant varieties and efficient irrigation scheduling.',
              style: TextStyle(fontSize: 12, color: Color(0xFF78350F)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlantingCalendar() {
    return AgrisenseModuleCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Climate-Adjusted Planting Calendar', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          const Text('Optimal planting windows for your top recommended crops',
              style: TextStyle(fontSize: 11, color: Color(0xFF9CA3AF))),
          const SizedBox(height: 12),
          for (final entry in _plantingCal) ...[
            _CalRow(entry: entry),
            if (entry != _plantingCal.last) const Divider(height: 16),
          ],
        ],
      ),
    );
  }

  Widget _buildDrySpellWarning() {
    return AgrisenseModuleCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.water_drop_outlined, color: Color(0xFF3B82F6), size: 18),
              SizedBox(width: 8),
              Text('Dry Spell Monitor', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 10),
          _DrySpellRow(crop: 'Rice (Vegetative)', threshold: '14 days', current: '4 days', safe: true),
          _DrySpellRow(crop: 'Corn (Silking)', threshold: '7 days', current: '4 days', safe: true),
          _DrySpellRow(crop: 'Eggplant', threshold: '10 days', current: '4 days', safe: true),
          const SizedBox(height: 8),
          const Text('Consecutive days without rainfall: 4 days', style: TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
        ],
      ),
    );
  }
}

class _CropProtectionChecklist extends StatelessWidget {
  const _CropProtectionChecklist();

  static const _items = [
    'Secure greenhouse netting and row covers',
    'Clear drainage canals to prevent waterlogging',
    'Harvest mature crops before storm landfall',
    'Avoid fertilizer application 48h before rain',
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: _items.map((item) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.check_circle_outline_rounded, color: Colors.white, size: 14),
            const SizedBox(width: 6),
            Expanded(child: Text(item, style: const TextStyle(color: Colors.white, fontSize: 11))),
          ],
        ),
      )).toList(),
    );
  }
}

class _DayForecast {
  final String day;
  final IconData icon;
  final String temp;
  final String rain;
  final String label;
  const _DayForecast(this.day, this.icon, this.temp, this.rain, this.label);
}

class _DayCard extends StatelessWidget {
  final _DayForecast day;
  const _DayCard({required this.day});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 68,
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F5F1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        children: [
          Text(day.day, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF6B7280))),
          const SizedBox(height: 6),
          Icon(day.icon, size: 22, color: const Color(0xFF3B82F6)),
          const SizedBox(height: 6),
          Text(day.temp, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
          const SizedBox(height: 2),
          Text('${day.rain} rain', style: const TextStyle(fontSize: 9, color: Color(0xFF9CA3AF))),
        ],
      ),
    );
  }
}

class _OutlookRow extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _OutlookRow({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(width: 140, child: Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)))),
          Expanded(child: Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color))),
        ],
      ),
    );
  }
}

class _CalEntry {
  final String crop;
  final String window;
  final String status;
  final Color color;
  const _CalEntry(this.crop, this.window, this.status, this.color);
}

class _CalRow extends StatelessWidget {
  final _CalEntry entry;
  const _CalRow({required this.entry});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(entry.crop, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              Text(entry.window, style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(color: entry.color.withAlpha(20), borderRadius: BorderRadius.circular(8)),
          child: Text(entry.status, style: TextStyle(fontSize: 10, color: entry.color, fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }
}

class _DrySpellRow extends StatelessWidget {
  final String crop;
  final String threshold;
  final String current;
  final bool safe;
  const _DrySpellRow({required this.crop, required this.threshold, required this.current, required this.safe});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(safe ? Icons.check_circle_rounded : Icons.warning_rounded,
              color: safe ? const Color(0xFF16A34A) : const Color(0xFFDC2626), size: 14),
          const SizedBox(width: 8),
          Expanded(child: Text(crop, style: const TextStyle(fontSize: 12))),
          Text('$current / $threshold', style: TextStyle(fontSize: 11, color: safe ? const Color(0xFF16A34A) : const Color(0xFFDC2626), fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
