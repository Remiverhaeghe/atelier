import 'package:atelier/logic/fixtures.dart';
import 'package:atelier/logic/hidden_networks.dart';
import 'package:atelier/logic/house_book.dart';
import 'package:atelier/logic/journal.dart';
import 'package:atelier/logic/room.dart';
import 'package:atelier/logic/room_copy.dart';
import 'package:atelier/logic/worksite.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/rooms.dart';

const _aRun = HiddenRun(
  id: 'r1',
  kind: NetworkKind.electric,
  wallIndex: 1,
  fromAlongMm: 300,
  fromHeightMm: 300,
  toAlongMm: 300,
  toHeightMm: 1100,
);

const _aJoists = JoistSet(
  id: 's1',
  place: JoistPlace.ceiling,
  wallIndex: 0,
  firstMm: 200,
  spacingMm: 600,
);

const _aPhoto = ClosingPhoto(
  id: 'p1',
  wallIndex: 1,
  path: '/photos/mur2.jpg',
  day: '2026-11-02',
  note: 'Gaine à 30 cm du coin',
);

void main() {
  test('axes des solives le long du mur, jusqu’au bout', () {
    final vRoom = rectangleRoom();
    expect(joistAxes(vRoom, _aJoists), [200, 800, 1400, 2000, 2600, 3200, 3800]);
    // Mur inconnu ou entraxe nul : rien
    expect(
      joistAxes(
        vRoom,
        const JoistSet(id: 'x', place: JoistPlace.floor, wallIndex: 9, firstMm: 0, spacingMm: 600),
      ),
      isEmpty,
    );
    expect(
      joistAxes(
        vRoom,
        const JoistSet(id: 'x', place: JoistPlace.floor, wallIndex: 0, firstMm: 0, spacingMm: 0),
      ),
      isEmpty,
    );
  });

  test('le caché de la pièce se relit à l’identique', () {
    final vRoom = rectangleRoom().copyWith(
      behindWalls: const BehindWalls(joists: [_aJoists], photos: [_aPhoto]),
    );
    final vBack = Room.fromJson(vRoom.toJson());
    expect(vBack.behindWalls.joists.single.toJson(), _aJoists.toJson());
    expect(vBack.behindWalls.photos.single.toJson(), _aPhoto.toJson());
    // Pièce sans rien de caché : le champ n'est pas écrit
    expect(rectangleRoom().toJson().containsKey('behindWalls'), isFalse);
    expect(Room.fromJson(rectangleRoom().toJson()).behindWalls.isEmpty, isTrue);
    // Valeurs absentes des anciens fichiers
    final vOld = JoistSet.fromJson({
      'id': 'o',
      'place': 'inconnu',
      'wallIndex': 0,
      'firstMm': 0,
      'spacingMm': 500,
    });
    expect((vOld.place, vOld.widthMm, vOld.heightMm), (JoistPlace.floor, 75, 200));
    expect(
      ClosingPhoto.fromJson({'id': 'q', 'wallIndex': -1, 'path': 'a', 'day': '2026-01-01'}).note,
      '',
    );
    expect(const BehindWalls().copyWith(photos: [_aPhoto]).photos, hasLength(1));
  });

  test('une copie de pièce ne reprend ni solives ni photos', () {
    final vRoom = rectangleRoom().copyWith(
      behindWalls: const BehindWalls(joists: [_aJoists], photos: [_aPhoto]),
    );
    expect(duplicateRoom(vRoom, pId: 'c', pName: 'Copie').behindWalls.isEmpty, isTrue);
  });

  test('fenêtres de la pièce et fenêtres de toit', () {
    final vRoom = rectangleRoom().copyWith(
      walls: const [
        Wall(
          lengthMm: 4000,
          openings: [Opening(kind: OpeningKind.window, offsetMm: 1000, widthMm: 1200)],
        ),
        Wall(
          lengthMm: 3000,
          openings: [Opening(kind: OpeningKind.door, offsetMm: 100, widthMm: 830)],
        ),
        Wall(lengthMm: 4000),
        Wall(lengthMm: 3000),
      ],
      fixtures: const [
        Fixture(
          id: 'v',
          kind: FixtureKind.roofWindow,
          xMm: 2000,
          yMm: 1500,
          widthMm: 780,
          depthMm: 980,
        ),
      ],
    );
    final vWindows = windowsOf(vRoom);
    expect(vWindows, hasLength(2));
    expect(vWindows.first, (
      wallNumber: 1,
      widthMm: 1200,
      heightMm: 1250,
      sillMm: 900,
      roof: false,
    ));
    expect(vWindows.last.roof, isTrue);
    expect(vWindows.last.heightMm, 980);
  });

  test('murs à photographier : réseaux relevés sans photo', () {
    final vRoom = rectangleRoom().copyWith(
      networks: [
        _aRun,
        const HiddenRun(
          id: 'r2',
          kind: NetworkKind.water,
          wallIndex: 3,
          fromAlongMm: 0,
          fromHeightMm: 500,
          toAlongMm: 1000,
          toHeightMm: 500,
        ),
      ],
    );
    expect(wallsToPhotograph(vRoom), [1, 3]);
    final vDone = vRoom.copyWith(behindWalls: const BehindWalls(photos: [_aPhoto]));
    expect(wallsToPhotograph(vDone), [3]);
  });

  test('dossier de la maison : une page par pièce qui a quelque chose à dire', () {
    final vSalon = rectangleRoom().copyWith(networks: [_aRun]);
    const vEmpty = Room(id: 'vide', name: 'Débarras', walls: [Wall(lengthMm: 2000)]);
    const vCuisine = Room(id: 'cuisine', name: 'Cuisine');
    final vWorksite = Worksite(
      id: 'w',
      name: 'Maison fictive',
      rooms: [vSalon, vEmpty, vCuisine],
      journal: const [
        JournalEntry(
          id: 'j1',
          roomId: 'cuisine',
          day: '2026-09-01',
          title: 'Carrelage',
          product: 'Grès cérame gris',
          reference: 'REF-0001',
        ),
        JournalEntry(id: 'j2', roomId: 'cuisine', day: '2026-09-02', title: 'Ménage'),
      ],
    );
    final vBook = houseBook(vWorksite);
    expect(vBook.map((pPage) => pPage.room.name), ['Salon', 'Cuisine']);
    expect(vBook.first.networkLengths, {NetworkKind.electric: 800});
    expect(vBook.first.toPhotograph, [1]);
    expect(vBook.last.references.single.reference, 'REF-0001');
    expect(houseBook(const Worksite(id: 'v', name: 'Vide')), isEmpty);
  });
}
