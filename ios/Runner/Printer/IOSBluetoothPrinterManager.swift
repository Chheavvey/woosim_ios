import Foundation
import CoreBluetooth
import UIKit

final class IOSBluetoothPrinterManager: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate {
  private var central: CBCentralManager!
  private var discovered: [UUID: CBPeripheral] = [:]
  private var discoveredNames: [UUID: String] = [:]

  private var connectedPeripheral: CBPeripheral?
  private var writeCharacteristic: CBCharacteristic?
  private var connectCompletion: ((IOSPrinterResult) -> Void)?
  private var scanCompletion: (([IOSPrinterDevice]) -> Void)?
  private var scanTimer: Timer?

  private var writeQueue: [Data] = []
  private var writeCompletion: ((IOSPrinterResult) -> Void)?
  private var isWriting = false

  override init() {
    super.init()
    central = CBCentralManager(delegate: self, queue: DispatchQueue.main)
  }

  var isBluetoothEnabled: Bool {
    central.state == .poweredOn
  }

  var isConnected: Bool {
    connectedPeripheral != nil && writeCharacteristic != nil
  }

  func scanForPrinters(completion: @escaping ([IOSPrinterDevice]) -> Void) {
    scanCompletion = completion
    discovered.removeAll()
    discoveredNames.removeAll()

    guard central.state == .poweredOn else {
      completion([])
      return
    }

    central.stopScan()
    central.scanForPeripherals(withServices: nil, options: [CBCentralManagerScanOptionAllowDuplicatesKey: false])

    scanTimer?.invalidate()
    scanTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: false) { [weak self] _ in
      guard let self else { return }
      self.central.stopScan()
      let devices = self.discovered.map { id, peripheral in
        IOSPrinterDevice(name: self.discoveredNames[id] ?? peripheral.name ?? "Bluetooth Printer", address: id.uuidString)
      }.sorted { $0.name.lowercased() < $1.name.lowercased() }
      self.scanCompletion?(devices)
      self.scanCompletion = nil
    }
  }

  func connect(address: String, completion: @escaping (IOSPrinterResult) -> Void) {
    guard central.state == .poweredOn else {
      completion(.fail("Bluetooth is turned off on iPhone"))
      return
    }

    guard let uuid = UUID(uuidString: address) else {
      completion(.fail("Invalid iOS BLE device identifier"))
      return
    }

    let peripheral: CBPeripheral?
    if let known = discovered[uuid] {
      peripheral = known
    } else {
      peripheral = central.retrievePeripherals(withIdentifiers: [uuid]).first
    }

    guard let target = peripheral else {
      completion(.fail("Printer not found. Press Refresh and keep the printer nearby."))
      return
    }

    disconnect()
    connectCompletion = completion
    connectedPeripheral = target
    target.delegate = self
    central.connect(target, options: nil)
  }

  func disconnect() {
    if let peripheral = connectedPeripheral {
      central.cancelPeripheralConnection(peripheral)
    }
    connectedPeripheral = nil
    writeCharacteristic = nil
    connectCompletion = nil
    writeQueue.removeAll()
    writeCompletion = nil
    isWriting = false
  }

  func printTestReceipt(completion: @escaping (IOSPrinterResult) -> Void) {
    var data = Data()
    data.append(IOSEscPos.initialize())
    data.append(IOSEscPos.alignCenter())
    data.append(IOSEscPos.boldOn())
    data.append(IOSEscPos.text("PHOTO PRINTER\n"))
    data.append(IOSEscPos.boldOff())
    data.append(IOSEscPos.text("80mm iOS BLE test page\n\n"))
    data.append(IOSEscPos.feed(3))
    write(data, completion: completion)
  }

  func printImage(path: String, paperWidth: Int, completion: @escaping (IOSPrinterResult) -> Void) {
    guard let image = UIImage(contentsOfFile: path) else {
      completion(.fail("Unable to load selected image on iOS"))
      return
    }

    IOSThermalImageConverter.paperWidth = paperWidth
    var data = Data()
    data.append(IOSEscPos.initialize())
    data.append(IOSEscPos.alignCenter())
    data.append(IOSEscPos.lineSpacing24())
    data.append(IOSEscPos.bitImage24(image))
    data.append(IOSEscPos.defaultLineSpacing())
    data.append(IOSEscPos.feed(4))
    write(data, completion: completion)
  }

  private func write(_ data: Data, completion: @escaping (IOSPrinterResult) -> Void) {
    guard let peripheral = connectedPeripheral, let characteristic = writeCharacteristic else {
      completion(.fail("Printer is not connected"))
      return
    }

    let maxLength = max(20, peripheral.maximumWriteValueLength(for: .withoutResponse))
    var chunks: [Data] = []
    var offset = 0
    while offset < data.count {
      let length = min(maxLength, data.count - offset)
      chunks.append(data.subdata(in: offset..<(offset + length)))
      offset += length
    }

    writeQueue = chunks
    writeCompletion = completion
    isWriting = false
    writeNextChunk()
  }

  private func writeNextChunk() {
    guard !isWriting else { return }
    guard let peripheral = connectedPeripheral, let characteristic = writeCharacteristic else {
      writeCompletion?(.fail("Printer disconnected during print"))
      clearWriteState()
      return
    }

    guard !writeQueue.isEmpty else {
      writeCompletion?(.ok())
      clearWriteState()
      return
    }

    let chunk = writeQueue.removeFirst()
    let useWithoutResponse = characteristic.properties.contains(.writeWithoutResponse)
    let writeType: CBCharacteristicWriteType = useWithoutResponse ? .withoutResponse : .withResponse

    isWriting = !useWithoutResponse
    peripheral.writeValue(chunk, for: characteristic, type: writeType)

    if useWithoutResponse {
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.012) { [weak self] in
        self?.writeNextChunk()
      }
    }
  }

  private func clearWriteState() {
    writeQueue.removeAll()
    writeCompletion = nil
    isWriting = false
  }

  func centralManagerDidUpdateState(_ central: CBCentralManager) {
    if central.state != .poweredOn {
      scanCompletion?([])
      scanCompletion = nil
      connectCompletion?(.fail("Bluetooth is not powered on"))
      connectCompletion = nil
    }
  }

  func centralManager(
    _ central: CBCentralManager,
    didDiscover peripheral: CBPeripheral,
    advertisementData: [String: Any],
    rssi RSSI: NSNumber
  ) {
    let advertisedName = advertisementData[CBAdvertisementDataLocalNameKey] as? String
    let name = advertisedName ?? peripheral.name ?? "Bluetooth Printer"
    let lower = name.lowercased()
    let looksLikePrinter = lower.contains("woosim") || lower.contains("wsp") || lower.contains("printer") || lower.contains("pos") || lower.contains("thermal")

    // Keep likely printers first. If the printer hides its name, keep it too so the user can still try connecting.
    if looksLikePrinter || advertisedName == nil || peripheral.name == nil {
      discovered[peripheral.identifier] = peripheral
      discoveredNames[peripheral.identifier] = name
    }
  }

  func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
    peripheral.delegate = self
    peripheral.discoverServices(nil)
  }

  func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
    let message = error?.localizedDescription ?? "Unable to connect to iOS BLE printer"
    connectCompletion?(.fail(message))
    connectCompletion = nil
  }

  func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
    if connectedPeripheral?.identifier == peripheral.identifier {
      connectedPeripheral = nil
      writeCharacteristic = nil
    }
  }

  func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
    if let error {
      connectCompletion?(.fail(error.localizedDescription))
      connectCompletion = nil
      return
    }

    for service in peripheral.services ?? [] {
      peripheral.discoverCharacteristics(nil, for: service)
    }
  }

  func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
    if let error {
      connectCompletion?(.fail(error.localizedDescription))
      connectCompletion = nil
      return
    }

    guard writeCharacteristic == nil else { return }

    if let characteristic = service.characteristics?.first(where: {
      $0.properties.contains(.writeWithoutResponse) || $0.properties.contains(.write)
    }) {
      writeCharacteristic = characteristic
      connectCompletion?(.ok())
      connectCompletion = nil
    }
  }

  func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
    isWriting = false
    if let error {
      writeCompletion?(.fail(error.localizedDescription))
      clearWriteState()
      return
    }
    writeNextChunk()
  }
}
