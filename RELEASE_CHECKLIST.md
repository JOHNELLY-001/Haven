# Release checklist — Haven (Android)

Status: **blocked on the upload keystore, the Maps key restriction for the new
package, and hardware QA.** Code, backend and portal are ready. Last build in
this round: `flutter build appbundle --release` (debug-signed on purpose, see
§3).

---

## 1. Application ID (decided)

Applied: **`tz.haven.app`** (`android/app/build.gradle.kts`). The Dart
namespace can stay `com.example.e_venues`; only the applicationId is public.

Google Play permanently binds the package name to the first upload. Changing
it later means shipping a brand-new app and losing reviews/installs.

Before release, update Google Cloud → the Maps API key's **Application
restrictions**:
- Add package `tz.haven.app`.
- Add the **upload/release SHA-1** (from the keystore in §2) *and* the debug
  SHA-1 if you install debug builds on a phone.
Without this the map renders blank in release builds.

Any future Android App Links (`assetlinks.json`) must use the same package.

## 2. Decision: upload keystore (one-time)

There is currently **no keystore** in the repo (correct — never commit one).
Generate it once, keep three backups (password manager + offline copy):

```powershell
keytool -genkeypair -v `
  -keystore "$env:USERPROFILE\haven-upload.jks" `
  -storetype JKS -keyalg RSA -keysize 4096 -validity 10000 `
  -alias haven
```

Then create `android/key.properties` (already gitignored):

```properties
storePassword=<the store password you just typed>
keyPassword=<same, unless you chose a different key password>
keyAlias=haven
storeFile=C:/Users/<you>/haven-upload.jks
```

Use forward slashes in `storeFile` (Gradle on Windows). Keep the `.jks`
**outside** the repo.

**Turn on Play App Signing** when creating the app. Google then holds the real
signing key and this file becomes your *upload* key — which can be reset if
lost. Losing it without Play App Signing means you can never update the app.

Once `android/key.properties` exists, `build.gradle.kts` automatically switches
release builds to the upload key (no code change needed).

## 3. Build & verify

```powershell
cd D:\Android\android_projects\e_venues
flutter pub get
flutter build appbundle --release
```

Output: `build\app\outputs\bundle\release\app-release.aab`

Sanity checks:
- Build log must **not** print the debug-key warning once `key.properties`
  exists.
- `bundletool build-apks --local-testing` (optional) to install the exact
  store artifact on a phone.
- Bump `version:` in `pubspec.yaml` (`1.0.0+1` → `1.0.0+2`) for every upload;
  Play rejects a reused `versionCode`.

Current ABI filter is `arm64-v8a` + `x86_64` (`build.gradle.kts:49`). Play
splits per device, so the x86_64 slice only affects emulator installs.

## 4. Play Console setup (first release)

- App name **Haven**, package name from §1, category, contact email.
- Store listing: 512×512 icon (`assets/images/haven.png` is 1254×1254 —
  downscale), 1024×500 feature graphic (needs design), 2–8 phone screenshots.
- Privacy policy URL (required — the app collects accounts, bookings, location,
  photos). Hosted at `https://haven-venue.vercel.app/privacy`; terms at
  `https://haven-venue.vercel.app/terms`.
- Data safety form: account data, approximate/precise location, photos,
  booking history; encrypted in transit = yes.
- Content rating questionnaire + target audience.
- Internal testing track first, then closed → production.

## 5. Device QA (from CHANGELOG_UI_V2)

Run on a real mid-range Android, not the emulator:

- [ ] Cold start → Explore scrolls at 60 fps
- [ ] System text size 200% → no clipped buttons, badges or nav labels
- [ ] TalkBack → nav tabs, hearts, filters, all booking steps announced
- [ ] Slow 3G / airplane mode → skeletons show, errors are friendly
- [ ] Hero flight tile→detail on every tab; pop mid-gallery swipe
- [ ] Booking flow end-to-end, incl. draft restore after process kill
- [ ] Venue detail: photos, map card, contact buttons, booking totals
- [ ] Login → logout → login; expired-token redirect

## 6. The new host flow (must pass on hardware)

1. Profile → **Host a Venue** → explainer sheet → Continue.
2. Browser opens the portal; email prefilled, same Haven password.
3. Publish a venue → success screen says **in review**.
4. Admin (`johnkiranga25@gmail.com`) → `haven-venue.vercel.app/admin` → approve.
5. App → Explore: venue appears (list cache is ≤30 s).
6. Edit the venue in the portal → back to `pending` → app hides it until
   re-approved.

## 7. Known gaps (not release blockers)

- No "back to Haven app" link on the web success screen yet (needs App Links,
  which require the final package name from §1).
- No approve/reject email — hosts see status on the portal dashboard.
- Support address is hidden in the UI for now but still used by the
  “Contact support” links (`ApiConfig.supportEmail` and the portal mailto);
  replace it with a real support mailbox before wide release.
- The 8-item device QA (§5) and the host flow (§6) still need a physical phone.

## 8. Release history

| Date | Version | Size | Signing | Notes |
|---|---|---|---|---|
| 2026-10-26 | 1.0.0+1 | 54.8 MB AAB → **11.1 MB download on arm64 phones** | debug | baseline build; SHA256 `BC2608AC…062523A7`. bundletool 1.18.3: arm64 11.1 MB, x86_64 11.3 MB, armeabi-v7a 10.6 MB. |
| 2026-10-26 | 1.0.0+1 | 55.3 MB AAB → **11.2 MB download on arm64 phones** | debug | real-data pass (profile, reviews, support screens); SHA256 `49EF6916…DBD03A`. bundletool 1.18.3: arm64 11.18 MB, x86_64 11.37 MB, armeabi-v7a 10.72 MB. |

The AAB is large because it also carries native debug symbols in
`BUNDLE-METADATA` (not downloaded by devices) and three ABI slices of the
engine (arm64 17.9 MB, armeabi-v7a 15.6 MB, x86_64 19.4 MB unpacked).

Do **not** use `flutter build apk --split-per-abi`: the hardcoded `abiFilters`
in `defaultConfig` conflicts with Gradle's split filters. For per-device size
figures use bundletool:

```powershell
java -jar bundletool-all-1.18.3.jar build-apks `
  --bundle=build\app\outputs\bundle\release\app-release.aab `
  --output=$env:TEMP\haven.apks --mode=default `
  --ks="$env:USERPROFILE\.android\debug.keystore" `
  --ks-key-alias=androiddebugkey --ks-pass=pass:android --key-pass=pass:android --overwrite

java -jar bundletool-all-1.18.3.jar get-size total `
  --apks=$env:TEMP\haven.apks --dimensions=ABI
```
