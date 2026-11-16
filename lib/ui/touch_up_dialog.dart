import 'package:flutter/material.dart';

import '../l10n/gen/app_localizations.dart';
import '../logic/touch_up.dart';
import '../logic/units.dart';

/// Reprise saisie ; [next] demande d'enchaîner sur la suivante.
typedef TouchUpEntry = ({TouchUp touchUp, bool next});

/// Ajout ou modification d'une reprise.
Future<TouchUpEntry?> editTouchUp(BuildContext pContext, {TouchUp? pTouchUp}) =>
    showDialog<TouchUpEntry>(
      context: pContext,
      builder: (_) => _TouchUpDialog(touchUp: pTouchUp),
    );

class _TouchUpDialog extends StatefulWidget {
  const _TouchUpDialog({this.touchUp});

  final TouchUp? touchUp;

  @override
  State<_TouchUpDialog> createState() => _TouchUpDialogState();
}

class _TouchUpDialogState extends State<_TouchUpDialog> {
  late final TextEditingController _label;
  late final TextEditingController _passes;
  late final TextEditingController _note;
  late final TextEditingController _toBuy;
  String? _labelError;
  String? _passesError;

  @override
  void initState() {
    super.initState();
    final vTouchUp = widget.touchUp;
    _label = TextEditingController(text: vTouchUp?.label ?? '');
    _passes = TextEditingController(text: '${vTouchUp?.passes ?? 1}');
    _note = TextEditingController(text: vTouchUp?.note ?? '');
    _toBuy = TextEditingController(text: vTouchUp?.toBuy ?? '');
  }

  @override
  void dispose() {
    _label.dispose();
    _passes.dispose();
    _note.dispose();
    _toBuy.dispose();
    super.dispose();
  }

  void _submit({bool pNext = false}) {
    final vText = AppLocalizations.of(context);
    final vLabel = _label.text.trim();
    final vPasses = parseWhole(_passes.text);
    setState(() {
      _labelError = vLabel.isEmpty ? vText.touchUpLabelMissing : null;
      _passesError = vPasses == null || vPasses < 1 ? vText.touchUpPassesInvalid : null;
    });
    if (_labelError != null || _passesError != null) {
      return;
    }
    final vBase =
        widget.touchUp ??
        TouchUp(id: DateTime.now().microsecondsSinceEpoch.toString(), label: vLabel);
    final TouchUpEntry vEntry = (
      touchUp: vBase.copyWith(
        label: vLabel,
        passes: vPasses,
        note: _note.text.trim(),
        toBuy: _toBuy.text.trim(),
      ),
      next: pNext,
    );
    Navigator.pop(context, vEntry);
  }

  @override
  Widget build(BuildContext context) {
    final vText = AppLocalizations.of(context);
    final vNew = widget.touchUp == null;

    return AlertDialog(
      title: Text(vNew ? vText.addTouchUp : vText.edit),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _label,
              autofocus: true,
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _submit(pNext: vNew),
              decoration: InputDecoration(labelText: vText.touchUpLabel, errorText: _labelError),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _passes,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: vText.touchUpPasses,
                helperText: vText.touchUpPassesHelp,
                errorText: _passesError,
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _note,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(labelText: vText.touchUpNote),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _toBuy,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: vText.touchUpToBuy,
                prefixIcon: const Icon(Icons.shopping_cart_outlined),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(vText.cancel)),
        if (vNew)
          OutlinedButton(onPressed: _submit, child: Text(vText.save))
        else
          FilledButton(onPressed: _submit, child: Text(vText.save)),
        if (vNew)
          FilledButton(onPressed: () => _submit(pNext: true), child: Text(vText.nextTouchUp)),
      ],
    );
  }
}
