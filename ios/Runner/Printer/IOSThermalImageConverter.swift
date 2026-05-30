import Foundation
import UIKit

struct IOSMonoBitmap {
  let width: Int
  let height: Int
  let pixels: [UInt8] // 0 = black, 255 = white

  func isBlack(x: Int, y: Int) -> Bool {
    pixels[y * width + x] == 0
  }
}

enum IOSThermalImageConverter {
  static var paperWidth: Int = 576

  static func toBlackWhiteBitmap(_ source: UIImage) -> IOSMonoBitmap? {
    let normalized = normalize(source)
    let targetWidth = max(8, min(paperWidth, 576) - (min(paperWidth, 576) % 8))
    let ratio = CGFloat(targetWidth) / max(normalized.size.width, 1)
    let targetHeight = max(Int(normalized.size.height * ratio), 1)

    guard let resized = resize(normalized, width: targetWidth, height: targetHeight),
          let cgImage = resized.cgImage else {
      return nil
    }

    let width = cgImage.width
    let height = cgImage.height
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    let bytesPerPixel = 4
    let bytesPerRow = bytesPerPixel * width
    var rgba = [UInt8](repeating: 255, count: height * bytesPerRow)

    guard let context = CGContext(
      data: &rgba,
      width: width,
      height: height,
      bitsPerComponent: 8,
      bytesPerRow: bytesPerRow,
      space: colorSpace,
      bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
    ) else { return nil }

    context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))

    var gray = Array(repeating: 0, count: width * height)
    for y in 0..<height {
      for x in 0..<width {
        let i = y * bytesPerRow + x * bytesPerPixel
        let r = Double(rgba[i])
        let g = Double(rgba[i + 1])
        let b = Double(rgba[i + 2])
        gray[y * width + x] = Int(r * 0.299 + g * 0.587 + b * 0.114)
      }
    }

    // Floyd-Steinberg dithering, same threshold idea as the Android version.
    for y in 0..<height {
      for x in 0..<width {
        let index = y * width + x
        let old = gray[index]
        let newValue = old < 160 ? 0 : 255
        let error = old - newValue
        gray[index] = newValue

        if x + 1 < width {
          gray[index + 1] = clamp(gray[index + 1] + error * 7 / 16)
        }
        if y + 1 < height {
          if x > 0 {
            gray[index + width - 1] = clamp(gray[index + width - 1] + error * 3 / 16)
          }
          gray[index + width] = clamp(gray[index + width] + error * 5 / 16)
          if x + 1 < width {
            gray[index + width + 1] = clamp(gray[index + width + 1] + error / 16)
          }
        }
      }
    }

    let pixels = gray.map { UInt8($0 == 0 ? 0 : 255) }
    return IOSMonoBitmap(width: width, height: height, pixels: pixels)
  }

  private static func clamp(_ value: Int) -> Int {
    max(0, min(255, value))
  }

  private static func normalize(_ image: UIImage) -> UIImage {
    if image.imageOrientation == .up { return image }
    UIGraphicsBeginImageContextWithOptions(image.size, false, image.scale)
    image.draw(in: CGRect(origin: .zero, size: image.size))
    let normalized = UIGraphicsGetImageFromCurrentImageContext() ?? image
    UIGraphicsEndImageContext()
    return normalized
  }

  private static func resize(_ image: UIImage, width: Int, height: Int) -> UIImage? {
    let size = CGSize(width: width, height: height)
    UIGraphicsBeginImageContextWithOptions(size, true, 1.0)
    UIColor.white.setFill()
    UIRectFill(CGRect(origin: .zero, size: size))
    image.draw(in: CGRect(origin: .zero, size: size))
    let resized = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()
    return resized
  }
}
