# iOS setup for Woosim printer

This project now includes an iOS native implementation using Flutter MethodChannel + Swift + CoreBluetooth BLE.

## Important compatibility note

iOS cannot connect to generic Bluetooth Classic/SPP printers in the same way Android can. The iOS implementation can print only when the printer exposes a BLE writable characteristic, or when the printer supports Apple MFi/ExternalAccessory with a vendor protocol.

The included Swift implementation supports the BLE path:

- Scan nearby BLE peripherals.
- Filter likely printers by names such as `Woosim`, `WSP`, `Printer`, `POS`, or `Thermal`.
- Connect to the selected peripheral.
- Discover a writable characteristic.
- Send ESC/POS 24-dot image data in BLE chunks.

If the printer does not appear on iPhone scan, it is probably Bluetooth Classic/SPP only or requires MFi protocol support.

## How to apply this folder

1. Create a clean Flutter project:

```bash
flutter create --org com.devlabs woosim_printer_flutter
```

2. Copy all files from this converted folder into the new Flutter project.

3. Make sure these iOS files exist:

```text
ios/Runner/AppDelegate.swift
ios/Runner/Printer/IOSPrinterChannelHandler.swift
ios/Runner/Printer/IOSBluetoothPrinterManager.swift
ios/Runner/Printer/IOSEscPos.swift
ios/Runner/Printer/IOSThermalImageConverter.swift
ios/Runner/Printer/IOSPrinterDevice.swift
ios/Runner/Printer/IOSPrinterResult.swift
ios/Runner/Info.plist
```

4. Open the iOS project in Xcode:

```bash
open ios/Runner.xcworkspace
```

5. Select a real iPhone device. Bluetooth printing will not work on iOS Simulator.

6. Run:

```bash
flutter pub get
flutter run
```

## Test flow

1. Turn on the Woosim printer.
2. Open the app on iPhone.
3. Go to the printer tab.
4. Tap **Scan printers**.
5. Select the printer.
6. Tap **Print Test** first.
7. Choose an image and tap **Print Photo**.

## When it still cannot print

If Scan does not show the printer, check whether your WSP-i450 model supports BLE or iOS/MFi. Some Woosim models support Android SPP only. In that case, Android will work but iOS cannot connect without a BLE/MFi-capable printer model or Woosim's iOS SDK/protocol.
