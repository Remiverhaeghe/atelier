/// Humidité avant la pose : relevés de l'humidimètre et feu vert pour le parquet.
library;

/// Support mesuré, et humidité à ne pas dépasser avant de poser du parquet, en pour cent.
///
/// Chape ciment et chape anhydrite se mesurent à la bombe à carbure (méthode CM) ; le bois,
/// à l'humidimètre à pointes, doit être ni trop sec ni trop humide.
enum MoistureMaterial {
  cementScreed(0, 2.0),
  anhydriteScreed(0, 0.5),
  wood(7, 11);

  const MoistureMaterial(this.minPercent, this.maxPercent);

  final double minPercent;
  final double maxPercent;
}

class MoistureReading {
  const MoistureReading({
    required this.id,
    required this.material,
    required this.day,
    required this.percent,
    this.roomId,
  });

  final String id;
  final MoistureMaterial material;

  /// Jour du relevé, au format AAAA-MM-JJ.
  final String day;
  final double percent;
  final String? roomId;

  Map<String, Object?> toJson() => {
    'id': id,
    'material': material.name,
    'day': day,
    'percent': percent,
    if (roomId != null) 'roomId': roomId,
  };

  static MoistureReading fromJson(Map<String, Object?> pJson) => MoistureReading(
    id: pJson['id']! as String,
    material: MoistureMaterial.values.asNameMap()[pJson['material']] ?? MoistureMaterial.wood,
    day: pJson['day']! as String,
    percent: (pJson['percent']! as num).toDouble(),
    roomId: pJson['roomId'] as String?,
  );
}

enum MoistureState { ready, tooWet, tooDry }

MoistureState moistureState(MoistureMaterial pMaterial, double pPercent) {
  final rState = pPercent > pMaterial.maxPercent
      ? MoistureState.tooWet
      : (pPercent < pMaterial.minPercent ? MoistureState.tooDry : MoistureState.ready);

  return rState;
}

/// Verdict d'une série : le dernier relevé décide ; s'il est trop humide et que ça sèche, nombre
/// de jours estimé au rythme des deux derniers relevés, sinon null.
typedef MoistureVerdict = ({MoistureState state, double last, int? daysLeft});

MoistureVerdict? moistureVerdict(List<MoistureReading> pReadings) {
  if (pReadings.isEmpty) {
    return null;
  }
  final vSorted = [...pReadings]..sort((pA, pB) => pA.day.compareTo(pB.day));
  final vLast = vSorted.last;
  final vState = moistureState(vLast.material, vLast.percent);
  int? vDays;
  if (vState == MoistureState.tooWet && vSorted.length > 1) {
    final vBefore = vSorted[vSorted.length - 2];
    final vElapsed = DateTime.parse(vLast.day).difference(DateTime.parse(vBefore.day)).inDays;
    final vDrop = vBefore.percent - vLast.percent;
    if (vElapsed > 0 && vDrop > 0) {
      // Marge contre l'arrondi des décimaux : 6,0000001 jours font 6 jours
      vDays = ((vLast.percent - vLast.material.maxPercent) / (vDrop / vElapsed) - 1e-6).ceil();
    }
  }
  final rVerdict = (state: vState, last: vLast.percent, daysLeft: vDays);

  return rVerdict;
}
