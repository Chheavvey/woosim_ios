package com.devlabs.woosim_printer_flutter.printer

import android.annotation.SuppressLint
import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothDevice
import android.bluetooth.BluetoothManager
import android.bluetooth.BluetoothSocket
import android.content.Context
import android.graphics.BitmapFactory
import java.io.OutputStream
import java.lang.reflect.Method
import java.util.UUID

class BluetoothPrinterManager(private val context: Context) {
    private val sppUuid: UUID = UUID.fromString("00001101-0000-1000-8000-00805F9B34FB")
    private val bluetoothAdapter: BluetoothAdapter? by lazy {
        (context.getSystemService(Context.BLUETOOTH_SERVICE) as BluetoothManager).adapter
    }

    private var socket: BluetoothSocket? = null
    private var outputStream: OutputStream? = null
    private var connectedDevice: PrinterDevice? = null

    fun isBluetoothEnabled(): Boolean = bluetoothAdapter?.isEnabled == true
    fun isConnected(): Boolean = socket?.isConnected == true && outputStream != null

    @SuppressLint("MissingPermission")
    fun getBondedPrinters(): List<PrinterDevice> {
        val devices = bluetoothAdapter?.bondedDevices ?: emptySet()
        return devices
            .map { PrinterDevice(it.name ?: "Unknown Printer", it.address) }
            .sortedBy { it.name.lowercase() }
    }

    @SuppressLint("MissingPermission")
    fun connect(device: PrinterDevice): NativePrinterResult {
        disconnect()
        if (!isBluetoothEnabled()) return NativePrinterResult(false, "Bluetooth is turned off")

        val btDevice = bluetoothAdapter?.bondedDevices?.firstOrNull { it.address == device.address }
            ?: return NativePrinterResult(false, "Printer not found in paired devices")

        bluetoothAdapter?.cancelDiscovery()

        val candidates = listOfNotNull(
            runCatching { btDevice.createRfcommSocketToServiceRecord(sppUuid) }.getOrNull(),
            runCatching { btDevice.createInsecureRfcommSocketToServiceRecord(sppUuid) }.getOrNull(),
            createFallbackSocket(btDevice)
        )

        for (candidate in candidates) {
            try {
                candidate.connect()
                socket = candidate
                outputStream = candidate.outputStream
                connectedDevice = device
                return NativePrinterResult(true)
            } catch (_: Exception) {
                runCatching { candidate.close() }
            }
        }

        return NativePrinterResult(false, "Unable to connect. Make sure printer is paired and supports SPP.")
    }

    fun disconnect() {
        runCatching { outputStream?.flush() }
        runCatching { outputStream?.close() }
        runCatching { socket?.close() }
        outputStream = null
        socket = null
        connectedDevice = null
    }

    fun printTestReceipt(): NativePrinterResult {
        val os = outputStream ?: return NativePrinterResult(false, "Printer not connected")
        return try {
            os.write(EscPos.initialize())
            os.write(EscPos.alignCenter())
            os.write(EscPos.boldOn())
            os.write("PHOTO PRINTER\n".toByteArray())
            os.write(EscPos.boldOff())
            os.write("80mm test page\n\n".toByteArray())
            os.write(EscPos.feed(3))
            os.flush()
            NativePrinterResult(true)
        } catch (e: Exception) {
            NativePrinterResult(false, e.message ?: "Print failed")
        }
    }

    fun printImage(imagePath: String, paperWidth: Int): NativePrinterResult {
        val os = outputStream ?: return NativePrinterResult(false, "Printer not connected")
        if (imagePath.isBlank()) return NativePrinterResult(false, "Image path is empty")

        return try {
            val bitmap = BitmapFactory.decodeFile(imagePath)
                ?: return NativePrinterResult(false, "Unable to decode selected image")
            val prepared = ThermalImageConverter.prepareForWoosim(bitmap, paperWidth)
            os.write(EscPos.initialize())
            os.write(EscPos.alignCenter())
            os.write(EscPos.lineSpacing24())
            os.write(EscPos.bitImage24(prepared))
            os.write(EscPos.defaultLineSpacing())
            os.write(EscPos.feed(4))
            os.flush()
            NativePrinterResult(true)
        } catch (e: Exception) {
            NativePrinterResult(false, e.message ?: "Image print failed")
        }
    }

    @SuppressLint("MissingPermission")
    private fun createFallbackSocket(device: BluetoothDevice): BluetoothSocket? {
        return try {
            val method: Method = device.javaClass.getMethod("createRfcommSocket", Int::class.javaPrimitiveType)
            method.invoke(device, 1) as? BluetoothSocket
        } catch (_: Exception) {
            null
        }
    }
}
