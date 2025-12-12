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
  List<Transaction> _allTransactions = []; // Store all transactions
  bool _isLoading = true;
  double _totalDebt = 0.0;
  DateTime? _startDate;
  DateTime? _endDate;

  final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  final DateFormat _dateFormat = DateFormat('dd MMM yyyy, HH:mm', 'id_ID');
  final DateFormat _shortDateFormat = DateFormat('dd MMM HH:mm', 'id_ID');
  final DateFormat _timeOnlyFormat = DateFormat('HH:mm', 'id_ID');
  final DateFormat _displayDateFormat = DateFormat('dd MMM yyyy', 'id_ID');

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

      // Store all transactions
      _allTransactions = transactions;

      // Apply date filter if set
      List<Transaction> filteredTransactions = transactions;
      if (_startDate != null && _endDate != null) {
        filteredTransactions =
            transactions.where((txn) {
              final txnDate = DateTime(
                txn.takenAt.year,
                txn.takenAt.month,
                txn.takenAt.day,
              );
              final start = DateTime(
                _startDate!.year,
                _startDate!.month,
                _startDate!.day,
              );
              final end = DateTime(
                _endDate!.year,
                _endDate!.month,
                _endDate!.day,
              );
              return (txnDate.isAtSameMomentAs(start) ||
                      txnDate.isAfter(start)) &&
                  (txnDate.isAtSameMomentAs(end) || txnDate.isBefore(end));
            }).toList();
      }

      double total = 0.0;
      for (var txn in filteredTransactions) {
        if (!txn.isReset) {
          total += txn.total;
        }
      }
      setState(() {
        _transactions = filteredTransactions;
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

  Future<void> _showDateRangePicker() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange:
          _startDate != null && _endDate != null
              ? DateTimeRange(start: _startDate!, end: _endDate!)
              : null,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Theme.of(context).colorScheme.primary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
      _loadTransactions();
    }
  }

  void _clearDateFilter() {
    setState(() {
      _startDate = null;
      _endDate = null;
    });
    _loadTransactions();
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
                                      : _buildGroupedTransactionsList(),
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
                if (_startDate != null && _endDate != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Row(
                      children: [
                        Icon(
                          Icons.date_range,
                          size: 14,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${_displayDateFormat.format(_startDate!)} - ${_displayDateFormat.format(_endDate!)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          // Date filter button
          IconButton(
            onPressed: _showDateRangePicker,
            icon: Icon(
              _startDate != null && _endDate != null
                  ? Icons.filter_alt
                  : Icons.filter_alt_outlined,
            ),
            style: IconButton.styleFrom(
              backgroundColor:
                  _startDate != null && _endDate != null
                      ? Theme.of(
                        context,
                      ).colorScheme.primary.withValues(alpha: 0.1)
                      : Colors.white,
              foregroundColor:
                  _startDate != null && _endDate != null
                      ? Theme.of(context).colorScheme.primary
                      : Colors.grey[700],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            tooltip: 'Filter Tanggal',
          ),
          if (_startDate != null && _endDate != null) ...[
            const SizedBox(width: 8),
            IconButton(
              onPressed: _clearDateFilter,
              icon: const Icon(Icons.clear),
              style: IconButton.styleFrom(
                backgroundColor: Colors.red[50],
                foregroundColor: Colors.red[700],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              tooltip: 'Hapus Filter',
            ),
          ],
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

  /// Group transactions by date (yyyy-MM-dd)
  Map<String, List<Transaction>> _groupTransactionsByDate() {
    final Map<String, List<Transaction>> grouped = {};
    final dateOnlyFormat = DateFormat('yyyy-MM-dd');

    for (var transaction in _transactions) {
      final dateKey = dateOnlyFormat.format(transaction.takenAt);
      if (!grouped.containsKey(dateKey)) {
        grouped[dateKey] = [];
      }
      grouped[dateKey]!.add(transaction);
    }

    return grouped;
  }

  Widget _buildGroupedTransactionsList() {
    final groupedTransactions = _groupTransactionsByDate();
    final sortedDates =
        groupedTransactions.keys.toList()
          ..sort((a, b) => b.compareTo(a)); // Sort descending (newest first)

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: sortedDates.length,
      itemBuilder: (context, dateIndex) {
        final dateKey = sortedDates[dateIndex];
        final transactions = groupedTransactions[dateKey]!;
        final firstTransaction = transactions.first;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date header
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Theme.of(context).colorScheme.primary,
                          Theme.of(context).colorScheme.secondary,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Theme.of(
                            context,
                          ).colorScheme.primary.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.calendar_today,
                          size: 14,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          DateFormat(
                            'EEEE, dd MMMM yyyy',
                            'id_ID',
                          ).format(firstTransaction.takenAt),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${transactions.length} transaksi',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Single card containing all transactions for this date
            Card(
              margin: const EdgeInsets.only(bottom: 16),
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Colors.grey[300]!, width: 1),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children:
                      transactions.asMap().entries.map((entry) {
                        final index = entry.key;
                        final transaction = entry.value;
                        final isLast = index == transactions.length - 1;

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildTransactionSection(transaction),
                            if (!isLast)
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Divider(
                                        color: Colors.grey[300],
                                        thickness: 1,
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                      ),
                                      child: Icon(
                                        Icons.fiber_manual_record,
                                        size: 8,
                                        color: Colors.grey[400],
                                      ),
                                    ),
                                    Expanded(
                                      child: Divider(
                                        color: Colors.grey[300],
                                        thickness: 1,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        );
                      }).toList(),
                ),
              ),
            ),
          ],
        );
      },
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

  Widget _buildTransactionSection(Transaction transaction) {
    final isReset = transaction.isReset;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Transaction items with subtle indicator
        ...transaction.lines.asMap().entries.map((entry) {
          final index = entry.key;
          final line = entry.value;
          final isFirstItem = index == 0;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Show transaction info only on first item
              if (isFirstItem)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Container(
                        width: 4,
                        height: 20,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors:
                                isReset
                                    ? [Colors.green[400]!, Colors.teal[400]!]
                                    : [
                                      Colors.orange[400]!,
                                      Colors.deepOrange[400]!,
                                    ],
                          ),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        isReset ? Icons.check_circle : Icons.shopping_cart,
                        size: 16,
                        color: isReset ? Colors.green[600] : Colors.orange[600],
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          _timeOnlyFormat.format(transaction.takenAt),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color:
                                isReset
                                    ? Colors.green[700]
                                    : Colors.orange[700],
                          ),
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color:
                              isReset ? Colors.green[100] : Colors.orange[100],
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          _currencyFormat.format(transaction.total),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color:
                                isReset
                                    ? Colors.green[700]
                                    : Colors.orange[700],
                            decoration:
                                isReset ? TextDecoration.lineThrough : null,
                          ),
                        ),
                      ),
                      // Action buttons as icons
                      if (!isReset) ...[
                        const SizedBox(width: 4),
                        IconButton(
                          onPressed: () => _editTransaction(transaction),
                          icon: const Icon(Icons.edit_outlined),
                          iconSize: 18,
                          color: Colors.blue[700],
                          padding: const EdgeInsets.all(4),
                          constraints: const BoxConstraints(
                            minWidth: 32,
                            minHeight: 32,
                          ),
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.blue[50],
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                          tooltip: 'Edit',
                        ),
                        const SizedBox(width: 4),
                        IconButton(
                          onPressed: () => _payOffTransaction(transaction),
                          icon: const Icon(Icons.check_circle_outline),
                          iconSize: 18,
                          color: Colors.green[700],
                          padding: const EdgeInsets.all(4),
                          constraints: const BoxConstraints(
                            minWidth: 32,
                            minHeight: 32,
                          ),
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.green[50],
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                          tooltip: 'Lunasi',
                        ),
                      ],
                    ],
                  ),
                ),
              // Item row with colored indicator
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Colored bar indicator
                  Container(
                    width: 4,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors:
                            isReset
                                ? [Colors.green[300]!, Colors.green[100]!]
                                : [Colors.orange[300]!, Colors.orange[100]!],
                      ),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color:
                          isReset
                              ? Colors.green[100]
                              : Theme.of(
                                context,
                              ).colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${line.quantity}x',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color:
                            isReset
                                ? Colors.green[700]
                                : Theme.of(context).colorScheme.primary,
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
                                _shortDateFormat.format(line.createdAt!),
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
              const SizedBox(height: 8),
            ],
          );
        }),
      ],
    );
  }
}
