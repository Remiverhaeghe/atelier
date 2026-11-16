import 'package:flutter/material.dart';

import '../l10n/gen/app_localizations.dart';
import '../logic/panel_cutting.dart';
import '../logic/units.dart';
import 'parquet_view.dart';
import 'theme.dart';

/// Débit de panneaux : pièces saisies, panneaux à acheter et plan de coupe dessiné.
class PanelCalculator extends StatefulWidget {
  const PanelCalculator({super.key});

  @override
  State<PanelCalculator> createState() => _PanelCalculatorState();
}

class _PanelCalculatorState extends State<PanelCalculator> {
  final _parts = <PanelPart>[
    (lengthMm: 800, widthMm: 400, count: 2),
    (lengthMm: 600, widthMm: 400, count: 3),
  ];
  int _panelLength = 2500;
  int _panelWidth = 1250;
  int _kerf = 3;
  bool _rotate = false;

  Future<void> _addPart() async {
    final vPart = await showDialog<PanelPart>(
      context: context,
      builder: (_) => const _PartDialog(),
    );
    if (vPart != null) {
      setState(() => _parts.add(vPart));
    }
  }

  @override
  Widget build(BuildContext context) {
    final vText = AppLocalizations.of(context);
    final vTheme = Theme.of(context);
    final vPlan = planPanels(_parts, _panelLength, _panelWidth, pKerfMm: _kerf, pRotate: _rotate);
    String vCm(int pMm) => formatCentimetres(pMm);

    return Scaffold(
      appBar: AppBar(title: Text(vText.panelTitle)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addPart,
        icon: const Icon(Icons.add),
        label: Text(vText.panelAddPart),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
        children: [
          Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  BigFigure(vText.panelCount(vPlan.panels.length)),
                  Text(vText.panelWaste((vPlan.wasteShare * 100).round())),
                  if (vPlan.tooBig.isNotEmpty)
                    IconLine(AtelierIcons.warning, vText.panelTooBig(vPlan.tooBig.length)),
                ],
              ),
            ),
          ),
          for (var vIndex = 0; vIndex < vPlan.panels.length; vIndex++) ...[
            const SizedBox(height: 12),
            Text(vText.panelNumber(vIndex + 1), style: vTheme.textTheme.titleSmall),
            const SizedBox(height: 4),
            AspectRatio(
              aspectRatio: _panelLength / _panelWidth,
              child: CustomPaint(
                painter: _PanelPainter(
                  panel: vPlan.panels[vIndex],
                  colors: AtelierColors.of(context),
                  style: vTheme.textTheme.labelSmall!,
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          Text(vText.panelParts, style: vTheme.textTheme.titleMedium),
          for (var vIndex = 0; vIndex < _parts.length; vIndex++)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(radius: 14, child: Text('${vIndex + 1}')),
              title: Text(
                vText.panelPart(
                  _parts[vIndex].count,
                  vCm(_parts[vIndex].lengthMm),
                  vCm(_parts[vIndex].widthMm),
                ),
              ),
              trailing: IconButton(
                tooltip: vText.delete,
                icon: const Icon(Icons.delete_outline),
                onPressed: () => setState(() => _parts.removeAt(vIndex)),
              ),
            ),
          NumberField<int>(
            label: vText.panelLength,
            initial: vCm(_panelLength),
            parse: parseCentimetres,
            onValue: (pValue) => setState(() => _panelLength = pValue),
          ),
          NumberField<int>(
            label: vText.panelWidth,
            initial: vCm(_panelWidth),
            parse: parseCentimetres,
            onValue: (pValue) => setState(() => _panelWidth = pValue),
          ),
          NumberField<int>(
            label: vText.panelKerf,
            initial: '$_kerf',
            parse: parseWhole,
            onValue: (pValue) => setState(() => _kerf = pValue),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(vText.panelRotate),
            subtitle: Text(vText.panelRotateHelp),
            value: _rotate,
            onChanged: (pValue) => setState(() => _rotate = pValue),
          ),
        ],
      ),
    );
  }
}

class _PanelPainter extends CustomPainter {
  _PanelPainter({required this.panel, required this.colors, required this.style});

  final CutPanel panel;
  final AtelierColors colors;
  final TextStyle style;

  @override
  void paint(Canvas pCanvas, Size pSize) {
    final vScale = pSize.width / panel.lengthMm;
    final vStroke = Paint()
      ..color = colors.ink
      ..style = PaintingStyle.stroke;
    pCanvas.drawRect(Offset.zero & pSize, Paint()..color = colors.grid);
    for (final vPart in panel.parts) {
      final vRect = Rect.fromLTWH(
        vPart.xMm * vScale,
        vPart.yMm * vScale,
        vPart.lengthMm * vScale,
        vPart.widthMm * vScale,
      );
      pCanvas.drawRect(vRect, Paint()..color = colors.wood);
      pCanvas.drawRect(vRect, vStroke);
      final vLabel = TextPainter(
        text: TextSpan(
          text: '${vPart.partIndex + 1}',
          style: style.copyWith(color: colors.ink),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      vLabel.paint(pCanvas, vRect.center - Offset(vLabel.width / 2, vLabel.height / 2));
    }
    pCanvas.drawRect(Offset.zero & pSize, vStroke);
  }

  @override
  bool shouldRepaint(_PanelPainter pOld) => pOld.panel != panel;
}

/// Saisie d'une pièce : longueur, largeur et nombre.
class _PartDialog extends StatefulWidget {
  const _PartDialog();

  @override
  State<_PartDialog> createState() => _PartDialogState();
}

class _PartDialogState extends State<_PartDialog> {
  final _length = TextEditingController();
  final _width = TextEditingController();
  final _count = TextEditingController(text: '1');
  String? _error;

  @override
  void dispose() {
    _length.dispose();
    _width.dispose();
    _count.dispose();
    super.dispose();
  }

  void _submit() {
    final vLength = parseCentimetres(_length.text);
    final vWidth = parseCentimetres(_width.text);
    final vCount = parseWhole(_count.text);
    if (vLength == null ||
        vLength == 0 ||
        vWidth == null ||
        vWidth == 0 ||
        vCount == null ||
        vCount == 0) {
      setState(() => _error = AppLocalizations.of(context).invalidLength);
      return;
    }
    Navigator.pop<PanelPart>(context, (lengthMm: vLength, widthMm: vWidth, count: vCount));
  }

  @override
  Widget build(BuildContext context) {
    final vText = AppLocalizations.of(context);
    const vNumbers = TextInputType.numberWithOptions(decimal: true);

    return AlertDialog(
      title: Text(vText.panelAddPart),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
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
            decoration: InputDecoration(labelText: vText.panelPartWidth, suffixText: vText.unitCm),
          ),
          TextField(
            controller: _count,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(labelText: vText.panelPartCount),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(vText.cancel)),
        FilledButton(onPressed: _submit, child: Text(vText.save)),
      ],
    );
  }
}
