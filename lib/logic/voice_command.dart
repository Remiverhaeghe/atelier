/// Commandes vocales du mode chantier : la phrase entendue devient une action, mains occupées.
library;

import 'search.dart';

enum VoiceTarget { cut, row }

enum VoiceAction { read, done }

typedef VoiceCommand = ({VoiceTarget? target, VoiceAction action});

const _aCutWords = ['coupe', 'plinthe', 'plinthes'];
const _aRowWords = ['rangee', 'lame', 'lames', 'parquet', 'rang'];
const _aDoneWords = [
  'fait',
  'faite',
  'termine',
  'terminee',
  'fini',
  'finie',
  'suivant',
  'suivante',
  'ok',
];
const _aReadWords = [
  'lis',
  'lire',
  'repete',
  'repeter',
  'redis',
  'dis',
  'quoi',
  'quelle',
  'combien',
];

/// Action reconnue dans la phrase, sinon null. La cible manque quand on a seulement dit
/// « fait » : l'écran prend alors la seule tâche en cours.
VoiceCommand? parseVoiceCommand(String pHeard) {
  final vWords = plainText(pHeard).split(RegExp(r"[\s,.!?']+")).toSet();
  bool vHas(List<String> pList) => pList.any(vWords.contains);
  final vTarget = vHas(_aCutWords) ? VoiceTarget.cut : (vHas(_aRowWords) ? VoiceTarget.row : null);
  // « Fait » l'emporte : on ne coche jamais par erreur en demandant une relecture, mais on
  // relit si rien d'autre n'est compris
  final VoiceAction? vAction = vHas(_aDoneWords)
      ? VoiceAction.done
      : (vHas(_aReadWords) || vTarget != null ? VoiceAction.read : null);
  if (vAction == null) {
    return null;
  }

  return (target: vTarget, action: vAction);
}

/// Cible retenue : celle qui a été dite, sinon la seule tâche encore ouverte.
VoiceTarget? resolveTarget(
  VoiceCommand pCommand, {
  required bool pCutOpen,
  required bool pRowOpen,
}) {
  if (pCommand.target != null) {
    return pCommand.target;
  }
  final rTarget = pCutOpen == pRowOpen ? null : (pCutOpen ? VoiceTarget.cut : VoiceTarget.row);

  return rTarget;
}
