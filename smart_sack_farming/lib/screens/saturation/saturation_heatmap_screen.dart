import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Tubungan, Iloilo — corrected center coordinates
const _kCenterLat = 10.7654;
const _kCenterLng = 122.3181;

// ─── Barangay centroids distributed around 10.7654°N, 122.3181°E ────────────
const _kBarangayCoords = <String, _Coord>{
  'Adgao':              _Coord(10.7960, 122.2817),
  'Ago':                _Coord(10.7890, 122.2937),
  'Ambarihon':          _Coord(10.7480, 122.2657),
  'Ayubo':              _Coord(10.7560, 122.3337),
  'Bacan':              _Coord(10.8040, 122.3087),
  'Badiang':            _Coord(10.7850, 122.3217),
  'Bagunanay':          _Coord(10.7420, 122.3457),
  'Balicua':            _Coord(10.7270, 122.3577),
  'Bantayanan':         _Coord(10.7790, 122.2587),
  'Batga':              _Coord(10.7160, 122.2957),
  'Bato':               _Coord(10.7620, 122.2477),
  'Bikil':              _Coord(10.8120, 122.3307),
  'Boloc':              _Coord(10.7030, 122.3177),
  'Bondoc (Sto. Niño)': _Coord(10.8000, 122.3477),
  'Borong':             _Coord(10.7460, 122.3687),
  'Buenavista':         _Coord(10.7690, 122.3557),
  'Cadabdab':           _Coord(10.7320, 122.2767),
  'Daga-ay':            _Coord(10.8180, 122.3217),
  'Desposorio':         _Coord(10.7550, 122.3037),
  'Igdampog Norte':     _Coord(10.7740, 122.2997),
  'Igdampog Sur':       _Coord(10.7700, 122.3047),
  'Igpaho':             _Coord(10.7380, 122.3277),
  'Igtuble':            _Coord(10.7230, 122.3397),
  'Ingay':              _Coord(10.7920, 122.2687),
  'Isauan':             _Coord(10.7080, 122.3297),
  'Jolason':            _Coord(10.8060, 122.2987),
  'Jona':               _Coord(10.7510, 122.2557),
  'La-ag (San Vicente)':_Coord(10.7600, 122.3727),
  'Lanag Norte':        _Coord(10.6990, 122.3037),
  'Lanag Sur':          _Coord(10.6940, 122.3117),
  'Male':               _Coord(10.8140, 122.2887),
  'Mayang':             _Coord(10.7350, 122.3507),
  'Molina':             _Coord(10.7260, 122.2687),
  'Morcillas':          _Coord(10.7980, 122.2537),
  'Nagba':              _Coord(10.7190, 122.3597),
  'Navillan':           _Coord(10.7530, 122.2397),
  'Pinamacalan':        _Coord(10.8220, 122.3037),
  'San Jose':           _Coord(10.7654, 122.3181),
  'Sibucauan':          _Coord(10.7800, 122.3447),
  'Singon':             _Coord(10.7430, 122.3117),
  'Tabat':              _Coord(10.7850, 122.3627),
  'Tagpu-an':           _Coord(10.7290, 122.2937),
  'Talento':            _Coord(10.7120, 122.3477),
  'Teniente Benito':    _Coord(10.8090, 122.2737),
  'Victoria':           _Coord(10.7600, 122.2277),
  'Zone I':             _Coord(10.7640, 122.3137),
  'Zone II':            _Coord(10.7654, 122.3181),
  'Zone III':           _Coord(10.7670, 122.3227),
};

// Mock SRS data per barangay — used when DB returns nothing
final _kMockSrs = <String, int>{
  'Adgao': 45,  'Ago': 72,  'Ambarihon': 88,  'Ayubo': 61,
  'Bacan': 55,  'Badiang': 78,  'Bagunanay': 95,  'Balicua': 42,
  'Bantayanan': 67,  'Batga': 83,  'Bato': 51,  'Bikil': 76,
  'Boloc': 110, 'Bondoc (Sto. Niño)': 58,  'Borong': 89,  'Buenavista': 64,
  'Cadabdab': 73,  'Daga-ay': 47,  'Desposorio': 91,  'Igdampog Norte': 62,
  'Igdampog Sur': 68,  'Igpaho': 85,  'Igtuble': 53,  'Ingay': 79,
  'Isauan': 44,  'Jolason': 96,  'Jona': 57,  'La-ag (San Vicente)': 82,
  'Lanag Norte': 48,  'Lanag Sur': 71,  'Male': 105, 'Mayang': 66,
  'Molina': 54,  'Morcillas': 87,  'Nagba': 93,  'Navillan': 43,
  'Pinamacalan': 75,  'San Jose': 69,  'Sibucauan': 98,  'Singon': 60,
  'Tabat': 84,  'Tagpu-an': 50,  'Talento': 77,  'Teniente Benito': 102,
  'Victoria': 46,  'Zone I': 65,  'Zone II': 70,  'Zone III': 74,
};

const _kCrops = ['All', 'Eggplant', 'Ampalaya (Bitter Gourd)', 'Okra', 'Sitaw (String Beans)', 'Squash'];
const _kSeasons = ['Current', 'Upcoming', 'Previous'];

class _Coord {
  final double lat, lng;
  const _Coord(this.lat, this.lng);
}

// ─── SRS level helpers ───────────────────────────────────────────────────────
Color _srsColor(int srs) {
  if (srs < 60)  return const Color(0xFF16A34A); // Safe — green
  if (srs < 81)  return const Color(0xFFF59E0B); // Moderate — amber
  if (srs < 101) return const Color(0xFFEF4444); // High — red
  return const Color(0xFF7C3AED);                 // Critical — purple
}

String _srsLabel(int srs) {
  if (srs < 60)  return 'Safe';
  if (srs < 81)  return 'Moderate';
  if (srs < 101) return 'High';
  return 'Critical';
}

// ─── Screen ──────────────────────────────────────────────────────────────────

class SaturationHeatmapScreen extends StatefulWidget {
  final bool adminView;
  const SaturationHeatmapScreen({super.key, this.adminView = false});

  @override
  State<SaturationHeatmapScreen> createState() => _SaturationHeatmapScreenState();
}

class _SaturationHeatmapScreenState extends State<SaturationHeatmapScreen> {
  final _mapCtrl = MapController();
  Map<String, int> _srsData = {};
  bool _loading = true;
  String _selectedCrop = 'All';
  String _selectedSeason = 'Current';
  String? _focusedBarangay;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _focusedBarangay = null; });
    try {
      final rows = await Supabase.instance.client
          .from('agrisense_saturation_scores')
          .select('barangay, srs_score, crop_type, season_name')
          .eq('municipality', 'Tubungan');

      final Map<String, int> data = {};
      for (final row in rows as List) {
        final b = row['barangay'] as String? ?? '';
        final srs = (row['srs_score'] as num?)?.toInt() ?? 0;
        if (b.isNotEmpty) data[b] = srs;
      }
      setState(() { _srsData = data.isEmpty ? Map.from(_kMockSrs) : data; _loading = false; });
    } catch (_) {
      setState(() { _srsData = Map.from(_kMockSrs); _loading = false; });
    }
  }

  Map<String, int> get _filtered {
    // In a real app, filter by crop/season from DB. For now return all.
    return _srsData;
  }

  // Summary counts
  int get _safeCount    => _filtered.values.where((s) => s < 60).length;
  int get _modCount     => _filtered.values.where((s) => s >= 60 && s < 81).length;
  int get _highCount    => _filtered.values.where((s) => s >= 81 && s < 101).length;
  int get _critCount    => _filtered.values.where((s) => s >= 101).length;

  void _focusBarangay(String name) {
    final coord = _kBarangayCoords[name];
    if (coord != null) {
      _mapCtrl.move(LatLng(coord.lat, coord.lng), 14.5);
    }
    setState(() => _focusedBarangay = name);
  }

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    return Scaffold(
      backgroundColor: const Color(0xFFF0F5F1),
      body: Column(children: [
        // ── Header ──
        Container(
          color: const Color(0xFF1B7737),
          padding: EdgeInsets.fromLTRB(16, topPad + 12, 16, 14),
          child: Column(children: [
            Row(children: [
              IconButton(
                onPressed: () => Navigator.maybePop(context),
                icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
                padding: EdgeInsets.zero, constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(color: Colors.white.withAlpha(30), borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.map_rounded, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(
                  widget.adminView ? 'SRS Heat Map — Admin View' : 'Saturation Heat Map',
                  style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700),
                ),
                const Text('Tubungan, Iloilo — Barangay SRS', style: TextStyle(color: Color(0xFFB2D9B8), fontSize: 11)),
              ])),
              IconButton(
                onPressed: _load,
                icon: const Icon(Icons.refresh_rounded, color: Colors.white, size: 20),
              ),
            ]),
            const SizedBox(height: 10),
            // Legend row
            Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
              _legendDot('< 60 — Safe',     const Color(0xFF16A34A)),
              _legendDot('61–80 — Moderate', const Color(0xFFF59E0B)),
              _legendDot('81–100 — High',   const Color(0xFFEF4444)),
              _legendDot('> 100 — Critical', const Color(0xFF7C3AED)),
            ]),
          ]),
        ),

        // ── Filters ──
        Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(children: [
            Expanded(child: _filterChips(_kCrops, _selectedCrop, (v) => setState(() { _selectedCrop = v; _focusedBarangay = null; }))),
            const SizedBox(width: 8),
            _seasonSelector(),
          ]),
        ),

        // ── Map ──
        Expanded(
          flex: 5,
          child: _loading
              ? const Center(child: CircularProgressIndicator(color: Color(0xFF1B7737)))
              : Stack(children: [
                  FlutterMap(
                    mapController: _mapCtrl,
                    options: MapOptions(
                      initialCenter: const LatLng(_kCenterLat, _kCenterLng),
                      initialZoom: 12.5,
                      onTap: (_, __) => setState(() => _focusedBarangay = null),
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.smartsackfarming.app',
                      ),
                      MarkerLayer(markers: _buildMarkers()),
                    ],
                  ),
                  // Focused barangay detail card
                  if (_focusedBarangay != null) _buildDetailCard(_focusedBarangay!),
                ]),
        ),

        // ── Summary strip ──
        _buildSummaryStrip(),
      ]),
    );
  }

  List<Marker> _buildMarkers() {
    final markers = <Marker>[];
    _filtered.forEach((barangay, srs) {
      final coord = _kBarangayCoords[barangay];
      if (coord == null) return;
      final color = _srsColor(srs);
      final isFocused = _focusedBarangay == barangay;
      markers.add(Marker(
        point: LatLng(coord.lat, coord.lng),
        width: isFocused ? 56 : 44,
        height: isFocused ? 56 : 44,
        child: GestureDetector(
          onTap: () => _focusBarangay(barangay),
          child: Stack(alignment: Alignment.center, children: [
            Container(
              width: isFocused ? 52 : 40,
              height: isFocused ? 52 : 40,
              decoration: BoxDecoration(
                color: color.withAlpha(isFocused ? 230 : 180),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: isFocused ? 3 : 2),
                boxShadow: [BoxShadow(color: color.withAlpha(120), blurRadius: isFocused ? 12 : 6)],
              ),
            ),
            Text(
              '$srs',
              style: TextStyle(
                color: Colors.white,
                fontSize: isFocused ? 11 : 9,
                fontWeight: FontWeight.w800,
              ),
            ),
          ]),
        ),
      ));
    });
    return markers;
  }

  Widget _buildDetailCard(String name) {
    final srs = _filtered[name] ?? 0;
    final color = _srsColor(srs);
    final label = _srsLabel(srs);
    return Positioned(
      bottom: 12, left: 12, right: 12,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withAlpha(80)),
          boxShadow: [BoxShadow(color: Colors.black.withAlpha(20), blurRadius: 16, offset: const Offset(0, 4))],
        ),
        child: Row(children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(color: color.withAlpha(20), shape: BoxShape.circle),
            child: Center(child: Text('$srs', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: color))),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF1B7737))),
            const SizedBox(height: 2),
            Row(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: color.withAlpha(20), borderRadius: BorderRadius.circular(6)),
                child: Text(label, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w700)),
              ),
              const SizedBox(width: 8),
              Text('SRS = $srs', style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
            ]),
            const SizedBox(height: 4),
            Text(
              _srsAdvice(srs),
              style: const TextStyle(fontSize: 11, color: Color(0xFF374151), height: 1.4),
            ),
          ])),
          IconButton(
            onPressed: () => setState(() => _focusedBarangay = null),
            icon: const Icon(Icons.close_rounded, size: 18, color: Color(0xFF9CA3AF)),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ]),
      ),
    );
  }

  Widget _buildSummaryStrip() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
        _summaryTile('Safe',     _safeCount,  const Color(0xFF16A34A)),
        _divider(),
        _summaryTile('Moderate', _modCount,   const Color(0xFFF59E0B)),
        _divider(),
        _summaryTile('High',     _highCount,  const Color(0xFFEF4444)),
        _divider(),
        _summaryTile('Critical', _critCount,  const Color(0xFF7C3AED)),
      ]),
    );
  }

  Widget _summaryTile(String label, int count, Color color) => Column(mainAxisSize: MainAxisSize.min, children: [
    Text('$count', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: color)),
    Text(label, style: const TextStyle(fontSize: 10, color: Color(0xFF6B7280))),
  ]);

  Widget _divider() => Container(width: 1, height: 32, color: const Color(0xFFE5E7EB));

  Widget _legendDot(String label, Color color) => Row(mainAxisSize: MainAxisSize.min, children: [
    Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
    const SizedBox(width: 4),
    Text(label, style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w600)),
  ]);

  Widget _filterChips(List<String> items, String selected, void Function(String) onSelect) {
    return SizedBox(
      height: 30,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 6),
        itemBuilder: (_, i) {
          final item = items[i];
          final isSel = item == selected;
          return GestureDetector(
            onTap: () => onSelect(item),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: isSel ? const Color(0xFF1B7737) : const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Center(child: Text(item, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: isSel ? Colors.white : const Color(0xFF374151)))),
            ),
          );
        },
      ),
    );
  }

  Widget _seasonSelector() {
    return Row(mainAxisSize: MainAxisSize.min, children: _kSeasons.map((s) {
      final sel = s == _selectedSeason;
      return GestureDetector(
        onTap: () => setState(() { _selectedSeason = s; _focusedBarangay = null; }),
        child: Container(
          margin: const EdgeInsets.only(left: 4),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          decoration: BoxDecoration(
            color: sel ? const Color(0xFF1B7737) : const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(s, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: sel ? Colors.white : const Color(0xFF374151))),
        ),
      );
    }).toList());
  }

  String _srsAdvice(int srs) {
    if (srs < 60) return 'Good conditions for planting. Market not saturated.';
    if (srs < 81) return 'Moderate saturation. Consider diversifying crops.';
    if (srs < 101) return 'High saturation risk. Delay planting this crop.';
    return 'Critical oversupply risk. Switch to alternative crops now.';
  }
}
