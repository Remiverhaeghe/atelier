/// Reprises : choses à faire ou à reprendre dans une pièce, en un ou plusieurs passages.
library;

/// Une reprise : son nom, ses passages (trois couches, quatre passes d'enduit…) et ses repères.
class TouchUp {
  const TouchUp({
    required this.id,
    required this.label,
    this.passes = 1,
    this.donePasses = 0,
    this.note = '',
    this.toBuy = '',
    this.markerXMm,
    this.markerYMm,
    this.photoPath,
    this.photoMarks = const [],
  });

  final String id;
  final String label;

  /// Passages prévus, au moins un.
  final int passes;
  final int donePasses;

  /// Produit, référence ou mesure, en quelques mots.
  final String note;

  /// Matériel à acheter pour cette reprise ; vide si rien.
  final String toBuy;

  /// Repère sur le plan, dans le repère des murs (millimètres) ; absent si non placé.
  final int? markerXMm;
  final int? markerYMm;

  /// Photo gardée dans le dossier de l'application.
  final String? photoPath;

  /// Cercles posés sur la photo, en fraction de sa largeur et de sa hauteur (0 à 1).
  final List<({double x, double y})> photoMarks;

  bool get done => donePasses >= passes;
  bool get hasMarker => markerXMm != null && markerYMm != null;

  /// Coche ou décoche le passage [pIndex] : cocher la 3e case coche aussi les deux premières.
  TouchUp togglePass(int pIndex) {
    final vDone = pIndex < donePasses ? pIndex : pIndex + 1;

    return copyWith(donePasses: vDone.clamp(0, passes));
  }

  TouchUp copyWith({
    String? label,
    int? passes,
    int? donePasses,
    String? note,
    String? toBuy,
    int? markerXMm,
    int? markerYMm,
    String? photoPath,
    bool clearMarker = false,
    bool clearPhoto = false,
    List<({double x, double y})>? photoMarks,
  }) {
    final vPasses = passes ?? this.passes;

    return TouchUp(
      id: id,
      label: label ?? this.label,
      passes: vPasses,
      donePasses: (donePasses ?? this.donePasses).clamp(0, vPasses),
      note: note ?? this.note,
      toBuy: toBuy ?? this.toBuy,
      markerXMm: clearMarker ? null : (markerXMm ?? this.markerXMm),
      markerYMm: clearMarker ? null : (markerYMm ?? this.markerYMm),
      photoPath: clearPhoto ? null : (photoPath ?? this.photoPath),
      photoMarks: clearPhoto ? const [] : (photoMarks ?? this.photoMarks),
    );
  }

  Map<String, Object?> toJson() => {
    'id': id,
    'label': label,
    'passes': passes,
    'donePasses': donePasses,
    if (note.isNotEmpty) 'note': note,
    if (toBuy.isNotEmpty) 'toBuy': toBuy,
    if (hasMarker) 'markerXMm': markerXMm,
    if (hasMarker) 'markerYMm': markerYMm,
    if (photoPath != null) 'photoPath': photoPath,
    if (photoMarks.isNotEmpty)
      'photoMarks': [
        for (final vMark in photoMarks) [vMark.x, vMark.y],
      ],
  };

  static TouchUp fromJson(Map<String, Object?> pJson) {
    final vPasses = _atLeastOne((pJson['passes'] as int?) ?? 1);

    return TouchUp(
      id: pJson['id']! as String,
      label: pJson['label']! as String,
      passes: vPasses,
      donePasses: ((pJson['donePasses'] as int?) ?? 0).clamp(0, vPasses),
      note: (pJson['note'] as String?) ?? '',
      toBuy: (pJson['toBuy'] as String?) ?? '',
      markerXMm: pJson['markerXMm'] as int?,
      markerYMm: pJson['markerYMm'] as int?,
      photoPath: pJson['photoPath'] as String?,
      photoMarks: [
        for (final vMark in (pJson['photoMarks'] as List<Object?>?) ?? const [])
          _mark(vMark! as List<Object?>),
      ],
    );
  }
}

/// Repère relu depuis le JSON, ramené dans la photo.
({double x, double y}) _mark(List<Object?> pJson) => (
  x: (pJson[0]! as num).toDouble().clamp(0.0, 1.0),
  y: (pJson[1]! as num).toDouble().clamp(0.0, 1.0),
);

/// Une reprise a toujours au moins un passage.
int _atLeastOne(int pValue) => pValue < 1 ? 1 : pValue;

/// Passages faits et prévus sur une liste de reprises.
({int done, int total}) touchUpPasses(List<TouchUp> pTouchUps) => (
  done: pTouchUps.fold(0, (pSum, pTouchUp) => pSum + pTouchUp.donePasses),
  total: pTouchUps.fold(0, (pSum, pTouchUp) => pSum + pTouchUp.passes),
);

/// Matériel à acheter pour les reprises pas encore finies, dans l'ordre de la liste.
List<String> touchUpPurchases(List<TouchUp> pTouchUps) => [
  for (final vTouchUp in pTouchUps)
    if (!vTouchUp.done && vTouchUp.toBuy.isNotEmpty) vTouchUp.toBuy,
];
