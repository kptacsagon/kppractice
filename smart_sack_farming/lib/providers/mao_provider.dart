import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/planting_record.dart';
import '../services/market_service.dart';

final upcomingPlantingsProvider = FutureProvider<List<PlantingRecord>>((ref) async {
  return MarketService.fetchUpcomingPlantings();
});
