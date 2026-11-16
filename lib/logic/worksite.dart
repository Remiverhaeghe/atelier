/// Chantier : un nom et des pièces.
library;

import 'room.dart';

class Worksite {
  const Worksite({
    required this.id,
    required this.name,
    this.rooms = const [],
    this.prices = const {},
    this.showGuidance = true,
  });

  final String id;
  final String name;
  final List<Room> rooms;

  /// Prix unitaires saisis, par nom d'article (voir ShoppingItem).
  final Map<String, double> prices;

  /// Onglet Guide affiché ; masquable pour qui ne veut que les calculs.
  final bool showGuidance;

  Worksite copyWith({
    String? id,
    String? name,
    List<Room>? rooms,
    Map<String, double>? prices,
    bool? showGuidance,
  }) => Worksite(
    id: id ?? this.id,
    name: name ?? this.name,
    rooms: rooms ?? this.rooms,
    prices: prices ?? this.prices,
    showGuidance: showGuidance ?? this.showGuidance,
  );

  Map<String, Object?> toJson() => {
    'id': id,
    'name': name,
    'rooms': [for (final vRoom in rooms) vRoom.toJson()],
    'prices': prices,
    'showGuidance': showGuidance,
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
  );
}
