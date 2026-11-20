import 'dart:typed_data';

import 'package:atelier/logic/touch_up.dart';
import 'package:atelier/ui/room_video_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/localized.dart';

/// Vidéo fictive de 30 s, arrêtée à 12 s.
class FakeVideo extends ChangeNotifier implements RoomVideo {
  @override
  Duration position = const Duration(seconds: 12);

  @override
  bool playing = false;

  @override
  Future<void> initialize() async {}

  @override
  Widget view() => const SizedBox(height: 120, child: Placeholder());

  @override
  Duration get length => const Duration(seconds: 30);

  @override
  Future<void> play() async => playing = true;

  @override
  Future<void> pause() async => playing = false;

  @override
  Future<void> seekTo(Duration pAt) async {
    position = pAt;
    notifyListeners();
  }
}

Widget opener(void Function(List<TouchUp>?) pResult, FrameGrabber pGrab) => localized(
  Builder(
    builder: (pContext) => TextButton(
      onPressed: () async => pResult(
        await Navigator.push<List<TouchUp>>(
          pContext,
          MaterialPageRoute(
            builder: (_) => RoomVideoScreen(
              videoPath: 'piece.mp4',
              video: FakeVideo(),
              grab: pGrab,
              annotate: (_, _, _) async => const [(x: 0.5, y: 0.5)],
              keep: (pName, _) async => 'photos/$pName',
            ),
          ),
        ),
      ),
      child: const Text('ouvrir'),
    ),
  ),
);

void main() {
  testWidgets('un défaut repéré sur la vidéo devient une reprise avec son image', (pTester) async {
    tallScreen(pTester);
    List<TouchUp>? vTouchUps;
    await pTester.pumpWidget(opener((pValue) => vTouchUps = pValue, (_, _) async => Uint8List(4)));
    await pTester.tap(find.text('ouvrir'));
    await pTester.pumpAndSettle();

    await pTester.tap(find.text('Repérer ici'));
    await pTester.pumpAndSettle();
    await pTester.enterText(find.byType(TextField), 'Trace de rouleau');
    await pTester.tap(find.text('Enregistrer'));
    await pTester.pumpAndSettle();

    expect(find.text('Vu sur la vidéo à 0:12'), findsOneWidget);
    await pTester.tap(find.text('Ajouter 1 reprise'));
    await pTester.pumpAndSettle();

    final vTouchUp = vTouchUps!.single;
    expect(vTouchUp.label, 'Trace de rouleau');
    expect(vTouchUp.note, 'Vu sur la vidéo à 0:12');
    expect(vTouchUp.photoPath, startsWith('photos/video-'));
    expect(vTouchUp.photoMarks, [(x: 0.5, y: 0.5)]);
  });

  testWidgets('image illisible : message, rien n\'est ajouté', (pTester) async {
    tallScreen(pTester);
    await pTester.pumpWidget(opener((_) {}, (_, _) async => null));
    await pTester.tap(find.text('ouvrir'));
    await pTester.pumpAndSettle();
    await pTester.tap(find.text('Repérer ici'));
    await pTester.pumpAndSettle();

    expect(find.textContaining("n'a pas pu être lue"), findsOneWidget);
    expect(find.textContaining('Ajouter'), findsNothing);
  });
}
