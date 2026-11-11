# Dumptrak Mobile Prototype

A standalone Flutter prototype for presenting a mobile-first ADAPTIQ Dumptrak
operations experience. It is not connected to the production application,
backend, map provider, telemetry, identity provider, or settlement services.

## Prototype screens

- **Home:** operational metrics, sample alerts, active trips, and a fleet insight.
- **Trips:** sample trip cards and a local-only create-trip interaction.
- **Map:** illustrative route and vehicle markers, explicitly marked as not live.
- **Alerts:** sample action-needed situations and informational records.
- **More:** Compliance & documents, Reports, Intelligence, Settlement, and FleetOps.

All records are illustrative. Creating a trip only adds a sample record in the
running app; it does not dispatch a vehicle or save data to a server. Real
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
`build/app/outputs/flutter-apk/app-debug.apk`. The app uses only Flutter's
built-in Material widgets and has no external package dependencies.
