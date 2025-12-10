import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../database/database_helper.dart';
import '../models/product.dart';
import '../models/category.dart';

class ProductManagementPage extends StatefulWidget {
  final int? categoryId;
  final String? categoryName;

  const ProductManagementPage({super.key, this.categoryId, this.categoryName});

  @override
  State<ProductManagementPage> createState() => _ProductManagementPageState();
}

class _ProductManagementPageState extends State<ProductManagementPage> {
  final DatabaseHelper _db = DatabaseHelper.instance;
  List<Product> _products = [];
  List<Product> _filteredProducts = [];
  List<Category> _categories = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();
  final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    _loadCategories();
    _loadProducts();
    _searchController.addListener(_filterProducts);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterProducts() {
    final query = _searchController.text.toLowerCase().trim();
    setState(() {
      if (query.isEmpty) {
        _filteredProducts = _products;
      } else {
        _filteredProducts =
            _products.where((product) {
              final name = product.name.toLowerCase();
              final unit = product.unit?.toLowerCase() ?? '';
              final notes = product.notes?.toLowerCase() ?? '';

              return name.contains(query) ||
                  unit.contains(query) ||
                  notes.contains(query);
            }).toList();
      }
    });
  }

  Future<void> _loadCategories() async {
    try {
      final categories = await _db.getAllCategories();
      setState(() {
        _categories = categories.where((c) => c.isActive).toList();
      });
    } catch (e) {
      // Silent fail for categories
    }
  }

  Future<void> _loadProducts() async {
    setState(() => _isLoading = true);
    try {
      final products = await _db.getAllProducts();
      // Filter by category if categoryId is provided
      final filteredByCategory =
          widget.categoryId != null
              ? products
                  .where((p) => p.categoryId == widget.categoryId)
                  .toList()
              : products;

      setState(() {
        _products = filteredByCategory;
        _filteredProducts = filteredByCategory;
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

  int _getCrossAxisCount(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final orientation = MediaQuery.of(context).orientation;

    // Portrait orientation: always use list (1 column)
    if (orientation == Orientation.portrait) {
      return 1;
    }
    // Landscape tablet/large screen: 3 columns
    else if (width > 600) {
      return 3;
    }
    // Landscape phone: 2 columns
    return 2;
  }

  Future<void> _showProductDialog({Product? product}) async {
    final nameController = TextEditingController(text: product?.name ?? '');
    final priceController = TextEditingController(
      text: product != null ? product.price.toString() : '',
    );
    final unitController = TextEditingController(text: product?.unit ?? '');
    final notesController = TextEditingController(text: product?.notes ?? '');
    final formKey = GlobalKey<FormState>();

    // Initialize selected category
    int? selectedCategoryId = product?.categoryId ?? widget.categoryId;

    await showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setDialogState) => AlertDialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  insetPadding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 24,
                  ),
                  title: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          product == null ? Icons.add_box : Icons.edit,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        product == null ? 'Tambah Barang' : 'Edit Barang',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  content: Form(
                    key: formKey,
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextFormField(
                            controller: nameController,
                            decoration: InputDecoration(
                              labelText: 'Nama Barang *',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              filled: true,
                              fillColor: Colors.grey[50],
                              prefixIcon: const Icon(Icons.inventory_2),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Nama barang harus diisi';
                              }
                              return null;
                            },
                            autofocus: true,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: priceController,
                            decoration: InputDecoration(
                              labelText: 'Harga *',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              filled: true,
                              fillColor: Colors.grey[50],
                              prefixIcon: const Icon(Icons.attach_money),
                              prefixText: 'Rp ',
                            ),
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Harga harus diisi';
                              }
                              if (double.tryParse(value) == null) {
                                return 'Harga harus berupa angka';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          // Category Dropdown
                          DropdownButtonFormField<int>(
                            value: selectedCategoryId,
                            decoration: InputDecoration(
                              labelText: 'Kategori',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              filled: true,
                              fillColor: Colors.grey[50],
                              prefixIcon: const Icon(Icons.category),
                            ),
                            hint: const Text('Pilih kategori (opsional)'),
                            items: [
                              const DropdownMenuItem<int>(
                                value: null,
                                child: Text('Tanpa Kategori'),
                              ),
                              ..._categories.map((category) {
                                return DropdownMenuItem<int>(
                                  value: category.id,
                                  child: Row(
                                    children: [
                                      const Icon(Icons.category, size: 20),
                                      const SizedBox(width: 8),
                                      Text(category.name),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ],
                            onChanged: (value) {
                              setDialogState(() {
                                selectedCategoryId = value;
                              });
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: unitController,
                            decoration: InputDecoration(
                              labelText: 'Satuan (contoh: pcs, kg, liter)',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              filled: true,
                              fillColor: Colors.grey[50],
                              prefixIcon: const Icon(Icons.straighten),
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: notesController,
                            decoration: InputDecoration(
                              labelText: 'Catatan',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              filled: true,
                              fillColor: Colors.grey[50],
                              prefixIcon: const Icon(Icons.note),
                              alignLabelWithHint: true,
                            ),
                            maxLines: 3,
                          ),
                        ],
                      ),
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                      child: const Text('Batal'),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        if (formKey.currentState!.validate()) {
                          try {
                            final newProduct = Product(
                              id: product?.id,
                              name: nameController.text.trim(),
                              price: double.parse(priceController.text.trim()),
                              categoryId: selectedCategoryId,
                              unit:
                                  unitController.text.trim().isEmpty
                                      ? null
                                      : unitController.text.trim(),
                              notes:
                                  notesController.text.trim().isEmpty
                                      ? null
                                      : notesController.text.trim(),
                            );

                            if (product == null) {
                              await _db.insertProduct(newProduct);
                            } else {
                              await _db.updateProduct(newProduct);
                            }

                            if (context.mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    product == null
                                        ? 'Barang berhasil ditambahkan'
                                        : 'Barang berhasil diperbarui',
                                  ),
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              );
                            }
                            _loadProducts();
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Error: $e'),
                                  behavior: SnackBarBehavior.floating,
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        backgroundColor: const Color(0xFF6366F1),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Simpan'),
                    ),
                  ],
                ),
          ),
    );
  }

  Future<void> _deleteProduct(Product product) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.warning_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Hapus Barang',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            content: Text('Yakin ingin menghapus "${product.name}"?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
                child: const Text('Batal'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Hapus'),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      try {
        await _db.deleteProduct(product.id!);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Barang berhasil dihapus'),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }
        _loadProducts();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              behavior: SnackBarBehavior.floating,
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Widget _buildProductCard(Product product) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, Color(0xFFF8F9FF)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _showProductDialog(product: product),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF6366F1).withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.inventory_2,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: IconButton(
                              icon: const Icon(
                                Icons.edit,
                                color: Color(0xFF6366F1),
                                size: 20,
                              ),
                              onPressed:
                                  () => _showProductDialog(product: product),
                              tooltip: 'Edit',
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: IconButton(
                              icon: const Icon(
                                Icons.delete,
                                color: Colors.red,
                                size: 20,
                              ),
                              onPressed: () => _deleteProduct(product),
                              tooltip: 'Hapus',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    product.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F2937),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _currencyFormat.format(product.price),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  if (product.unit != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(
                          Icons.straighten,
                          size: 16,
                          color: Color(0xFF6B7280),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'per ${product.unit}',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (product.notes != null && product.notes!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.amber.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.amber.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.note, size: 16, color: Colors.amber),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              product.notes!,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF6B7280),
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final crossAxisCount = _getCrossAxisCount(context);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF8F9FF), Color(0xFFFFFFFF)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Modern Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF6366F1).withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.categoryName != null
                                ? 'Barang ${widget.categoryName}'
                                : 'Kelola Barang',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.categoryName != null
                                ? 'Produk dalam kategori ini'
                                : 'Manage your products here',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${_products.length}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Search Bar
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Cari barang...',
                    hintStyle: TextStyle(color: Colors.grey[400]),
                    prefixIcon: const Icon(
                      Icons.search,
                      color: Color(0xFF6366F1),
                    ),
                    suffixIcon:
                        _searchController.text.isNotEmpty
                            ? IconButton(
                              icon: const Icon(
                                Icons.clear,
                                color: Color(0xFF6366F1),
                              ),
                              onPressed: () {
                                _searchController.clear();
                              },
                            )
                            : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF6366F1)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Color(0xFF6366F1),
                        width: 2,
                      ),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                ),
              ),
              // Content
              Expanded(
                child:
                    _isLoading
                        ? const Center(
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Color(0xFF6366F1),
                            ),
                          ),
                        )
                        : _products.isEmpty
                        ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      const Color(0xFF6366F1).withOpacity(0.1),
                                      const Color(0xFF8B5CF6).withOpacity(0.1),
                                    ],
                                  ),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.inventory_2_outlined,
                                  size: 80,
                                  color: Colors.grey[400],
                                ),
                              ),
                              const SizedBox(height: 24),
                              Text(
                                'Belum ada barang',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[700],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Tap tombol + untuk menambah barang',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[500],
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
                              Container(
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      const Color(0xFF6366F1).withOpacity(0.1),
                                      const Color(0xFF8B5CF6).withOpacity(0.1),
                                    ],
                                  ),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.search_off,
                                  size: 80,
                                  color: Colors.grey[400],
                                ),
                              ),
                              const SizedBox(height: 24),
                              Text(
                                'Tidak ada hasil pencarian',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[700],
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
                        : crossAxisCount == 1
                        ? ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _filteredProducts.length,
                          itemBuilder: (context, index) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: _buildProductCard(
                                _filteredProducts[index],
                              ),
                            );
                          },
                        )
                        : GridView.builder(
                          padding: const EdgeInsets.all(16),
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 4,
                                crossAxisSpacing: 16,
                                mainAxisSpacing: 16,
                                childAspectRatio: 1.1,
                              ),
                          itemCount: _filteredProducts.length,
                          itemBuilder: (context, index) {
                            return _buildProductCard(_filteredProducts[index]);
                          },
                        ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showProductDialog(),
        tooltip: 'Tambah Barang',
        backgroundColor: const Color(0xFF6366F1),
        icon: const Icon(Icons.add),
        label: const Text('Tambah Barang'),
      ),
    );
  }
}
