package com.devlabs.woosim_printer_flutter.printer

data class NativePrinterResult(val success: Boolean, val error: String? = null) {
    fun toMap(): Map<String, Any?> = mapOf("success" to success, "error" to error)
}
