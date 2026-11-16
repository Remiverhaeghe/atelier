import 'package:flutter/material.dart';

import '../l10n/gen/app_localizations.dart';
import '../logic/thermal.dart';
import '../logic/touch_up.dart';
import 'photos.dart';

String thermalIssueLabel(AppLocalizations pText, ThermalIssue pIssue) => switch (pIssue) {
  ThermalIssue.windowFrame => pText.thermalWindow,
  ThermalIssue.doorGap => pText.thermalDoor,
  ThermalIssue.outlet => pText.thermalOutlet,
  ThermalIssue.thermalBridge => pText.thermalBridge,
  ThermalIssue.ceiling => pText.thermalCeiling,
  ThermalIssue.shutterBox => pText.thermalShutter,
};

IconData thermalIssueIcon(ThermalIssue pIssue) => switch (pIssue) {
  ThermalIssue.windowFrame => Icons.window_outlined,
  ThermalIssue.doorGap => Icons.door_front_door_outlined,
  ThermalIssue.outlet => Icons.power_outlined,
  ThermalIssue.thermalBridge => Icons.border_outer,
  ThermalIssue.ceiling => Icons.roofing_outlined,
  ThermalIssue.shutterBox => Icons.blinds_outlined,
};

/// Préconisation et matériel à acheter.
(String, String) thermalFixTexts(AppLocalizations pText, ThermalFix pFix) => switch (pFix) {
  ThermalFix.sealWindow => (pText.fixSealWindow, pText.buySealWindow),
  ThermalFix.doorSweep => (pText.fixDoorSweep, pText.buyDoorSweep),
  ThermalFix.airtightBox => (pText.fixAirtightBox, pText.buyAirtightBox),
  ThermalFix.insulateWall => (pText.fixInsulateWall, ''),
  ThermalFix.insulateAttic => (pText.fixInsulateAttic, ''),
  ThermalFix.insulateShutterBox => (pText.fixInsulateShutterBox, pText.buyInsulateShutterBox),
};

/// Relevé de caméra thermique transformé en reprise : défaut, image, préconisation.
Future<TouchUp?> addThermalTouchUp(BuildContext pContext, {PhotoTaker? pImages}) =>
    showDialog<TouchUp>(
      context: pContext,
      builder: (_) => _ThermalDialog(images: pImages ?? pickImage),
    );

class _ThermalDialog extends StatefulWidget {
  const _ThermalDialog({required this.images});

  final PhotoTaker images;

  @override
  State<_ThermalDialog> createState() => _ThermalDialogState();
}

class _ThermalDialogState extends State<_ThermalDialog> {
  final _id = DateTime.now().microsecondsSinceEpoch.toString();
  ThermalIssue? _issue;
  String? _image;

  @override
  Widget build(BuildContext context) {
    final vText = AppLocalizations.of(context);
    final vTheme = Theme.of(context);
    final vIssue = _issue;

    return AlertDialog(
      title: Text(vText.thermalTitle),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(vText.thermalHelp, style: vTheme.textTheme.bodySmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final vChoice in ThermalIssue.values)
                  ChoiceChip(
                    avatar: Icon(thermalIssueIcon(vChoice), size: 18),
                    label: Text(thermalIssueLabel(vText, vChoice)),
                    selected: vChoice == vIssue,
                    onSelected: (_) => setState(() => _issue = vChoice),
                  ),
              ],
            ),
            if (vIssue != null) ...[
              const SizedBox(height: 10),
              Text(thermalFixTexts(vText, fixFor(vIssue)).$1),
              if (needsQuote(vIssue))
                Text(vText.thermalQuote, style: TextStyle(color: vTheme.colorScheme.primary)),
            ],
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: () async {
                final vPath = await widget.images(_id);
                if (vPath != null) {
                  setState(() => _image = vPath);
                }
              },
              icon: Icon(_image == null ? Icons.add_photo_alternate_outlined : Icons.check),
              label: Text(_image == null ? vText.thermalImage : vText.thermalImageTaken),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(vText.cancel)),
        FilledButton(
          onPressed: vIssue == null
              ? null
              : () {
                  final (vNote, vBuy) = thermalFixTexts(vText, fixFor(vIssue));
                  Navigator.pop(
                    context,
                    TouchUp(
                      id: _id,
                      label: thermalIssueLabel(vText, vIssue),
                      note: vNote,
                      toBuy: vBuy,
                      photoPath: _image,
                    ),
                  );
                },
          child: Text(vText.thermalAdd),
        ),
      ],
    );
  }
}
