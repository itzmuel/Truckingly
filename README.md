# Dumptrak Mobile Prototype

A standalone Flutter prototype for presenting a mobile-first ADAPTIQ Dumptrak
operations experience. It is not connected to the production application,
backend, map provider, telemetry, identity provider, or settlement services.

## Prototype screens

- **Home:** operational metrics, sample alerts, active trips, and a fleet insight.
- **Trips:** sample trip cards, status filters, and a three-step demo creation
  wizard for route/project, assignments, and review.
- **Map:** interactive simulated route schematic with status-colored vehicle
  markers, pinch zoom/pan, reset view, and vehicle detail sheets. No live GPS.
- **Alerts:** four selectable sections (Needs action, Earlier detections,
  History, and Informational records), an optional situation-kind filter,
  history outcome filtering, and expandable closure guidance. Needs action
  starts with two sample situations; explicitly resolved alerts move to History.
  Earlier detections and Informational records have no sample records.
- **Reports:** opens to demo analytics with trip-status charts, seven-day
  simulated completions, vehicle workload, alert summaries, and vehicle scope.
  Also includes the mobile Customer visits layout with inclusive date pickers,
  required asset scope, saved sample arrival/departure events, dwell summaries,
  daily counts, and data provenance. Defaults to the current calendar month
  through today in the Africa/Lagos reporting context. Other report sections,
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
available. Alert action buttons open explicitly simulated local management.
The trip archive shortcut selects the Completed status. The map does not claim
that tracking is live.

## Demo roles and guided scenarios

**More > Account** switches between Administrator, Dispatcher, Supervisor, and
Driver sample perspectives. This changes only the displayed sample name and
role; it is not authentication, authorization, or permission enforcement.
Every role can still use the same demo features.

**More > Demo controls > Guided scenarios** offers Normal operations, Delivery
delay, and Vehicle incident. Each selection includes a short screen-by-screen
walkthrough with shortcuts to Home, Trips, Map, Alerts, or Reports. Load asks
for confirmation and replaces the local demo snapshot with the selected fixed
scenario. Cancel keeps all current records. Reset Demo always restores the
original samples.

The Home screen also has a **Stakeholder walkthrough** shortcut to open the
scenario selector and walkthrough steps directly.

**Demo Director** offers three presentation modes: Autoplay advances through a
five-screen sequence on a 3-, 5-, or 8-minute schedule and supports pause,
resume, previous, next, replay, and stop; Guided waits for the presenter to
advance after each screen's demonstration; Explore loads the selected scenario
and returns to the interactive app. Autoplay and Guided visibly animate a
labeled simulated touch pointer over real app controls, then activate those
controls: open a trip, advance its journey stage, inspect the assigned vehicle
on the map, review the scenario alert, and open the Customer visits report.
The presentation header identifies the selected sample person and role, and
the narration emphasizes that role's responsibilities. A Driver perspective
reviews alerts without acknowledging them; the other perspectives acknowledge
the selected open demo alert. Roles remain display-only, not authentication,
authorization, or permission enforcement. Starting or replaying a
presentation requires confirmation because it replaces saved sample trips,
alerts, and visit events. Stopping or using system Back returns to Home without
another data change. Automated touches and resulting actions are simulated and
saved locally; the pointer does not represent a physical touch or user input.
An acknowledged alert remains open and does not imply the underlying issue was
resolved or repaired.

The delay scenario uses a sample status label and an alert, not an actual
calculated delay or arrival time. The incident scenario marks a sample trip as
Exception and adds an explicitly simulated vehicle alert; it does not report a
real vehicle condition or notify anyone. Scenario selection and records persist
locally. Later edits can change the loaded starting scenario's records.

GitHub Actions runs `flutter analyze` and the complete serial Flutter test suite
for each push and pull request.

## Interactive demo foundation (Phase 1)

Home, Trips, Alerts, and the Reports operations summary read one `DemoStore`.
The original dataset has two active trips, one in transit, zero completed
trips, and two open alerts referencing those trips. Home's completed-today
count uses simulated completion timestamps in Africa/Lagos (UTC+1).
Trip completion does not imply a geofence visit, verified tonnage, or an
automatically resolved alert. Customer visits only counts manually recorded
sample arrivals and departures; trip completion alone never creates a visit.

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

## Simulated alert management

Open an alert from Home, Alerts, or History to review its saved state.
Open alerts can be acknowledged, assigned to a sample supervisor, given notes,
and resolved with a required summary and confirmation. Acknowledgment and
assignment leave the alert open; only resolution moves it to read-only History.
History's All closed situations and Closed by a person filters include these
resolutions; other outcomes remain empty. No telemetry repair, tonnage
verification, real notification, or financial action occurs.

Home, Alerts, and Reports count only open alerts. Resolving a tracking alert
removes the map's simulated reporting-gap override, not a real GPS fault.
Changes survive reopening; failed writes retain input for retry without
publishing partial changes. Reset Demo clears notes, assignments, acknowledgments,
and resolutions. Older snapshots without lifecycle fields remain readable.

## Simulated fleet map

The Map tab shows four sample vehicles on separate schematic route lanes
(not geographic roads or distances). Tap a marker or a vehicle list entry for
its driver, assigned/current or last completed trip, simulated speed, sample
location, and reporting state. Open demo trip navigates to the existing trip
details; Back returns to the map. Unassigned vehicles remain at a demo depot.

Positions derive from saved stages: origin before transit, halfway In transit,
80% Approaching, and destination when Arrived/Completed. Simulated moving speeds
are 42 km/h in transit and 24 km/h approaching; stopped/idle vehicles show zero.
An open Tracking alert overrides the vehicle status to Reporting gap and its
speed to Unknown; the marker remains an illustrative stage-based position,
not a recent telemetry fix. Advancing/completing a trip does not clear an alert.

The map recomputes from shared saved data after creation, edits, progression,
reset, and reopening. Active trips take precedence over a last completed trip.
Original samples without a driver display that assignment as unknown.
Maintenance is explicitly not evaluated. Persistent SIMULATED / NOT LIVE GPS
labels appear on the map and vehicle sheets. No map SDK, tiles, location
permissions, network requests, or timer-driven fake telemetry are used.

## Demo reports and analytics

Open **More > Reports > Demo analytics** (the default report section).
Charts derive from the same saved trips and alerts used across the app:

- **Trips by current status:** all saved records, including cancelled and exception trips.
- **Simulated completions:** seven inclusive calendar days ending today in
  Africa/Lagos (UTC+1), using recorded completion timestamps, not inferred stages.
- **Vehicle workload:** active and completed trip assignments for each sample vehicle,
  including unused vehicles. These are counts, not utilization or driving hours.
- **Alert overview:** open, acknowledged-but-still-open, and resolved counts, plus
  open alerts grouped by kind. Alerts on completed trips remain included.

The vehicle selector scopes these charts and alerts through trip assignments.
The shared operations totals above remain all-time and all-vehicle; Customer
visits retains its separate date/asset filters and empty evidence state.
Charts update after saved creation, editing, progression, resolution, and reset;
reopening computes them from persisted records. Empty scopes display explicit
zero-record states. Bars include text counts and accessibility labels.

No geofence visits, tonnage, financial values, distances, or journey durations
are invented. Site coordinates and real customer locations are not available.

## Customer visit demo events

Use **More > Demo controls > Customer visit demo events** to record a sample
vehicle's arrival at Lekki Site or Apapa Terminal. The optional trip link only
accepts an active trip assigned to that vehicle; otherwise the event is outside
a trip. A vehicle cannot have more than one open sample visit at once. Record a
departure to complete the visit, or explicitly close it as incomplete. The
event's timestamp is recorded locally; nothing reads the device's location or
claims a geofence event occurred.

The Customer visits report filters by inclusive arrival dates in Africa/Lagos
(UTC+1) and the selected sample vehicle scope. It reports completed visits,
unique vehicles, sample sites/customers served, dwell for completed visits
only, open and explicitly incomplete visits, visits linked to a trip, and
daily arrivals/completions. Each manually entered arrival counts separately;
the demo does not merge or infer visits. Reported “GPS reporting gaps” are Not
evaluated. The site panel shows names only because no sample coordinates exist.

Visit events are saved with the shared demo snapshot and survive reopening.
Reset Demo or loading a guided scenario clears the visit events. Older saved
snapshots without visit records remain readable. Write errors do not publish
partial changes. These sample counts are not live location evidence, verified
customer attendance, or operational reporting.

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
