"""Dessine l'icône d'Atelier : une équerre de mètre ruban jaune sur vert sapin."""

from PIL import Image, ImageDraw

TAILLE = 1024
SAPIN = (0x1F, 0x5A, 0x3A, 255)
METRE = (0xF2, 0xB2, 0x30, 255)
ENCRE = (0x24, 0x30, 0x2B, 255)


def dessiner_equerre(pImage, pEchelle, pCentreX, pCentreY):
    """Trace les deux branches graduées de l'équerre, coin en bas à gauche."""
    vDessin = ImageDraw.Draw(pImage)
    vLargeur = int(130 * pEchelle)
    vLongueur = int(560 * pEchelle)
    vGauche = int(pCentreX - vLongueur / 2)
    vBas = int(pCentreY + vLongueur / 2)
    vRayon = int(24 * pEchelle)
    vDessin.rounded_rectangle(
        [vGauche, vBas - vLongueur, vGauche + vLargeur, vBas], radius=vRayon, fill=METRE
    )
    vDessin.rounded_rectangle(
        [vGauche, vBas - vLargeur, vGauche + vLongueur, vBas], radius=vRayon, fill=METRE
    )
    for vIndex in range(2, 9):
        vPosition = int(vLargeur + (vIndex - 1) * (vLongueur - vLargeur) / 8.5)
        vTrait = int((60 if vIndex % 2 == 0 else 36) * pEchelle)
        vEpaisseur = max(2, int(12 * pEchelle))
        vDessin.rectangle(
            [
                vGauche + vLargeur - vTrait,
                vBas - vPosition - vEpaisseur // 2,
                vGauche + vLargeur,
                vBas - vPosition + vEpaisseur // 2,
            ],
            fill=ENCRE,
        )
        vDessin.rectangle(
            [
                vGauche + vPosition - vEpaisseur // 2,
                vBas - vLargeur,
                vGauche + vPosition + vEpaisseur // 2,
                vBas - vLargeur + vTrait,
            ],
            fill=ENCRE,
        )


def main():
    """Écrit l'icône, son premier plan adaptatif et l'image de démarrage."""
    vIcone = Image.new("RGBA", (TAILLE, TAILLE), SAPIN)
    dessiner_equerre(vIcone, 1.0, TAILLE / 2, TAILLE / 2)
    vIcone.save("assets/icon/icon.png")
    # Zone sûre de l'icône adaptative : le symbole tient dans les 66 % du centre
    vPremierPlan = Image.new("RGBA", (TAILLE, TAILLE), (0, 0, 0, 0))
    dessiner_equerre(vPremierPlan, 0.62, TAILLE / 2, TAILLE / 2)
    vPremierPlan.save("assets/icon/foreground.png")
    vDemarrage = Image.new("RGBA", (512, 512), (0, 0, 0, 0))
    dessiner_equerre(vDemarrage, 0.5, 256, 256)
    vDemarrage.save("assets/icon/splash.png")


if __name__ == "__main__":
    main()
