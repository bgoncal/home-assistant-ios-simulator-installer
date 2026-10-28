# Home Assistant iOS Simulator Installer

A Mac app for trying test builds of Home Assistant without building anything:

- the [iOS app](https://github.com/home-assistant/iOS), installed in the iOS Simulator,
- the [Android app](https://github.com/home-assistant/android), installed in the Android emulator, or downloaded as an APK,
- [Core](https://github.com/home-assistant/core), the Home Assistant server, running on your Mac,
- the [frontend](https://github.com/home-assistant/frontend), the web interface, served by that server.

Pick the latest version or a pull request for each one, in any combination: just the iOS app with your own server, both apps, just a server, a frontend pull request on the latest Core, or everything together.

## Install

1. Download `Home-Assistant-iOS-Simulator-Installer.zip` from the [latest release](https://github.com/bgoncal/home-assistant-ios-simulator-installer/releases/latest).
2. Double-click the zip to unzip it, and drag **Home Assistant iOS Simulator Installer** into your **Applications** folder.
3. The app isn't signed by Apple, so macOS refuses to open it at first. Open **Terminal** and run this once:

   ```bash
   xattr -dr com.apple.quarantine "/Applications/Home Assistant iOS Simulator Installer.app"
   ```

4. Open the app from Applications.

Or do all of it in one go from Terminal:

```bash
curl -fL -o /tmp/ha-sim-installer.zip https://github.com/bgoncal/home-assistant-ios-simulator-installer/releases/latest/download/Home-Assistant-iOS-Simulator-Installer.zip && ditto -x -k /tmp/ha-sim-installer.zip /Applications && xattr -dr com.apple.quarantine "/Applications/Home Assistant iOS Simulator Installer.app" && open "/Applications/Home Assistant iOS Simulator Installer.app"
```

## Updates

The app checks for a new version each time it opens, and you can check any time from the app menu with **Check for Updates…**. When one is available, a banner at the top of the window shows what's new: click **Install Update** and the app downloads it, replaces itself and reopens. You don't need to run the Terminal command again.

Version 0.1 can't update itself. If you have it, download the latest version once by following [Install](#install) again.

## What you need

- A Mac with Apple silicon (M1 or newer) running macOS 14 or later.
- For the Android app in the emulator: nothing to install beforehand. Setup downloads Google's Android tools and an emulator (a few gigabytes), or uses Android Studio's if you have it. Downloading the APK needs none of this.
- For the iOS app: [Xcode](https://apps.apple.com/app/xcode/id497799835), free from the App Store. You never build anything with it: it's only needed because it contains the iOS Simulator. Plan for about 40 GB of free space.
- For test builds of the apps and the frontend: a free [GitHub](https://github.com/signup) account. GitHub only lets signed-in users download them.
- For Core: about 2 GB of free space. Nothing else to install.
- To use the iOS app without Core: a Home Assistant server your Mac can reach.

## Using it

The sidebar has three pages, **Run**, **Setup** and **Downloads**, and your **Recent** runs. Each part shows its status on the Run page: green when it's running, red when it failed. The inspector on the right (toolbar button, or the ⓘ next to a status) shows each part's details, extra settings and log.

### Setup

Only the apps need this page. Core needs nothing: its first run downloads what it needs.

- **Xcode:** if it's missing, **Get Xcode** opens it in the App Store. If you have several versions, pick one from the menu. **Other Versions…** downloads another one: it opens Apple's download page in your browser (sign in with your Apple Account if asked), waits for the download to finish in your Downloads folder, and installs it in Applications for you.
- **Xcode license:** shown only when Xcode was never opened. Click **Open Xcode**, agree to the license, then come back and click **Check Again**.
- **iOS Simulator:** shows the iOS versions you have. **Add Simulator…** creates another simulated iPhone or iPad. **Other Versions…** downloads another iOS version (several gigabytes each). Turn on **Show betas** to see beta versions.
- **Android emulator:** if you have Android Studio, its emulator and virtual devices are used. Otherwise **Set Up…** shows Google's Android SDK license; once you accept it, the app downloads Java, the Android tools, an emulator and an Android system image. Either way it adds a virtual phone named **Home Assistant Test**, so your own virtual devices and apps are left alone (**Add Test Device…** when it's missing). **Add Emulator…** creates more.
- **GitHub account:** needed for test builds of the apps and the frontend. Use **Change Account** to sign in. There are two ways:
  - **Use an Access Token…** (easiest): click **Create a Token on GitHub**, keep the default settings (public repositories, read-only), click **Generate token**, copy it, and paste it into the app. It's stored in your Mac's keychain.
  - **GitHub CLI:** if you already use [`gh`](https://cli.github.com) and ran `gh auth login`, your accounts are listed in the menu. Pick one.

### Run

Turn on the parts you want with their switches, choose a version for each, then click **Run** (⌘R).

- **iOS app:** **Latest** is the newest build of the app's `main` branch, or paste a pull request number or link, such as `6142`. Choose the iOS version and the simulated device; one marked **(new)** is created for you. **Start fresh** removes the app and its data first.
- **Android app:** **Latest** is the newest build of the app's `main` branch (a release build), or paste a pull request number (a debug build). **Full** is the Play Store version, with Google services; **Minimal** is the version without them. Choose the virtual device; **Start fresh** removes the app and its data first. **Download APK** saves the APK to your Downloads folder instead, to install on a phone or anywhere else.
- **Core:** the latest release, the current beta, the `dev` branch, or a pull request. The first run downloads Python and Home Assistant, which takes a minute or two; later runs reuse them. **Start fresh** erases the server's data first, so you go through onboarding again.
- **Frontend:** the latest release, the `dev` branch, or a pull request. It replaces the frontend that comes with Core. With the frontend on and Core off, the latest release of Core runs with it.

When the server is up, the Run page shows its address:

- **On this Mac and in the iOS Simulator**, such as `http://localhost:8123`.
- **In the Android emulator**, such as `http://10.0.2.2:8123`. That's how the emulator reaches your Mac.
- **From a phone or another computer on the same network**, such as `http://192.168.1.20:8123`.

**Connect the iOS App** and **Connect the Android App** open the app's onboarding with the right address filled in.

The server is named *Simulator Test Server* followed by your Mac's name, so it never clashes with your real Home Assistant on the network. Port 8123 is used when it's free; otherwise the next free one. You can choose another port in the inspector.

**Run** only redoes what changed. Change just the frontend and the server restarts with it in a few seconds, without reinstalling Core or touching the iOS app. Change just the iOS build and the server keeps running. Turn a part off and click **Run** to stop it.

- **Stop** (⌘.) cancels a run in progress, or stops the server and quits the app in the simulator.
- **Take Screenshot**, **Record Screen** and **Android Screenshot** save to your Desktop. Click **Record Screen** again to stop recording. Attach these when you report what you found.
- Quitting the installer stops the server.

In the simulator, click to tap and click-and-drag to scroll.

### Adding devices

The **+** next to **Device** in the iOS and Android columns adds a simulator or an emulator, and it's selected right away:

- **iOS:** pick the iOS version, the iPhone or iPad model and a name. **Download Another iOS Version…** gets more versions.
- **Android:** pick a Pixel phone, foldable or tablet, an Android version from 9 to 17, and a name. A version you don't have yet is downloaded first (about 2 GB); you can follow along in the Android column.

### Recent

Every run is remembered in the sidebar under the date and time it ran, with an icon for each part it ran. Hover over one to see the versions, such as *iOS app #6142 · Core dev · Frontend #25000*. Click one to bring back those choices, then click **Run**. Right-click for **Run Again**, **Remove from Recent** and **Clear Recent**.

### Downloads

Everything the app keeps on your Mac, with its size: iOS and Android app builds, Core installs (about 1 GB each), frontend builds and the tools (uv, Python and Java). **Delete** frees the space; anything can be downloaded again. What the running server uses can't be deleted. Your server's data isn't listed here; erase it from the inspector's **Core** tab.

### Inspector

- **iOS app:** the installed build and device, screenshot and recording, connecting to the server, removing the app, and what the installer did.
- **Android app:** the installed build, package and emulator, downloading the APK, a screenshot, connecting to the server, removing the app, and what the installer did.
- **Core:** the version and addresses, the port, the server's data folder, **Erase Server Data…**, and the live server log (or the installer's own steps).
- **Frontend:** the build being served, where it's stored, and what the installer did.

## Troubleshooting

**macOS asks to let the installer use Bluetooth or find devices on your local network.** That's the Home Assistant server you started, which looks for devices like it does on a Home Assistant device. Either answer works; with **Don't Allow**, Bluetooth and network discovery integrations find nothing.

**Core fails to start.** Open the inspector's **Core** tab and look at the server log. **Start fresh** helps when a newer version left data an older one can't read.

**"Apple could not verify…" or "is damaged and can't be opened".** Run the `xattr` command from [Install](#install) again. It's needed each time you download the app yourself, but not for updates installed from inside the app.

**"The app couldn't replace itself".** The app needs permission to change the folder it's in. Move it to your Applications folder, or download the update from its release page and install it like the first time.

**"This build can't run in the Simulator".** The build was packaged without parts it needs and would crash on launch. This affects builds made before October 27, 2026, when the Home Assistant iOS project started preparing its simulator builds for use outside Xcode. Install **Latest version** instead. For a pull request, ask its author to push a new commit or update the branch: that makes a new build. Re-running the old checks doesn't help, because they rebuild the same code.

**"The checks for pull request … are still running" or "… failed".** The pull request's build isn't ready, or it didn't pass. Try again later, or ask the pull request's author.

**The app keeps asking for keychain access.** Click **Always Allow**. This happens because the app isn't signed by Apple.

**Something else.** Copy the red error message and [open an issue](https://github.com/bgoncal/home-assistant-ios-simulator-installer/issues).

## What the simulator can't do

The simulator stands in for most of the app, but not all of it. Notifications sent by your server may not arrive, sensors that need phone hardware (motion, steps, Bluetooth, NFC, battery) report placeholders, location is simulated (**Features > Location** in the simulator), and there's no Apple Watch app. Test those on a real iPhone through TestFlight.

## For developers

### How it works

- iOS builds come from the `ios-simulator` artifact of the [home-assistant/iOS CI workflow](https://github.com/home-assistant/iOS/actions/workflows/ci.yml): the latest successful run on `main`, or the run for a pull request's latest commit. Downloading artifacts requires a GitHub token even for public repositories.
- Android builds come from the [home-assistant/android CI](https://github.com/home-assistant/android/actions): the `release-apks` artifact of the latest successful push to `main`, or the `APKs` artifact of a pull request's latest commit. The phone APKs are installed with `adb`; the emulator is started with `emulator -avd`. A virtual device is created with `avdmanager`, using an Android SDK found in `ANDROID_HOME` or `~/Library/Android/sdk`, or one installed in `~/Library/Application Support/HASimulatorInstaller/Android SDK`.
- Core runs in a Python environment made with [uv](https://github.com/astral-sh/uv), which the app downloads with a matching Python into `~/Library/Caches/HASimulatorInstaller`. Releases and betas come from PyPI; `dev` and pull requests are installed from their source on GitHub, with translations generated the way Core's developers do. The server's data lives in `~/Library/Application Support/HASimulatorInstaller/Server`.
- Frontend builds come from the `frontend-build` artifact of the [home-assistant/frontend CI workflow](https://github.com/home-assistant/frontend/actions/workflows/ci.yaml) (kept by GitHub for 7 days) or from the wheel attached to its latest release, and are served through Core's `frontend: development_repo` option.
- Xcode versions come from [xcodereleases.com](https://xcodereleases.com) (14.3 and later), and iOS Simulator versions from Apple's simulator download index (iOS 16.4, the app's minimum, and later). iOS versions are installed with `xcodebuild -downloadPlatform iOS -buildVersion …` using the selected Xcode.
- Everything else uses `simctl` from the selected Xcode.

### GitHub sign-in with a code

Builds made with a GitHub OAuth App client ID also offer **Sign In with GitHub…**, GitHub's [device flow](https://docs.github.com/en/apps/oauth-apps/building-oauth-apps/authorizing-oauth-apps#device-flow): the app shows a short code, you approve it on github.com, and no token needs to be copied. To enable it, [register an OAuth App](https://github.com/settings/applications/new), tick **Enable Device Flow**, and pass its client ID when building. Only the public client ID ships in the app.

### Building

```bash
Scripts/build-app.sh
```

The app lands in `build/Home Assistant iOS Simulator Installer.app`, signed ad hoc. Optional environment variables:

- `GITHUB_CLIENT_ID`: OAuth App client ID for **Sign In with GitHub…**.
- `SIGN_IDENTITY` and `NOTARY_PROFILE`: a Developer ID signing identity and a `notarytool` keychain profile, to sign and notarize the app so it opens without the `xattr` step.
- `VERSION`: the version number, `0.5` by default.

During development you can also run it with `swift run`.
