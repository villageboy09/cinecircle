// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _roleController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();

  bool _isLoading = false;
  File? _imageFile;
  String? _existingImageUrl;

  bool _isValidName(String value) {
    return RegExp(r"^[A-Za-z][A-Za-z .'-]{1,59}$").hasMatch(value.trim());
  }

  bool _isValidCity(String value) {
    return RegExp(
      r"^[A-Za-z0-9][A-Za-z0-9 .,'-]{1,79}$",
    ).hasMatch(value.trim());
  }

  Future<void> _pickAndUploadImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });

      final prefs = await SharedPreferences.getInstance();
      final mobile = prefs.getString('user_phone') ?? '';
      if (mobile.isEmpty) return;

      setState(() => _isLoading = true);

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('https://team.cropsync.in/cine_circle/cinecircle_api.php'),
      );
      request.fields['action'] = 'upload_profile_image';
      request.fields['mobile_number'] = mobile;
      request.files.add(
        await http.MultipartFile.fromPath('image', pickedFile.path),
      );

      try {
        var streamedResponse = await request.send();
        if (streamedResponse.statusCode == 200) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Profile image uploaded!')),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Upload failed: $e')));
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _loadCurrentData();
  }

  Future<void> _loadCurrentData() async {
    final prefs = await SharedPreferences.getInstance();
    final String mobile = prefs.getString('user_phone') ?? '';

    setState(() {
      _nameController.text = prefs.getString('user_name') ?? '';
      _roleController.text =
          prefs.getString('account_type') ?? 'Aspiring Actor';
    });

    if (mobile.isEmpty) return;

    try {
      final response = await http.post(
        Uri.parse('https://team.cropsync.in/cine_circle/cinecircle_api.php'),
        body: {'action': 'get_profile', 'mobile_number': mobile},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          final profile = data['profile'];
          if (mounted) {
            setState(() {
              _nameController.text =
                  profile['full_name'] ?? _nameController.text;

              if (profile['role_title'] != null &&
                  profile['role_title'].toString().isNotEmpty) {
                _roleController.text = profile['role_title'];
              } else {
                _roleController.text = 'Aspiring Actor';
              }

              _cityController.text = profile['city'] ?? '';
              _bioController.text = profile['bio'] ?? '';
              _existingImageUrl = profile['profile_image_url'];
            });
          }
        }
      }
    } catch (e) {
      // Fallback
    }
  }

  Future<void> _saveProfile() async {
    setState(() {
      _isLoading = true;
    });

    final prefs = await SharedPreferences.getInstance();
    final String mobile = prefs.getString('user_phone') ?? '';

    if (mobile.isEmpty) {
      setState(() => _isLoading = false);
      return;
    }

    final name = _nameController.text.trim();
    final city = _cityController.text.trim();

    if (!_isValidName(name)) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid name using letters only.')),
      );
      return;
    }

    if (city.isNotEmpty && !_isValidCity(city)) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Enter a valid city name.')));
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('https://team.cropsync.in/cine_circle/cinecircle_api.php'),
        body: {
          'action': 'update_profile',
          'mobile_number': mobile,
          'full_name': name,
          'role_title': _roleController.text,
          'city': city,
          'bio': _bioController.text,
        },
      );

      if (!mounted) return;
      if (response.statusCode == 200) {
        await prefs.setString('user_name', name);
        await prefs.setString('account_type', _roleController.text);
        if (!mounted) return;
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update profile')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const BackButton(color: Colors.black),
        title: const Text(
          'Edit Profile',
          style: TextStyle(
            fontFamily: 'Google Sans',
            color: Colors.black,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Center(
              child: GestureDetector(
                onTap: _pickAndUploadImage,
                child: Stack(
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.grey.shade300,
                          width: 2,
                        ),
                        image: _imageFile != null
                            ? DecorationImage(
                                image: FileImage(_imageFile!),
                                fit: BoxFit.cover,
                              )
                            : (_existingImageUrl != null &&
                                  _existingImageUrl!.isNotEmpty)
                            ? DecorationImage(
                                image: CachedNetworkImageProvider(
                                  _existingImageUrl!,
                                ),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child:
                          (_imageFile == null &&
                              (_existingImageUrl == null ||
                                  _existingImageUrl!.isEmpty))
                          ? const Icon(
                              Icons.person,
                              size: 50,
                              color: Colors.grey,
                            )
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: Colors.black,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.camera_alt,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            _buildTextField(label: 'Full Name', controller: _nameController),
            const SizedBox(height: 16),
            _buildTextField(label: 'Role Title', controller: _roleController),
            const SizedBox(height: 16),
            _buildTextField(label: 'City', controller: _cityController),
            const SizedBox(height: 16),
            _buildTextField(
              label: 'Bio',
              controller: _bioController,
              maxLines: 4,
              maxLength: 250,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  disabledBackgroundColor: Colors.grey.shade400,
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Save Details',
                        style: TextStyle(
                          fontFamily: 'Google Sans',
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    int maxLines = 1,
    int? maxLength,
  }) {
    final List<TextInputFormatter>? formatters = label == 'Full Name'
        ? [FilteringTextInputFormatter.allow(RegExp(r"[A-Za-z .'-]"))]
        : label == 'City'
        ? [FilteringTextInputFormatter.allow(RegExp(r"[A-Za-z0-9 .,'-]"))]
        : null;

    return TextField(
      controller: controller,
      maxLines: maxLines,
      maxLength: maxLength,
      inputFormatters: formatters,
      style: const TextStyle(
        fontFamily: 'Google Sans',
        fontSize: 16,
        color: Colors.black,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: Colors.grey.shade600,
          fontFamily: 'Google Sans',
        ),
        alignLabelWithHint: maxLines > 1,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.black),
        ),
      ),
    );
  }
}
