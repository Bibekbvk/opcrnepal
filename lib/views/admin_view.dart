import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import '../models/certificate.dart';
import '../services/storage_service.dart';

class AdminView extends StatefulWidget {
  final StorageService storageService;
  final VoidCallback onGoToPublic;
  final Function(String id) onViewCertificate;

  const AdminView({
    super.key,
    required this.storageService,
    required this.onGoToPublic,
    required this.onViewCertificate,
  });

  @override
  State<AdminView> createState() => _AdminViewState();
}

class _AdminViewState extends State<AdminView> {
  final _formKey = GlobalKey<FormState>();
  final _picker = ImagePicker();
  
  // Form controllers
  final _dispatchController = TextEditingController();
  final _nameController = TextEditingController();
  final _fathersNameController = TextEditingController();
  final _genderController = TextEditingController();
  final _nationalityController = TextEditingController();
  final _issuedDateController = TextEditingController();
  final _sigNameController = TextEditingController();
  final _sigRankController = TextEditingController();
  final _statusController = TextEditingController();
  
  Uint8List? _selectedPhotoBytes;
  String? _selectedPhotoName;
  String? _selectedPhotoUrl;
  String? _editingCertificateId; // Null if creating new

  @override
  void initState() {
    super.initState();
    // Default values to make adding data easier
    _genderController.text = 'Female';
    _nationalityController.text = 'Nepali';
    _sigRankController.text = 'Police Inspector';
    _issuedDateController.text = DateTime.now().toString().split(' ')[0]; // yyyy-MM-dd
    _statusController.text = 'No Criminal Record Till 11 December 2025';
  }

  @override
  void dispose() {
    _dispatchController.dispose();
    _nameController.dispose();
    _fathersNameController.dispose();
    _genderController.dispose();
    _nationalityController.dispose();
    _issuedDateController.dispose();
    _sigNameController.dispose();
    _sigRankController.dispose();
    _statusController.dispose();
    super.dispose();
  }

  // Load a certificate into the form for editing
  void _loadCertificateForEditing(Certificate cert) {
    setState(() {
      _editingCertificateId = cert.id;
      _dispatchController.text = cert.dispatchNumber;
      _nameController.text = cert.name;
      _fathersNameController.text = cert.fathersName;
      _genderController.text = cert.gender;
      _nationalityController.text = cert.nationality;
      _issuedDateController.text = cert.issuedDate;
      _sigNameController.text = cert.signatureName;
      _sigRankController.text = cert.signatureRank;
      _statusController.text = cert.statusText;
      _selectedPhotoUrl = cert.photoUrl;
      _selectedPhotoBytes = null;
      _selectedPhotoName = null;
    });
  }

  // Reset form to start fresh
  void _resetForm() {
    setState(() {
      _editingCertificateId = null;
      _dispatchController.clear();
      _nameController.clear();
      _fathersNameController.clear();
      _genderController.text = 'Female';
      _nationalityController.text = 'Nepali';
      _issuedDateController.text = DateTime.now().toString().split(' ')[0];
      _sigNameController.clear();
      _sigRankController.text = 'Police Inspector';
      _statusController.text = 'No Criminal Record Till 11 December 2025';
      _selectedPhotoUrl = null;
      _selectedPhotoBytes = null;
      _selectedPhotoName = null;
    });
  }

  // Pick an image and prepare for uploader
  Future<void> _pickImage() async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 300,
        maxHeight: 400,
        imageQuality: 40,
      );
      if (image != null) {
        final bytes = await image.readAsBytes();
        setState(() {
          _selectedPhotoBytes = bytes;
          _selectedPhotoName = image.name;
          _selectedPhotoUrl = 'data:image/jpeg;base64,${base64Encode(bytes)}';
        });
      }
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Failed to pick image: $e')),
      );
    }
  }

  // Save the certificate
  Future<void> _saveCertificate() async {
    if (!_formKey.currentState!.validate()) return;
    
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    if (_selectedPhotoUrl == null && _selectedPhotoBytes == null) {
      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('Please upload a photo for the certificate.')),
      );
      return;
    }

    String finalPhotoUrl = _selectedPhotoUrl ?? '';

    // If a new photo is selected, upload it first
    if (_selectedPhotoBytes != null) {
      try {
        finalPhotoUrl = await widget.storageService.uploadPhoto(
          _selectedPhotoBytes!,
          _selectedPhotoName ?? 'photo.jpg',
        );
      } catch (e) {
        scaffoldMessenger.showSnackBar(
          SnackBar(content: Text('Photo upload failed: $e')),
        );
        return;
      }
    }

    final newCert = Certificate(
      id: _editingCertificateId ?? const Uuid().v4(),
      dispatchNumber: _dispatchController.text.trim(),
      name: _nameController.text.trim(),
      fathersName: _fathersNameController.text.trim(),
      gender: _genderController.text.trim(),
      nationality: _nationalityController.text.trim(),
      issuedDate: _issuedDateController.text.trim(),
      signatureName: _sigNameController.text.trim(),
      signatureRank: _sigRankController.text.trim(),
      photoUrl: finalPhotoUrl,
      statusText: _statusController.text.trim(),
    );

    await widget.storageService.saveCertificate(newCert);

    scaffoldMessenger.showSnackBar(
      SnackBar(
        content: Text(_editingCertificateId != null 
            ? 'Certificate updated successfully!' 
            : 'New certificate created successfully!'),
        backgroundColor: Colors.green,
      ),
    );

    _resetForm();
  }

  // Copy shareable link to clipboard
  void _copyLink(Certificate cert) {
    final String url = '${Uri.base.origin}/?id=${cert.id}';
    Clipboard.setData(ClipboardData(text: url));
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text('Copied link: $url')),
          ],
        ),
        backgroundColor: Colors.blue[700],
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    print('DEBUG: AdminView.build() called');
    final isDesktop = MediaQuery.of(context).size.width > 900;
    final certList = widget.storageService.certificates;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: Text(
          'Certificate Admin Panel',
          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
        backgroundColor: const Color(0xFF0F172A), // Slate 900
        foregroundColor: Colors.white,
        actions: [
          TextButton.icon(
            onPressed: widget.onGoToPublic,
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            label: const Text('Back to Certificate', style: TextStyle(color: Colors.white)),
          ),
          const SizedBox(width: 10),
        ],
      ),
      backgroundColor: const Color(0xFFF1F5F9), // Slate 100
      body: SafeArea(
        child: ListenableBuilder(
          listenable: widget.storageService,
          builder: (context, _) {
            if (!widget.storageService.isInitialized) {
              return const Center(child: CircularProgressIndicator());
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 1200),
                  child: isDesktop
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Left side: Form uploader
                            Expanded(
                              flex: 6,
                              child: _buildFormCard(),
                            ),
                            const SizedBox(width: 24),
                            // Right side: Existing Certificates list
                            Expanded(
                              flex: 5,
                              child: _buildListCard(certList),
                            ),
                          ],
                        )
                      : Column(
                          children: [
                            _buildFormCard(),
                            const SizedBox(height: 24),
                            _buildListCard(certList),
                          ],
                        ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildFormCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _editingCertificateId != null ? 'Edit Certificate Details' : 'Create New Certificate',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1E293B),
                    ),
                  ),
                  if (_editingCertificateId != null)
                    TextButton.icon(
                      onPressed: _resetForm,
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Create New Instead'),
                    ),
                ],
              ),
              const Divider(height: 24),
              
              // Photo Uploader Section
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image uploader box
                  GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      width: 120,
                      height: 150,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: _selectedPhotoUrl != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: _selectedPhotoUrl!.startsWith('http')
                                  ? Image.network(_selectedPhotoUrl!, fit: BoxFit.cover)
                                  : Image.memory(base64Decode(_selectedPhotoUrl!.contains(',') ? _selectedPhotoUrl!.split(',').last : _selectedPhotoUrl!), fit: BoxFit.cover),
                            )
                          : const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_a_photo, color: Colors.grey, size: 30),
                                SizedBox(height: 8),
                                Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 8.0),
                                  child: Text(
                                    'Upload Photo',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(fontSize: 11, color: Colors.grey),
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Upload Candidate Photo',
                          style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Select a portrait image from your device. The image will be saved directly in your browser local storage as a Base64 string.',
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          onPressed: _pickImage,
                          icon: const Icon(Icons.upload, size: 16),
                          label: const Text('Select Image'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0F172A),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Inputs Grid
              LayoutBuilder(
                builder: (context, constraints) {
                  final useGrid = constraints.maxWidth > 500;
                  return Table(
                    columnWidths: useGrid 
                        ? const {0: FlexColumnWidth(1), 1: FlexColumnWidth(1)}
                        : const {0: FlexColumnWidth(1)},
                    children: [
                      TableRow(
                        children: [
                          _buildTextField('Dispatch Number', _dispatchController, 'e.g. 2082-646906'),
                          _buildTextField('Name', _nameController, 'e.g. Ashma Ghimire'),
                        ],
                      ),
                      TableRow(
                        children: [
                          _buildTextField("Father's Name", _fathersNameController, 'e.g. Hom Nath Ghimire'),
                          _buildTextField('Gender', _genderController, 'e.g. Female'),
                        ],
                      ),
                      TableRow(
                        children: [
                          _buildTextField('Nationality', _nationalityController, 'e.g. Nepali'),
                          _buildTextField('Issued Date', _issuedDateController, 'e.g. 2025-12-11'),
                        ],
                      ),
                      TableRow(
                        children: [
                          _buildTextField('Signature Name', _sigNameController, 'e.g. Rajaram Khadka'),
                          _buildTextField('Signature Rank', _sigRankController, 'e.g. Police Inspector'),
                        ],
                      ),
                    ],
                  );
                },
              ),
              
              _buildTextField('Status Badge Text', _statusController, 'e.g. No Criminal Record Till 11 December 2025', isFullWidth: true),
              
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _saveCertificate,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981), // Emerald 500
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: Text(
                  _editingCertificateId != null ? 'Update Certificate' : 'Save Certificate',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildListCard(List<Certificate> certList) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Stored Certificates (${certList.length})',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1E293B),
              ),
            ),
            const Divider(height: 24),
            certList.isEmpty
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 32.0),
                    child: Center(
                      child: Text('No certificates stored. Create one on the left.', style: TextStyle(color: Colors.grey)),
                    ),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: certList.length,
                    separatorBuilder: (context, index) => const Divider(height: 16),
                    itemBuilder: (context, index) {
                      final cert = certList[index];
                      return Container(
                        padding: const EdgeInsets.all(8.0),
                        decoration: BoxDecoration(
                          color: _editingCertificateId == cert.id ? Colors.blue.withOpacity(0.05) : null,
                          borderRadius: BorderRadius.circular(8),
                          border: _editingCertificateId == cert.id 
                              ? Border.all(color: Colors.blue.withOpacity(0.3))
                              : null,
                        ),
                        child: Row(
                          children: [
                            // Candidate thumbnail
                            Container(
                              width: 50,
                              height: 60,
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: cert.photoUrl.startsWith('http')
                                    ? Image.network(cert.photoUrl, fit: BoxFit.cover)
                                    : Image.memory(base64Decode(cert.photoUrl.contains(',') ? cert.photoUrl.split(',').last : cert.photoUrl), fit: BoxFit.cover),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    cert.name,
                                    style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14),
                                  ),
                                  Text(
                                    'Dispatch: ${cert.dispatchNumber}',
                                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.green.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      'Valid',
                                      style: TextStyle(color: Colors.green[800], fontSize: 10, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Action Buttons
                            Column(
                              children: [
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      tooltip: 'Copy shareable URL link',
                                      icon: const Icon(Icons.link, color: Colors.blue, size: 20),
                                      onPressed: () => _copyLink(cert),
                                    ),
                                    IconButton(
                                      tooltip: 'View in Verification Screen',
                                      icon: const Icon(Icons.visibility, color: Colors.green, size: 20),
                                      onPressed: () => widget.onViewCertificate(cert.id),
                                    ),
                                  ],
                                ),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      tooltip: 'Edit details',
                                      icon: const Icon(Icons.edit, color: Colors.orange, size: 20),
                                      onPressed: () => _loadCertificateForEditing(cert),
                                    ),
                                    IconButton(
                                      tooltip: 'Delete',
                                      icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                                      onPressed: () => _showDeleteConfirmation(cert),
                                    ),
                                  ],
                                ),
                              ],
                            )
                          ],
                        ),
                      );
                    },
                  ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(Certificate cert) {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    // If we're deleting the default mock data, warn that it will disappear
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Delete Certificate'),
          content: Text('Are you sure you want to delete the certificate for "${cert.name}"?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete'),
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                await widget.storageService.deleteCertificate(cert.id);
                if (_editingCertificateId == cert.id) {
                  _resetForm();
                }
                scaffoldMessenger.showSnackBar(
                  SnackBar(content: Text('Deleted certificate for ${cert.name}')),
                );
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, String hint, {bool isFullWidth = false}) {
    final fieldWidget = Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(fontWeight: FontWeight.w500, fontSize: 13, color: const Color(0xFF475569)),
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: controller,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: const BorderSide(color: Colors.blue, width: 1.5),
              ),
              filled: true,
              fillColor: Colors.white,
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return '$label is required';
              }
              return null;
            },
          ),
        ],
      ),
    );

    if (isFullWidth) {
      return fieldWidget;
    }
    
    // Fallback cell item inside the grid
    return fieldWidget;
  }
}
