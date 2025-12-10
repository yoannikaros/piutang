import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../database/database_helper.dart';
import '../models/customer.dart';
import '../models/product.dart';
import '../models/transaction.dart';
import '../models/transaction_line.dart';

class AddTransactionPage extends StatefulWidget {
  final Customer customer;

  const AddTransactionPage({super.key, required this.customer});

  @override
  State<AddTransactionPage> createState() => _AddTransactionPageState();
}

class _AddTransactionPageState extends State<AddTransactionPage> {
  final DatabaseHelper _db = DatabaseHelper.instance;
  List<Product> _allProducts = [];
  final Map<int, _ProductQuantity> _productQuantities = {};
  bool _isLoading = true;
  bool _isSaving = false;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Product> get _filteredProducts {
    if (_searchQuery.isEmpty) {
      return _allProducts;
    }
    return _allProducts.where((product) {
      return product.name.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }

  Future<void> _loadProducts() async {
    setState(() => _isLoading = true);
    try {
      final products = await _db.getAllProducts();
      setState(() {
        _allProducts = products;
        // Initialize all products with quantity 0
        for (var product in products) {
          _productQuantities[product.id!] = _ProductQuantity(
            quantity: 0,
            unitPrice: product.price,
          );
        }
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

  void _incrementQuantity(int productId) {
    setState(() {
      _productQuantities[productId]!.quantity++;
    });
  }

  void _decrementQuantity(int productId) {
    setState(() {
      if (_productQuantities[productId]!.quantity > 0) {
        _productQuantities[productId]!.quantity--;
      }
    });
  }

  void _updateQuantity(int productId, int quantity) {
    if (quantity >= 0) {
      setState(() {
        _productQuantities[productId]!.quantity = quantity;
      });
    }
  }

  void _updatePrice(int productId, double price) {
    if (price >= 0) {
      setState(() {
        _productQuantities[productId]!.unitPrice = price;
      });
    }
  }

  double get _totalAmount {
    double total = 0.0;
    _productQuantities.forEach((productId, pq) {
      total += pq.quantity * pq.unitPrice;
    });
    return total;
  }

  int get _totalItems {
    int count = 0;
    _productQuantities.forEach((_, pq) {
      if (pq.quantity > 0) count++;
    });
    return count;
  }

  Future<void> _saveTransaction() async {
    // Get products with quantity > 0
    final selectedProducts =
        _allProducts.where((product) {
          return _productQuantities[product.id!]!.quantity > 0;
        }).toList();

    if (selectedProducts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tambahkan minimal 1 barang')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final transaction = Transaction(
        customerId: widget.customer.id!,
        takenAt: DateTime.now(),
        lines:
            selectedProducts.map((product) {
              final pq = _productQuantities[product.id!]!;
              return TransactionLine(
                transactionId: 0, // Will be set by database
                productId: product.id!,
                quantity: pq.quantity,
                unitPrice: pq.unitPrice,
                lineTotal: pq.quantity * pq.unitPrice,
              );
            }).toList(),
      );

      await _db.insertTransaction(transaction);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Transaksi berhasil disimpan')),
        );
      }
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tambah Transaksi'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                children: [
                  // Customer Info
                  Card(
                    margin: const EdgeInsets.all(12),
                    color: Colors.blue[50],
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          CircleAvatar(
                            child: Text(
                              widget.customer.name
                                  .substring(0, 1)
                                  .toUpperCase(),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.customer.name,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (widget.customer.phone != null)
                                  Text(
                                    widget.customer.phone!,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[700],
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Search Bar
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Cari barang...',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon:
                            _searchQuery.isNotEmpty
                                ? IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () {
                                    setState(() {
                                      _searchController.clear();
                                      _searchQuery = '';
                                    });
                                  },
                                )
                                : null,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.grey[100],
                        isDense: true,
                      ),
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value;
                        });
                      },
                    ),
                  ),

                  // Header
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Pilih Barang',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (_totalItems > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.blue[100],
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '$_totalItems item dipilih',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue[900],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                  // Products List
                  Expanded(
                    child:
                        _allProducts.isEmpty
                            ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.inventory_2_outlined,
                                    size: 80,
                                    color: Colors.grey[400],
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Belum ada barang tersedia',
                                    style: TextStyle(
                                      fontSize: 18,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            )
                            : _filteredProducts.isEmpty
                            ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.search_off,
                                    size: 80,
                                    color: Colors.grey[400],
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Barang tidak ditemukan',
                                    style: TextStyle(
                                      fontSize: 18,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Coba kata kunci lain',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[500],
                                    ),
                                  ),
                                ],
                              ),
                            )
                            : ListView.builder(
                              itemCount: _filteredProducts.length,
                              itemBuilder: (context, index) {
                                return _buildProductCard(
                                  _filteredProducts[index],
                                );
                              },
                            ),
                  ),

                  // Total and Save Button
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withValues(alpha: 0.3),
                          spreadRadius: 1,
                          blurRadius: 5,
                          offset: const Offset(0, -3),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Total:',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              _currencyFormat.format(_totalAmount),
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.red[700],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton.icon(
                            onPressed: _isSaving ? null : _saveTransaction,
                            icon:
                                _isSaving
                                    ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                    : const Icon(Icons.save),
                            label: Text(
                              _isSaving ? 'Menyimpan...' : 'Simpan Transaksi',
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              textStyle: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
    );
  }

  Widget _buildProductCard(Product product) {
    final pq = _productQuantities[product.id!]!;
    final isSelected = pq.quantity > 0;
    final qtyController = TextEditingController(text: pq.quantity.toString());
    final priceController = TextEditingController(
      text: pq.unitPrice.toStringAsFixed(0),
    );

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      elevation: isSelected ? 3 : 1,
      color: isSelected ? Colors.blue[50] : null,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? Colors.blue[900] : null,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${_currencyFormat.format(product.price)}${product.unit != null ? ' / ${product.unit}' : ''}',
                        style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                      ),
                    ],
                  ),
                ),
                // Quantity Counter
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove),
                        onPressed: () => _decrementQuantity(product.id!),
                        iconSize: 20,
                        padding: const EdgeInsets.all(8),
                        constraints: const BoxConstraints(),
                      ),
                      Container(
                        width: 50,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: TextField(
                          controller: qtyController,
                          textAlign: TextAlign.center,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? Colors.blue[900] : null,
                          ),
                          onChanged: (value) {
                            final qty = int.tryParse(value);
                            if (qty != null) _updateQuantity(product.id!, qty);
                          },
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add),
                        onPressed: () => _incrementQuantity(product.id!),
                        iconSize: 20,
                        padding: const EdgeInsets.all(8),
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (isSelected) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: priceController,
                      decoration: const InputDecoration(
                        labelText: 'Harga Satuan',
                        border: OutlineInputBorder(),
                        prefixText: 'Rp ',
                        isDense: true,
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      onChanged: (value) {
                        final price = double.tryParse(value);
                        if (price != null) _updatePrice(product.id!, price);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text(
                        'Subtotal',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      Text(
                        _currencyFormat.format(pq.quantity * pq.unitPrice),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ProductQuantity {
  int quantity;
  double unitPrice;

  _ProductQuantity({required this.quantity, required this.unitPrice});
}
