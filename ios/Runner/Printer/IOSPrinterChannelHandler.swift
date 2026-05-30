import Flutter
import Foundation

final class IOSPrinterChannelHandler {
  private let channel: FlutterMethodChannel
  private let manager = IOSBluetoothPrinterManager()

  init(messenger: FlutterBinaryMessenger) {
    channel = FlutterMethodChannel(name: "woosim_printer", binaryMessenger: messenger)
    channel.setMethodCallHandler(handle)
  }

  private func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "isBluetoothEnabled":
      result(manager.isBluetoothEnabled)

    case "isConnected":
      result(manager.isConnected)

    case "getBondedPrinters":
      manager.scanForPrinters { devices in
        result(devices.map { $0.toMap() })
      }

    case "connect":
      guard let args = call.arguments as? [String: Any],
            let address = args["address"] as? String else {
        result(IOSPrinterResult.fail("Missing printer address").toMap())
        return
      }
      manager.connect(address: address) { nativeResult in
        result(nativeResult.toMap())
      }

    case "disconnect":
      manager.disconnect()
      result(nil)

    case "printTestReceipt":
      manager.printTestReceipt { nativeResult in
        result(nativeResult.toMap())
      }

    case "printImage":
      guard let args = call.arguments as? [String: Any],
            let path = args["imagePath"] as? String else {
        result(IOSPrinterResult.fail("Missing image path").toMap())
        return
      }
      let paperWidth = args["paperWidth"] as? Int ?? 576
      manager.printImage(path: path, paperWidth: paperWidth) { nativeResult in
        result(nativeResult.toMap())
      }

    default:
      result(FlutterMethodNotImplemented)
    }
  }
}
