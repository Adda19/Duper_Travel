import 'dart:io';

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_constants.dart';
import '../models/wishlist_place_model.dart';
import '../providers/wishlist_provider.dart';
import 'add_wishlist_place_screen.dart';
import 'wishlist_detail_screen.dart';

class WishlistScreen extends StatefulWidget {
  const WishlistScreen({super.key});

  @override
  State<WishlistScreen> createState() => _WishlistScreenState();
}

class _WishlistScreenState extends State<WishlistScreen> {
  String _search = '';
  String _statusFilter = ''; // '' = all, 'pending', 'visited'
  String _typeFilter = '';   // '' = all types

  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<WishlistPlaceModel> _applyFilters(List<WishlistPlaceModel> all) {
    return all.where((p) {
      if (_search.isNotEmpty &&
          !p.nombre.toLowerCase().contains(_search.toLowerCase()) &&
          !p.ciudad.toLowerCase().contains(_search.toLowerCase())) {
        return false;
      }
      if (_statusFilter.isNotEmpty && p.estado != _statusFilter) return false;
      if (_typeFilter.isNotEmpty && p.tipo != _typeFilter) return false;
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Por Visitar'),
        centerTitle: false,
        actions: [
          ValueListenableBuilder<Box<WishlistPlaceModel>>(
            valueListenable:
                Hive.box<WishlistPlaceModel>(HiveBoxes.wishlist).listenable(),
            builder: (_, box, __) {
              final total = box.length;
              return Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Center(
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: cs.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$total',
                      style: TextStyle(
                        color: cs.onPrimaryContainer,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: ValueListenableBuilder<Box<WishlistPlaceModel>>(
        valueListenable:
            Hive.box<WishlistPlaceModel>(HiveBoxes.wishlist).listenable(),
        builder: (context, _, __) {
          final all = WishlistProvider.instance.getAll();
          final filtered = _applyFilters(all);

          return Column(
            children: [
              // ── Search bar ─────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                child: TextField(
                  controller: _searchCtrl,
                  decoration: InputDecoration(
                    hintText: 'Buscar por nombre o ciudad...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    suffixIcon: _search.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _searchCtrl.clear();
                              setState(() => _search = '');
                            },
                          )
                        : null,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: cs.surfaceVariant.withOpacity(0.5),
                  ),
                  onChanged: (v) => setState(() => _search = v),
                ),
              ),

              // ── Status + type filters ──────────────────────────────────────
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                child: Row(
                  children: [
                    _StatusChip(
                      label: 'Todos',
                      icon: Icons.favorite_border,
                      selected: _statusFilter.isEmpty,
                      color: cs.primary,
                      onTap: () => setState(() => _statusFilter = ''),
                    ),
                    const SizedBox(width: 6),
                    _StatusChip(
                      label: 'Pendientes',
                      icon: Icons.bookmark_border,
                      selected: _statusFilter == WishlistStatus.pending,
                      color: cs.secondary,
                      onTap: () => setState(() => _statusFilter =
                          _statusFilter == WishlistStatus.pending
                              ? ''
                              : WishlistStatus.pending),
                    ),
                    const SizedBox(width: 6),
                    _StatusChip(
                      label: 'Visitados',
                      icon: Icons.check_circle_outline,
                      selected: _statusFilter == WishlistStatus.visited,
                      color: const Color(0xFF2E7D32),
                      onTap: () => setState(() => _statusFilter =
                          _statusFilter == WishlistStatus.visited
                              ? ''
                              : WishlistStatus.visited),
                    ),
                    const SizedBox(width: 12),
                    const VerticalDivider(width: 1, indent: 4, endIndent: 4),
                    const SizedBox(width: 12),
                    ...PlaceType.all.map((type) => Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: _StatusChip(
                            label: PlaceType.label(type),
                            icon: PlaceType.icon(type),
                            selected: _typeFilter == type,
                            color: PlaceTypeColor.of(type),
                            onTap: () => setState(() => _typeFilter =
                                _typeFilter == type ? '' : type),
                          ),
                        )),
                  ],
                ),
              ),

              // ── List ───────────────────────────────────────────────────────
              Expanded(
                child: filtered.isEmpty
                    ? _EmptyState(hasFilters: all.isNotEmpty)
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                        itemCount: filtered.length,
                        itemBuilder: (context, i) {
                          final place = filtered[i];
                          return _WishlistCard(
                            place: place,
                            onTap: () => _openDetail(place),
                            onDelete: () => _confirmDelete(place),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAdd,
        icon: const Icon(Icons.add),
        label: const Text('Agregar lugar'),
      ),
    );
  }

  void _openAdd() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddWishlistPlaceScreen()),
    );
  }

  void _openDetail(WishlistPlaceModel place) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => WishlistDetailScreen(place: place)),
    );
  }

  Future<void> _confirmDelete(WishlistPlaceModel place) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar lugar'),
        content: Text('¿Eliminar "${place.nombre}" de tu lista?'),
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
    if (ok == true) {
      await WishlistProvider.instance.deletePlace(place);
    }
  }
}

// ── Card ──────────────────────────────────────────────────────────────────────

class _WishlistCard extends StatelessWidget {
  final WishlistPlaceModel place;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _WishlistCard({
    required this.place,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final typeColor = PlaceTypeColor.of(place.tipo);
    final isVisited = place.isVisited;
    final photoPath =
        place.fotos.isNotEmpty ? place.fotos.first : null;

    return Dismissible(
      key: ValueKey(place.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: cs.error,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white, size: 28),
      ),
      confirmDismiss: (_) async {
        onDelete();
        return false; // let the callback handle deletion
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 10),
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: InkWell(
          onTap: onTap,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Photo / type icon ─────────────────────────────────────────
              SizedBox(
                width: 88,
                height: 88,
                child: photoPath != null && File(photoPath).existsSync()
                    ? Image.file(File(photoPath), fit: BoxFit.cover)
                    : Container(
                        color: typeColor.withAlpha(30),
                        child: Icon(PlaceType.icon(place.tipo),
                            color: typeColor, size: 36),
                      ),
              ),

              // ── Info ──────────────────────────────────────────────────────
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              place.nombre,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isVisited)
                            const Icon(Icons.check_circle,
                                color: Color(0xFF2E7D32), size: 18),
                        ],
                      ),
                      if (place.ciudad.isNotEmpty || place.pais.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(
                          [place.ciudad, place.pais]
                              .where((s) => s.isNotEmpty)
                              .join(', '),
                          style: TextStyle(
                              fontSize: 12, color: cs.onSurfaceVariant),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          _SmallBadge(
                            label: PlaceType.label(place.tipo),
                            color: typeColor,
                          ),
                          const SizedBox(width: 6),
                          if (place.fuente.isNotEmpty)
                            _SmallBadge(
                              label: place.fuente,
                              color: cs.secondary,
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat("d MMM y", 'es').format(place.fechaGuardado),
                        style: TextStyle(
                            fontSize: 11, color: cs.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Small badge ───────────────────────────────────────────────────────────────

class _SmallBadge extends StatelessWidget {
  final String label;
  final Color color;
  const _SmallBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

// ── Status filter chip ────────────────────────────────────────────────────────

class _StatusChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _StatusChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? color : color.withAlpha(20),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? color : color.withAlpha(60),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: selected ? Colors.white : color),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final bool hasFilters;
  const _EmptyState({required this.hasFilters});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              hasFilters ? Icons.search_off : Icons.favorite_border,
              size: 72,
              color: cs.primary.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              hasFilters
                  ? 'Sin resultados para tu búsqueda'
                  : '¡Guarda ese lugar que viste en Instagram!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: cs.onSurface.withOpacity(0.6),
              ),
            ),
            if (!hasFilters) ...[
              const SizedBox(height: 8),
              Text(
                'Tu lista de lugares por visitar aparecerá aquí.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: cs.onSurface.withOpacity(0.45),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
