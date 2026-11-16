/// Chantier : un nom et des pièces.
library;

import 'goals.dart';
import 'room.dart';

class Worksite {
  const Worksite({
    required this.id,
    required this.name,
    this.rooms = const [],
    this.prices = const {},
    this.showGuidance = true,
    this.goal,
    this.goalsReached = 0,
  });

  final String id;
  final String name;
  final List<Room> rooms;

  /// Prix unitaires saisis, par nom d'article (voir ShoppingItem).
  final Map<String, double> prices;

  /// Onglet Guide affiché ; masquable pour qui ne veut que les calculs.
  final bool showGuidance;

  /// Objectif du jour en cours, ou le dernier fixé.
  final DailyGoal? goal;

  /// Objectifs atteints jusqu'ici, pour les badges.
  final int goalsReached;

  Worksite copyWith({
    String? id,
    String? name,
    List<Room>? rooms,
    Map<String, double>? prices,
    bool? showGuidance,
    DailyGoal? goal,
    int? goalsReached,
  }) => Worksite(
    id: id ?? this.id,
    name: name ?? this.name,
    rooms: rooms ?? this.rooms,
    prices: prices ?? this.prices,
    showGuidance: showGuidance ?? this.showGuidance,
    goal: goal ?? this.goal,
    goalsReached: goalsReached ?? this.goalsReached,
  );

  Map<String, Object?> toJson() => {
    'id': id,
    'name': name,
    'rooms': [for (final vRoom in rooms) vRoom.toJson()],
    'prices': prices,
    'showGuidance': showGuidance,
    if (goal != null) 'goal': goal!.toJson(),
    'goalsReached': goalsReached,
  };

  static Worksite fromJson(Map<String, Object?> pJson) => Worksite(
    id: pJson['id']! as String,
    name: pJson['name']! as String,
    rooms: [
      for (final vRoom in (pJson['rooms'] as List<Object?>?) ?? const [])
        Room.fromJson(vRoom! as Map<String, Object?>),
    ],
    prices: {
      for (final vEntry in ((pJson['prices'] as Map<String, Object?>?) ?? const {}).entries)
        vEntry.key: (vEntry.value! as num).toDouble(),
    },
    showGuidance: (pJson['showGuidance'] as bool?) ?? true,
    goal: pJson['goal'] == null ? null : DailyGoal.fromJson(pJson['goal']! as Map<String, Object?>),
    goalsReached: (pJson['goalsReached'] as int?) ?? 0,
  );
}
