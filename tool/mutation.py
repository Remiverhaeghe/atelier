"""Tests de mutation sur lib/logic : on glisse une petite erreur dans le code et on vérifie
qu'un test la voit. Un mutant qui survit montre un calcul que les tests ne contrôlent pas."""

import argparse
import random
import re
import subprocess
import sys
from pathlib import Path

# Remplacements tentés, du plus courant au plus fin
MUTATIONS = [
    (r"(?<![<>=!])<=(?!=)", "<"),
    (r"(?<![<>=!])>=(?!=)", ">"),
    (r"(?<![<>=!-])<(?![<=])", "<="),
    (r"(?<![<>=!-])>(?![>=])", ">="),
    (r"==", "!="),
    (r"!=", "=="),
    (r"&&", "||"),
    (r"\|\|", "&&"),
    (r"(?<=[\w)\]]) \+ (?=[\w(])", " - "),
    (r"(?<=[\w)\]]) - (?=[\w(])", " + "),
    (r"(?<=[\w)\]]) \* (?=[\w(])", " / "),
    (r"\.ceil\(\)", ".floor()"),
    (r"\.floor\(\)", ".ceil()"),
]

# Lignes à laisser : commentaires, imports, textes et signatures de types génériques
IGNORE = re.compile(r"^\s*(//|///|import |library|part |export )|=>\s*'|<[A-Z]\w*(, ?\w+)*>")


def mutants(pFile):
    """Toutes les mutations possibles d'un fichier : (numéro de ligne, ligne mutée)."""
    rFound = []
    for vNumber, vLine in enumerate(pFile.read_text(encoding="utf-8").splitlines()):
        if IGNORE.search(vLine) or "'" in vLine:
            continue
        for vPattern, vReplacement in MUTATIONS:
            for vMatch in re.finditer(vPattern, vLine):
                vMutated = vLine[: vMatch.start()] + vReplacement + vLine[vMatch.end() :]
                rFound.append((vNumber, vMutated))
    return rFound


def test_for(pFile):
    """Test unitaire du fichier s'il existe, sinon tous les tests de lib/logic."""
    vTest = Path("test/logic") / f"{pFile.stem}_test.dart"
    return str(vTest) if vTest.exists() else "test/logic"


def killed(pFile, pNumber, pMutated):
    """Vrai si les tests échouent avec la ligne mutée ; le fichier est toujours remis."""
    vOriginal = pFile.read_text(encoding="utf-8")
    vLines = vOriginal.splitlines()
    vLines[pNumber] = pMutated
    pFile.write_text("\n".join(vLines) + "\n", encoding="utf-8")
    try:
        vRun = subprocess.run(
            ["flutter", "test", "--no-pub", test_for(pFile)],
            capture_output=True,
            timeout=600,
            check=False,
        )
        return vRun.returncode != 0
    finally:
        pFile.write_text(vOriginal, encoding="utf-8")


def main():
    """Tire des mutants au hasard (graine fixe), les essaie et donne le score."""
    vParser = argparse.ArgumentParser(description=__doc__)
    vParser.add_argument("--max", type=int, default=60, help="nombre de mutants essayés")
    vParser.add_argument("--seed", type=int, default=1, help="graine du tirage")
    vParser.add_argument("--min-score", type=float, default=0, help="score minimal, en %")
    vArgs = vParser.parse_args()

    vAll = [(vFile, vNumber, vMutated) for vFile in sorted(Path("lib/logic").glob("*.dart"))
            for vNumber, vMutated in mutants(vFile)]
    random.Random(vArgs.seed).shuffle(vAll)
    vTried = vAll[: vArgs.max]
    vSurvivors = []
    for vIndex, (vFile, vNumber, vMutated) in enumerate(vTried, 1):
        vKilled = killed(vFile, vNumber, vMutated)
        print(f"[{vIndex}/{len(vTried)}] {'tué' if vKilled else 'SURVIT'} {vFile}:{vNumber + 1}")
        if not vKilled:
            vSurvivors.append(f"{vFile}:{vNumber + 1}: {vMutated.strip()}")
    vScore = 100 * (len(vTried) - len(vSurvivors)) / max(1, len(vTried))
    print(f"\nScore de mutation : {vScore:.1f} % ({len(vTried)} mutants sur {len(vAll)} possibles)")
    for vSurvivor in vSurvivors:
        print(f"  survit : {vSurvivor}")
    return 1 if vScore < vArgs.min_score else 0


if __name__ == "__main__":
    sys.exit(main())
