import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../core/constants/app_constants.dart';
import '../../costs/models/manual_expense_model.dart';
import '../../places/models/place_model.dart';
import '../../trips/models/trip_model.dart';

// ── Color mapping (matches app's PlaceTypeColor) ──────────────────────────────

PdfColor _typeColor(String type) => switch (type) {
      PlaceType.hotel => const PdfColor.fromInt(0xFF1565C0),
      PlaceType.restaurant => const PdfColor.fromInt(0xFFE53935),
      PlaceType.attraction => const PdfColor.fromInt(0xFF7B1FA2),
      PlaceType.transport => const PdfColor.fromInt(0xFF00838F),
      PlaceType.shopping => const PdfColor.fromInt(0xFFFF6D00),
      PlaceType.entertainment => const PdfColor.fromInt(0xFFFDD835),
      PlaceType.nature => const PdfColor.fromInt(0xFF2E7D32),
      _ => const PdfColor.fromInt(0xFF757575),
    };

String _typeEmoji(String type) => switch (type) {
      PlaceType.hotel => '🏨',
      PlaceType.restaurant => '🍽️',
      PlaceType.attraction => '📸',
      PlaceType.transport => '🚌',
      PlaceType.shopping => '🛍️',
      PlaceType.entertainment => '🎭',
      PlaceType.nature => '🌳',
      _ => '📍',
    };

// ── Main generator ─────────────────────────────────────────────────────────────

Future<Uint8List> generateItineraryPdf({
  required TripModel trip,
  required List<PlaceModel> places,
  required List<ManualExpenseModel> expenses,
}) async {
  final pdf = pw.Document();

  final dateFmt = DateFormat("d 'de' MMMM yyyy", 'es');
  final dayFmt = DateFormat("EEEE d 'de' MMMM", 'es');
  final currFmt = NumberFormat('#,##0.00', 'es');
  final compactFmt = NumberFormat.compact(locale: 'es');

  // ── Fonts ──────────────────────────────────────────────────────────────────
  // Use built-in base14 fonts for offline compatibility
  final titleFont = pw.Font.helveticaBold();
  final bodyFont = pw.Font.helvetica();
  final boldFont = pw.Font.helveticaBold();

  // ── Brand colors ───────────────────────────────────────────────────────────
  const primary = PdfColor.fromInt(0xFF1976D2);
  const primaryDark = PdfColor.fromInt(0xFF0D47A1);
  const bgLight = PdfColor.fromInt(0xFFF5F5F5);
  const textMain = PdfColor.fromInt(0xFF212121);
  const textMuted = PdfColor.fromInt(0xFF757575);
  const divider = PdfColor.fromInt(0xFFE0E0E0);

  // ── Pre-compute totals ────────────────────────────────────────────────────
  double totalEstimado = places.fold(0, (s, p) => s + p.costoEstimado);
  for (final e in expenses) {
    totalEstimado += e.montoEstimado;
  }
  int totalMinutos = places.fold(0, (s, p) => s + p.tiempoEstimadoMin);

  // Category breakdown from places
  final Map<String, double> categoryTotals = {};
  for (final p in places) {
    if (p.costoEstimado <= 0) continue;
    final cat = switch (p.tipo) {
      PlaceType.hotel => CostCategory.accommodation,
      PlaceType.restaurant => CostCategory.food,
      PlaceType.transport => CostCategory.transport,
      PlaceType.shopping => CostCategory.shopping,
      PlaceType.entertainment => CostCategory.activities,
      PlaceType.attraction => CostCategory.activities,
      PlaceType.nature => CostCategory.activities,
      _ => CostCategory.other,
    };
    categoryTotals[cat] = (categoryTotals[cat] ?? 0) + p.costoEstimado;
  }
  for (final e in expenses) {
    categoryTotals[e.categoria] =
        (categoryTotals[e.categoria] ?? 0) + e.montoEstimado;
  }

  // Group places by day
  final Map<int, List<PlaceModel>> byDay = {};
  for (int d = 1; d <= trip.duracionDias; d++) {
    byDay[d] = places.where((p) => p.dia == d).toList();
  }

  // ── Header / footer builders ───────────────────────────────────────────────
  pw.Widget pageHeader() => pw.Container(
        decoration: const pw.BoxDecoration(
          gradient: pw.LinearGradient(
            colors: [primaryDark, primary],
          ),
        ),
        padding: const pw.EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              trip.nombre,
              style: pw.TextStyle(
                font: boldFont,
                fontSize: 11,
                color: PdfColors.white,
              ),
            ),
            pw.Text(
              'Dupper App',
              style: pw.TextStyle(
                font: bodyFont,
                fontSize: 9,
                color: const PdfColor(1, 1, 1, 0.7),
              ),
            ),
          ],
        ),
      );

  pw.Widget pageFooter(pw.Context ctx) => pw.Container(
        decoration: const pw.BoxDecoration(
          border: pw.Border(
            top: pw.BorderSide(color: divider, width: 0.5),
          ),
        ),
        padding: const pw.EdgeInsets.symmetric(horizontal: 24, vertical: 6),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'Generado con Dupper App  ·  By AddaVargas & AngelicaMonroy',
              style: pw.TextStyle(
                font: bodyFont,
                fontSize: 7,
                color: textMuted,
              ),
            ),
            pw.Text(
              'Página ${ctx.pageNumber} de ${ctx.pagesCount}',
              style: pw.TextStyle(
                font: bodyFont,
                fontSize: 7,
                color: textMuted,
              ),
            ),
          ],
        ),
      );

  // ── COVER PAGE ─────────────────────────────────────────────────────────────
  final h = trip.horaSalida;
  final timeStr = h != null
      ? '${h.hour.toString().padLeft(2, '0')}:${h.minute.toString().padLeft(2, '0')}'
      : null;
  final transportLabel =
      '${TransportType.emoji(trip.tipoTransporte)}  ${TransportType.label(trip.tipoTransporte)}';

  pdf.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: pw.EdgeInsets.zero,
      build: (ctx) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          // Top gradient banner
          pw.Container(
            height: 180,
            decoration: const pw.BoxDecoration(
              gradient: pw.LinearGradient(
                colors: [primaryDark, primary],
                begin: pw.Alignment.topLeft,
                end: pw.Alignment.bottomRight,
              ),
            ),
            child: pw.Center(
              child: pw.Column(
                mainAxisAlignment: pw.MainAxisAlignment.center,
                children: [
                  pw.Text(
                    trip.nombre,
                    style: pw.TextStyle(
                      font: titleFont,
                      fontSize: 28,
                      color: PdfColors.white,
                    ),
                    textAlign: pw.TextAlign.center,
                  ),
                  pw.SizedBox(height: 8),
                  pw.Text(
                    trip.destino,
                    style: pw.TextStyle(
                      font: bodyFont,
                      fontSize: 14,
                      color: const PdfColor(1, 1, 1, 0.7),
                    ),
                    textAlign: pw.TextAlign.center,
                  ),
                ],
              ),
            ),
          ),

          pw.SizedBox(height: 30),

          // Info cards grid
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(horizontal: 40),
            child: pw.Column(
              children: [
                _InfoRow(
                  icon: '📅',
                  label: 'Fechas',
                  value:
                      '${dateFmt.format(trip.fechaInicio)}  →  ${dateFmt.format(trip.fechaFin)}',
                  bodyFont: bodyFont,
                  boldFont: boldFont,
                ),
                pw.SizedBox(height: 12),
                _InfoRow(
                  icon: '📆',
                  label: 'Duración',
                  value:
                      '${trip.duracionDias} ${trip.duracionDias == 1 ? "día" : "días"}',
                  bodyFont: bodyFont,
                  boldFont: boldFont,
                ),
                pw.SizedBox(height: 12),
                _InfoRow(
                  icon: '👥',
                  label: 'Personas',
                  value:
                      '${trip.numeroPersonas} ${trip.numeroPersonas == 1 ? "persona" : "personas"}',
                  bodyFont: bodyFont,
                  boldFont: boldFont,
                ),
                pw.SizedBox(height: 12),
                _InfoRow(
                  icon: '🚀',
                  label: 'Transporte',
                  value: timeStr != null
                      ? '$transportLabel  ·  Sale a las $timeStr'
                      : transportLabel,
                  bodyFont: bodyFont,
                  boldFont: boldFont,
                ),
                pw.SizedBox(height: 12),
                _InfoRow(
                  icon: '💰',
                  label: 'Presupuesto',
                  value: trip.presupuestoTotal > 0
                      ? '${trip.moneda} ${currFmt.format(trip.presupuestoTotal)}'
                      : trip.moneda,
                  bodyFont: bodyFont,
                  boldFont: boldFont,
                ),
                pw.SizedBox(height: 12),
                _InfoRow(
                  icon: '💵',
                  label: 'Costo estimado',
                  value:
                      '${trip.moneda} ${currFmt.format(totalEstimado)}  (${trip.moneda} ${currFmt.format(trip.numeroPersonas > 0 ? totalEstimado / trip.numeroPersonas : totalEstimado)} p/persona)',
                  bodyFont: bodyFont,
                  boldFont: boldFont,
                ),
              ],
            ),
          ),

          pw.Spacer(),

          // Bottom attribution
          pw.Container(
            padding: const pw.EdgeInsets.all(20),
            child: pw.Center(
              child: pw.Text(
                'DUPPER App  ·  By AddaVargas & AngelicaMonroy',
                style: pw.TextStyle(
                  font: bodyFont,
                  fontSize: 9,
                  color: textMuted,
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );

  // ── DAY PAGES ──────────────────────────────────────────────────────────────
  for (int day = 1; day <= trip.duracionDias; day++) {
    final date = trip.fechaInicio.add(Duration(days: day - 1));
    final dayPlaces = byDay[day] ?? [];
    final dayLabel =
        'Día $day — ${_capitalize(dayFmt.format(date))}';

    final dayCost = dayPlaces.fold(0.0, (s, p) => s + p.costoEstimado);
    final dayMins = dayPlaces.fold(0, (s, p) => s + p.tiempoEstimadoMin);
    final dayHrs = dayMins ~/ 60;
    final dayMin = dayMins % 60;
    final dayTime = dayHrs > 0
        ? '${dayHrs}h ${dayMin > 0 ? "${dayMin}min" : ""}'
        : '${dayMin}min';

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.zero,
        build: (ctx) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            pageHeader(),
            pw.Expanded(
              child: pw.Padding(
                padding: const pw.EdgeInsets.fromLTRB(24, 16, 24, 8),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    // Day header
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: pw.BoxDecoration(
                        color: primary,
                        borderRadius: pw.BorderRadius.circular(8),
                      ),
                      child: pw.Text(
                        dayLabel,
                        style: pw.TextStyle(
                          font: boldFont,
                          fontSize: 13,
                          color: PdfColors.white,
                        ),
                      ),
                    ),
                    pw.SizedBox(height: 12),

                    // Table
                    if (dayPlaces.isEmpty)
                      pw.Padding(
                        padding:
                            const pw.EdgeInsets.symmetric(vertical: 20),
                        child: pw.Text(
                          'Sin lugares planificados para este día.',
                          style: pw.TextStyle(
                            font: bodyFont,
                            fontSize: 10,
                            color: textMuted,
                          ),
                        ),
                      )
                    else ...[
                      // Table header
                      pw.Container(
                        color: bgLight,
                        padding: const pw.EdgeInsets.symmetric(
                            horizontal: 8, vertical: 6),
                        child: pw.Row(
                          children: [
                            pw.Expanded(
                              flex: 4,
                              child: pw.Text('Lugar',
                                  style: pw.TextStyle(
                                      font: boldFont,
                                      fontSize: 9,
                                      color: textMuted)),
                            ),
                            pw.Expanded(
                              flex: 2,
                              child: pw.Text('Tipo',
                                  style: pw.TextStyle(
                                      font: boldFont,
                                      fontSize: 9,
                                      color: textMuted)),
                            ),
                            pw.Expanded(
                              flex: 2,
                              child: pw.Text('Horario',
                                  style: pw.TextStyle(
                                      font: boldFont,
                                      fontSize: 9,
                                      color: textMuted)),
                            ),
                            pw.Expanded(
                              flex: 2,
                              child: pw.Text('Tiempo',
                                  style: pw.TextStyle(
                                      font: boldFont,
                                      fontSize: 9,
                                      color: textMuted)),
                            ),
                            pw.SizedBox(
                              width: 60,
                              child: pw.Text(
                                'Costo est.',
                                style: pw.TextStyle(
                                    font: boldFont,
                                    fontSize: 9,
                                    color: textMuted),
                                textAlign: pw.TextAlign.right,
                              ),
                            ),
                          ],
                        ),
                      ),
                      pw.Divider(color: divider, height: 1),

                      // Table rows
                      ...dayPlaces.asMap().entries.map((entry) {
                        final idx = entry.key;
                        final p = entry.value;
                        final rowBg = idx.isOdd
                            ? PdfColors.white
                            : const PdfColor.fromInt(0xFFFAFAFA);
                        final tColor = _typeColor(p.tipo);
                        final mins = p.tiempoEstimadoMin;
                        final timeLabel = mins >= 60
                            ? '${mins ~/ 60}h${mins % 60 > 0 ? " ${mins % 60}m" : ""}'
                            : '${mins}min';

                        return pw.Container(
                          color: rowBg,
                          padding: const pw.EdgeInsets.symmetric(
                              horizontal: 8, vertical: 5),
                          child: pw.Row(
                            children: [
                              // Color strip + nombre
                              pw.Expanded(
                                flex: 4,
                                child: pw.Row(
                                  children: [
                                    pw.Container(
                                      width: 3,
                                      height: 20,
                                      color: tColor,
                                    ),
                                    pw.SizedBox(width: 6),
                                    pw.Expanded(
                                      child: pw.Text(
                                        '${_typeEmoji(p.tipo)} ${p.nombre}',
                                        style: pw.TextStyle(
                                          font: bodyFont,
                                          fontSize: 9,
                                          color: textMain,
                                        ),
                                        maxLines: 2,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              pw.Expanded(
                                flex: 2,
                                child: pw.Text(
                                  PlaceType.label(p.tipo),
                                  style: pw.TextStyle(
                                    font: bodyFont,
                                    fontSize: 8,
                                    color: tColor,
                                  ),
                                ),
                              ),
                              pw.Expanded(
                                flex: 2,
                                child: pw.Text(
                                  p.horario.isNotEmpty ? p.horario : '—',
                                  style: pw.TextStyle(
                                    font: bodyFont,
                                    fontSize: 8,
                                    color: textMuted,
                                  ),
                                ),
                              ),
                              pw.Expanded(
                                flex: 2,
                                child: pw.Text(
                                  timeLabel,
                                  style: pw.TextStyle(
                                    font: bodyFont,
                                    fontSize: 8,
                                    color: textMuted,
                                  ),
                                ),
                              ),
                              pw.SizedBox(
                                width: 60,
                                child: pw.Text(
                                  p.costoEstimado > 0
                                      ? compactFmt.format(p.costoEstimado)
                                      : '—',
                                  style: pw.TextStyle(
                                    font: bodyFont,
                                    fontSize: 8,
                                    color: textMuted,
                                  ),
                                  textAlign: pw.TextAlign.right,
                                ),
                              ),
                            ],
                          ),
                        );
                      }),

                      pw.Divider(color: divider, height: 1),

                      // Day subtotal
                      pw.Container(
                        color: const PdfColor.fromInt(0xFFE3F2FD),
                        padding: const pw.EdgeInsets.symmetric(
                            horizontal: 8, vertical: 6),
                        child: pw.Row(
                          mainAxisAlignment:
                              pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text(
                              'Subtotal del día  ·  $dayTime',
                              style: pw.TextStyle(
                                font: boldFont,
                                fontSize: 9,
                                color: primaryDark,
                              ),
                            ),
                            pw.Text(
                              dayCost > 0
                                  ? '${trip.moneda} ${currFmt.format(dayCost)}'
                                  : '—',
                              style: pw.TextStyle(
                                font: boldFont,
                                fontSize: 9,
                                color: primaryDark,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    // Comments per place (below table)
                    ..._commentsSection(dayPlaces, bodyFont, boldFont,
                        textMain, textMuted, divider),
                  ],
                ),
              ),
            ),
            pageFooter(ctx),
          ],
        ),
      ),
    );
  }

  // ── SUMMARY PAGE ──────────────────────────────────────────────────────────
  final totalHrs = totalMinutos ~/ 60;
  final totalMin = totalMinutos % 60;
  final totalTimeLabel =
      '${totalHrs}h${totalMin > 0 ? " ${totalMin}min" : ""}';

  pdf.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: pw.EdgeInsets.zero,
      build: (ctx) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          pageHeader(),
          pw.Expanded(
            child: pw.Padding(
              padding: const pw.EdgeInsets.fromLTRB(24, 16, 24, 8),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // Section title
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: pw.BoxDecoration(
                      color: const PdfColor.fromInt(0xFF2E7D32),
                      borderRadius: pw.BorderRadius.circular(8),
                    ),
                    child: pw.Text(
                      '📊  Resumen del Viaje',
                      style: pw.TextStyle(
                        font: boldFont,
                        fontSize: 13,
                        color: PdfColors.white,
                      ),
                    ),
                  ),
                  pw.SizedBox(height: 20),

                  // Key metrics row
                  pw.Row(
                    children: [
                      _MetricBox(
                        label: 'Tiempo total',
                        value: totalTimeLabel,
                        bodyFont: bodyFont,
                        boldFont: boldFont,
                      ),
                      pw.SizedBox(width: 12),
                      _MetricBox(
                        label: 'Lugares',
                        value: '${places.length}',
                        bodyFont: bodyFont,
                        boldFont: boldFont,
                      ),
                      pw.SizedBox(width: 12),
                      _MetricBox(
                        label: 'Personas',
                        value: '${trip.numeroPersonas}',
                        bodyFont: bodyFont,
                        boldFont: boldFont,
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 20),

                  // Budget comparison
                  pw.Text(
                    'Presupuesto',
                    style: pw.TextStyle(
                      font: boldFont,
                      fontSize: 11,
                      color: textMain,
                    ),
                  ),
                  pw.SizedBox(height: 8),
                  _BudgetRow(
                    label: 'Presupuesto total',
                    value: trip.presupuestoTotal > 0
                        ? '${trip.moneda} ${currFmt.format(trip.presupuestoTotal)}'
                        : 'No definido',
                    bodyFont: bodyFont,
                    boldFont: boldFont,
                    highlight: false,
                  ),
                  _BudgetRow(
                    label: 'Costo estimado total',
                    value:
                        '${trip.moneda} ${currFmt.format(totalEstimado)}',
                    bodyFont: bodyFont,
                    boldFont: boldFont,
                    highlight: true,
                  ),
                  _BudgetRow(
                    label: 'Costo estimado por persona',
                    value: trip.numeroPersonas > 0
                        ? '${trip.moneda} ${currFmt.format(totalEstimado / trip.numeroPersonas)}'
                        : '—',
                    bodyFont: bodyFont,
                    boldFont: boldFont,
                    highlight: false,
                  ),
                  if (trip.presupuestoTotal > 0) ...[
                    _BudgetRow(
                      label: 'Diferencia (presupuesto − estimado)',
                      value:
                          '${trip.moneda} ${currFmt.format(trip.presupuestoTotal - totalEstimado)}',
                      bodyFont: bodyFont,
                      boldFont: boldFont,
                      highlight: false,
                      valueColor: trip.presupuestoTotal >= totalEstimado
                          ? const PdfColor.fromInt(0xFF2E7D32)
                          : const PdfColor.fromInt(0xFFB71C1C),
                    ),
                  ],

                  pw.SizedBox(height: 20),

                  // Category breakdown
                  pw.Text(
                    'Desglose por categoría',
                    style: pw.TextStyle(
                      font: boldFont,
                      fontSize: 11,
                      color: textMain,
                    ),
                  ),
                  pw.SizedBox(height: 8),
                  ...CostCategory.all
                      .where((cat) =>
                          (categoryTotals[cat] ?? 0) > 0)
                      .map((cat) => _BudgetRow(
                            label:
                                '${_catEmoji(cat)}  ${CostCategory.label(cat)}',
                            value:
                                '${trip.moneda} ${currFmt.format(categoryTotals[cat]!)}',
                            bodyFont: bodyFont,
                            boldFont: boldFont,
                            highlight: false,
                          )),
                ],
              ),
            ),
          ),
          pageFooter(ctx),
        ],
      ),
    ),
  );

  return Uint8List.fromList(await pdf.save());
}

// ── Helper widgets ─────────────────────────────────────────────────────────────

pw.Widget _InfoRow({
  required String icon,
  required String label,
  required String value,
  required pw.Font bodyFont,
  required pw.Font boldFont,
}) {
  const textMuted = PdfColor.fromInt(0xFF757575);
  const textMain = PdfColor.fromInt(0xFF212121);
  return pw.Row(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.SizedBox(
        width: 100,
        child: pw.Text(
          '$icon  $label',
          style: pw.TextStyle(font: boldFont, fontSize: 10, color: textMuted),
        ),
      ),
      pw.Expanded(
        child: pw.Text(
          value,
          style: pw.TextStyle(font: bodyFont, fontSize: 10, color: textMain),
        ),
      ),
    ],
  );
}

pw.Widget _MetricBox({
  required String label,
  required String value,
  required pw.Font bodyFont,
  required pw.Font boldFont,
}) {
  const primary = PdfColor.fromInt(0xFF1976D2);
  const bgLight = PdfColor.fromInt(0xFFE3F2FD);
  return pw.Expanded(
    child: pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: pw.BoxDecoration(
        color: bgLight,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        children: [
          pw.Text(
            value,
            style: pw.TextStyle(font: boldFont, fontSize: 16, color: primary),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            label,
            style:
                pw.TextStyle(font: bodyFont, fontSize: 8, color: primary),
          ),
        ],
      ),
    ),
  );
}

pw.Widget _BudgetRow({
  required String label,
  required String value,
  required pw.Font bodyFont,
  required pw.Font boldFont,
  required bool highlight,
  PdfColor? valueColor,
}) {
  const bgLight = PdfColor.fromInt(0xFFF5F5F5);
  const bgHighlight = PdfColor.fromInt(0xFFE3F2FD);
  const textMain = PdfColor.fromInt(0xFF212121);
  const primary = PdfColor.fromInt(0xFF1976D2);
  const divider = PdfColor.fromInt(0xFFE0E0E0);

  return pw.Container(
    decoration: pw.BoxDecoration(
      color: highlight ? bgHighlight : bgLight,
      border: const pw.Border(
        bottom: pw.BorderSide(color: divider, width: 0.5),
      ),
    ),
    padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    child: pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(
            font: highlight ? boldFont : bodyFont,
            fontSize: 9,
            color: textMain,
          ),
        ),
        pw.Text(
          value,
          style: pw.TextStyle(
            font: boldFont,
            fontSize: 9,
            color: valueColor ?? (highlight ? primary : textMain),
          ),
        ),
      ],
    ),
  );
}

List<pw.Widget> _commentsSection(
  List<PlaceModel> places,
  pw.Font bodyFont,
  pw.Font boldFont,
  PdfColor textMain,
  PdfColor textMuted,
  PdfColor divider,
) {
  final withComments =
      places.where((p) => p.comentarios.isNotEmpty).toList();
  if (withComments.isEmpty) return [];
  return [
    pw.SizedBox(height: 14),
    pw.Text('Notas',
        style:
            pw.TextStyle(font: boldFont, fontSize: 9, color: textMuted)),
    pw.SizedBox(height: 4),
    ...withComments.map(
      (p) => pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 4),
        child: pw.RichText(
          text: pw.TextSpan(
            children: [
              pw.TextSpan(
                text: '${p.nombre}: ',
                style: pw.TextStyle(
                    font: boldFont, fontSize: 8, color: textMain),
              ),
              pw.TextSpan(
                text: p.comentarios,
                style: pw.TextStyle(
                    font: bodyFont, fontSize: 8, color: textMuted),
              ),
            ],
          ),
        ),
      ),
    ),
  ];
}

// ── Helpers ────────────────────────────────────────────────────────────────────

String _capitalize(String s) =>
    s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

String _catEmoji(String cat) => switch (cat) {
      CostCategory.accommodation => '🏨',
      CostCategory.food => '🍽️',
      CostCategory.transport => '🚌',
      CostCategory.activities => '🎭',
      CostCategory.shopping => '🛍️',
      CostCategory.health => '💊',
      _ => '📋',
    };
