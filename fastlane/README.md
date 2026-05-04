fastlane documentation
----

# Installation

Make sure you have the latest version of the Xcode command line tools installed:

```sh
xcode-select --install
```

For _fastlane_ installation instructions, see [Installing _fastlane_](https://docs.fastlane.tools/#installing-fastlane)

# Available Actions

## iOS

### ios asc_verify

```sh
[bundle exec] fastlane ios asc_verify
```

Verify App Store Connect API key (JWT): token + list apps + bundle ID lookup.

### ios asc_register_bundle_id

```sh
[bundle exec] fastlane ios asc_register_bundle_id
```

Register the iOS bundle identifier via Connect API (safe if it already exists).

### ios asc_build_appstore_ipa

```sh
[bundle exec] fastlane ios asc_build_appstore_ipa
```

Archive Release and export an App Store IPA (signing via Xcode Automatic).

### ios asc_upload_ipa

```sh
[bundle exec] fastlane ios asc_upload_ipa
```

Upload an existing IPA to TestFlight (API key). Set ipa: or IPA_PATH.

### ios asc_ship_testflight

```sh
[bundle exec] fastlane ios asc_ship_testflight
```

Build App Store IPA then upload to TestFlight. Optional skip_build:true ipa:path

----

This README.md is auto-generated and will be re-generated every time [_fastlane_](https://fastlane.tools) is run.

More information about _fastlane_ can be found on [fastlane.tools](https://fastlane.tools).

The documentation of _fastlane_ can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
