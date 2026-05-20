/// STEP-BY-STEP MODIFICATION GUIDE FOR AGRI FINANCIAL DSS SCREEN
/// 
/// This file shows exactly how to modify:
/// lib/screens/features/agri_financial_dss_screen.dart
///
/// To integrate market saturation predictions

// ────────────────────────────────────────────────────────────────────────────
// STEP 1: ADD IMPORTS AT THE TOP
// ────────────────────────────────────────────────────────────────────────────

// BEFORE (existing imports):
/*
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/agri_dss_models.dart';
import '../../services/agri_dss_service.dart';
*/

// AFTER (add these imports):
/*
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/agri_dss_models.dart';
import '../../models/planting_intention.dart';           // ← ADD THIS
import '../../services/agri_dss_service.dart';
import '../../services/planting_intention_service.dart';  // ← ADD THIS
import '../../services/enhanced_ais_service.dart';        // ← ADD THIS
import '../../widgets/market_saturation_widget.dart';     // ← ADD THIS
*/

// ────────────────────────────────────────────────────────────────────────────
// STEP 2: ADD FIELDS TO _AgriFinancialDssScreenState
// ────────────────────────────────────────────────────────────────────────────

/*
class _AgriFinancialDssScreenState extends State<AgriFinancialDssScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  final _svc = AgriDssService();
  final _plantingSvc = PlantingIntentionService();     // ← ADD THIS
  
  List<CroppingCycle> _cycles = [];
  List<SaturationPrediction> _saturations = [];         // ← ADD THIS
  bool _loading = true;
  String? _filterCommodity;
  String _farmerId = '';                                // ← ADD THIS
  String _barangay = 'Tubungan, Iloilo';              // ← ADD THIS
  String _season = 'Dry Season 2026';                 // ← ADD THIS
*/

// ────────────────────────────────────────────────────────────────────────────
// STEP 3: UPDATE initState() TO LOAD SATURATION DATA
// ────────────────────────────────────────────────────────────────────────────

/*
@override
void initState() {
  super.initState();
  _tabs = TabController(length: 5, vsync: this);  // ← CHANGE FROM 4 TO 5
  _load();
}

// Then update _load():
Future<void> _load() async {
  setState(() => _loading = true);
  
  // Load existing cycles
  final cycles = await _svc.getCycles();
  
  // ← ADD THIS: Load saturation predictions
  List<SaturationPrediction> saturations = [];
  try {
    saturations = await _plantingSvc.getSaturationSummary(
      season: _season,
      barangay: _barangay,
    );
  } catch (e) {
    print('Note: Could not load saturation data: $e');
    // Gracefully continue without saturation data
  }
  
  if (!mounted) return;
  setState(() {
    _cycles = cycles;
    _saturations = saturations;              // ← ADD THIS
    _loading = false;
  });
}
*/

// ────────────────────────────────────────────────────────────────────────────
// STEP 4: UPDATE TabBar TO ADD NEW TAB
// ────────────────────────────────────────────────────────────────────────────

/*
TabBar(
  controller: _tabs,
  labelColor: Colors.white,
  unselectedLabelColor: Colors.white54,
  indicatorColor: Colors.white,
  indicatorWeight: 3,
  isScrollable: true,
  tabAlignment: TabAlignment.start,
  tabs: const [
    Tab(text: 'Profit'),
    Tab(text: 'Alerts'),
    Tab(text: 'Cycles'),
    Tab(text: 'Markets'),
    Tab(text: 'Planting Plans'),    // ← ADD THIS
  ],
),
*/

// ────────────────────────────────────────────────────────────────────────────
// STEP 5: UPDATE TabBarView BODY - PROFIT TAB INTEGRATION
// ────────────────────────────────────────────────────────────────────────────

/*
// In TabBarView, update the Profit tab (index 0):

TabBarView(
  controller: _tabs,
  children: [
    // TAB 0: PROFIT (with saturation)
    SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ← ADD THIS: Saturation widget at top of Profit tab
          if (_saturations.isNotEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                    'Market Saturation Forecast',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                Container(
                  height: 300,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: MarketSaturationWidget(
                    farmerId: _farmerId,
                    barangay: _barangay,
                    season: _season,
                    selectedCommodity: _filterCommodity,
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          
          // Existing profit section continues...
          Text(
            'Crop Profitability',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          // ... rest of existing profit tab code
        ],
      ),
    ),
    
    // TAB 1: ALERTS (with saturation alerts)
    _buildAlertsTab(),  // See function below
    
    // TAB 2: CYCLES (unchanged)
    _buildCyclesTab(),
    
    // TAB 3: MARKETS (unchanged)
    _buildMarketsTab(),
    
    // TAB 4: PLANTING PLANS (new)
    _buildPlantingPlansTab(),  // See function below
  ],
),
*/

// ────────────────────────────────────────────────────────────────────────────
// STEP 6: ADD ALERTS TAB WITH SATURATION WARNINGS
// ────────────────────────────────────────────────────────────────────────────

/*
Widget _buildAlertsTab() {
  final alerts = <Alert>[];
  
  // ← ADD THIS: Create alerts from saturation predictions
  for (final sat in _saturations) {
    if (sat.saturationLevel == 'danger') {
      alerts.add(Alert(
        title: '⚠️ OVERSUPPLY: ${sat.cropName}',
        message: 'Severe market oversupply detected (${(sat.supplyDemandRatio * 100 - 100).toStringAsFixed(0)}% excess)',
        severity: 'critical',
        ctaLabel: 'View Analysis',
      ));
    } else if (sat.saturationLevel == 'caution') {
      alerts.add(Alert(
        title: '🔔 MARKET CAUTION: ${sat.cropName}',
        message: 'Moderate oversupply predicted. Consider cost reduction.',
        severity: 'warning',
        ctaLabel: 'View Details',
      ));
    }
  }
  
  // Add existing alerts...
  // ... original alert loading code ...
  
  return SingleChildScrollView(
    padding: const EdgeInsets.all(16),
    child: Column(
      children: [
        if (alerts.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Text('No alerts'),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: alerts.length,
            itemBuilder: (context, index) {
              final alert = alerts[index];
              return _buildAlertCard(alert);
            },
          ),
      ],
    ),
  );
}

Widget _buildAlertCard(Alert alert) {
  final isCritical = alert.severity == 'critical';
  final isWarning = alert.severity == 'warning';
  
  return Card(
    margin: const EdgeInsets.only(bottom: 12),
    color: isCritical
        ? Colors.red.shade50
        : isWarning
            ? Colors.orange.shade50
            : Colors.blue.shade50,
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                isCritical
                    ? Icons.error_rounded
                    : isWarning
                        ? Icons.warning_rounded
                        : Icons.info_rounded,
                color: isCritical
                    ? Colors.red
                    : isWarning
                        ? Colors.orange
                        : Colors.blue,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      alert.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      alert.message,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                // TODO: Navigate to analysis screen
              },
              child: Text(alert.ctaLabel ?? 'View'),
            ),
          ),
        ],
      ),
    ),
  );
}
*/

// ────────────────────────────────────────────────────────────────────────────
// STEP 7: ADD NEW PLANTING PLANS TAB
// ────────────────────────────────────────────────────────────────────────────

/*
Widget _buildPlantingPlansTab() {
  return SingleChildScrollView(
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Market Predictions Based on Farmer Plans',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        Text(
          'See what other farmers plan to plant and how it affects prices',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 24),
        
        if (_saturations.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  Icon(Icons.grass_rounded, size: 48, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text(
                    'No market data yet',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Go to "Planting Plans" to enter your crop intentions',
                    style: Theme.of(context).textTheme.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          )
        else
          SizedBox(
            height: 500,
            child: MarketSaturationWidget(
              farmerId: _farmerId,
              barangay: _barangay,
              season: _season,
            ),
          ),
      ],
    ),
  );
}
*/

// ────────────────────────────────────────────────────────────────────────────
// STEP 8: ADD HELPER TO CREATE SATURATION ALERT
// ────────────────────────────────────────────────────────────────────────────

/*
Alert _createSaturationAlert(SaturationPrediction sat) {
  final isDanger = sat.saturationLevel == 'danger';
  
  return Alert(
    title: isDanger
        ? '❌ CRITICAL: ${sat.cropName} Oversupply'
        : '⚠️ WARNING: ${sat.cropName} Market Risk',
    message: isDanger
        ? 'Heavy oversupply predicted. Price drop: ${sat.predictedPriceImpactPercent.toStringAsFixed(1)}%'
        : 'Moderate oversupply risk. Monitor market closely.',
    severity: isDanger ? 'critical' : 'warning',
    ctaLabel: 'View Analysis',
  );
}
*/

// ────────────────────────────────────────────────────────────────────────────
// STEP 9: UPDATE COMMODITY FILTER
// ────────────────────────────────────────────────────────────────────────────

/*
// When filtering commodities, also filter saturation predictions:

void _filterByCommodity(String commodity) {
  setState(() {
    _filterCommodity = commodity;
    // No need to reload - filter happens on render
  });
}

// Add getter for filtered saturations:
List<SaturationPrediction> get _filteredSaturations =>
    _filterCommodity == null
        ? _saturations
        : _saturations
            .where((s) => s.cropName.toLowerCase() == _filterCommodity!.toLowerCase())
            .toList();
*/

// ────────────────────────────────────────────────────────────────────────────
// FULL EXAMPLE: Updated Profit Tab Code
// ────────────────────────────────────────────────────────────────────────────

/*
// COMPLETE PROFIT TAB with saturation integration:

SingleChildScrollView(
  padding: const EdgeInsets.all(16),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // NEW: Saturation widget
      if (_filteredSaturations.isNotEmpty) ...[
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            'Market Saturation',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.red,
            ),
          ),
        ),
        Container(
          height: 280,
          margin: const EdgeInsets.only(bottom: 24),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.red.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: MarketSaturationWidget(
            farmerId: _farmerId,
            barangay: _barangay,
            season: _season,
            selectedCommodity: _filterCommodity,
          ),
        ),
      ],
      
      // EXISTING: Financial metrics
      Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          'Financial Metrics',
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ),
      // ... rest of existing profit tab code ...
    ],
  ),
)
*/

// ────────────────────────────────────────────────────────────────────────────
// TESTING AFTER INTEGRATION
// ────────────────────────────────────────────────────────────────────────────

/*
After making these changes, test:

1. Run Flutter app: flutter run
2. Navigate to Financial Model (AgriFinancial DSS)
3. Check Profit tab: Should show saturation widget with predictions
4. Check Alerts tab: Should include saturation risk alerts
5. Check new "Planting Plans" tab: Should show all market predictions
6. Test commodity filter: Should filter saturation data
7. Verify no compile errors: All imports should resolve

If you see errors:
- Check that files exist: lib/widgets/market_saturation_widget.dart
- Check imports match file paths exactly
- Run: flutter pub get
- Clean: flutter clean && flutter pub get
- Rebuild: flutter run
*/

// ────────────────────────────────────────────────────────────────────────────
// ALTERNATIVE: Add Saturation Banner Instead of Full Widget
// ────────────────────────────────────────────────────────────────────────────

/*
If you want a simpler integration - just a warning banner:

Widget _buildSaturationBanner() {
  if (_saturations.isEmpty) return const SizedBox.shrink();
  
  final dangerCrops = _saturations
      .where((s) => s.saturationLevel == 'danger')
      .toList();
  
  if (dangerCrops.isEmpty) return const SizedBox.shrink();
  
  return Container(
    padding: const EdgeInsets.all(12),
    margin: const EdgeInsets.only(bottom: 16),
    decoration: BoxDecoration(
      color: Colors.red.shade50,
      border: Border.all(color: Colors.red.shade300),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '⚠️ Market Risk Alert',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.red.shade700,
          ),
        ),
        const SizedBox(height: 8),
        ...dangerCrops.map((crop) => Text(
          '• ${crop.cropName}: ${(crop.supplyDemandRatio * 100 - 100).toStringAsFixed(0)}% oversupply predicted',
          style: TextStyle(color: Colors.red.shade700, fontSize: 12),
        )),
      ],
    ),
  );
}

// Then add to Profit tab:
// _buildSaturationBanner(),
*/

print('Integration guide complete!');
