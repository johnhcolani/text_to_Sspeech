# AdMob setup for T 2 S

This branch adds the first, low-disruption monetization placement to T 2 S:

- Android and iOS only (Google Mobile Ads does not support this Flutter plugin on web/desktop).
- One anchored adaptive banner fixed at the bottom of the Home screen.
- No interstitial, app-open, or rewarded ads in the first release.
- UMP consent is requested on app launch before ads are requested.
- A visible **Privacy choices** entry point appears next to the ad area when UMP reports that it is required.
- Debug/profile builds use Google's official test banner IDs.
- Release builds do not request a banner unless a production banner ad unit ID is supplied.

## 1. Create or finish the AdMob account

1. Sign in to Google AdMob.
2. Finish the account, payment, and publisher setup requested by AdMob.
3. Do not use live ads while developing or repeatedly click your own production ads.

## 2. Add T 2 S as two apps in AdMob

Create/link the app separately for each store platform:

- Android / Google Play: package `com.johnacolani.text_to_speech`
- iOS / App Store: use the current iOS bundle identifier from the Xcode Runner target.

If a store version is not yet available, AdMob can create it as an unpublished app and it can be linked later.

## 3. Create one Banner ad unit per platform

For each AdMob app:

1. Open **Ad units**.
2. Choose **Banner**.
3. Name it something clear, for example:
   - `T2S Android Home Banner`
   - `T2S iOS Home Banner`
4. Copy the resulting ad unit ID.

## 4. Send these four IDs before production

The repository intentionally uses Google's sample **App IDs** for development and test banner IDs for non-release builds. Before publishing, replace/configure all four real values:

1. Android AdMob **App ID** (`ca-app-pub-...~...`)
2. Android Home Banner **Ad Unit ID** (`ca-app-pub-.../...`)
3. iOS AdMob **App ID** (`ca-app-pub-...~...`)
4. iOS Home Banner **Ad Unit ID** (`ca-app-pub-.../...`)

Native App IDs are stored in:

- `android/app/src/main/AndroidManifest.xml`
- `ios/Runner/Info.plist`

Production banner ad unit IDs are supplied at build time:

```bash
flutter build appbundle --release \
  --dart-define=ADMOB_ANDROID_BANNER_ID=ca-app-pub-XXXXXXXXXXXXXXXX/YYYYYYYYYY
```

```bash
flutter build ipa --release \
  --dart-define=ADMOB_IOS_BANNER_ID=ca-app-pub-XXXXXXXXXXXXXXXX/YYYYYYYYYY
```

If the production banner ID is omitted, the release build intentionally stays banner-ad-free rather than accidentally serving Google's test ad unit.

## 5. Configure Privacy & messaging in AdMob

In AdMob, open **Privacy & messaging** and configure the messages appropriate for the countries where the app is distributed. The app already uses UMP to:

- refresh consent information on launch,
- display a required consent form,
- call `canRequestAds()` before requesting ads,
- expose **Privacy choices** when UMP requires it.

Do not choose child-directed / age-restricted advertising settings until the intended store target audience for T 2 S has been decided. Store declarations and ad request configuration must agree with the actual audience.

For iOS, if an IDFA message/ATT flow is enabled in AdMob, the repository already includes `NSUserTrackingUsageDescription`. Review the final wording before release.

## 6. iOS production checklist

Before App Store release:

1. Replace the sample `GADApplicationIdentifier` with the real iOS AdMob App ID.
2. Add/update the current Google-recommended `SKAdNetworkItems` list in `ios/Runner/Info.plist` from Google's iOS Mobile Ads quick-start documentation.
3. Run `pod install` after `flutter pub get`.
4. Update App Store Connect **App Privacy** so it includes data collected by Google Mobile Ads / other third-party advertising partners used by the shipped configuration.
5. Update the app privacy policy as needed for advertising and consent.

## 7. Android production checklist

Before Google Play release:

1. Replace the sample Android AdMob App ID in `AndroidManifest.xml`.
2. Build with the production Android banner ad unit ID using `--dart-define`.
3. In Play Console, update the app's **Contains ads** declaration.
4. Review/update **Data safety**, privacy policy, target audience, and Families-related declarations as applicable to the actual app audience.

The current ads branch sets Android `minSdk = 23`, required by the current Google Mobile Ads SDK generation.

## 8. app-ads.txt

AdMob app ownership verification uses `app-ads.txt`.

1. Make sure the developer website is present in the Google Play and App Store listings.
2. In AdMob go to **Apps > View all apps > app-ads.txt > How to set up app-ads.txt**.
3. Copy the personalized AdMob line containing the publisher ID.
4. Publish it at the root of the developer website, for example:
   `https://www.4ideasapp.com/app-ads.txt`
5. Confirm the file opens publicly in a browser.
6. Return to AdMob and check/request verification.

Do not invent the publisher ID; use the personalized line copied from AdMob.

## 9. Local test sequence

Use the feature branch:

```bash
git fetch origin
git switch feat/admob-banner-ads
git pull origin feat/admob-banner-ads
flutter clean
flutter pub get
```

Android:

```bash
flutter run -d <android-device-id>
```

or:

```bash
flutter build apk --debug
```

iOS:

```bash
cd ios
pod install
cd ..
flutter run -d <ios-device-id>
```

During development the banner should clearly be a Google **test ad**. Do not substitute a live production ad unit merely to test layout or clicks.

## 10. Recommended monetization progression

First release:

- Home bottom adaptive banner only.

After real usage data and feedback:

- Consider a second bottom banner on History if it does not crowd the history cards.
- Consider an interstitial only at a natural break and with conservative frequency; never on every Play tap.
- Add rewarded ads only if there is a genuine optional reward/feature to grant.
- Consider a paid **Remove Ads** option later if users ask for it.
