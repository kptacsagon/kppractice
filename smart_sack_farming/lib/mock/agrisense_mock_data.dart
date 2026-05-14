import '../models/agrisense_alert.dart';
import '../models/agrisense_farmer_profile.dart';
import '../models/agrisense_market_price.dart';
import '../models/agrisense_pest_report.dart';
import '../models/agrisense_price_alert.dart';
import '../models/agrisense_program_enrollment.dart';
import '../models/agrisense_saturation_score.dart';

class AgrisenseMockData {
  AgrisenseMockData._();

  static final AgrisenseFarmerProfile profile = AgrisenseFarmerProfile(
    id: 'mock-farmer-001',
    userId: 'mock-user-001',
    rsbsaNumber: '040-2026-001-000123',
    fullName: 'Juan Dela Cruz',
    age: 42,
    sex: 'Male',
    civilStatus: 'Married',
    contactNumber: '09171234567',
    address: 'Purok 3, Brgy. Maligaya',
    barangay: 'Maligaya',
    municipality: 'San Jose',
    province: 'Quezon',
    farmingExperienceYears: 15,
    irrigationAccess: 'Irrigation Canal',
    farmingMethod: 'Conventional',
    equipmentOwned: ['Hand Tractor', 'Sprayer'],
    primaryCrops: ['Sweet Corn', 'Eggplant'],
    preferredCrops: ['Chili', 'Tomato'],
    farmOwnershipType: 'Owner',
    marketAccess: 'Local Market',
    verificationStatus: 'Verified',
  );

  static final List<AgrisenseAlert> alerts = [
    AgrisenseAlert(
      id: 'alert-001',
      farmerId: 'mock-farmer-001',
      module: 'WCRA',
      alertType: 'typhoon_warning',
      severity: 'critical',
      title: 'Typhoon Signal 1 Warning',
      message: 'PAGASA has issued Signal 1 for your area. Heavy rainfall expected in 48 hours. Protect your crops today.',
      ctaLabel: 'View Weather Advisory',
      ctaAction: 'open_wcra',
      triggeredAt: DateTime.now().subtract(const Duration(hours: 2)),
    ),
    AgrisenseAlert(
      id: 'alert-002',
      farmerId: 'mock-farmer-001',
      module: 'CSI',
      alertType: 'saturation_warning',
      severity: 'warning',
      title: 'Sweet Corn Saturation Warning',
      message: 'SRS is at 78 — supply is approaching market capacity. Consider diversifying to Chili or Tomato.',
      ctaLabel: 'View Saturation Map',
      ctaAction: 'open_csi',
      triggeredAt: DateTime.now().subtract(const Duration(hours: 5)),
    ),
    AgrisenseAlert(
      id: 'alert-003',
      farmerId: 'mock-farmer-001',
      module: 'PDEW',
      alertType: 'pest_alert',
      severity: 'warning',
      title: 'Fall Armyworm Detected Nearby',
      message: 'Tier 2 alert: 4 reports of Fall Armyworm in adjacent barangays. Inspect your corn fields now.',
      ctaLabel: 'View Pest Alerts',
      ctaAction: 'open_pdew',
      triggeredAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
  ];

  static final List<AgrisenseSaturationScore> saturationScores = [
    AgrisenseSaturationScore(
      id: 'score-001',
      municipality: 'San Jose',
      cropType: 'Sweet Corn',
      seasonName: 'Wet Season 2026',
      srsScore: 78,
      projectedSupplyMt: 312,
      projectedDemandMt: 400,
      priceForecastMin: 16.0,
      priceForecastMax: 20.0,
      lastUpdated: DateTime.now().subtract(const Duration(days: 1)),
    ),
    AgrisenseSaturationScore(
      id: 'score-002',
      municipality: 'San Jose',
      cropType: 'Eggplant',
      seasonName: 'Wet Season 2026',
      srsScore: 52,
      projectedSupplyMt: 156,
      projectedDemandMt: 300,
      priceForecastMin: 32.0,
      priceForecastMax: 40.0,
      lastUpdated: DateTime.now().subtract(const Duration(days: 1)),
    ),
    AgrisenseSaturationScore(
      id: 'score-003',
      municipality: 'San Jose',
      cropType: 'Rice',
      seasonName: 'Wet Season 2026',
      srsScore: 91,
      projectedSupplyMt: 820,
      projectedDemandMt: 900,
      priceForecastMin: 18.0,
      priceForecastMax: 22.0,
      lastUpdated: DateTime.now().subtract(const Duration(days: 2)),
    ),
    AgrisenseSaturationScore(
      id: 'score-004',
      municipality: 'San Jose',
      cropType: 'Chili',
      seasonName: 'Wet Season 2026',
      srsScore: 44,
      projectedSupplyMt: 88,
      projectedDemandMt: 200,
      priceForecastMin: 70.0,
      priceForecastMax: 90.0,
      lastUpdated: DateTime.now().subtract(const Duration(days: 1)),
    ),
    AgrisenseSaturationScore(
      id: 'score-005',
      municipality: 'San Jose',
      cropType: 'Tomato',
      seasonName: 'Wet Season 2026',
      srsScore: 60,
      projectedSupplyMt: 180,
      projectedDemandMt: 300,
      priceForecastMin: 38.0,
      priceForecastMax: 48.0,
      lastUpdated: DateTime.now().subtract(const Duration(days: 3)),
    ),
  ];

  static final List<AgrisensePestReport> pestReports = [
    AgrisensePestReport(
      id: 'pest-001',
      farmerId: 'mock-farmer-002',
      municipality: 'San Jose',
      cropType: 'Corn',
      pestType: 'Fall Armyworm (FAW)',
      severity: 'Moderate',
      status: 'Active',
      reportedAt: DateTime.now().subtract(const Duration(hours: 6)),
    ),
    AgrisensePestReport(
      id: 'pest-002',
      farmerId: 'mock-farmer-003',
      municipality: 'San Jose',
      cropType: 'Rice',
      pestType: 'Brown Planthopper (BPH)',
      severity: 'Severe',
      status: 'Active',
      reportedAt: DateTime.now().subtract(const Duration(hours: 14)),
    ),
    AgrisensePestReport(
      id: 'pest-003',
      farmerId: 'mock-farmer-004',
      municipality: 'San Jose',
      cropType: 'Eggplant',
      pestType: 'Fruit Borer',
      severity: 'Mild',
      status: 'Pending',
      reportedAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
  ];

  static final List<AgrisenseMarketPrice> marketPrices = [
    AgrisenseMarketPrice(
      id: 'price-001',
      municipality: 'San Jose',
      cropType: 'Sweet Corn',
      pricePerKg: 18.50,
      recordedDate: DateTime.now(),
    ),
    AgrisenseMarketPrice(
      id: 'price-002',
      municipality: 'San Jose',
      cropType: 'Eggplant',
      pricePerKg: 35.00,
      recordedDate: DateTime.now(),
    ),
    AgrisenseMarketPrice(
      id: 'price-003',
      municipality: 'San Jose',
      cropType: 'Chili',
      pricePerKg: 75.00,
      recordedDate: DateTime.now(),
    ),
    AgrisenseMarketPrice(
      id: 'price-004',
      municipality: 'San Jose',
      cropType: 'Rice (Dry)',
      pricePerKg: 22.00,
      recordedDate: DateTime.now(),
    ),
    AgrisenseMarketPrice(
      id: 'price-005',
      municipality: 'San Jose',
      cropType: 'Tomato',
      pricePerKg: 42.00,
      recordedDate: DateTime.now(),
    ),
    AgrisenseMarketPrice(
      id: 'price-006',
      municipality: 'San Jose',
      cropType: 'Bitter Gourd',
      pricePerKg: 28.00,
      recordedDate: DateTime.now(),
    ),
  ];

  static final List<AgrisensePriceAlert> priceAlerts = [
    AgrisensePriceAlert(
      id: 'palert-001',
      farmerId: 'mock-farmer-001',
      cropType: 'Sweet Corn',
      targetPrice: 22.00,
      createdAt: DateTime.now().subtract(const Duration(days: 3)),
    ),
    AgrisensePriceAlert(
      id: 'palert-002',
      farmerId: 'mock-farmer-001',
      cropType: 'Eggplant',
      targetPrice: 40.00,
      createdAt: DateTime.now().subtract(const Duration(days: 5)),
    ),
  ];

  static final List<AgrisenseProgramEnrollment> programEnrollments = [
    AgrisenseProgramEnrollment(
      id: 'enroll-001',
      farmerId: 'mock-farmer-001',
      programName: 'RCEF — Rice Competitiveness Enhancement Fund',
      status: 'Active',
      enrolledDate: DateTime(2026, 3, 10),
      expiryDate: DateTime(2026, 12, 31),
    ),
    AgrisenseProgramEnrollment(
      id: 'enroll-002',
      farmerId: 'mock-farmer-001',
      programName: 'PUNLA — Puno ng Pagkain at Kabuhayan',
      status: 'Active',
      enrolledDate: DateTime(2026, 4, 1),
    ),
    AgrisenseProgramEnrollment(
      id: 'enroll-003',
      farmerId: 'mock-farmer-001',
      programName: 'PCFC Micro-Agri Loan',
      status: 'Pending',
      enrolledDate: DateTime(2026, 5, 5),
    ),
  ];
}
