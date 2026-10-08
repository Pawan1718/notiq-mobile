# Notiq.Mobile — Flutter foundation

This is the mobile tenant app foundation. It consumes the existing Notiq.Api; no new backend or persistence layer is introduced.

## Prerequisites
- Flutter SDK (Dart >=3.4), Android Studio / Android SDK
- Existing Notiq.Api running, accessible from emulator/device

## Initialize native host projects

From this directory **once** after installing Flutter:

```bash
flutter create --platforms=android,ios --project-name notiq_mobile --org com.notiq .
flutter pub get
flutter analyze
flutter test
```

`flutter create` generates official Android/iOS runner files that are intentionally not hand-written here. Review generated bundle IDs/signing settings before shipping.

## Run

Android emulator (host ASP.NET API at port 5055):

```bash
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:5055
```

For physical devices use a reachable HTTPS address. Production builds strictly require HTTPS. Android's default cleartext restrictions may block the local HTTP emulator URL; prefer an HTTPS development endpoint or explicitly configure a debug-only network policy in the generated Android runner. Never enable production cleartext globally.

## Implemented foundation
- Responsive tenant login against `POST /api/auth/login`
- Validates Notiq `ApiResponse<T>` and tenant login response
- JWT/expiry/tenant stored in platform secure storage
- Authenticated Dio client, clears credentials on API 401
- Riverpod auth state, guarded GoRouter navigation
- Branded Material 3 light/dark themes
- Logout and placeholder dashboard (no mock KPIs)

## Phase 2: realtime inbox (feature branch)
- Uses the authenticated `/hubs/communication` SignalR hub with the secure session JWT.
- Listens for `conversation.message.changed`, `conversation.message.status.changed`, and `conversation.updated`.
- Invalidates the visible inbox page, and refreshes the selected conversation on matching events.
- Reconnects with bounded backoff; reloads visible data after a connection is restored.
- Closes the connection when the inbox is disposed (including route/logout transitions).
- Run `flutter pub get && flutter analyze && flutter test` and verify on an actual Android emulator/device before calling Phase 2 runtime-verified. Backend SignalR, JWT tenant authorization, and websocket/HTTPS access must be available.

## Not yet implemented
- Campaigns, notifications, billing
- Auth expiry notification while idle, session refresh (no refresh API was verified)
- Runtime validation on device and production signing

Do not hardcode tokens or credentials in source control or logs. The browser React sessionStorage approach is **not** copied into mobile.
