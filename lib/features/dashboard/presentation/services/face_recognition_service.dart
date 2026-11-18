import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

class FaceMatchResult {
  const FaceMatchResult(this.distance, this.match);

  /// Jarak Euclidean antar dua embedding (makin kecil = makin mirip).
  final double distance;
  final bool match;
}

class FaceRecognitionService {
  /// Batas jarak Euclidean. HARUS dikalibrasi dari data pengujianmu.
  /// 1.0 hanya titik awal.
  static const double threshold = 1.0;

  Interpreter? _interpreter;
  int _inputSize = 0; // tinggi = lebar input model (mis. 160 atau 112)
  int _embeddingDim = 0; // panjang vektor keluaran (mis. 128 atau 512)

  final FaceDetector _detector = FaceDetector(
    options: FaceDetectorOptions(
      performanceMode: FaceDetectorMode.fast,
      enableClassification: true, // mata terbuka & senyum
    ),
  );

  bool get isLoaded => _interpreter != null;

  Future<List<Face>> _detect(String imagePath) =>
      _detector.processImage(InputImage.fromFilePath(imagePath));

  // 1. Memuat model TFLite dari folder assets
  Future<void> loadModel() async {
    if (_interpreter != null) return;
    try {
      final options = InterpreterOptions()..threads = 2;
      final interpreter = await Interpreter.fromAsset(
          'assets/model_wajah.tflite',
          options: options);

      // Ukuran dibaca dari model, aman untuk 112x112 maupun 160x160.
      final inShape = interpreter.getInputTensor(0).shape; // [1, H, W, 3]
      final outShape = interpreter.getOutputTensor(0).shape; // [1, D]
      _inputSize = inShape[1];
      _embeddingDim = outShape.last;
      _interpreter = interpreter;
      debugPrint(
          '✅ Model TFLite berhasil dimuat (input $_inputSize, output $_embeddingDim)');
    } catch (e) {
      debugPrint('❌ Gagal memuat model TFLite: $e');
    }
  }

  // 2. Cek kualitas foto sebelum diproses.
  // Mengembalikan pesan masalah, atau null jika foto layak dipakai.
  Future<String?> cekFoto(String imagePath) async {
    final faces = await _detect(imagePath);

    if (faces.isEmpty) return 'Wajah tidak terdeteksi.';
    if (faces.length > 1) return 'Terdeteksi lebih dari satu wajah.';

    final f = faces.first;
    if ((f.headEulerAngleY ?? 0).abs() > 20) {
      return 'Hadapkan wajah lurus ke kamera.';
    }
    final kiri = f.leftEyeOpenProbability;
    final kanan = f.rightEyeOpenProbability;
    if (kiri != null && kanan != null && (kiri < 0.3 || kanan < 0.3)) {
      return 'Buka mata dengan jelas.';
    }
    return null;
  }

  // 3. Foto -> deteksi wajah -> embedding.
  // Mengembalikan null jika tidak ada wajah di foto.
  Future<List<double>?> recognizeFace(String imagePath) async {
    if (_interpreter == null) {
      throw Exception('Model belum dimuat!');
    }

    final faces = await _detect(imagePath);
    if (faces.isEmpty) return null;

    // Ambil wajah terbesar
    faces.sort((a, b) => (b.boundingBox.width * b.boundingBox.height)
        .compareTo(a.boundingBox.width * a.boundingBox.height));
    final box = faces.first.boundingBox;

    var image = img.decodeImage(await File(imagePath).readAsBytes());
    if (image == null) return null;
    // Foto kamera sering menyimpan rotasi di EXIF; samakan dengan ML Kit.
    image = img.bakeOrientation(image);

    final x = box.left.round().clamp(0, image.width - 1).toInt();
    final y = box.top.round().clamp(0, image.height - 1).toInt();
    final w = box.width.round().clamp(1, image.width - x).toInt();
    final h = box.height.round().clamp(1, image.height - y).toInt();

    final face = img.copyCrop(image, x: x, y: y, width: w, height: h);
    final resized =
        img.copyResize(face, width: _inputSize, height: _inputSize);

    // Normalisasi (x - 127.5) / 128. Sesuaikan dengan cara model dilatih.
    final input = Float32List(_inputSize * _inputSize * 3);
    var i = 0;
    for (var yy = 0; yy < _inputSize; yy++) {
      for (var xx = 0; xx < _inputSize; xx++) {
        final p = resized.getPixel(xx, yy);
        input[i++] = (p.r - 127.5) / 128.0;
        input[i++] = (p.g - 127.5) / 128.0;
        input[i++] = (p.b - 127.5) / 128.0;
      }
    }

    final output =
        List.generate(1, (_) => List<double>.filled(_embeddingDim, 0.0));
    _interpreter!.run(input.reshape([1, _inputSize, _inputSize, 3]), output);

    // L2-normalize supaya jarak antar embedding konsisten.
    final emb = List<double>.from(output[0]);
    final norm = math.sqrt(emb.fold<double>(0, (s, v) => s + v * v));
    return norm == 0 ? emb : emb.map((v) => v / norm).toList();
  }

  // 4. Tantangan senyum (liveness sederhana).
  // Foto pertama netral, foto kedua tersenyum, dan orangnya harus sama.
  // Mengembalikan pesan masalah, atau null jika lolos.
  Future<String?> cekTantanganSenyum(
      String fotoNetral, String fotoSenyum) async {
    final a = await _detect(fotoNetral);
    final b = await _detect(fotoSenyum);
    if (a.length != 1 || b.length != 1) {
      return 'Pastikan hanya ada satu wajah di kedua foto.';
    }

    final senyumA = a.first.smilingProbability;
    final senyumB = b.first.smilingProbability;
    if (senyumA == null || senyumB == null) {
      return 'Ekspresi tidak terbaca, coba lagi.';
    }
    if (senyumA > 0.4) return 'Foto pertama harus berwajah netral.';
    if (senyumB < 0.7) return 'Foto kedua harus tersenyum lebar.';

    final ea = await recognizeFace(fotoNetral);
    final eb = await recognizeFace(fotoSenyum);
    if (ea == null || eb == null) return 'Wajah tidak terbaca.';
    if (!compare(ea, eb).match) return 'Kedua foto bukan orang yang sama.';
    return null;
  }

  // 5. Bandingkan dua embedding
  static double distance(List<double> a, List<double> b) {
    var sum = 0.0;
    for (var i = 0; i < a.length; i++) {
      final d = a[i] - b[i];
      sum += d * d;
    }
    return math.sqrt(sum);
  }

  static FaceMatchResult compare(List<double> a, List<double> b) {
    final d = distance(a, b);
    return FaceMatchResult(d, d < threshold);
  }

  Future<void> dispose() async {
    _interpreter?.close();
    _interpreter = null;
    await _detector.close();
  }
}