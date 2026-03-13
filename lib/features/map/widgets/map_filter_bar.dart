import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_constants.dart';

/// Floating filter bar displayed at the top of the map.
/// Two scrollable rows: one for place types, one for days.
/// When a specific day is selected and [tripStart] is provided, a date banner
/// is shown below the chips inside the card.
class MapFilterBar extends StatelessWidget {
  final String selectedType; // '' = show all types
  final int selectedDay;     // 0  = show all days
  final int maxDays;
  final DateTime? tripStart;
  final bool showWishlist;
  final VoidCallback onWishlistToggled;
  final ValueChanged<String> onTypeChanged;
  final ValueChanged<int> onDayChanged;

  const MapFilterBar({
    super.key,
    required this.selectedType,
    required this.selectedDay,
    required this.maxDays,
    this.tripStart,
    this.showWishlist = false,
    required this.onWishlistToggled,
    required this.onTypeChanged,
    required this.onDayChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Type chips ───────────────────────────────────────────────
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  children: [
                    _FilterChip(
                      label: 'Todos',
                      icon: Icons.layers_outlined,
                      color: Theme.of(context).colorScheme.primary,
                      selected: selectedType.isEmpty,
                      onTap: () => onTypeChanged(''),
                    ),
                    const SizedBox(width: 6),
                    ...PlaceType.all.map((type) => Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: _FilterChip(
                            label: PlaceType.label(type),
                            icon: PlaceType.icon(type),
                            color: PlaceTypeColor.of(type),
                            selected: selectedType == type,
                            onTap: () => onTypeChanged(
                              selectedType == type ? '' : type,
                            ),
                          ),
                        )),
                  ],
                ),
              ),

              // ── Day chips (only if trip has > 1 day) ────────────────────
              if (maxDays > 1) ...[
                const SizedBox(height: 6),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Row(
                    children: [
                      _FilterChip(
                        label: 'Todos los días',
                        icon: Icons.calendar_today_outlined,
                        color: Theme.of(context).colorScheme.secondary,
                        selected: selectedDay == 0,
                        onTap: () => onDayChanged(0),
                      ),
                      const SizedBox(width: 6),
                      ...List.generate(
                        maxDays,
                        (i) => Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: _FilterChip(
                            label: 'Día ${i + 1}',
                            icon: Icons.today_outlined,
                            color: Theme.of(context).colorScheme.secondary,
                            selected: selectedDay == i + 1,
                            onTap: () => onDayChanged(
                              selectedDay == i + 1 ? 0 : i + 1,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // ── Day date banner ──────────────────────────────────────────
              if (selectedDay > 0 && tripStart != null) ...[
                const SizedBox(height: 6),
                _DayDateBanner(day: selectedDay, tripStart: tripStart!),
              ],

              // ── Wishlist toggle ──────────────────────────────────────────
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  children: [
                    Icon(
                      showWishlist
                          ? Icons.favorite
                          : Icons.favorite_border,
                      size: 16,
                      color: showWishlist
                          ? Colors.pinkAccent
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Ver Wishlist',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: showWishlist
                            ? Colors.pinkAccent
                            : Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const Spacer(),
                    Switch(
                      value: showWishlist,
                      onChanged: (_) => onWishlistToggled(),
                      activeColor: Colors.pinkAccent,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Day date banner ────────────────────────────────────────────────────────────

class _DayDateBanner extends StatelessWidget {
  final int day;
  final DateTime tripStart;

  const _DayDateBanner({required this.day, required this.tripStart});

  @override
  Widget build(BuildContext context) {
    final date = tripStart.add(Duration(days: day - 1));
    String cap(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
    final label = cap(DateFormat("EEEE d 'de' MMMM", 'es').format(date));

    return Container(
      margin: const EdgeInsets.fromLTRB(8, 0, 8, 2),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.55),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.calendar_month_outlined, size: 13, color: Colors.white),
          const SizedBox(width: 5),
          Text(
            'Día $day · $label',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Internal chip ─────────────────────────────────────────────────────────────

class _FilterChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.icon,
    required this.color,
    required this.selected,
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
