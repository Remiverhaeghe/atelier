import 'package:atelier/logic/voice_command.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('phrases du chantier', () {
    expect(parseVoiceCommand('Coupe faite'), (target: VoiceTarget.cut, action: VoiceAction.done));
    expect(parseVoiceCommand('répète la rangée'), (
      target: VoiceTarget.row,
      action: VoiceAction.read,
    ));
    expect(parseVoiceCommand('plinthe'), (target: VoiceTarget.cut, action: VoiceAction.read));
    expect(parseVoiceCommand('OK, suivant !'), (target: null, action: VoiceAction.done));
    expect(parseVoiceCommand('bonjour'), isNull);
    expect(parseVoiceCommand(''), isNull);
  });

  test('sans cible dite, la seule tâche ouverte', () {
    const vDone = (target: null, action: VoiceAction.done);
    expect(resolveTarget(vDone, pCutOpen: true, pRowOpen: false), VoiceTarget.cut);
    expect(resolveTarget(vDone, pCutOpen: false, pRowOpen: true), VoiceTarget.row);
    expect(resolveTarget(vDone, pCutOpen: true, pRowOpen: true), isNull);
    const vRead = (target: VoiceTarget.row, action: VoiceAction.read);
    expect(resolveTarget(vRead, pCutOpen: true, pRowOpen: true), VoiceTarget.row);
  });
}
