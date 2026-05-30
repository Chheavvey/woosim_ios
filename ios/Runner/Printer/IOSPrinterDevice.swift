import Foundation

struct IOSPrinterDevice {
  let name: String
  let address: String

  func toMap() -> [String: Any] {
    return [
      "name": name,
      "address": address
    ]
  }
}
