#!/usr/bin/env bash
# **********************************************************************
# Script : steam_mod_loader.sh BETA v1.0.2
# Description : Gestionnaire de snapshots Steam, mod loader et
#               « app store » de mods/plugins pour VRChat (ou autre jeu)
#
# Fonctionnalités :
#  - Lister les jeux Steam installés (dans STEAM_COMMON)
#  - Créer/restaurer des snapshots du dossier du jeu
#  - Installer des mods/plugins depuis GitHub (branche choisie, ici "VRChat")
#    * Récupère la liste des .zip disponibles, vérifie leur date pour afficher
#      un indicateur (🟢 = à jour, 🟠 = obsolète)
#    * Offre le choix de « Installer » le mod ou de « Noter » (si le mod ne fonctionne
#      pas) et d’envoyer une demande (via webhook) pour déclencher une nouvelle snapshot
#  - Bloquer/débloquer les mises à jour en modifiant le manifeste Steam
#
# Pré-requis : dialog, curl, jq, unzip (et sudo pour chattr).
#
# NoNameIsHere_ Novalis Powered By LunarWave 
# **********************************************************************

# ========= Configuration =========
STEAM_COMMON="$HOME/.local/share/Steam/steamapps/common"
STEAM_APPS="$HOME/.local/share/Steam/steamapps"
SNAPSHOT_DIR="$HOME/steam_snapshots"
GITHUB_BRANCH="VRChat"
GITHUB_REPO="ErrorNoName/SnapSteamDB"
DISCORD_WEBHOOK_URL="https://discord.com/api/webhooks/1360928126980460564/bIBJG-L5wK-xe3Fw3jQfll_ULBZkJnBcRkv38R4HGI63NNoaxgJ_NQngam_Sg0R1DhHl"
TMP_DIR="/tmp/steam_mod_loader"
mkdir -p "$SNAPSHOT_DIR" "$TMP_DIR"

# Fichier temporaire pour dialog
TMP_FILE=$(mktemp)

# ========= Gestion des signaux et nettoyage =========
function cleanup_and_exit() {
    rm -f "$TMP_FILE"
    rm -rf "$TMP_DIR"
    clear
    exit
}
trap cleanup_and_exit SIGINT SIGTERM

# ========= Utilitaires =========

# Détection de l'OS (pour choisir la commande d'extraction)
function detect_os() {
    case "$OSTYPE" in
        linux*)   echo "linux";;
        msys*|cygwin*|win32*) echo "windows";;
        *)        echo "linux";;
    esac
}

# ========= Gestion des jeux Steam =========

# Liste les jeux installés (dossier STEAM_COMMON) et propose un menu dialog
function list_games() {
    local menu_items=()
    for game in "$STEAM_COMMON"/*; do
        if [ -d "$game" ]; then
            menu_items+=("$(basename "$game")" "")
        fi
    done
    if [ ${#menu_items[@]} -eq 0 ]; then
        dialog --msgbox "Aucun jeu trouvé dans $STEAM_COMMON" 8 40
        cleanup_and_exit
    fi
    dialog --clear --title "Liste des jeux Steam" \
           --menu "Sélectionnez un jeu :" 15 50 8 \
           "${menu_items[@]}" 2>"$TMP_FILE"
    if [ ! -s "$TMP_FILE" ]; then
        # Annulation
        return 1
    fi
    SELECTED_GAME=$(<"$TMP_FILE")
    return 0
}

# ========= Gestion des snapshots =========

# Créer un snapshot du dossier du jeu
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
        dialog --msgbox "Snapshot créé : snapshot_$snapshot_id" 8 50
    else
        dialog --msgbox "Erreur lors de la création du snapshot." 8 50
    fi
}

# Restaurer un snapshot sélectionné
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
        dialog --msgbox "Aucun snapshot disponible." 8 50
        return
    fi
    dialog --clear --title "Restaurer un snapshot" \
           --menu "Sélectionnez un snapshot :" 15 50 8 \
           "${menu_items[@]}" 2>"$TMP_FILE"
    if [ ! -s "$TMP_FILE" ]; then
        return
    fi
    local snap_choice
    snap_choice=$(<"$TMP_FILE")
    local chosen_snapshot="$snap_dir/$snap_choice"
    dialog --yesno "Vous allez restaurer $snap_choice pour $SELECTED_GAME. Cela supprimera le dossier actuel du jeu. Continuer ?" 10 50
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
        dialog --msgbox "Erreur lors de la restauration." 8 50
    fi
}

# ========= Blocage des mises à jour Steam =========

# Recherche le manifeste Steam du jeu
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

# Bloquer (rendre immutable) le manifeste pour empêcher une MAJ
function block_updates() {
    local manifest
    manifest=$(find_manifest)
    if [ -z "$manifest" ]; then
        dialog --msgbox "Manifeste introuvable pour $SELECTED_GAME." 8 50
        return
    fi
    chmod a-w "$manifest"
    sudo chattr +i "$manifest"
    if [ $? -eq 0 ]; then
        dialog --msgbox "Mises à jour bloquées pour $SELECTED_GAME." 8 50
    else
        dialog --msgbox "Erreur lors du blocage." 8 50
    fi
}

# Débloquer le manifeste
function unblock_updates() {
    local manifest
    manifest=$(find_manifest)
    if [ -z "$manifest" ]; then
        dialog --msgbox "Manifeste introuvable pour $SELECTED_GAME." 8 50
        return
    fi
    sudo chattr -i "$manifest"
    chmod 644 "$manifest"
    if [ $? -eq 0 ]; then
        dialog --msgbox "Mises à jour débloquées pour $SELECTED_GAME." 8 50
    else
        dialog --msgbox "Erreur lors du déblocage." 8 50
    fi
}

# ========= Mod Store (installation de mods/plugins) =========

# Récupérer la liste des mods (.zip) depuis GitHub (branche donnée)
function fetch_mods_list() {
    # Récupération et nettoyage de la réponse JSON pour enlever les caractères de contrôle
    local response
    response=$(curl -s "https://api.github.com/repos/$GITHUB_REPO/contents?ref=$GITHUB_BRANCH" | tr -d '\000-\011\013\014\016-\037')
    MODS_JSON="$response"
    MOD_COUNT=0
    MOD_NAMES=()
    MOD_URLS=()
    MOD_DATES=()
    local items
    items=$(echo "$MODS_JSON" | jq -c '.[]')
    while IFS= read -r line; do
        local name download_url commit_info commit_date
        name=$(echo "$line" | jq -r '.name')
        download_url=$(echo "$line" | jq -r '.download_url')
        if [[ $name == *.zip && "$download_url" != "null" ]]; then
            commit_info=$(curl -s "https://api.github.com/repos/$GITHUB_REPO/commits?path=$name&sha=$GITHUB_BRANCH" | tr -d '\000-\011\013\014\016-\037')
            commit_date=$(echo "$commit_info" | jq -r '.[0].commit.author.date')
            if [ "$commit_date" != "null" ]; then
                MOD_NAMES+=("$name")
                MOD_URLS+=("$download_url")
                MOD_DATES+=("$commit_date")
                ((MOD_COUNT++))
            fi
        fi
    done <<< "$items"
}

# Comparer la date du mod avec 3 mois en secondes
function is_mod_current() {
    local commit_date="$1"
    local commit_epoch current_epoch
    commit_epoch=$(date -d "$commit_date" +%s 2>/dev/null)
    current_epoch=$(date +%s)
    # 3 mois ≈ 7776000 secondes
    if [ $(( current_epoch - commit_epoch )) -lt 7776000 ]; then
        return 0
    else
        return 1
    fi
}

# Afficher la liste des mods et proposer un extra bouton pour envoyer une demande
function mod_store_menu() {
    fetch_mods_list
    if [ $MOD_COUNT -eq 0 ]; then
        dialog --msgbox "Aucun mod trouvé sur GitHub pour la branche $GITHUB_BRANCH." 8 50
        return
    fi

    local menu_items=()
    # Ajout des mods disponibles
    for i in "${!MOD_NAMES[@]}"; do
        local mod_name="${MOD_NAMES[$i]}"
        local mod_date="${MOD_DATES[$i]}"
        if is_mod_current "$mod_date"; then
            marker="🟢"
        else
            marker="🟠"
        fi
        menu_items+=("$i" "$mod_name $marker")
    done
    # Option supplémentaire pour envoyer une demande de nouvelle snapshot mod
    menu_items+=("REQ" "Envoyer demande de snapshot mod")

    dialog --clear --title "Mod Store pour $SELECTED_GAME" \
           --menu "Sélectionnez un mod à installer ou une option :" 20 60 10 \
           "${menu_items[@]}" 2>"$TMP_FILE"
    if [ ! -s "$TMP_FILE" ]; then
        # L'utilisateur a annulé
        return
    fi
    local mod_selection
    mod_selection=$(<"$TMP_FILE")
    if [ "$mod_selection" == "REQ" ]; then
        send_mod_request
    else
        mod_action_menu "$mod_selection"
    fi
}

# Proposer une action après avoir sélectionné un mod (installer ou noter)
function mod_action_menu() {
    local index="$1"
    local mod_name="${MOD_NAMES[$index]}"
    dialog --clear --title "$mod_name" \
           --menu "Que souhaitez-vous faire ?" 10 60 2 \
           1 "Installer le mod" \
           2 "Noter le mod (non fonctionnel)" 2>"$TMP_FILE"
    if [ ! -s "$TMP_FILE" ]; then
        return
    fi
    local action
    action=$(<"$TMP_FILE")
    if [ "$action" == "1" ]; then
        install_mod "$index"
    elif [ "$action" == "2" ]; then
        rate_mod "$index"
    fi
}

# Télécharger et installer le mod
function install_mod() {
    local index="$1"
    local mod_name="${MOD_NAMES[$index]}"
    local mod_url="${MOD_URLS[$index]}"
    local mod_temp_dir="$TMP_DIR/mod_extract"
    rm -rf "$mod_temp_dir"
    mkdir -p "$mod_temp_dir"
    dialog --infobox "Téléchargement de $mod_name ..." 5 50
    curl -L -o "$mod_temp_dir/$mod_name" "$mod_url"
    if [ $? -ne 0 ]; then
        dialog --msgbox "Erreur lors du téléchargement du mod." 8 50
        return
    fi
    os_type=$(detect_os)
    if [ "$os_type" == "linux" ]; then
        unzip -o "$mod_temp_dir/$mod_name" -d "$mod_temp_dir"
    elif [ "$os_type" == "windows" ]; then
        powershell.exe -Command "Expand-Archive -Force '$mod_temp_dir\\$mod_name' '$mod_temp_dir'"
    else
        dialog --msgbox "OS non reconnu pour l'extraction." 8 50
        return
    fi
    local game_path="$STEAM_COMMON/$SELECTED_GAME"
    for folder in "Mods" "Plugins"; do
        if [ -d "$mod_temp_dir/$folder" ]; then
            if [ -d "$game_path/$folder" ]; then
                rm -rf "$game_path/$folder"
            fi
            cp -r "$mod_temp_dir/$folder" "$game_path/"
        fi
    done
    dialog --msgbox "Mod $mod_name installé avec succès pour $SELECTED_GAME." 8 50
    # Optionnel : on peut envoyer une notification de succès
    curl -H "Content-Type: application/json" -X POST -d "{\"content\": \"[Install] $mod_name a été installé sur $SELECTED_GAME.\"}" "$DISCORD_WEBHOOK_URL" >/dev/null 2>&1
    rm -rf "$mod_temp_dir"
}

# Permet de noter un mod en précisant s'il fonctionne ou non et en envoyant une notification
function rate_mod() {
    local index="$1"
    local mod_name="${MOD_NAMES[$index]}"
    dialog --clear --title "Notation du mod" \
           --menu "Le mod fonctionne-t-il ?" 10 60 2 \
           1 "Oui" \
           2 "Non" 2>"$TMP_FILE"
    if [ ! -s "$TMP_FILE" ]; then
        return
    fi
    local note
    note=$(<"$TMP_FILE")
    if [ "$note" == "1" ]; then
        note_str="Fonctionnel"
    else
        note_str="Non fonctionnel"
    fi
    local message="[Rating] Pour $SELECTED_GAME, le mod '$mod_name' est noté : $note_str."
    curl -H "Content-Type: application/json" -X POST -d "{\"content\": \"$message\"}" "$DISCORD_WEBHOOK_URL" >/dev/null 2>&1
    dialog --msgbox "Merci pour votre retour !" 8 40
}

# Envoyer une demande de snapshot mod via webhook
function send_mod_request() {
    dialog --inputbox "Entrez un message de demande de nouvelle snapshot pour les mods de $SELECTED_GAME :" 8 60 2>"$TMP_FILE"
    if [ ! -s "$TMP_FILE" ]; then
        return
    fi
    local req_msg
    req_msg=$(<"$TMP_FILE")
    local message="[Request] Pour $SELECTED_GAME, demande de nouvelle snapshot mod : $req_msg"
    curl -H "Content-Type: application/json" -X POST -d "{\"content\": \"$message\"}" "$DISCORD_WEBHOOK_URL" >/dev/null 2>&1
    dialog --msgbox "Votre demande a été envoyée." 8 40
}

# ========= Menu principal =========

function main_menu() {
    while true; do
        list_games
        # Si list_games a été annulé, on passe à l'itération suivante
        if [ $? -ne 0 ]; then
            cleanup_and_exit
        fi
        dialog --clear --title "Gestion de $SELECTED_GAME" \
               --menu "Que souhaitez-vous faire ?" 20 60 10 \
               1 "Créer un snapshot" \
               2 "Restaurer un snapshot" \
               3 "Bloquer les mises à jour" \
               4 "Débloquer les mises à jour" \
               5 "Accéder au Mod Store" \
               6 "Quitter" 2>"$TMP_FILE"
        local choice
        choice=$(<"$TMP_FILE")
        case "$choice" in
            1) create_snapshot ;;
            2) restore_snapshot ;;
            3) block_updates ;;
            4) unblock_updates ;;
            5) mod_store_menu ;;
            6) cleanup_and_exit ;;
            *) ;;
        esac
        dialog --yesno "Gérer un autre jeu ?" 8 40
        if [ $? -ne 0 ]; then
            cleanup_and_exit
        fi
    done
}

# ========= Lancement =========
main_menu
