import 'package:flutter/material.dart';

import '../l10n/gen/app_localizations.dart';
import '../logic/angle_measure.dart';
import '../logic/units.dart';
import 'dialogs.dart';

/// Mesure de l'angle réel d'un coin avec un mètre : renvoie l'angle intérieur, ou null.
Future<double?> measureCornerAngle(BuildContext pContext) =>
    showDialog<double>(context: pContext, builder: (_) => const _AngleDialog());

class _AngleDialog extends StatefulWidget {
  const _AngleDialog();

  @override
  State<_AngleDialog> createState() => _AngleDialogState();
}

class _AngleDialogState extends State<_AngleDialog> {
  final _sideA = TextEditingController(text: '50');
  final _sideB = TextEditingController(text: '50');
  final _gap = TextEditingController();
  bool _outside = false;

  @override
  void dispose() {
    _sideA.dispose();
    _sideB.dispose();
    _gap.dispose();
    super.dispose();
  }

  double? get _angle {
    final vA = parseCentimetres(_sideA.text);
    final vB = parseCentimetres(_sideB.text);
    final vGap = parseCentimetres(_gap.text);
    if (vA == null || vB == null || vGap == null) {
      return null;
    }

    return cornerAngle(pSideAMm: vA, pSideBMm: vB, pDiagonalMm: vGap, pOutside: _outside);
  }

  @override
  Widget build(BuildContext context) {
    final vText = AppLocalizations.of(context);
    final vTheme = Theme.of(context);
    final vAngle = _angle;
    final vTyped = _gap.text.trim().isNotEmpty;
    const vNumbers = TextInputType.numberWithOptions(decimal: true);
    Widget vField(TextEditingController pController, String pLabel, {bool pFocus = false}) =>
        Padding(
          padding: const EdgeInsets.only(top: 10),
          child: TextField(
            controller: pController,
            autofocus: pFocus,
            keyboardType: vNumbers,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(labelText: pLabel, suffixText: vText.unitCm),
          ),
        );

    return AlertDialog(
      title: Text(vText.measureAngle),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(vText.measureAngleHelp),
            vField(_sideA, vText.markOnWall),
            vField(_sideB, vText.markOnNextWall),
            vField(_gap, vText.markGap, pFocus: true),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _outside,
              title: Text(vText.outsideCornerMeasure),
              onChanged: (pValue) => setState(() => _outside = pValue),
            ),
            if (vAngle != null)
              Text(
                vText.measuredAngle(formatAngle(vAngle)),
                style: vTheme.textTheme.titleLarge!.copyWith(color: vTheme.colorScheme.primary),
              )
            else if (vTyped)
              Text(vText.impossibleTriangle, style: TextStyle(color: vTheme.colorScheme.error)),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(vText.cancel)),
        FilledButton(
          onPressed: vAngle == null ? null : () => Navigator.pop(context, vAngle),
          child: Text(vText.useAngle),
        ),
      ],
    );
  }
}
