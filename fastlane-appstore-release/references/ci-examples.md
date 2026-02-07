# CI Examples

## GitHub Actions (minimal)
```yaml
name: iOS Release
on:
  workflow_dispatch:

jobs:
  release:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v4
      - uses: ruby/setup-ruby@v1
        with:
          ruby-version: "3.2"
      - name: Install Fastlane
        run: gem install fastlane
      - name: Select Xcode
        run: sudo xcode-select -s /Applications/Xcode.app
      - name: Run Fastlane
        env:
          ASC_KEY_ID: ${{ secrets.ASC_KEY_ID }}
          ASC_ISSUER_ID: ${{ secrets.ASC_ISSUER_ID }}
          ASC_KEY_FILEPATH: ${{ secrets.ASC_KEY_FILEPATH }}
          MATCH_GIT_URL: ${{ secrets.MATCH_GIT_URL }}
          MATCH_PASSWORD: ${{ secrets.MATCH_PASSWORD }}
        run: fastlane ios release
```

Notes:
- Store the .p8 file in a secure location and expose the path via `ASC_KEY_FILEPATH`.
- Set `MATCH_READONLY=true` in CI if you want strict readonly behavior.

## Bitrise (outline)
- Add a Script step before `Fastlane` to export env vars for API key and match.
- Use the built-in Fastlane step with lane: `ios release` or `macos release`.

## Xcode Cloud (outline)
- Add a Post-build script to call `bundle exec fastlane ios release`.
- Store API key and match secrets in Xcode Cloud environment variables.
