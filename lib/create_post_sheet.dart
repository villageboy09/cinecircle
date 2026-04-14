import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

class CreatePostSheet extends StatefulWidget {
  const CreatePostSheet({super.key});

  @override
  State<CreatePostSheet> createState() => _CreatePostSheetState();
}

class _CreatePostSheetState extends State<CreatePostSheet> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  String _category = 'Project Update';
  File? _mediaFile;
  String _mediaType = 'image';
  bool _isPosting = false;

  final List<String> _categories = [
    'Project Update',
    'Casting Call',
    'Screening Room',
    'Behind the Scenes',
    'Other'
  ];

  Future<void> _pickMedia(ImageSource source, bool isVideo) async {
    final picker = ImagePicker();
    XFile? pickedFile;
    
    if (isVideo) {
      pickedFile = await picker.pickVideo(source: source);
    } else {
      pickedFile = await picker.pickImage(source: source);
    }

    if (pickedFile != null) {
      File file = File(pickedFile.path);
      if (!isVideo) {
        file = await _autoCropIfNecessary(file);
      }

      setState(() {
        _mediaFile = file;
        _mediaType = isVideo ? 'video' : 'image';
      });
    }
  }

  Future<File> _autoCropIfNecessary(File originalFile) async {
    try {
      final Uint8List bytes = await originalFile.readAsBytes();
      img.Image? decodedImage = img.decodeImage(bytes);
      if (decodedImage == null) return originalFile;

      final double currentAspect = decodedImage.width / decodedImage.height;
      const double targetAspect = 4 / 5;

      if (currentAspect > targetAspect) {
        final int targetWidth = (decodedImage.height * targetAspect).toInt();
        final int offsetX = (decodedImage.width - targetWidth) ~/ 2;
        
        final img.Image cropped = img.copyCrop(
          decodedImage,
          x: offsetX,
          y: 0,
          width: targetWidth,
          height: decodedImage.height,
        );
        
        final Directory tempDir = await getTemporaryDirectory();
        final String path = '${tempDir.path}/cropped_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final File croppedFile = File(path)..writeAsBytesSync(img.encodeJpg(cropped, quality: 90));
        return croppedFile;
      }
    } catch (e) {
      debugPrint('Auto-crop error: $e');
    }
    return originalFile;
  }

  Future<void> _submitPost() async {
    if (_titleController.text.trim().isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please add a title')));
      }
      return;
    }

    setState(() => _isPosting = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final mobile = prefs.getString('user_phone') ?? '';

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('https://team.cropsync.in/cine_circle/social_api.php'),
      );

      request.fields['action'] = 'create_post';
      request.fields['mobile_number'] = mobile;
      request.fields['category'] = _category;
      request.fields['title'] = _titleController.text.trim();
      request.fields['description'] = _descController.text.trim();
      request.fields['media_type'] = _mediaType;

      if (_mediaFile != null) {
        request.files.add(await http.MultipartFile.fromPath('media', _mediaFile!.path));
      }

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        if (mounted) Navigator.pop(context, true);
      } else {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: ${response.statusCode}')));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isPosting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      decoration: const BoxDecoration(
        color: Color(0xFFF9FAFB),
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                   Text(
                    'Create Post',
                    style: TextStyle(
                      fontFamily: 'Google Sans',
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: Colors.grey.shade900,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close, color: Colors.grey.shade600),
                    style: IconButton.styleFrom(backgroundColor: Colors.grey.shade200),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              
              // Category Selection (Premium Horizontal List)
              const Text(
                'WHAT IS THIS ABOUT?',
                style: TextStyle(
                  fontFamily: 'Google Sans',
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: Colors.black45,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 40,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _categories.length,
                  itemBuilder: (context, index) {
                    bool selected = _category == _categories[index];
                    return GestureDetector(
                      onTap: () => setState(() => _category = _categories[index]),
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: selected ? Colors.black : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: selected ? Colors.black : Colors.grey.shade300),
                          boxShadow: selected ? [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 8, offset: const Offset(0, 4))] : null,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          _categories[index],
                          style: TextStyle(
                            fontFamily: 'Google Sans',
                            fontSize: 13,
                            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                            color: selected ? Colors.white : Colors.black87,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              
              const SizedBox(height: 24),

              // Title Input
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))],
                ),
                child: TextField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    hintText: 'Give it a headline...',
                    hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 15),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.all(18),
                  ),
                  style: const TextStyle(fontFamily: 'Google Sans', fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(height: 16),

              // Description Input
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))],
                ),
                child: TextField(
                  controller: _descController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: 'Tell the circle more...',
                    hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.all(18),
                  ),
                  style: const TextStyle(fontFamily: 'Google Sans', fontSize: 14, height: 1.5),
                ),
              ),
              const SizedBox(height: 24),

              // Media Section
              const Text(
                'ATTACH MEDIA',
                style: TextStyle(
                  fontFamily: 'Google Sans',
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: Colors.black45,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 12),
              
              if (_mediaFile != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Stack(
                    children: [
                      AspectRatio(
                        aspectRatio: _mediaType == 'image' ? 4/5 : 16/9,
                        child: Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.black12,
                            image: _mediaType == 'image' 
                              ? DecorationImage(image: FileImage(_mediaFile!), fit: BoxFit.cover)
                              : null,
                          ),
                          child: _mediaType == 'video' ? const Center(child: Icon(Icons.videocam, size: 64, color: Colors.black54)) : null,
                        ),
                      ),
                      Positioned(
                        top: 12, right: 12,
                        child: GestureDetector(
                          onTap: () => setState(() => _mediaFile = null),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                            child: const Icon(Icons.close, color: Colors.white, size: 20),
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              else
                Row(
                  children: [
                    Expanded(
                      child: _buildMediaPicker(
                        onTap: () => _pickMedia(ImageSource.gallery, false),
                        icon: Icons.image_outlined,
                        label: 'Photo',
                        color: Colors.blue.shade50,
                        iconColor: Colors.blue.shade600,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildMediaPicker(
                        onTap: () => _pickMedia(ImageSource.gallery, true),
                        icon: Icons.videocam_outlined,
                        label: 'Video',
                        color: Colors.purple.shade50,
                        iconColor: Colors.purple.shade600,
                      ),
                    ),
                  ],
                ),

              const SizedBox(height: 32),

              // Post Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isPosting ? null : _submitPost,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    elevation: 8,
                    shadowColor: Colors.black.withValues(alpha: 0.4),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  ),
                  child: _isPosting 
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Post to Circle',
                        style: TextStyle(fontFamily: 'Google Sans', fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMediaPicker({
    required VoidCallback onTap,
    required IconData icon,
    required String label,
    required Color color,
    required Color iconColor,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            Icon(icon, size: 32, color: iconColor),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Google Sans',
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: iconColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
