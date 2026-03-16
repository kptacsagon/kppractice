import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/market_endorsement.dart';
import '../services/market_service.dart';

final farmerEndorsementsProvider = FutureProvider.family<List<MarketEndorsement>, String>((ref, farmerId) async {
  return MarketService.fetchEndorsementsForFarmer(farmerId);
});

final openEndorsementsProvider = FutureProvider<List<MarketEndorsement>>((ref) async {
  return MarketService.fetchOpenEndorsements();
});
