import 'package:flutter/material.dart';

import '../l10n/gen/app_localizations.dart';
import '../logic/room.dart';
import '../logic/slope.dart';
import '../logic/units.dart';
import 'parquet_view.dart';
import 'theme.dart';

/// Plafond rampant : un ou deux pans, chacun avec son mur bas, sa jambette et sa largeur.
class SlopeEditor extends StatelessWidget {
  const SlopeEditor({super.key, required this.room, required this.onChanged});

  final Room room;
  final ValueChanged<Room> onChanged;

  Slope _newSlope(int pWallIndex) =>
      Slope(wallIndex: pWallIndex, lowMm: (room.ceilingHeightMm * 0.4).round(), runMm: 2000);

  @override
  Widget build(BuildContext context) {
    final vText = AppLocalizations.of(context);
    final vSlope = room.slope;
    final vSlope2 = room.slope2;
    // Le second pan part par défaut du mur d'en face, deux murs plus loin
    final vOpposite = room.walls.isEmpty ? 0 : ((vSlope?.wallIndex ?? 0) + 2) % room.walls.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          secondary: const Icon(Icons.roofing_outlined),
          title: Text(vText.slopeSwitch),
          value: vSlope != null,
          onChanged: (pOn) => onChanged(
            pOn
                ? room.copyWith(slope: _newSlope(0))
                : room.copyWith(clearSlope: true, clearSlope2: true),
          ),
        ),
        if (vSlope != null) ...[
          const _SlopeSketch(),
          IconLine(Icons.straighten, vText.slopeHowTo),
          _PanEditor(
            key: const ValueKey('pan1'),
            room: room,
            slope: vSlope,
            onChanged: (pSlope) => onChanged(room.copyWith(slope: pSlope)),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            secondary: const Icon(Icons.change_history_outlined),
            title: Text(vText.slopeSecond),
            value: vSlope2 != null,
            onChanged: (pOn) => onChanged(
              pOn
                  ? room.copyWith(slope2: _newSlope(vOpposite))
                  : room.copyWith(clearSlope2: true),
            ),
          ),
          if (vSlope2 != null)
            _PanEditor(
              key: const ValueKey('pan2'),
              room: room,
              slope: vSlope2,
              onChanged: (pSlope) => onChanged(room.copyWith(slope2: pSlope)),
            ),
          if (activeSlopes(room).length < [vSlope, vSlope2].nonNulls.length)
            IconLine(AtelierIcons.warning, vText.slopeInvalid)
          else
            IconLine(
              Icons.accessibility_new,
              vText.slopeStanding(formatSquareMetres(standingFloorMm2(room) / 1e6)),
            ),
        ],
      ],
    );
  }
}

/// Un pan : mur bas, jambette, puis largeur au sol ou longueur du rampant.
class _PanEditor extends StatefulWidget {
  const _PanEditor({super.key, required this.room, required this.slope, required this.onChanged});

  final Room room;
  final Slope slope;
  final ValueChanged<Slope> onChanged;

  @override
  State<_PanEditor> createState() => _PanEditorState();
}

class _PanEditorState extends State<_PanEditor> {
  /// Saisie par la longueur mesurée le long du plafond plutôt qu'au sol.
  bool _byRafter = false;
  int? _rafterMm;

  Slope get _slope => widget.slope;

  void _setRafter(int pRafterMm) {
    setState(() => _rafterMm = pRafterMm);
    final vRun = runFromRafter(
      pRafterMm: pRafterMm,
      pLowMm: _slope.lowMm,
      pHighMm: widget.room.ceilingHeightMm,
    );
    if (vRun != null) {
      widget.onChanged(Slope(wallIndex: _slope.wallIndex, lowMm: _slope.lowMm, runMm: vRun));
    }
  }

  @override
  Widget build(BuildContext context) {
    final vText = AppLocalizations.of(context);
    final vRoom = widget.room;
    final vRafter = _rafterMm;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DropdownButtonFormField<int>(
          initialValue: _slope.wallIndex.clamp(0, vRoom.walls.length - 1),
          decoration: InputDecoration(labelText: vText.slopeWall),
          items: [
            for (var vIndex = 0; vIndex < vRoom.walls.length; vIndex++)
              DropdownMenuItem(value: vIndex, child: Text(vText.wallTitle(vIndex + 1))),
          ],
          onChanged: (pIndex) => widget.onChanged(
            Slope(wallIndex: pIndex!, lowMm: _slope.lowMm, runMm: _slope.runMm),
          ),
        ),
        NumberField<int>(
          label: vText.slopeLow,
          initial: formatCentimetres(_slope.lowMm),
          parse: parseCentimetres,
          onValue: (pValue) => widget.onChanged(
            Slope(wallIndex: _slope.wallIndex, lowMm: pValue, runMm: _slope.runMm),
          ),
        ),
        const SizedBox(height: 10),
        SegmentedButton<bool>(
          segments: [
            ButtonSegment(value: false, label: Text(vText.slopeByFloor)),
            ButtonSegment(value: true, label: Text(vText.slopeByRafter)),
          ],
          selected: {_byRafter},
          onSelectionChanged: (pChoice) => setState(() => _byRafter = pChoice.single),
        ),
        if (!_byRafter)
          NumberField<int>(
            key: const ValueKey('run'),
            label: vText.slopeRun,
            initial: formatCentimetres(_slope.runMm),
            parse: parseCentimetres,
            onValue: (pValue) => widget.onChanged(
              Slope(wallIndex: _slope.wallIndex, lowMm: _slope.lowMm, runMm: pValue),
            ),
          )
        else ...[
          NumberField<int>(
            key: const ValueKey('rafter'),
            label: vText.slopeRafter,
            initial: vRafter == null ? '' : formatCentimetres(vRafter),
            parse: parseCentimetres,
            onValue: _setRafter,
          ),
          if (vRafter != null)
            switch (runFromRafter(
              pRafterMm: vRafter,
              pLowMm: _slope.lowMm,
              pHighMm: vRoom.ceilingHeightMm,
            )) {
              final int vRun => IconLine(
                Icons.calculate_outlined,
                vText.slopeRunComputed(formatCentimetres(vRun)),
              ),
              null => IconLine(AtelierIcons.warning, vText.slopeRafterTooShort),
            },
        ],
      ],
    );
  }
}

/// Coupe d'un comble : où se prennent la jambette, la largeur au sol et le rampant.
class _SlopeSketch extends StatelessWidget {
  const _SlopeSketch();

  @override
  Widget build(BuildContext context) {
    final vText = AppLocalizations.of(context);
    final vColors = AtelierColors.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: AspectRatio(
        aspectRatio: 2.2,
        child: CustomPaint(
          painter: _SketchPainter(
            ink: vColors.ink,
            tape: vColors.tape,
            style: Theme.of(context).textTheme.labelSmall!.copyWith(color: vColors.ink),
            low: vText.slopeSketchLow,
            run: vText.slopeSketchRun,
            rafter: vText.slopeSketchRafter,
          ),
        ),
      ),
    );
  }
}

class _SketchPainter extends CustomPainter {
  _SketchPainter({
    required this.ink,
    required this.tape,
    required this.style,
    required this.low,
    required this.run,
    required this.rafter,
  });

  final Color ink;
  final Color tape;
  final TextStyle style;
  final String low;
  final String run;
  final String rafter;

  void _label(Canvas pCanvas, String pText, Offset pAt) {
    final vPainter = TextPainter(
      text: TextSpan(text: pText, style: style),
      textDirection: TextDirection.ltr,
    )..layout();
    vPainter.paint(pCanvas, pAt - Offset(vPainter.width / 2, vPainter.height / 2));
  }

  @override
  void paint(Canvas pCanvas, Size pSize) {
    final vW = pSize.width;
    final vH = pSize.height;
    final vWall = Paint()
      ..color = ink
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    final vMeasure = Paint()
      ..color = tape
      ..strokeWidth = 2;
    final vFloorY = vH * 0.88;
    final vKneeX = vW * 0.12;
    final vKneeY = vH * 0.55;
    final vBreakX = vW * 0.55;
    final vCeilY = vH * 0.12;
    // Sol, jambette, rampant, plafond plat
    pCanvas.drawPath(
      Path()
        ..moveTo(vW * 0.95, vFloorY)
        ..lineTo(vKneeX, vFloorY)
        ..lineTo(vKneeX, vKneeY)
        ..lineTo(vBreakX, vCeilY)
        ..lineTo(vW * 0.95, vCeilY),
      vWall,
    );
    // Aplomb de la cassure, en tirets
    for (var vY = vCeilY; vY < vFloorY; vY += 8) {
      pCanvas.drawLine(Offset(vBreakX, vY), Offset(vBreakX, vY + 4), vWall..strokeWidth = 1);
    }
    pCanvas.drawLine(Offset(vKneeX + 6, vFloorY), Offset(vKneeX + 6, vKneeY), vMeasure);
    pCanvas.drawLine(Offset(vKneeX, vFloorY - 6), Offset(vBreakX, vFloorY - 6), vMeasure);
    pCanvas.drawLine(Offset(vKneeX + 4, vKneeY - 6), Offset(vBreakX + 2, vCeilY - 4), vMeasure);
    _label(pCanvas, low, Offset(vKneeX + 30, (vFloorY + vKneeY) / 2));
    _label(pCanvas, run, Offset((vKneeX + vBreakX) / 2, vFloorY - 18));
    _label(pCanvas, rafter, Offset((vKneeX + vBreakX) / 2 - 18, (vKneeY + vCeilY) / 2 - 12));
  }

  @override
  bool shouldRepaint(_SketchPainter pOld) => pOld.ink != ink || pOld.low != low;
}
