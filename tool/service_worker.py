"""Écrit build/web/sw.js : met en cache tous les fichiers de la version web, pour l'hors ligne.

Le nom du cache change à chaque construction : une nouvelle version remplace l'ancienne au
prochain lancement en ligne.
"""

import hashlib
import json
import sys
from pathlib import Path


def main(pFolder: str) -> None:
    """Liste les fichiers construits et écrit le service worker à côté."""
    vRoot = Path(pFolder)
    vFiles = sorted(
        vPath.relative_to(vRoot).as_posix()
        for vPath in vRoot.rglob("*")
        if vPath.is_file() and vPath.name != "sw.js"
    )
    vDigest = hashlib.sha256()
    for vName in vFiles:
        vDigest.update(vName.encode())
        vDigest.update((vRoot / vName).read_bytes())
    vCache = "atelier-" + vDigest.hexdigest()[:12]
    vScript = f"""// Généré par tool/service_worker.py : ne pas modifier.
const CACHE = {json.dumps(vCache)};
const FILES = {json.dumps(["./"] + vFiles)};

self.addEventListener('install', (event) => {{
  event.waitUntil(caches.open(CACHE).then((cache) => cache.addAll(FILES)));
  self.skipWaiting();
}});

self.addEventListener('activate', (event) => {{
  event.waitUntil(
    caches.keys().then((keys) =>
      Promise.all(keys.filter((key) => key !== CACHE).map((key) => caches.delete(key))),
    ),
  );
  self.clients.claim();
}});

// Le cache d'abord : l'appli s'ouvre sans réseau ; sinon le réseau.
self.addEventListener('fetch', (event) => {{
  if (event.request.method !== 'GET') {{
    return;
  }}
  event.respondWith(
    caches.match(event.request, {{ignoreSearch: true}}).then((hit) => hit || fetch(event.request)),
  );
}});
"""
    (vRoot / "sw.js").write_text(vScript, encoding="utf-8")
    print(f"{len(vFiles)} fichiers mis en cache dans {vCache}")


if __name__ == "__main__":
    main(sys.argv[1] if len(sys.argv) > 1 else "build/web")
