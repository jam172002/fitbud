# FitBud on Supabase - setup & operations

Project ref: `tcvldfsydgxxfdyrwspv` (region ap-southeast-1)

Already done by the migration (nothing to do): schema + RLS + triggers + RPCs,
realtime publication, storage buckets/policies, sample data, edge functions
`delete-account` and `push-notification` deployed.

## What lives where

| Was (Firebase)                         | Now (Supabase)                                             |
|----------------------------------------|------------------------------------------------------------|
| Firebase Auth                          | Supabase Auth (email, Google, Apple-on-iOS)                |
| Firestore + security rules             | Postgres + RLS (`supabase/migrations`)                     |
| Cloud Functions (notifications, scan)  | DB triggers + RPCs (`scan_gym`, `accept_*`, ...)           |
| Cloud Function `requestAccountDeletion`| Edge function `delete-account`                             |
| Cloud Storage                          | Storage buckets `avatars`, `chat-media`                    |
| FCM push                               | still FCM (free) - sent by edge function `push-notification` |
| App Check                              | Not available - see "Abuse protection" below              |
| Hosting (static pages)                 | unchanged (Firebase Hosting works for static pages only)   |

## One-time dashboard / secret steps

### 1. Auth URL configuration
Dashboard -> Authentication -> URL Configuration -> **Redirect URLs**, add:
`com.fitbudpk.fitbud://login-callback/`

### 2. Google sign-in
1. Google Cloud Console -> APIs & Services -> Credentials. Create OAuth client IDs:
   a **Web** client (used as `serverClientId`), an **Android** client (package
   `com.fitbudpk.fitbud` + your SHA-1), and an **iOS** client.
2. Dashboard -> Authentication -> Providers -> Google: enable, paste the **Web**
   client ID and secret. Turn on "Skip nonce check" only if the native flow asks for it.
3. Run the app with the ids:
   `flutter run --dart-define=GOOGLE_WEB_CLIENT_ID=<web-id> --dart-define=GOOGLE_IOS_CLIENT_ID=<ios-id>`
   (put the iOS reversed client id in `ios/Runner/Info.plist` URL schemes as the
   `google_sign_in` docs describe).

### 3. Apple sign-in (iOS only - the button is hidden on other platforms)
1. Apple Developer: enable "Sign in with Apple" for the App ID `com.fitbudpk.fitbud`.
2. Xcode: add the "Sign in with Apple" capability to the Runner target.
3. Dashboard -> Authentication -> Providers -> Apple: enable, add
   `com.fitbudpk.fitbud` under "Authorized Client IDs".

### 4. Push notifications (FCM stays; no Blaze plan needed)
FCM delivery through the HTTP v1 API is free. Only a service-account key is needed:

1. Firebase console -> Project settings -> Service accounts -> *Generate new private key*.
   Keep this file out of git.
2. Store it and the webhook secret (pick any long random string for `<secret>`):

```bash
supabase secrets set PUSH_WEBHOOK_SECRET=<secret>
supabase secrets set FIREBASE_SERVICE_ACCOUNT="$(cat path/to/service-account.json)"
```

3. Store the same secret in Vault so the database trigger can sign its calls
   (SQL editor):

```sql
select vault.create_secret('<secret>', 'push_webhook_secret');
```

Until step 3 is done, notifications are still written to the `notifications`
table (and shown in-app); only the OS push is skipped.

### 5. Email settings
Authentication -> Providers -> Email: decide on "Confirm email". With it on, sign-up
asks the user to confirm first (the app handles this). For production configure a
custom SMTP provider (Authentication -> SMTP) - the built-in mailer is heavily rate-limited.

### 6. Make an admin (optional)
Admin = `app_metadata.admin = true` (can write gyms/plans/products/activities and read reports):

```sql
update auth.users set raw_app_meta_data = raw_app_meta_data || '{"admin": true}' where email = 'you@example.com';
```

### 7. Admin panel and gym panel
Both panels (sibling folders `fitbud_admin/` and `gym_panel/`) now use the same
Supabase project as the app - no Firebase SDK.

* **Admin panel** signs in with email + password and requires `app_metadata.admin = true`
  (step 6). It manages gyms, plans, products, activities and users (RLS: `is_admin()`).
  Images go to the public `catalog-media` bucket (admin-only write).
* **Gym owners** are created from the admin panel (Gyms -> Add): the admin-only edge
  function `create-gym-owner` creates the login (`app_metadata.role = gymOwner`) and the
  gym row stores it in `gyms.owner_uid`. The **gym panel** finds the owner's gym through
  that column; RLS (`is_gym_owner`) lets an owner read only their own gym's `scans` and
  `gym_stats_daily`.
* Admin "Delete user" calls `delete-account` with `targetUserId` (admins only), i.e. the same
  full deletion pipeline as in-app account deletion.
* Gym-panel "Forgot password": add the panel's URL under Authentication -> URL
  Configuration -> Redirect URLs, otherwise the reset link opens the Site URL.
* Run the panels with `--dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...`
  to point at another project (defaults are the same public values the app uses).
* Firebase Hosting is still used to serve the two web builds (`firebase.json` /
  `.firebaserc` in each panel); nothing else from Firebase remains in them.

Deploy order: `supabase db push` (adds the gym owner columns/policies and the bucket), then
`supabase functions deploy create-gym-owner delete-account`.

## Abuse protection (replaces App Check)
Supabase has no App Check equivalent. The layered approach used instead:
* **RLS everywhere** - the anon key alone can read/write nothing sensitive.
* **Server-side rules** for premium state, check-in cooldown, buddy acceptance.
* **Rate limits**: Authentication -> Rate Limits (sign-ins, OTP/email sends).
* **CAPTCHA on auth** (recommended before launch): Authentication -> Attack
  Protection -> enable Cloudflare Turnstile / hCaptcha, then pass the token in
  `signUp`/`signInWithPassword` (`captchaToken:`). Free.
* Optionally gate the edge functions on Play Integrity / App Attest tokens later.

## Sample data
`supabase/seed.sql` (already applied) creates activities, 5 gyms, 3 plans,
4 products and 5 demo people (premium, **no password**, so they can't be logged
into). After you sign up, edit the email in `supabase/demo_connect.sql` and run it
in the SQL editor to give your account buddies, a chat, a request and a session invite.

## Developing
```bash
supabase db push                 # apply new migrations to the linked project
supabase functions deploy        # deploy edge functions
supabase db query --linked -f supabase/tests/smoke.sql   # RLS/RPC smoke test (rolls back)
```
Client config is in `lib/data/supabase_config.dart` (public URL + publishable key);
override per build with `--dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...`.

## Not migrated / follow-ups
* **Payments** (JazzCash/EasyPaisa) were never implemented server-side; purchase
  paths still refuse. Premium/subscription rows are server-write-only by RLS.
* **Firebase hosting** still serves `public/` (privacy, delete-account, payments).
  Any static host works; Firebase project can be reduced to FCM only.
* Retention: gym scans older than 730 days are purged nightly by `pg_cron`
  (placeholder period - confirm with the project owner).
