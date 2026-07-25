# Competition App (Flutter, Clean Architecture)

Flutter client for the `competition-api` backend (admin CRUD over
`/api/admin/competitions`). Structured in three layers per feature:

```
lib/
  core/                          # shared, feature-agnostic code only
    config/env_config.dart      # dev/staging/prod values, see env/*.json
    constants/{api_constants,app_constants}.dart
    logging/{app_logger,log_level}.dart
    error/{exceptions,failures}.dart
    network/{dio_client,network_info,app_logging_interceptor}.dart
    usecases/usecase.dart
    theme/app_theme.dart
    di/core_injection.dart       # registers Connectivity/NetworkInfo/DioClient
    routes/app_router.dart       # merges every feature's route map

  features/
    competition/                 # <- fully self-contained vertical slice
      domain/                    # pure Dart, no Flutter/Dio imports
        entities/competition.dart
        repositories/competition_repository.dart   (abstract contract)
        usecases/                # one class per action: get/create/update/...
      data/                      # implements the domain contracts
        models/competition_model.dart              (JSON <-> entity)
        datasources/competition_remote_data_source.dart
        repositories/competition_repository_impl.dart
      presentation/              # Flutter widgets + state
        providers/competition_provider.dart        (ChangeNotifier)
        pages/{competition_list_page,competition_form_page}.dart
        widgets/competition_card.dart
      di/competition_injection.dart    # feature registers its own deps
      routes/competition_routes.dart   # feature owns its own route names

    # <- next feature (e.g. auth, wallet) would be a sibling folder here,
    #    with the exact same five-part shape: domain/data/presentation/di/routes

  injection_container.dart       # composition root — just calls each
                                  # feature's register function, in order
  main.dart                      # entrypoint only: error handling, DI, runApp
  app.dart                       # CompetitionApp root widget: theme/routing/banner
```

**Feature-first, not layer-first.** Everything a feature needs — its
entities, API calls, screens, DI registration, and routes — lives inside
that feature's folder. `core/` only holds things every feature shares
(network client, error types, theme). To add a new feature (say `auth` or
`wallet`), you copy the five-folder shape (`domain/data/presentation/di/routes`),
never touch another feature's files, and add one line to
`injection_container.dart` and one line to `core/routes/app_router.dart`.

Dependency rule inside each feature: `presentation → domain ← data`. The
domain layer has zero knowledge of Dio, JSON, or Flutter — only entities,
repository interfaces, and use cases. Swapping the backend, adding a cache
layer, or writing tests means touching that feature's `data/`, never
`presentation/` or `domain/`, and never another feature at all.

## State management: Riverpod + get_it, split by responsibility

- **get_it** (`core/di/`, `<feature>/di/`) wires the *data and domain*
  layers — data sources, repositories, use cases. These are plain
  singletons with no widget-tree lifecycle, so a service locator fits.
- **Riverpod** (`<feature>/presentation/providers/`) owns *UI state*.
  `CompetitionNotifier` is a `StateNotifier<CompetitionState>` exposed via
  `competitionNotifierProvider`; it pulls its use cases from `sl` (get_it)
  in its constructor, so nothing about the DI wiring above had to change.
  Pages are `ConsumerWidget`/`ConsumerStatefulWidget` and read state with
  `ref.watch(competitionNotifierProvider)`.
- `main.dart` wraps the app in `ProviderScope` (Riverpod's root) instead of
  `provider`'s `MultiProvider`.

## Routing: GoRouter, still feature-owned

`<feature>/routes/competition_routes.dart` exports a `List<RouteBase>`
(`CompetitionRoutes.routes`) instead of a page map. `core/routes/app_router.dart`
builds one `GoRouter` by spreading each feature's list together — adding a
new feature means adding one `...FeatureRoutes.routes` line there.

- List page: `/competitions`
- Form page: `/competitions/form`, nested under the list route
- Editing passes the `Competition` via `extra` (`context.push('form', extra: competition)`);
  creating passes nothing, so the form starts blank.
- `app.dart` uses `MaterialApp.router(routerConfig: AppRouter.router)`.
- Pages navigate with `context.push(...)` / `context.pop()` (the `go_router`
  extension on `BuildContext`) instead of `Navigator.of(context)`.

## Environment configuration

Three environments, one JSON file each, in `env/`:

| File | ENV_NAME | Network logging | Log level |
|---|---|---|---|
| `env/dev.json` | `dev` | on | `debug` |
| `env/staging.json` | `staging` | on | `info` |
| `env/prod.json` | `prod` | off | `warning` |

Passed in via `--dart-define-from-file=env/<name>.json` at run/build time
(see "Before you run it" above) and read by `core/config/env_config.dart`,
which every other env-dependent piece of code goes through:

- `ApiConstants.baseUrl` is just `EnvConfig.apiBaseUrl` — edit the URL in
  the JSON file, not in Dart.
- `DioClient` adds `AppLoggingInterceptor` only when
  `EnvConfig.enableNetworkLogging` is true, and always excludes headers
  from the log (that's where the bearer token lives) regardless of
  environment.
- `app.dart` shows a "DEV"/"STAGING" corner banner for any non-prod
  build, so a build that got the wrong `--dart-define-from-file` flag
  doesn't quietly look like production.

Add a new environment-dependent value by adding one field to `EnvConfig`
and one key to each of the three JSON files — nowhere else needs to
change.

## Logging

All logging goes through `core/logging/app_logger.dart` — nothing in the
app calls `print`/`debugPrint` directly. `AppLogger.debug/info/warning/error`
write via `dart:developer`'s `log()`, so entries show up with proper
level/name/timestamp in DevTools and `flutter logs`/Logcat/Console, not
just as plain stdout text.

- **Level filtering is compile-time.** `EnvConfig.logLevel` (from
  `LOG_LEVEL` in each `env/*.json`) sets the minimum severity; anything
  below it is dropped before the message string is even built, so a prod
  build isn't paying to format debug logs it'll never show.
- **HTTP logging** goes through `core/network/app_logging_interceptor.dart`
  instead of Dio's built-in `LogInterceptor` (which just calls `print`),
  so request/response lines respect the same level filtering. Headers are
  never logged at any level (that's where the bearer token lives); bodies
  only log at `debug`.
- **Uncaught errors are caught, not lost.** `main.dart` wraps `runApp` in
  `runZonedGuarded` (catches async errors that escape a try/catch) and
  sets `FlutterError.onError` (catches widget build/layout/paint errors)
  — both route to `AppLogger.error` instead of Flutter's default
  print-and-continue behavior.
- **Domain-level failures** (a failed load/create/update/delete) log a
  `warning` in `competition_notifier.dart` with the human-readable
  `Failure.message`, separate from the raw HTTP error the interceptor
  already logged — useful when a failure isn't a network error at all
  (e.g. a validation failure from the backend).

To add a log call anywhere: `AppLogger.info('message', tag: 'YourFeature')`
(or `.debug`/`.warning`/`.error`). Don't reach for `print` or a new
package — this is the one path.

## Auth token storage

The admin bearer token is stored via `flutter_secure_storage`
(`core/storage/token_storage.dart`), not `SharedPreferences` — on Android
it's backed by `EncryptedSharedPreferences` (Keystore-derived AES), on iOS
by Keychain. `DioClient` takes a `TokenStorage` in its constructor and
reads the token on every request's `onRequest` interceptor; it never talks
to the plugin directly. When you build the login screen, call
`sl<TokenStorage>().saveToken(token)` on success and
`sl<TokenStorage>().clearToken()` on logout.

## Payments (Cashfree)

Competition entry fees are collected via **Cashfree's Web Checkout**
(`flutter_cashfree_pg_sdk`), wired into the "Join competition" button on
`CompetitionDetailsPage`. Lives in `features/payment/`, same
domain/data/presentation/di shape as every other feature:

```
features/payment/
  domain/
    entities/payment_order.dart          # orderId + paymentSessionId from the backend
    entities/payment_verification.dart   # server-confirmed PAID/pending/failed + `joined`
    repositories/payment_repository.dart
    usecases/{create_payment_order,verify_payment}.dart
  data/
    models/{payment_order_model,payment_verification_model}.dart
    datasources/payment_remote_data_source.dart
    repositories/payment_repository_impl.dart
    services/cashfree_checkout_service.dart   # wraps the Cashfree SDK's callback API
  presentation/providers/
    join_competition_state.dart
    join_competition_notifier.dart       # orchestrates the 3 steps below
  di/payment_injection.dart
```

**Flow** (`JoinCompetitionNotifier.join`, triggered from
`CompetitionDetailsPage._handleJoin`):

1. **Create order — server-side.** `CreatePaymentOrder` calls
   `POST ApiConstants.paymentOrders` with just `{competitionId,
   difficulty}`; the backend creates the actual Cashfree order (this
   requires the merchant **secret key**, so it can never happen on the
   client) and returns `{orderId, paymentSessionId, orderAmount,
   currency}`. The backend — not the client — decides the amount, so a
   tampered request can't buy a cheaper entry.
2. **Checkout — client-side.** `CashfreeCheckoutService` builds a
   `CFSession` from that `orderId`/`paymentSessionId` and launches
   `CFWebCheckoutPaymentBuilder` via `CFPaymentGatewayService.doPayment`.
   Its `onVerify`/`onError` callbacks only mean the checkout UI
   *finished* — they are **not** trusted as the payment result.
3. **Confirm — server-side.** `VerifyPayment` calls
   `GET ApiConstants.paymentOrderStatus(orderId)`. Only a response with
   `status: success` **and** `joined: true` is treated as a completed
   join; anything else surfaces `errorMessage` back to the button.
   `CompetitionDetailsPage` pushes `WaitingQueuePage` only after this
   succeeds — see `CompetitionRoutes.queuePath`.

`ApiConstants.paymentOrders` / `paymentOrderStatus` and the model
`fromJson` field names are **assumed**, same caveat as every other
player-facing endpoint in this app (no confirmed backend schema yet) —
update them once the real routes exist.

### Environment

`CashfreeCheckoutService` picks `CFEnvironment.SANDBOX` for
dev/staging and `CFEnvironment.PRODUCTION` for prod, driven by the
existing `EnvConfig.isProd` — no new `--dart-define` key needed, but
this assumes the backend's Cashfree keys switch sandbox/production in
lockstep with `ENV_NAME`. Use Cashfree's sandbox test card/UPI
credentials (from your Cashfree dashboard) against the dev/staging
backend before testing with real money in prod.

### Native setup (not included in this export)

This project export has no `android/`/`ios/` platform folders, so the
following couldn't be applied directly — add them once those folders
exist, before running on a device:

- **Android**: `minSdkVersion 19` or higher in `android/app/build.gradle`.
- **iOS**: `platform :ios, '11.0'` (or higher) in `ios/Podfile`, and add
  to `ios/Runner/Info.plist`:
  ```xml
  <key>LSApplicationQueriesSchemes</key>
  <array>
    <string>amazonpay</string>
    <string>upi</string>
    <string>credpay</string>
    <string>bhim</string>
    <string>paytmmp</string>
    <string>phonepe</string>
    <string>tez</string>
    <string>navipay</string>
    <string>mobikwik</string>
    <string>myairtel</string>
    <string>popclubapp</string>
    <string>super</string>
    <string>kiwi</string>
    <string>simplypayupi</string>
    <string>whatsapp</string>
  </array>
  ```
  (Lets the WebView-based checkout deep-link into installed UPI apps
  instead of forcing everything through the mobile web flow.)
- Run `flutter pub get` after these are in place — this PR only adds
  `flutter_cashfree_pg_sdk` to `pubspec.yaml`, it doesn't (and can't,
  without the platform folders) run pub/pod install for you.

## Matchmaking (REST + Socket.IO)

Once payment is confirmed, the player is placed in a live matchmaking
queue and `WaitingQueuePage` shows their position in real time. Lives in
`features/matchmaking/`, same domain/data/presentation/di shape as
`payment`:

```
features/matchmaking/
  domain/
    entities/matchmaking_entry.dart      # queueId, status, position, playersAhead, waitSeconds
    repositories/matchmaking_repository.dart
    usecases/{enter_matchmaking_queue,get_matchmaking_status,leave_matchmaking_queue}.dart
  data/
    models/matchmaking_entry_model.dart
    datasources/matchmaking_remote_data_source.dart
    repositories/matchmaking_repository_impl.dart
    services/matchmaking_socket_service.dart   # wraps socket_io_client
  di/matchmaking_injection.dart
```

**Flow:**

1. **Enter queue — server-side.** Right after `VerifyPayment` confirms
   `joined: true`, `JoinCompetitionNotifier` calls `EnterMatchmakingQueue`
   (`POST ApiConstants.matchmakingQueue`), which returns the initial
   `MatchmakingEntry` (`queueId` + starting position/players-ahead/wait
   time). `CompetitionDetailsPage` pushes `WaitingQueuePage` with that
   entry as `WaitingQueueArgs`.
2. **Real-time updates — Socket.IO.** `WaitingQueuePage` calls
   `MatchmakingSocketService.watchQueue(queueId)`, which connects a
   shared socket (auth'd with the stored bearer token via
   `auth: {token}`), emits `ApiConstants.matchmakingJoinEvent` to
   subscribe, and streams `ApiConstants.matchmakingUpdateEvent` payloads
   back as they arrive — no polling once this is live.
3. **REST fallback.** `GetMatchmakingStatus`
   (`GET ApiConstants.matchmakingQueueEntry(queueId)`) polls every 2s
   until the socket delivers its first update, and resumes
   automatically if the socket ever errors or disconnects — see
   `WaitingQueuePage`'s doc comment for the exact handoff logic. The
   player is never left stale just because realtime is unavailable.
4. **Leave queue.** `LeaveMatchmakingQueue`
   (`DELETE ApiConstants.matchmakingQueueEntry(queueId)`) plus
   `MatchmakingSocketService.stopWatching` (emits
   `ApiConstants.matchmakingLeaveEvent`) both fire from
   `WaitingQueuePage._handleCancel` and `dispose`.

`ApiConstants.socketUrl`/`socketPath` and all three event names
(`matchmakingJoinEvent` / `matchmakingLeaveEvent` /
`matchmakingUpdateEvent`), plus `matchmakingQueue` /
`matchmakingQueueEntry` and the model `fromJson` field names, are
**assumed** — same no-confirmed-schema caveat as the payment endpoints.
In particular this assumes the backend scopes `matchmakingUpdateEvent`
per subscriber (e.g. a Socket.IO room per `queueId`); update
`MatchmakingSocketService` once the real contract is known.

## Theming

`core/theme/` holds one file per mode:
- `app_colors.dart` — the single seed color both modes are generated from
- `light_theme.dart` / `dark_theme.dart` — mirror each other component-for-
  component (same shapes, paddings, elevations); only colors differ
- `app_theme.dart` — thin facade (`AppTheme.light` / `AppTheme.dark`) that
  `app.dart` imports

`app.dart` sets `theme`, `darkTheme`, and `themeMode: ThemeMode.system`,
so the app follows the device's light/dark setting automatically. If you
want a manual in-app toggle instead, that'd be a small Riverpod
`StateProvider<ThemeMode>` read in `app.dart`.

Note: any hardcoded `Colors.xyz` in feature widgets (like the status dot
in `competition_card.dart`) needs a light/dark-aware variant — pull from
`Theme.of(context).colorScheme` or branch on `Theme.of(context).brightness`
like that file does, rather than a fixed shade that only looks right in
one mode.

## Responsive utilities

`core/utils/` has three pieces, for two different use cases:

- **`breakpoints.dart`** — the width cutoffs (`mobile < 600 < tablet < 1024 <= desktop`),
  matching Material 3's compact/medium/expanded window size classes.
- **`responsive_context.dart`** — a `BuildContext` extension for the common
  "read it once during build" case: `context.isMobile`, `context.deviceType`,
  or `context.responsive(mobile: 1, tablet: 2, desktop: 3)` to pick a value
  per size class (unset `tablet`/`desktop` fall back to the size below).
- **`responsive_builder.dart`** — `ResponsiveBuilder`, a `LayoutBuilder`
  wrapper for when a widget needs to *reactively* rebuild as its available
  width crosses a breakpoint (e.g. inside a resizable pane) rather than
  the whole screen's width.

`competition_list_page.dart` already uses `context.responsive(...)` to
switch between a single-column `ListView` on mobile and a
`GridView` (2 columns tablet, 3 desktop) on wider layouts — copy that
pattern for any other list screens you add.

## What's implemented

List / create / edit / enable-disable / delete competitions, matching the
admin CRUD scope described in `WIRING.md` from `competition-api.zip`
(no leaderboard endpoints — those weren't in that scope). Player-facing
live competitions, details, and joining (via Cashfree payment — see
"Payments (Cashfree)" above) are implemented against **assumed** endpoint
shapes, since none of that was part of the confirmed admin CRUD scope
either; update `ApiConstants`/the relevant models once the real routes
are known. Matchmaking after a successful join (queue entry, real-time
position updates via Socket.IO with a REST polling fallback, leaving the
queue — see "Matchmaking (REST + Socket.IO)" above) is wired the same
way, also against assumed endpoint/event shapes.

## Before you run it

1. **Point it at your backend.** Environment values (API URL, environment
   name, network logging) live in `env/dev.json`, `env/staging.json`, and
   `env/prod.json` — edit the `API_BASE_URL` in whichever file matches
   your backend, then run/build with `--dart-define-from-file`:
   ```
   flutter run --dart-define-from-file=env/dev.json
   flutter build apk --dart-define-from-file=env/prod.json
   ```
   `lib/core/config/env_config.dart` reads these at compile time; nothing
   in code needs to change to switch environments. Forgetting the flag
   falls back to `env_config.dart`'s own defaults (dev-like, with a
   placeholder URL), and any build that isn't `prod` shows a colored
   "DEV"/"STAGING" banner in the top-right corner so a misrouted build is
   obvious before it's mistaken for production.
2. **Admin auth token.** The Dio client reads a bearer token from secure
   storage (`admin_token`, see `core/storage/token_storage.dart`). Wire up
   your login screen to store it there — `dio_client.dart` already
   attaches it to every request.
3. **Generate native folders.** This zip only contains `lib/`, `env/`,
   `pubspec.yaml`, and `analysis_options.yaml` — no `android/`, `ios/`,
   `web/`, etc., since those are binary/generated scaffolding the Flutter
   SDK produces, and I don't have the SDK available here. Once you unzip
   this into a folder, run:
   ```
   flutter create .
   flutter pub get
   flutter run --dart-define-from-file=env/dev.json
   ```
   `flutter create .` will fill in the platform folders without touching
   your `lib/` code.

## Heads-up on your usual workflow

Your DiamondPlay setup (GitHub web UI edits → Vercel auto-deploy) works
because that's a web app — Vercel builds it in the cloud. Flutter compiles
to a native binary, so that pipeline won't build this app. You'll need one of:
- A laptop/desktop with Flutter installed (Android Studio or VS Code), or
- A cloud IDE with Flutter support (e.g. FlutHub, Codemagic CI for builds
  triggered from GitHub, or a service like Zapp.run / DartPad won't be
  enough since this is a multi-file project).

Happy to help set up Codemagic or a similar CI so you can keep building
from your phone if that's useful — just say the word.
