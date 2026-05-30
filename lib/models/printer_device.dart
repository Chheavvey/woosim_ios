class PrinterDevice {
  const PrinterDevice({required this.name, required this.address});

  final String name;
  final String address;

  factory PrinterDevice.fromMap(Map<dynamic, dynamic> map) {
    return PrinterDevice(
      name: (map['name'] ?? 'Unknown Printer').toString(),
      address: (map['address'] ?? '').toString(),
    );
  }

  Map<String, String> toMap() {
    return {'name': name, 'address': address};
  }
}
