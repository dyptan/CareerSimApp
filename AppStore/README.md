# Career Simulator 1.0: App Store submission guide

Everything App Store Connect asks for, matched to what the code actually does. The long texts live next to this file so you can copy them straight into the forms.

**Status, 2026-10-05.** Through the App Store Connect API, the iOS and macOS 1.0 versions already have their **description, promotional text, keywords, copyright** (release set to manual) and the app's **subtitle** filled in from `en-US/`; the **screenshots** are uploaded (7 iPhone 6.5", 7 iPad 13", 5 Mac, in the order of their file names; every one processed and checked against the required size); and the 18 Game Center leaderboards exist as drafts. The Support and Privacy Policy pages are published with GitHub Pages (§5); their URLs still have to be entered in App Store Connect. Still open: the review contact details and notes (the API requires a contact email and phone, in `+<country code> …` form, before it saves the notes), builds, the declarations (content rights, App Privacy, EU trader status, availability), and adding the leaderboards to each version. Nothing has been submitted.

| File | Goes into |
| --- | --- |
| `en-US/subtitle.txt` | App Information ▸ Subtitle (28 / 30) |
| `en-US/promotional-text.txt` | Promotional Text (150 / 170) |
| `en-US/description.txt` | Description (2,379 / 4,000) |
| `en-US/keywords.txt` | Keywords (97 / 100) |
| `en-US/copyright.txt` | Copyright |
| `en-US/review-notes-ios.txt` | App Review Information ▸ Notes, iOS page |
| `en-US/review-notes-macos.txt` | App Review Information ▸ Notes, macOS page |
| `../docs/index.html`, `../docs/privacy.html` | Support URL and Privacy Policy URL (published with GitHub Pages, §5) |

## 1. "iOS App Version 1.0" page

| Field | What to enter |
| --- | --- |
| **Previews and Screenshots ▸ iPhone 6.5" Display** | 1 to 10 portrait screenshots, **1284 × 2778** (or 1242 × 2688). Apple reuses them for the other iPhone sizes. App previews (video) are optional. Seven ready-made shots are in `screenshots/iphone-6.5/` (start screen, how to play, careers, job odds, school comparison, advisor, skills), already 1284 × 2778 with no alpha channel; they are not committed to git. |
| **… ▸ iPad tab** | Required, because the app is universal (`TARGETED_DEVICE_FAMILY = 1,2`): 13" display, **2064 × 2752** or 2048 × 2732. The same seven scenes are in `screenshots/ipad-13/`, at exactly 2064 × 2752 with no alpha channel (iPad Pro 13-inch simulator, portrait), also not committed. |
| **… ▸ Apple Watch tab** | Leave empty. |
| **Promotional Text** | `en-US/promotional-text.txt`. Optional, and can be changed later without a new version. |
| **Description** | `en-US/description.txt`. Keep the "Compete on Game Center" paragraph only if the 18 leaderboards are live and attached to this version (§4); otherwise delete it. |
| **Keywords** | `en-US/keywords.txt`. It leaves out "career" and "simulator", which Apple already indexes from the name. |
| **Support URL** | Required: `https://dyptan.github.io/CareerSimApp/` (the page is `docs/index.html`, §5). It links to GitHub Issues as the way to contact you. |
| **Marketing URL** | Leave blank (optional). |
| **Version** | `1.0`, already filled in. The project's `MARKETING_VERSION` is now `1.0` so the build matches this record. |
| **Copyright** | `2026 Ivan Dyptan` (the year, then the rights holder; no URL, no ©). |
| **Routing App Coverage File**, **App Clip**, **iMessage App** | Not applicable. Leave them. |
| **Build** | Click **Add Build** and pick the processed 1.0 build. The button is greyed out until a build with version `1.0` has finished processing (§6). |
| **Game Center** | Nothing to type here. Leave Multiplayer Compatibility as it is (the game is single-player). The leaderboards are set up under Game Center in the left menu (§4). |
| **Sign-in required** | **Untick it.** The app has no accounts; leaving it ticked forces a username and password you do not have. |
| **Contact Information** | First name `Ivan`, last name `Dyptan`, plus your own phone number (with country code) and email. Only App Review sees these. |
| **Notes** | `en-US/review-notes-ios.txt` (2,404 / 4,000). |
| **Attachment** | Skip. |
| **App Store Version Release** | **Manually release this version** (already selected) is the safe choice for a first release: you decide when it goes live once it is approved. |

## 2. "macOS App Version 1.0" page

Same form again, separately. Differences:

* Screenshots: Mac sizes, 16:10: **1280 × 800, 1440 × 900, 2560 × 1600 or 2880 × 1800**, with no alpha channel (a plain window grab has both problems). Take them on your Mac with the app running; seven are already prepared in `screenshots/mac/` (upload 01 to 05; 06 and 07 are the weaker ones) (2560 × 1600, the capture centred at native sharpness on a neutral background with a shadow). Capture with the Mac's region set to the United States, or launch with `-AppleLanguages "(en)" -AppleLocale en_US`, so numbers read "4,000 $/yr" instead of "4.000 $/yr".
* Notes: `en-US/review-notes-macos.txt`.
* Build: the macOS build from Xcode Cloud (the build list is per platform).
* The description, keywords, support URL and copyright can be identical.

## 3. Sections in the left menu that also block "Add for Review"

| Section | What to answer |
| --- | --- |
| **App Information** | Name `Career Simulator`. Subtitle from `en-US/subtitle.txt`. Primary category **Games** (subcategories Simulation, Strategy); the secondary category is optional. **Privacy Policy URL is required** for iOS and macOS: `https://dyptan.github.io/CareerSimApp/privacy.html` (§5). **Content Rights:** the app does not contain, show or access third-party content. |
| **App Privacy** | **Data Not Collected.** The app has no networking of its own, and no analytics, ads or tracking. Apple states you are not responsible for disclosing data Apple itself collects (Game Center), and data processed only on device (the Apple Intelligence advisor) is not "collected". The project now ships `PrivacyInfo.xcprivacy` declaring no tracking, no collected data, and the one required-reason API it uses: UserDefaults (`@AppStorage("hasSeenCoach")`, reason `CA92.1`). |
| **Ratings and Reviews** (age rating) | Answer **None / No** to every content question: no violence, sexual content, profanity, horror, alcohol or drugs, simulated gambling, contests, user-generated content, web access or messaging with other people. Expected result: **4+**. If a question asks about AI chat: the advisor is Apple's on-device model, limited to game facts. |
| **Pricing and Availability** (under Monetization) | Your choice of price (the app has no in-app purchases). **Untick China mainland and Vietnam**: Apple requires games there to hold a government approval number or licence. South Korea needs nothing extra (a GRAC rating is only for casino or Frequent/Intense gambling, sexual, alcohol or violence content). |
| **App Accessibility** | Optional. Skip for 1.0 unless you have tested VoiceOver, Larger Text and the rest and can honestly tick them. |
| **Digital Services Act** (EU trader status) | Account Holder or Admin only: **Business** (top bar) ▸ **Agreements** tab ▸ **Compliance** section ▸ *Complete Compliance Requirements* next to Digital Services Act. Then, per app: **App Information** ▸ *App Store Regulations and Permits* ▸ Digital Services Act ▸ **Edit**. It is required to submit a new app, and apps without it are removed from the EU storefronts. |
| **Export compliance** | No prompt: the project now sets `ITSAppUsesNonExemptEncryption = NO` (the app uses only the encryption built into the OS). |

## 4. Game Center leaderboards

The 18 boards (US plus 17 country suffixes) were created in App Store Connect on 2026-10-03 by `Tools/GameCenter/leaderboards.py create --apply`, each as a draft with six localizations (`INTEGER`, best score, high is best). Apple caps a leaderboard name at 30 characters, so the name a player sees is the country's own; the description says what is measured.

What is left is to **add the leaderboards to each version page**, under **Game Center**, so they ship with 1.0: a draft board is not live until it belongs to a released version. The entitlement `com.apple.developer.game-center` is already in `CareersApp.entitlements`.

To change or add a board, edit the table in the script, run `leaderboards.py check`, then look at the dry run before applying:

```bash
python3 Tools/GameCenter/leaderboards.py create
ASC_KEY_ID=… ASC_ISSUER_ID=… ASC_KEY_PATH=~/AuthKey_….p8 ASC_BUNDLE_ID=dev.dyptan.carrersim python3 Tools/GameCenter/leaderboards.py create --apply
```

The key comes from Users and Access ▸ Integrations ▸ App Store Connect API. The key used on 2026-10-03 could create the leaderboards but was refused (HTTP 403) when writing the version page's text fields, so filling those through the API needs a key with the **App Manager** (or Admin) role.

## 5. Support and privacy pages

Both pages live in `docs/` and are served by GitHub Pages: `docs/index.html` is the Support page and `docs/privacy.html` the Privacy Policy.

| Field in App Store Connect | URL |
| --- | --- |
| Support URL (each version page) | `https://dyptan.github.io/CareerSimApp/` |
| Privacy Policy URL (App Information, shared by iOS and macOS) | `https://dyptan.github.io/CareerSimApp/privacy.html` |

The contact on both pages is **GitHub Issues** of this repository (turned on 2026-10-05), so no email address is published. Posting there needs a free GitHub account; if App Review or players need a plain email address, add one to both pages.

Pages was turned on 2026-10-05 to serve `/docs` from the branch `claude/appstore-prep`, so the URLs work before the pull request is merged. **After PR #43 is merged, switch the source to `main` / `docs`** (Settings ▸ Pages ▸ Build and deployment, or `gh api -X PUT repos/dyptan/CareerSimApp/pages -f 'source[branch]=main' -f 'source[path]=/docs'`); until then, edits made on `main` do not reach the site.

The privacy policy states what the app does, so keep it true: if a change adds networking, analytics, storage of personal data or another third-party package, update `docs/privacy.html` and its "Last updated" date in the same pull request, and revisit the App Privacy answers.

## 6. Builds

Xcode Cloud archives on a tag. A build only attaches to this page if its version string is `1.0` (`MARKETING_VERSION`, now set). After this branch is merged, tag it (for example `v1.0.0-rc.1`), wait for the iOS and macOS builds to finish processing in App Store Connect, then **Add Build**. A build that stays on "Missing Compliance" cannot be selected; the new Info.plist key prevents that.

## 7. Before you click "Add for Review"

* [ ] Sign-in required is unticked
* [ ] Support URL and Privacy Policy URL are entered and open in a browser; Pages serves `main` / `docs` (not the PR branch)
* [ ] Screenshots uploaded for iPhone, iPad (and Mac on the macOS page)
* [ ] Build attached on both platforms
* [ ] Leaderboards created and attached, or the Game Center paragraphs removed from the description and notes
* [ ] App Privacy, Age Rating, Pricing and Availability, Trader status all complete
* [ ] Contact phone and email filled in
