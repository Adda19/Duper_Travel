import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/utils/trip_provider.dart';
import '../../trips/models/trip_model.dart';
import '../models/wishlist_place_model.dart';
import '../providers/wishlist_provider.dart';
import 'add_wishlist_place_screen.dart';

const _linkSep = ':::';

class WishlistDetailScreen extends StatefulWidget {
  final WishlistPlaceModel place;
  const WishlistDetailScreen({super.key, required this.place});

  @override
  State<WishlistDetailScreen> createState() => _WishlistDetailScreenState();
}

class _WishlistDetailScreenState extends State<WishlistDetailScreen> {
  late WishlistPlaceModel _place;
  final _picker = ImagePicker();
  bool _addingPhoto = false;

  @override
  void initState() {
    super.initState();
    _place = widget.place;
  }

  @override
  Widget build(BuildContext context) {
    final typeColor = PlaceTypeColor.of(_place.tipo);
    final isVisited = _place.isVisited;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // ── SliverAppBar ────────────────────────────────────────────────────
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
              background: _place.fotos.isNotEmpty &&
                      File(_place.fotos.first).existsSync()
                  ? Image.file(File(_place.fotos.first), fit: BoxFit.cover)
                  : Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [typeColor, typeColor.withAlpha(200)],
                        ),
                      ),
                      child: Center(
                        child: Icon(PlaceType.icon(_place.tipo),
                            size: 72, color: Colors.white.withAlpha(180)),
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
                      _StatusBadge(isVisited: isVisited),
                      const SizedBox(width: 8),
                      if (_place.fuente.isNotEmpty)
                        _FuenteBadge(fuente: _place.fuente),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // ── Marcar como visitado ─────────────────────────────────
                  SizedBox(
                    width: double.infinity,
                    child: isVisited
                        ? OutlinedButton.icon(
                            onPressed: _markAsPending,
                            icon: const Icon(Icons.undo),
                            label: const Text('Marcar como pendiente'),
                          )
                        : FilledButton.icon(
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFF2E7D32),
                            ),
                            onPressed: _markAsVisited,
                            icon: const Icon(Icons.check_circle_outline),
                            label: const Text('Marcar como visitado'),
                          ),
                  ),
                  const SizedBox(height: 12),

                  // ── Mover a viaje ─────────────────────────────────────────
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _moveToTrip,
                      icon: const Icon(Icons.flight_takeoff_outlined),
                      label: const Text('Mover a viaje'),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ── Info grid ─────────────────────────────────────────────
                  _InfoGrid(place: _place),
                  const SizedBox(height: 24),

                  // ── Location ──────────────────────────────────────────────
                  if (_place.hasLocation) ...[
                    _SectionTitle('Cómo llegar'),
                    const SizedBox(height: 10),
                    _LocationCard(
                      lat: _place.latitud,
                      lng: _place.longitud,
                      onDirections: _openDirections,
                    ),
                    const SizedBox(height: 24),
                  ],

                  // ── Tags ──────────────────────────────────────────────────
                  if (_place.tags.isNotEmpty) ...[
                    _SectionTitle('Etiquetas'),
                    const SizedBox(height: 10),
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
                    const SizedBox(height: 24),
                  ],

                  // ── Comentarios ───────────────────────────────────────────
                  if (_place.comentarios.isNotEmpty) ...[
                    _SectionTitle('Comentarios'),
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .surfaceVariant
                            .withOpacity(0.5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(_place.comentarios,
                          style: const TextStyle(fontSize: 14)),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // ── Links ─────────────────────────────────────────────────
                  if (_place.links.isNotEmpty) ...[
                    _SectionTitle('Links'),
                    const SizedBox(height: 10),
                    ..._place.links.map((raw) {
                      final parts = raw.split(_linkSep);
                      final label =
                          parts.length > 1 ? parts[0] : 'Ver enlace';
                      final url =
                          parts.length > 1 ? parts[1] : parts[0];
                      return ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
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
                        onTap: () => _launchUrl(url),
                      );
                    }),
                    const SizedBox(height: 24),
                  ],

                  // ── Fotos ─────────────────────────────────────────────────
                  _SectionTitle('Fotos'),
                  const SizedBox(height: 10),
                  _PhotoGallery(
                    fotos: _place.fotos,
                    isAdding: _addingPhoto,
                    onAddPhoto: _showPhotoSourceDialog,
                    onDeletePhoto: _deletePhoto,
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Actions ────────────────────────────────────────────────────────────────

  Future<void> _markAsVisited() async {
    await WishlistProvider.instance.markAsVisited(_place);
    if (mounted) setState(() {});
  }

  Future<void> _markAsPending() async {
    await WishlistProvider.instance.markAsPending(_place);
    if (mounted) setState(() {});
  }

  void _openEdit() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddWishlistPlaceScreen(existing: _place),
      ),
    );
    if (mounted) setState(() {});
  }

  Future<void> _confirmDelete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar lugar'),
        content: Text('¿Eliminar "${_place.nombre}" de tus guardados?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (ok == true && mounted) {
      await WishlistProvider.instance.deletePlace(_place);
      Navigator.of(context).pop();
    }
  }

  Future<void> _moveToTrip() async {
    final trips = TripProvider.instance.getAllTrips();
    if (trips.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No tienes viajes. Crea uno primero.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    // Step 1: select trip
    final trip = await showDialog<TripModel>(
      context: context,
      builder: (_) => SimpleDialog(
        title: const Text('Seleccionar viaje'),
        children: trips
            .map((t) => SimpleDialogOption(
                  onPressed: () => Navigator.pop(context, t),
                  child: Text(t.nombre,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                ))
            .toList(),
      ),
    );
    if (trip == null || !mounted) return;

    // Step 2: select day
    final maxDays = trip.duracionDias;
    final day = await showDialog<int>(
      context: context,
      builder: (_) => SimpleDialog(
        title: Text('Día en "${trip.nombre}"'),
        children: List.generate(
          maxDays,
          (i) => SimpleDialogOption(
            onPressed: () => Navigator.pop(context, i + 1),
            child: Text('Día ${i + 1}'),
          ),
        ),
      ),
    );
    if (day == null || !mounted) return;

    await WishlistProvider.instance.moveToTrip(_place, trip.id, day);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              '"${_place.nombre}" añadido al Día $day de "${trip.nombre}"'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _openDirections() async {
    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1'
      '&destination=${_place.latitud},${_place.longitud}',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  // ── Photos ─────────────────────────────────────────────────────────────────

  Future<void> _showPhotoSourceDialog() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Galería'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Cámara'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
          ],
        ),
      ),
    );
    if (source != null) await _addPhoto(source);
  }

  Future<void> _addPhoto(ImageSource source) async {
    setState(() => _addingPhoto = true);
    try {
      final xfile = await _picker.pickImage(
          source: source, imageQuality: 85, maxWidth: 1920);
      if (xfile == null) return;
      final dir = await getApplicationDocumentsDirectory();
      final name = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final saved = await File(xfile.path).copy('${dir.path}/$name');
      _place.fotos.add(saved.path);
      await WishlistProvider.instance.updatePlace(_place);
      if (mounted) setState(() {});
    } finally {
      if (mounted) setState(() => _addingPhoto = false);
    }
  }

  Future<void> _deletePhoto(int index) async {
    final path = _place.fotos[index];
    _place.fotos.removeAt(index);
    await WishlistProvider.instance.updatePlace(_place);
    try {
      final f = File(path);
      if (await f.exists()) await f.delete();
    } catch (_) {}
    if (mounted) setState(() {});
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: Theme.of(context).colorScheme.primary,
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
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(PlaceType.icon(tipo), size: 14, color: color),
          const SizedBox(width: 5),
          Text(PlaceType.label(tipo),
              style: TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w600, color: color)),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final bool isVisited;
  const _StatusBadge({required this.isVisited});

  @override
  Widget build(BuildContext context) {
    final color =
        isVisited ? const Color(0xFF2E7D32) : const Color(0xFF757575);
    final label = isVisited ? 'Visitado' : 'Pendiente';
    final icon = isVisited ? Icons.check_circle : Icons.bookmark_border;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 5),
          Text(label,
              style: TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w600, color: color)),
        ],
      ),
    );
  }
}

class _FuenteBadge extends StatelessWidget {
  final String fuente;
  const _FuenteBadge({required this.fuente});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.secondary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(WishlistSource.icon(fuente), size: 14, color: color),
          const SizedBox(width: 5),
          Text(fuente,
              style: TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w600, color: color)),
        ],
      ),
    );
  }
}

class _InfoGrid extends StatelessWidget {
  final WishlistPlaceModel place;
  const _InfoGrid({required this.place});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final items = <_InfoItem>[
      if (place.ciudad.isNotEmpty || place.pais.isNotEmpty)
        _InfoItem(
          icon: Icons.location_city_outlined,
          label: 'Ciudad',
          value: [place.ciudad, place.pais]
              .where((s) => s.isNotEmpty)
              .join(', '),
        ),
      _InfoItem(
        icon: Icons.calendar_today_outlined,
        label: 'Guardado',
        value: DateFormat("d 'de' MMMM y", 'es').format(place.fechaGuardado),
      ),
      if (place.isVisited && place.fechaVisitado != null)
        _InfoItem(
          icon: Icons.check_circle_outline,
          label: 'Visitado',
          value:
              DateFormat("d 'de' MMMM y", 'es').format(place.fechaVisitado!),
        ),
      if (place.costoEstimado > 0)
        _InfoItem(
          icon: Icons.attach_money_outlined,
          label: 'Costo estimado',
          value: place.costoEstimado.toStringAsFixed(0),
        ),
      if (place.tiempoEstimadoMin > 0)
        _InfoItem(
          icon: Icons.schedule_outlined,
          label: 'Tiempo estimado',
          value: () {
            final h = place.tiempoEstimadoMin ~/ 60;
            final m = place.tiempoEstimadoMin % 60;
            if (h == 0) return '${m}min';
            if (m == 0) return '${h}h';
            return '${h}h ${m}min';
          }(),
        ),
      if (place.horario.isNotEmpty)
        _InfoItem(
          icon: Icons.access_time_outlined,
          label: 'Horario',
          value: place.horario,
        ),
    ];

    if (items.isEmpty) return const SizedBox.shrink();

    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceVariant.withOpacity(0.35),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: items
            .map((item) => ListTile(
                  dense: true,
                  leading: Icon(item.icon, size: 20, color: cs.primary),
                  title: Text(item.label,
                      style: TextStyle(
                          fontSize: 11, color: cs.onSurfaceVariant)),
                  subtitle: Text(item.value,
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w500)),
                ))
            .toList(),
      ),
    );
  }
}

class _InfoItem {
  final IconData icon;
  final String label;
  final String value;
  const _InfoItem(
      {required this.icon, required this.label, required this.value});
}

class _LocationCard extends StatelessWidget {
  final double lat;
  final double lng;
  final VoidCallback onDirections;
  const _LocationCard(
      {required this.lat, required this.lng, required this.onDirections});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.primaryContainer.withOpacity(0.4),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(Icons.location_pin, color: cs.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '${lat.toStringAsFixed(5)}, ${lng.toStringAsFixed(5)}',
              style: TextStyle(fontSize: 13, color: cs.onSurface),
            ),
          ),
          FilledButton.tonal(
            onPressed: onDirections,
            child: const Text('Ir'),
          ),
        ],
      ),
    );
  }
}

class _PhotoGallery extends StatelessWidget {
  final List<String> fotos;
  final bool isAdding;
  final VoidCallback onAddPhoto;
  final ValueChanged<int> onDeletePhoto;

  const _PhotoGallery({
    required this.fotos,
    required this.isAdding,
    required this.onAddPhoto,
    required this.onDeletePhoto,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 120,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          // Add button
          GestureDetector(
            onTap: isAdding ? null : onAddPhoto,
            child: Container(
              width: 100,
              height: 100,
              margin: const EdgeInsets.only(right: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.4),
                  width: 1.5,
                  style: BorderStyle.solid,
                ),
              ),
              child: isAdding
                  ? const Center(
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_a_photo_outlined,
                            color: Theme.of(context).colorScheme.primary,
                            size: 28),
                        const SizedBox(height: 4),
                        Text('Agregar',
                            style: TextStyle(
                                fontSize: 11,
                                color:
                                    Theme.of(context).colorScheme.primary)),
                      ],
                    ),
            ),
          ),

          // Existing photos
          ...fotos.asMap().entries.map((entry) {
            final i = entry.key;
            final path = entry.value;
            final file = File(path);
            return GestureDetector(
              onLongPress: () => _confirmDeletePhoto(context, i),
              onTap: () => _openFullscreen(context, i),
              child: Container(
                width: 100,
                height: 100,
                margin: const EdgeInsets.only(right: 10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.grey.shade200,
                ),
                clipBehavior: Clip.antiAlias,
                child: file.existsSync()
                    ? Image.file(file, fit: BoxFit.cover)
                    : const Icon(Icons.broken_image_outlined,
                        color: Colors.grey),
              ),
            );
          }),
        ],
      ),
    );
  }

  Future<void> _confirmDeletePhoto(BuildContext context, int index) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar foto'),
        content: const Text('¿Eliminar esta foto?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Eliminar')),
        ],
      ),
    );
    if (ok == true) onDeletePhoto(index);
  }

  void _openFullscreen(BuildContext context, int initial) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _FullscreenGallery(fotos: fotos, initial: initial),
      ),
    );
  }
}

class _FullscreenGallery extends StatefulWidget {
  final List<String> fotos;
  final int initial;
  const _FullscreenGallery({required this.fotos, required this.initial});

  @override
  State<_FullscreenGallery> createState() => _FullscreenGalleryState();
}

class _FullscreenGalleryState extends State<_FullscreenGallery> {
  late final PageController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = PageController(initialPage: widget.initial);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text('${widget.initial + 1}/${widget.fotos.length}'),
      ),
      body: PageView.builder(
        controller: _ctrl,
        itemCount: widget.fotos.length,
        itemBuilder: (_, i) {
          final file = File(widget.fotos[i]);
          return InteractiveViewer(
            child: Center(
              child: file.existsSync()
                  ? Image.file(file)
                  : const Icon(Icons.broken_image_outlined,
                      color: Colors.grey, size: 80),
            ),
          );
        },
      ),
    );
  }
}
