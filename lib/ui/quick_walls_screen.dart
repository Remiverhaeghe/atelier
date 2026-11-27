import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../l10n/gen/app_localizations.dart';
import '../logic/auto_corners.dart';
import '../logic/geometry.dart';
import '../logic/room.dart';
import '../logic/units.dart';
import 'dialogs.dart' show formatAngle;
import 'room_measure_picker.dart' show unitName;
import 'room_plan.dart';
import 'theme.dart';

/// Tous les murs de la pièce sur un seul écran : une ligne par mur, le plan qui se dessine à
/// mesure, et la pièce rectangulaire en deux cotes. Renvoie les murs, ou null si on annule.
Future<List<Wall>?> editAllWalls(BuildContext pContext, Room pRoom) => Navigator.push(
  pContext,
  MaterialPageRoute<List<Wall>>(builder: (_) => QuickWallsScreen(room: pRoom)),
);

/// Coin le plus courant : rentrant d'équerre, ou sortant d'équerre.
const insideCornerDeg = 90.0;
const outsideCornerDeg = 270.0;

/// Murs d'une pièce rectangulaire de [pLengthMm] sur [pWidthMm], dans l'ordre du tour.
List<Wall> rectangleWalls(int pLengthMm, int pWidthMm) => [
  Wall(lengthMm: pLengthMm),
  Wall(lengthMm: pWidthMm),
  Wall(lengthMm: pLengthMm),
  Wall(lengthMm: pWidthMm),
];

class QuickWallsScreen extends StatefulWidget {
  const QuickWallsScreen({super.key, required this.room});

  final Room room;

  @override
  State<QuickWallsScreen> createState() => _QuickWallsScreenState();
}

/// Unités proposées pour taper les longueurs des murs.
const wallUnits = [FieldUnit.cm, FieldUnit.m, FieldUnit.mm];

class _Row {
  _Row(this.wall, FieldUnit pUnit)
    : length = TextEditingController(
        text: wall.lengthMm == 0 ? '' : lengthInUnit(wall.lengthMm, pUnit),
      ),
      angle = TextEditingController(text: formatAngle(wall.angleToNextDeg)),
      autoAngleText = wall.angleAuto ? formatAngle(wall.angleToNextDeg) : null;

  /// Mur d'origine : ses ouvertures et son bout libre sont gardés.
  final Wall wall;
  final TextEditingController length;
  final TextEditingController angle;

  /// Angle tel que l'appli l'a calculé : tant que le champ n'a pas bougé, il reste automatique.
  final String? autoAngleText;

  void dispose() {
    length.dispose();
    angle.dispose();
  }
}

class _QuickWallsScreenState extends State<QuickWallsScreen> {
  var _unit = FieldUnit.cm;
  late final List<_Row> _rows = [
    for (final vWall in widget.room.walls) _Row(vWall, _unit),
    if (widget.room.walls.isEmpty) _Row(const Wall(lengthMm: 0), _unit),
  ];

  int? _length(_Row pRow) => parseInUnit(pRow.length.text, _unit);

  /// Change d'unité en réécrivant les longueurs déjà tapées.
  void _switchUnit(FieldUnit pUnit) => setState(() {
    for (final vRow in _rows) {
      final vLength = _length(vRow);
      if (vLength != null) {
        vRow.length.text = lengthInUnit(vLength, pUnit);
      }
    }
    _unit = pUnit;
  });

  @override
  void dispose() {
    for (final vRow in _rows) {
      vRow.dispose();
    }
    super.dispose();
  }

  /// Murs lisibles des lignes ; une ligne vide ou fausse est laissée de côté.
  List<Wall> _typedWalls() => [
    for (final vRow in _rows)
      if (_length(vRow) case final int vLength when vLength > 0)
        vRow.wall.copyWith(
          lengthMm: vLength,
          angleToNextDeg: parseDegrees(vRow.angle.text) ?? insideCornerDeg,
          angleAuto: vRow.autoAngleText != null && vRow.angle.text == vRow.autoAngleText,
        ),
  ];

  bool get _complete =>
      _rows.every((pRow) => (_length(pRow) ?? 0) > 0 && parseDegrees(pRow.angle.text) != null);

  void _setRows(List<Wall> pWalls) => setState(() {
    for (final vRow in _rows) {
      vRow.dispose();
    }
    _rows
      ..clear()
      ..addAll(pWalls.map((pWall) => _Row(pWall, _unit)));
  });

  Future<void> _rectangle() async {
    final vSize = await showDialog<(int, int)>(
      context: context,
      builder: (_) => const _RectangleDialog(),
    );
    if (vSize != null) {
      _setRows(rectangleWalls(vSize.$1, vSize.$2));
    }
  }

  String _fittedSummary(List<Wall> pWalls) =>
      pWalls.map((pWall) => '${formatAngle(pWall.angleToNextDeg)}°').join(' · ');

  /// Variation maximale d'un angle quand les longueurs sont fausses de la précision supposée.
  String _fittedMargin(List<Wall> pWalls) {
    final vSpread = cornerUncertainty([for (final vWall in pWalls) vWall.lengthMm]);

    return formatAngle(vSpread == null ? 0.0 : vSpread.reduce(math.max));
  }

  @override
  Widget build(BuildContext context) {
    final vText = AppLocalizations.of(context);
    final vTheme = Theme.of(context);
    final vTyped = _typedWalls();
    final vWalls = withFittedCorners(vTyped);
    final vFitted = !identical(vWalls, vTyped);
    final vRoom = widget.room.copyWith(walls: vWalls, closed: true);
    final vDrawable = vWalls.length >= 2;

    return Scaffold(
      appBar: AppBar(
        title: Text(vText.quickWallsTitle),
        actions: [
          TextButton(
            onPressed: _complete && vWalls.length >= 3
                ? () => Navigator.pop(context, vWalls)
                : null,
            child: Text(vText.save),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          Text(vText.quickWallsHelp, style: vTheme.textTheme.bodyMedium),
          const SizedBox(height: 8),
          if (vDrawable)
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: SizedBox(
                key: ValueKey(vWalls.length),
                height: 220,
                child: RoomPlan(room: vRoom),
              ),
            ),
          if (vWalls.length >= 3)
            IconLine(
              closesProperly(vRoom) ? Icons.check_circle_outline : Icons.error_outline,
              closesProperly(vRoom)
                  ? vText.closureOk
                  : vText.closureGap(formatCentimetres(closureGapMm(vRoom).round())),
              color: closesProperly(vRoom) ? null : vTheme.colorScheme.error,
            ),
          if (vFitted)
            IconLine(
              Icons.auto_fix_high,
              vText.cornersFitted(
                _fittedSummary(vWalls),
                formatCentimetres(measureToleranceMm),
                _fittedMargin(vWalls),
              ),
            ),
          const SizedBox(height: 8),
          SegmentedButton<FieldUnit>(
            segments: [
              for (final vUnit in wallUnits)
                ButtonSegment(value: vUnit, label: Text(unitName(vText, vUnit))),
            ],
            selected: {_unit},
            onSelectionChanged: (pUnit) => _switchUnit(pUnit.single),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _rectangle,
            icon: const Icon(Icons.crop_square),
            label: Text(vText.quickRectangle),
          ),
          for (final (vIndex, vRow) in _rows.indexed)
            _WallRow(
              key: ObjectKey(vRow),
              number: vIndex + 1,
              row: vRow,
              unit: _unit,
              onChanged: () => setState(() {}),
              onRemove: _rows.length > 1
                  ? () => setState(() => _rows.removeAt(vIndex).dispose())
                  : null,
            ),
          const SizedBox(height: 8),
          FilledButton.tonalIcon(
            onPressed: () => setState(() => _rows.add(_Row(const Wall(lengthMm: 0), _unit))),
            icon: const Icon(Icons.add),
            label: Text(vText.addWall),
          ),
        ],
      ),
    );
  }
}

class _WallRow extends StatelessWidget {
  const _WallRow({
    super.key,
    required this.number,
    required this.row,
    required this.unit,
    required this.onChanged,
    this.onRemove,
  });

  final int number;
  final _Row row;
  final FieldUnit unit;
  final VoidCallback onChanged;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final vText = AppLocalizations.of(context);
    final vAngle = parseDegrees(row.angle.text);
    final vKind = vAngle == insideCornerDeg
        ? insideCornerDeg
        : vAngle == outsideCornerDeg
        ? outsideCornerDeg
        : null;

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: row.length,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: vText.wallTitle(number),
                    suffixText: unitName(vText, unit),
                    errorText:
                        row.length.text.isNotEmpty && parseInUnit(row.length.text, unit) == null
                        ? vText.invalidLength
                        : null,
                  ),
                  onChanged: (_) => onChanged(),
                ),
              ),
              if (onRemove != null)
                IconButton(
                  tooltip: vText.quickRemoveWall,
                  icon: const Icon(Icons.remove_circle_outline),
                  onPressed: onRemove,
                ),
            ],
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              ChoiceChip(
                label: Text(vText.quickCornerInside),
                selected: vKind == insideCornerDeg,
                onSelected: (_) {
                  row.angle.text = formatAngle(insideCornerDeg);
                  onChanged();
                },
              ),
              ChoiceChip(
                label: Text(vText.quickCornerOutside),
                selected: vKind == outsideCornerDeg,
                onSelected: (_) {
                  row.angle.text = formatAngle(outsideCornerDeg);
                  onChanged();
                },
              ),
              SizedBox(
                width: 110,
                child: TextField(
                  controller: row.angle,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    isDense: true,
                    labelText: vText.quickCornerOther,
                    suffixText: '°',
                    errorText: vAngle == null ? vText.invalidAngle : null,
                  ),
                  onChanged: (_) => onChanged(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RectangleDialog extends StatefulWidget {
  const _RectangleDialog();

  @override
  State<_RectangleDialog> createState() => _RectangleDialogState();
}

class _RectangleDialogState extends State<_RectangleDialog> {
  final _length = TextEditingController();
  final _width = TextEditingController();

  @override
  void dispose() {
    _length.dispose();
    _width.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vText = AppLocalizations.of(context);
    final vLength = parseCentimetres(_length.text);
    final vWidth = parseCentimetres(_width.text);
    final vValid = (vLength ?? 0) > 0 && (vWidth ?? 0) > 0;

    return AlertDialog(
      title: Text(vText.quickRectangle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _length,
            autofocus: true,
            decoration: InputDecoration(labelText: vText.quickRectLength, suffixText: vText.unitCm),
            onChanged: (_) => setState(() {}),
          ),
          TextField(
            controller: _width,
            decoration: InputDecoration(labelText: vText.quickRectWidth, suffixText: vText.unitCm),
            onChanged: (_) => setState(() {}),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(vText.cancel)),
        FilledButton(
          onPressed: vValid ? () => Navigator.pop(context, (vLength!, vWidth!)) : null,
          child: Text(vText.save),
        ),
      ],
    );
  }
}
