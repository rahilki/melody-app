import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart'
    show kIsWeb; // مشغل على الويب ولا الفون
import 'package:flutter/material.dart'; //مكتبة تصميم واجهات الفلتر
import 'package:cloud_firestore/cloud_firestore.dart'; //تخزين بيانات البوست
import 'package:shared_preferences/shared_preferences.dart'; //خزن ونجيب userDocId و lastEmail.
import 'package:firebase_auth/firebase_auth.dart'; //نعرف مين المستخدم الحالي
import 'package:firebase_storage/firebase_storage.dart'; //نخزن الصور/الفيديوهات
import 'package:image_picker/image_picker.dart'; //نفتح المعرض لاختيار صورة/فيديو
import 'package:flutter_image_compress/flutter_image_compress.dart'; //نضغط الصورة قبل الرفع عشان نقلل الحجم (سويتها لان الصور كانت ما طايعه تنرفع بعدين المشكلة طلعت بسبب ان لازم ندفع للفيربس)

class AddPostPage extends StatefulWidget {
  const AddPostPage({super.key});

  @override
  State<AddPostPage> createState() => _AddPostPageState();
}

class _AddPostPageState extends State<AddPostPage> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _content = TextEditingController();
  bool _saving = false; //عشان ما ينضغط الزر مرتين

  File? _mediaFile;
  Uint8List? _mediaBytes; // للويب
  String? _mediaType; // image أو video

  @override
  void dispose() {
    _title.dispose();
    _content.dispose();
    super.dispose();
  }

  Future<void> _pickMedia(bool isVideo) async {
    final picker = ImagePicker();
    final picked = await (isVideo
        ? picker.pickVideo(source: ImageSource.gallery)
        : picker.pickImage(source: ImageSource.gallery));

    if (picked != null) {
      if (kIsWeb) {
        _mediaBytes = await picked.readAsBytes(); // للويب
        _mediaFile = null;
      } else {
        _mediaFile = File(picked.path); // للموبايل
        _mediaBytes = null;
      }
      setState(() {
        _mediaType = isVideo
            ? 'video'
            : 'image'; //نحدث الحالة ونحدد إذا هو صورة أو فيديو
      });
    }
  }

  // ضغط الصور قبل الرفع
  Future<File> _compressImage(File file) async {
    //  compressWithFile أكتب البايتات في ملف جديد
    final bytes = await FlutterImageCompress.compressWithFile(
      file.absolute.path,
      quality: 70, // قلل الجودة لتصغير الحجم
      format: CompressFormat.jpeg,
    );

    if (bytes == null) return file; // لو فشل الضغط نرجّع الملف الأصلي

    final outPath = '${file.path}_compressed.jpg';
    final outFile = await File(outPath).writeAsBytes(bytes, flush: true);
    return outFile;
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() =>
        _saving = true); //إذا الحقول (العنوان/المحتوى) فاضية → ما يكمل الحفظ

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw 'يرجى تسجيل الدخول أولًا.';

      final uid = user.uid;
      final email = user.email ?? '';
      final prefs = await SharedPreferences.getInstance();

      String? userDocId = prefs.getString('userDocId');
      final emailLower = (prefs.getString('lastEmail') ?? email).toLowerCase();
      userDocId ??= uid;

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userDocId)
          .get();

      final u = userDoc.data() ?? {};
      final stageName = (u['stageName'] ?? '').toString();
      final fullName = (u['fullName'] ?? '').toString();
      //stageName = اسم الشهرة للفنان
      //fullName = الاسم الكامل الحقيقي يعني

      final authorName = stageName.isNotEmpty
          ? stageName
          : (fullName.isNotEmpty ? fullName : 'فنان');
      //إذا عنده اسم شهرة (stageName) → نستخدمه
      //إذا ما عنده → نستخدم الاسم الكامل (fullName)
      //إذا الاثنين فاضيين → نخليها كلمة فنان

      //إذا اسم شهرة الفنانة فاضي نستخدم الجزء الاول من الايميل
      //مثلا إذا ايميلي rahil@gmail.com
      //يكون @rahil
      final authorHandle = stageName.isNotEmpty
          ? '@$stageName'
          : (emailLower.isNotEmpty ? '@${emailLower.split('@').first}' : '');
      //نقرأ رابط الصورة من الفيربيس
      final authorPhotoUrl = (u['photoUrl'] ?? '').toString();

      // --- رفع صورة أو فيديو لو موجود ---
      String? mediaUrl;
      if (_mediaFile != null || _mediaBytes != null) {
        final fileName = '${DateTime.now().millisecondsSinceEpoch}_$uid';
        final ref =
            FirebaseStorage.instance.ref().child('posts').child(fileName);

        final metadata = SettableMetadata(
          contentType: _mediaType == 'video' ? 'video/mp4' : 'image/jpeg',
        );

        if (kIsWeb && _mediaBytes != null) {
          await ref.putData(_mediaBytes!, metadata);
        } else if (_mediaFile != null) {
          File fileToUpload = _mediaFile!;
          if (_mediaType == 'image') {
            fileToUpload = await _compressImage(_mediaFile!); // ضغط الصورة
          }
          await ref.putFile(fileToUpload, metadata);
        }

        mediaUrl = await ref.getDownloadURL();
      }

      // --- حفظ المنشور ---
      await FirebaseFirestore.instance.collection('posts').add({
        'title': _title.text.trim(),
        'content': _content.text.trim(),
        'mediaUrl': mediaUrl,
        'mediaType': _mediaType, // image أو video

        // مهم للرولز
        'authorUid': uid,

        // باقي البيانات
        'authorId': userDocId,
        'authorEmail': email,
        'authorEmailLower': emailLower,
        'authorName': authorName,
        'authorHandle': authorHandle,
        'authorPhotoUrl': authorPhotoUrl,

        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'status': 'published',
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم نشر المنشور بنجاح')),
      );

      setState(() => _saving = false);

      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) Navigator.pop(context);
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تعذّر الحفظ: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('إضافة منشور')),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: ListView(
              children: [
                TextFormField(
                  controller: _title,
                  textAlign: TextAlign.right,
                  decoration: const InputDecoration(labelText: 'عنوان المنشور'),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'مطلوب' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _content,
                  textAlign: TextAlign.right,
                  maxLines: 6,
                  decoration: const InputDecoration(
                    labelText: 'المحتوى',
                    alignLabelWithHint: true,
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'مطلوب' : null,
                ),
                const SizedBox(height: 12),
                if (_mediaType == 'image')
                  kIsWeb && _mediaBytes != null
                      ? Image.memory(_mediaBytes!, height: 150)
                      : (_mediaFile != null
                          ? Image.file(_mediaFile!, height: 150)
                          : const SizedBox()),
                if (_mediaType == 'video')
                  const Icon(Icons.videocam, size: 100, color: Colors.blue),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () => _pickMedia(false),
                      icon: const Icon(Icons.image),
                      label: const Text("إضافة صورة"),
                    ),
                    ElevatedButton.icon(
                      onPressed: () => _pickMedia(true),
                      icon: const Icon(Icons.videocam),
                      label: const Text("إضافة فيديو"),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                SizedBox(
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: _saving ? null : _save,
                    icon: _saving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.check),
                    label: const Text('نشر'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

//رحيل البادي
