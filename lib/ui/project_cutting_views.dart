import 'package:flutter/material.dart';

import '../l10n/gen/app_localizations.dart';
import '../logic/bar_cutting.dart';
import '../logic/project_cutting.dart';
import '../logic/units.dart';
import 'theme.dart';

/// Nom affiché d'une pièce de projet.
String pieceNameLabel(AppLocalizations pText, PieceName pName) => switch (pName) {
  PieceName.stile => pText.cutPieceStile,
  PieceName.rail => pText.cutPieceRail,
  PieceName.bead => pText.cutPieceBead,
  PieceName.side => pText.cutPieceSide,
  PieceName.shelf => pText.cutPieceShelf,
  PieceName.back => pText.cutPieceBack,
  PieceName.joist => pText.cutPieceJoist,
  PieceName.ledger => pText.cutPieceLedger,
  PieceName.post => pText.cutPiecePost,
  PieceName.eavesSide => pText.cutPieceEavesSide,
  PieceName.eavesFloor => pText.cutPieceEavesFloor,
  PieceName.door => pText.cutPieceDoor,
  PieceName.custom => pText.cutPieceCustom,
};

/// Une barre du commerce vue de dessus : morceaux numérotés, traits de scie, chute au bout.
class BarCutStrip extends StatelessWidget {
  const BarCutStrip({super.key, required this.bar, required this.kerfMm, required this.label});

  final CutBar bar;
  final int kerfMm;

  /// Numéro affiché sur le morceau de rang donné dans la barre.
  final String Function(int pPosition) label;

  @override
  Widget build(BuildContext context) {
    final vTheme = Theme.of(context);
    final vText = AppLocalizations.of(context);

    return Semantics(
      label: vText.cutPlanBarLabel(formatCentimetres(bar.barMm)),
      child: SizedBox(
        height: 34,
        child: CustomPaint(
          painter: _BarPainter(
            bar: bar,
            kerfMm: kerfMm,
            label: label,
            colors: AtelierColors.of(context),
            style: vTheme.textTheme.labelSmall!,
          ),
        ),
      ),
    );
  }
}

class _BarPainter extends CustomPainter {
  _BarPainter({
    required this.bar,
    required this.kerfMm,
    required this.label,
    required this.colors,
    required this.style,
  });

  final CutBar bar;
  final int kerfMm;
  final String Function(int pPosition) label;
  final AtelierColors colors;
  final TextStyle style;

  @override
  void paint(Canvas pCanvas, Size pSize) {
    final vScale = pSize.width / bar.barMm;
    final vStroke = Paint()
      ..color = colors.ink
      ..style = PaintingStyle.stroke;
    final vWhole = Offset.zero & pSize;
    // Le fond quadrillé est la chute : ce qui n'est pas taillé
    pCanvas.drawRect(vWhole, Paint()..color = colors.grid);
    var vX = 0.0;
    for (var vPosition = 0; vPosition < bar.pieceLengths.length; vPosition++) {
      final vRect = Rect.fromLTWH(vX, 0, bar.pieceLengths[vPosition] * vScale, pSize.height);
      pCanvas
        ..drawRect(vRect, Paint()..color = colors.wood)
        ..drawRect(vRect, vStroke);
      final vText = TextPainter(
        text: TextSpan(text: label(vPosition), style: style.copyWith(color: colors.ink)),
        textDirection: TextDirection.ltr,
      )..layout();
      if (vText.width < vRect.width) {
        vText.paint(pCanvas, vRect.center - Offset(vText.width / 2, vText.height / 2));
      }
      vX = vRect.right;
      // Trait de scie élargi pour rester visible à l'échelle d'une barre de plusieurs mètres
      final vKerf = Rect.fromLTWH(vX, 0, (kerfMm * vScale).clamp(2.0, 6.0), pSize.height);
      if (vKerf.left < pSize.width) {
        pCanvas.drawRect(vKerf, Paint()..color = colors.tape);
      }
      vX += kerfMm * vScale;
    }
    pCanvas.drawRect(vWhole, vStroke);
  }

  @override
  bool shouldRepaint(_BarPainter pOld) => pOld.bar != bar || pOld.kerfMm != kerfMm;
}

/// Saisie d'une pièce libre : barre ou panneau, dimensions et nombre.
class ProjectPieceDialog extends StatefulWidget {
  const ProjectPieceDialog({super.key});

  @override
  State<ProjectPieceDialog> createState() => _ProjectPieceDialogState();
}

class _ProjectPieceDialogState extends State<ProjectPieceDialog> {
  final _length = TextEditingController();
  final _width = TextEditingController();
  final _thickness = TextEditingController(text: '18');
  final _count = TextEditingController(text: '1');
  var _kind = StockKind.panel;
  String? _error;

  @override
  void dispose() {
    _length.dispose();
    _width.dispose();
    _thickness.dispose();
    _count.dispose();
    super.dispose();
  }

  void _submit() {
    final vLength = parseCentimetres(_length.text);
    // Une barre se décrit par sa section en millimètres, un panneau par sa largeur en cm
    final vWidth = _kind == StockKind.bar ? parseWhole(_width.text) : parseCentimetres(_width.text);
    final vThickness = parseWhole(_thickness.text);
    final vCount = parseWhole(_count.text);
    if (vLength == null ||
        vLength == 0 ||
        vWidth == null ||
        vWidth == 0 ||
        vThickness == null ||
        vThickness == 0 ||
        vCount == null ||
        vCount == 0) {
      setState(() => _error = AppLocalizations.of(context).invalidLength);
      return;
    }
    Navigator.pop<ProjectPiece>(context, (
      name: PieceName.custom,
      kind: _kind,
      lengthMm: vLength,
      widthMm: vWidth,
      thicknessMm: vThickness,
      count: vCount,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final vText = AppLocalizations.of(context);
    const vNumbers = TextInputType.numberWithOptions(decimal: true);
    final vBar = _kind == StockKind.bar;

    return AlertDialog(
      title: Text(vText.panelAddPart),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SegmentedButton<StockKind>(
              segments: [
                ButtonSegment(value: StockKind.panel, label: Text(vText.cutPlanKindPanel)),
                ButtonSegment(value: StockKind.bar, label: Text(vText.cutPlanKindBar)),
              ],
              selected: {_kind},
              onSelectionChanged: (pKinds) => setState(() => _kind = pKinds.first),
            ),
            TextField(
              controller: _length,
              autofocus: true,
              keyboardType: vNumbers,
              decoration: InputDecoration(
                labelText: vText.panelPartLength,
                suffixText: vText.unitCm,
                errorText: _error,
              ),
            ),
            TextField(
              controller: _width,
              keyboardType: vNumbers,
              decoration: InputDecoration(
                labelText: vBar ? vText.cutPlanSectionWidth : vText.panelPartWidth,
                suffixText: vBar ? vText.unitMm : vText.unitCm,
              ),
            ),
            TextField(
              controller: _thickness,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: vText.cutPlanThickness,
                suffixText: vText.unitMm,
              ),
            ),
            TextField(
              controller: _count,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: vText.panelPartCount),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(vText.cancel)),
        FilledButton(onPressed: _submit, child: Text(vText.save)),
      ],
    );
  }
}
