// 檔案: lib/pages/edit_profile_page.dart
// 用途: 編輯個人資料（只更新 Firestore，不直接變更 Firebase Auth）
// 作者: (請填入作者)
// 日期: 2026-05-30

import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

/// 編輯個人資料頁面，允許更新名稱、Email、個人介紹與頭像。
///
/// 注意：此頁只同步更新 Firestore，不直接變更 Firebase Auth 的 email。
class EditProfilePage extends StatefulWidget {
  final User? firebaseUser;
  final String? backendUserId;

  const EditProfilePage({super.key, this.firebaseUser, this.backendUserId});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  final ImagePicker _imagePicker = ImagePicker();

  bool _isLoading = true;
  bool _isSaving = false;
  bool _emailEditable = true;
  XFile? _pickedImage;
  String? _initialImageUrl;

  String get _cloudinaryCloudName => dotenv.env['CLOUDINARY_CLOUD_NAME'] ?? '';
  String get _cloudinaryUploadPreset =>
      dotenv.env['CLOUDINARY_UPLOAD_PRESET'] ?? '';

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  /// 讀取 Firestore 的使用者資料並預填表單。
  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);

    try {
      if (widget.firebaseUser != null) {
        final user = widget.firebaseUser!;
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        final data = doc.data() ?? <String, dynamic>{};

        _nameController.text = (data['name'] ?? user.displayName ?? '')
            .toString();
        _emailController.text = (data['email'] ?? user.email ?? '').toString();
        _descriptionController.text = (data['description'] ?? '').toString();
        _initialImageUrl = (data['imageUrl'] ?? user.photoURL ?? '').toString();

        _emailEditable = user.providerData.any(
          (provider) => provider.providerId == 'password',
        );
      } else if (widget.backendUserId != null) {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(widget.backendUserId)
            .get();
        final data = doc.data() ?? <String, dynamic>{};

        _nameController.text = (data['name'] ?? '').toString();
        _emailController.text = (data['email'] ?? '').toString();
        _descriptionController.text = (data['description'] ?? '').toString();
        _initialImageUrl = (data['imageUrl'] ?? '').toString();
        _emailEditable = true;
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('載入資料失敗：$e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// 選取相簿圖片。
  Future<void> _pickImage() async {
    try {
      final file = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );
      if (file != null && mounted) {
        setState(() => _pickedImage = file);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('選取圖片失敗：$e')));
      }
    }
  }

  /// 上傳頭像到 Cloudinary，回傳圖片網址。
  Future<String?> _uploadAvatar(String id) async {
    if (_pickedImage == null) return null;

    final file = File(_pickedImage!.path);
    if (_cloudinaryCloudName.isEmpty || _cloudinaryUploadPreset.isEmpty) {
      throw Exception('Cloudinary 環境變數未設定完整');
    }

    final uri = Uri.parse(
      'https://api.cloudinary.com/v1_1/$_cloudinaryCloudName/image/upload',
    );
    final request = http.MultipartRequest('POST', uri)
      ..fields['upload_preset'] = _cloudinaryUploadPreset
      ..fields['public_id'] = 'avatars/$id'
      ..files.add(await http.MultipartFile.fromPath('file', file.path));

    final response = await request.send();
    final responseBody = await response.stream.bytesToString();

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Cloudinary 上傳失敗：$responseBody');
    }

    final data = responseBody.isNotEmpty ? responseBody : '{}';
    final decoded = Map<String, dynamic>.from(
      jsonDecode(data) as Map<String, dynamic>,
    );
    final secureUrl = decoded['secure_url']?.toString();
    if (secureUrl == null || secureUrl.isEmpty) {
      throw Exception('Cloudinary 未回傳圖片網址');
    }

    return secureUrl;
  }

  /// 儲存 Firestore 的個人資料。
  Future<void> _save() async {
    setState(() => _isSaving = true);

    try {
      final name = _nameController.text.trim();
      final email = _emailController.text.trim();
      final description = _descriptionController.text.trim();

      String? id;
      if (widget.firebaseUser != null) {
        id = widget.firebaseUser!.uid;
      } else if (widget.backendUserId != null) {
        id = widget.backendUserId;
      }

      if (id == null || id.isEmpty) {
        throw Exception('找不到可編輯的使用者');
      }

      final imageUrl = await _uploadAvatar(id);

      await FirebaseFirestore.instance.collection('users').doc(id).set({
        if (name.isNotEmpty) 'name': name,
        if (email.isNotEmpty) 'email': email,
        if (description.isNotEmpty) 'description': description,
        if (imageUrl != null) 'imageUrl': imageUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              '個人資料已更新',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 1),
          ),
        );
        //延遲1秒後返回上一頁
        Future.delayed(const Duration(seconds: 1), () {
          Navigator.pop(context, true);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '更新失敗：$e',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ImageProvider? avatarProvider = _pickedImage != null
        ? FileImage(File(_pickedImage!.path))
        : (_initialImageUrl != null && _initialImageUrl!.isNotEmpty)
        ? NetworkImage(_initialImageUrl!)
        : null;

    return Scaffold(
      appBar: AppBar(title: const Text('編輯個人資料')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  GestureDetector(
                    onTap: _pickImage,
                    child: CircleAvatar(
                      radius: 56,
                      backgroundImage: avatarProvider,
                      child: avatarProvider == null
                          ? const Icon(Icons.camera_alt, size: 40)
                          : null,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: '名稱',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _emailController,
                    enabled: _emailEditable,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 6),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      _emailEditable
                          ? 'Email 只會更新到 Firestore，不會直接變更 Firebase Auth。'
                          : '此帳號為社群登入，無法在此修改 Email。',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                      labelText: '個人介紹',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.multiline,
                    maxLines: 4,
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _save,
                      child: _isSaving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('儲存'),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
