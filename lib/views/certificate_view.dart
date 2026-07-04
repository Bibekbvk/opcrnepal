import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/certificate.dart';
import '../services/storage_service.dart';

class CertificateView extends StatelessWidget {
  final StorageService storageService;
  final String? certificateId;
  final String? dispatchNumber;
  final VoidCallback onGoToAdmin;

  const CertificateView({
    super.key,
    required this.storageService,
    this.certificateId,
    this.dispatchNumber,
    required this.onGoToAdmin,
  });

  @override
  Widget build(BuildContext context) {
    print('DEBUG: CertificateView.build() called. Storage initialized: ${storageService.isInitialized}');
    Certificate? cert;
    
    // Look up certificate by ID or Dispatch Number, fallback to the default/first one
    if (certificateId != null && certificateId!.isNotEmpty) {
      cert = storageService.getCertificateById(certificateId!);
    } else if (dispatchNumber != null && dispatchNumber!.isNotEmpty) {
      cert = storageService.getCertificateByDispatch(dispatchNumber!);
    }

    // Fallback: Use the default/first certificate available
    if (cert == null && storageService.certificates.isNotEmpty) {
      cert = storageService.certificates.first;
    }

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: const Color(0xFFF8FAFC), // Slate 50 background for the page
      body: cert == null
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: Stack(
                children: [
                  // Main scrollable content
                  SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
                    child: Center(
                      child: Container(
                        constraints: const BoxConstraints(maxWidth: 450),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 15,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // 1. Photo Section
                            Container(
                              height: 480,
                              decoration: const BoxDecoration(
                                border: Border(
                                  left: BorderSide(color: Colors.black, width: 2.0),
                                  right: BorderSide(color: Colors.black, width: 2.0),
                                ),
                              ),
                              child: Stack(
                                children: [
                                  // The Photo itself
                                  Positioned.fill(
                                    child: _buildPhoto(cert.photoUrl),
                                  ),
                                  // The decorative horizontal dash at the top-left
                                  Positioned(
                                    top: 15,
                                    left: 20,
                                    child: Container(
                                      width: 25,
                                      height: 3,
                                      decoration: BoxDecoration(
                                        color: Colors.grey[700],
                                        borderRadius: BorderRadius.circular(1.5),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            
                            // 2. Details Grid Section
                            Padding(
                              padding: const EdgeInsets.all(24.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Detail fields in a Table to align them perfectly like the screenshot
                                  Table(
                                    columnWidths: const {
                                      0: FlexColumnWidth(1.1),
                                      1: FlexColumnWidth(0.9),
                                    },
                                    children: [
                                      TableRow(
                                        children: [
                                          _buildDetailField('Dispatch Number', cert.dispatchNumber),
                                          _buildDetailField('Name', cert.name),
                                        ],
                                      ),
                                      TableRow(
                                        children: [
                                          _buildDetailField("Father's name", cert.fathersName),
                                          _buildDetailField('Gender', cert.gender),
                                        ],
                                      ),
                                      TableRow(
                                        children: [
                                          _buildDetailField('Nationality', cert.nationality),
                                          _buildDetailField('Issued Date', cert.issuedDate),
                                        ],
                                      ),
                                      TableRow(
                                        children: [
                                          _buildDetailField('Signature Name', cert.signatureName),
                                          _buildDetailField('Signature Rank', cert.signatureRank),
                                        ],
                                      ),
                                    ],
                                  ),
                                  
                                  const SizedBox(height: 20),
                                  
                                  // 3. Status Section
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Status',
                                          style: GoogleFonts.inter(
                                            color: const Color(0xFF94A3B8), // slate-400
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        // Green Pill Badge
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF22C55E), // Vibrant Green (no criminal record)
                                            borderRadius: BorderRadius.circular(20),
                                          ),
                                          child: Text(
                                            cert.statusText,
                                            style: GoogleFonts.inter(
                                              color: Colors.white,
                                              fontSize: 13.5,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Subtle settings icon at the bottom of the page or top right (outside the card) to access the admin panel
                  Positioned(
                    top: 16,
                    right: 16,
                    child: Tooltip(
                      message: 'Admin Panel',
                      child: InkWell(
                        onTap: onGoToAdmin,
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.admin_panel_settings,
                            color: Color(0xFF475569), // Slate 600
                            size: 24,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildDetailField(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              color: const Color(0xFF94A3B8), // slate-400 label
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: GoogleFonts.inter(
              color: const Color(0xFF1E293B), // slate-800 value
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhoto(String photo) {
    if (photo.startsWith('http://') || photo.startsWith('https://')) {
      return Image.network(
        photo,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return const Center(child: CircularProgressIndicator());
        },
        errorBuilder: (context, error, stackTrace) => const Center(
          child: Icon(Icons.broken_image, size: 80, color: Colors.grey),
        ),
      );
    } else {
      try {
        String cleanBase64 = photo;
        if (photo.contains(',')) {
          cleanBase64 = photo.split(',').last;
        }
        return Image.memory(
          base64Decode(cleanBase64),
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => const Center(
            child: Icon(Icons.person, size: 120, color: Colors.grey),
          ),
        );
      } catch (e) {
        return const Center(
          child: Icon(Icons.person, size: 120, color: Colors.grey),
        );
      }
    }
  }
}
