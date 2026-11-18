import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:apk_absensi/core/config/app_config.dart';

class PresensiRepository {
  // Endpoint Webhook Google Apps Script untuk pencatatan Spreadsheet
  static const String apiUrl = AppConfig.appsScriptUrl;

  // Helper untuk validasi dan parsing respons HTTP dari endpoint
  static Map<String, dynamic> _parseResponse(http.Response response) {
    if (response.statusCode == 200 || response.statusCode == 302) {
      if (response.body.trim().isEmpty) {
        return {
          "status": "success",
          "message": "Data berhasil dikirim dan disimpan!"
        };
      }

      try {
        return jsonDecode(response.body);
      } catch (e) {
        return {
          "status": "success",
          "message": "Data berhasil dikirim dan disimpan!"
        };
      }
    }

    // Jika terjadi error dari server (misal 404, 500)
    return {
      "status": "error",
      "message": "Gagal terhubung ke server (Error: ${response.statusCode})"
    };
  }

  // 1. Kirim Presensi Biometrik
  static Future<Map<String, dynamic>> submitPresensi({
    required String userId,
    required String timestamp,
    required double latitude,
    required double longitude,
    required String biometricStatus,
    required List<int> fotoBytes,
  }) async {
    try {
      String base64Image = base64Encode(fotoBytes);

      var response = await http.post(
        Uri.parse(apiUrl),
        headers: {"Content-Type": "text/plain;charset=utf-8"},
        body: jsonEncode({
          "action": "presensi",
          "user_id": userId,
          "timestamp": timestamp,
          "latitude": latitude,
          "longitude": longitude,
          "biometric_status": biometricStatus,
          "foto_base64": base64Image,
        }),
      );

      return _parseResponse(response);
    } catch (e) {
      return {"status": "error", "message": e.toString()};
    }
  }

  // 2. Kirim Pengajuan Izin
  static Future<Map<String, dynamic>> submitIzin({
    required String userId,
    required String tanggal,
    required String keterangan,
    required List<int> fileBytes,
  }) async {
    try {
      String base64Image = base64Encode(fileBytes);
      
      var response = await http.post(
        Uri.parse(apiUrl),
        headers: {"Content-Type": "text/plain;charset=utf-8"},
        body: jsonEncode({
          "action": "submit_izin",
          "user_id": userId,
          "tanggal": tanggal,
          "keterangan": keterangan,
          "file_base64": base64Image,
        }),
      );

      return _parseResponse(response);
    } catch (e) {
      return {"status": "error", "message": e.toString()};
    }
  }

  // 3. Kirim Penyerahan Tugas Divisi
  static Future<Map<String, dynamic>> submitTugas({
    required String userId,
    required String judulTugas,
    required String tanggalSubmit,
    required List<int> fileBytes,
    String mimeType = "application/pdf",
  }) async {
    try {
      String base64File = base64Encode(fileBytes);
      
      var response = await http.post(
        Uri.parse(apiUrl),
        headers: {"Content-Type": "text/plain;charset=utf-8"},
        body: jsonEncode({
          "action": "submit_tugas",
          "user_id": userId,
          "judul_tugas": judulTugas,
          "tanggal_submit": tanggalSubmit,
          "file_base64": base64File,
          "mime_type": mimeType,
        }),
      );

      return _parseResponse(response);
    } catch (e) {
      return {"status": "error", "message": e.toString()};
    }
  }
}