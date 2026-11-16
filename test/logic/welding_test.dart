import 'package:atelier/logic/welding.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('procédés conseillés selon le métal et l\'épaisseur', () {
    expect(rankProcesses(Metal.aluminium, 3).first, WeldProcess.tig);
    expect(rankProcesses(Metal.aluminium, 3), isNot(contains(WeldProcess.stick)));
    expect(rankProcesses(Metal.stainless, 1.5).first, WeldProcess.tig);
    expect(rankProcesses(Metal.stainless, 5).first, WeldProcess.migMag);
    expect(rankProcesses(Metal.steel, 1).first, WeldProcess.migMag);
    expect(rankProcesses(Metal.steel, 1), isNot(contains(WeldProcess.stick)));
    expect(rankProcesses(Metal.steel, 4), contains(WeldProcess.stick));
  });

  test('dehors, l\'électrode et le fil fourré passent devant', () {
    expect(rankProcesses(Metal.steel, 4, pOutdoor: true).take(2), [
      WeldProcess.stick,
      WeldProcess.fluxCore,
    ]);
    expect(rankProcesses(Metal.aluminium, 3, pOutdoor: true), [
      WeldProcess.tig,
      WeldProcess.migMag,
    ]);
  });

  test('réglages de départ : électrode, fil, tungstène', () {
    expect(weldSetting(WeldProcess.stick, 3), (
      process: WeldProcess.stick,
      minAmps: 88,
      maxAmps: 113,
      diameterMm: 2.5,
    ));
    expect(weldSetting(WeldProcess.stick, 1).diameterMm, 2.0);
    expect(weldSetting(WeldProcess.stick, 5).diameterMm, 3.2);
    expect(weldSetting(WeldProcess.stick, 8).diameterMm, 4.0);
    expect(weldSetting(WeldProcess.migMag, 2), (
      process: WeldProcess.migMag,
      minAmps: 60,
      maxAmps: 80,
      diameterMm: 0.6,
    ));
    expect(weldSetting(WeldProcess.fluxCore, 4).diameterMm, 0.8);
    expect(weldSetting(WeldProcess.migMag, 6).diameterMm, 1.0);
    expect(weldSetting(WeldProcess.tig, 2).diameterMm, 1.6);
    expect(weldSetting(WeldProcess.tig, 0).minAmps, 30);
    expect(weldSetting(WeldProcess.tig, 4).diameterMm, 2.4);
  });
}
