import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/utils/trip_provider.dart';
import '../models/place_model.dart';
import '../providers/place_provider.dart';
import 'add_place_screen.dart';

const _linkSep = ':::';

class PlaceDetailScreen extends StatefulWidget {
  final PlaceModel place;

  const PlaceDetailScreen({super.key, required this.place});

  @override
  State<PlaceDetailScreen> createState() => _PlaceDetailScreenState();
}

class _PlaceDetailScreenState extends State<PlaceDetailScreen> {
  late PlaceModel _place;
  final _picker = ImagePicker();
  bool _addingPhoto = false;

  @override
  void initState() {
    super.initState();
    _place = widget.place;
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final typeColor = PlaceTypeColor.of(_place.tipo);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // ── SliverAppBar with type color ──────────────────────────────────
          SliverAppBar(
            expandedHeight: 180,
            pinned: true,
            backgroundColor: typeColor,
            foregroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                _place.nombre,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  shadows: [Shadow(blurRadius: 4, color: Colors.black38)],
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [typeColor, typeColor.withAlpha(200)],
                  ),
                ),
                child: Center(
                  child: Icon(
                    PlaceType.icon(_place.tipo),
                    size: 72,
                    color: Colors.white.withAlpha(180),
                  ),
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                tooltip: 'Editar',
                onPressed: _openEdit,
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline),
                tooltip: 'Eliminar',
                onPressed: _confirmDelete,
              ),
            ],
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Status & type badges ──────────────────────────────────
                  Row(
                    children: [
                      _TypeBadge(tipo: _place.tipo),
                      const SizedBox(width: 8),
                      _StatusBadge(estado: _place.estado),
                      const Spacer(),
                      if (_place.calificacion > 0)
                        _StarDisplay(value: _place.calificacion),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // ── Info grid ─────────────────────────────────────────────
                  _InfoCard(children: [
                    _InfoRow(
                      icon: Icons.calendar_today,
                      label: 'Día',
                      value: 'Día ${_place.dia}',
                    ),
                    if (_place.horario.isNotEmpty)
                      _InfoRow(
                        icon: Icons.access_time,
                        label: 'Horario',
                        value: _place.horario,
                      ),
                    _InfoRow(
                      icon: Icons.schedule,
                      label: 'Tiempo estimado',
                      value: _formatTime(_place.tiempoEstimadoMin),
                    ),
                    if (_place.costoEstimado > 0)
                      _InfoRow(
                        icon: Icons.attach_money,
                        label: 'Costo estimado',
                        value:
                            '${_moneda()} ${_place.costoEstimado.toStringAsFixed(0)}',
                      ),
                    if (_place.costoReal > 0)
                      _InfoRow(
                        icon: Icons.receipt,
                        label: 'Costo real',
                        value:
                            '${_moneda()} ${_place.costoReal.toStringAsFixed(0)}',
                      ),
                  ]),
                  const SizedBox(height: 16),

                  // ── Location ──────────────────────────────────────────────
                  if (_place.latitud != 0 && _place.longitud != 0) ...[
                    const _SectionLabel('Ubicación'),
                    const SizedBox(height: 8),
                    _LocationCard(
                      lat: _place.latitud,
                      lng: _place.longitud,
                      onOpenMaps: _openGoogleMaps,
                    ),
                    const SizedBox(height: 16),
                  ],

                  // ── Tags ──────────────────────────────────────────────────
                  if (_place.tags.isNotEmpty) ...[
                    const _SectionLabel('Tags'),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: _place.tags
                          .map((t) => Chip(
                                label: Text(t),
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                                labelStyle: const TextStyle(fontSize: 12),
                                padding: EdgeInsets.zero,
                              ))
                          .toList(),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // ── Comentarios ───────────────────────────────────────────
                  if (_place.comentarios.isNotEmpty) ...[
                    const _SectionLabel('Comentarios'),
                    const SizedBox(height: 8),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Text(
                          _place.comentarios,
                          style: const TextStyle(fontSize: 14, height: 1.5),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // ── Links ─────────────────────────────────────────────────
                  if (_place.links.isNotEmpty) ...[
                    const _SectionLabel('Links'),
                    const SizedBox(height: 8),
                    ..._place.links.map((raw) {
                      final parts = raw.split(_linkSep);
                      final label =
                          parts.length > 1 ? parts[0] : 'Ver enlace';
                      final url =
                          parts.length > 1 ? parts[1] : parts[0];
                      return _LinkTile(label: label, url: url);
                    }),
                    const SizedBox(height: 16),
                  ],

                  // ── Fotos ─────────────────────────────────────────────────
                  Row(
                    children: [
                      const _SectionLabel('Fotos'),
                      const Spacer(),
                      TextButton.icon(
                        onPressed: _addingPhoto ? null : _addPhoto,
                        icon: _addingPhoto
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2),
                              )
                            : const Icon(Icons.add_a_photo_outlined),
                        label: const Text('Agregar'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (_place.fotos.isEmpty)
                    _EmptyPhotos(onAdd: _addPhoto)
                  else
                    _PhotoGallery(
                      paths: _place.fotos,
                      onDelete: _deletePhoto,
                    ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  String _moneda() =>
      TripProvider.instance.getActiveTrip()?.moneda ?? 'USD';

  String _formatTime(int minutes) {
    final h = minutes ~/ 60;
    final m = minutes % 60;
    if (h == 0) return '${m}min';
    if (m == 0) return '${h}h';
    return '${h}h ${m}min';
  }

  // ── Actions ────────────────────────────────────────────────────────────────

  void _openEdit() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddPlaceScreen(existing: _place),
      ),
    );
    // Refresh place after edit
    final updated = PlaceProvider.instance.getById(_place.id);
    if (updated != null && mounted) {
      setState(() => _place = updated);
    }
  }

  Future<void> _confirmDelete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar lugar'),
        content:
            Text('¿Eliminar "${_place.nombre}"? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirm == true && mounted) {
      await PlaceProvider.instance.deletePlace(_place);
      if (mounted) Navigator.of(context).pop();
    }
  }

  Future<void> _openGoogleMaps() async {
    final lat = _place.latitud;
    final lng = _place.longitud;
    final name = Uri.encodeComponent(_place.nombre);
    final uri = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=$lat,$lng&query_place_id=$name');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo abrir Google Maps')),
      );
    }
  }

  Future<void> _addPhoto() async {
    final choice = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Tomar foto'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Elegir de galería'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );

    if (choice == null || !mounted) return;
    setState(() => _addingPhoto = true);

    try {
      final xFile = await _picker.pickImage(
        source: choice,
        imageQuality: 85,
        maxWidth: 1920,
      );

      if (xFile == null) {
        setState(() => _addingPhoto = false);
        return;
      }

      final savedPath = await _savePhoto(xFile.path);
      _place.fotos.add(savedPath);
      await PlaceProvider.instance.updatePlace(_place);

      if (mounted) setState(() => _addingPhoto = false);
    } catch (e) {
      if (mounted) {
        setState(() => _addingPhoto = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar foto: $e')),
        );
      }
    }
  }

  Future<String> _savePhoto(String sourcePath) async {
    final docsDir = await getApplicationDocumentsDirectory();
    final photosDir = Directory('${docsDir.path}/dupper_photos');
    await photosDir.create(recursive: true);

    // Naming: {TripName}_{PlaceName}_{index}.jpg
    final trip = TripProvider.instance.getActiveTrip();
    final tripName = _sanitize(trip?.nombre ?? 'viaje');
    final placeName = _sanitize(_place.nombre);
    final index = _place.fotos.length;
    final fileName = '${tripName}_${placeName}_$index.jpg';
    final dest = File('${photosDir.path}/$fileName');

    await File(sourcePath).copy(dest.path);
    return dest.path;
  }

  String _sanitize(String input) {
    return input
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .substring(0, input.length.clamp(0, 20));
  }

  Future<void> _deletePhoto(int index) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar foto'),
        content: const Text('¿Eliminar esta foto?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;

    final path = _place.fotos[index];
    _place.fotos.removeAt(index);
    await PlaceProvider.instance.updatePlace(_place);
    setState(() {});

    // Delete file from disk (best effort)
    try {
      final file = File(path);
      if (await file.exists()) await file.delete();
    } catch (_) {}
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.4,
          ),
    );
  }
}

class _TypeBadge extends StatelessWidget {
  final String tipo;
  const _TypeBadge({required this.tipo});

  @override
  Widget build(BuildContext context) {
    final color = PlaceTypeColor.of(tipo);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withAlpha(80)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(PlaceType.icon(tipo), size: 14, color: color),
          const SizedBox(width: 4),
          Text(PlaceType.label(tipo),
              style: TextStyle(
                  fontSize: 12, color: color, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String estado;
  const _StatusBadge({required this.estado});

  static const _colors = {
    PlaceStatus.pending: Color(0xFF757575),
    PlaceStatus.visited: Color(0xFF2E7D32),
    'confirmed': Color(0xFF1565C0),
    PlaceStatus.skipped: Color(0xFFBF360C),
  };

  @override
  Widget build(BuildContext context) {
    final color = _colors[estado] ?? const Color(0xFF757575);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withAlpha(80)),
      ),
      child: Text(
        PlaceStatus.label(estado == 'confirmed' ? 'confirmed' : estado),
        style: TextStyle(
            fontSize: 12, color: color, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _StarDisplay extends StatelessWidget {
  final double value;
  const _StarDisplay({required this.value});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.secondary;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.star_rounded, color: color, size: 18),
        const SizedBox(width: 2),
        Text(
          value.toStringAsFixed(0),
          style: TextStyle(
              fontWeight: FontWeight.w700, color: color, fontSize: 14),
        ),
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  final List<Widget> children;
  const _InfoCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          children: children
              .expand((w) => [w, const Divider(height: 12)])
              .toList()
            ..removeLast(),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onSurfaceVariant;
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 8),
        Text(label,
            style: TextStyle(fontSize: 13, color: color)),
        const Spacer(),
        Text(value,
            style: const TextStyle(
                fontSize: 13, fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class _LocationCard extends StatelessWidget {
  final double lat;
  final double lng;
  final VoidCallback onOpenMaps;

  const _LocationCard(
      {required this.lat, required this.lng, required this.onOpenMaps});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Icon(Icons.location_pin, color: colorScheme.primary, size: 28),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${lat.toStringAsFixed(5)}, ${lng.toStringAsFixed(5)}',
                      style: const TextStyle(fontSize: 13)),
                ],
              ),
            ),
            FilledButton.tonal(
              onPressed: onOpenMaps,
              child: const Text('Google Maps'),
            ),
          ],
        ),
      ),
    );
  }
}

class _LinkTile extends StatelessWidget {
  final String label;
  final String url;

  const _LinkTile({required this.label, required this.url});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      child: ListTile(
        dense: true,
        leading: const Icon(Icons.link, size: 20),
        title: Text(label.isNotEmpty ? label : url,
            style: const TextStyle(fontSize: 13)),
        subtitle: label.isNotEmpty
            ? Text(url,
                style: const TextStyle(fontSize: 11),
                maxLines: 1,
                overflow: TextOverflow.ellipsis)
            : null,
        trailing: const Icon(Icons.open_in_new, size: 16),
        onTap: () async {
          final uri = Uri.tryParse(url);
          if (uri != null && await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          }
        },
      ),
    );
  }
}

class _EmptyPhotos extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyPhotos({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onAdd,
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          border: Border.all(
              color: Theme.of(context).colorScheme.outlineVariant,
              style: BorderStyle.solid),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_a_photo_outlined,
                size: 36,
                color: Theme.of(context).colorScheme.onSurfaceVariant),
            const SizedBox(height: 8),
            Text('Agrega fotos del lugar',
                style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 13)),
          ],
        ),
      ),
    );
  }
}

class _PhotoGallery extends StatelessWidget {
  final List<String> paths;
  final ValueChanged<int> onDelete;

  const _PhotoGallery({required this.paths, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 140,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: paths.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final path = paths[index];
          return GestureDetector(
            onTap: () => _openFullScreen(context, index),
            onLongPress: () => onDelete(index),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.file(
                File(path),
                width: 120,
                height: 140,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 120,
                  height: 140,
                  color: Colors.grey.shade200,
                  child: const Icon(Icons.broken_image, color: Colors.grey),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _openFullScreen(BuildContext context, int initialIndex) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _FullScreenGallery(
          paths: paths,
          initialIndex: initialIndex,
        ),
      ),
    );
  }
}

// ── Full-screen gallery with swipe ────────────────────────────────────────────

class _FullScreenGallery extends StatefulWidget {
  final List<String> paths;
  final int initialIndex;

  const _FullScreenGallery(
      {required this.paths, required this.initialIndex});

  @override
  State<_FullScreenGallery> createState() => _FullScreenGalleryState();
}

class _FullScreenGalleryState extends State<_FullScreenGallery> {
  late final PageController _pageCtrl;
  late final ValueNotifier<int> _currentPage;

  @override
  void initState() {
    super.initState();
    _currentPage = ValueNotifier(widget.initialIndex);
    _pageCtrl = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    _currentPage.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: ValueListenableBuilder<int>(
          valueListenable: _currentPage,
          builder: (_, page, __) => Text(
            '${page + 1} / ${widget.paths.length}',
            style: const TextStyle(color: Colors.white),
          ),
        ),
      ),
      body: PageView.builder(
        controller: _pageCtrl,
        itemCount: widget.paths.length,
        onPageChanged: (i) => _currentPage.value = i,
        itemBuilder: (context, index) {
          return InteractiveViewer(
            child: Center(
              child: Image.file(
                File(widget.paths[index]),
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.broken_image,
                  color: Colors.white,
                  size: 64,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
