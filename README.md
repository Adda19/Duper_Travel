# Dupper — Planificador de viajes personal

Dupper es una aplicación móvil Flutter para Android que te ayuda a organizar tus viajes de manera completa: planifica itinerarios día a día, visualiza tus lugares en un mapa interactivo, controla los costos del viaje y guarda en una lista personal los lugares que quieres visitar algún día.

---

## Qué hace la aplicación

### Mapa interactivo
- Visualiza todos los lugares de tu viaje activo sobre un mapa OpenStreetMap.
- Filtra por **tipo de lugar** (hotel, restaurante, atracción, etc.) y por **día del viaje**.
- Muestra la fecha real de cada día al seleccionarlo (ej. "Día 1 · Lunes 3 de Marzo").
- **Modo ruta**: selecciona varios lugares y ábrelos directamente en Google Maps como ruta con paradas.
- Toggle **Ver Wishlist**: superpone tus lugares por visitar en el mismo mapa (marcador de corazón gris = pendiente, verde = visitado).

### Itinerario
- Vista por días expandibles con cabecera que muestra: fecha, costo total, tiempo total y barra de progreso visitados/total.
- Cada lugar muestra su estado (pendiente / visitado / omitido), calificación con estrellas y costo.

### Agregar viaje
- Crea viajes con nombre, destinos múltiples (autocompletado Nominatim/OSM), fechas, número de personas, moneda y presupuesto total.

### Costos
- Resumen de gastos del viaje activo: costo estimado vs real, desglosado por categoría.
- Registro de gastos manuales adicionales.

### Viajes
- Lista de todos tus viajes con tarjeta de resumen.
- Selecciona el viaje activo que se muestra en el mapa e itinerario.

### Wishlist — Por Visitar
- Lista personal de lugares que quieres visitar algún día, independiente de cualquier viaje.
- Guarda la **fuente** del descubrimiento: Instagram, TikTok, Recomendación, Web, Otro.
- Filtros por estado (Pendiente / Visitado) y tipo de lugar. Búsqueda por nombre o ciudad.
- Detalle completo: fotos, links, comentarios, mapa opcional.
- Botón **Marcar como visitado** con fecha automática.
- Botón **Mover a viaje**: copia el lugar como ítem de planificación en cualquier viaje existente.

---

## Requisitos previos

| Herramienta | Versión mínima |
|---|---|
| Flutter SDK | 3.x (probado con 3.2.3) |
| Dart SDK | ≥ 3.2.3 |
| Android SDK | compileSdk 34 / minSdk 21 (Android 5.0+) |
| Java | 8+ (incluido con Android Studio) |
| Android Studio o VS Code | Con plugin Flutter instalado |

---

## Instalación y primer arranque

### 1. Clonar el repositorio

```bash
git clone https://github.com/TU_USUARIO/dupper.git
cd dupper
```

### 2. Instalar dependencias

```bash
flutter pub get
```

### 3. Verificar el entorno

```bash
flutter doctor
```

Asegúrate de que **Android toolchain** y el dispositivo/emulador estén en verde.

### 4. Ejecutar en modo debug

```bash
flutter run
```

### 5. Generar APK de release

```bash
flutter build apk --release
```

El APK queda en:
```
build/app/outputs/flutter-apk/app-release.apk
```

---

## Cosas a tener en cuenta

### Datos locales — sin backend
- Todos los datos se almacenan **localmente** en el dispositivo usando [Hive](https://pub.dev/packages/hive).
- No hay backend, cuenta de usuario ni sincronización en la nube.
- Al desinstalar la app **se pierden todos los datos**. Haz copias manuales si es necesario.

### Mapas y geocodificación — requieren internet
- Los tiles del mapa vienen de **OpenStreetMap** — necesitan conexión.
- La búsqueda de destinos y ciudades usa la API **Nominatim** (gratuita, con límite de velocidad).
- Sin internet el mapa se ve en blanco y la búsqueda no funciona, pero los datos locales siguen accesibles.

### Permisos de Android requeridos
| Permiso | Para qué |
|---|---|
| `ACCESS_FINE_LOCATION` | Centrar el mapa en tu posición actual |
| `ACCESS_COARSE_LOCATION` | Ubicación aproximada de respaldo |
| `CAMERA` | Tomar fotos de lugares desde la cámara |
| `READ_EXTERNAL_STORAGE` | Galería en Android ≤ 12 |
| `INTERNET` | Mapas y búsquedas |

### Google Maps (rutas y direcciones)
- "Cómo llegar" y el modo ruta abren **Google Maps** como app externa.
- El bloque `<queries>` en `AndroidManifest.xml` declara los intents necesarios para Android 11+.
- Si Google Maps no está instalado en el dispositivo, el botón no funcionará.

### Firma del APK
- El APK de release actual usa la **debug key** de Flutter.
- Para publicar en Google Play es necesario crear una keystore de producción y configurarla en `android/app/build.gradle` bajo `signingConfigs`.

### Adaptadores Hive escritos manualmente
- Los archivos `*.g.dart` **no se generan** con `build_runner` — están escritos a mano.
- Si se agregan campos nuevos a un modelo, hay que actualizar el `.g.dart` correspondiente: incrementar el contador en `writeByte(N)` y agregar el nuevo campo tanto en `read()` como en `write()`.
- Los `typeId` de Hive están fijos: `0` = TripModel, `1` = PlaceModel, `2` = ManualExpenseModel, `3` = WishlistPlaceModel.

### Versión de intl — no actualizar
- El proyecto usa `intl: ^0.18.1`. **No actualizar a 0.19.x** porque `flutter_localizations` lo fija en 0.18.x y genera conflictos de dependencias.

---

## Estructura del proyecto

```
lib/
├── app.dart                          # MaterialApp + NavigationBar (6 tabs)
├── main.dart                         # Inicialización Hive + registro de adapters
├── core/
│   ├── constants/app_constants.dart  # PlaceType, PlaceStatus, WishlistStatus, HiveBoxes…
│   ├── theme/app_theme.dart          # Temas claro y oscuro
│   └── utils/trip_provider.dart      # Estado global del viaje activo (ValueNotifier)
└── features/
    ├── map/                          # Mapa interactivo, filtros, modo ruta, wishlist toggle
    ├── itinerary/                    # Itinerario por días expandibles
    ├── places/                       # PlaceModel, CRUD, formulario, detalle con fotos
    ├── trips/                        # TripModel, lista de viajes, formulario con typeahead
    ├── costs/                        # Costos estimados vs reales y gastos manuales
    └── wishlist/                     # Lista de deseos: modelo, provider, pantallas
```

---

## Dependencias principales

| Paquete | Uso |
|---|---|
| `hive` + `hive_flutter` | Base de datos local |
| `flutter_map` | Mapa interactivo con tiles OSM |
| `latlong2` | Coordenadas geográficas |
| `geolocator` | Ubicación del dispositivo |
| `image_picker` | Fotos desde cámara o galería |
| `url_launcher` | Abrir Google Maps externo |
| `flutter_typeahead` | Autocompletado de destinos y ciudades |
| `http` | Llamadas a la API Nominatim |
| `intl` | Formato de fechas en español |
| `path_provider` | Directorio de documentos para guardar fotos |

---

## Versión actual

**v1.6.0** (versionCode 6) — Flutter 3.x / Android minSdk 21
