# Fastlane Templates

## Appfile (example)
```ruby
app_identifier("com.example.app")
apple_id("dev@example.com")
team_id("TEAMID")
itc_team_id("123456789")
```

## Fastfile (example)
```ruby
def api_key
  app_store_connect_api_key(
    key_id: ENV["ASC_KEY_ID"],
    issuer_id: ENV["ASC_ISSUER_ID"],
    key_filepath: ENV["ASC_KEY_FILEPATH"]
  )
end

platform :ios do
  desc "Upload iOS build to TestFlight"
  lane :beta do
    setup_ci if ENV["CI"]
    match(type: "appstore", readonly: true) if ENV["CI"]
    match(type: "appstore") unless ENV["CI"]
    build_app(
      scheme: "App",
      export_method: "app-store"
    )
    upload_to_testflight(api_key: api_key)
  end

  desc "Release iOS build to App Store"
  lane :release do
    setup_ci if ENV["CI"]
    match(type: "appstore", readonly: true) if ENV["CI"]
    match(type: "appstore") unless ENV["CI"]
    build_app(
      scheme: "App",
      export_method: "app-store"
    )
    upload_to_app_store(
      api_key: api_key,
      submit_for_review: true
    )
  end
end

platform :macos do
  desc "Upload macOS build to TestFlight"
  lane :beta do
    setup_ci if ENV["CI"]
    match(type: "appstore", readonly: true) if ENV["CI"]
    match(type: "appstore") unless ENV["CI"]
    build_app(
      scheme: "MacApp",
      export_method: "app-store"
    )
    upload_to_testflight(api_key: api_key)
  end

  desc "Release macOS build to App Store"
  lane :release do
    setup_ci if ENV["CI"]
    match(type: "appstore", readonly: true) if ENV["CI"]
    match(type: "appstore") unless ENV["CI"]
    build_app(
      scheme: "MacApp",
      export_method: "app-store"
    )
    upload_to_app_store(
      api_key: api_key,
      submit_for_review: true
    )
  end
end
```

## Matchfile (optional)
```ruby
git_url("git@github.com:org/fastlane-certs.git")
storage_mode("git")
team_id("TEAMID")
```

## .env (example)
```dotenv
ASC_KEY_ID=XXXXXXXXXX
ASC_ISSUER_ID=YYYYYYYY-YYYY-YYYY-YYYY-YYYYYYYYYYYY
ASC_KEY_FILEPATH=fastlane/AuthKey_XXXXXXXXXX.p8
MATCH_PASSWORD=change-me
```

## Version and Build Number Notes
- Use increment_build_number or increment_version_number when needed.
- In CI, consider setting build number from the CI run number.
