# FlightFinder Release Guide

This project ships an unsigned local release bundle flow by default, with a path to signed/notarized distribution for public release.

## 1) Pre-release validation

Run functional verification before any release build:

```bash
xcodegen generate
xcodebuild -project FlightFinder.xcodeproj \
  -scheme FlightFinder \
  -destination 'platform=macOS' \
  -derivedDataPath .derivedData \
  test
```

Optional skill/browser checks:

```bash
./scripts/validate_with_skills.sh
```

## 2) Build unsigned release artifacts

Use the release bundler script:

```bash
./scripts/build_release_bundle.sh --clean
```

Outputs:

- `build/release/FlightFinder.app`
- `build/release/FlightFinder-macos-v<MARKETING_VERSION>-b<CURRENT_PROJECT_VERSION>-unsigned.zip`
- `build/release/FlightFinder-macos-v<MARKETING_VERSION>-b<CURRENT_PROJECT_VERSION>-unsigned.sha256`

Optional version override for artifact naming:

```bash
./scripts/build_release_bundle.sh --version 1.0.0
```

## 3) Sign for distribution (Developer ID)

Unsigned artifacts are suitable for internal testing. For external distribution, sign with Apple Developer ID:

```bash
codesign --deep --force --verify --verbose \
  --sign "Developer ID Application: YOUR_TEAM_NAME (TEAMID)" \
  build/release/FlightFinder.app
```

Validate signature:

```bash
codesign --verify --deep --strict --verbose=2 build/release/FlightFinder.app
spctl --assess --type execute --verbose build/release/FlightFinder.app
```

## 4) Notarize (recommended for external users)

Submit and staple:

```bash
xcrun notarytool submit build/release/FlightFinder-macos-vX.Y.Z-bN-unsigned.zip \
  --keychain-profile "AC_NOTARY_PROFILE" \
  --wait

xcrun stapler staple build/release/FlightFinder.app
```

Re-zip the stapled app for final distribution:

```bash
cd build/release
ditto -c -k --sequesterRsrc --keepParent FlightFinder.app FlightFinder-macos-vX.Y.Z-bN.zip
shasum -a 256 FlightFinder-macos-vX.Y.Z-bN.zip > FlightFinder-macos-vX.Y.Z-bN.sha256
```

