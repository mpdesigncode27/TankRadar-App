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

----

This README.md is auto-generated and will be re-generated every time [_fastlane_](https://fastlane.tools) is run.

More information about _fastlane_ can be found on [fastlane.tools](https://fastlane.tools).

The documentation of _fastlane_ can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
