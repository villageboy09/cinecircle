import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:video_player/video_player.dart';
import 'global_notifier.dart';

class _CropArgs {
  final Uint8List bytes;
  final double ratio;
  final String destPath;
  _CropArgs(this.bytes, this.ratio, this.destPath);
}

bool _processAndCropImage(_CropArgs args) {
  try {
    img.Image? decoded = img.decodeImage(args.bytes);
    if (decoded == null) return false;
    
    final double current = decoded.width / decoded.height;
    img.Image cropped;
    if ((current - args.ratio).abs() < 0.01) {
      cropped = decoded;
    } else if (current > args.ratio) {
      final int w = (decoded.height * args.ratio).toInt();
      final int x = (decoded.width - w) ~/ 2;
      cropped = img.copyCrop(
        decoded,
        x: x,
        y: 0,
        width: w,
        height: decoded.height,
      );
    } else {
      final int h = (decoded.width / args.ratio).toInt();
      final int y = (decoded.height - h) ~/ 2;
      cropped = img.copyCrop(
        decoded,
        x: 0,
        y: y,
        width: decoded.width,
        height: h,
      );
    }
    
    File(args.destPath).writeAsBytesSync(img.encodeJpg(cropped, quality: 90));
    return true;
  } catch (e) {
    debugPrint('Crop error background: $e');
    return false;
  }
}

// ── Aspect ratio options ────────────────────────────────────────────────────
class _AspectOption {
  final String label;
  final String sublabel;
  final double? ratio; // null = original (no crop)
  final IconData icon;

  const _AspectOption({
    required this.label,
    required this.sublabel,
    required this.ratio,
    required this.icon,
  });
}

const _aspectOptions = <_AspectOption>[
  _AspectOption(
    label: '1:1',
    sublabel: 'Square',
    ratio: 1.0,
    icon: Icons.crop_square,
  ),
  _AspectOption(
    label: '4:5',
    sublabel: 'Portrait',
    ratio: 4 / 5,
    icon: Icons.crop_portrait,
  ),
  _AspectOption(
    label: '16:9',
    sublabel: 'Wide',
    ratio: 16 / 9,
    icon: Icons.crop_landscape,
  ),
  _AspectOption(
    label: 'Full',
    sublabel: 'Original',
    ratio: null,
    icon: Icons.crop_free,
  ),
];

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();

  String _category = 'Project Update';
  File? _rawFile; // original picked file (no crop applied)
  File? _displayFile; // file used for preview / upload (cropped copy)
  String _mediaType = 'image';
  bool _isPosting = false;
  int _selectedRatioIndex = 1; // default: 4:5 Portrait
  VideoPlayerController? _videoController;

  final List<String> _categories = [
    'Project Update',
    'Casting Call',
    'Screening Room',
    'Behind the Scenes',
    'Community Highlight',
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  // ── Media picking ───────────────────────────────────────────────────────
  Future<void> _pickMedia(bool isVideo) async {
    final picker = ImagePicker();
    XFile? picked;
    if (isVideo) {
      picked = await picker.pickVideo(source: ImageSource.gallery);
    } else {
      picked = await picker.pickImage(source: ImageSource.gallery);
    }
    if (picked == null) return;

    final raw = File(picked.path);
    
    if (isVideo) {
      _videoController?.dispose();
      _videoController = VideoPlayerController.file(raw);
      await _videoController!.initialize();
      _videoController!.setLooping(true);
      _videoController!.play();
    }

    setState(() {
      _rawFile = raw;
      _displayFile = raw; // Show original immediately to avoid glitch/delay
      _mediaType = isVideo ? 'video' : 'image';
    });

    if (!isVideo) {
      // Background crop
      _applyRatio(_aspectOptions[_selectedRatioIndex].ratio);
    }
  }

  // ── Crop / resize to chosen ratio ────────────────────────────────────────
  Future<void> _applyRatio(double? ratio) async {
    if (_rawFile == null || _mediaType != 'image') return;

    if (ratio == null) {
      setState(() {
        _displayFile = _rawFile;
      });
      return;
    }

    try {
      final Uint8List bytes = await _rawFile!.readAsBytes();
      final dir = await getTemporaryDirectory();
      final path = '${dir.path}/post_${ratio.toStringAsFixed(2)}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      
      final args = _CropArgs(bytes, ratio, path);
      final success = await compute(_processAndCropImage, args);
      
      if (mounted) {
        setState(() {
          if (success) {
            _displayFile = File(path);
          }
        });
      }
    } catch (e) {
      debugPrint('Crop dispatch error: $e');
      if (mounted) {
        setState(() {
          _displayFile = _rawFile; // Fallback to raw on error
        });
      }
    }
  }

  Future<void> _onRatioSelected(int idx) async {
    setState(() => _selectedRatioIndex = idx);
    await _applyRatio(_aspectOptions[idx].ratio);
  }

  // ── Submit ───────────────────────────────────────────────────────────────
  Future<void> _submitPost() async {
    final title = _titleController.text.trim();
    final description = _descController.text.trim();
    final uploadFile = _displayFile ?? _rawFile;

    if (description.length > 500) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Post is limited to 500 characters.')),
      );
      return;
    }

    if (title.isEmpty && description.isEmpty && uploadFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add text or media before posting')),
      );
      return;
    }

    setState(() => _isPosting = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final mobile = prefs.getString('user_phone') ?? '';

      final req = http.MultipartRequest(
        'POST',
        Uri.parse('https://team.cropsync.in/cine_circle/social_api.php'),
      );
      req.fields['action'] = 'create_post';
      req.fields['mobile_number'] = mobile;
      req.fields['category'] = _category;
      req.fields['title'] = title;
      req.fields['description'] = description;
      req.fields['media_type'] = _mediaType;

      if (uploadFile != null) {
        req.files.add(
          await http.MultipartFile.fromPath('media', uploadFile.path),
        );
      }

      final streamed = await req.send();
      final response = await http.Response.fromStream(streamed);

      if (!mounted) return;

      if (response.statusCode == 200) {
        try {
          final data = json.decode(response.body);
          final postId = data['post_id']?.toString() ?? '';
          if (postId.isNotEmpty) {
            await _saveAspectRatio(postId);
          }
        } catch (_) {}
        await _awardCredits(mobile);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.stars_rounded, color: Colors.amber, size: 20),
                SizedBox(width: 10),
                Text(
                  'Posted! You earned 10 CineCredits 🎬',
                  style: TextStyle(fontFamily: 'Google Sans'),
                ),
              ],
            ),
            backgroundColor: Colors.black,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed (${response.statusCode})')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isPosting = false);
    }
  }

  Future<void> _awardCredits(String mobile) async {
    try {
      final res = await http.post(
        Uri.parse('https://team.cropsync.in/cine_circle/social_api.php'),
        body: {
          'action': 'award_social_credits',
          'mobile_number': mobile,
          'amount': '10',
          'activity': 'POST_CREATED',
          'description': 'Created a new post in Circle',
        },
      );
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        final balance = int.tryParse(data['new_balance']?.toString() ?? '');
        if (balance != null) {
          GlobalNotifier.instance.updateCredits(balance);
        }
      }
    } catch (_) {}
  }

  Future<void> _saveAspectRatio(String postId) async {
    if (_mediaType != 'image') return;
    final ratio = _aspectOptions[_selectedRatioIndex].ratio;
    if (ratio == null) return;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('post_aspect_ratios') ?? '{}';
    final Map<String, dynamic> map = json.decode(raw);
    map[postId] = ratio;
    await prefs.setString('post_aspect_ratios', json.encode(map));
  }

  // ── Build ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF9FAFB),
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'New Post',
          style: TextStyle(
            fontFamily: 'Google Sans',
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.black,
          ),
        ),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.close, color: Colors.black),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // ── Category chips ──
              _sectionLabel('CATEGORY'),
              const SizedBox(height: 10),
              SizedBox(
                height: 54,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  itemCount: _categories.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (_, i) {
                    final sel = _category == _categories[i];
                    return GestureDetector(
                      onTap: () => setState(() => _category = _categories[i]),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: sel ? Colors.black : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: sel ? Colors.black : Colors.grey.shade300,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          _categories[i],
                          style: TextStyle(
                            fontFamily: 'Google Sans',
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: sel ? Colors.white : Colors.black87,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),

              // ── Title ──
              _sectionLabel('HEADLINE *'),
              const SizedBox(height: 10),
              TextField(
                controller: _titleController,
                maxLength: 120,
                textCapitalization: TextCapitalization.sentences,
                style: const TextStyle(
                  fontFamily: 'Google Sans',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
                decoration: InputDecoration(
                  hintText: 'Give your post a headline...',
                  hintStyle: TextStyle(
                    color: Colors.grey.shade400,
                    fontWeight: FontWeight.normal,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(
                      color: Colors.black,
                      width: 1.5,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // ── Description ──
              _sectionLabel('CAPTION'),
              const SizedBox(height: 10),
              TextField(
                controller: _descController,
                maxLength: 500,
                maxLines: 3,
                textCapitalization: TextCapitalization.sentences,
                style: const TextStyle(
                  fontFamily: 'Google Sans',
                  fontSize: 14,
                  height: 1.5,
                ),
                decoration: InputDecoration(
                  hintText: 'Tell your circle more about this...',
                  hintStyle: TextStyle(color: Colors.grey.shade400),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(
                      color: Colors.black,
                      width: 1.5,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // ── Media section ──
              _sectionLabel('MEDIA'),
              const SizedBox(height: 10),

              if (_rawFile == null) ...[
                // Media pickers
                Row(
                  children: [
                    Expanded(
                      child: _mediaTile(
                        icon: Icons.image_rounded,
                        label: 'Photo',
                        color: const Color(0xFFEEF4FF),
                        iconColor: const Color(0xFF3B82F6),
                        onTap: () => _pickMedia(false),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _mediaTile(
                        icon: Icons.videocam_rounded,
                        label: 'Video',
                        color: const Color(0xFFF5F0FF),
                        iconColor: const Color(0xFF8B5CF6),
                        onTap: () => _pickMedia(true),
                      ),
                    ),
                  ],
                ),
              ] else ...[
                // Media preview + controls
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Stack(
                    children: [
                      // Preview
                      if (_mediaType == 'image' && _displayFile != null)
                        AspectRatio(
                          aspectRatio: _aspectOptions[_selectedRatioIndex].ratio ?? 1.0,
                          child: Image.file(
                            _displayFile!,
                            fit: BoxFit.cover,
                            width: double.infinity,
                          ),
                        )
                      else
                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.black,
                            border: Border.symmetric(
                              horizontal: BorderSide(color: Colors.grey.shade200, width: 0.5),
                            ),
                          ),
                          child: _videoController != null && _videoController!.value.isInitialized
                              ? GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _videoController!.value.isPlaying
                                          ? _videoController!.pause()
                                          : _videoController!.play();
                                    });
                                  },
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      AspectRatio(
                                        aspectRatio: _videoController!.value.aspectRatio,
                                        child: VideoPlayer(_videoController!),
                                      ),
                                      if (!_videoController!.value.isPlaying)
                                        Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: const BoxDecoration(
                                            color: Colors.black45,
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 40),
                                        ),
                                    ],
                                  ),
                                )
                              : const SizedBox(
                                  height: 200,
                                  child: Center(
                                    child: CircularProgressIndicator(color: Colors.white70),
                                  ),
                                ),
                        ),

                      // Top-right close
                      Positioned(
                        top: 10,
                        right: 10,
                        child: GestureDetector(
                          onTap: () => setState(() {
                            _rawFile = _displayFile = null;
                            _videoController?.dispose();
                            _videoController = null;
                          }),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(
                              color: Colors.black54,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ),
                      ),

                      // Top-left media type badge
                      Positioned(
                        top: 10,
                        left: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _mediaType == 'image' ? '🖼 Image' : '🎬 Video',
                            style: const TextStyle(
                              fontFamily: 'Google Sans',
                              fontSize: 12,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Aspect ratio row (images only)
                if (_mediaType == 'image') ...[
                  const SizedBox(height: 12),
                  _sectionLabel('CROP / ASPECT RATIO'),
                  const SizedBox(height: 10),
                  Row(
                    children: List.generate(_aspectOptions.length, (i) {
                      final opt = _aspectOptions[i];
                      final sel = _selectedRatioIndex == i;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () => _onRatioSelected(i),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: EdgeInsets.only(
                              right: i < _aspectOptions.length - 1 ? 8 : 0,
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: sel ? Colors.black : Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: sel
                                    ? Colors.black
                                    : Colors.grey.shade300,
                                width: 1.5,
                              ),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  opt.icon,
                                  size: 20,
                                  color: sel
                                      ? Colors.white
                                      : Colors.grey.shade600,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  opt.label,
                                  style: TextStyle(
                                    fontFamily: 'Google Sans',
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: sel ? Colors.white : Colors.black87,
                                  ),
                                ),
                                Text(
                                  opt.sublabel,
                                  style: TextStyle(
                                    fontFamily: 'Google Sans',
                                    fontSize: 10,
                                    color: sel
                                        ? Colors.white70
                                        : Colors.grey.shade500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ],
              ],

              const SizedBox(height: 24),

              // ── Post button ──
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _isPosting ? null : _submitPost,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _isPosting
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.send_rounded, size: 20),
                            SizedBox(width: 10),
                            Text(
                              'Post to Circle',
                              style: TextStyle(
                                fontFamily: 'Google Sans',
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────────────
  Widget _sectionLabel(String text) => Text(
    text,
    style: TextStyle(
      fontFamily: 'Google Sans',
      fontSize: 11,
      fontWeight: FontWeight.w800,
      color: Colors.grey.shade500,
      letterSpacing: 1.2,
    ),
  );

  Widget _mediaTile({
    required IconData icon,
    required String label,
    required Color color,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 22),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          children: [
            Icon(icon, size: 36, color: iconColor),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Google Sans',
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: iconColor,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'from gallery',
              style: TextStyle(
                fontFamily: 'Google Sans',
                fontSize: 11,
                color: iconColor.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
