import 'dart:async';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../l10n/gen/app_localizations.dart';
import '../logic/workshop.dart';
import 'theme.dart';
import 'site_mode_screen.dart';

/// Hauteur des boutons : assez grands pour être touchés avec des gants de travail.
const workshopButtonHeight = 88.0;

Future<void> _keepAwake(bool pOn) => WakelockPlus.toggle(enable: pOn);

/// Mode atelier : chronomètre en très gros chiffres, étape en cours et liste des étapes, en
/// plein écran, écran gardé allumé.
class WorkshopModeScreen extends StatefulWidget {
  const WorkshopModeScreen({
    super.key,
    required this.title,
    required this.steps,
    this.onStepDone,
    this.awake,
    this.clock,
  });

  final String title;
  final List<String> steps;

  /// Étape cochée et temps passé dessus, pour la noter ailleurs (reprises de la pièce).
  final void Function(int pIndex, Duration pTime)? onStepDone;
  final AwakeKeeper? awake;

  /// Heure courante ; remplaçable dans les tests.
  final DateTime Function()? clock;

  @override
  State<WorkshopModeScreen> createState() => _WorkshopModeScreenState();
}

class _WorkshopModeScreenState extends State<WorkshopModeScreen> {
  late WorkshopRun _run = WorkshopRun(stepCount: widget.steps.length);
  Timer? _ticker;
  var _drying = const DryingTimers();

  DateTime _now() => (widget.clock ?? DateTime.now)();

  @override
  void initState() {
    super.initState();
    _awake(true);
    _fullScreen(true);
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _awake(false);
    _fullScreen(false);
    super.dispose();
  }

  /// Un échec du greffon (émulateur, tests) ne doit pas fermer le mode atelier.
  Future<void> _awake(bool pOn) async {
    try {
      await (widget.awake ?? _keepAwake)(pOn);
    } on Object catch (pError) {
      log('Écran allumé indisponible : $pError', name: 'atelier');
    }
  }

  Future<void> _fullScreen(bool pOn) async {
    try {
      await SystemChrome.setEnabledSystemUIMode(
        pOn ? SystemUiMode.immersiveSticky : SystemUiMode.edgeToEdge,
      );
    } on Object catch (pError) {
      log('Plein écran indisponible : $pError', name: 'atelier');
    }
  }

  void _toggleChrono() {
    final vNow = _now();
    setState(() => _run = _run.chrono.running ? _run.pause(vNow) : _run.start(vNow));
    _syncTicker();
  }

  /// L'horloge ne tourne que si le chrono ou un séchage est en cours : rien ne redessine l'écran
  /// pour rien.
  void _syncTicker() {
    _ticker?.cancel();
    _ticker = _run.chrono.running || _drying.anyRunning(_now())
        ? Timer.periodic(const Duration(seconds: 1), (_) {
            final vWasRunning = _drying.anyRunning(_now().subtract(const Duration(seconds: 1)));
            if (vWasRunning && !_drying.anyRunning(_now())) {
              HapticFeedback.heavyImpact();
            }
            setState(() {});
            if (!_run.chrono.running && !_drying.anyRunning(_now())) {
              _ticker?.cancel();
              _ticker = null;
            }
          })
        : null;
  }

  void _startDrying(int pMinutes) {
    setState(() => _drying = _drying.start(_run.current, _now(), Duration(minutes: pMinutes)));
    _syncTicker();
  }

  void _swipe(DragEndDetails pDetails) {
    final vVelocity = pDetails.primaryVelocity ?? 0;
    if (vVelocity < -300 && _run.current < widget.steps.length - 1) {
      setState(() => _run = _run.goTo(_run.current + 1, _now()));
    } else if (vVelocity > 300 && _run.current > 0) {
      setState(() => _run = _run.goTo(_run.current - 1, _now()));
    }
  }

  void _done() {
    final vIndex = _run.current;
    final vBefore = _run.stepTimes[vIndex] ?? Duration.zero;
    setState(() => _run = _run.markDone(_now()));
    widget.onStepDone?.call(vIndex, (_run.stepTimes[vIndex] ?? Duration.zero) - vBefore);
  }

  @override
  Widget build(BuildContext context) {
    final vText = AppLocalizations.of(context);
    final vTheme = Theme.of(context);
    final vNow = _now();
    final vSteps = widget.steps;
    const vBig = Size.fromHeight(workshopButtonHeight);
    final vChronoStyle = vTheme.textTheme.displayLarge!.copyWith(
      fontSize: 96,
      fontWeight: FontWeight.w700,
      fontFeatures: const [FontFeature.tabularFigures()],
      color: vTheme.colorScheme.primary,
    );

    return Scaffold(
      appBar: AppBar(title: Text('${vText.workshopTitle} · ${widget.title}')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(vText.workshopAwake, style: vTheme.textTheme.bodySmall),
          Center(
            child: FittedBox(
              child: Text(formatChrono(_run.chrono.elapsed(vNow)), style: vChronoStyle),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(minimumSize: vBig),
                  onPressed: _toggleChrono,
                  icon: Icon(_run.chrono.running ? Icons.pause : Icons.play_arrow, size: 40),
                  label: Text(_run.chrono.running ? vText.workshopPause : vText.workshopStart),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(minimumSize: vBig),
                  onPressed: _run.chrono.running
                      ? null
                      : () => setState(() => _run = _run.resetChrono()),
                  icon: const Icon(Icons.replay, size: 40),
                  label: Text(vText.workshopReset),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (vSteps.isEmpty)
            Text(vText.workshopNoSteps, style: vTheme.textTheme.headlineSmall)
          else ...[
            GestureDetector(
              onHorizontalDragEnd: _swipe,
              child: Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _run.finished
                          ? vText.workshopFinished
                          : vText.workshopStepOf(_run.current + 1, vSteps.length),
                      style: vTheme.textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    if (!_run.finished)
                      Text(
                        vSteps[_run.current],
                        style: vTheme.textTheme.headlineMedium!.copyWith(fontFamily: handFont),
                      ),
                    if (!_run.finished) ..._dryingLines(vText, vTheme, vNow),
                  ],
                ),
              ),
            ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(minimumSize: vBig),
                    onPressed: _run.current == 0
                        ? null
                        : () => setState(() => _run = _run.goTo(_run.current - 1, _now())),
                    child: Text(vText.workshopPrevious),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(minimumSize: vBig),
                    onPressed: _run.finished ? null : _done,
                    icon: const Icon(Icons.check, size: 40),
                    label: Text(vText.workshopDone),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(minimumSize: vBig),
                    onPressed: _run.current >= vSteps.length - 1
                        ? null
                        : () => setState(() => _run = _run.goTo(_run.current + 1, _now())),
                    child: Text(vText.workshopNext),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(vText.workshopList, style: vTheme.textTheme.titleLarge),
            if (_run.stepTimes.isNotEmpty)
              Text(
                vText.workshopTotal(formatChrono(_run.stepsTotal)),
                style: vTheme.textTheme.titleMedium,
              ),
            for (final (vIndex, vStep) in vSteps.indexed)
              ListTile(
                minTileHeight: 72,
                selected: vIndex == _run.current && !_run.finished,
                leading: Icon(
                  _run.done.contains(vIndex) ? Icons.check_circle : Icons.radio_button_unchecked,
                  size: 36,
                ),
                title: Text('${vIndex + 1}. $vStep', style: vTheme.textTheme.titleLarge),
                subtitle: _stepSubtitle(vText, vIndex, vNow),
                onTap: () => setState(() => _run = _run.reopen(vIndex).goTo(vIndex, _now())),
              ),
          ],
        ],
      ),
    );
  }

  /// Temps passé sur l'étape et séchage en cours, sous son titre dans la liste.
  Widget? _stepSubtitle(AppLocalizations pText, int pIndex, DateTime pNow) {
    final vLines = [
      if (_run.stepTimes[pIndex] != null)
        pText.workshopStepTime(formatChrono(_run.stepTimes[pIndex]!)),
      if (_drying.remaining(pIndex, pNow) case final Duration vLeft)
        vLeft == Duration.zero
            ? pText.workshopDryingDone
            : pText.workshopDryingLeft(formatChrono(vLeft)),
    ];

    return vLines.isEmpty ? null : Text(vLines.join(' · '));
  }

  /// Minuteur de séchage de l'étape en cours : choix de la durée, ou temps qu'il reste.
  List<Widget> _dryingLines(AppLocalizations pText, ThemeData pTheme, DateTime pNow) {
    final vLeft = _drying.remaining(_run.current, pNow);
    if (vLeft == null) {
      return [
        const SizedBox(height: 12),
        Text(pText.workshopDrying, style: pTheme.textTheme.titleMedium),
        Wrap(
          spacing: 8,
          children: [
            for (final vMinutes in dryingPresetMinutes)
              ActionChip(
                label: Text(formatDryingPreset(vMinutes)),
                onPressed: () => _startDrying(vMinutes),
              ),
          ],
        ),
      ];
    }

    return [
      const SizedBox(height: 12),
      Text(
        vLeft == Duration.zero ? pText.workshopDryingDone : pText.workshopDryingLeft(formatChrono(vLeft)),
        style: pTheme.textTheme.headlineSmall,
      ),
      TextButton(
        onPressed: () {
          setState(() => _drying = _drying.cancel(_run.current));
          _syncTicker();
        },
        child: Text(pText.workshopDryingCancel),
      ),
    ];
  }
}

/// « 15 min », « 1 h », « 24 h » : durée d'un bouton de séchage.
String formatDryingPreset(int pMinutes) =>
    pMinutes < 60 ? '$pMinutes min' : '${pMinutes ~/ 60} h';
