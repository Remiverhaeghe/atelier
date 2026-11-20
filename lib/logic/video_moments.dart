/// Moments repérés en relisant la vidéo d'une pièce : chacun devient une reprise avec
/// l'image arrêtée, entourée là où il faut reprendre.
library;

import 'touch_up.dart';

/// Un moment repéré : où il est dans la vidéo, l'image gardée et ce qu'on y a entouré.
typedef VideoMoment = ({
  Duration at,
  String label,
  String photoPath,
  List<({double x, double y})> marks,
});

/// Minutes et secondes d'un moment de la vidéo : « 1:05 ».
String formatVideoTime(Duration pAt) {
  final vSeconds = pAt.inSeconds;
  final rText = '${vSeconds ~/ 60}:${(vSeconds % 60).toString().padLeft(2, '0')}';

  return rText;
}

/// Reprises tirées des moments, dans l'ordre de la vidéo ; [pNote] écrit la note
/// d'après l'heure du moment, [pId] donne l'identifiant de chaque reprise.
List<TouchUp> touchUpsFromMoments(
  List<VideoMoment> pMoments,
  String Function(String pTime) pNote,
  String Function(int pIndex) pId,
) {
  final vSorted = [...pMoments]..sort((pA, pB) => pA.at.compareTo(pB.at));
  final rTouchUps = [
    for (final (vIndex, vMoment) in vSorted.indexed)
      TouchUp(
        id: pId(vIndex),
        label: vMoment.label,
        note: pNote(formatVideoTime(vMoment.at)),
        photoPath: vMoment.photoPath,
        photoMarks: vMoment.marks,
      ),
  ];

  return rTouchUps;
}
