#!/bin/bash
# Script : steam_manager_ui.sh
# Fonctionnalités : Liste des jeux, création/restauration de snapshots, blocage/déblocage des mises à jour.
# ATTENTION : Ce script effectue des opérations destructrices. Sauvegardez vos données au préalable.

# Configurations (à adapter si besoin)
STEAM_COMMON="$HOME/.local/share/Steam/steamapps/common"
STEAM_APPS="$HOME/.local/share/Steam/steamapps"
SNAPSHOT_DIR="$HOME/steam_snapshots"

# Vérifier que dialog est installé
if ! command -v dialog &>/dev/null; then
    echo "L'utilitaire 'dialog' n'est pas installé. Veuillez l'installer (ex: sudo pacman -S dialog) et relancer le script."
    exit 1
fi

# Création du répertoire de snapshots si nécessaire
mkdir -p "$SNAPSHOT_DIR"

# Fichier temporaire pour dialog
TMP_FILE=$(mktemp)

# Fonction pour lister les jeux Steam et renvoyer un menu dialog
function select_game() {
    local menu_items=()
    local i=1
    for game in "$STEAM_COMMON"/*; do
        if [ -d "$game" ]; then
            local game_name
            game_name=$(basename "$game")
            menu_items+=("$game_name" "")
            ((i++))
        fi
    done

    if [ ${#menu_items[@]} -eq 0 ]; then
        dialog --msgbox "Aucun jeu trouvé dans $STEAM_COMMON" 8 40
        cleanup_and_exit
    fi

    dialog --clear --title "Liste des jeux Steam" \
        --menu "Sélectionnez un jeu :" 15 50 8 \
        "${menu_items[@]}" 2>"$TMP_FILE"

    SELECTED_GAME=$(<"$TMP_FILE")
}

# Fonction pour afficher un menu d'actions pour le jeu sélectionné
function game_menu() {
    while true; do
        dialog --clear --title "Gestion de $SELECTED_GAME" \
            --menu "Que souhaitez-vous faire ?" 15 50 8 \
            1 "Créer un snapshot" \
            2 "Restaurer un snapshot" \
            3 "Bloquer les mises à jour" \
            4 "Débloquer les mises à jour" \
            5 "Retour" 2>"$TMP_FILE"
        local choice=$(<"$TMP_FILE")

        case "$choice" in
            1) create_snapshot ;;
            2) restore_snapshot ;;
            3) block_updates ;;
            4) unblock_updates ;;
            5) break ;;
            *) break ;;
        esac
    done
}

# Fonction pour créer un snapshot
function create_snapshot() {
    local game_path="$STEAM_COMMON/$SELECTED_GAME"
    if [ ! -d "$game_path" ]; then
        dialog --msgbox "Dossier du jeu introuvable : $game_path" 8 50
        return
    fi

    mkdir -p "$SNAPSHOT_DIR/$SELECTED_GAME"
    local snapshot_id
    snapshot_id=$(date +"%Y%m%d_%H%M%S")
    local snapshot_dir="$SNAPSHOT_DIR/$SELECTED_GAME/snapshot_$snapshot_id"

    mkdir -p "$snapshot_dir"
    rsync -a --delete "$game_path/" "$snapshot_dir/"
    if [ $? -eq 0 ]; then
        dialog --msgbox "Snapshot créé avec succès : snapshot_$snapshot_id" 8 50
    else
        dialog --msgbox "Erreur lors de la création du snapshot." 8 50
    fi
}

# Fonction pour restaurer un snapshot
function restore_snapshot() {
    local snap_dir="$SNAPSHOT_DIR/$SELECTED_GAME"
    if [ ! -d "$snap_dir" ]; then
        dialog --msgbox "Aucun snapshot trouvé pour $SELECTED_GAME." 8 50
        return
    fi

    local menu_items=()
    for snap in "$snap_dir"/snapshot_*; do
        [ -d "$snap" ] || continue
        menu_items+=("$(basename "$snap")" "")
    done

    if [ ${#menu_items[@]} -eq 0 ]; then
        dialog --msgbox "Aucun snapshot disponible pour $SELECTED_GAME." 8 50
        return
    fi

    dialog --clear --title "Restaurer un snapshot" \
        --menu "Sélectionnez un snapshot :" 15 50 8 \
        "${menu_items[@]}" 2>"$TMP_FILE"

    local snap_choice=$(<"$TMP_FILE")
    local chosen_snapshot="$snap_dir/$snap_choice"
    dialog --yesno "Vous allez restaurer le snapshot $snap_choice pour $SELECTED_GAME. Cela supprimera le dossier actuel du jeu. Continuer ?" 10 50
    if [ $? -ne 0 ]; then
        return
    fi

    local game_path="$STEAM_COMMON/$SELECTED_GAME"
    rm -rf "$game_path"
    mkdir -p "$game_path"
    rsync -a --delete "$chosen_snapshot/" "$game_path/"
    if [ $? -eq 0 ]; then
        dialog --msgbox "Snapshot restauré avec succès." 8 50
    else
        dialog --msgbox "Erreur lors de la restauration du snapshot." 8 50
    fi
}

# Recherche le manifeste Steam associé au jeu
function find_manifest() {
    local manifest_file=""
    for file in "$STEAM_APPS"/appmanifest_*.acf; do
        if grep -q "\"installdir\"[[:space:]]*\"$SELECTED_GAME\"" "$file"; then
            manifest_file="$file"
            break
        fi
    done
    echo "$manifest_file"
}

# Fonction pour bloquer les mises à jour en rendant le manifeste immutable
function block_updates() {
    local manifest=$(find_manifest)
    if [ -z "$manifest" ]; then
        dialog --msgbox "Manifeste introuvable pour $SELECTED_GAME." 8 50
        return
    fi
    chmod a-w "$manifest"
    sudo chattr +i "$manifest"
    if [ $? -eq 0 ]; then
        dialog --msgbox "Mises à jour bloquées pour $SELECTED_GAME." 8 50
    else
        dialog --msgbox "Erreur lors du blocage des mises à jour." 8 50
    fi
}

# Fonction pour débloquer les mises à jour
function unblock_updates() {
    local manifest=$(find_manifest)
    if [ -z "$manifest" ]; then
        dialog --msgbox "Manifeste introuvable pour $SELECTED_GAME." 8 50
        return
    fi
    sudo chattr -i "$manifest"
    chmod 644 "$manifest"
    if [ $? -eq 0 ]; then
        dialog --msgbox "Mises à jour débloquées pour $SELECTED_GAME." 8 50
    else
        dialog --msgbox "Erreur lors du déblocage des mises à jour." 8 50
    fi
}

# Fonction de nettoyage à la fin du script
function cleanup_and_exit() {
    rm -f "$TMP_FILE"
    clear
    exit
}

# Gestion du signal interruption (Ctrl+C)
trap cleanup_and_exit SIGINT SIGTERM

# --- Main ---
while true; do
    select_game
    game_menu
    dialog --yesno "Voulez-vous gérer un autre jeu ?" 8 40
    if [ $? -ne 0 ]; then
        break
    fi
done

cleanup_and_exit
