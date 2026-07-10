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
