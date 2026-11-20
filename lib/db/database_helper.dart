import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/laporan_item.dart';

/// Helper singleton SQLite untuk mengelola basis data pengaduan pungli Anpundung Bandung
/// Mengimplementasikan skema tabel permanen laporan_pungli dengan operasi CRUD lengkap.
/// Pengembang: Ghazy Nabil Alghfari (NIM: 707012400023 | D4SIKC Telkom University)
class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  static const String tableLaporan = 'laporan_pungli';

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('anpundung_bandung.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    // 1. Buat tabel laporan_pungli dengan primary key id TEXT
    await db.execute('''
      CREATE TABLE $tableLaporan (
        id TEXT PRIMARY KEY,
        judul TEXT NOT NULL,
        kategori TEXT NOT NULL,
        lokasi TEXT NOT NULL,
        terlapor TEXT NOT NULL,
        nominal TEXT NOT NULL,
        tanggal TEXT NOT NULL,
        status TEXT NOT NULL,
        deskripsi TEXT NOT NULL,
        tindak_lanjut TEXT NOT NULL,
        is_anonim INTEGER NOT NULL
      )
    ''');

    // 2. Pre-seed data pengaduan awal Kota Bandung
    for (final item in _seedDataAwal) {
      await db.insert(tableLaporan, item.toMap());
    }
  }

  // ================= CRUD OPERATIONS =================

  /// CREATE: Menambahkan laporan baru ke SQLite
  Future<int> insertLaporan(LaporanItem item) async {
    final db = await database;
    return await db.insert(
      tableLaporan,
      item.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// READ: Mengambil seluruh riwayat laporan terurut dari ID / waktu terbaru
  Future<List<LaporanItem>> getAllLaporan() async {
    final db = await database;
    final result = await db.query(
      tableLaporan,
      orderBy: 'id DESC',
    );
    return result.map((map) => LaporanItem.fromMap(map)).toList();
  }

  /// READ BY ID: Mengambil satu laporan berdasarkan ID
  Future<LaporanItem?> getLaporanById(String id) async {
    final db = await database;
    final result = await db.query(
      tableLaporan,
      where: 'id = ?',
      whereArgs: [id],
    );
    if (result.isNotEmpty) {
      return LaporanItem.fromMap(result.first);
    }
    return null;
  }

  /// UPDATE: Memperbarui isi laporan menggunakan parameterized query aman
  Future<int> updateLaporan(LaporanItem item) async {
    final db = await database;
    return await db.update(
      tableLaporan,
      item.toMap(),
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  /// DELETE: Menghapus laporan berdasarkan ID menggunakan parameterized query
  Future<int> deleteLaporan(String id) async {
    final db = await database;
    return await db.delete(
      tableLaporan,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Mengosongkan seluruh tabel laporan
  Future<int> clearAll() async {
    final db = await database;
    return await db.delete(tableLaporan);
  }

  /// Menutup koneksi database
  Future<void> close() async {
    final db = await database;
    _database = null;
    await db.close();
  }

  // ================= SEED DATA AWAL =================
  static final List<LaporanItem> _seedDataAwal = [
    const LaporanItem(
      id: 'AP-BDG-2026-081',
      judul: 'Pungli Tarif Parkir Getok Asia Afrika',
      kategori: 'Parkir Liar',
      lokasi: 'Jl. Asia Afrika (Dekat Gedung Merdeka), Bandung',
      terlapor: 'Oknum Jukir Liar Tanpa Karcis',
      nominal: 'Rp 20.000 (Mobil)',
      tanggal: '24 Sep 2026',
      status: 'Investigasi',
      deskripsi:
          'Pengendara dipaksa membayar tarif parkir mobil Rp 20.000 tanpa karcis resmi. Saat ditanya karcis Dishub, oknum bertindak intimidatif.',
      tindakLanjut:
          'Tim Saber Pungli Polrestabes Bandung dan Dishub telah mengamankan 2 jukir liar untuk pembinaan dan sanksi tindak pidana ringan.',
      isAnonim: true,
    ),
    const LaporanItem(
      id: 'AP-BDG-2026-079',
      judul: 'Iuran Siluman Gedung SMP Negeri Bandung',
      kategori: 'Pendidikan',
      lokasi: 'Kecamatan Coblong, Kota Bandung',
      terlapor: 'Komite Sekolah Oknum Tertentu',
      nominal: 'Rp 750.000 / Siswa',
      tanggal: '22 Sep 2026',
      status: 'Verifikasi',
      deskripsi:
          'Wali murid diwajibkan membayar uang renovasi aula tanpa persetujuan Disdik Bandung dan tanpa tanda terima resmi yayasan/komite.',
      tindakLanjut:
          'Inspektorat Kota Bandung memanggil pihak kepala sekolah dan komite untuk klarifikasi dokumen administrasi keuangan BOS.',
      isAnonim: false,
    ),
    const LaporanItem(
      id: 'AP-BDG-2026-075',
      judul: 'Pungli Lapak Ilegal PKL Taman Sari',
      kategori: 'Pasar & PKL',
      lokasi: 'Jl. Taman Sari (Sekitar Babakan Siliwangi)',
      terlapor: 'Organisasi Kemasyarakatan Liar',
      nominal: 'Rp 30.000 / Hari',
      tanggal: '19 Sep 2026',
      status: 'Selesai',
      deskripsi:
          'Pedagang kaki lima dimintai setoran harian dengan dalih uang keamanan wilayah oleh kelompok preman setempat.',
      tindakLanjut:
          'Satpol PP Kota Bandung bersama Satgas Saber Pungli melakukan penertiban dan memasang plang zona bebas pungli.',
      isAnonim: true,
    ),
    const LaporanItem(
      id: 'AP-BDG-2026-070',
      judul: 'Pungutan Legalisir Surat Domisili Kelurahan',
      kategori: 'Kelurahan & Izin',
      lokasi: 'Kelurahan Bandung Pusat',
      terlapor: 'Oknum Staf Kelurahan',
      nominal: 'Rp 150.000',
      tanggal: '15 Sep 2026',
      status: 'Selesai',
      deskripsi:
          'Warga dipungut biaya pengurusan surat keterangan domisili padahal layanan resmi kelurahan bebas biaya (Rp 0).',
      tindakLanjut:
          'Pemberian teguran disiplin dan pengembalian uang pungutan kepada warga bersangkutan.',
      isAnonim: true,
    ),
  ];
}
