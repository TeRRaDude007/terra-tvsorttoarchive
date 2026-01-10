TVSortToArchive v1.7 – Script Summary

TVSortToArchive is a Bash script designed to automatically organize TV show releases from an “Unsorted” directory into a structured archive based on resolution, release type, and series/season information.

✅ Key Features

Top-Level Scan Only
Processes only top-level folders in the Unsorted directory.
Avoids touching nested folders like Sample or Sub/Subs.
Resolution Detection
Automatically detects release resolution: 720p, 1080p, 2160p (UHD).

BluRay Support
Detects BluRay releases based on the release name.

By default, routes BluRay releases to dedicated folders:
TV-BLURAY-720P
TV-BLURAY-1080P
TV-BLURAY-2160P

Optional configuration (BLURAY_AS_REGULAR=1) allows BluRay releases to be stored together with normal TV releases in the standard TV-720P/1080P/2160P directories.

Series and Season Parsing
Extracts series name and season from standard SxxExx patterns in release filenames.

Creates structured folders: <Archive>/<Series>/<Season>/ReleaseName.
Custom Season Folder Formats

Supports optional season naming:
SXX (default, e.g., S01)
Season.XX (e.g., Season.01)
SeasonX (e.g., Season1)
SeasonXX (e.g., Season01)

Duplicate Handling
Detects if a release already exists in the archive.

Optionally moves duplicates to a dedicated folder (DUPLICATE_PATH) instead of skipping silently.

Sandbox Mode
Controlled by SANDBOX=1 for dry-run previews.

SANDBOX=0 executes actual moves.
All logs indicate what would be moved or created.

Logging
Logs all actions including folder creation, moves, duplicates, and skips.

Preserves the full history in a dedicated log file (LOG_FILE).
Safe Handling

Never deletes or alters Sample or Sub folders.

Only moves the top-level release folders themselves.
