import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player/video_player.dart';

class PostStoryScreen extends StatefulWidget {
  const PostStoryScreen({super.key});

  @override
  State<PostStoryScreen> createState() => _PostStoryScreenState();
}

class _PostStoryScreenState extends State<PostStoryScreen> {
  File? _mediaFile;
  String _mediaType = 'image';
  bool _isUploading = false;
  VideoPlayerController? _videoController;

  final ImagePicker _picker = ImagePicker();

  Future<void> _pickMedia(ImageSource source, {bool isVideo = false}) async {
    final XFile? file = isVideo 
      ? await _picker.pickVideo(source: source)
      : await _picker.pickImage(source: source);

    if (file != null) {
      if (_videoController != null) {
        await _videoController!.dispose();
        _videoController = null;
      }

      setState(() {
        _mediaFile = File(file.path);
        _mediaType = isVideo ? 'video' : 'image';
      });

      if (isVideo) {
        _videoController = VideoPlayerController.file(_mediaFile!)
          ..initialize().then((_) {
            setState(() {});
            _videoController!.play();
            _videoController!.setLooping(true);
          });
      }
    }
  }

  Future<void> _uploadStory() async {
    if (_mediaFile == null) return;

    setState(() => _isUploading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final mobile = prefs.getString('user_phone') ?? '';

      final request = http.MultipartRequest(
        'POST',
        Uri.parse('https://team.cropsync.in/cine_circle/stories_api.php'),
      );

      request.fields['action'] = 'upload_story';
      request.fields['mobile_number'] = mobile;
      request.fields['media_type'] = _mediaType;
      
      request.files.add(
        await http.MultipartFile.fromPath('media', _mediaFile!.path),
      );

      final response = await request.send();
      final responseData = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Story posted successfully!')),
          );
          Navigator.pop(context, true); // Return true to refresh stories
        }
      } else {
        throw Exception('Failed to upload story: $responseData');
      }
    } catch (e) {
      debugPrint('Upload error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Add to Story', style: TextStyle(color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (_mediaFile != null)
            TextButton(
              onPressed: _isUploading ? null : _uploadStory,
              child: _isUploading 
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.blue))
                : const Text('Share', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 16)),
            ),
        ],
      ),
      body: Center(
        child: _mediaFile == null 
          ? _buildPickerOptions()
          : _buildPreview(),
      ),
    );
  }

  Widget _buildPickerOptions() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildOptionTile(Icons.camera_alt, 'Take Photo', () => _pickMedia(ImageSource.camera)),
        _buildOptionTile(Icons.videocam, 'Record Video', () => _pickMedia(ImageSource.camera, isVideo: true)),
        _buildOptionTile(Icons.photo_library, 'Upload from Gallery', () => _showGalleryOptions()),
      ],
    );
  }

  void _showGalleryOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey.shade900,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(15))),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.image, color: Colors.white),
              title: const Text('Pick Image', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                _pickMedia(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.movie, color: Colors.white),
              title: const Text('Pick Video', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                _pickMedia(ImageSource.gallery, isVideo: true);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionTile(IconData icon, String label, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 40),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
          decoration: BoxDecoration(
            color: Colors.grey.shade900,
            borderRadius: BorderRadius.circular(15),
          ),
          child: Row(
            children: [
              Icon(icon, color: Colors.blue, size: 28),
              const SizedBox(width: 20),
              Text(label, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPreview() {
    return Stack(
      children: [
        Positioned.fill(
          child: _mediaType == 'image'
            ? Image.file(_mediaFile!, fit: BoxFit.contain)
            : (_videoController != null && _videoController!.value.isInitialized
                ? AspectRatio(
                    aspectRatio: _videoController!.value.aspectRatio,
                    child: VideoPlayer(_videoController!),
                  )
                : const Center(child: CircularProgressIndicator())),
        ),
        Positioned(
          top: 10,
          right: 10,
          child: IconButton(
            icon: const CircleAvatar(
              backgroundColor: Colors.black54,
              child: Icon(Icons.delete, color: Colors.white),
            ),
            onPressed: () {
              setState(() {
                _mediaFile = null;
                _videoController?.dispose();
                _videoController = null;
              });
            },
          ),
        ),
      ],
    );
  }
}
