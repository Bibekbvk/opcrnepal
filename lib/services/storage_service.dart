import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/certificate.dart';

class StorageService extends ChangeNotifier {
  // CONFIGURATION: Set your Firebase Web App credentials here to activate cloud mode
  static const String firebaseApiKey = 'AIzaSyAyyCpOgvNPWw2KBN0oCS764I_51d6efiU';
  static const String firebaseAuthDomain = 'opcr-gov-np-verification.firebaseapp.com';
  static const String firebaseProjectId = 'opcr-gov-np-verification';
  static const String firebaseStorageBucket = 'opcr-gov-np-verification.firebasestorage.app';
  static const String firebaseMessagingSenderId = '1023291726339';
  static const String firebaseAppId = '1:1023291726339:web:6d0a2986633e89c10f8c36';

  static const String _storageKey = 'certificates_list_v1';
  
  List<Certificate> _certificates = [];
  bool _initialized = false;

  List<Certificate> get certificates => _certificates;
  bool get isInitialized => _initialized;

  // Checks if Firebase config is populated
  bool get isFirebaseActive {
    return firebaseApiKey.isNotEmpty && 
           firebaseProjectId.isNotEmpty && 
           !firebaseApiKey.contains('YOUR_API');
  }

  StorageService();

  Future<void> init() async {
    print('DEBUG: StorageService.init() started. Cloud Mode: $isFirebaseActive');
    
    if (isFirebaseActive) {
      await _initCloud();
    } else {
      await _initLocal();
    }
  }

  // ==========================================
  // Local Database Fallback (Offline Mode)
  // ==========================================
  Future<void> _initLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? jsonStr = prefs.getString(_storageKey);
      
      if (jsonStr != null && jsonStr.isNotEmpty) {
        final List<dynamic> decodedList = jsonDecode(jsonStr);
        _certificates = decodedList.map((item) => Certificate.fromJson(item)).toList();
      } else {
        _certificates = [_getDefaultCertificate()];
        await _saveToLocalPrefs(prefs);
      }
    } catch (e) {
      print('DEBUG: Local init error: $e');
      _certificates = [_getDefaultCertificate()];
    }
    _initialized = true;
    notifyListeners();
  }

  Future<void> _saveToLocalPrefs(SharedPreferences prefs) async {
    final String encoded = jsonEncode(_certificates.map((c) => c.toJson()).toList());
    await prefs.setString(_storageKey, encoded);
  }

  // ==========================================
  // Firebase Cloud Mode
  // ==========================================
  Future<void> _initCloud() async {
    try {
      final firestore = FirebaseFirestore.instance;
      final snapshot = await firestore.collection('certificates').get();
      
      _certificates = snapshot.docs.map((doc) {
        final data = doc.data();
        // Inject ID from document ID in case it's missing in data
        if (!data.containsKey('id')) {
          data['id'] = doc.id;
        }
        return Certificate.fromJson(data);
      }).toList();
      
      if (_certificates.isEmpty) {
        // Seed default if database collection is empty
        final defaultCert = _getDefaultCertificate();
        await firestore.collection('certificates').doc(defaultCert.id).set(defaultCert.toJson());
        _certificates = [defaultCert];
      }
    } catch (e) {
      print('DEBUG: Firebase cloud init error: $e');
      // If cloud query fails, fall back to local storage
      await _initLocal();
      return;
    }
    _initialized = true;
    notifyListeners();
  }

  Certificate _getDefaultCertificate() {
    return Certificate(
      id: 'default-cert-id',
      dispatchNumber: '2082-646906',
      name: 'Ashma Ghimire',
      fathersName: 'Hom Nath Ghimire',
      gender: 'Female',
      nationality: 'Nepali',
      issuedDate: '2025-12-11',
      signatureName: 'Rajaram Khadka',
      signatureRank: 'Police Inspector',
      photoUrl: 'https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?q=80&w=600&auto=format&fit=crop',
      statusText: 'No Criminal Record Till 11 December 2025',
    );
  }

  // ==========================================
  // Database CRUD Actions
  // ==========================================
  Future<void> saveCertificate(Certificate certificate) async {
    // Always update in-memory list first so UI reflects changes immediately
    final index = _certificates.indexWhere((c) => c.id == certificate.id);
    if (index != -1) {
      _certificates[index] = certificate;
    } else {
      _certificates.add(certificate);
    }
    notifyListeners();

    // Then persist to cloud or local storage
    if (isFirebaseActive) {
      try {
        final firestore = FirebaseFirestore.instance;
        await firestore.collection('certificates').doc(certificate.id).set(certificate.toJson());
        print('DEBUG: Certificate saved to Firestore successfully');
      } catch (e) {
        print('DEBUG: Firebase save error: $e');
        // Fall back to local storage if cloud fails
        try {
          final prefs = await SharedPreferences.getInstance();
          await _saveToLocalPrefs(prefs);
          print('DEBUG: Saved to local storage as fallback');
        } catch (e2) {
          print('DEBUG: Local storage fallback also failed: $e2');
        }
      }
    } else {
      final prefs = await SharedPreferences.getInstance();
      await _saveToLocalPrefs(prefs);
    }
  }

  Future<void> deleteCertificate(String id) async {
    // Always remove from in-memory list first so UI updates immediately
    _certificates.removeWhere((c) => c.id == id);
    notifyListeners();

    // Then persist the deletion
    if (isFirebaseActive) {
      try {
        final firestore = FirebaseFirestore.instance;
        await firestore.collection('certificates').doc(id).delete();
        print('DEBUG: Certificate deleted from Firestore successfully');
      } catch (e) {
        print('DEBUG: Firebase delete error: $e');
        // Also save updated list to local storage as fallback
        try {
          final prefs = await SharedPreferences.getInstance();
          await _saveToLocalPrefs(prefs);
        } catch (_) {}
      }
    } else {
      final prefs = await SharedPreferences.getInstance();
      await _saveToLocalPrefs(prefs);
    }
  }

  // ==========================================
  // Image Storage Upload Action
  // ==========================================
  Future<String> uploadPhoto(Uint8List fileBytes, String fileName) async {
    if (isFirebaseActive) {
      try {
        final path = 'photos/${DateTime.now().millisecondsSinceEpoch}_$fileName';
        final storageRef = FirebaseStorage.instance.ref().child(path);
        
        // Upload bytes with proper content-type
        final uploadTask = storageRef.putData(
          fileBytes, 
          SettableMetadata(contentType: 'image/jpeg')
        );
        
        await uploadTask;
        return await storageRef.getDownloadURL();
      } catch (e) {
        print('DEBUG: Firebase storage upload error: $e');
        return 'data:image/jpeg;base64,${base64Encode(fileBytes)}';
      }
    } else {
      // Offline mode: return base64 string
      return 'data:image/jpeg;base64,${fileBytes.isEmpty ? "" : base64Encode(fileBytes)}';
    }
  }

  // ==========================================
  // Lookups
  // ==========================================
  Certificate? getCertificateById(String id) {
    try {
      return _certificates.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  Certificate? getCertificateByDispatch(String dispatchNumber) {
    try {
      return _certificates.firstWhere(
        (c) => c.dispatchNumber.trim().toLowerCase() == dispatchNumber.trim().toLowerCase()
      );
    } catch (_) {
      return null;
    }
  }
}
