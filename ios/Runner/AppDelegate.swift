import UIKit
import Flutter
import CoreBluetooth

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  private var woosimPrinterPlugin: WoosimPrinterPlugin?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    if let controller = window?.rootViewController as? FlutterViewController {
      woosimPrinterPlugin = WoosimPrinterPlugin(binaryMessenger: controller.binaryMessenger)
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}

private final class WoosimPrinterPlugin: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate {
  private let channel: FlutterMethodChannel
  private var centralManager: CBCentralManager!

  private var discoveredPrinters: [UUID: CBPeripheral] = [:]
  private var connectedPeripheral: CBPeripheral?
  private var writableCharacteristic: CBCharacteristic?

  private var scanResult: FlutterResult?
  private var connectResult: FlutterResult?

  init(binaryMessenger: FlutterBinaryMessenger) {
    channel = FlutterMethodChannel(name: "woosim_printer", binaryMessenger: binaryMessenger)
    super.init()
    centralManager = CBCentralManager(delegate: self, queue: .main)
    channel.setMethodCallHandler(handle)
  }

  private func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "isBluetoothEnabled":
      result(centralManager.state == .poweredOn)

    case "isConnected":
      result(connectedPeripheral?.state == .connected && writableCharacteristic != nil)

    case "getBondedPrinters":
      scanForPrinters(result: result)

    case "connect":
      guard let args = call.arguments as? [String: Any],
            let address = args["address"] as? String else {
        result(["success": false, "error": "Missing printer address"])
        return
      }
      connect(address: address, result: result)

    case "disconnect":
      disconnect()
      result(nil)

    case "printTestReceipt":
      printTestReceipt(result: result)

    case "printImage":
      guard let args = call.arguments as? [String: Any],
            let imagePath = args["imagePath"] as? String else {
        result(["success": false, "error": "Missing image path"])
        return
      }
      let paperWidth = args["paperWidth"] as? Int ?? 576
      printImage(imagePath: imagePath, paperWidth: paperWidth, result: result)

    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func scanForPrinters(result: @escaping FlutterResult) {
    guard centralManager.state == .poweredOn else {
      result([])
      return
    }

    scanResult = result
    discoveredPrinters.removeAll()
    centralManager.scanForPeripherals(withServices: nil, options: [
      CBCentralManagerScanOptionAllowDuplicatesKey: false
    ])

    DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) { [weak self] in
      guard let self = self else { return }

      self.centralManager.stopScan()

      let printers = self.discoveredPrinters.values
        .sorted { ($0.name ?? "") < ($1.name ?? "") }
        .map { peripheral in
          [
            "name": peripheral.name ?? "Unknown BLE Printer",
            "address": peripheral.identifier.uuidString
          ]
        }

      self.scanResult?(printers)
      self.scanResult = nil
    }
  }

  private func connect(address: String, result: @escaping FlutterResult) {
    guard centralManager.state == .poweredOn else {
      result(["success": false, "error": "Bluetooth is turned off"])
      return
    }

    guard let uuid = UUID(uuidString: address) else {
      result(["success": false, "error": "Invalid printer address"])
      return
    }

    let peripheral = discoveredPrinters[uuid] ??
      centralManager.retrievePeripherals(withIdentifiers: [uuid]).first

    guard let printer = peripheral else {
      result(["success": false, "error": "Printer not found. Tap Refresh and try again."])
      return
    }

    connectResult = result
    writableCharacteristic = nil
    connectedPeripheral = printer
    printer.delegate = self
    centralManager.connect(printer, options: nil)
  }

  private func disconnect() {
    if let peripheral = connectedPeripheral {
      centralManager.cancelPeripheralConnection(peripheral)
    }

    connectedPeripheral = nil
    writableCharacteristic = nil
  }

  private func printTestReceipt(result: @escaping FlutterResult) {
    let text = "\nWOOSIM TEST PRINT\nBluetooth iOS Connected\n------------------------\nDate: \(Date())\n\n\n"

    var data = Data()
    data.append(contentsOf: [0x1B, 0x40])
    data.append(text.data(using: .utf8) ?? Data())
    data.append(contentsOf: [0x1D, 0x56, 0x42, 0x00])

    write(data: data, result: result)
  }

  private func printImage(imagePath: String, paperWidth: Int, result: @escaping FlutterResult) {
    guard let image = UIImage(contentsOfFile: imagePath) else {
      result(["success": false, "error": "Cannot load selected image"])
      return
    }

    guard let raster = escPosRasterData(from: image, paperWidth: paperWidth) else {
      result(["success": false, "error": "Cannot convert image for printing"])
      return
    }

    var data = Data()
    data.append(contentsOf: [0x1B, 0x40])
    data.append(raster)
    data.append(contentsOf: [0x0A, 0x0A, 0x0A])

    write(data: data, result: result)
  }

  private func write(data: Data, result: @escaping FlutterResult) {
    guard let peripheral = connectedPeripheral,
          peripheral.state == .connected,
          let characteristic = writableCharacteristic else {
      result(["success": false, "error": "Printer not connected"])
      return
    }

    let writeType: CBCharacteristicWriteType =
      characteristic.properties.contains(.write) ? .withResponse : .withoutResponse

    let maxLength = max(20, peripheral.maximumWriteValueLength(for: writeType))
    var offset = 0

    while offset < data.count {
      let chunkSize = min(maxLength, data.count - offset)
      let chunk = data.subdata(in: offset..<(offset + chunkSize))
      peripheral.writeValue(chunk, for: characteristic, type: writeType)
      offset += chunkSize
      Thread.sleep(forTimeInterval: 0.015)
    }

    result(["success": true])
  }

  private func escPosRasterData(from image: UIImage, paperWidth: Int) -> Data? {
    let width = max(8, paperWidth - (paperWidth % 8))
    let scale = CGFloat(width) / max(image.size.width, 1)
    let height = max(1, Int(image.size.height * scale))
    let size = CGSize(width: width, height: height)

    UIGraphicsBeginImageContextWithOptions(size, true, 1.0)
    UIColor.white.setFill()
    UIRectFill(CGRect(origin: .zero, size: size))
    image.draw(in: CGRect(origin: .zero, size: size))
    let resized = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()

    guard let cgImage = resized?.cgImage else { return nil }

    let bytesPerPixel = 4
    let bytesPerRow = width * bytesPerPixel
    var pixels = [UInt8](repeating: 0, count: height * bytesPerRow)

    guard let context = CGContext(
      data: &pixels,
      width: width,
      height: height,
      bitsPerComponent: 8,
      bytesPerRow: bytesPerRow,
      space: CGColorSpaceCreateDeviceRGB(),
      bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
    ) else {
      return nil
    }

    context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))

    let widthBytes = width / 8
    var raster = Data()

    raster.append(contentsOf: [0x1D, 0x76, 0x30, 0x00])
    raster.append(UInt8(widthBytes & 0xFF))
    raster.append(UInt8((widthBytes >> 8) & 0xFF))
    raster.append(UInt8(height & 0xFF))
    raster.append(UInt8((height >> 8) & 0xFF))

    for y in 0..<height {
      for xByte in 0..<widthBytes {
        var byte: UInt8 = 0

        for bit in 0..<8 {
          let x = xByte * 8 + bit
          let index = y * bytesPerRow + x * bytesPerPixel

          let red = Int(pixels[index])
          let green = Int(pixels[index + 1])
          let blue = Int(pixels[index + 2])
          let luminance = (red * 299 + green * 587 + blue * 114) / 1000

          if luminance < 160 {
            byte |= UInt8(0x80 >> bit)
          }
        }

        raster.append(byte)
      }
    }

    return raster
  }

  func centralManagerDidUpdateState(_ central: CBCentralManager) {
    if central.state != .poweredOn {
      scanResult?([])
      scanResult = nil

      connectResult?(["success": false, "error": "Bluetooth is turned off"])
      connectResult = nil
    }
  }

  func centralManager(
    _ central: CBCentralManager,
    didDiscover peripheral: CBPeripheral,
    advertisementData: [String : Any],
    rssi RSSI: NSNumber
  ) {
    let name = peripheral.name ??
      advertisementData[CBAdvertisementDataLocalNameKey] as? String ??
      ""

    let lowerName = name.lowercased()

    if lowerName.contains("woosim") ||
        lowerName.contains("printer") ||
        lowerName.contains("wsp") ||
        !name.isEmpty {
      discoveredPrinters[peripheral.identifier] = peripheral
    }
  }

  func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
    connectedPeripheral = peripheral
    peripheral.delegate = self
    peripheral.discoverServices(nil)
  }

  func centralManager(
    _ central: CBCentralManager,
    didFailToConnect peripheral: CBPeripheral,
    error: Error?
  ) {
    connectResult?(["success": false, "error": error?.localizedDescription ?? "Connection failed"])
    connectResult = nil
  }

  func centralManager(
    _ central: CBCentralManager,
    didDisconnectPeripheral peripheral: CBPeripheral,
    error: Error?
  ) {
    if connectedPeripheral?.identifier == peripheral.identifier {
      connectedPeripheral = nil
      writableCharacteristic = nil
    }
  }

  func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
    if let error = error {
      connectResult?(["success": false, "error": error.localizedDescription])
      connectResult = nil
      return
    }

    peripheral.services?.forEach { service in
      peripheral.discoverCharacteristics(nil, for: service)
    }
  }

  func peripheral(
    _ peripheral: CBPeripheral,
    didDiscoverCharacteristicsFor service: CBService,
    error: Error?
  ) {
    if let error = error {
      connectResult?(["success": false, "error": error.localizedDescription])
      connectResult = nil
      return
    }

    guard writableCharacteristic == nil else { return }

    if let characteristic = service.characteristics?.first(where: {
      $0.properties.contains(.write) || $0.properties.contains(.writeWithoutResponse)
    }) {
      writableCharacteristic = characteristic
      connectResult?(["success": true])
      connectResult = nil
    }
  }
}