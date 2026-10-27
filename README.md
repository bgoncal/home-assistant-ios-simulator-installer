# Home Assistant iOS Simulator Installer

A Mac app that installs a test build of the [Home Assistant iOS app](https://github.com/home-assistant/iOS) in the iOS Simulator and opens it, so you can try the latest version or a pull request without building anything in Xcode.

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

## What you need

- A Mac with Apple silicon (M1 or newer) running macOS 14 or later.
- [Xcode](https://apps.apple.com/app/xcode/id497799835), free from the App Store. You never build anything with it: it's only needed because it contains the iOS Simulator. Plan for about 40 GB of free space.
- A free [GitHub](https://github.com/signup) account. GitHub only lets signed-in users download test builds.
- A Home Assistant server your Mac can reach.

## Using it

The window has three parts. Work through them top to bottom.

### Setup

Every row needs a green check before you can install.

- **Xcode:** if it's missing, **Get Xcode** opens it in the App Store. If you have several versions, pick one from the menu. **Other Versions…** downloads another one: it opens Apple's download page in your browser (sign in with your Apple Account if asked), waits for the download to finish in your Downloads folder, and installs it in Applications for you.
- **Xcode license:** shown only when Xcode was never opened. Click **Open Xcode**, agree to the license, then come back and click **Check Again**.
- **iOS Simulator:** shows the iOS versions you have. **Other Versions…** downloads another one (several gigabytes each). Turn on **Show betas** to see beta versions.
- **GitHub account:** use **Change Account** to sign in. There are two ways:
  - **Use an Access Token…** (easiest): click **Create a Token on GitHub**, keep the default settings (public repositories, read-only), click **Generate token**, copy it, and paste it into the app. It's stored in your Mac's keychain.
  - **GitHub CLI:** if you already use [`gh`](https://cli.github.com) and ran `gh auth login`, your accounts are listed in the menu. Pick one.

### What to test

- **Build:** **Latest version** is the newest build of the app's `main` branch. **A pull request** lets you paste a pull request number or link, such as `6142` or `https://github.com/home-assistant/iOS/pull/6142`.
- **iOS version** and **Device:** the simulated iPhone or iPad to use. A device marked **(new)** is created for you.
- **Start fresh:** removes the app and everything in it (servers, settings) before installing. Leave it off to keep your data between builds.

### Install & Open

Click **Install & Open**. The app finds the build, downloads it, starts the simulator, installs the app and opens it. The last three builds are kept, so installing one of them again is quick.

- **Stop** (⌘.) cancels an install in progress, or quits the app in the simulator once it's running.
- **Take Screenshot** and **Record Screen** save to your Desktop. Click **Record Screen** again to stop recording. Attach these when you report what you found.

In the simulator, click to tap and click-and-drag to scroll. Connect to your Home Assistant server just like on a real iPhone.

## Troubleshooting

**"Apple could not verify…" or "is damaged and can't be opened".** Run the `xattr` command from [Install](#install) again. It's needed again after every update.

**"This build can't run in the Simulator".** The build was packaged without parts it needs and would crash on launch. This affects builds made before the Home Assistant iOS project started preparing its simulator builds for use outside Xcode. Pick a newer build.

**"The checks for pull request … are still running" or "… failed".** The pull request's build isn't ready, or it didn't pass. Try again later, or ask the pull request's author.

**The app keeps asking for keychain access.** Click **Always Allow**. This happens because the app isn't signed by Apple.

**Something else.** Copy the red error message and [open an issue](https://github.com/bgoncal/home-assistant-ios-simulator-installer/issues).

## What the simulator can't do

The simulator stands in for most of the app, but not all of it. Notifications sent by your server may not arrive, sensors that need phone hardware (motion, steps, Bluetooth, NFC, battery) report placeholders, location is simulated (**Features > Location** in the simulator), and there's no Apple Watch app. Test those on a real iPhone through TestFlight.

## For developers

### How it works

- Builds come from the `ios-simulator` artifact of the [home-assistant/iOS CI workflow](https://github.com/home-assistant/iOS/actions/workflows/ci.yml): the latest successful run on `main`, or the run for a pull request's latest commit. Downloading artifacts requires a GitHub token even for public repositories.
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
- `VERSION`: the version number, `0.1` by default.

During development you can also run it with `swift run`.
