# Apple TV download regression tests

Run from the repository root:

```sh
Resources/Scripts/test.apple-tv-support.sh
```

The runner copies the production `AppPackage.swift` into a temporary Swift package,
so these tests do not launch Asspp or access accounts and Keychain. They check
platform identity, persistence compatibility, explicit historical version selection,
and rejection of an iPhone IPA when an Apple TV package is expected.

To also verify public App Store version resolution for a universal iOS/tvOS app:

```sh
ASSPP_LIVE_STORE_TESTS=1 Resources/Scripts/test.apple-tv-support.sh
```

The optional live test uses public metadata and does not require an Apple ID.
Account authentication, license acquisition, and a complete signed IPA download
must be verified separately with an account that owns the app.
