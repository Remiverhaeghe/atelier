import 'package:flutter/material.dart';

import '../l10n/gen/app_localizations.dart';
import '../logic/gestures.dart';
import 'gesture_scenes.dart';
import 'glossary_view.dart';
import 'starter_tools_screen.dart';
import 'sketch3d.dart';
import 'theme.dart';
import 'work_sheet_pdf.dart';

/// Nombre de passes jouées, et durée d'une passe. L'animation s'arrête à mi-course, l'outil
/// au bout de son geste, pour qu'on voie la position à retenir.
const gesturePasses = 3.5;
const gesturePassDuration = Duration(milliseconds: 1800);

/// Le ralenti joue le geste quatre fois moins vite.
const slowMotionFactor = 4;

/// Les gestes de base, un par carte.
class GesturesScreen extends StatelessWidget {
  const GesturesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final vText = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(vText.gesturesTitle)),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
            child: Text(vText.gesturesIntro, style: Theme.of(context).textTheme.bodyMedium),
          ),
          for (final vGesture in Gesture.values)
            Card(
              child: ListTile(
                title: Text(gestureName(vText, vGesture)),
                subtitle: Text(gestureUse(vText, vGesture)),
                trailing: const Icon(Icons.play_circle_outline),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(builder: (_) => GestureScreen(gesture: vGesture)),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Un geste : le croquis animé, les étapes, l'erreur courante et les protections.
class GestureScreen extends StatelessWidget {
  const GestureScreen({super.key, required this.gesture});

  final Gesture gesture;

  @override
  Widget build(BuildContext context) {
    final vText = AppLocalizations.of(context);
    final vTheme = Theme.of(context);
    final vSteps = gestureSteps(vText, gesture);

    return Scaffold(
      appBar: AppBar(
        title: Text(gestureName(vText, gesture)),
        actions: [
          PrintSheetButton(
            sheet: () => (
              title: gestureName(vText, gesture),
              intro: gestureUse(vText, gesture),
              measures: const [],
              results: [
                if (gesture.gear.isNotEmpty)
                  vText.sheetGear(gesture.gear.map((pGear) => gearName(vText, pGear)).join(', ')),
                if (gesture.rotating) vText.gestureNoGloves,
                gestureMistake(vText, gesture),
              ],
              buy: const [],
              steps: vSteps,
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          GestureSketch(gesture: gesture),
          Text(vText.termUseTitle, style: vTheme.textTheme.titleSmall),
          Text(gestureUse(vText, gesture), style: vTheme.textTheme.bodyLarge),
          const SizedBox(height: 12),
          Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(vText.gestureHowTitle, style: vTheme.textTheme.titleMedium),
                  for (final (vIndex, vStep) in vSteps.indexed)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text('${vIndex + 1}. $vStep', style: vTheme.textTheme.bodyMedium),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          IconLine(
            Icons.report_gmailerrorred,
            gestureMistake(vText, gesture),
            color: vTheme.colorScheme.error,
          ),
          if (gesture.gear.isNotEmpty || gesture.rotating) ...[
            const SizedBox(height: 8),
            Text(vText.gestureGearTitle, style: vTheme.textTheme.titleSmall),
            Wrap(
              spacing: 8,
              children: [
                for (final vGear in gesture.gear)
                  Chip(
                    avatar: const Icon(Icons.shield_outlined, size: 18),
                    label: Text(gearName(vText, vGear)),
                  ),
              ],
            ),
            if (gesture.rotating) IconLine(Icons.back_hand_outlined, vText.gestureNoGloves),
          ],
          const SizedBox(height: 8),
          Text(vText.gestureToolsTitle, style: vTheme.textTheme.titleSmall),
          Wrap(
            spacing: 8,
            children: [
              for (final vTool in gesture.tools)
                Chip(
                  avatar: const Icon(Icons.handyman_outlined, size: 18),
                  label: Text(toolName(vText, vTool)),
                ),
            ],
          ),
          if (gesture.terms.isNotEmpty) TermsRow(gesture.terms),
        ],
      ),
    );
  }
}

/// Croquis en relief qui joue le geste quelques fois, puis s'arrête. On peut le mettre en pause,
/// le ralentir, l'avancer au doigt sur la réglette ou le rejouer.
class GestureSketch extends StatefulWidget {
  const GestureSketch({super.key, required this.gesture});

  final Gesture gesture;

  @override
  State<GestureSketch> createState() => _GestureSketchState();
}

class _GestureSketchState extends State<GestureSketch> with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    upperBound: gesturePasses,
    duration: gesturePassDuration * gesturePasses,
  );

  var _started = false;

  /// Ralenti : le geste dure quatre fois plus longtemps.
  var _slow = false;

  /// Durée de toutes les passes, à la vitesse choisie.
  Duration get _duration => gesturePassDuration * gesturePasses * (_slow ? slowMotionFactor : 1);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Joué une fois à l'ouverture, pas à chaque changement d'orientation ou de thème
    if (!_started) {
      _started = true;
      _play();
    }
  }

  void _play() {
    // Animations coupées dans les réglages du téléphone : l'outil est montré au bout du geste
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.value = gesturePasses;
    } else {
      _controller.forward(from: 0);
    }
  }

  void _pauseOrResume() {
    if (_controller.isAnimating) {
      _controller.stop();
    } else if (_controller.value >= gesturePasses) {
      _controller.forward(from: 0);
    } else {
      _controller.forward();
    }
    setState(() {});
  }

  void _toggleSlow() {
    setState(() => _slow = !_slow);
    _controller.duration = _duration;
    // Une animation en cours repart du même point, à la nouvelle vitesse
    if (_controller.isAnimating) {
      _controller.forward();
    }
  }

  /// Réglette tirée au doigt : le geste s'arrête et suit le doigt.
  void _scrub(double pValue) {
    _controller
      ..stop()
      ..value = pValue;
    setState(() {});
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vText = AppLocalizations.of(context);

    return Column(
      children: [
        AspectRatio(
          aspectRatio: 1.5,
          child: AnimatedBuilder(
            animation: _controller,
            builder: (pContext, _) {
              final vScene = gestureScene(vText, widget.gesture, _controller.value);
              return Sketch3D(parts: vScene.parts, callouts: vScene.callouts);
            },
          ),
        ),
        // Réglette et bouton suivent l'animation à chaque image, fin du geste comprise
        AnimatedBuilder(
          animation: _controller,
          builder: (pContext, _) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Slider(
                value: _controller.value,
                max: gesturePasses,
                semanticFormatterCallback: (_) => vText.gestureScrub,
                onChanged: _scrub,
              ),
              Wrap(
                alignment: WrapAlignment.end,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 4,
                children: [
                  IconButton(
                    tooltip: _controller.isAnimating ? vText.gesturePause : vText.gestureResume,
                    icon: Icon(_controller.isAnimating ? Icons.pause : Icons.play_arrow),
                    onPressed: _pauseOrResume,
                  ),
                  FilterChip(
                    avatar: const Icon(Icons.slow_motion_video, size: 18),
                    label: Text(vText.gestureSlow),
                    selected: _slow,
                    onSelected: (_) => _toggleSlow(),
                  ),
                  TextButton.icon(
                    onPressed: _play,
                    icon: const Icon(Icons.replay),
                    label: Text(vText.gestureReplay, style: const TextStyle(fontFamily: handFont)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

String gestureName(AppLocalizations pText, Gesture pGesture) => switch (pGesture) {
  Gesture.saw => pText.gestureSaw,
  Gesture.plane => pText.gesturePlane,
  Gesture.drill => pText.gestureDrill,
  Gesture.screw => pText.gestureScrew,
  Gesture.sand => pText.gestureSand,
  Gesture.chisel => pText.gestureChisel,
  Gesture.caulk => pText.gestureCaulk,
  Gesture.plug => pText.gesturePlug,
  Gesture.cutBoard => pText.gestureCutBoard,
  Gesture.mitre => pText.gestureMitre,
  Gesture.laser => pText.gestureLaser,
  Gesture.grout => pText.gestureGrout,
};

String gestureUse(AppLocalizations pText, Gesture pGesture) => switch (pGesture) {
  Gesture.saw => pText.gestureSawUse,
  Gesture.plane => pText.gesturePlaneUse,
  Gesture.drill => pText.gestureDrillUse,
  Gesture.screw => pText.gestureScrewUse,
  Gesture.sand => pText.gestureSandUse,
  Gesture.chisel => pText.gestureChiselUse,
  Gesture.caulk => pText.gestureCaulkUse,
  Gesture.plug => pText.gesturePlugUse,
  Gesture.cutBoard => pText.gestureCutBoardUse,
  Gesture.mitre => pText.gestureMitreUse,
  Gesture.laser => pText.gestureLaserUse,
  Gesture.grout => pText.gestureGroutUse,
};

List<String> gestureSteps(AppLocalizations pText, Gesture pGesture) => switch (pGesture) {
  Gesture.saw => [pText.gestureSaw1, pText.gestureSaw2, pText.gestureSaw3],
  Gesture.plane => [pText.gesturePlane1, pText.gesturePlane2, pText.gesturePlane3],
  Gesture.drill => [pText.gestureDrill1, pText.gestureDrill2, pText.gestureDrill3],
  Gesture.screw => [pText.gestureScrew1, pText.gestureScrew2, pText.gestureScrew3],
  Gesture.sand => [pText.gestureSand1, pText.gestureSand2, pText.gestureSand3],
  Gesture.chisel => [pText.gestureChisel1, pText.gestureChisel2, pText.gestureChisel3],
  Gesture.caulk => [pText.gestureCaulk1, pText.gestureCaulk2, pText.gestureCaulk3],
  Gesture.plug => [pText.gesturePlug1, pText.gesturePlug2, pText.gesturePlug3],
  Gesture.cutBoard => [pText.gestureCutBoard1, pText.gestureCutBoard2, pText.gestureCutBoard3],
  Gesture.mitre => [pText.gestureMitre1, pText.gestureMitre2, pText.gestureMitre3],
  Gesture.laser => [pText.gestureLaser1, pText.gestureLaser2, pText.gestureLaser3],
  Gesture.grout => [pText.gestureGrout1, pText.gestureGrout2, pText.gestureGrout3],
};

String gestureMistake(AppLocalizations pText, Gesture pGesture) => switch (pGesture) {
  Gesture.saw => pText.gestureSawMistake,
  Gesture.plane => pText.gesturePlaneMistake,
  Gesture.drill => pText.gestureDrillMistake,
  Gesture.screw => pText.gestureScrewMistake,
  Gesture.sand => pText.gestureSandMistake,
  Gesture.chisel => pText.gestureChiselMistake,
  Gesture.caulk => pText.gestureCaulkMistake,
  Gesture.plug => pText.gesturePlugMistake,
  Gesture.cutBoard => pText.gestureCutBoardMistake,
  Gesture.mitre => pText.gestureMitreMistake,
  Gesture.laser => pText.gestureLaserMistake,
  Gesture.grout => pText.gestureGroutMistake,
};

String gearName(AppLocalizations pText, Gear pGear) => switch (pGear) {
  Gear.glasses => pText.gearGlasses,
  Gear.mask => pText.gearMask,
  Gear.gloves => pText.gearGloves,
  Gear.earmuffs => pText.gearEarmuffs,
};
