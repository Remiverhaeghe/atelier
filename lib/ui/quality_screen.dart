import 'package:flutter/material.dart';

import '../l10n/gen/app_localizations.dart';
import '../logic/quality_checks.dart';
import '../logic/room.dart';
import '../logic/units.dart';
import 'photos.dart';
import 'theme.dart';

/// Contrôles qualité, étape par étape. Ouverts depuis une pièce ([room] et [onChanged]), les
/// contrôles cochés et leurs photos sont gardés avec les étapes faites de la pièce.
class QualityScreen extends StatefulWidget {
  const QualityScreen({super.key, this.room, this.onChanged, this.photos});

  final Room? room;
  final ValueChanged<Room>? onChanged;

  /// Prise de photo ; remplaçable dans les tests.
  final PhotoTaker? photos;

  @override
  State<QualityScreen> createState() => _QualityScreenState();
}

class _QualityScreenState extends State<QualityScreen> {
  // Copie locale : l'écran est poussé par-dessus la pièce et ne la reçoit pas à nouveau
  late Room? _room = widget.room;
  late final _done = doneChecks(widget.room?.doneSteps ?? const []);

  void _toggle(QualityCheck pCheck, bool pDone) {
    setState(() => pDone ? _done.add(pCheck) : _done.remove(pCheck));
    final vRoom = _room;
    if (vRoom != null) {
      final vSteps = {...vRoom.doneSteps};
      pDone ? vSteps.add(qualityKey(pCheck)) : vSteps.remove(qualityKey(pCheck));
      _save(vRoom.copyWith(doneSteps: vSteps.toList()..sort()));
    }
  }

  Future<void> _photo(QualityCheck pCheck) async {
    final vRoom = _room;
    if (vRoom == null) {
      return;
    }
    final vKey = qualityKey(pCheck);
    final vPath = await (widget.photos ?? takePhoto)('${vRoom.id}-$vKey');
    if (vPath != null && mounted) {
      _save(
        vRoom.copyWith(
          stepPhotos: {
            ...vRoom.stepPhotos,
            vKey: [...?vRoom.stepPhotos[vKey], vPath],
          },
        ),
      );
    }
  }

  void _save(Room pRoom) {
    setState(() => _room = pRoom);
    widget.onChanged?.call(pRoom);
  }

  @override
  Widget build(BuildContext context) {
    final vText = AppLocalizations.of(context);
    final vTheme = Theme.of(context);
    final vProgress = stageProgress(_done);

    return Scaffold(
      appBar: AppBar(title: Text(vText.qualityTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 32),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 0, 4, 4),
            child: Text(vText.qualityIntro, style: vTheme.textTheme.bodyMedium),
          ),
          if (_room == null)
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
              child: IconLine(Icons.info_outline, vText.qualityNoRoom),
            ),
          for (final vStage in QualityStage.values) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 12, 4, 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(qualityStageName(vText, vStage), style: vTheme.textTheme.titleMedium),
                  ),
                  Text(vText.qualityProgress(vProgress[vStage]!.done, vProgress[vStage]!.total)),
                ],
              ),
            ),
            for (final vCheck in QualityCheck.values.where((pCheck) => pCheck.stage == vStage))
              _CheckCard(
                check: vCheck,
                done: _done.contains(vCheck),
                photos: _room?.stepPhotos[qualityKey(vCheck)] ?? const [],
                canPhoto: _room != null,
                onDone: (pDone) => _toggle(vCheck, pDone),
                onPhoto: () => _photo(vCheck),
              ),
          ],
        ],
      ),
    );
  }
}

class _CheckCard extends StatelessWidget {
  const _CheckCard({
    required this.check,
    required this.done,
    required this.photos,
    required this.canPhoto,
    required this.onDone,
    required this.onPhoto,
  });

  final QualityCheck check;
  final bool done;
  final List<String> photos;
  final bool canPhoto;
  final ValueChanged<bool> onDone;
  final VoidCallback onPhoto;

  @override
  Widget build(BuildContext context) {
    final vText = AppLocalizations.of(context);
    final vTheme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(4, 4, 8, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CheckboxListTile(
              value: done,
              onChanged: (pValue) => onDone(pValue ?? false),
              controlAffinity: ListTileControlAffinity.leading,
              title: Text(qualityCheckName(vText, check)),
              subtitle: Text(qualityCheckHow(vText, check)),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: IconLine(Icons.straighten, qualityTolerance(vText, check)),
            ),
            Wrap(
              spacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                TextButton.icon(
                  onPressed: () => showDialog<void>(
                    context: context,
                    builder: (_) => QualityMeasureDialog(check: check),
                  ),
                  icon: const Icon(Icons.rule),
                  label: Text(vText.qualityMeasure),
                ),
                if (canPhoto)
                  IconButton(
                    tooltip: vText.qualityPhoto,
                    icon: const Icon(Icons.add_a_photo_outlined),
                    onPressed: onPhoto,
                  ),
                for (final vPath in photos)
                  IconButton(
                    tooltip: vText.qualityPhoto,
                    icon: Icon(Icons.photo_outlined, color: vTheme.colorScheme.primary),
                    onPressed: () => showPhoto(context, vPath),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Saisie d'une mesure et verdict immédiat : bon, ou à reprendre.
class QualityMeasureDialog extends StatefulWidget {
  const QualityMeasureDialog({super.key, required this.check});

  final QualityCheck check;

  @override
  State<QualityMeasureDialog> createState() => _QualityMeasureDialogState();
}

class _QualityMeasureDialogState extends State<QualityMeasureDialog> {
  int? _first;
  int? _second;

  QualityVerdict? _verdict() {
    final vFirst = _first;
    // À la règle, la longueur lue est celle de la règle
    final vSecond = widget.check.method == QualityMethod.straightedge
        ? widget.check.overMm
        : _second;
    if (vFirst == null || vSecond == null) {
      return null;
    }
    final rVerdict = widget.check.method == QualityMethod.diagonals
        ? checkDiagonals(widget.check, vFirst, vSecond)
        : checkGap(widget.check, vFirst, vSecond);

    return rVerdict;
  }

  @override
  Widget build(BuildContext context) {
    final vText = AppLocalizations.of(context);
    final vTheme = Theme.of(context);
    final vDiagonals = widget.check.method == QualityMethod.diagonals;
    final vRule = widget.check.method == QualityMethod.straightedge;
    final vVerdict = _verdict();

    return AlertDialog(
      title: Text(qualityCheckName(vText, widget.check)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: vDiagonals ? vText.qualityFirstDiagonal : vText.qualityGap,
              ),
              onChanged: (pText) => setState(
                () => _first = vDiagonals ? parseCentimetres(pText) : parseWhole(pText),
              ),
            ),
            // À la règle, la longueur est celle de la règle : rien d'autre à saisir
            if (!vRule)
              TextField(
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: vDiagonals ? vText.qualitySecondDiagonal : vText.qualityLength,
                ),
                onChanged: (pText) => setState(() => _second = parseCentimetres(pText)),
              ),
            const SizedBox(height: 12),
            if (vVerdict != null)
              IconLine(
                vVerdict.ok ? Icons.check_circle_outline : Icons.report_gmailerrorred,
                vVerdict.ok
                    ? vText.qualityOk(vVerdict.gapMm, vVerdict.toleranceMm)
                    : vText.qualityRedo(vVerdict.gapMm, vVerdict.toleranceMm),
                color: vVerdict.ok ? vTheme.colorScheme.primary : vTheme.colorScheme.error,
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(MaterialLocalizations.of(context).closeButtonLabel),
        ),
      ],
    );
  }
}

/// Écart toléré, dit selon la façon de mesurer.
String qualityTolerance(AppLocalizations pText, QualityCheck pCheck) => switch (pCheck.method) {
  QualityMethod.diagonals => pText.qualityTolDiagonals(
    (pCheck.toleranceMm * 1000 / pCheck.overMm).round(),
  ),
  QualityMethod.straightedge => pText.qualityTolRule(
    pCheck.toleranceMm,
    formatCentimetres(pCheck.overMm),
  ),
  QualityMethod.level || QualityMethod.plumb => pText.qualityTolLength(
    pCheck.toleranceMm,
    formatCentimetres(pCheck.overMm),
  ),
};

String qualityStageName(AppLocalizations pText, QualityStage pStage) => switch (pStage) {
  QualityStage.layout => pText.qualityStageLayout,
  QualityStage.framing => pText.qualityStageFraming,
  QualityStage.support => pText.qualityStageSupport,
  QualityStage.laying => pText.qualityStageLaying,
  QualityStage.finish => pText.qualityStageFinish,
};

String qualityCheckName(AppLocalizations pText, QualityCheck pCheck) => switch (pCheck) {
  QualityCheck.layoutSquare => pText.qualityLayoutSquare,
  QualityCheck.layoutLevel => pText.qualityLayoutLevel,
  QualityCheck.studsPlumb => pText.qualityStudsPlumb,
  QualityCheck.frameSquare => pText.qualityFrameSquare,
  QualityCheck.floorFlat => pText.qualityFloorFlat,
  QualityCheck.wallFlat => pText.qualityWallFlat,
  QualityCheck.firstRowStraight => pText.qualityFirstRowStraight,
  QualityCheck.shelfLevel => pText.qualityShelfLevel,
  QualityCheck.tileLippage => pText.qualityTileLippage,
  QualityCheck.doorPlumb => pText.qualityDoorPlumb,
  QualityCheck.finishedWallFlat => pText.qualityFinishedWallFlat,
};

String qualityCheckHow(AppLocalizations pText, QualityCheck pCheck) => switch (pCheck) {
  QualityCheck.layoutSquare => pText.qualityLayoutSquareHow,
  QualityCheck.layoutLevel => pText.qualityLayoutLevelHow,
  QualityCheck.studsPlumb => pText.qualityStudsPlumbHow,
  QualityCheck.frameSquare => pText.qualityFrameSquareHow,
  QualityCheck.floorFlat => pText.qualityFloorFlatHow,
  QualityCheck.wallFlat => pText.qualityWallFlatHow,
  QualityCheck.firstRowStraight => pText.qualityFirstRowStraightHow,
  QualityCheck.shelfLevel => pText.qualityShelfLevelHow,
  QualityCheck.tileLippage => pText.qualityTileLippageHow,
  QualityCheck.doorPlumb => pText.qualityDoorPlumbHow,
  QualityCheck.finishedWallFlat => pText.qualityFinishedWallFlatHow,
};
