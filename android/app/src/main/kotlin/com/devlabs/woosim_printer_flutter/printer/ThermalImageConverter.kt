package com.devlabs.woosim_printer_flutter.printer

import android.graphics.Bitmap
import android.graphics.Color
import kotlin.math.max

object ThermalImageConverter {
    fun prepareForWoosim(source: Bitmap, requestedWidth: Int): Bitmap {
        val targetWidth = requestedWidth
            .coerceAtMost(576)
            .let { if (it % 8 == 0) it else it - (it % 8) }
            .coerceAtLeast(8)

        val ratio = targetWidth.toFloat() / max(source.width, 1).toFloat()
        val resizedHeight = (source.height * ratio).toInt().coerceAtLeast(1)
        val scaled = Bitmap.createScaledBitmap(source, targetWidth, resizedHeight, true)

        val gray = Array(resizedHeight) { IntArray(targetWidth) }
        for (y in 0 until resizedHeight) {
            for (x in 0 until targetWidth) {
                val p = scaled.getPixel(x, y)
                gray[y][x] = (Color.red(p) * 0.299 + Color.green(p) * 0.587 + Color.blue(p) * 0.114).toInt()
            }
        }

        applyFloydSteinbergDithering(gray, targetWidth, resizedHeight)

        val result = Bitmap.createBitmap(targetWidth, resizedHeight, Bitmap.Config.ARGB_8888)
        for (y in 0 until resizedHeight) {
            for (x in 0 until targetWidth) {
                result.setPixel(x, y, if (gray[y][x] == 0) Color.BLACK else Color.WHITE)
            }
        }
        return result
    }

    private fun applyFloydSteinbergDithering(gray: Array<IntArray>, width: Int, height: Int) {
        for (y in 0 until height) {
            for (x in 0 until width) {
                val old = gray[y][x]
                val newValue = if (old < 160) 0 else 255
                val error = old - newValue
                gray[y][x] = newValue

                if (x + 1 < width) gray[y][x + 1] = (gray[y][x + 1] + error * 7 / 16).coerceIn(0, 255)
                if (y + 1 < height) {
                    if (x > 0) gray[y + 1][x - 1] = (gray[y + 1][x - 1] + error * 3 / 16).coerceIn(0, 255)
                    gray[y + 1][x] = (gray[y + 1][x] + error * 5 / 16).coerceIn(0, 255)
                    if (x + 1 < width) gray[y + 1][x + 1] = (gray[y + 1][x + 1] + error * 1 / 16).coerceIn(0, 255)
                }
            }
        }
    }
}
