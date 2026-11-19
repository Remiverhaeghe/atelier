#!/usr/bin/env bash
# Réunit tous les tests de test/ (sauf les captures) dans test/tous_test.dart.
#
# Lancés fichier par fichier, les 250 tests sont compilés 250 fois : c'est ce qui prend le plus
# de temps en CI. Réunis, ils sont compilés une seule fois. Chaque fichier reste un groupe à son
# nom, pour retrouver d'où vient un échec.
set -euo pipefail
cd "$(dirname "$0")/.."
mapfile -t vFiles < <(find test -name '*_test.dart' -not -path 'test/captures/*' -not -name 'tous_test.dart' | sort)
{
  echo "// Généré par tool/tous_les_tests.sh, ne pas modifier."
  echo "import 'package:flutter_test/flutter_test.dart';"
  echo
  for vIndex in "${!vFiles[@]}"; do
    echo "import '${vFiles[$vIndex]#test/}' as t$vIndex;"
  done
  echo
  echo "void main() {"
  for vIndex in "${!vFiles[@]}"; do
    echo "  group('${vFiles[$vIndex]#test/}', t$vIndex.main);"
  done
  echo "}"
} > test/tous_test.dart
echo "${#vFiles[@]} fichiers de test réunis dans test/tous_test.dart"
