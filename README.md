# WorkoutCreator

A native Swift / SwiftUI port of TrainerRoad's WorkoutCreator desktop application, built to run on Apple Silicon.

The original WorkoutCreator (`com.trainerroad.tools.WorkoutCreator`, v1.8.1, Adobe AIR / ActionScript 3, built November 2020) is x86_64-only and runs on macOS via Rosetta 2. This project is an unofficial reimplementation that runs natively, sourcing the design and behavior from the original app's structure and the TrainerRoad REST API. It is not affiliated with TrainerRoad.

## Why this exists

Adobe ended its own support for Adobe AIR in 2019 (the runtime was transferred to Harman), and Apple is winding down Rosetta 2 — the x86_64 translation layer the original WorkoutCreator depends on — in upcoming macOS releases. Once Rosetta 2 is removed, the legacy WorkoutCreator (which has no arm64 slice and no maintained replacement) will stop running on Mac entirely. This project is a native rebuild aimed at preserving the workflow on Apple Silicon ahead of that cliff, by reverse-engineering the original app's data formats, SQLite schema, and TrainerRoad API surface area, and reimplementing the UI in SwiftUI.

## What it does

- Sign in with a TrainerRoad account.
- Sync a user's custom workouts (the ones authored by the signed-in member) bidirectionally with TrainerRoad. Only custom workouts created by the user are stored locally; the 5300+ workouts in the TrainerRoad library are filtered out.
- Edit workouts:
  - Add, clone, delete intervals.
  - Adjust each interval's length and target power (% FTP). Length changes ripple to subsequent intervals to keep the timeline contiguous.
  - Auto-name intervals by power zone (Recovery / Endurance / Tempo / Sweet Spot / Threshold / VO2 Max / Anaerobic Capacity / Sprint) with a sequence number per zone. Custom names are left alone.
  - Edit cue text (the lines that show during the workout: "Last one. The only easy day was yesterday.", etc.).
- Visualize the workout as a power curve with zone bands. Toggle the left Y axis between watts (from your stored FTP) and the right Y axis in % FTP.
- Persist locally in a SQLite database mirroring the schema used by the original app.
- Read and write the `.mrc` workout file format (export, sync payload).

## Status

Working for the author's normal use, but rough around the edges and full of project-specific assumptions. Notable known behavior:

- Locally-created workouts now emit a leading "Workout" meta-interval and `[COURSE DATA]` padding past the last interval, matching TrainerRoad's own MRC structure. This was added after a finish-line crash in TrainerRoad on a workout authored here.
- Sync includes automatic repair passes that re-fetch workouts whose local MRC fails to parse and re-format workouts that lack the meta-interval shape.
- macOS keychain prompts a password challenge on launch when the build's code signature changes (unavoidable for ad-hoc-signed development builds). Set a stable signing team in Xcode and the prompt goes away after one "Always Allow".

## Architecture

| Area | Files / Notes |
|---|---|
| App entry | `WorkoutCreator/WorkoutCreatorApp.swift`, `ContentView.swift` |
| Auth | `Auth/AuthStore.swift`, `Auth/KeychainHelper.swift` |
| Data model | `Models/WorkoutFile.swift`, `WorkoutInterval.swift`, `WorkoutDetails.swift`, `CuePoint.swift`, `WorkoutPoint.swift` |
| Persistence | GRDB 6 over SQLite. `Database/AppDatabase.swift`, `WorkoutRepository.swift`, `Database/Migrations/` |
| TrainerRoad client | `Services/TrainerRoadClient.swift` (REST), `WorkoutSyncService.swift` (sync state machine) |
| MRC format | `Services/MRCParser.swift`, `MRCWriter.swift` |
| UI | `Views/Auth/`, `Views/WorkoutList/`, `Views/Editor/`, `Views/Shared/` |

The sync state machine runs eight ordered steps:

0. Hard-delete locally-corrupt (unparseable) workouts so they re-download.  
0.5. Re-format any workout whose MRC lacks the meta-interval and mark it dirty.  
1. Fetch the server's full workout ID list.  
2. Download IDs we haven't seen, filter to the signed-in member's, persist.  
3. Push dirty workouts via PUT.  
4. Soft-delete local workouts the server no longer has (skipping dirty ones).  
5. Push locally soft-deleted workouts to the server via PUT with `IsActive=false`, then hard-delete locally.  
6. Hard-delete orphaned inactive locals not on the server (DB cleanup).

## Build & run

Requirements: macOS, Xcode (Swift 5.10+ recommended), an Apple ID set as a development team in Xcode (optional but recommended; it stabilizes the code signature and stops the keychain prompts).

```bash
cd WorkoutCreator
xcodegen generate   # (re)generates the .xcodeproj from project.yml; only needed after adding files
open WorkoutCreator.xcodeproj
```

In Xcode, select the `WorkoutCreator` scheme and Run. On first launch, sign in with your TrainerRoad email and password. Credentials are stored in the macOS keychain.

## Debugging

`File → Dump All Workouts (Debug)` (`Cmd+Shift+D`) prints every workout's metadata, parsed intervals, last six course-data points, and raw MRC head/tail to the Xcode console. Useful for comparing workouts when something parses or syncs unexpectedly.

The sync service logs every step to the console with a `[Sync]` prefix; the HTTP client logs publish/delete responses with a `[TrainerRoad]` prefix.

## License & attribution

The Swift implementation in this repository is MIT licensed — see [LICENSE](LICENSE). What is *not* covered by that license — the original WorkoutCreator design, the `.mrc` format, the SQL schema, TrainerRoad's API and trademarks — is acknowledged in [NOTICE](NOTICE). Using this software requires a valid TrainerRoad account.

"TrainerRoad" is a trademark of TrainerRoad, LLC. This project is not affiliated with, endorsed by, or sponsored by TrainerRoad, LLC.
