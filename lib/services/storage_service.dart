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
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove(_storageKey);
        print('DEBUG: Cleared stale local SharedPreferences cache.');
      } catch (e) {
        print('DEBUG: Error clearing local SharedPreferences cache: $e');
      }
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
      dispatchNumber: '2083-285084',
      name: 'Arjun Ghimire',
      fathersName: 'Hom Nath Ghimire',
      gender: 'Male',
      nationality: 'Nepali',
      issuedDate: '2026-06-29',
      signatureName: 'Kashi Raj Thapa',
      signatureRank: 'Police Inspector',
      photoUrl: 'data:image/jpeg;base64,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',
      statusText: 'No Criminal Record Till 29 June 2026',
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
