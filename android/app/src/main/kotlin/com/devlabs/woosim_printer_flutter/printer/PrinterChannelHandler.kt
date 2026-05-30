package com.devlabs.woosim_printer_flutter.printer

import android.content.Context
import android.os.Handler
import android.os.Looper
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class PrinterChannelHandler(context: Context) : MethodChannel.MethodCallHandler {
    private val mainHandler = Handler(Looper.getMainLooper())
    private val printerManager = BluetoothPrinterManager(context)

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "isBluetoothEnabled" -> result.success(printerManager.isBluetoothEnabled())
            "isConnected" -> result.success(printerManager.isConnected())
            "getBondedPrinters" -> runAsync(result) {
                printerManager.getBondedPrinters().map { it.toMap() }
            }
            "connect" -> runAsync(result) {
                val address = call.argument<String>("address").orEmpty()
                val name = call.argument<String>("name") ?: "Unknown Printer"
                printerManager.connect(PrinterDevice(name, address)).toMap()
            }
            "disconnect" -> {
                printerManager.disconnect()
                result.success(null)
            }
            "printTestReceipt" -> runAsync(result) {
                printerManager.printTestReceipt().toMap()
            }
            "printImage" -> runAsync(result) {
                val imagePath = call.argument<String>("imagePath").orEmpty()
                val paperWidth = call.argument<Int>("paperWidth") ?: 576
                printerManager.printImage(imagePath, paperWidth).toMap()
            }
            else -> result.notImplemented()
        }
    }

    private fun runAsync(result: MethodChannel.Result, block: () -> Any?) {
        Thread {
            try {
                val value = block()
                mainHandler.post { result.success(value) }
            } catch (e: Exception) {
                mainHandler.post { result.error("WOOSIM_ERROR", e.message ?: "Native printer error", null) }
            }
        }.start()
    }
}
