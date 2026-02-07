---
name: fastlane-appstore-release
description: Automate iOS/iPadOS and macOS App Store and TestFlight releases with Fastlane. Use when setting up or maintaining fastlane/Appfile, Fastfile, or Matchfile, configuring App Store Connect API key auth, managing signing, automating version or build numbers, uploading builds, metadata, or screenshots, or integrating Fastlane into CI for App Store or TestFlight submissions.
---

# Fastlane App Store Release

## Overview
Automate App Store and TestFlight submissions for iOS/iPadOS and macOS using Fastlane lanes, App Store Connect API keys, match-based signing, and repeatable CI-safe configuration.

## Workflow
1. Collect required inputs.
2. Choose authentication and signing approach.
3. Create or update Fastlane configuration.
4. Implement lanes for TestFlight and App Store per platform.
5. Wire version and build number policy.
6. Run and validate lanes locally, then document CI requirements.

## Defaults (Recommended)
- Use App Store Connect API key auth.
- Use match for signing and set CI to readonly mode.
- Provide CI examples for at least one provider if the user mentions CI, otherwise include a minimal GitHub Actions template by default.

## Required Inputs
- Xcode project or workspace path, and schemes per platform.
- Bundle IDs per app target.
- Apple Developer Team ID and App Store Connect Team ID (if different).
- App Store Connect app record status (exists or needs creation).
- Release scope for metadata, screenshots, and auto-submit behavior.
- Version and build number policy and source of truth.
- CI provider and secrets management approach.

## Authentication and Signing
- Default to App Store Connect API key auth and avoid Apple ID password login.
- Default to match-based signing; fall back to Xcode automatic signing only when match is not possible.
- Load references/auth-and-signing.md for exact setup steps and environment variables.

## Implementation Steps
1. Inspect the repo and map schemes to platforms. Prefer using .xcworkspace when present.
2. Initialize Fastlane if missing, then create fastlane/Appfile and fastlane/Fastfile.
3. Configure App Store Connect API key auth and signing using references/auth-and-signing.md.
4. Implement lanes for each platform, using ios:beta, ios:release, macos:beta, macos:release. Use build_app with export_method "app-store", upload_to_testflight for beta, and upload_to_app_store for release. Pass api_key when API key auth is used.
5. Add version and build number updates if required by the project policy.
6. Validate locally and capture CI requirements and environment variables. Load references/ci-examples.md for provider templates.

## Outputs
- fastlane/Appfile
- fastlane/Fastfile
- fastlane/Matchfile when match is used
- .env or CI secrets mapping for App Store Connect API key and signing

## 他スキルとの連携

- **ios-cicd-pipeline**: CIワークフローからFastlaneレーンを呼び出す
- **ios-development**: 実装完了後、本スキルでリリース自動化

## References
- references/auth-and-signing.md
- references/ci-examples.md
- references/fastlane-templates.md

