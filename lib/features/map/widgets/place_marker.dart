import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';

/// Marker pin rendered inside a flutter_map [Marker.builder].
///
/// - Pending  → pulses (scale animation)
/// - Confirmed → slightly larger (48 vs 40)
/// - Route mode → shows checkbox overlay
class PlaceMarker extends StatefulWidget {
  final String tipo;
  final String estado;

  /// Day number to display as a badge (e.g. 1 → "D1"). Null hides the badge.
  final int? dia;
  final bool routeMode;
  final bool isSelected;
  final VoidCallback? onTap;

  const PlaceMarker({
    super.key,
    required this.tipo,
    required this.estado,
    this.dia,
    this.routeMode = false,
    this.isSelected = false,
    this.onTap,
  });

  @override
  State<PlaceMarker> createState() => _PlaceMarkerState();
}

class _PlaceMarkerState extends State<PlaceMarker>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _pulse = Tween<double>(begin: 1.0, end: 1.22).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
    if (widget.estado == PlaceStatus.pending) {
      _ctrl.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(PlaceMarker old) {
    super.didUpdateWidget(old);
    final isPending = widget.estado == PlaceStatus.pending;
    if (isPending && !_ctrl.isAnimating) {
      _ctrl.repeat(reverse: true);
    } else if (!isPending && _ctrl.isAnimating) {
      _ctrl
        ..stop()
        ..reset();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = PlaceTypeColor.of(widget.tipo);
    final icon = PlaceType.icon(widget.tipo);
    final isPending = widget.estado == PlaceStatus.pending;
    final isConfirmed = widget.estado == 'confirmed';
    final isVisited = widget.estado == PlaceStatus.visited;
    final baseSize = isConfirmed ? 48.0 : 40.0;

    // ── Marker body ──────────────────────────────────────────────────────────
    Widget body = Container(
      width: baseSize,
      height: baseSize,
      decoration: BoxDecoration(
        color: isVisited ? color.withAlpha(160) : color,
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white,
          width: isConfirmed ? 3 : 2,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withAlpha(isPending ? 120 : 80),
            blurRadius: 8,
            spreadRadius: isPending ? 3 : 1,
          ),
        ],
      ),
      child: widget.routeMode
          ? _checkmark(widget.isSelected, color)
          : Icon(icon, color: Colors.white, size: baseSize * 0.5),
    );

    // ── Pulse wrapper for pending ────────────────────────────────────────────
    if (isPending && !widget.routeMode) {
      body = ScaleTransition(scale: _pulse, child: body);
    }

    return GestureDetector(
      onTap: widget.onTap,
      child: SizedBox(
        width: 60,
        height: 60,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Center(child: body),
            if (widget.dia != null && !widget.routeMode)
              Positioned(
                top: 4,
                right: 4,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.65),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'D${widget.dia}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      height: 1.2,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _checkmark(bool selected, Color color) {
    return Icon(
      selected ? Icons.check_circle : Icons.radio_button_unchecked,
      color: Colors.white,
      size: 22,
    );
  }
}
