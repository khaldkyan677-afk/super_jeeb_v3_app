import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:typed_data';
import '../config/app_theme.dart';
import '../config/api_endpoints.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Uint8List? _imageBytes;
  bool _isUploading = false;
  String? _imageUrl;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      setState(() {
        _imageBytes = bytes;
      });
      _uploadImage();
    }
  }

  Future<void> _uploadImage() async {
    if (_imageBytes == null) return;

    setState(() => _isUploading = true);

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        throw Exception('المستخدم غير مسجل الدخول');
      }

      final fileName = 'avatar_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final path = 'public/$fileName';

      // استخدام uploadBinary بدلاً من upload
      await Supabase.instance.client.storage
          .from('avatars')
          .uploadBinary(path, _imageBytes!);

      final url = Supabase.instance.client.storage
          .from('avatars')
          .getPublicUrl(path);

      await _saveAvatarToDatabase(email: user.email ?? '', avatarUrl: url);

      setState(() {
        _imageUrl = url;
        _isUploading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم رفع الصورة وحفظها بنجاح!')),
        );
      }
    } catch (e) {
      setState(() => _isUploading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ في رفع الصورة: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _saveAvatarToDatabase({required String email, required String avatarUrl}) async {
    try {
      await http.post(
        Uri.parse('${ApiEndpoints.baseUrl}/auth/update-avatar'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'avatarUrl': avatarUrl,
        }),
      );
    } catch (e) {
      print('Error saving avatar: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('الملف الشخصي'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppTheme.darkBlack, AppTheme.primaryRed],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 80),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withOpacity(0.2)),
                ),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundColor: Colors.white.withOpacity(0.2),
                      backgroundImage: _imageUrl != null
                          ? NetworkImage(_imageUrl!)
                          : (_imageBytes != null
                              ? MemoryImage(_imageBytes!)
                              : null),
                      child: _imageUrl == null && _imageBytes == null
                          ? const Icon(Icons.person, size: 60, color: Colors.white)
                          : null,
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: _isUploading ? null : _pickImage,
                      icon: const Icon(Icons.upload_file),
                      label: Text(_isUploading ? 'جاري الرفع...' : 'اختيار صورة'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryRed,
                        minimumSize: const Size(double.infinity, 45),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
