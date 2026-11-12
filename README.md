# Dumptrak Mobile Prototype

A standalone Flutter prototype for presenting a mobile-first ADAPTIQ Dumptrak
operations experience. It is not connected to the production application,
backend, map provider, telemetry, identity provider, or settlement services.

## Prototype screens

- **Home:** operational metrics, sample alerts, active trips, and a fleet insight.
- **Trips:** sample trip cards, status filters, and a three-step demo creation
  wizard for route/project, assignments, and review.
- **Map:** minimal map workspace with an explicit tracking-not-connected state;
  no fabricated live locations.
- **Alerts:** four selectable sections (Needs action, Earlier detections,
  History, and Informational records), an optional situation-kind filter,
  history outcome filtering, and expandable closure guidance. Needs action
  contains two sample situations; the other sections have no sample records.
- **Reports:** mobile Customer visits layout with inclusive date pickers,
  required asset scope, empty-sample metrics, daily counts, customer-site and
  visits empty states, and data provenance. Defaults to the previous calendar
  month in the displayed Africa/Lagos reporting context. Other report sections,
  map integration, and Excel exports are explicitly not connected.
  A shared demo operations summary shows the same saved trip and alert totals
  as Home and Trips, independently of visit date filters.
- **More:** Compliance & documents, Reports, Intelligence, Settlement, and FleetOps.
- **Intelligence:** mobile workspace with a required sample period selector
  (7, 30, or 90 days), fleet coverage, vehicle evaluation availability, analytic
  findings, provisional-threshold guidance, and navigation to actionable alerts.
  Retry explicitly reports that no API is configured; no live request is made.
- **Settlement:** Work Offers demo warning, sample completion-evidence queue
  counts, administrator setup guidance, and GEUTech linking explanation.
- **FleetOps:** last-24-hours movement layout with an explicit unavailable-data
  state and GEUTech linking guidance. Both linking buttons open an explanatory
  dialog only; no credentials are requested and no accounts are linked.

Android system Back (including the back gesture) closes dialogs and sheets
first, returns More detail screens to More, and returns main tabs to Home.
Back from Home allows the app to exit.

The five main screens follow the supplied UX Pilot redesign: near-black
surfaces, blue active-tab indicators, compact status badges, rounded cards,
trip origin/destination and vehicle/material fields, and alert action cards.
Existing filters and More detail screens remain
available. Alert action buttons explain that no operational change was made.
The trip archive shortcut selects the Completed status. The map does not claim
that tracking is live.

## Interactive demo foundation (Phase 1)

Home, Trips, Alerts, and the Reports operations summary read one `DemoStore`.
The original dataset has two active trips, one in transit, zero completed
trips, and two open alerts referencing those trips. Home's completed-today
count uses simulated completion timestamps in Africa/Lagos (UTC+1).
Trip completion does not imply a geofence visit, verified tonnage, or an
automatically resolved alert; Customer visits stays explicitly empty.

Use **More > Demo controls** to:

- **Advance demo one step:** move every eligible trip through Planned,
  Dispatched, At origin, In transit, Approaching, Arrived, and Completed.
  Terminal and exception states are not advanced. This is manual simulation,
  not GPS telemetry or a production action.
- **Reset Demo:** after confirmation, restore the original trip/alert dataset
  and clear the shell's filters. Cancel leaves saved records untouched.

On Android/iOS, the entry point loads a versioned JSON snapshot using
`shared_preferences` before displaying operations. This is lightweight,
non-critical demo storage, not a production database or durable financial
ledger. A single snapshot keeps related records together. Updates are
published to the UI only after the storage call succeeds; storage errors
are shown and leave the in-memory records unchanged. Invalid saved data is
not silently discarded: startup offers Retry or a confirmed sample restore.
No cloud synchronization or credentials are involved.

The persistence interface can be replaced when a larger local database or
authorized production API is needed. Tests inject in-memory storage and
exercise failed reads/writes, restart loading, simulation, and reset.
App removal or clearing app data removes the stored demo.

## Demo trip creation (Phase 2, first feature)

Use **Trips > + (New trip)** to choose a sample project, origin, destination,
driver, vehicle, and material, then review and create a **Planned** trip.
All six selections are required. No free-text production records, credentials,
dispatch messages, or real GPS are involved.

The wizard excludes vehicles/drivers with active demo assignments, validates
again when saving, and shows an explicit state when no free assignments remain.
New trip IDs are unique among saved records. Successful creation selects
All statuses so a previous filter cannot hide the new trip, and updates Home,
Trips, and the Reports summary. Project and driver appear on detailed trip
cards and remain assigned as the simulation advances.

Back returns to the preceding wizard step without losing selections; Back
from the first step closes without saving. Saving blocks duplicate submission
and Back until finished. A failed save keeps the review and selections for
retry, without adding a partial trip. Older local snapshots remain readable;
Reset Demo also removes newly created trips.

## Trip details, editing, and individual simulation

Tap a trip card on Home or Trips to open its details. The detail screen shows
the route, project, driver, vehicle, material, and current simulated status.
Missing assignments on original samples are shown as not assigned.

- **Edit demo assignments** reuses the three-step wizard and preserves the trip
  ID, status, progress, and recorded timeline. Editing is available while
  Planned, Dispatched, or At origin; after departure assignments are read-only.
  The trip's own vehicle/driver remain available, but assignments used by other
  active trips cannot be selected. Existing samples with missing project/driver
  require these selections when edited.
- **Simulate: next stage** advances only the selected trip by one stage and
  saves its timestamped event. Completed trips cannot advance again.
  Counters and Reports update from the shared state. Alerts stay open.
- **Journey timeline** distinguishes recorded simulated events from stages
  without evidence. Original/older samples do not acquire invented historical
  timestamps. Times are displayed in Africa/Lagos (UTC+1). Both individual
  advancement and the bulk Demo controls record timeline events.

Edits, events, and completion times survive reopening. Saves block repeated
actions and Back while pending. Failed saves leave records unchanged and show
an error for retry. Back from details returns to the originating tab and keeps
its filters and scroll position. Reset Demo also clears recorded events.

Interactive map/vehicle details, alert lifecycle,
visit analytics, roles, and guided scenarios remain later phases.

All records are illustrative. Demo creation replaces the earlier production
setup-blocker sheet; production prerequisites and permissions are not bypassed
because no production system is connected. Real
authentication, tenant permissions, APIs, telemetry, push notifications, and
offline behavior should be integrated only after the existing source or API
documentation is available.

## Run locally

Install the Flutter SDK, then from this folder run:

```shell
flutter create --no-overwrite --platforms=android,ios .
flutter pub get
flutter run
```

The first command generates the Android and iOS runner projects for this
standalone prototype. For a quick presentation, run on an Android emulator or
iOS simulator. Building or running the iOS app requires macOS and Xcode.

If Flutter selects an incompatible Java version for Android, point it to an
installed JDK supported by the generated Gradle wrapper (Java 17 through 24):

```shell
flutter config --jdk-dir="C:\path\to\jdk"
```

The Android debug APK is written to
`build/app/outputs/flutter-apk/app-debug.apk`. The UI uses Flutter's built-in
Material widgets; `shared_preferences` stores the local demo snapshot.
