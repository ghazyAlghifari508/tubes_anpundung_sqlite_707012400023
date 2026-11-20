import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/laporan_cubit.dart';
import '../models/laporan_item.dart';
import '../navigation/app_routes.dart';

/// Halaman Riwayat Laporan Pengaduan
/// Mengimplementasikan pembacaan data permanen dari SQLite (Read),
/// pembaruan isi laporan (Update dengan parameterized query),
/// dan penghapusan data (Delete via Dismissible swipe & tombol konfirmasi dialog).
/// Pengembang: Ghazy Nabil Alghfari (NIM: 707012400023 | D4SIKC Telkom University)
class HalamanRiwayatLaporan extends StatelessWidget {
  const HalamanRiwayatLaporan({super.key});

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Investigasi':
        return Colors.orange.shade800;
      case 'Verifikasi':
        return Colors.blue.shade700;
      case 'Selesai':
        return Colors.green.shade700;
      default:
        return const Color(0xFF1E56A0);
    }
  }

  void _tampilkanDialogEdit(BuildContext context, LaporanItem item) {
    final nominalController = TextEditingController(text: item.nominal);
    final deskripsiController = TextEditingController(text: item.deskripsi);
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              const Icon(Icons.edit_note_rounded, color: Color(0xFF163172)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Koreksi Laporan (${item.id})',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF163172),
                  ),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Perbarui data nominal atau kronologi laporan pada database SQLite lokal:',
                    style: TextStyle(fontSize: 12, color: Colors.black87),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: nominalController,
                    decoration: const InputDecoration(
                      labelText: 'Nominal Pungutan',
                      prefixIcon: Icon(Icons.payments_outlined),
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Wajib diisi' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: deskripsiController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Deskripsi / Kronologi Kejadian',
                      prefixIcon: Icon(Icons.description_outlined),
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Wajib diisi' : null,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Batal'),
            ),
            FilledButton.icon(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  final itemDiubah = item.copyWith(
                    nominal: nominalController.text.trim(),
                    deskripsi: deskripsiController.text.trim(),
                  );
                  context.read<LaporanCubit>().ubahLaporan(itemDiubah);
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Laporan "${item.id}" berhasil diperbarui di basis data SQLite lokal!',
                      ),
                      backgroundColor: const Color(0xFF163172),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
              icon: const Icon(Icons.save_rounded, size: 18),
              label: const Text('Simpan Perubahan'),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF163172),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _konfirmasiHapus(BuildContext context, LaporanItem item) async {
    final setuju = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Row(
          children: [
            Icon(Icons.delete_forever_rounded, color: Colors.red),
            SizedBox(width: 8),
            Expanded(
              child: Text('Hapus Laporan SQLite'),
            ),
          ],
        ),
        content: Text(
          'Apakah Anda yakin ingin menghapus laporan "${item.judul}" secara permanen dari basis data SQLite lokal?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red.shade700,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus Permanen'),
          ),
        ],
      ),
    );

    if (setuju == true && context.mounted) {
      context.read<LaporanCubit>().hapusLaporan(item.id);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Laporan "${item.judul}" telah dihapus dari database.'),
          backgroundColor: const Color(0xFF163172),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      appBar: AppBar(
        title: BlocBuilder<LaporanCubit, LaporanState>(
          builder: (context, state) {
            return Text('Riwayat Laporan (${state.totalLaporan})');
          },
        ),
        backgroundColor: const Color(0xFF163172),
        foregroundColor: Colors.white,
      ),
      body: BlocBuilder<LaporanCubit, LaporanState>(
        builder: (context, state) {
          final riwayat = state.daftarLaporan;

          final theme = Theme.of(context);
          final isDark = theme.brightness == Brightness.dark;

          if (riwayat.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.assignment_late_outlined,
                    size: 64,
                    color: isDark ? Colors.grey.shade600 : Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Belum Ada Riwayat Laporan',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDark
                          ? const Color(0xFF90CAF9)
                          : const Color(0xFF163172),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Gunakan tombol "Lapor Kilat" di bawah untuk melaporkan pungli.',
                    style: TextStyle(
                      fontSize: 12,
                      color:
                          isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              await context.read<LaporanCubit>().muatLaporan();
            },
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
              itemCount: riwayat.length,
              itemBuilder: (context, index) {
                final item = riwayat[index];
                final statusColor = _getStatusColor(item.status);

                return Dismissible(
                  key: Key(item.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    decoration: BoxDecoration(
                      color: Colors.red.shade700,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'HAPUS SQLITE',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                        SizedBox(width: 8),
                        Icon(
                          Icons.delete_forever_rounded,
                          color: Colors.white,
                          size: 26,
                        ),
                      ],
                    ),
                  ),
                  confirmDismiss: (direction) async {
                    return await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        title: const Row(
                          children: [
                            Icon(Icons.delete_forever_rounded,
                                color: Colors.red),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text('Hapus Laporan?'),
                            ),
                          ],
                        ),
                        content: Text(
                          'Geser kartu mendeteksi perintah hapus. Hapus "${item.judul}" dari SQLite?',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: const Text('Batal'),
                          ),
                          FilledButton(
                            style: FilledButton.styleFrom(
                              backgroundColor: Colors.red.shade700,
                            ),
                            onPressed: () => Navigator.pop(ctx, true),
                            child: const Text('Hapus'),
                          ),
                        ],
                      ),
                    );
                  },
                  onDismissed: (direction) {
                    context.read<LaporanCubit>().hapusLaporan(item.id);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Laporan "${item.judul}" berhasil dihapus dari SQLite via gesture swipe.',
                        ),
                        backgroundColor: const Color(0xFF163172),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  child: Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    elevation: 1,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: BorderSide(
                        color: isDark ? Colors.white12 : Colors.grey.shade200,
                      ),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      leading: CircleAvatar(
                        radius: 22,
                        backgroundColor: statusColor.withValues(alpha: 0.15),
                        child: Icon(
                          Icons.shield_outlined,
                          color: statusColor,
                          size: 24,
                        ),
                      ),
                      title: Text(
                        item.judul,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? const Color(0xFF90CAF9)
                              : const Color(0xFF163172),
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text(
                            '${item.id} • ${item.lokasi}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Text(
                                'Pungutan: ${item.nominal}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFE53935),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: statusColor.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  item.status,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: statusColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.edit_outlined,
                              size: 20,
                              color: Color(0xFF163172),
                            ),
                            tooltip: 'Edit / Koreksi Laporan',
                            onPressed: () =>
                                _tampilkanDialogEdit(context, item),
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.delete_outline_rounded,
                              size: 20,
                              color: Colors.red.shade400,
                            ),
                            tooltip: 'Hapus Laporan',
                            onPressed: () => _konfirmasiHapus(context, item),
                          ),
                        ],
                      ),
                      onTap: () {
                        final args = RincianLaporanArguments(
                          idLaporan: item.id,
                          judul: item.judul,
                          kategori: item.kategori,
                          lokasi: item.lokasi,
                          terlapor: item.terlapor,
                          nominal: item.nominal,
                          tanggal: item.tanggal,
                          status: item.status == 'Investigasi'
                              ? 'Sedang Diinvestigasi Satgas'
                              : item.status == 'Verifikasi'
                                  ? 'Tahap Verifikasi Bukti'
                                  : 'Selesai Ditindak Tegas',
                          deskripsi: item.deskripsi,
                          tindakLanjut: item.tindakLanjut,
                        );
                        Navigator.pushNamed(
                          context,
                          AppRoutes.rincianLaporan,
                          arguments: args,
                        );
                      },
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),

      // Floating Action Button CenterDocked
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result =
              await Navigator.pushNamed(context, AppRoutes.buatLaporan);
          if (result != null && context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(result.toString()),
                backgroundColor: const Color(0xFF163172),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
        backgroundColor: const Color(0xFFE53935),
        foregroundColor: Colors.white,
        elevation: 4,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Lapor Kilat'),
      ),

      // BottomAppBar dengan CircularNotchedRectangle
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8.0,
        color: const Color(0xFF163172),
        elevation: 8,
        child: SizedBox(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              IconButton(
                icon:
                    const Icon(Icons.filter_list_rounded, color: Colors.white),
                tooltip: 'Saring Status Aduan',
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content:
                          Text('Filter status aduan diaktifkan (Semua Status)'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.search_rounded, color: Colors.white),
                tooltip: 'Cari Riwayat',
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content:
                          Text('Pencarian riwayat laporan siap digunakan'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              ),
              const SizedBox(width: 48), // Ruang kosong untuk lekukan FAB
              IconButton(
                icon: const Icon(Icons.file_download_rounded,
                    color: Colors.white),
                tooltip: 'Unduh Bukti Tanda Terima',
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content:
                          Text('Bukti tanda terima aduan berhasil diunduh'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.refresh_rounded, color: Colors.white),
                tooltip: 'Segarkan Riwayat',
                onPressed: () {
                  context.read<LaporanCubit>().muatLaporan();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content:
                          Text('Data riwayat aduan SQLite telah disegarkan'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
