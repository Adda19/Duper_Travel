import 'package:flutter/material.dart';

// ── Place types ───────────────────────────────────────────────────────────────
class PlaceType {
  static const String hotel = 'hotel';
  static const String restaurant = 'restaurant';
  static const String attraction = 'attraction';
  static const String transport = 'transport';
  static const String shopping = 'shopping';
  static const String entertainment = 'entertainment';
  static const String nature = 'nature';
  static const String other = 'other';

  static const List<String> all = [
    hotel,
    restaurant,
    attraction,
    transport,
    shopping,
    entertainment,
    nature,
    other,
  ];

  static String label(String type) => switch (type) {
        hotel => 'Hotel',
        restaurant => 'Restaurante',
        attraction => 'Atracción',
        transport => 'Transporte',
        shopping => 'Compras',
        entertainment => 'Entretenimiento',
        nature => 'Naturaleza',
        _ => 'Otro',
      };

  static IconData icon(String type) => switch (type) {
        hotel => Icons.hotel,
        restaurant => Icons.restaurant,
        attraction => Icons.photo_camera,
        transport => Icons.directions_transit,
        shopping => Icons.shopping_bag,
        entertainment => Icons.theater_comedy,
        nature => Icons.park,
        _ => Icons.place,
      };
}

// ── Color per place type ───────────────────────────────────────────────────────
class PlaceTypeColor {
  static const Map<String, Color> colors = {
    PlaceType.hotel: Color(0xFF1565C0),
    PlaceType.restaurant: Color(0xFFE53935),
    PlaceType.attraction: Color(0xFF7B1FA2),
    PlaceType.transport: Color(0xFF00838F),
    PlaceType.shopping: Color(0xFFFF6D00),
    PlaceType.entertainment: Color(0xFFFDD835),
    PlaceType.nature: Color(0xFF2E7D32),
    PlaceType.other: Color(0xFF757575),
  };

  static Color of(String type) =>
      colors[type] ?? const Color(0xFF757575);
}

// ── Cost categories ────────────────────────────────────────────────────────────
class CostCategory {
  static const String accommodation = 'accommodation';
  static const String food = 'food';
  static const String transport = 'transport';
  static const String activities = 'activities';
  static const String shopping = 'shopping';
  static const String health = 'health';
  static const String other = 'other';

  static const List<String> all = [
    accommodation,
    food,
    transport,
    activities,
    shopping,
    health,
    other,
  ];

  static String label(String cat) => switch (cat) {
        accommodation => 'Alojamiento',
        food => 'Comida',
        transport => 'Transporte',
        activities => 'Actividades',
        shopping => 'Compras',
        health => 'Salud',
        _ => 'Otro',
      };

  static IconData icon(String cat) => switch (cat) {
        accommodation => Icons.hotel,
        food => Icons.restaurant,
        transport => Icons.directions_car,
        activities => Icons.local_activity,
        shopping => Icons.shopping_cart,
        health => Icons.medical_services,
        _ => Icons.receipt,
      };

  static Color color(String cat) => switch (cat) {
        accommodation => const Color(0xFF1565C0),
        food => const Color(0xFFE53935),
        transport => const Color(0xFF00838F),
        activities => const Color(0xFF7B1FA2),
        shopping => const Color(0xFFFF6D00),
        health => const Color(0xFF2E7D32),
        _ => const Color(0xFF757575),
      };
}

// ── Place status ───────────────────────────────────────────────────────────────
class PlaceStatus {
  static const String pending = 'pending';
  static const String visited = 'visited';
  static const String skipped = 'skipped';

  static String label(String status) => switch (status) {
        visited => 'Visitado',
        skipped => 'Omitido',
        _ => 'Pendiente',
      };
}

// ── Supported currencies ───────────────────────────────────────────────────────
class AppCurrencies {
  static const List<String> all = [
    'USD', 'EUR', 'MXN', 'ARS', 'COP',
    'CLP', 'PEN', 'BRL', 'GBP', 'JPY',
  ];
}

// ── Wishlist status ────────────────────────────────────────────────────────────
class WishlistStatus {
  static const String pending = 'pending';
  static const String visited = 'visited';

  static String label(String status) =>
      status == visited ? 'Visitado' : 'Pendiente';
}

// ── Wishlist sources ───────────────────────────────────────────────────────────
class WishlistSource {
  static const String instagram = 'Instagram';
  static const String tiktok = 'TikTok';
  static const String recommendation = 'Recomendación';
  static const String web = 'Web';
  static const String other = 'Otro';

  static const List<String> all = [
    instagram,
    tiktok,
    recommendation,
    web,
    other,
  ];

  static IconData icon(String source) => switch (source) {
        instagram => Icons.camera_alt_outlined,
        tiktok => Icons.music_note_outlined,
        recommendation => Icons.people_outlined,
        web => Icons.language_outlined,
        _ => Icons.help_outline,
      };
}

// ── Transport types ────────────────────────────────────────────────────────────
class TransportType {
  static const String vuelo = 'vuelo';
  static const String carro = 'carro';
  static const String bus = 'bus';
  static const String tren = 'tren';
  static const String barco = 'barco';
  static const String otro = 'otro';

  static const List<String> all = [vuelo, carro, bus, tren, barco, otro];

  static String label(String type) => switch (type) {
        vuelo => 'Vuelo',
        carro => 'Carro',
        bus => 'Bus',
        tren => 'Tren',
        barco => 'Barco',
        _ => 'Otro',
      };

  static String emoji(String type) => switch (type) {
        vuelo => '✈️',
        carro => '🚗',
        bus => '🚌',
        tren => '🚂',
        barco => '🚢',
        _ => '🧳',
      };

  static String countdownText(String type) => switch (type) {
        vuelo => '¡Tu vuelo sale en',
        carro => '¡Arrancas en',
        bus => '¡Tu bus sale en',
        tren => '¡Tu tren sale en',
        barco => '¡Zarpas en',
        _ => '¡Tu aventura comienza en',
      };
}

// ── Hive box names ─────────────────────────────────────────────────────────────
class HiveBoxes {
  static const String trips = 'trips';
  static const String places = 'places';
  static const String settings = 'settings';
  static const String expenses = 'expenses';
  static const String wishlist = 'wishlist';
}

// ── Hive type IDs ──────────────────────────────────────────────────────────────
class HiveTypeIds {
  static const int trip = 0;
  static const int place = 1;
  static const int manualExpense = 2;
  static const int wishlistPlace = 3;
}
