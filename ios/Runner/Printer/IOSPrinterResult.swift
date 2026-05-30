import Foundation

struct IOSPrinterResult {
  let success: Bool
  let error: String?

  static func ok() -> IOSPrinterResult {
    IOSPrinterResult(success: true, error: nil)
  }

  static func fail(_ message: String) -> IOSPrinterResult {
    IOSPrinterResult(success: false, error: message)
  }

  func toMap() -> [String: Any] {
    return [
      "success": success,
      "error": error as Any
    ]
  }
}
