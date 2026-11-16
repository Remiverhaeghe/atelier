/// Chantier : un nom et des pièces.
library;

import 'expenses.dart';
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
    this.ownedTools = const [],
    this.stock = const {},
    this.expenses = const [],
    this.bought = const [],
    this.stores = const {},
    this.references = const {},
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

  /// Outils déjà là, par nom (voir Tool) ; vide tant que l'inventaire n'est pas fait.
  final List<String> ownedTools;

  /// Articles déjà en stock, par nom d'article (voir ShoppingItem).
  final Map<String, int> stock;

  /// Achats réellement faits.
  final List<Expense> expenses;

  /// Articles déjà mis dans le chariot, par nom d'article.
  final List<String> bought;

  /// Magasin ou rayon de chaque article, et référence qui convient.
  final Map<String, String> stores;
  final Map<String, String> references;

  Worksite copyWith({
    String? id,
    String? name,
    List<Room>? rooms,
    Map<String, double>? prices,
    bool? showGuidance,
    DailyGoal? goal,
    int? goalsReached,
    List<String>? ownedTools,
    Map<String, int>? stock,
    List<Expense>? expenses,
    List<String>? bought,
    Map<String, String>? stores,
    Map<String, String>? references,
  }) => Worksite(
    id: id ?? this.id,
    name: name ?? this.name,
    rooms: rooms ?? this.rooms,
    prices: prices ?? this.prices,
    showGuidance: showGuidance ?? this.showGuidance,
    goal: goal ?? this.goal,
    goalsReached: goalsReached ?? this.goalsReached,
    ownedTools: ownedTools ?? this.ownedTools,
    stock: stock ?? this.stock,
    expenses: expenses ?? this.expenses,
    bought: bought ?? this.bought,
    stores: stores ?? this.stores,
    references: references ?? this.references,
  );

  Map<String, Object?> toJson() => {
    'id': id,
    'name': name,
    'rooms': [for (final vRoom in rooms) vRoom.toJson()],
    'prices': prices,
    'showGuidance': showGuidance,
    if (goal != null) 'goal': goal!.toJson(),
    'goalsReached': goalsReached,
    if (ownedTools.isNotEmpty) 'ownedTools': ownedTools,
    if (stock.isNotEmpty) 'stock': stock,
    if (expenses.isNotEmpty) 'expenses': [for (final vExpense in expenses) vExpense.toJson()],
    if (bought.isNotEmpty) 'bought': bought,
    if (stores.isNotEmpty) 'stores': stores,
    if (references.isNotEmpty) 'references': references,
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
    ownedTools: [
      for (final vTool in (pJson['ownedTools'] as List<Object?>?) ?? const []) vTool! as String,
    ],
    stock: {
      for (final vEntry in ((pJson['stock'] as Map<String, Object?>?) ?? const {}).entries)
        vEntry.key: vEntry.value! as int,
    },
    expenses: [
      for (final vExpense in (pJson['expenses'] as List<Object?>?) ?? const [])
        Expense.fromJson(vExpense! as Map<String, Object?>),
    ],
    bought: [for (final vItem in (pJson['bought'] as List<Object?>?) ?? const []) vItem! as String],
    stores: _texts(pJson['stores']),
    references: _texts(pJson['references']),
  );
}

Map<String, String> _texts(Object? pJson) => {
  for (final vEntry in ((pJson as Map<String, Object?>?) ?? const {}).entries)
    vEntry.key: vEntry.value! as String,
};
