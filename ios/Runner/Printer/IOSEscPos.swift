import Foundation
import UIKit

enum IOSEscPos {
  static func initialize() -> Data { Data([0x1B, 0x40]) }
  static func alignCenter() -> Data { Data([0x1B, 0x61, 0x01]) }
  static func boldOn() -> Data { Data([0x1B, 0x45, 0x01]) }
  static func boldOff() -> Data { Data([0x1B, 0x45, 0x00]) }
  static func feed(_ lines: UInt8) -> Data { Data([0x1B, 0x64, lines]) }
  static func lineSpacing24() -> Data { Data([0x1B, 0x33, 24]) }
  static func defaultLineSpacing() -> Data { Data([0x1B, 0x32]) }

  static func text(_ value: String) -> Data {
    value.data(using: .utf8) ?? Data()
  }

  /// 24-dot double-density bit image mode: ESC * 33 nL nH ... LF.
  static func bitImage24(_ image: UIImage) -> Data {
    guard let bitmap = IOSThermalImageConverter.toBlackWhiteBitmap(image) else { return Data() }
    let width = bitmap.width
    let height = bitmap.height
    var output = Data()
    let widthL = UInt8(width & 0xFF)
    let widthH = UInt8((width >> 8) & 0xFF)

    var y = 0
    while y < height {
      output.append(contentsOf: [0x1B, 0x2A, 33, widthL, widthH])
      for x in 0..<width {
        for k in 0..<3 {
          var slice: UInt8 = 0
          for b in 0..<8 {
            let yy = y + k * 8 + b
            if yy >= height { continue }
            if bitmap.isBlack(x: x, y: yy) {
              slice |= UInt8(1 << (7 - b))
            }
          }
          output.append(slice)
        }
      }
      output.append(0x0A)
      y += 24
    }
    return output
  }
}
