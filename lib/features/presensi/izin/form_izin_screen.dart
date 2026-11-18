import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart'; // Tambahkan baris ini
import 'package:apk_absensi/features/auth/auth_service.dart';
import 'package:apk_absensi/features/presensi/data/presensi_repository.dart';

class FormIzinScreen extends StatefulWidget {
  const FormIzinScreen({super.key});

  @override
  State<FormIzinScreen> createState() => _FormIzinScreenState();
}

class _FormIzinScreenState extends State<FormIzinScreen> {
  final _keteranganController = TextEditingController();
  final _tanggalController = TextEditingController();
  XFile? _selectedImage;
  bool _isLoading = false;

 final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = pickedFile;
      });
    }
  }

  Future<void> _submitData() async {
    if (_keteranganController.text.isEmpty || _tanggalController.text.isEmpty || _selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Semua kolom dan bukti foto wajib diisi!')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      var bytes = await _selectedImage!.readAsBytes();
      var result = await PresensiRepository.submitIzin(
        userId: AuthService.userId,
        tanggal: _tanggalController.text,
        keterangan: _keteranganController.text,
        fileBytes: bytes,
      );

      if (!mounted) return;

      if (result['status'] == 'success') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Izin berhasil diajukan! Menunggu ACC Admin.')),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal: ${result['message']}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Form Pengajuan Izin')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            TextField(
              controller: _tanggalController,
              decoration: const InputDecoration(
                labelText: 'Tanggal (Contoh: 2026-10-23)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _keteranganController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Alasan / Keterangan Izin',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _pickImage,
              icon: const Icon(Icons.image),
              label: Text(_selectedImage == null ? 'Pilih Bukti Surat/Foto' : 'Ganti Bukti Foto'),
            ),
            if (_selectedImage != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Text('File terpilih: ${_selectedImage!.name}', style: const TextStyle(color: Colors.green)),
              ),
            const SizedBox(height: 24),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: _isLoading ? null : _submitData,
              child: _isLoading 
                ? const CircularProgressIndicator(color: Colors.white) 
                : const Text('Kirim Pengajuan Izin', style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}