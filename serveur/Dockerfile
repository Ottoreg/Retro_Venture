# Serveur de jeu Retro Venture (GDD § 16.5) : Godot 4.5 sans affichage + le dossier game/.
# Construit depuis la racine du dépôt : docker compose (voir serveur/README.md).
FROM debian:bookworm-slim

# Garder aligné avec la CI et l'éditeur (docs/decisions/0001-moteur-godot-4.md).
ARG GODOT_VERSION=4.5.1

RUN apt-get update \
    && apt-get install -y --no-install-recommends ca-certificates curl unzip \
    && rm -rf /var/lib/apt/lists/* \
    && curl -fsSL -o /tmp/godot.zip \
       "https://github.com/godotengine/godot/releases/download/${GODOT_VERSION}-stable/Godot_v${GODOT_VERSION}-stable_linux.x86_64.zip" \
    && unzip -q /tmp/godot.zip -d /opt \
    && mv "/opt/Godot_v${GODOT_VERSION}-stable_linux.x86_64" /usr/local/bin/godot \
    && rm /tmp/godot.zip

WORKDIR /jeu
COPY game/ /jeu/
# Import une fois pour toutes (classes et ressources) : le démarrage est ensuite immédiat.
RUN timeout 600 godot --headless --path /jeu --import || true

ENV RV_PORT=8080 \
    RV_DATA_DIR=/donnees
EXPOSE 8080
CMD ["godot", "--headless", "--path", "/jeu", "-s", "res://server/server_main.gd"]
