# SpinFood — Upcoming Features

All items below have been implemented. Notes call out remaining setup / device testing.

## 1. Home Screen Widget (WidgetKit) ✅

**Implemented**:
- `SpinFoodWidgetExtension` target with small / medium / large families
- App Group `group.giusscos.SpinFood` shared between app + widget
- App writes a `WidgetSnapshot` (pantry alerts, today's meals, quick-cook suggestion) and reloads timelines
- Widget reads the snapshot from shared `UserDefaults`

**Setup still needed on your Apple Developer account**:
- Enable App Groups for both App ID and Widget App ID (`group.giusscos.SpinFood`)
- Run on device/simulator, long-press Home Screen → Add Widget → Foo

---

## 2. iCloud Sync (CloudKit + SwiftData) ✅

**Implemented**:
- `ModelConfiguration` uses `cloudKitDatabase: .private("iCloud.giusscos.SpinFood")`
- Falls back to a local store if CloudKit is unavailable (no iCloud account / some simulators)

**Setup / testing**:
- Requires a real Apple ID with iCloud enabled and a proper provisioning profile
- Best tested on two devices (or two simulators) signed into the same Apple ID

---

## 3. Per-Step Cook Timer ✅

**Implemented**:
- `StepRecipe.suggestedDuration` with an “Auto-start timer” editor on each step
- Persistent floating timer banner during cooking (survives page turns)
- Step timer blocks promote into the floating banner when started
- Local notification via `UNTimeIntervalNotificationTrigger` when the timer completes

---

## 4. Barcode Scanner ✅

**Implemented**:
- `BarcodeScannerView` (AVFoundation, EAN-8/13, UPC-E, Code 128)
- Open Food Facts lookup with local barcode cache
- Scan entry points from Inventory toolbar and Add Food form
- Auto-fills name / category / unit / emoji for review before saving
- Updated `NSCameraUsageDescription`

**Testing**: requires a real device (simulator has no camera)
