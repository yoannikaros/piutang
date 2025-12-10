import 'package:flutter/material.dart';
import 'customer_management_page.dart';
import 'product_management_page.dart';
import 'category_management_page.dart';

class ManagementMenuPage extends StatelessWidget {
  const ManagementMenuPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width > 600;

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
                    isTablet
                        ? _buildTabletLayout(context)
                        : _buildMobileLayout(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
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
                  'Kelola Data',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Manajemen konsumen dan barang',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildMenuCard(
            context,
            icon: Icons.people_rounded,
            title: 'Kelola Konsumen',
            subtitle: 'Tambah, edit, atau hapus konsumen',
            gradient: [Colors.blue[400]!, Colors.blue[600]!],
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CustomerManagementPage(),
                ),
              );
            },
          ),
          // const SizedBox(height: 20),
          // _buildMenuCard(
          //   context,
          //   icon: Icons.inventory_2_rounded,
          //   title: 'Kelola Barang',
          //   subtitle: 'Tambah, edit, atau hapus barang',
          //   gradient: [Colors.green[400]!, Colors.green[600]!],
          //   onTap: () {
          //     Navigator.push(
          //       context,
          //       MaterialPageRoute(
          //         builder: (context) => const ProductManagementPage(),
          //       ),
          //     );
          //   },
          // ),
          const SizedBox(height: 20),
          _buildMenuCard(
            context,
            icon: Icons.category_rounded,
            title: 'Kelola Kategori',
            subtitle: 'Tambah, edit, atau hapus kategori',
            gradient: [Colors.purple[400]!, Colors.purple[600]!],
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CategoryManagementPage(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTabletLayout(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          Expanded(
            child: _buildMenuCard(
              context,
              icon: Icons.people_rounded,
              title: 'Kelola Konsumen',
              subtitle: 'Tambah, edit, atau hapus konsumen',
              gradient: [Colors.blue[400]!, Colors.blue[600]!],
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CustomerManagementPage(),
                  ),
                );
              },
            ),
          ),
          const SizedBox(width: 20),
          // Expanded(
          //   child: _buildMenuCard(
          //     context,
          //     icon: Icons.inventory_2_rounded,
          //     title: 'Kelola Barang',
          //     subtitle: 'Tambah, edit, atau hapus barang',
          //     gradient: [Colors.green[400]!, Colors.green[600]!],
          //     onTap: () {
          //       Navigator.push(
          //         context,
          //         MaterialPageRoute(
          //           builder: (context) => const ProductManagementPage(),
          //         ),
          //       );
          //     },
          //   ),
          // ),
          // const SizedBox(width: 20),
          Expanded(
            child: _buildMenuCard(
              context,
              icon: Icons.category_rounded,
              title: 'Kelola Kategori',
              subtitle: 'Tambah, edit, atau hapus kategori',
              gradient: [Colors.purple[400]!, Colors.purple[600]!],
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CategoryManagementPage(),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required List<Color> gradient,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: gradient),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: gradient[0].withValues(alpha: 0.4),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Icon(icon, size: 48, color: Colors.white),
              ),
              const SizedBox(height: 24),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: gradient),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Buka',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(width: 8),
                    Icon(Icons.arrow_forward, color: Colors.white, size: 18),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
