import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import '../database/database_helper.dart';

class PdfService {
  static final PdfService instance = PdfService._init();
  PdfService._init();

  final DatabaseHelper _db = DatabaseHelper.instance;

  Future<List<int>> generateTransactionReport() async {
    final pdf = pw.Document();

    // Get all transaction data
    final data = await _db.getAllTransactionsForPdf();
    final customers = data['customers'] as List<Map<String, dynamic>>;
    final generatedAt = DateTime.parse(data['generated_at'] as String);

    // Format dates
    final dateFormat = DateFormat('dd MMM yyyy');
    final dateTimeFormat = DateFormat('dd MMM yyyy HH:mm');
    final currencyFormat = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    // Calculate grand total
    double grandTotal = 0;
    int totalTransactions = 0;
    for (var customerData in customers) {
      final transactions =
          customerData['transactions'] as List<Map<String, dynamic>>;
      for (var txnData in transactions) {
        final lines = txnData['lines'] as List<Map<String, dynamic>>;
        final txnTotal = lines.fold<double>(
          0.0,
          (sum, line) => sum + ((line['line_total'] as num).toDouble()),
        );
        grandTotal += txnTotal;
        totalTransactions++;
      }
    }

    // Build PDF pages
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (context) {
          List<pw.Widget> widgets = [];

          // Header
          widgets.add(
            pw.Container(
              padding: const pw.EdgeInsets.only(bottom: 20),
              decoration: const pw.BoxDecoration(
                border: pw.Border(
                  bottom: pw.BorderSide(color: PdfColors.blue700, width: 3),
                ),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'LAPORAN TRANSAKSI',
                    style: pw.TextStyle(
                      fontSize: 28,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.blue700,
                    ),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Text(
                    'Tanggal: ${dateTimeFormat.format(generatedAt)}',
                    style: const pw.TextStyle(
                      fontSize: 12,
                      color: PdfColors.grey700,
                    ),
                  ),
                ],
              ),
            ),
          );

          widgets.add(pw.SizedBox(height: 20));

          // Summary Card
          widgets.add(
            pw.Container(
              padding: const pw.EdgeInsets.all(16),
              decoration: pw.BoxDecoration(
                color: PdfColors.blue50,
                borderRadius: pw.BorderRadius.circular(8),
                border: pw.Border.all(color: PdfColors.blue200),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Total Pelanggan',
                        style: const pw.TextStyle(
                          fontSize: 10,
                          color: PdfColors.grey700,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        '${customers.length}',
                        style: pw.TextStyle(
                          fontSize: 20,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.blue700,
                        ),
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Total Transaksi',
                        style: const pw.TextStyle(
                          fontSize: 10,
                          color: PdfColors.grey700,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        '$totalTransactions',
                        style: pw.TextStyle(
                          fontSize: 20,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.blue700,
                        ),
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        'Grand Total',
                        style: const pw.TextStyle(
                          fontSize: 10,
                          color: PdfColors.grey700,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        currencyFormat.format(grandTotal),
                        style: pw.TextStyle(
                          fontSize: 20,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.green700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );

          widgets.add(pw.SizedBox(height: 30));

          // Iterate through customers
          for (var customerData in customers) {
            final customer = customerData['customer'] as Map<String, dynamic>;
            final transactions =
                customerData['transactions'] as List<Map<String, dynamic>>;

            // Customer Header
            widgets.add(
              pw.Container(
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey200,
                  borderRadius: const pw.BorderRadius.only(
                    topLeft: pw.Radius.circular(8),
                    topRight: pw.Radius.circular(8),
                  ),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          customer['name'] as String,
                          style: pw.TextStyle(
                            fontSize: 14,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        if (customer['phone'] != null)
                          pw.Text(
                            'Tel: ${customer['phone']}',
                            style: const pw.TextStyle(
                              fontSize: 10,
                              color: PdfColors.grey700,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            );

            // Transactions for this customer
            for (var txnData in transactions) {
              final transaction =
                  txnData['transaction'] as Map<String, dynamic>;
              final lines = txnData['lines'] as List<Map<String, dynamic>>;
              final takenAt = DateTime.parse(transaction['taken_at'] as String);
              final isReset = (transaction['is_reset'] as int) == 1;

              double transactionTotal = 0;

              // Transaction info
              widgets.add(
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: pw.BoxDecoration(
                    color: isReset ? PdfColors.green50 : PdfColors.white,
                    border: pw.Border.all(color: PdfColors.grey300),
                  ),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        'Tanggal: ${dateTimeFormat.format(takenAt)}',
                        style: const pw.TextStyle(
                          fontSize: 10,
                          color: PdfColors.grey700,
                        ),
                      ),
                      if (isReset)
                        pw.Container(
                          padding: const pw.EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: pw.BoxDecoration(
                            color: PdfColors.green,
                            borderRadius: pw.BorderRadius.circular(4),
                          ),
                          child: pw.Text(
                            'LUNAS',
                            style: const pw.TextStyle(
                              fontSize: 8,
                              color: PdfColors.white,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );

              // Transaction items table
              List<List<String>> tableData = [
                ['Produk', 'Qty', 'Harga Satuan', 'Total'],
              ];

              for (var line in lines) {
                final productName = line['product_name'] as String;
                final quantity = line['quantity'] as int;
                final unitPrice = (line['unit_price'] as num).toDouble();
                final lineTotal = (line['line_total'] as num).toDouble();
                final unit = line['product_unit'] as String?;

                transactionTotal += lineTotal;

                tableData.add([
                  unit != null ? '$productName ($unit)' : productName,
                  '$quantity',
                  currencyFormat.format(unitPrice),
                  currencyFormat.format(lineTotal),
                ]);
              }

              widgets.add(
                pw.Table(
                  border: pw.TableBorder.all(color: PdfColors.grey300),
                  columnWidths: {
                    0: const pw.FlexColumnWidth(3),
                    1: const pw.FlexColumnWidth(1),
                    2: const pw.FlexColumnWidth(2),
                    3: const pw.FlexColumnWidth(2),
                  },
                  children:
                      tableData.asMap().entries.map((entry) {
                        final isHeader = entry.key == 0;
                        final row = entry.value;

                        return pw.TableRow(
                          decoration: pw.BoxDecoration(
                            color:
                                isHeader ? PdfColors.blue700 : PdfColors.white,
                          ),
                          children:
                              row.map((cell) {
                                return pw.Container(
                                  padding: const pw.EdgeInsets.all(8),
                                  child: pw.Text(
                                    cell,
                                    style: pw.TextStyle(
                                      fontSize: 9,
                                      fontWeight:
                                          isHeader
                                              ? pw.FontWeight.bold
                                              : pw.FontWeight.normal,
                                      color:
                                          isHeader
                                              ? PdfColors.white
                                              : PdfColors.black,
                                    ),
                                    textAlign:
                                        row.indexOf(cell) == 0
                                            ? pw.TextAlign.left
                                            : pw.TextAlign.right,
                                  ),
                                );
                              }).toList(),
                        );
                      }).toList(),
                ),
              );

              // Transaction total
              widgets.add(
                pw.Container(
                  padding: const pw.EdgeInsets.all(8),
                  decoration: const pw.BoxDecoration(
                    color: PdfColors.grey100,
                    border: pw.Border(
                      left: pw.BorderSide(color: PdfColors.grey300),
                      right: pw.BorderSide(color: PdfColors.grey300),
                      bottom: pw.BorderSide(color: PdfColors.grey300),
                    ),
                  ),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.end,
                    children: [
                      pw.Text(
                        'Total: ',
                        style: pw.TextStyle(
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Text(
                        currencyFormat.format(transactionTotal),
                        style: pw.TextStyle(
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                          color:
                              isReset ? PdfColors.green700 : PdfColors.red700,
                        ),
                      ),
                    ],
                  ),
                ),
              );

              widgets.add(pw.SizedBox(height: 8));
            }

            widgets.add(pw.SizedBox(height: 20));
          }

          // Empty state
          if (customers.isEmpty) {
            widgets.add(
              pw.Container(
                padding: const pw.EdgeInsets.all(40),
                alignment: pw.Alignment.center,
                child: pw.Column(
                  children: [
                    pw.Text(
                      'Tidak ada transaksi',
                      style: pw.TextStyle(
                        fontSize: 16,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.grey600,
                      ),
                    ),
                    pw.SizedBox(height: 8),
                    pw.Text(
                      'Belum ada data transaksi yang dapat ditampilkan',
                      style: const pw.TextStyle(
                        fontSize: 12,
                        color: PdfColors.grey500,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return widgets;
        },
        footer: (context) {
          return pw.Container(
            alignment: pw.Alignment.centerRight,
            margin: const pw.EdgeInsets.only(top: 20),
            child: pw.Text(
              'Halaman ${context.pageNumber} dari ${context.pagesCount}',
              style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
            ),
          );
        },
      ),
    );

    // Return the PDF bytes
    return await pdf.save();
  }
}
