import 'dart:async';

import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';

import '../l10n/gen/app_localizations.dart';
import '../logic/level.dart';
import '../logic/units.dart';
import 'theme.dart';

/// Gravité lue sur l'accéléromètre du téléphone.
Stream<Gravity> phoneGravity() =>
    accelerometerEventStream().map((pEvent) => (x: pEvent.x, y: pEvent.y, z: pEvent.z));

/// Ouvre le niveau pour mesurer un angle ; renvoie l'angle choisi, ou null.
Future<double?> measureAngle(BuildContext pContext, {Stream<Gravity>? pGravity}) =>
    Navigator.push<double>(
      pContext,
      MaterialPageRoute(builder: (_) => LevelScreen(gravity: pGravity, picking: true)),
    );

/// Niveau à bulle et inclinomètre : téléphone posé sur la surface à contrôler.
class LevelScreen extends StatefulWidget {
  const LevelScreen({super.key, this.gravity, this.picking = false});

  /// Mesures de gravité ; remplaçable dans les tests.
  final Stream<Gravity>? gravity;

  /// Ouvert depuis une saisie : un bouton renvoie l'angle mesuré.
  final bool picking;

  @override
  State<LevelScreen> createState() => _LevelScreenState();
}

class _LevelScreenState extends State<LevelScreen> {
  final _samples = <Gravity>[];
  StreamSubscription<Gravity>? _subscription;

  @override
  void initState() {
    super.initState();
    _subscription = (widget.gravity ?? phoneGravity()).listen((pGravity) {
      setState(() {
        _samples.add(pGravity);
        if (_samples.length > 15) {
          _samples.removeAt(0);
        }
      });
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vText = AppLocalizations.of(context);
    final vTheme = Theme.of(context);
    final vGravity = averageGravity(_samples);
    final vTilt = tiltDeg(vGravity);
    final vBubble = bubble(vGravity);
    final vLevel = vTilt < levelToleranceDeg;
    final vColors = vTheme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(vText.levelTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: SizedBox(
              width: 220,
              height: 220,
              child: CustomPaint(
                painter: _BubblePainter(
                  alongDeg: vBubble.alongDeg,
                  acrossDeg: vBubble.acrossDeg,
                  ring: vColors.outline,
                  bubble: vLevel ? vColors.primary : vColors.tertiary,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Center(child: BigFigure('${formatDecimal((vTilt * 10).round() / 10)}°')),
          Center(
            child: Text(
              vLevel
                  ? vText.levelOk
                  : vText.levelSlope(formatDecimal((slopePercent(vTilt) * 10).round() / 10)),
              style: vTheme.textTheme.titleMedium,
            ),
          ),
          const SizedBox(height: 16),
          IconLine(Icons.info_outline, vText.levelHowTo),
          if (widget.picking) ...[
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => Navigator.pop(context, (vTilt * 10).round() / 10),
              icon: const Icon(Icons.check),
              label: Text(vText.levelUse),
            ),
          ],
        ],
      ),
    );
  }
}

class _BubblePainter extends CustomPainter {
  _BubblePainter({
    required this.alongDeg,
    required this.acrossDeg,
    required this.ring,
    required this.bubble,
  });

  final double alongDeg;
  final double acrossDeg;
  final Color ring;
  final Color bubble;

  @override
  void paint(Canvas pCanvas, Size pSize) {
    final vCenter = pSize.center(Offset.zero);
    final vRadius = pSize.shortestSide / 2;
    final vStroke = Paint()
      ..color = ring
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    pCanvas.drawCircle(vCenter, vRadius - 2, vStroke);
    pCanvas.drawCircle(vCenter, vRadius * 0.15, vStroke);
    // 10° d'inclinaison amènent la bulle au bord ; elle monte vers le côté haut
    final vX = (-acrossDeg / 10).clamp(-1.0, 1.0) * (vRadius - 20);
    final vY = (alongDeg / 10).clamp(-1.0, 1.0) * (vRadius - 20);
    pCanvas.drawCircle(vCenter + Offset(vX, vY), 18, Paint()..color = bubble);
  }

  @override
  bool shouldRepaint(_BubblePainter pOld) =>
      pOld.alongDeg != alongDeg || pOld.acrossDeg != acrossDeg || pOld.bubble != bubble;
}
