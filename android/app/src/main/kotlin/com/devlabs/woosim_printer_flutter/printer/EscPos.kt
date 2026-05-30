package com.devlabs.woosim_printer_flutter.printer

import android.graphics.Bitmap
import android.graphics.Color
import java.io.ByteArrayOutputStream

object EscPos {
    fun initialize() = byteArrayOf(0x1B, 0x40)
    fun alignCenter() = byteArrayOf(0x1B, 0x61, 0x01)
    fun boldOn() = byteArrayOf(0x1B, 0x45, 0x01)
    fun boldOff() = byteArrayOf(0x1B, 0x45, 0x00)
    fun feed(lines: Int) = byteArrayOf(0x1B, 0x64, lines.toByte())
    fun lineSpacing24() = byteArrayOf(0x1B, 0x33, 24)
    fun defaultLineSpacing() = byteArrayOf(0x1B, 0x32)

    /**
     * 24-dot double-density bit image mode: ESC * 33.
     * This keeps the same Woosim-compatible print strategy as the Android source app.
     */
    fun bitImage24(bitmap: Bitmap): ByteArray {
        val width = bitmap.width
        val height = bitmap.height
        val out = ByteArrayOutputStream()
        val widthL = (width and 0xFF).toByte()
        val widthH = ((width shr 8) and 0xFF).toByte()

        var y = 0
        while (y < height) {
            out.write(byteArrayOf(0x1B, 0x2A, 33, widthL, widthH))
            for (x in 0 until width) {
                for (k in 0 until 3) {
                    var slice = 0
                    for (b in 0 until 8) {
                        val yy = y + k * 8 + b
                        if (yy >= height) continue
                        val pixel = bitmap.getPixel(x, yy)
                        if (Color.red(pixel) == 0) slice = slice or (1 shl (7 - b))
                    }
                    out.write(slice)
                }
            }
            out.write(0x0A)
            y += 24
        }
        return out.toByteArray()
    }
}
