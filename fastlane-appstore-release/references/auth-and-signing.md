# Authentication and Signing

## App Store Connect API Key (preferred)
Use an App Store Connect API key instead of Apple ID password login. This is the default.

Checklist:
- Create a key in App Store Connect under Users and Access > Keys.
- Download the .p8 key file (only available once).
- Record the Key ID, Issuer ID, and Team ID.
- Store the .p8 file securely in CI secrets or a secure path.

Environment variables (example names):
- ASC_KEY_ID
- ASC_ISSUER_ID
- ASC_KEY_FILEPATH

Fastlane snippet:
```ruby
api_key = app_store_connect_api_key(
  key_id: ENV["ASC_KEY_ID"],
  issuer_id: ENV["ASC_ISSUER_ID"],
  key_filepath: ENV["ASC_KEY_FILEPATH"]
)
```

Pass api_key to upload actions:
```ruby
upload_to_testflight(api_key: api_key)
upload_to_app_store(api_key: api_key)
```

## Signing Options

### Option A: match (recommended default)
Use match to manage certificates and provisioning profiles. Prefer this for teams and CI.

Typical setup:
- Create a private git repo for match storage.
- Run match once locally to generate and store profiles.
- Use readonly mode on CI.

Common env vars:
- MATCH_GIT_URL
- MATCH_PASSWORD
- MATCH_READONLY=true (for CI)

If using match, add a Matchfile or inline match config in the Fastfile.

### Option B: Xcode Automatic Signing (fallback)
Use Xcode-managed signing only when match is not available.

Requirements:
- Correct team set in project settings.
- Automatic signing enabled for each target.

## macOS Notes
- App Store distribution for macOS uses the same API key flow.
- If using match, include platform :macos and type appstore.
