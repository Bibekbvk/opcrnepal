import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'services/storage_service.dart';
import 'views/certificate_view.dart';
import 'views/admin_view.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  print('DEBUG: main() started');

  // Create storage service (does NOT auto-init)
  final storageService = StorageService();

  // Initialize Firebase FIRST if configured
  if (storageService.isFirebaseActive) {
    try {
      print('DEBUG: Initializing Firebase client...');
      await Firebase.initializeApp(
        options: const FirebaseOptions(
          apiKey: StorageService.firebaseApiKey,
          authDomain: StorageService.firebaseAuthDomain,
          projectId: StorageService.firebaseProjectId,
          storageBucket: StorageService.firebaseStorageBucket,
          messagingSenderId: StorageService.firebaseMessagingSenderId,
          appId: StorageService.firebaseAppId,
        ),
      );
      print('DEBUG: Firebase client initialized');
    } catch (e) {
      print('DEBUG: Firebase initialization error: $e');
    }
  }

  // NOW initialize StorageService (Firestore is available)
  await storageService.init();
  print('DEBUG: StorageService initialized');
  
  runApp(MyApp(storageService: storageService));
  print('DEBUG: runApp() called');
}

class MyApp extends StatelessWidget {
  final StorageService storageService;

  const MyApp({super.key, required this.storageService});

  @override
  Widget build(BuildContext context) {
    print('DEBUG: MyApp.build() called');
    return ListenableBuilder(
      listenable: storageService,
      builder: (context, _) {
        print('DEBUG: ListenableBuilder builder() called. Storage initialized: ${storageService.isInitialized}');
        return MaterialApp(
          title: 'Police Clearance Certificate Verification',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF0F172A), // Slate 900
              primary: const Color(0xFF0F172A),
              secondary: const Color(0xFF10B981), // Emerald 500
            ),
          ),
          initialRoute: '/',
          onGenerateRoute: (settings) {
            print('DEBUG: onGenerateRoute() called for route: ${settings.name}');
            // Helper to parse query parameters from a route string or from Uri.base
            final Uri baseUri = Uri.base;
            print('DEBUG: Uri.base: $baseUri');
            
            // Check if the current route name is admin or if we explicitly load page=admin
            final String routeName = settings.name ?? '/';
            final bool isAdminRoute = routeName == '/admin' || 
                                     routeName.startsWith('/admin?') ||
                                     baseUri.queryParameters['page'] == 'admin';

            if (isAdminRoute) {
              print('DEBUG: Routing to AdminView');
              return MaterialPageRoute(
                builder: (context) => AdminView(
                  storageService: storageService,
                  onGoToPublic: () {
                    Navigator.pushReplacementNamed(context, '/');
                  },
                  onViewCertificate: (id) {
                    // Navigate to public view for a specific certificate
                    Navigator.pushNamed(context, '/?id=$id');
                  },
                ),
                settings: RouteSettings(name: '/admin', arguments: settings.arguments),
              );
            }

            // Otherwise, route to public CertificateView
            // Extract the certificate ID from either URL query parameters (for direct links)
            // or from the route settings name (for in-app Navigation)
            String? certId = baseUri.queryParameters['id'];
            String? dispatch = baseUri.queryParameters['dispatch'];

            // Parse settings.name in case of in-app pushes e.g., '/?id=abc'
            if (routeName.contains('?')) {
              final parsed = Uri.parse(routeName);
              if (parsed.queryParameters.containsKey('id')) {
                certId = parsed.queryParameters['id'];
              }
              if (parsed.queryParameters.containsKey('dispatch')) {
                dispatch = parsed.queryParameters['dispatch'];
              }
            }

            print('DEBUG: Routing to CertificateView with certId: $certId, dispatch: $dispatch');
            return MaterialPageRoute(
              builder: (context) => CertificateView(
                storageService: storageService,
                certificateId: certId,
                dispatchNumber: dispatch,
                onGoToAdmin: () {
                  Navigator.pushNamed(context, '/admin');
                },
              ),
              settings: settings,
            );
          },
        );
      },
    );
  }
}
