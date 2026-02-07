# Capabilities Templates (Simulators/Emulators)

Use these as starting points and keep them minimal.

## iOS Simulator (App Path)

```json
{
  "ios": {
    "platformName": "iOS",
    "appium:automationName": "XCUITest",
    "appium:deviceName": "iPhone 15",
    "appium:udid": "<SIM_UDID>",
    "appium:platformVersion": "<IOS_VERSION>",
    "appium:app": "/absolute/path/to/MyApp.app"
  }
}
```

## iOS Simulator (Bundle ID)

```json
{
  "ios": {
    "platformName": "iOS",
    "appium:automationName": "XCUITest",
    "appium:deviceName": "iPhone 15",
    "appium:udid": "<SIM_UDID>",
    "appium:platformVersion": "<IOS_VERSION>",
    "appium:bundleId": "com.example.myapp"
  }
}
```

## Android Emulator (APK Path)

```json
{
  "android": {
    "platformName": "Android",
    "appium:automationName": "UiAutomator2",
    "appium:deviceName": "<AVD_NAME>",
    "appium:udid": "<EMULATOR_SERIAL>",
    "appium:platformVersion": "<ANDROID_VERSION>",
    "appium:app": "/absolute/path/to/app.apk"
  }
}
```

## Android Emulator (Package/Activity)

```json
{
  "android": {
    "platformName": "Android",
    "appium:automationName": "UiAutomator2",
    "appium:deviceName": "<AVD_NAME>",
    "appium:udid": "<EMULATOR_SERIAL>",
    "appium:platformVersion": "<ANDROID_VERSION>",
    "appium:appPackage": "com.example.myapp",
    "appium:appActivity": ".MainActivity"
  }
}
```
