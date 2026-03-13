import 'package:hive/hive.dart';

import '../../../core/constants/app_constants.dart';
import '../../places/providers/place_provider.dart';
import '../models/manual_expense_model.dart';

class CostProvider {
  CostProvider._();
  static final CostProvider instance = CostProvider._();

  Box<ManualExpenseModel> get _box =>
      Hive.box<ManualExpenseModel>(HiveBoxes.expenses);

  // ── Read ───────────────────────────────────────────────────────────────────

  List<ManualExpenseModel> getManualExpenses(String tripId) {
    return _box.values
        .where((e) => e.tripId == tripId)
        .toList()
      ..sort((a, b) => b.fecha.compareTo(a.fecha));
  }

  // ── Write ──────────────────────────────────────────────────────────────────

  Future<void> addManualExpense(ManualExpenseModel expense) async {
    await _box.put(expense.id, expense);
  }

  Future<void> updateManualExpense(ManualExpenseModel expense) async {
    await expense.save();
  }

  Future<void> deleteManualExpense(ManualExpenseModel expense) async {
    await expense.delete();
  }

  Future<void> deleteExpensesByTrip(String tripId) async {
    for (final e in getManualExpenses(tripId)) {
      await e.delete();
    }
  }

  // ── Aggregates ─────────────────────────────────────────────────────────────

  double getTotalEstimado(String tripId) {
    final placesTotal = PlaceProvider.instance
        .getPlacesByTrip(tripId)
        .fold<double>(0, (s, p) => s + p.costoEstimado);
    final manualTotal = getManualExpenses(tripId)
        .fold<double>(0, (s, e) => s + e.montoEstimado);
    return placesTotal + manualTotal;
  }

  double getTotalReal(String tripId) {
    final placesTotal = PlaceProvider.instance
        .getPlacesByTrip(tripId)
        .fold<double>(0, (s, p) => s + p.costoReal);
    final manualTotal = getManualExpenses(tripId)
        .fold<double>(0, (s, e) => s + e.montoReal);
    return placesTotal + manualTotal;
  }

  Map<String, double> getTotalEstimadoByCategory(String tripId) {
    final result = <String, double>{};
    for (final place in PlaceProvider.instance.getPlacesByTrip(tripId)) {
      if (place.costoEstimado <= 0) continue;
      final cat = placeTypeToCategory(place.tipo);
      result[cat] = (result[cat] ?? 0) + place.costoEstimado;
    }
    for (final expense in getManualExpenses(tripId)) {
      if (expense.montoEstimado <= 0) continue;
      result[expense.categoria] =
          (result[expense.categoria] ?? 0) + expense.montoEstimado;
    }
    return result;
  }

  Map<String, double> getTotalRealByCategory(String tripId) {
    final result = <String, double>{};
    for (final place in PlaceProvider.instance.getPlacesByTrip(tripId)) {
      if (place.costoReal <= 0) continue;
      final cat = placeTypeToCategory(place.tipo);
      result[cat] = (result[cat] ?? 0) + place.costoReal;
    }
    for (final expense in getManualExpenses(tripId)) {
      if (expense.montoReal <= 0) continue;
      result[expense.categoria] =
          (result[expense.categoria] ?? 0) + expense.montoReal;
    }
    return result;
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  static String placeTypeToCategory(String tipo) => switch (tipo) {
        PlaceType.hotel => CostCategory.accommodation,
        PlaceType.restaurant => CostCategory.food,
        PlaceType.transport => CostCategory.transport,
        PlaceType.shopping => CostCategory.shopping,
        PlaceType.attraction ||
        PlaceType.entertainment ||
        PlaceType.nature =>
          CostCategory.activities,
        _ => CostCategory.other,
      };
}
