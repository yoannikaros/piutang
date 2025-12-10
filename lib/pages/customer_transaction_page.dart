import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database/database_helper.dart';
import '../models/customer.dart';
import '../models/transaction.dart';
import '../services/receipt_printer_service.dart';
import 'add_transaction_page.dart';
import 'edit_transaction_page.dart';

class CustomerTransactionPage extends StatefulWidget {
  final Customer customer;

  const CustomerTransactionPage({super.key, required this.customer});

  @override
  State<CustomerTransactionPage> createState() =>
      _CustomerTransactionPageState();
}

class _CustomerTransactionPageState extends State<CustomerTransactionPage> {
  final DatabaseHelper _db = DatabaseHelper.instance;
  List<Transaction> _transactions = [];
  bool _isLoading = true;
  double _totalDebt = 0.0;

  final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  final DateFormat _dateFormat = DateFormat('dd MMM yyyy, HH:mm', 'id_ID');
  final DateFormat _shortDateFormat = DateFormat('dd MMM HH:mm', 'id_ID');

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    setState(() => _isLoading = true);
    try {
      final transactions = await _db.getCustomerTransactions(
        widget.customer.id!,
      );
      double total = 0.0;
      for (var txn in transactions) {
        if (!txn.isReset) {
          total += txn.total;
        }
      }
      setState(() {
        _transactions = transactions;
        _totalDebt = total;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error memuat data: $e')));
      }
    }
  }

  Future<void> _payOffTransaction(Transaction transaction) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Lunasi Transaksi'),
            content: Text(
              'Tandai transaksi ini sebagai lunas?\n\n'
              'Tanggal: ${_dateFormat.format(transaction.takenAt)}\n'
              'Total: ${_currencyFormat.format(transaction.total)}',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Batal'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Lunasi'),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      try {
        // Mark this specific transaction as paid
        final updatedTransaction = transaction.copyWith(
          isReset: true,
          resetAt: DateTime.now(),
        );
        await _db.updateTransaction(updatedTransaction);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Transaksi berhasil dilunasi')),
          );
        }

        // Automatically print receipt
        _printReceipt(transaction);

        _loadTransactions();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      }
    }
  }

  Future<void> _printReceipt(Transaction transaction) async {
    try {
      final printerService = ReceiptPrinterService.instance;

      final result = await printerService.printReceipt(
        customer: widget.customer,
        transaction: transaction,
        storeName: 'TOKO SAYA', // You can customize this
        // storeAddress: 'Alamat Toko', // Optional
        // storePhone: '08123456789', // Optional
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.message),
            backgroundColor: result.success ? Colors.green : Colors.orange,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mencetak nota: $e'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  Future<void> _editTransaction(Transaction transaction) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder:
            (context) => EditTransactionPage(
              customer: widget.customer,
              transaction: transaction,
            ),
      ),
    );

    // Reload if changes were made
    if (result == true) {
      _loadTransactions();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).colorScheme.primary.withValues(alpha: 0.05),
              Theme.of(context).colorScheme.secondary.withValues(alpha: 0.05),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(context),
              Expanded(
                child:
                    _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : Column(
                          children: [
                            _buildCustomerInfoCard(),
                            const SizedBox(height: 16),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                              ),
                              child: Row(
                                children: [
                                  const Text(
                                    'Riwayat Transaksi',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const Spacer(),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .primary
                                          .withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      '${_transactions.length} transaksi',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color:
                                            Theme.of(
                                              context,
                                            ).colorScheme.primary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            Expanded(
                              child:
                                  _transactions.isEmpty
                                      ? _buildEmptyState()
                                      : ListView.builder(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                        ),
                                        itemCount: _transactions.length,
                                        itemBuilder: (context, index) {
                                          final transaction =
                                              _transactions[index];
                                          return _buildTransactionCard(
                                            transaction,
                                          );
                                        },
                                      ),
                            ),
                          ],
                        ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (context) => AddTransactionPage(customer: widget.customer),
            ),
          );
          _loadTransactions();
        },
        icon: const Icon(Icons.add_shopping_cart),
        label: const Text('Tambah Transaksi'),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back),
            style: IconButton.styleFrom(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.customer.name,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (widget.customer.phone != null)
                  Row(
                    children: [
                      Icon(Icons.phone, size: 14, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        widget.customer.phone!,
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerInfoCard() {
    final hasDebt = _totalDebt > 0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors:
              hasDebt
                  ? [Colors.orange[400]!, Colors.deepOrange[500]!]
                  : [Colors.green[400]!, Colors.teal[500]!],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: (hasDebt ? Colors.orange : Colors.green).withValues(
              alpha: 0.3,
            ),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Total Hutang',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _currencyFormat.format(_totalDebt),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              hasDebt ? Icons.account_balance_wallet : Icons.check_circle,
              color: Colors.white,
              size: 32,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.receipt_long_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Belum ada transaksi',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap tombol di bawah untuk menambah',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionCard(Transaction transaction) {
    final isReset = transaction.isReset;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors:
                    isReset
                        ? [Colors.green[400]!, Colors.teal[400]!]
                        : [Colors.orange[400]!, Colors.deepOrange[400]!],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: (isReset ? Colors.green : Colors.orange).withValues(
                    alpha: 0.3,
                  ),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              isReset ? Icons.check_circle : Icons.shopping_cart,
              color: Colors.white,
              size: 24,
            ),
          ),
          title: Text(
            _dateFormat.format(transaction.takenAt),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isReset ? Colors.green[50] : Colors.orange[50],
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                isReset ? 'LUNAS' : 'Belum Lunas',
                style: TextStyle(
                  color: isReset ? Colors.green[700] : Colors.orange[700],
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                ),
              ),
            ),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _currencyFormat.format(transaction.total),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isReset ? Colors.grey[600] : Colors.red[700],
                  decoration: isReset ? TextDecoration.lineThrough : null,
                ),
              ),
              if (!isReset) ...[
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () => _editTransaction(transaction),
                  icon: const Icon(Icons.edit_outlined),
                  color: Colors.blue[600],
                  tooltip: 'Edit',
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.blue[50],
                    padding: const EdgeInsets.all(8),
                  ),
                ),
                const SizedBox(width: 4),
                IconButton(
                  onPressed: () => _payOffTransaction(transaction),
                  icon: const Icon(Icons.check_circle_outline),
                  color: Colors.green[600],
                  tooltip: 'Lunasi',
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.green[50],
                    padding: const EdgeInsets.all(8),
                  ),
                ),
              ],
            ],
          ),
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
              child: Column(
                children: [
                  ...transaction.lines.map((line) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Theme.of(
                                context,
                              ).colorScheme.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${line.quantity}x',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  line.productName ?? 'Produk',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                                Row(
                                  children: [
                                    Text(
                                      '${_currencyFormat.format(line.unitPrice)}${line.productUnit != null ? ' / ${line.productUnit}' : ''}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    if (line.createdAt != null) ...[
                                      Text(
                                        ' • ',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                      Icon(
                                        Icons.access_time,
                                        size: 12,
                                        color: Colors.grey[600],
                                      ),
                                      const SizedBox(width: 2),
                                      Text(
                                        _shortDateFormat.format(
                                          line.createdAt!,
                                        ),
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Text(
                            _currencyFormat.format(line.lineTotal),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                  if (!isReset) ...[
                    const SizedBox(height: 12),
                    const Divider(),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _editTransaction(transaction),
                            icon: const Icon(Icons.edit_outlined),
                            label: const Text('Edit Transaksi'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue[600],
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              elevation: 0,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _payOffTransaction(transaction),
                            icon: const Icon(Icons.check_circle_outline),
                            label: const Text('Lunasi'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green[600],
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              elevation: 0,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
