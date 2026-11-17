import 'package:atelier/logic/whats_new.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('nouveautés après une mise à jour, pas à la première installation', () {
    expect(shouldShowNews(pSeen: 0, pHasData: true), isTrue);
    expect(shouldShowNews(pSeen: newsVersion, pHasData: true), isFalse);
    expect(shouldShowNews(pSeen: 0, pHasData: false), isFalse);
  });
}
