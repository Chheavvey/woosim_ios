# Woosim Printer Flutter Conversion

This is a Flutter conversion of the Android Kotlin/Jetpack Compose Woosim WSP-i450 80mm photo printer app.

## What was converted

- Compose Home/Printers/History tabs -> Flutter Material 3 UI.
- Android image picker -> Flutter `image_picker`.
- Runtime permissions -> Flutter `permission_handler`.
- Bluetooth SPP printer connection -> Android native MethodChannel.
- Woosim ESC/POS 24-dot image printing -> Android native Kotlin.
- 80mm paper width -> 576 pixels.
- Floyd-Steinberg dithering -> retained in native Kotlin.

## Class/function split

### Flutter / Dart

```text
lib/
├─ main.dart                              # App entry point only
├─ app/
│  └─ woosim_printer_app.dart             # MaterialApp, theme, root screen
├─ controllers/
│  └─ printer_controller.dart             # UI state + business flow orchestration
├─ models/
│  ├─ printer_device.dart                 # Bluetooth printer model
│  ├─ printer_operation_result.dart       # Native operation result model
│  └─ print_history_item.dart             # Print history model
├─ services/
│  ├─ woosim_printer_service.dart         # Flutter MethodChannel API wrapper
│  ├─ permission_service.dart             # Android runtime permission handling
│  └─ image_picker_service.dart           # Gallery image picker wrapper
├─ screens/
│  ├─ printer_home_page.dart              # Scaffold + tabs + navigation
│  ├─ home_tab.dart                       # Select photo / print / status UI
│  ├─ printers_tab.dart                   # Paired printer list + connect UI
│  └─ history_tab.dart                    # Print history UI
├─ widgets/
│  └─ status_pill.dart                    # Reusable small status chip
└─ utils/
   └─ date_formatter.dart                 # Date/time formatting helper
```

### Android native / Kotlin

```text
android/app/src/main/kotlin/com/devlabs/woosim_printer_flutter/
├─ MainActivity.kt                        # Registers MethodChannel only
└─ printer/
   ├─ PrinterChannelHandler.kt            # Handles Flutter MethodChannel calls
   ├─ BluetoothPrinterManager.kt          # Bluetooth SPP connect/print operations
   ├─ PrinterDevice.kt                    # Native printer model
   ├─ NativePrinterResult.kt              # Native operation result model
   ├─ EscPos.kt                           # ESC/POS byte command builder
   └─ ThermalImageConverter.kt            # Resize + grayscale + dithering for 80mm print
```

## How to use these files

1. Create a new Flutter project:

```bash
flutter create --org com.devlabs woosim_printer_flutter
cd woosim_printer_flutter
```

2. Copy these converted files into your Flutter project root. Let them replace the generated files where paths match.

3. Open `android/app/build.gradle.kts` and set:

```kotlin
minSdk = 28
namespace = "com.devlabs.woosim_printer_flutter"
```

Also make sure `applicationId` is:

```kotlin
applicationId = "com.devlabs.woosim_printer_flutter"
```

4. Install dependencies:

```bash
flutter pub get
```

5. Run on Android device:

```bash
flutter run
```

## Important

Pair your Woosim WSP-i450 printer in Android Bluetooth settings first. The app reads paired devices, connects using Bluetooth SPP, then prints.

This conversion is Android-focused because the original printer logic uses Android Bluetooth sockets directly.

## iOS BLE printer support added

This version includes Swift native iOS support under `ios/Runner/Printer`.

The iOS side uses CoreBluetooth BLE and the same Flutter MethodChannel name: `woosim_printer`. It supports:

- Scan nearby BLE printers
- Connect to a writable BLE characteristic
- Print test receipt
- Print selected image using ESC/POS 24-dot image mode

Important: iOS does not support generic Bluetooth Classic/SPP printer connection like Android. The included iOS code works only if the Woosim printer exposes BLE write characteristics. See `docs/IOS_SETUP.md`.
