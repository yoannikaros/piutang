import 'package:sqflite/sqflite.dart' as sqflite;
import 'package:path/path.dart';
import '../models/customer.dart';
import '../models/product.dart';
import '../models/category.dart';
import '../models/transaction.dart';
import '../models/transaction_line.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static sqflite.Database? _database;

  DatabaseHelper._init();

  Future<sqflite.Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('piutang.db');
    return _database!;
  }

  Future<sqflite.Database> _initDB(String filePath) async {
    final dbPath = await sqflite.getDatabasesPath();
    final path = join(dbPath, filePath);

    return await sqflite.openDatabase(
      path,
      version: 4,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
    );
  }

  Future<void> _createDB(sqflite.Database db, int version) async {
    // Create customers table
    await db.execute('''
      CREATE TABLE customers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        phone TEXT,
        notes TEXT,
        created_at TEXT NOT NULL DEFAULT (datetime('now')),
        is_active INTEGER NOT NULL DEFAULT 1
      )
    ''');

    // Create categories table
    await db.execute('''
      CREATE TABLE categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE,
        description TEXT,
        icon_code INTEGER,
        color TEXT,
        created_at TEXT NOT NULL DEFAULT (datetime('now')),
        is_active INTEGER NOT NULL DEFAULT 1
      )
    ''');

    // Create products table
    await db.execute('''
      CREATE TABLE products (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE,
        price NUMERIC NOT NULL,
        unit TEXT,
        notes TEXT,
        category_id INTEGER,
        created_at TEXT NOT NULL DEFAULT (datetime('now')),
        is_active INTEGER NOT NULL DEFAULT 1,
        FOREIGN KEY(category_id) REFERENCES categories(id) ON DELETE SET NULL
      )
    ''');

    // Create transactions table
    await db.execute('''
      CREATE TABLE transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        customer_id INTEGER NOT NULL,
        taken_at TEXT NOT NULL DEFAULT (datetime('now')),
        notes TEXT,
        is_reset INTEGER NOT NULL DEFAULT 0,
        reset_at TEXT,
        FOREIGN KEY(customer_id) REFERENCES customers(id) ON DELETE CASCADE
      )
    ''');

    // Create transaction_lines table
    await db.execute('''
      CREATE TABLE transaction_lines (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        transaction_id INTEGER NOT NULL,
        product_id INTEGER NOT NULL,
        quantity INTEGER NOT NULL DEFAULT 1,
        unit_price NUMERIC NOT NULL,
        line_total NUMERIC NOT NULL,
        notes TEXT,
        created_at TEXT NOT NULL DEFAULT (datetime('now')),
        FOREIGN KEY(transaction_id) REFERENCES transactions(id) ON DELETE CASCADE,
        FOREIGN KEY(product_id) REFERENCES products(id) ON DELETE RESTRICT
      )
    ''');
  }

  Future<void> _upgradeDB(
    sqflite.Database db,
    int oldVersion,
    int newVersion,
  ) async {
    if (oldVersion < 2) {
      // Add categories table
      await db.execute('''
        CREATE TABLE categories (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL UNIQUE,
          description TEXT,
          icon_code INTEGER,
          color TEXT,
          created_at TEXT NOT NULL DEFAULT (datetime('now')),
          is_active INTEGER NOT NULL DEFAULT 1
        )
      ''');

      // Add category_id column to products table
      await db.execute('''
        ALTER TABLE products ADD COLUMN category_id INTEGER REFERENCES categories(id) ON DELETE SET NULL
      ''');
    }

    if (oldVersion < 4) {
      // Add created_at column to transaction_lines table
      await db.execute('''
        ALTER TABLE transaction_lines ADD COLUMN created_at TEXT NOT NULL DEFAULT (datetime('now'))
      ''');
    }
  }

  // ==================== CUSTOMER OPERATIONS ====================

  Future<int> insertCustomer(Customer customer) async {
    final db = await database;
    return await db.insert('customers', customer.toMap());
  }

  Future<List<Customer>> getAllCustomers() async {
    final db = await database;

    // Get customers with their total debt
    final result = await db.rawQuery('''
      SELECT 
        c.*,
        COALESCE(SUM(CASE WHEN t.is_reset = 0 THEN tl.line_total ELSE 0 END), 0) as total_debt
      FROM customers c
      LEFT JOIN transactions t ON c.id = t.customer_id
      LEFT JOIN transaction_lines tl ON t.id = tl.transaction_id
      WHERE c.is_active = 1
      GROUP BY c.id
      ORDER BY c.name ASC
    ''');

    return result.map((map) => Customer.fromMap(map)).toList();
  }

  Future<Customer?> getCustomer(int id) async {
    final db = await database;

    final result = await db.rawQuery(
      '''
      SELECT 
        c.*,
        COALESCE(SUM(CASE WHEN t.is_reset = 0 THEN tl.line_total ELSE 0 END), 0) as total_debt
      FROM customers c
      LEFT JOIN transactions t ON c.id = t.customer_id
      LEFT JOIN transaction_lines tl ON t.id = tl.transaction_id
      WHERE c.id = ? AND c.is_active = 1
      GROUP BY c.id
    ''',
      [id],
    );

    if (result.isNotEmpty) {
      return Customer.fromMap(result.first);
    }
    return null;
  }

  Future<int> updateCustomer(Customer customer) async {
    final db = await database;
    return await db.update(
      'customers',
      customer.toMap(),
      where: 'id = ?',
      whereArgs: [customer.id],
    );
  }

  Future<int> deleteCustomer(int id) async {
    final db = await database;
    // Soft delete
    return await db.update(
      'customers',
      {'is_active': 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ==================== PRODUCT OPERATIONS ====================

  Future<int> insertProduct(Product product) async {
    final db = await database;
    return await db.insert('products', product.toMap());
  }

  Future<List<Product>> getAllProducts() async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT 
        p.*,
        c.name as category_name
      FROM products p
      LEFT JOIN categories c ON p.category_id = c.id
      WHERE p.is_active = 1
      ORDER BY p.name ASC
    ''');
    return result.map((map) => Product.fromMap(map)).toList();
  }

  Future<Product?> getProduct(int id) async {
    final db = await database;
    final result = await db.query(
      'products',
      where: 'id = ? AND is_active = ?',
      whereArgs: [id, 1],
    );
    if (result.isNotEmpty) {
      return Product.fromMap(result.first);
    }
    return null;
  }

  Future<int> updateProduct(Product product) async {
    final db = await database;
    return await db.update(
      'products',
      product.toMap(),
      where: 'id = ?',
      whereArgs: [product.id],
    );
  }

  Future<int> deleteProduct(int id) async {
    final db = await database;
    // Soft delete
    return await db.update(
      'products',
      {'is_active': 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ==================== CATEGORY OPERATIONS ====================

  Future<int> insertCategory(Category category) async {
    final db = await database;
    return await db.insert('categories', category.toMap());
  }

  Future<List<Category>> getAllCategories() async {
    final db = await database;
    final result = await db.query(
      'categories',
      where: 'is_active = ?',
      whereArgs: [1],
      orderBy: 'name ASC',
    );
    return result.map((map) => Category.fromMap(map)).toList();
  }

  Future<Category?> getCategory(int id) async {
    final db = await database;
    final result = await db.query(
      'categories',
      where: 'id = ? AND is_active = ?',
      whereArgs: [id, 1],
    );
    if (result.isNotEmpty) {
      return Category.fromMap(result.first);
    }
    return null;
  }

  Future<int> updateCategory(Category category) async {
    final db = await database;
    return await db.update(
      'categories',
      category.toMap(),
      where: 'id = ?',
      whereArgs: [category.id],
    );
  }

  Future<int> deleteCategory(int id) async {
    final db = await database;
    // Check if any products use this category
    final productCount = sqflite.Sqflite.firstIntValue(
      await db.rawQuery(
        'SELECT COUNT(*) FROM products WHERE category_id = ? AND is_active = 1',
        [id],
      ),
    );

    if (productCount != null && productCount > 0) {
      throw Exception(
        'Tidak dapat menghapus kategori yang masih digunakan oleh $productCount produk',
      );
    }

    // Soft delete
    return await db.update(
      'categories',
      {'is_active': 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> getCategoryProductCount(int categoryId) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM products WHERE category_id = ? AND is_active = 1',
      [categoryId],
    );
    return sqflite.Sqflite.firstIntValue(result) ?? 0;
  }

  // ==================== TRANSACTION OPERATIONS ====================

  Future<int> insertTransaction(Transaction transaction) async {
    final db = await database;

    // Insert transaction and its lines in a single transaction
    return await db.transaction((txn) async {
      // Insert the transaction
      final transactionId = await txn.insert(
        'transactions',
        transaction.toMap(),
      );

      // Insert all transaction lines
      for (var line in transaction.lines) {
        await txn.insert(
          'transaction_lines',
          line.copyWith(transactionId: transactionId).toMap(),
        );
      }

      return transactionId;
    });
  }

  Future<List<Transaction>> getCustomerTransactions(int customerId) async {
    final db = await database;

    // Get all transactions for a customer
    final transactionMaps = await db.query(
      'transactions',
      where: 'customer_id = ?',
      whereArgs: [customerId],
      orderBy: 'taken_at DESC',
    );

    List<Transaction> transactions = [];

    for (var txnMap in transactionMaps) {
      // Get lines for this transaction with product details
      final lineMaps = await db.rawQuery(
        '''
        SELECT 
          tl.*,
          p.name as product_name,
          p.unit as product_unit
        FROM transaction_lines tl
        JOIN products p ON tl.product_id = p.id
        WHERE tl.transaction_id = ?
        ORDER BY tl.created_at ASC, tl.id ASC
      ''',
        [txnMap['id']],
      );

      final lines =
          lineMaps.map((map) => TransactionLine.fromMap(map)).toList();
      transactions.add(Transaction.fromMap(txnMap, lines: lines));
    }

    return transactions;
  }

  Future<int> updateTransaction(Transaction transaction) async {
    final db = await database;
    return await db.update(
      'transactions',
      transaction.toMap(),
      where: 'id = ?',
      whereArgs: [transaction.id],
    );
  }

  Future<Transaction?> getTransaction(int transactionId) async {
    final db = await database;

    // Get the transaction
    final transactionMaps = await db.query(
      'transactions',
      where: 'id = ?',
      whereArgs: [transactionId],
    );

    if (transactionMaps.isEmpty) return null;

    // Get lines for this transaction with product details
    final lineMaps = await db.rawQuery(
      '''
      SELECT 
        tl.*,
        p.name as product_name,
        p.unit as product_unit
      FROM transaction_lines tl
      JOIN products p ON tl.product_id = p.id
      WHERE tl.transaction_id = ?
      ORDER BY tl.created_at ASC, tl.id ASC
    ''',
      [transactionId],
    );

    final lines = lineMaps.map((map) => TransactionLine.fromMap(map)).toList();
    return Transaction.fromMap(transactionMaps.first, lines: lines);
  }

  Future<void> addItemsToTransaction(
    int transactionId,
    List<TransactionLine> newLines,
  ) async {
    final db = await database;

    // Add all new transaction lines
    await db.transaction((txn) async {
      for (var line in newLines) {
        await txn.insert(
          'transaction_lines',
          line.copyWith(transactionId: transactionId).toMap(),
        );
      }
    });
  }

  Future<int> resetCustomerDebt(int customerId) async {
    final db = await database;

    // Mark all unpaid transactions as reset
    return await db.update(
      'transactions',
      {'is_reset': 1, 'reset_at': DateTime.now().toIso8601String()},
      where: 'customer_id = ? AND is_reset = 0',
      whereArgs: [customerId],
    );
  }

  // ==================== UTILITY ====================

  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}
