# QuakeNav

QuakeNav is a Flutter prototype for earthquake-aware navigation and evacuation support. It monitors quake intensity data, displays nearby evacuation sites on a map, and guides users toward the nearest available site when evacuation is recommended.

## Features

- Live map view with current-location tracking
- Firebase Realtime Database integration for quake intensity and evacuation site data
- Nearest evacuation site selection
- Push notification and overlay service scaffolding
- Authentication, messaging, account, settings, and onboarding screens

## Tech Stack

- Flutter / Dart
- Firebase Core, Auth, Realtime Database, and Messaging
- flutter_map and OpenStreetMap tiles
- Geolocator
- Firebase Cloud Functions

## Local Setup

Install Flutter dependencies:

```sh
flutter pub get
```

Create your Firebase Android config from the example:

```sh
cp android/app/google-services.example.json android/app/google-services.json
cp .env.example .env
```

Then replace the placeholder values with your own Firebase project values. The real `android/app/google-services.json` and `.env` files are intentionally ignored so API keys and project configuration are not committed.

Run the app:

```sh
flutter run
```

## Security Notes

- `android/app/google-services.json` is not committed.
- `.env` is not committed; `.env.example` documents the required local values.
- Local SDK paths in `android/local.properties` are not committed.
- Generated folders such as `.dart_tool`, `build`, `.firebase`, and `node_modules` are ignored.
- Firebase database rules and Google API key restrictions should be configured in Firebase Console / Google Cloud before publishing a production app.
