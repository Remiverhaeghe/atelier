import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../l10n/gen/app_localizations.dart';
import '../logic/baseboard.dart';
import '../logic/laying_plan.dart';
import '../logic/room.dart';
import '../logic/site_mode.dart';
import '../logic/units.dart';
import '../state/worksites_controller.dart';
import 'baseboard_view.dart';
import 'theme.dart';

/// Lecture d'un texte à voix haute ; remplaçable dans les tests.
typedef Speaker = Future<void> Function(String pText);

/// Écran gardé allumé ou non ; remplaçable dans les tests.
typedef AwakeKeeper = Future<void> Function(bool pOn);

Future<void> _speak(String pText) async {
  final vTts = FlutterTts();
  await vTts.setLanguage('fr-FR');
  await vTts.speak(pText);
}

Future<void> _keepAwake(bool pOn) => WakelockPlus.toggle(enable: pOn);

/// Mode chantier : une seule chose à faire à la fois, en gros, lisible avec des gants.
class SiteModeScreen extends StatefulWidget {
  const SiteModeScreen({
    super.key,
    required this.controller,
    required this.worksiteId,
    required this.roomId,
    this.speaker,
    this.awake,
  });

  final WorksitesController controller;
  final String worksiteId;
  final String roomId;
  final Speaker? speaker;
  final AwakeKeeper? awake;

  @override
  State<SiteModeScreen> createState() => _SiteModeScreenState();
}

class _SiteModeScreenState extends State<SiteModeScreen> {
  @override
  void initState() {
    super.initState();
    _awake(true);
  }

  @override
  void dispose() {
    _awake(false);
    super.dispose();
  }

  /// Un échec du greffon (émulateur, tests) ne doit pas fermer le mode chantier.
  Future<void> _awake(bool pOn) async {
    try {
      await (widget.awake ?? _keepAwake)(pOn);
    } on Object catch (pError) {
      log('Écran allumé indisponible : $pError', name: 'atelier');
    }
  }

  Future<void> _say(String pText) async {
    try {
      await (widget.speaker ?? _speak)(pText);
    } on Object catch (pError) {
      log('Lecture à voix haute indisponible : $pError', name: 'atelier');
    }
  }

  Room? _room() => widget.controller
      .worksite(widget.worksiteId)
      ?.rooms
      .where((pRoom) => pRoom.id == widget.roomId)
      .firstOrNull;

  String _cutText(AppLocalizations pText, int pIndex, BaseboardPiece pPiece) => pText.siteModeCutText(
    pIndex + 1,
    pPiece.wallNumber,
    formatCentimetres(pPiece.lengthMm),
    cutLabel(pText, pPiece.startCut),
    cutLabel(pText, pPiece.endCut),
  );

  String _rowText(AppLocalizations pText, LayingRow pRow) => pText.siteModeRowText(
    pRow.number,
    [
      for (final vRun in pRow.runs) vRun.pieces.map(formatCentimetres).join(' + '),
    ].join(' / '),
  );

  @override
  Widget build(BuildContext context) {
    final vText = AppLocalizations.of(context);

    return ListenableBuilder(
      listenable: widget.controller,
      builder: (pContext, _) {
        final vRoom = _room();
        if (vRoom == null) {
          return const Scaffold();
        }
        void vSave(Room pRoom) => widget.controller.updateRoom(widget.worksiteId, pRoom);
        final vCut = nextBaseboardCut(vRoom);
        final vRow = nextLayingRow(vRoom);
        final vHasPlan = planLaying(vRoom, vRoom.parquet) != null;

        return Scaffold(
          appBar: AppBar(title: Text('${vText.siteModeTitle} · ${vRoom.name}')),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              IconLine(Icons.light_mode_outlined, vText.siteModeAwake),
              const SizedBox(height: 12),
              _TaskCard(
                icon: AtelierIcons.baseboard,
                title: vText.siteModeCut,
                text: vCut == null ? vText.siteModeCutsDone : _cutText(vText, vCut.index, vCut.piece),
                onSpeak: vCut == null
                    ? null
                    : () => _say(_cutText(vText, vCut.index, vCut.piece)),
                onDone: vCut == null ? null : () => vSave(markCut(vRoom, vCut.index)),
              ),
              const SizedBox(height: 16),
              _TaskCard(
                icon: AtelierIcons.laying,
                title: vText.siteModeRow,
                text: vRow != null
                    ? _rowText(vText, vRow)
                    : (vHasPlan ? vText.siteModeRowsDone : vText.siteModeNoPlan),
                onSpeak: vRow == null ? null : () => _say(_rowText(vText, vRow)),
                onDone: vRow == null ? null : () => vSave(markLaid(vRoom, vRow.number)),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Une tâche en gros caractères, avec deux grands boutons.
class _TaskCard extends StatelessWidget {
  const _TaskCard({
    required this.icon,
    required this.title,
    required this.text,
    required this.onSpeak,
    required this.onDone,
  });

  final IconData icon;
  final String title;
  final String text;
  final VoidCallback? onSpeak;
  final VoidCallback? onDone;

  @override
  Widget build(BuildContext context) {
    final vText = AppLocalizations.of(context);
    final vTheme = Theme.of(context);
    const vBig = Size.fromHeight(64);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(icon, size: 32, color: vTheme.colorScheme.primary),
                const SizedBox(width: 12),
                Text(title, style: vTheme.textTheme.titleLarge),
              ],
            ),
            const SizedBox(height: 12),
            Text(text, style: vTheme.textTheme.headlineSmall),
            if (onDone != null) ...[
              const SizedBox(height: 16),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(minimumSize: vBig),
                onPressed: onSpeak,
                icon: const Icon(Icons.volume_up_outlined, size: 28),
                label: Text(vText.siteModeSpeak),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                style: FilledButton.styleFrom(minimumSize: vBig),
                onPressed: onDone,
                icon: const Icon(Icons.check, size: 28),
                label: Text(vText.siteModeDone),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
