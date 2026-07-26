# GK Quiz Competition Platform

Monorepo combining the Flutter client and the real Node.js/Express backend
(`gk-quiz-backend-with-leaderboards`), with the admin dashboard + user
management module merged in.

```
project/
├── frontend/   Flutter app (Clean Architecture, Riverpod, go_router)
├── backend/    Node.js/Express API (Postgres + Redis + Socket.IO)
├── README.md
└── .gitignore
```

No existing code in either project was rewritten. The admin dashboard/user
module (previously a separate handoff) has now been merged into your real
backend:

- `src/controllers/dashboardController.js`, `userController.js`
- `src/models/dashboardModel.js`, `userModel.js`
- `src/services/dashboardService.js`, `userService.js`
- `src/routes/dashboardRoutes.js`, `userRoutes.js`
- `src/validators/userSchemas.js` (renamed from `userValidators.js` to match
  your existing `authSchemas.js` / `questionSchemas.js` naming convention)
- `tests/dashboard.test.js`, `user.test.js`
- `src/database/migrations/005_add_user_status.sql` (renumbered — `003` and
  `004` were already taken by `003_user_auth_providers.sql` and
  `004_payments.sql`)
- Two lines added to `src/app.js`: the requires and
  `app.use('/api/admin/dashboard', ...)` / `app.use('/api/admin/users', ...)`

## One real integration change, and why

The user module's routes originally called `validate(schema, 'query')` /
`validate(schema, 'params')` — a different signature from your existing
`middleware/validate.js`, which expects `validate({ query, params, body })`.
Your `validate.js` is the one every other route already depends on, so I
updated the **new** `userRoutes.js` call sites to match it, rather than
touch the shared middleware. Nothing else in that file changed.

## ⚠️ Please review before deploying: block/suspend doesn't stop login yet

The new admin endpoints (`POST /api/admin/users/:id/block` etc.) write to a
`status` column (`active`/`blocked`/`suspended`, added by migration `005`).
Your existing `authService.js` login/refresh checks only look at the older
`is_blocked` boolean column — they don't know about `status` yet. Right now,
an admin "blocking" a user updates the database but **does not actually
prevent that user from logging in**. This needs one of:
- `authService.js` updated to also reject `status IN ('blocked','suspended')`, or
- `userModel.updateStatus` also flips `is_blocked` to stay in sync.

I didn't make this change myself since it touches your auth/security logic
directly — happy to patch it if you tell me which approach you'd prefer.

## Other things I noticed but didn't touch

Your backend upload has two parallel copies of the DB/migration wiring:
`src/config/db.js` vs `src/database/connection.js` (identical), and
`src/config/migrate.js` (reads the root `migrations/` folder, 3 files) vs
`src/database/migrate.js` (reads `src/database/migrations/`, now 5 files).
`package.json`'s `npm run migrate` script points at `src/database/migrate.js`,
so that's the one actually in use — the `config/` versions and the root
`migrations/` folder look like leftovers from an earlier pass. I left both in
place since you asked me not to remove anything, but you'll likely want to
delete the unused copies once you confirm.

## Frontend build note

`frontend/` contains only the Dart `lib/` source — no `android/`, `ios/`, or
`web/` platform folders, and no `pubspec.lock`. To get a buildable app:

```bash
cd frontend
flutter create . --project-name competition_app   # regenerates platform folders in place
flutter pub get
flutter run --dart-define-from-file=env/dev.json
```

API base URL is already environment-configurable — just point at the right
file, no code changes needed:

```bash
flutter run --dart-define-from-file=env/dev.json      # or staging.json / prod.json
flutter build apk --dart-define-from-file=env/prod.json
```

## Backend setup

```bash
cd backend
cp .env.example .env    # fill in DATABASE_URL, REDIS_URL, JWT_ACCESS_SECRET, JWT_REFRESH_SECRET, CORS_ORIGINS, ...
npm install
npm run migrate          # runs src/database/migrations/*.sql in order, including 005
npm run dev               # nodemon
npm start                  # production
npm test                   # jest + supertest
```

## Verification status

I don't have network/build access in this environment, so I could not run
`npm install`/`npm start`/`npm test` or `flutter pub get`/`flutter build`
here. What I did verify by hand against the actual source:
- Every new/changed backend file passes `node --check` (valid syntax)
- Every `require(...)` path in the new/changed files resolves to a real file
- The new routes are wired into `app.js` and match the real `validate()` and
  `auth` middleware signatures
- `dashboardModel.js`/`userModel.js` only query tables/columns that exist in
  your migrations (`users`, `refresh_tokens`, `matches`, `payments`, plus the
  new `status` columns from migration `005`)
- `swagger.js`'s `apis` glob (`./src/routes/*.js`) already picks up the new
  route files automatically — no Swagger config changes needed
