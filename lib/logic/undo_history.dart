/// Historique pour annuler et refaire : les états d'avant, et ceux qu'on vient d'annuler.
library;

class UndoHistory<T> {
  UndoHistory({this.limit = 30, this.mergeWithin = const Duration(seconds: 1)});

  /// Nombre d'états gardés : au-delà, les plus anciens sont oubliés.
  final int limit;

  /// Changements rapprochés (une saisie chiffre par chiffre) regroupés en une seule étape.
  final Duration mergeWithin;

  final _aPast = <T>[];
  final _aFuture = <T>[];
  DateTime? _aLast;

  bool get canUndo => _aPast.isNotEmpty;
  bool get canRedo => _aFuture.isNotEmpty;

  /// Note l'état [pBefore] qu'on s'apprête à quitter, à l'instant [pNow].
  void record(T pBefore, DateTime pNow) {
    final vLast = _aLast;
    _aLast = pNow;
    _aFuture.clear();
    if (vLast != null && pNow.difference(vLast) < mergeWithin && _aPast.isNotEmpty) {
      return;
    }
    _aPast.add(pBefore);
    if (_aPast.length > limit) {
      _aPast.removeAt(0);
    }
  }

  /// État d'avant [pCurrent], qui part dans les états à refaire ; null s'il n'y en a pas.
  T? undo(T pCurrent) {
    if (_aPast.isEmpty) {
      return null;
    }
    _aFuture.add(pCurrent);
    _aLast = null;

    return _aPast.removeLast();
  }

  /// État annulé en dernier, [pCurrent] repartant dans le passé ; null s'il n'y en a pas.
  T? redo(T pCurrent) {
    if (_aFuture.isEmpty) {
      return null;
    }
    _aPast.add(pCurrent);
    _aLast = null;

    return _aFuture.removeLast();
  }
}
