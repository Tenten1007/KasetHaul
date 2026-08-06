import 'dart:io';
import '../services/firebase_service.dart';

const int _maxFileSizeBytes = 5 * 1024 * 1024; // 5 MB

class StorageRepository {
  Future<String> uploadFile({
    required File file,
    required String path,
  }) async {
    final size = await file.length();
    if (size > _maxFileSizeBytes) {
      throw Exception('ไฟล์มีขนาดเกิน 5 MB กรุณาเลือกไฟล์ที่เล็กกว่า');
    }
    final ref = FirebaseService.storage.ref(path);
    final task = await ref.putFile(file);
    return await task.ref.getDownloadURL();
  }

  Future<void> deleteFile(String url) async {
    final ref = FirebaseService.storage.refFromURL(url);
    await ref.delete();
  }
}
