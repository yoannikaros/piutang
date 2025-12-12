import 'package:flutter/material.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Kebijakan Privasi'), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Card
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Theme.of(context).colorScheme.primary,
                            Theme.of(context).colorScheme.secondary,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.privacy_tip,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Kebijakan Privasi',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Terakhir diperbarui: Desember 2025',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Introduction
            _buildSection(
              context,
              icon: Icons.info_outline,
              title: 'Pendahuluan',
              content:
                  'Aplikasi Manajemen Piutang ini dirancang untuk membantu Anda mengelola catatan hutang pelanggan secara offline. Kami sangat menghargai privasi Anda dan berkomitmen untuk melindungi data pribadi Anda.',
            ),

            const SizedBox(height: 16),

            // Data Collection
            _buildSection(
              context,
              icon: Icons.folder_outlined,
              title: 'Data yang Kami Kumpulkan',
              content:
                  'Aplikasi ini menyimpan data berikut secara lokal di perangkat Anda:\n\n'
                  '• Informasi pelanggan (nama, nomor telepon, catatan)\n'
                  '• Data transaksi hutang\n'
                  '• Daftar produk dan kategori\n'
                  '• File backup database (jika Anda membuatnya)\n\n'
                  'PENTING: Semua data disimpan secara lokal di perangkat Anda. Kami TIDAK mengumpulkan, mengirim, atau menyimpan data Anda di server manapun.',
              highlight: true,
            ),

            const SizedBox(height: 16),

            // Offline Operation
            _buildSection(
              context,
              icon: Icons.cloud_off,
              title: 'Aplikasi Offline',
              content:
                  'Aplikasi ini sepenuhnya bekerja secara offline dan TIDAK memerlukan koneksi internet. '
                  'Aplikasi ini TIDAK mengirimkan data Anda ke internet atau server eksternal manapun. '
                  'Semua data Anda tetap tersimpan di perangkat Anda sendiri.',
              highlight: true,
            ),

            const SizedBox(height: 16),

            // Data Storage
            _buildSection(
              context,
              icon: Icons.storage,
              title: 'Penyimpanan Data',
              content:
                  'Data Anda disimpan dalam database SQLite lokal di penyimpanan internal perangkat Android Anda. '
                  'Hanya aplikasi ini yang memiliki akses ke database tersebut. Data tidak dapat diakses oleh aplikasi lain tanpa izin Anda.',
            ),

            const SizedBox(height: 16),

            // Backup & Restore
            _buildSection(
              context,
              icon: Icons.backup,
              title: 'Backup dan Restore',
              content:
                  'Aplikasi menyediakan fitur backup dan restore untuk keamanan data Anda:\n\n'
                  '• Backup: Anda dapat menyimpan salinan database ke lokasi pilihan Anda (seperti Google Drive, penyimpanan lokal, dll)\n'
                  '• Restore: Anda dapat mengembalikan data dari file backup yang telah Anda simpan\n\n'
                  'File backup yang Anda buat sepenuhnya berada di bawah kendali Anda. '
                  'Kami menyarankan Anda menyimpan backup di tempat yang aman.',
            ),

            const SizedBox(height: 16),

            // No Third Party
            _buildSection(
              context,
              icon: Icons.block,
              title: 'Tidak Ada Pihak Ketiga',
              content:
                  'Aplikasi ini TIDAK menggunakan:\n\n'
                  '• Layanan analitik pihak ketiga\n'
                  '• Layanan iklan\n'
                  '• Layanan cloud storage\n'
                  '• SDK atau library yang mengirim data ke server eksternal\n\n'
                  'Kami tidak membagikan data Anda dengan pihak ketiga manapun.',
              highlight: true,
            ),

            const SizedBox(height: 16),

            // Permissions
            _buildSection(
              context,
              icon: Icons.security,
              title: 'Izin Aplikasi',
              content:
                  'Aplikasi ini meminta izin berikut:\n\n'
                  '• Penyimpanan: Untuk menyimpan database lokal dan file backup\n\n'
                  'Semua izin digunakan hanya untuk fungsi aplikasi dan tidak untuk tujuan lain.',
            ),

            const SizedBox(height: 16),

            // Data Security
            _buildSection(
              context,
              icon: Icons.lock_outline,
              title: 'Keamanan Data',
              content:
                  'Karena semua data disimpan secara lokal di perangkat Anda, keamanan data bergantung pada:\n\n'
                  '• Keamanan perangkat Anda (PIN, password, biometric)\n'
                  '• Backup berkala yang Anda lakukan\n'
                  '• Penyimpanan backup di tempat yang aman\n\n'
                  'Kami menyarankan Anda untuk:\n'
                  '• Mengaktifkan kunci layar di perangkat Anda\n'
                  '• Membuat backup secara berkala\n'
                  '• Menyimpan file backup di lokasi yang aman',
            ),

            const SizedBox(height: 16),

            // Data Deletion
            _buildSection(
              context,
              icon: Icons.delete_outline,
              title: 'Penghapusan Data',
              content:
                  'Anda memiliki kontrol penuh atas data Anda:\n\n'
                  '• Anda dapat menghapus data individual dalam aplikasi\n'
                  '• Anda dapat menghapus semua data dengan menghapus aplikasi (uninstall)\n'
                  '• Menghapus aplikasi akan menghapus semua data lokal secara permanen\n\n'
                  'Pastikan Anda telah membuat backup sebelum menghapus aplikasi jika Anda ingin menyimpan data.',
            ),

            const SizedBox(height: 16),

            // Free and Open
            _buildSection(
              context,
              icon: Icons.volunteer_activism,
              title: 'Aplikasi Gratis',
              content:
                  'Aplikasi ini disediakan secara GRATIS untuk digunakan oleh siapa saja. '
                  'Tidak ada biaya tersembunyi, tidak ada pembelian dalam aplikasi, dan tidak ada iklan.',
            ),

            const SizedBox(height: 16),

            // Children Privacy
            _buildSection(
              context,
              icon: Icons.child_care,
              title: 'Privasi Anak',
              content:
                  'Aplikasi ini tidak secara khusus menargetkan anak-anak di bawah usia 13 tahun. '
                  'Karena aplikasi tidak mengumpulkan data apapun, tidak ada risiko privasi terhadap pengguna dari segala usia.',
            ),

            const SizedBox(height: 16),

            // Policy Changes
            _buildSection(
              context,
              icon: Icons.update,
              title: 'Perubahan Kebijakan',
              content:
                  'Kami dapat memperbarui Kebijakan Privasi ini dari waktu ke waktu. '
                  'Perubahan akan ditampilkan di halaman ini dengan tanggal "Terakhir diperbarui" yang baru. '
                  'Kami menyarankan Anda untuk meninjau halaman ini secara berkala.',
            ),

            const SizedBox(height: 16),

            // Contact
            _buildSection(
              context,
              icon: Icons.contact_mail,
              title: 'Hubungi Kami',
              content:
                  'Jika Anda memiliki pertanyaan tentang Kebijakan Privasi ini atau praktik privasi aplikasi, '
                  'silakan hubungi kami melalui halaman aplikasi di Google Play Store.',
            ),

            const SizedBox(height: 24),

            // Footer Note
            Card(
              color: Colors.green[50],
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Colors.green[200]!),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.verified_user,
                      color: Colors.green[700],
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Komitmen Kami',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.green[900],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Kami berkomitmen untuk tidak mengumpulkan, menyimpan, atau membagikan data pribadi Anda. '
                            'Aplikasi ini sepenuhnya offline dan semua data Anda tetap di perangkat Anda.',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.green[800],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String content,
    bool highlight = false,
  }) {
    return Card(
      elevation: highlight ? 2 : 1,
      color: highlight ? Colors.blue[50] : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side:
            highlight ? BorderSide(color: Colors.blue[200]!) : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  color:
                      highlight
                          ? Colors.blue[700]
                          : Theme.of(context).colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: highlight ? Colors.blue[900] : null,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              content,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: highlight ? Colors.blue[800] : Colors.grey[700],
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
