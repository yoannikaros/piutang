import 'package:intl/intl.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';
import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import '../models/customer.dart';
import '../models/transaction.dart';

class ReceiptPrinterService {
  static final ReceiptPrinterService instance = ReceiptPrinterService._init();

  ReceiptPrinterService._init();

  final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  final DateFormat _dateFormat = DateFormat('dd MMM yyyy, HH:mm', 'id_ID');

  /// Check if Bluetooth is available and enabled
  Future<bool> isBluetoothAvailable() async {
    try {
      final bool result = await PrintBluetoothThermal.bluetoothEnabled;
      return result;
    } catch (e) {
      return false;
    }
  }

  /// Get list of paired Bluetooth devices
  Future<List<BluetoothInfo>> getPairedDevices() async {
    try {
      final List<BluetoothInfo> devices =
          await PrintBluetoothThermal.pairedBluetooths;
      return devices;
    } catch (e) {
      return [];
    }
  }

  /// Connect to a Bluetooth printer
  Future<bool> connectToPrinter(String macAddress) async {
    try {
      final bool result = await PrintBluetoothThermal.connect(
        macPrinterAddress: macAddress,
      );
      return result;
    } catch (e) {
      return false;
    }
  }

  /// Check if printer is connected
  Future<bool> isConnected() async {
    try {
      final bool result = await PrintBluetoothThermal.connectionStatus;
      return result;
    } catch (e) {
      return false;
    }
  }

  /// Disconnect from printer
  Future<void> disconnect() async {
    try {
      await PrintBluetoothThermal.disconnect;
    } catch (e) {
      // Ignore disconnect errors
    }
  }

  /// Generate receipt content for a paid transaction
  Future<List<int>> generateReceipt({
    required Customer customer,
    required Transaction transaction,
    String? storeName,
    String? storeAddress,
    String? storePhone,
  }) async {
    final profile = await CapabilityProfile.load();
    final generator = Generator(PaperSize.mm58, profile);
    List<int> bytes = [];

    // Header
    bytes += generator.text(
      storeName ?? 'TOKO SAYA',
      styles: const PosStyles(
        align: PosAlign.center,
        height: PosTextSize.size2,
        width: PosTextSize.size2,
        bold: true,
      ),
    );

    if (storeAddress != null) {
      bytes += generator.text(
        storeAddress,
        styles: const PosStyles(align: PosAlign.center, bold: false),
      );
    }

    if (storePhone != null) {
      bytes += generator.text(
        'Telp: $storePhone',
        styles: const PosStyles(align: PosAlign.center, bold: false),
      );
    }

    bytes += generator.text('================================');
    bytes += generator.text('BUKTI PEMBAYARAN');
    bytes += generator.text('================================');
    bytes += generator.emptyLines(1);

    // Customer Info
    bytes += generator.text('Pelanggan: ${customer.name}');
    if (customer.phone != null) {
      bytes += generator.text('Telp: ${customer.phone}');
    }
    bytes += generator.text(
      'Tanggal: ${_dateFormat.format(transaction.takenAt)}',
    );
    bytes += generator.text('--------------------------------');
    bytes += generator.emptyLines(1);

    // Transaction Items
    bytes += generator.text(
      'RINCIAN TRANSAKSI',
      styles: const PosStyles(bold: true),
    );
    bytes += generator.text('--------------------------------');

    for (var line in transaction.lines) {
      // Product name
      bytes += generator.text(
        line.productName ?? 'Produk',
        styles: const PosStyles(bold: true),
      );

      // Quantity x Price = Total
      final qtyPrice =
          '${line.quantity}x ${_currencyFormat.format(line.unitPrice)}';
      final lineTotal = _currencyFormat.format(line.lineTotal);

      bytes += generator.row([
        PosColumn(
          text: qtyPrice,
          width: 6,
          styles: const PosStyles(align: PosAlign.left),
        ),
        PosColumn(
          text: lineTotal,
          width: 6,
          styles: const PosStyles(align: PosAlign.right),
        ),
      ]);
    }

    bytes += generator.text('--------------------------------');

    // Total
    bytes += generator.row([
      PosColumn(
        text: 'TOTAL',
        width: 6,
        styles: const PosStyles(bold: true, height: PosTextSize.size2),
      ),
      PosColumn(
        text: _currencyFormat.format(transaction.total),
        width: 6,
        styles: const PosStyles(
          align: PosAlign.right,
          bold: true,
          height: PosTextSize.size2,
        ),
      ),
    ]);

    bytes += generator.text('================================');
    bytes += generator.emptyLines(1);

    // Payment confirmation
    bytes += generator.text(
      'LUNAS',
      styles: const PosStyles(
        align: PosAlign.center,
        bold: true,
        height: PosTextSize.size2,
        width: PosTextSize.size2,
      ),
    );

    bytes += generator.text(
      'Dibayar: ${_dateFormat.format(DateTime.now())}',
      styles: const PosStyles(align: PosAlign.center),
    );

    bytes += generator.emptyLines(1);
    bytes += generator.text(
      'Terima Kasih',
      styles: const PosStyles(align: PosAlign.center, bold: true),
    );

    bytes += generator.emptyLines(3);
    bytes += generator.cut();

    return bytes;
  }

  /// Print receipt for a paid transaction
  Future<PrintResult> printReceipt({
    required Customer customer,
    required Transaction transaction,
    String? storeName,
    String? storeAddress,
    String? storePhone,
  }) async {
    try {
      // Check if Bluetooth is available
      final bool bluetoothEnabled = await isBluetoothAvailable();
      if (!bluetoothEnabled) {
        return PrintResult(
          success: false,
          message: 'Bluetooth tidak aktif. Silakan aktifkan Bluetooth.',
        );
      }

      // Check if already connected
      bool connected = await isConnected();

      // If not connected, try to connect to the first paired printer
      if (!connected) {
        final devices = await getPairedDevices();
        if (devices.isEmpty) {
          return PrintResult(
            success: false,
            message: 'Tidak ada printer Bluetooth yang terpasang.',
          );
        }

        // Try to connect to the first device
        connected = await connectToPrinter(devices.first.macAdress);
        if (!connected) {
          return PrintResult(
            success: false,
            message: 'Gagal terhubung ke printer.',
          );
        }
      }

      // Generate receipt
      final bytes = await generateReceipt(
        customer: customer,
        transaction: transaction,
        storeName: storeName,
        storeAddress: storeAddress,
        storePhone: storePhone,
      );

      // Print
      final result = await PrintBluetoothThermal.writeBytes(bytes);

      if (result) {
        return PrintResult(success: true, message: 'Nota berhasil dicetak');
      } else {
        return PrintResult(success: false, message: 'Gagal mencetak nota');
      }
    } catch (e) {
      return PrintResult(success: false, message: 'Error: ${e.toString()}');
    }
  }
}

class PrintResult {
  final bool success;
  final String message;

  PrintResult({required this.success, required this.message});
}
