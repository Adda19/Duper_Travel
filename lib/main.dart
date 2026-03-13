import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';

import 'app.dart';
import 'core/constants/app_constants.dart';
import 'core/utils/trip_provider.dart';
import 'features/trips/models/trip_model.dart';
import 'features/places/models/place_model.dart';
import 'features/costs/models/manual_expense_model.dart';
import 'features/wishlist/models/wishlist_place_model.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive with the app documents directory
  final appDocDir = await getApplicationDocumentsDirectory();
  await Hive.initFlutter(appDocDir.path);

  // Register Hive adapters
  Hive.registerAdapter(TripModelAdapter());
  Hive.registerAdapter(PlaceModelAdapter());
  Hive.registerAdapter(ManualExpenseModelAdapter());
  Hive.registerAdapter(WishlistPlaceModelAdapter());

  // Open Hive boxes
  await Hive.openBox<TripModel>(HiveBoxes.trips);
  await Hive.openBox<PlaceModel>(HiveBoxes.places);
  await Hive.openBox<ManualExpenseModel>(HiveBoxes.expenses);
  await Hive.openBox<WishlistPlaceModel>(HiveBoxes.wishlist);
  await Hive.openBox(HiveBoxes.settings);

  // Init global provider
  await TripProvider.instance.init();

  runApp(const DupperApp());
}
