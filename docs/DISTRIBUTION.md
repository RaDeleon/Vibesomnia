# DMG installer and alpha testing

The owner approved public alpha development on 2026-11-07 while acceptance testing
continues. Packaging never changes visibility or publishes a release automatically.

## User experience

1. Open the versioned DMG and double-click **Install Vibesomnia.pkg**.
2. Read the welcome/license screens and authorize installation to Applications.
3. Open **Applications → Vibesomnia**. First-run setup detects AI apps, saves
   display/closed-lid/battery preferences, and offers a guided remote test.
4. Starting a closed-lid test asks for separate administrator authorization.
   Finish setup without testing if desired; reopen the guide at any time.

The installer copies only the app and creates a package receipt. It does not
change power settings, enable SSH, install a persistent service, launch scripts
as the logged-in user, or auto-start Vibesomnia. Preinstall refuses a running
Vibesomnia app/guard or a recovery record. End/recover and quit before updating.
The component is explicitly non-relocatable: installation targets Applications,
not a developer's existing build folder. Per-user preferences survive updates.

## Build a local test DMG

```sh
swift test
./script/package_dmg.sh --local
./script/verify_installer.py dist/installers/Vibesomnia-0.1.0-alpha.5-universal-local-unsigned.dmg
```

Output: `dist/installers/`, with a SHA-256 checksum next to the DMG. The package
contains arm64 and x86_64 slices for the app, CLI and power guard, targeting
macOS 14+. The local app is ad-hoc signed; the installer is unsigned and neither
is notarized. Do not advertise this as a normal Gatekeeper-ready download.

Packaging stages a fresh app in a temporary directory and leaves the running app
and its closed-lid session alone. `script/build_bundle.sh` owns bundle construction
and signing for both development and distribution. The normal Run script still
requests graceful app termination before replacing a development bundle.

To inspect setup without touching an active session, build to a separate path:

```sh
./script/build_bundle.sh "$PWD/work/preview/Vibesomnia.app" debug native
open -n "$PWD/work/preview/Vibesomnia.app" --args --setup-preview
```

Preview reads app availability but has no power actions, control IPC, add-ons or
preference writes. It cannot certify the actual installed first-launch behavior.

## Signed distribution

Prerequisites: Apple Developer membership, Developer ID Application **and**
Developer ID Installer certificates with private keys, and notarization credentials.

```sh
export VIBESOMNIA_SIGNING_IDENTITY='Developer ID Application: Your Name (TEAMID)'
export VIBESOMNIA_INSTALLER_IDENTITY='Developer ID Installer: Your Name (TEAMID)'
# Store credentials interactively using notarytool; never put passwords in source.
xcrun notarytool store-credentials vibesomnia-notary
export VIBESOMNIA_NOTARY_PROFILE=vibesomnia-notary
./script/package_dmg.sh --signed
```

Signing proceeds inside-out: helper, CLI, app with hardened runtime and the Apple
Events entitlement, installer, then DMG. Package and DMG are submitted for
notarization, stapled and validated. Actual signed distribution is unverified until
valid certificates and credentials are supplied; the local path does not fake it.

## GitHub Actions

`.github/workflows/installer.yml` is **manual only**. Select `local` for an unsigned
alpha or `signed` for Developer ID distribution. It runs tests, builds/validates
the DMG, and stores an Actions artifact for seven days. It has read-only
repository permissions and no release-publishing or visibility-changing step.
GitHub requires this dispatch workflow to exist on the default branch before it
can normally be launched from Actions. Main is not merged automatically.

For signed jobs, configure these repository secrets through GitHub:

- `DEVELOPER_ID_CERTIFICATES_P12`: base64 archive containing both identities/keys.
- `DEVELOPER_ID_CERTIFICATES_PASSWORD`: archive password.
- `DEVELOPER_ID_APPLICATION`, `DEVELOPER_ID_INSTALLER`: full identity names.
- `NOTARY_APPLE_ID`, `NOTARY_TEAM_ID`, `NOTARY_APP_PASSWORD`.

The job imports keys into a temporary runner keychain and deletes it afterward.
Do not commit certificates or credentials. Runner/storage use is subject
to repository visibility and the account's plan; no paid runner or billing setting is enabled by this code.

## Release gate

Follow docs/TESTING.md: clean installation, upgrade, first-run persistence,
permission denial, app discovery, sleep restoration, physical lid cycling and
real remote reconnection. Verify the downloaded signed artifact on clean Apple
silicon and Intel systems. The owner explicitly authorized the alpha.5 prerelease and public repository.
Further binary releases still require explicit approval; public availability
does not replace these acceptance checks. Provide corresponding
source for the exact binary version alongside any distributed release.

To uninstall, end/recover any session, quit Vibesomnia, then move the app to Trash.
Preferences and user-authored add-ons are retained; the installer never deletes them.
