# AttendX — Attendance Tracker

A premium, production-quality Flutter attendance tracker for Android, backed
entirely by **Supabase** (PostgreSQL, Auth, Realtime, RLS) and built with
**GitHub Actions** for automated APK builds.

## Features

- **Auth** — Email/password sign up & sign in via Supabase Auth, persisted
  sessions, password reset.
- **Home dashboard** — Overall attendance ring, today's classes, low-attendance
  warnings with "attend N more classes" guidance.
- **Fast attendance marking** — One-tap Present/Absent per subject/date/class,
  with duplicate prevention and automatic offline queueing.
- **Attendance calculator** — Classes needed to hit a target, max classes you
  can miss, and "what if" projections — all backed by unit-tested math.
- **Subjects** — Add/edit/delete, per-subject trend chart, target tracking.
- **Timetable** — Weekly (Mon–Sat) schedule with add/edit/delete, today
  highlighted.
- **History** — Filterable (status/subject/date), paginated attendance log.
- **Analytics** — Present vs absent breakdown, per-subject comparison chart.
- **Profile & Settings** — Light/Dark/System theme, default target %,
  notifications toggle, logout.
- **Offline support** — Attendance marked offline is queued locally and
  synced automatically once connectivity returns; History/Home still read
  from cache while offline.
- **Realtime** — Attendance changes propagate live across Home/Subjects/
  History without restarting the app.

## Tech Stack

| Layer          | Choice                                   |
|----------------|-------------------------------------------|
| UI framework   | Flutter (Material 3)                     |
| State mgmt     | Riverpod (`flutter_riverpod`)            |
| Routing        | `go_router`                              |
| Backend        | Supabase (Postgres, Auth, Realtime, RLS) |
| Charts         | `fl_chart`                               |
| Offline cache  | `shared_preferences`                     |
| CI/CD          | GitHub Actions                           |

## Architecture

```
lib/
  core/            theme, constants, services (Supabase, connectivity,
                   offline queue), utils (attendance calculator), errors
  models/          plain Dart data models
  repositories/    talk to Supabase; one per domain (auth, subjects, ...)
  providers/       Riverpod providers/notifiers wiring repositories to UI
  routing/         go_router configuration + auth redirect
  widgets/         shared widgets (gauge, subject card, sync banner, ...)
  features/        one folder per feature, each with its own screens/
  main.dart
```

---

## 1. Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) 3.24+ (stable)
- A free [Supabase](https://supabase.com) project
- A GitHub account (for CI builds)

## 2. Supabase Setup

1. Create a new project at [supabase.com](https://supabase.com).
2. Open **SQL Editor** → paste the entire contents of `supabase/schema.sql`
   → **Run**. This creates all tables, indexes, RLS policies, triggers, and
   enables Realtime on `attendance_records`, `subjects`, and `timetable`.
3. Go to **Project Settings → API** and copy:
   - **Project URL**
   - **anon / public key**
4. Confirm **Authentication → Providers → Email** is enabled (it is by
   default). Disable "Confirm email" during development if you want
   instant sign-in without checking an inbox.

## 3. Environment Variables

Copy the example file and fill in your own values — **never commit real
keys**:

```bash
cp .env.example .env
```

```
SUPABASE_URL=your_supabase_url
SUPABASE_ANON_KEY=your_supabase_anon_key
```

`.env` is already listed in `.gitignore`, so it will never be pushed to
GitHub.

## 4. Run Locally

```bash
flutter pub get
flutter run
```

## 5. Testing & Analysis

```bash
flutter analyze
flutter test
```

Unit tests cover the attendance-calculator math (classes needed, max
missable, projections, edge cases). Widget tests cover the gauge and the
login form's validation.

---

## 6. Push to GitHub

```bash
git init
git add .
git commit -m "Initial commit: AttendX"
git branch -M main
git remote add origin https://github.com/<your-username>/<your-repo>.git
git push -u origin main
```

## 7. Configure Repository Secrets (required for CI)

The GitHub Actions workflows build the app with your Supabase credentials
injected securely — they are **never** stored in the repo itself.

1. In your GitHub repo, go to **Settings → Secrets and variables → Actions**.
2. Add two **Repository secrets**:
   - `SUPABASE_URL`
   - `SUPABASE_ANON_KEY`

Without these secrets, the workflow still builds successfully, but the
resulting APK will have an empty `.env` and won't be able to reach Supabase
at runtime.

## 8. Enable & Run GitHub Actions

1. Go to the **Actions** tab of your repository → enable workflows if
   prompted.
2. Every push to `main` triggers `.github/workflows/build-apk.yml`, which:
   - sets up Java 17 + Flutter
   - generates the Gradle wrapper
   - runs `flutter analyze` and `flutter test`
   - builds `app-release.apk`
   - uploads it as a workflow **artifact**
3. Wait for the run to finish (green check), open it, and download
   **app-release** from the **Artifacts** section at the bottom of the run
   summary page.

### Tagged Releases (optional)

Pushing a version tag automatically builds and attaches the APK to a GitHub
Release via `.github/workflows/release-apk.yml`:

```bash
git tag v1.0.0
git push origin v1.0.0
```

---

## Troubleshooting

| Problem | Fix |
|---|---|
| `flutter.sdk not set in local.properties` | Run `flutter pub get` once locally, or let CI handle it — the workflow's `subosito/flutter-action` sets this up automatically. |
| App builds but can't reach Supabase | Check `.env` locally, or the `SUPABASE_URL`/`SUPABASE_ANON_KEY` repo secrets in CI. |
| `flutter analyze` fails on a fresh clone | Run `flutter pub get` first — generated files and package resolution must exist before analysis. |
| Gradle build fails in CI | The workflow generates the Gradle wrapper on the fly (`gradle wrapper --gradle-version 8.6`) using the Gradle preinstalled on GitHub's `ubuntu-latest` runners — no wrapper JAR is committed to the repo. |
| Duplicate attendance error | Attendance is uniquely keyed by (user, subject, date, class number) at the database level — this is expected and prevents double-marking. |

## Known Limitations

- No push notifications yet (the notifications toggle is stored but not
  wired to an actual notification scheduler).
- Offline queue uses `shared_preferences` (simple JSON queue) rather than a
  full local SQL mirror — sufficient for queuing marks made offline, but it
  doesn't give a complete offline history browsing experience beyond the
  last-fetched page.
- No iOS project scaffold included (Android/APK only, per the CI pipeline
  requested).
- Release APK is signed with the Android debug keystore so CI builds work
  out of the box — replace with your own keystore in
  `android/app/build.gradle` before publishing to the Play Store.
