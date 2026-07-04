# Police Clearance Certificate Verification System

A Flutter web-based verification system with an administrative dashboard for managing certificates, storing data securely in Firebase Firestore, and deployed via Firebase Hosting.

## Features
- **Admin Dashboard (`/?page=admin`)**: Create, update, list, and delete certificates. Includes optimized photo compression (JPEG, max 300x400 at 40% quality) to stay within Firestore document limits.
- **Verification Page**: Beautiful public view of certificate details (dispatch status, issue date, metadata, etc.) queried live from Firestore.
- **Firebase Core/Firestore Integration**: Instant database updates with local-storage fallback.

---

## Setup & Running on Another PC

### 1. Prerequisites
- **Flutter SDK**: Make sure Flutter is installed and added to your system path.
- **Firebase CLI**: Install the Firebase CLI tools if you want to deploy (`npm install -g firebase-tools`).

### 2. Getting Started
Clone the repository:
```bash
git clone https://github.com/Bibekbvk/opcrnepal.git
cd opcrnepal
```

Install the dependencies:
```bash
flutter pub get
```

### 3. Run Locally
Run the app in your browser:
```bash
flutter run -d chrome
```

---

## Firebase Configuration

This app is configured to use a unified Firebase project (`opcr-gov-np-verification`). The credentials and configurations are pre-defined in:
- `lib/services/storage_service.dart` (Firebase project credentials: API key, project ID, storage bucket, etc.)
- `firebase.json` (Firebase CLI deployment rules)
- `firestore.rules` & `storage.rules` (Security rules)

### Deploying Changes
If you make changes to the app and want to deploy the updated version to the web:

1. **Login to Firebase**:
   ```bash
   firebase login
   ```
2. **Build the production web assets**:
   ```bash
   flutter build web
   ```
3. **Deploy to Firebase Hosting**:
   ```bash
   firebase deploy --only hosting
   ```

Your live site URL will be: `https://opcr-gov-np-verification.web.app`
