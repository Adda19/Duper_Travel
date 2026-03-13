import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_constants.dart';
import '../models/trip_model.dart';

class TripCountdownBanner extends StatefulWidget {
  final TripModel trip;
  const TripCountdownBanner({super.key, required this.trip});

  @override
  State<TripCountdownBanner> createState() => _TripCountdownBannerState();
}

class _TripCountdownBannerState extends State<TripCountdownBanner>
    with TickerProviderStateMixin {
  late final AnimationController _gradientCtrl;
  late final AnimationController _iconCtrl;
  late final AnimationController _pulseCtrl;
  Timer? _timer;
  Duration _remaining = Duration.zero;

  @override
  void initState() {
    super.initState();
    _gradientCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _iconCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..repeat(reverse: true);

    _updateRemaining();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) _updateRemaining();
    });
  }

  void _updateRemaining() {
    final target = _departureDateTime();
    final now = DateTime.now();
    setState(() {
      _remaining =
          (target != null && target.isAfter(now)) ? target.difference(now) : Duration.zero;
    });
  }

  DateTime? _departureDateTime() {
    final h = widget.trip.horaSalida;
    final base = widget.trip.fechaInicio;
    if (h != null) {
      return DateTime(base.year, base.month, base.day, h.hour, h.minute);
    }
    return DateTime(base.year, base.month, base.day);
  }

  @override
  void dispose() {
    _gradientCtrl.dispose();
    _iconCtrl.dispose();
    _pulseCtrl.dispose();
    _timer?.cancel();
    super.dispose();
  }

  // ── State routing ──────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final start = DateTime(widget.trip.fechaInicio.year,
        widget.trip.fechaInicio.month, widget.trip.fechaInicio.day);
    final end = DateTime(widget.trip.fechaFin.year, widget.trip.fechaFin.month,
        widget.trip.fechaFin.day);

    if (today.isBefore(start)) return _buildBefore(context);
    if (!today.isAfter(end)) return _buildInProgress(context, today, start);
    return _buildFinished(context);
  }

  // ── BEFORE ─────────────────────────────────────────────────────────────────

  Widget _buildBefore(BuildContext context) {
    final isUnder1h = _remaining.inMinutes < 60 && _remaining.inSeconds > 0;
    final isUnder24h = _remaining.inHours < 24 && _remaining.inSeconds > 0;

    final List<Color> from;
    final List<Color> to;

    if (isUnder1h) {
      from = [const Color(0xFFB71C1C), const Color(0xFFC62828)];
      to = [const Color(0xFFE53935), const Color(0xFFEF5350)];
    } else if (isUnder24h) {
      from = [const Color(0xFFBF360C), const Color(0xFFE65100)];
      to = [const Color(0xFFFF6D00), const Color(0xFFFF8F00)];
    } else {
      from = [const Color(0xFF1A237E), const Color(0xFF4A148C)];
      to = [const Color(0xFF283593), const Color(0xFF6A1B9A)];
    }

    return AnimatedBuilder(
      animation: _gradientCtrl,
      builder: (context, _) {
        final t = _gradientCtrl.value;
        final c1 = Color.lerp(from[0], to[0], t)!;
        final c2 = Color.lerp(from[1], to[1], t)!;
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              colors: [c1, c2],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: isUnder1h
              ? _buildUnder1h()
              : isUnder24h
                  ? _buildUnder24h()
                  : _buildNormal(context),
        );
      },
    );
  }

  Widget _buildNormal(BuildContext context) {
    final trip = widget.trip;
    final tipo = trip.tipoTransporte;
    final emoji = TransportType.emoji(tipo);
    final headerText = '${TransportType.countdownText(tipo)}!';

    final days = _remaining.inDays;
    final hours = _remaining.inHours % 24;
    final minutes = _remaining.inMinutes % 60;
    final seconds = _remaining.inSeconds % 60;

    final dateFmt = DateFormat('d MMM', 'es');
    final h = trip.horaSalida;
    final timeStr = h != null
        ? ' · ${h.hour.toString().padLeft(2, '0')}:${h.minute.toString().padLeft(2, '0')}'
        : '';
    final infoLine = '${trip.destino} · ${dateFmt.format(trip.fechaInicio)}$timeStr';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with animated transport icon
        Row(
          children: [
            AnimatedBuilder(
              animation: _iconCtrl,
              builder: (_, __) {
                final offset = (_iconCtrl.value * 20) - 10;
                return Transform.translate(
                  offset: Offset(offset, 0),
                  child: Text(emoji, style: const TextStyle(fontSize: 20)),
                );
              },
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                headerText,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        // Countdown row
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _CountUnit(value: days, label: 'días'),
            const _Colon(),
            _CountUnit(value: hours, label: 'hrs'),
            const _Colon(),
            _CountUnit(value: minutes, label: 'min'),
            const _Colon(),
            _CountUnit(value: seconds, label: 'seg'),
          ],
        ),
        const SizedBox(height: 8),
        // Destination / time info
        Text(
          infoLine,
          style: const TextStyle(color: Colors.white70, fontSize: 11),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildUnder24h() {
    final tipo = widget.trip.tipoTransporte;
    final emoji = TransportType.emoji(tipo);
    final hours = _remaining.inHours;
    final minutes = _remaining.inMinutes % 60;
    final seconds = _remaining.inSeconds % 60;

    return Column(
      children: [
        Text(
          '¡Mañana es el gran día! $emoji 🎉',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w800,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _CountUnit(value: hours, label: 'hrs', large: true),
            const _Colon(large: true),
            _CountUnit(value: minutes, label: 'min', large: true),
            const _Colon(large: true),
            _CountUnit(value: seconds, label: 'seg', large: true),
          ],
        ),
      ],
    );
  }

  Widget _buildUnder1h() {
    final minutes = _remaining.inMinutes % 60;
    final seconds = _remaining.inSeconds % 60;

    return AnimatedBuilder(
      animation: _pulseCtrl,
      builder: (_, __) {
        return Column(
          children: [
            Text(
              '¡Ya casi! ⚡',
              style: TextStyle(
                color: Colors.white
                    .withAlpha((178 + (77 * _pulseCtrl.value).round())),
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _CountUnit(value: minutes, label: 'min', large: true),
                const _Colon(large: true),
                _CountUnit(value: seconds, label: 'seg', large: true),
              ],
            ),
          ],
        );
      },
    );
  }

  // ── IN PROGRESS ────────────────────────────────────────────────────────────

  Widget _buildInProgress(
      BuildContext context, DateTime today, DateTime start) {
    final day = today.difference(start).inDays + 1;
    final totalDays = widget.trip.duracionDias;
    final progress = (day / totalDays).clamp(0.0, 1.0);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: const LinearGradient(
          colors: [Color(0xFF1B5E20), Color(0xFF388E3C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('🌍', style: TextStyle(fontSize: 16)),
              const SizedBox(width: 8),
              Text(
                'En curso · Día $day de $totalDays',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.white24,
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              minHeight: 5,
            ),
          ),
        ],
      ),
    );
  }

  // ── FINISHED ───────────────────────────────────────────────────────────────

  Widget _buildFinished(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: cs.surfaceVariant,
      ),
      child: Row(
        children: [
          const Text('🎒', style: TextStyle(fontSize: 16)),
          const SizedBox(width: 8),
          Text(
            '¡Qué viaje! · Terminado',
            style: TextStyle(
              color: cs.onSurfaceVariant,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Helper widgets ─────────────────────────────────────────────────────────────

class _CountUnit extends StatelessWidget {
  final int value;
  final String label;
  final bool large;
  const _CountUnit(
      {required this.value, required this.label, this.large = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value.toString().padLeft(2, '0'),
          style: TextStyle(
            color: Colors.white,
            fontSize: large ? 28 : 20,
            fontWeight: FontWeight.w900,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white70,
            fontSize: large ? 10 : 9,
          ),
        ),
      ],
    );
  }
}

class _Colon extends StatelessWidget {
  final bool large;
  const _Colon({this.large = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4, right: 4),
      child: Text(
        ':',
        style: TextStyle(
          color: Colors.white,
          fontSize: large ? 24 : 18,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}
