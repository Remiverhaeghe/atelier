"""Prépare les images de la fiche Play Store à partir de l'icône et des captures fictives."""

from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

from dessiner_icone import ENCRE, METRE, SAPIN, dessiner_equerre

SORTIE = Path("docs/play-store")
PAPIER = (0xF1, 0xF4, 0xF0, 255)
# Le Play Store refuse une capture dont le grand côté dépasse deux fois le petit :
# les captures en 1080 × 2340 sont posées sur un fond de 1080 × 1920.
CAPTURE = (1080, 1920)
CAPTURES = ["02-chantier", "03-piece", "05-pose", "06-plinthes", "10-reprises", "13-calculs"]


def police(pNom, pTaille):
    """Charge une police embarquée de l'application."""
    rPolice = ImageFont.truetype(f"assets/fonts/{pNom}.ttf", pTaille)

    return rPolice


def icone():
    """Icône haute résolution de 512 × 512."""
    vIcone = Image.open("assets/icon/icon.png").convert("RGB")
    vIcone.resize((512, 512), Image.LANCZOS).save(SORTIE / "icone-512.png")


def presentation():
    """Image de présentation de 1024 × 500 : l'équerre et le nom de l'appli."""
    vImage = Image.new("RGBA", (1024, 500), SAPIN)
    dessiner_equerre(vImage, 0.55, 250, 250)
    vDessin = ImageDraw.Draw(vImage)
    vDessin.text((440, 150), "Atelier", font=police("BarlowSemiCondensed-Bold", 120), fill=METRE)
    vDessin.text(
        (446, 300),
        "Mesurer, calculer, poser.",
        font=police("Barlow-Medium", 44),
        fill=PAPIER,
    )
    vImage.convert("RGB").save(SORTIE / "presentation-1024x500.png")


def captures():
    """Captures réduites et centrées sur un fond papier au bon rapport."""
    for vIndex, vNom in enumerate(CAPTURES, start=1):
        vCapture = Image.open(f"docs/captures/{vNom}.png").convert("RGBA")
        vHauteur = CAPTURE[1] - 80
        vLargeur = round(vCapture.width * vHauteur / vCapture.height)
        vReduite = vCapture.resize((vLargeur, vHauteur), Image.LANCZOS)
        vFond = Image.new("RGBA", CAPTURE, PAPIER)
        vCadre = ImageDraw.Draw(vFond)
        vGauche = (CAPTURE[0] - vLargeur) // 2
        vCadre.rounded_rectangle(
            [vGauche - 6, 34, vGauche + vLargeur + 6, 46 + vHauteur], radius=28, fill=ENCRE
        )
        vFond.alpha_composite(vReduite, (vGauche, 40))
        vFond.convert("RGB").save(SORTIE / f"capture-{vIndex}.png")


def main():
    """Écrit toutes les images dans docs/play-store."""
    SORTIE.mkdir(parents=True, exist_ok=True)
    icone()
    presentation()
    captures()


if __name__ == "__main__":
    main()
