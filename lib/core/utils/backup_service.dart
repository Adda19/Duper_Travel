import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../constants/app_constants.dart';
import '../../features/costs/models/manual_expense_model.dart';
import '../../features/places/models/place_model.dart';
import '../../features/trips/models/trip_model.dart';
import '../../features/wishlist/models/wishlist_place_model.dart';
import 'trip_provider.dart';

class BackupService {
  BackupService._();
  static final BackupService instance = BackupService._();

  // ── Export ─────────────────────────────────────────────────────────────────

  Future<void> exportData() async {
    final tripsBox = Hive.box<TripModel>(HiveBoxes.trips);
    final placesBox = Hive.box<PlaceModel>(HiveBoxes.places);
    final expensesBox = Hive.box<ManualExpenseModel>(HiveBoxes.expenses);
    final wishlistBox = Hive.box<WishlistPlaceModel>(HiveBoxes.wishlist);
    final settingsBox = Hive.box(HiveBoxes.settings);

    final data = <String, dynamic>{
      'version': '1.9',
      'fecha_exportacion': DateTime.now().toIso8601String(),
      'app': 'TripPlanner',
      'trips': tripsBox.values.map((t) => t.toJson()).toList(),
      'places': placesBox.values.map((p) => p.toJson()).toList(),
      'expenses': expensesBox.values.map((e) => e.toJson()).toList(),
      'wishlist': wishlistBox.values.map((w) => w.toJson()).toList(),
      'active_trip_id': settingsBox.get('active_trip_id'),
    };

    final jsonStr = const JsonEncoder.withIndent('  ').convert(data);

    final dir = await getTemporaryDirectory();
    final now = DateTime.now();
    final fileName =
        'TripPlanner_backup_${now.year}${_pad(now.month)}${_pad(now.day)}.json';
    final file = File('${dir.path}/$fileName');
    await file.writeAsString(jsonStr);

    await Share.shareXFiles(
      [XFile(file.path)],
      text: 'Backup de TripPlanner',
    );
  }

  // ── Import ─────────────────────────────────────────────────────────────────

  Future<void> importData(BuildContext context) async {
    // 1. Pick file
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );
    if (result == null || result.files.isEmpty) return;

    final path = result.files.single.path;
    if (path == null) return;

    // 2. Read & parse
    String jsonStr;
    try {
      jsonStr = await File(path).readAsString();
    } catch (_) {
      if (context.mounted) {
        _showError(context, 'No se pudo leer el archivo.');
      }
      return;
    }

    Map<String, dynamic> data;
    try {
      data = jsonDecode(jsonStr) as Map<String, dynamic>;
    } catch (_) {
      if (context.mounted) {
        _showError(context, 'El archivo JSON es inválido.');
      }
      return;
    }

    // 3. Validate
    if (data['app'] != 'TripPlanner') {
      if (context.mounted) {
        _showError(
            context, 'El archivo no es un backup válido de TripPlanner.');
      }
      return;
    }

    // 4. Confirm
    if (!context.mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Importar datos'),
        content: const Text(
          'Esto reemplazará todos tus datos actuales.\n¿Deseas continuar?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.orange),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Importar'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    // 5. Restore
    try {
      await _restoreData(data);
    } catch (e) {
      if (context.mounted) {
        _showError(context, 'Error al restaurar: $e');
      }
      return;
    }

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Datos restaurados correctamente'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // ── Internal ───────────────────────────────────────────────────────────────

  Future<void> _restoreData(Map<String, dynamic> data) async {
    final tripsBox = Hive.box<TripModel>(HiveBoxes.trips);
    final placesBox = Hive.box<PlaceModel>(HiveBoxes.places);
    final expensesBox = Hive.box<ManualExpenseModel>(HiveBoxes.expenses);
    final wishlistBox = Hive.box<WishlistPlaceModel>(HiveBoxes.wishlist);
    final settingsBox = Hive.box(HiveBoxes.settings);

    // Clear
    await tripsBox.clear();
    await placesBox.clear();
    await expensesBox.clear();
    await wishlistBox.clear();

    // Trips
    for (final raw in (data['trips'] as List? ?? [])) {
      final t = TripModel.fromJson(raw as Map<String, dynamic>);
      await tripsBox.put(t.id, t);
    }

    // Places
    for (final raw in (data['places'] as List? ?? [])) {
      final p = PlaceModel.fromJson(raw as Map<String, dynamic>);
      await placesBox.put(p.id, p);
    }

    // Expenses
    for (final raw in (data['expenses'] as List? ?? [])) {
      final e = ManualExpenseModel.fromJson(raw as Map<String, dynamic>);
      await expensesBox.put(e.id, e);
    }

    // Wishlist
    for (final raw in (data['wishlist'] as List? ?? [])) {
      final w = WishlistPlaceModel.fromJson(raw as Map<String, dynamic>);
      await wishlistBox.put(w.id, w);
    }

    // Active trip
    final activeTripId = data['active_trip_id'] as String?;
    if (activeTripId != null) {
      await settingsBox.put('active_trip_id', activeTripId);
      TripProvider.instance.activeTrip.value = tripsBox.get(activeTripId);
    } else {
      await settingsBox.delete('active_trip_id');
      TripProvider.instance.activeTrip.value = null;
    }
  }

  void _showError(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String _pad(int n) => n.toString().padLeft(2, '0');
}
