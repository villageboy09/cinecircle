import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

const _jobDetailApiBase = 'https://team.cropsync.in/cine_circle/jobs_api.php';

class JobDetailScreen extends StatefulWidget {
  final String jobId;
  final String jobType; // 'casting' | 'daily'
  final VoidCallback? onApplied;

  const JobDetailScreen({
    super.key,
    required this.jobId,
    required this.jobType,
    this.onApplied,
  });

  @override
  State<JobDetailScreen> createState() => _JobDetailScreenState();
}

class _JobDetailScreenState extends State<JobDetailScreen> {
  bool _isLoading = true;
  bool _isApplying = false;
  bool _isSaving = false;
  Map<String, dynamic>? _job;

  @override
  void initState() {
    super.initState();
    _fetchDetail();
  }

  Future<String> _getMobile() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_phone') ?? '';
  }

  Future<void> _fetchDetail() async {
    setState(() => _isLoading = true);
    try {
      final mobile = await _getMobile();
      final res = await http.get(Uri.parse(
        '$_jobDetailApiBase?action=get_job_detail&mobile_number=$mobile&job_id=${widget.jobId}&job_type=${widget.jobType}',
      ));
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        if (data['status'] == 'success') {
          setState(() => _job = data['data']);
        }
      }
    } catch (e) {
      debugPrint('fetchDetail error: $e');
    }
    setState(() => _isLoading = false);
  }

  Future<void> _applyJob() async {
    final job = _job;
    if (job == null || job['has_applied'] == true) return;

    // Show cover note bottom sheet
    final coverNote = await _showApplySheet();
    if (coverNote == null) return; // user cancelled

    setState(() => _isApplying = true);
    try {
      final mobile = await _getMobile();
      final res = await http.post(
        Uri.parse(_jobDetailApiBase),
        body: {
          'action': 'apply_job',
          'mobile_number': mobile,
          'job_id': widget.jobId,
          'job_type': widget.jobType,
          'cover_note': coverNote,
        },
      );
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        if (data['status'] == 'success' || data['status'] == 'already_applied') {
          setState(() => _job!['has_applied'] = true);
          widget.onApplied?.call();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(data['message'] ?? 'Applied!', style: const TextStyle(fontFamily: 'Google Sans')),
              backgroundColor: Colors.green.shade700,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ));
          }
        }
      }
    } catch (e) {
      debugPrint('applyJob error: $e');
    }
    setState(() => _isApplying = false);
  }

  Future<String?> _showApplySheet() async {
    final ctrl = TextEditingController();
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 24, right: 24, top: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 20),
            const Text('Apply for this role', style: TextStyle(fontFamily: 'Google Sans', fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextField(
              controller: ctrl,
              maxLines: 4,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                hintText: 'Add a short note (optional)...',
                hintStyle: TextStyle(fontFamily: 'Google Sans', color: Colors.grey.shade500),
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.all(16),
              ),
              style: const TextStyle(fontFamily: 'Google Sans'),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Submit Application', style: TextStyle(fontFamily: 'Google Sans', fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleSave() async {
    setState(() => _isSaving = true);
    try {
      final mobile = await _getMobile();
      final res = await http.post(
        Uri.parse(_jobDetailApiBase),
        body: {
          'action': 'toggle_save_job',
          'mobile_number': mobile,
          'job_id': widget.jobId,
          'job_type': widget.jobType,
        },
      );
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        if (data['status'] == 'success') {
          setState(() => _job!['is_saved'] = data['is_saved']);
        }
      }
    } catch (e) {
      debugPrint('toggleSave error: $e');
    }
    setState(() => _isSaving = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        title: Image.asset('assets/cinelogo.png', height: 32, fit: BoxFit.contain),
        centerTitle: true,
        actions: [
          if (_job != null)
            _isSaving
                ? const Padding(padding: EdgeInsets.all(14), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2)))
                : IconButton(
                    icon: Icon(_job!['is_saved'] == true ? Icons.bookmark : Icons.bookmark_border, color: Colors.black),
                    onPressed: _toggleSave,
                  ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.black))
          : _job == null
              ? const Center(child: Text('Job not found.', style: TextStyle(fontFamily: 'Google Sans')))
              : _buildBody(),
    );
  }

  Widget _buildBody() {
    final job = _job!;
    final isCasting = widget.jobType == 'casting';
    final hasApplied = job['has_applied'] == true;
    final hasImage = job['image_url'] != null && (job['image_url'] as String).isNotEmpty;
    final int applicantCount = job['applicant_count'] ?? 0;

    final List<dynamic> requirements      = job['requirements'] ?? [];
    final List<dynamic> responsibilities  = job['responsibilities'] ?? [];
    final List<dynamic> submissionMats    = job['submission_materials'] ?? [];

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Optional banner image
          if (hasImage) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(job['image_url'], height: 180, width: double.infinity, fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => const SizedBox.shrink()),
            ),
            const SizedBox(height: 20),
          ],

          // Title
          Text(job['title'] ?? '',
              style: const TextStyle(fontFamily: 'Google Sans', fontSize: 28, fontWeight: FontWeight.w600, color: Colors.black, letterSpacing: -0.5)),
          const SizedBox(height: 8),

          // Company / location
          if (isCasting) ...[
            Text('${job['company'] ?? ''} • ${job['location'] ?? ''}',
                style: const TextStyle(fontFamily: 'Google Sans', fontSize: 15, color: Colors.black87)),
            const SizedBox(height: 4),
            Text('${job['pay_type'] ?? ''} • Posted ${job['time_ago'] ?? ''}',
                style: const TextStyle(fontFamily: 'Google Sans', fontSize: 15, color: Colors.black87)),
          ] else ...[
            Text('${job['role_type'] ?? ''} | ${job['project_type'] ?? ''} | ${job['location'] ?? ''}',
                style: const TextStyle(fontFamily: 'Google Sans', fontSize: 15, color: Colors.black87)),
            const SizedBox(height: 4),
            Text('${job['shoot_date'] ?? ''} • ${job['pay_per_day'] ?? ''} • Posted ${job['time_ago'] ?? ''}',
                style: const TextStyle(fontFamily: 'Google Sans', fontSize: 15, color: Colors.black87)),
          ],

          // Applicant count badge
          if (applicantCount > 0) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(20)),
              child: Text('$applicantCount applicant${applicantCount != 1 ? 's' : ''}',
                  style: TextStyle(fontFamily: 'Google Sans', fontSize: 12, color: Colors.grey.shade700)),
            ),
          ],

          if (job['is_urgent'] == true) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(border: Border.all(color: Colors.red.shade400), borderRadius: BorderRadius.circular(20)),
              child: Text('URGENT', style: TextStyle(fontFamily: 'Google Sans', fontSize: 11, color: Colors.red.shade600, fontWeight: FontWeight.bold)),
            ),
          ],

          const SizedBox(height: 24),
          // Description
          if (job['description'] != null && (job['description'] as String).isNotEmpty) ...[
            Text(job['description'], style: const TextStyle(fontFamily: 'Google Sans', fontSize: 15, color: Colors.black87, height: 1.5)),
            const SizedBox(height: 24),
          ],

          // Casting-specific sections
          if (isCasting) ...[
            if (requirements.isNotEmpty) ...[
              Divider(color: Colors.grey.shade300),
              const SizedBox(height: 16),
              _buildSection('Requirements', requirements),
            ],
            if (responsibilities.isNotEmpty) ...[
              const SizedBox(height: 8),
              Divider(color: Colors.grey.shade300),
              const SizedBox(height: 16),
              _buildSection('Responsibilities', responsibilities),
            ],
            if (submissionMats.isNotEmpty) ...[
              const SizedBox(height: 8),
              Divider(color: Colors.grey.shade300),
              const SizedBox(height: 16),
              _buildSection('Submission materials', submissionMats),
            ],
          ],

          const SizedBox(height: 32),
          // Apply button
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: hasApplied || _isApplying ? null : _applyJob,
              style: ElevatedButton.styleFrom(
                backgroundColor: hasApplied ? Colors.grey.shade300 : Colors.black,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _isApplying
                  ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                  : Text(
                      hasApplied ? 'Already Applied ✓' : 'Apply Now',
                      style: const TextStyle(fontFamily: 'Google Sans', fontSize: 16, fontWeight: FontWeight.w600),
                    ),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: TextButton.icon(
              onPressed: _toggleSave,
              icon: Icon(_job!['is_saved'] == true ? Icons.bookmark : Icons.bookmark_border, color: Colors.black),
              label: Text(
                _job!['is_saved'] == true ? 'Saved' : 'Save Job',
                style: const TextStyle(fontFamily: 'Google Sans', color: Colors.black, fontSize: 16, fontWeight: FontWeight.w500),
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<dynamic> bullets) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontFamily: 'Google Sans', fontSize: 18, fontWeight: FontWeight.w500, color: Colors.black)),
        const SizedBox(height: 12),
        ...bullets.map((b) => _buildBulletPoint(b.toString())),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('•', style: TextStyle(fontSize: 18, height: 1.2, color: Colors.black)),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(fontFamily: 'Google Sans', fontSize: 15, color: Colors.black87, height: 1.4))),
        ],
      ),
    );
  }
}
