import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Layanan push notifikasi lokal untuk pengingat presensi dan respon admin.
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  /// Inisialisasi plugin notifikasi & daftarkan channel Android
  Future<void> init() async {
    if (_isInitialized) return;

    try {
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const darwinSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: darwinSettings,
        macOS: darwinSettings,
      );

      await _notificationsPlugin.initialize(
        initSettings,
        onDidReceiveNotificationResponse: (response) {
          debugPrint('Notifikasi diklik: ${response.payload}');
        },
      );

      // Minta izin notifikasi pada Android 13 (Tiramisu / API 33) ke atas
      final androidImplementation = _notificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      if (androidImplementation != null) {
        await androidImplementation.requestNotificationsPermission();
      }

      _isInitialized = true;
      debugPrint('NotificationService berhasil diinisialisasi.');
    } catch (e) {
      debugPrint('Gagal inisialisasi NotificationService: $e');
    }
  }

  /// Tampilkan notifikasi push langsung ke drawer notifikasi sistem
  Future<void> tampilkanNotifikasi({
    required int id,
    required String judul,
    required String pesan,
    String? payload,
  }) async {
    try {
      const androidDetails = AndroidNotificationDetails(
        'presensi_channel',
        'Pengingat Presensi Magang',
        channelDescription:
            'Pengingat waktu presensi datang (09:00) dan pulang (16:00-17:00)',
        importance: Importance.max,
        priority: Priority.high,
        showWhen: true,
        icon: '@mipmap/ic_launcher',
      );

      const notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: DarwinNotificationDetails(),
      );

      await _notificationsPlugin.show(
        id,
        judul,
        pesan,
        notificationDetails,
        payload: payload,
      );
    } catch (e) {
      debugPrint('Gagal mengirim push notifikasi: $e');
    }
  }

  /// Cek kondisi presensi datang dan pulang saat ini,
  /// lalu kirim notifikasi jika peserta belum absen pada rentang waktu yang sesuai.
  Future<void> cekDanKirimPengingatPresensi({
    required String? jamMasuk,
    required String? jamPulang,
  }) async {
    final now = DateTime.now();
    final jam = now.hour;
    final menit = now.minute;
    final totalMenit = jam * 60 + menit;

    final hariKey = '${now.year}-${now.month}-${now.day}';
    final prefs = await SharedPreferences.getInstance();

    // 1. PENGINGAT PRESENSI MASUK:
    // Rentang jam 07:00 s/d 09:15 WIB
    if (totalMenit >= (7 * 60) && totalMenit <= (9 * 60 + 15)) {
      if (jamMasuk == null) {
        final notifKey = 'notif_masuk_$hariKey';
        final sudahKirim = prefs.getBool(notifKey) ?? false;
        if (!sudahKirim) {
          await tampilkanNotifikasi(
            id: 101,
            judul: '⚠️ Pengingat Presensi Masuk (09:00 WIB)',
            pesan: 'Kamu belum absen masuk hari ini. Segera buka aplikasi dan lakukan presensi sebelum pukul 09:00 WIB!',
            payload: 'presensi_masuk',
          );
          await prefs.setBool(notifKey, true);
        }
      }
    }

    // 2. PENGINGAT PRESENSI PULANG:
    // Rentang jam 16:00 s/d 17:15 WIB
    if (totalMenit >= (16 * 60) && totalMenit <= (17 * 60 + 15)) {
      if (jamPulang == null) {
        final notifKey = 'notif_pulang_$hariKey';
        final sudahKirim = prefs.getBool(notifKey) ?? false;
        if (!sudahKirim) {
          await tampilkanNotifikasi(
            id: 102,
            judul: '🕒 Pengingat Presensi Pulang (16:00 - 17:00 WIB)',
            pesan: 'Jam kerja selesai pukul 16:00 WIB. Segera lakukan presensi pulang sebelum batas maksimal pukul 17:00 WIB!',
            payload: 'presensi_pulang',
          );
          await prefs.setBool(notifKey, true);
        }
      }
    }
  }
}
