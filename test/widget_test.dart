import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tubes_anpundung_707012400023/cubit/bookmark_cubit.dart';
import 'package:tubes_anpundung_707012400023/cubit/laporan_cubit.dart';
import 'package:tubes_anpundung_707012400023/cubit/theme_cubit.dart';
import 'package:tubes_anpundung_707012400023/models/laporan_item.dart';
import 'package:tubes_anpundung_707012400023/main.dart';

void main() {
  group('Model LaporanItem SQLite Serialization Tests', () {
    test('toMap dan fromMap menghasilkan data yang identik dan konsisten', () {
      const original = LaporanItem(
        id: 'AP-BDG-2026-999',
        judul: 'Pungli Parkir Stasiun Bandung',
        kategori: 'Parkir Liar',
        lokasi: 'Jl. Stasiun Barat, Andir',
        terlapor: 'Oknum Jukir Liar',
        nominal: 'Rp 10.000',
        tanggal: '21 Nov 2026',
        status: 'Investigasi',
        deskripsi: 'Dipaksa bayar parkir tanpa karcis resmi',
        tindakLanjut: 'Sedang diverifikasi oleh Satgas Dishub',
        isAnonim: true,
      );

      final map = original.toMap();
      expect(map['id'], 'AP-BDG-2026-999');
      expect(map['judul'], 'Pungli Parkir Stasiun Bandung');
      expect(map['kategori'], 'Parkir Liar');
      expect(map['lokasi'], 'Jl. Stasiun Barat, Andir');
      expect(map['terlapor'], 'Oknum Jukir Liar');
      expect(map['nominal'], 'Rp 10.000');
      expect(map['tanggal'], '21 Nov 2026');
      expect(map['status'], 'Investigasi');
      expect(map['deskripsi'], 'Dipaksa bayar parkir tanpa karcis resmi');
      expect(map['tindak_lanjut'], 'Sedang diverifikasi oleh Satgas Dishub');
      expect(map['is_anonim'], 1); // Boolean ke Integer 1 untuk SQLite

      final restored = LaporanItem.fromMap(map);
      expect(restored.id, original.id);
      expect(restored.judul, original.judul);
      expect(restored.kategori, original.kategori);
      expect(restored.lokasi, original.lokasi);
      expect(restored.terlapor, original.terlapor);
      expect(restored.nominal, original.nominal);
      expect(restored.tanggal, original.tanggal);
      expect(restored.status, original.status);
      expect(restored.deskripsi, original.deskripsi);
      expect(restored.tindakLanjut, original.tindakLanjut);
      expect(restored.isAnonim, isTrue);
    });

    test('is_anonim = 0 dipetakan menjadi isAnonim = false', () {
      final map = {
        'id': 'AP-01',
        'judul': 'Pungli Kelurahan',
        'kategori': 'Kelurahan & Izin',
        'lokasi': 'Bandung',
        'terlapor': 'Oknum',
        'nominal': 'Rp 50.000',
        'tanggal': '21 Nov 2026',
        'status': 'Investigasi',
        'deskripsi': 'Pungli izin',
        'tindak_lanjut': 'Proses',
        'is_anonim': 0,
      };

      final item = LaporanItem.fromMap(map);
      expect(item.isAnonim, isFalse);
    });
  });

  group('Unit Test Cubit Anpundung', () {
    test(
        'LaporanCubit unit test - tambah, ubah (update), dan hapus (delete) laporan',
        () async {
      final cubit = LaporanCubit();
      expect(cubit.state.totalLaporan, 4);
      expect(cubit.state.totalInvestigasi, 1);
      expect(cubit.state.totalDitindak, 2);

      // 1. CREATE: Tambah laporan
      await cubit.tambahLaporan(
        judul: 'Pungli Parkir Dago',
        kategori: 'Parkir Liar',
        lokasi: 'Jl. Ir. H. Juanda',
        terlapor: 'Oknum Jukir',
        nominal: 'Rp 10.000',
        deskripsi: 'Memaksa tanpa karcis resmi',
      );

      expect(cubit.state.totalLaporan, 5);
      expect(cubit.state.totalInvestigasi, 2);
      expect(cubit.state.daftarLaporan.first.judul, 'Pungli Parkir Dago');

      final laporanBaru = cubit.state.daftarLaporan.first;

      // 2. UPDATE: Ubah nominal dan deskripsi laporan
      final laporanDiupdate = laporanBaru.copyWith(
        nominal: 'Rp 25.000',
        deskripsi: 'Revisi: Oknum meminta tambahan uang keamanan',
      );
      await cubit.ubahLaporan(laporanDiupdate);

      final laporanTerkoreksi = cubit.state.daftarLaporan.first;
      expect(laporanTerkoreksi.nominal, 'Rp 25.000');
      expect(laporanTerkoreksi.deskripsi,
          'Revisi: Oknum meminta tambahan uang keamanan');

      // 3. DELETE: Hapus laporan
      await cubit.hapusLaporan(laporanBaru.id);
      expect(cubit.state.totalLaporan, 4);
    });

    test('BookmarkTitikRawanCubit unit test - toggle pantau lokasi', () {
      final cubit = BookmarkTitikRawanCubit();
      expect(cubit.isDipantau('TR-BDG-01'), isTrue);

      cubit.toggleBookmark('TR-BDG-02');
      expect(cubit.isDipantau('TR-BDG-02'), isTrue);

      cubit.toggleBookmark('TR-BDG-02');
      expect(cubit.isDipantau('TR-BDG-02'), isFalse);
    });

    test('ThemeCubit unit test - toggle and setDarkMode', () {
      final cubit = ThemeCubit();
      expect(cubit.state, ThemeMode.light);

      cubit.toggle();
      expect(cubit.state, ThemeMode.dark);

      cubit.toggle();
      expect(cubit.state, ThemeMode.light);

      cubit.setDarkMode(true);
      expect(cubit.state, ThemeMode.dark);

      cubit.setDarkMode(false);
      expect(cubit.state, ThemeMode.light);
    });
  });

  testWidgets(
      'Uji Integrasi State Management LaporanCubit dan Form Buat Laporan', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2280);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const AnpundungApp());
    await tester.pumpAndSettle();

    // 1. Verifikasi Beranda dan data awal
    expect(find.text('Anpundung Mobile'), findsOneWidget);
    expect(find.textContaining('Ghazy Nabil Alghfari'), findsWidgets);
    expect(find.text('Total Laporan'), findsOneWidget);
    expect(find.text('4'), findsWidgets); // 4 laporan awal

    // 2. Buka Halaman Buat Laporan via icon tambah di AppBar
    await tester.tap(find.byIcon(Icons.add_alert_rounded));
    await tester.pumpAndSettle();

    expect(find.text('Buat Laporan Pungli'), findsOneWidget);
    expect(find.text('Kirim Laporan Pungli'), findsOneWidget);

    // 3. Isi formulir dengan ensureVisible
    final judulField = find.widgetWithText(
        TextFormField, 'Contoh: Getok tarif parkir motor depan Mall BEC');
    await tester.ensureVisible(judulField);
    await tester.enterText(judulField, 'Pungli Parkir Cihampelas Rp 15.000');

    final lokasiField = find.widgetWithText(
        TextFormField, 'Contoh: Jl. Purnawarman No. 13, Bandung Wetan');
    await tester.ensureVisible(lokasiField);
    await tester.enterText(lokasiField, 'Jl. Cihampelas No. 45, Bandung');

    final deskripsiField = find.widgetWithText(TextFormField,
        'Tuliskan detail kronologi, waktu kejadian, dan tindakan pemaksaan...');
    await tester.ensureVisible(deskripsiField);
    await tester.enterText(
      deskripsiField,
      'Jukir memaksa pengendara motor membayar Rp 15.000 tanpa tiket parkir resmi.',
    );

    // 4. Tekan tombol submit
    final submitButton = find.text('Kirim Laporan Pungli');
    await tester.ensureVisible(submitButton);
    await tester.tap(submitButton);
    await tester.pump(); // Memicu setState lokal

    // Verifikasi state lokal _sedangMengirim: indikator loading & label berubah
    expect(find.text('Sedang Mengirim Laporan...'), findsOneWidget);

    // Lewati durasi delay simulasi pengiriman (1200 ms)
    await tester.pump(const Duration(milliseconds: 1300));
    await tester.pumpAndSettle();

    // Kembali ke Beranda
    expect(find.text('Anpundung Mobile'), findsOneWidget);

    // Verifikasi counter bertambah menjadi 5
    expect(find.text('5'), findsWidgets);
    expect(find.text('Pungli Parkir Cihampelas Rp 15.000'), findsOneWidget);

    // 5. Pindah ke Tab Profil & Aduan Warga
    await tester.tap(find.byIcon(Icons.person_outline_rounded));
    await tester.pumpAndSettle();

    expect(find.text('Profil & Aduan Warga'), findsOneWidget);
    expect(find.text('Titik Rawan Dipantau'), findsOneWidget);

    // 6. Uji SwitchListTile Dark Mode di Halaman Profil
    final switchFinder = find.byType(Switch);
    expect(switchFinder, findsOneWidget);

    // Cek tema awal adalah light
    var app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.themeMode, ThemeMode.light);

    // Tap switch untuk mengaktifkan Dark Mode
    await tester.tap(switchFinder);
    await tester.pumpAndSettle();

    // Verifikasi tema berubah menjadi dark
    app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.themeMode, ThemeMode.dark);
    expect(find.text('Mode malam aktif: antarmuka ramah mata di malam hari'),
        findsOneWidget);
  });

  testWidgets('Uji Tampilan Adaptif Layar Lebar NavigationRail', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(2280, 1080);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const AnpundungApp());
    await tester.pumpAndSettle();

    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
  });
}
