#!/usr/bin/env bash
#
# TeRRaDude TVSORTTOARCHIVE (c)2026
# 
# Move TV releases from Unsorted to structured archive
#
# CHANGELOG
#
# 2026-01-12  v1.7
#   - BLURAY_AS_REGULAR option added
#   - SANDBOX mode instead of DRY_RUN
#   - BluRay detection and routing to TV-BLURAY-720P/1080P/2160P
#   - top-level scan only
#   - ignore Sample/Sub/Subs folders inside releases
#   - optional season folder format
#   - duplicate handling: move to DUPLICATE_PATH if release exists
#   - keeps full code structure
#
# Compatible:
#   Debian 12 and above
#
# Note:
#  Please take note that these scripts come without instructions on how to set
#  them up, it is sole responsibility of the end user to understand the scripts
#  function before executing them. If you do not know how to execute them, then
#  please don't use them. They come with no warranty should any damage happen due
#  to the improper settings and execution of these scripts (missing data, etc).
#
#
############################
# CONFIGURATION
############################

# Source folder with unsorted TV releases
UNSORTED_BASE="/glftpd/site/_ARCHiVE/TV/TV-Unsorted"

# Archive base paths
ARCHIVE_BASE="/glftpd/site/_ARCHiVE/TV"

TV_720P_DIR="$ARCHIVE_BASE/TV-720P"
TV_1080P_DIR="$ARCHIVE_BASE/TV-1080P"
TV_2160P_DIR="$ARCHIVE_BASE/TV-2160P"

# BluRay archive paths
TV_BLURAY_720P_DIR="$ARCHIVE_BASE/TV-BLURAY-720P"
TV_BLURAY_1080P_DIR="$ARCHIVE_BASE/TV-BLURAY-1080P"
TV_BLURAY_2160P_DIR="$ARCHIVE_BASE/TV-BLURAY-2160P"

# Log file
LOG_FILE="/glftpd/ftp-data/logs/tvsorttoarchivev1.7.log"

# Optional season folder format
# Options:
#   SXX       -> S01, S02, etc. (default)
#   Season.XX -> Season.01, Season.02
#   SeasonX   -> Season1, Season2
#   SeasonXX  -> Season01, Season02
SEASON_FORMAT="SXX"

# BluRay handling mode
# 0 = BluRay releases go to TV-BLURAY directories
# 1 = BluRay releases go to normal TV-* directories
BLURAY_AS_REGULAR=1

# Duplicate handling
# 1 = move duplicates to DUPLICATE_PATH
# 0 = skip duplicates silently
HANDLE_DUPLICATES=1
DUPLICATE_PATH="/glftpd/site/_ARCHiVE/TV/TV-Unsorted/DUPLICATE"

# Sandbox mode: 1 = preview only, 0 = actually move
SANDBOX=1

#--------------------------- END OF CONFIG ------------------------------

############################
# FUNCTIONS
############################

log() {
    echo "$(date "+%a %b %e %T %Y") TVSORTTOARCHIVE: $1" | tee -a "$LOG_FILE"
}

make_dir() {
    local dir="$1"
    if [[ ! -d "$dir" ]]; then
        log "Creating directory: $dir"
        [[ "$SANDBOX" -eq 0 ]] && mkdir -p "$dir" && chmod 777 "$dir"
    fi
}

move_release() {
    local src="$1"
    local dest="$2"

    log "MOVE: '$src' --> '$dest'"

    if [[ "$SANDBOX" -eq 0 ]]; then
        mkdir -p "$(dirname "$dest")"
        chmod 777 "$(dirname "$dest")"
        mv -T "$src" "$dest"
    fi
}

############################
# MAIN SCRIPT
############################

log "Scan started in $UNSORTED_BASE (sandbox=$SANDBOX)"

shopt -s nullglob

# Only top-level directories (releases) in UNSORTED_BASE
for rel in "$UNSORTED_BASE"/*; do

    [[ ! -d "$rel" ]] && continue

    release_name=$(basename "$rel")

    ############################
    # Ignore unwanted folders inside releases
    ############################
    # Skip folders named Sample, Subs, Sub (any capitalization)
    if [[ "$release_name" =~ ^([Ss]ample[s]?|[Ss]ub[s]?)$ ]]; then
        continue
    fi

    ############################
    # Detect resolution and BluRay
    ############################
    if [[ "$release_name" =~ [Bb]lu[Rr]ay ]] && [[ "$BLURAY_AS_REGULAR" -eq 0 ]]; then
        # BluRay release → special TV-BLURAY directories
        if [[ "$release_name" =~ 2160p|UHD ]]; then
            TARGET_ROOT="$TV_BLURAY_2160P_DIR"
            RES="2160p BluRay"
        elif [[ "$release_name" =~ 1080p ]]; then
            TARGET_ROOT="$TV_BLURAY_1080P_DIR"
            RES="1080p BluRay"
        elif [[ "$release_name" =~ 720p ]]; then
            TARGET_ROOT="$TV_BLURAY_720P_DIR"
            RES="720p BluRay"
        else
            log "SKIP (BluRay release with unsupported resolution): $release_name"
            continue
        fi
    else
        # Regular releases or BluRay treated as normal
        if [[ "$release_name" =~ 2160p|UHD ]]; then
            TARGET_ROOT="$TV_2160P_DIR"
            RES="2160p"
        elif [[ "$release_name" =~ 1080p ]]; then
            TARGET_ROOT="$TV_1080P_DIR"
            RES="1080p"
        elif [[ "$release_name" =~ 720p ]]; then
            TARGET_ROOT="$TV_720P_DIR"
            RES="720p"
        else
            log "SKIP (no supported resolution found): $release_name"
            continue
        fi
    fi

    ############################
    # Parse series + season
    ############################
    if [[ "$release_name" =~ ^(.+)\.S([0-9]{2})E[0-9]{2} ]]; then
        SERIES="${BASH_REMATCH[1]}"
        SEASON_NUM="${BASH_REMATCH[2]}"
    else
        log "SKIP (cannot parse SxxExx pattern): $release_name"
        continue
    fi

    ############################
    # Optional season folder formatting
    ############################
    case "$SEASON_FORMAT" in
        SXX)
            SEASON="S$SEASON_NUM"
            ;;
        Season.XX)
            SEASON="Season.$SEASON_NUM"
            ;;
        SeasonX)
            SEASON="Season$((10#$SEASON_NUM))"  # remove leading zero
            ;;
        SeasonXX)
            SEASON="Season$SEASON_NUM"
            ;;
        *)
            SEASON="S$SEASON_NUM"  # fallback default
            ;;
    esac

    TARGET_SERIES_PATH="$TARGET_ROOT/$SERIES"
    TARGET_SEASON_PATH="$TARGET_SERIES_PATH/$SEASON"
    TARGET_FULL_PATH="$TARGET_SEASON_PATH/$release_name"

    ############################
    # Duplicate check
    ############################
    if [[ -e "$TARGET_FULL_PATH" ]]; then
        log "DUPLICATE detected: $release_name"

        if [[ "$HANDLE_DUPLICATES" -eq 1 ]]; then
            DUP_DEST="$DUPLICATE_PATH/$release_name"
            make_dir "$DUPLICATE_PATH"
            move_release "$rel" "$DUP_DEST"
        else
            log "SKIP duplicate (no move): $release_name"
        fi
        continue
    fi

    ############################
    # Make series/season folders
    ############################
    make_dir "$TARGET_SERIES_PATH"
    make_dir "$TARGET_SEASON_PATH"

    ############################
    # Move release
    ############################
    move_release "$rel" "$TARGET_FULL_PATH"

done

log "Scan finished."
exit 0
