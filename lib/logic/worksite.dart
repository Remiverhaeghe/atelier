/// Chantier : un nom et des pièces.
library;

import 'room.dart';

class Worksite {
  const Worksite({required this.id, required this.name, this.rooms = const []});

  final String id;
  final String name;
  final List<Room> rooms;

  Worksite copyWith({String? name, List<Room>? rooms}) =>
      Worksite(id: id, name: name ?? this.name, rooms: rooms ?? this.rooms);

  Map<String, Object?> toJson() => {
    'id': id,
    'name': name,
    'rooms': [for (final vRoom in rooms) vRoom.toJson()],
  };

  static Worksite fromJson(Map<String, Object?> pJson) => Worksite(
    id: pJson['id']! as String,
    name: pJson['name']! as String,
    rooms: [
      for (final vRoom in (pJson['rooms'] as List<Object?>?) ?? const [])
        Room.fromJson(vRoom! as Map<String, Object?>),
    ],
  );
}
