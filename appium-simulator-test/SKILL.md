---
name: appium-simulator-test
description: "iOS/Androidシミュレーター・エミュレーターでのAppiumテスト。自動アプリ検出、capabilities生成、テスト実行。シミュレーターテスト、Appium、e2eテスト等のキーワードで使用。"
---

# Appium Simulator Test

## Goal

Run end-to-end mobile app tests on iOS simulators (default) or Android emulators using appium-mcp, with automatic app discovery and capability updates.

## Workflow

1.  **Default Configuration (iOS)**
    *   **Platform:** iOS
    *   **Device:** iPhone 17
    *   **OS Version:** Latest available
    *   **Action:** Automatically proceed with these defaults. Do NOT ask the user unless these specific defaults are unavailable or fail.

2.  **Automatic App Path Discovery**
    *   Search for the `.app` file in the following locations (in order):
        1.  Current project's `build/` or `DerivedData` directories.
        2.  `/Users/yappa/Library/Developer/Xcode/DerivedData` (look for the most recently modified matching the project name).
    *   **Command:** Use `find` or `mdfind` to locate the `.app` bundle.
    *   **Condition:**
        *   If **one** valid `.app` is found: Use it automatically.
        *   If **multiple** are found: Use the most recently modified one.
        *   If **none** are found or the path is ambiguous: **ASK THE USER** for the path.

3.  **Verify appium-mcp Connection**
    *   Check if `appium-mcp` is connected.
    *   If not, guide the user to add it: `npx appium-mcp@latest`.
    *   Config path: `/Users/yappa/.appium-mcp/capabilities.json`.

4.  **Simulator Check & Capability Update**
    *   **Check:** Run `xcrun simctl list devices available` to confirm "iPhone 17" exists.
    *   **If iPhone 17 is missing:** **ASK THE USER** how to proceed (or fallback to the latest available iPhone).
    *   **Update Capabilities:**
        *   Use the script `scripts/update_capabilities.py` (or manual JSON edit) with:
            *   `platformName`: `iOS`
            *   `deviceName`: `iPhone 17`
            *   `platformVersion`: (Latest version found in `xcrun simctl list runtimes`)
            *   `app`: (The automatically found path)
            *   `automationName`: `XCUITest`

5.  **Execute via appium-mcp**
    *   Start the session.
    *   Perform the requested test steps.

6.  **Error Handling (User Interaction)**
    *   **Only ask the user if:**
        *   The app path cannot be found automatically.
        *   The simulator (iPhone 17) is not available.
        *   The test fails or exceptions occur that require human decision.
    *   Otherwise, proceed silently and report the final result.

## Notes

- **Silent by Default:** Do not confirm parameters with the user if they can be inferred.
- **iPhone 17 Priority:** Always try to use iPhone 17 first.
- **Latest OS:** Always use the highest version number available for the simulator.

## 他スキルとの連携

- **hig-ooui-mobile-design**: デザイン仕様に基づいたUIテスト
- **ios-development**: 実装後のe2eテスト
- **ios-cicd-pipeline**: CIパイプラインでテスト自動実行

