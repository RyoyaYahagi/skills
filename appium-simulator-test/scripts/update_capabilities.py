#!/usr/bin/env python3
import argparse
import json
from pathlib import Path


def load_json(path: Path):
    if not path.exists():
        return {}
    with path.open("r", encoding="utf-8") as f:
        return json.load(f)


def save_json(path: Path, data: dict):
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", encoding="utf-8") as f:
        json.dump(data, f, indent=2)
        f.write("\n")


def main():
    parser = argparse.ArgumentParser(description="Update appium-mcp capabilities.json for simulators/emulators")
    parser.add_argument("--capabilities", required=True, help="Path to capabilities.json")
    parser.add_argument("--platform", required=True, choices=["ios", "android"], help="Target platform")
    parser.add_argument("--udid", required=True, help="Device UDID/serial")
    parser.add_argument("--platform-version", required=False, default=None, help="OS version")

    parser.add_argument("--app", required=False, default=None, help="Absolute path to .app or .apk")
    parser.add_argument("--bundle-id", required=False, default=None, help="iOS bundleId")
    parser.add_argument("--app-package", required=False, default=None, help="Android appPackage")
    parser.add_argument("--app-activity", required=False, default=None, help="Android appActivity")

    parser.add_argument("--device-name", required=False, default=None, help="Human device name")

    args = parser.parse_args()

    path = Path(args.capabilities).expanduser()
    data = load_json(path)

    if args.platform == "ios":
        cap = {
            "platformName": "iOS",
            "appium:automationName": "XCUITest",
            "appium:udid": args.udid,
        }
        if args.device_name:
            cap["appium:deviceName"] = args.device_name
        if args.platform_version:
            cap["appium:platformVersion"] = args.platform_version
        if args.app:
            cap["appium:app"] = args.app
        if args.bundle_id:
            cap["appium:bundleId"] = args.bundle_id
        data["ios"] = cap

    else:
        cap = {
            "platformName": "Android",
            "appium:automationName": "UiAutomator2",
            "appium:udid": args.udid,
        }
        if args.device_name:
            cap["appium:deviceName"] = args.device_name
        if args.platform_version:
            cap["appium:platformVersion"] = args.platform_version
        if args.app:
            cap["appium:app"] = args.app
        if args.app_package:
            cap["appium:appPackage"] = args.app_package
        if args.app_activity:
            cap["appium:appActivity"] = args.app_activity
        data["android"] = cap

    save_json(path, data)
    print(f"Updated {path}")


if __name__ == "__main__":
    main()
