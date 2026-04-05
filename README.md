# 🏃 HealthKit Demo — SwiftUI

A SwiftUI demo showing how to request HealthKit authorization, read today's step count, log water intake, and set up background delivery for live health data updates — using Apple's modern async/await HealthKit APIs.

---

## 🤔 What this is

This project walks through the full HealthKit integration pattern: requesting separate read and write permissions, querying step data with `HKStatisticsQueryDescriptor`, writing water intake samples, and enabling background delivery so your app wakes when new health data arrives. All wrapped in an `@Observable` class that drives a SwiftUI view.

## ✅ Why you'd use it

- **Complete auth flow** — explains *why* Apple hides read permission status and what the correct pattern is
- **Modern async HealthKit APIs** — uses `HKStatisticsQueryDescriptor`, not legacy callback-based queries
- **Background delivery setup** — observer query + `enableBackgroundDelivery` wired up with the correct completion handler pattern
- **Read + Write in one example** — step count read and water intake write, side by side
- **`@Observable` pattern** — Swift 5.9 observation macro, not the older `ObservableObject`

## 📺 From the NoahDoesCoding YouTube Channel

This project is a companion to a tutorial on [@NoahDoesCoding97](https://www.youtube.com/@NoahDoesCoding97). Subscribe for weekly SwiftUI tutorials.

---

## 🚀 Getting Started

### 1. Clone the Repo
```bash
git clone https://github.com/NDCSwift/HealthKitDemoSwiftUI.git
cd HealthKitDemoSwiftUI
```
Or select "Clone Git Repository…" when Xcode launches.

### 2. Open in Xcode
- Double-click `HealthKitDemoSwiftUI.xcodeproj`.

### 3. Add the HealthKit Capability
Go to **Target → Signing & Capabilities** and add **HealthKit**.

### 4. Set Your Development Team

In Xcode, navigate to: **TARGET → Signing & Capabilities → Team**
- Select your personal or organizational team.

### 5. Update the Bundle Identifier
- Change `com.example.MyApp` to a unique identifier.

### 6. Run on a Physical Device
HealthKit is not available on the Simulator or iPad.

---

## 🛠️ Notes

- HealthKit is **not available on iPad** — always guard with `HKHealthStore.isHealthDataAvailable()`
- Add `NSHealthShareUsageDescription` and `NSHealthUpdateUsageDescription` to your `Info.plist`
- Background delivery requires the HealthKit background modes entitlement
- If you see a code signing error, check that Team and Bundle ID are set

## 📦 Requirements

- Xcode 15+
- iOS 17+
- Real iPhone required (HealthKit not available in Simulator)

📺 [Watch the guide on YouTube](https://www.youtube.com/@NoahDoesCoding97)
