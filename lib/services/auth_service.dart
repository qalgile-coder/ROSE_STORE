import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import '../core/secrets.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<UserCredential> signIn(String email, String password) async {
    return await _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  /// Google Sign-In with Account Picker & Robust Error Handling
  Future<UserCredential> signInWithGoogle() async {
    try {
      // 1. Trigger the Google Authentication flow
      // استخدام احتيادي لمسح أي جلسة سابقة عالقة لضمان ظهور نافذة اختيار الحساب بسلاسة
      final GoogleSignIn googleSignIn = GoogleSignIn();
      
      // محاولة تسجيل الخروج المحلي أولاً لتفادي تداخل الجلسات المعلقة
      if (await googleSignIn.isSignedIn()) {
        await googleSignIn.signOut();
      }

      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        throw Exception('Google Sign-In was cancelled by the user.');
      }

      // 2. Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // التأكد من توفر الـ tokens المطلوبة
      if (googleAuth.accessToken == null && googleAuth.idToken == null) {
        throw Exception('Failed to obtain Google authentication tokens.');
      }

      // 3. Create a new credential for Firebase
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // 4. Sign in to Firebase with the credential
      UserCredential userCredential = await _auth.signInWithCredential(credential);
      User? user = userCredential.user;

      if (user != null) {
        // 5. Check if user already exists in Firestore with timeout protection
        DocumentReference userDocRef = _db.collection('users').doc(user.uid);
        DocumentSnapshot userDoc = await userDocRef.get().timeout(
          const Duration(seconds: 10),
          onTimeout: () => throw Exception('Connection timeout while checking user profile.'),
        );

        if (!userDoc.exists) {
          // Create user document if it's their first time signing in via Google
          // استخدام set مع merge لتجنب الكتابة الفوقية الخاطئة إذا تم إنشاء المستند مسبقاً
          await userDocRef.set({
            'name': user.displayName ?? 'Google User',
            'email': user.email ?? '',
            'phone': user.phoneNumber ?? '',
            'role': 'customer',
            'shopId': null,
            'status': 'active',
            'createdAt': FieldValue.serverTimestamp(),
            'referredBy': null,
            'referralCode': user.uid.length >= 6 ? user.uid.substring(0, 6).toUpperCase() : user.uid.toUpperCase(),
          }, SetOptions(merge: true));
        }
      }

      return userCredential;
    } catch (e) {
      debugPrint('Error during Google Sign-In: $e');
      // إعادة رمي الخطأ ليتم التقاطه بوضوح في واجهة المستخدم (UI) مع رسالة مفهومة
      rethrow;
    }
  }

  Future<void> signUpCustomer({
    required String name,
    required String email,
    required String phone,
    required String password,
    String? referredBy,
  }) async {
    UserCredential credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    await _db.collection('users').doc(credential.user!.uid).set({
      'name': name,
      'email': email,
      'phone': phone,
      'role': 'customer',
      'shopId': null,
      'status': 'active',
      'createdAt': FieldValue.serverTimestamp(),
      'referredBy': referredBy,
      'referralCode': credential.user!.uid.length >= 6 ? credential.user!.uid.substring(0, 6).toUpperCase() : credential.user!.uid.toUpperCase(),
    });
  }

  /// Super Admin creating Vendor/Rider without logging out
  Future<void> createSubUser({
    required String name,
    required String email,
    required String phone,
    required String password,
    required String role, // 'vendor' or 'rider'
    String? shopName,
    String? shopCategory,
    String? vehicleInfo,
    String? licenseNumber,
  }) async {
    FirebaseApp secondaryApp = await Firebase.initializeApp(
      name: 'secondaryAuthApp',
      options: Firebase.app().options,
    );

    try {
      FirebaseAuth secondaryAuth = FirebaseAuth.instanceFor(app: secondaryApp);
      
      UserCredential credential = await secondaryAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      String uid = credential.user!.uid;
      String? shopId;

      if (role == 'vendor' && shopName != null) {
        DocumentReference shopRef = _db.collection('shops').doc();
        shopId = shopRef.id;
        await shopRef.set({
          'name': shopName,
          'vendorId': uid,
          'category': shopCategory ?? 'General',
          'status': 'active',
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      await _db.collection('users').doc(uid).set({
        'name': name,
        'email': email,
        'phone': phone,
        'role': role,
        'shopId': shopId,
        'vehicleInfo': vehicleInfo,
        'licenseNumber': licenseNumber,
        'isOnline': false,
        'rating': 5.0,
        'totalDeliveries': 0,
        'totalEarnings': 0.0,
        'status': 'active',
        'createdAt': FieldValue.serverTimestamp(),
      });
      
      final smtpServer = gmail(AppSecrets.smtpEmail, AppSecrets.smtpPassword);
      final message = Message()
        ..from = const Address(AppSecrets.smtpEmail, 'Zen Mart Pro')
        ..recipients.add(email)
        ..subject = 'Welcome to Zen Mart Pro - Your Account Credentials'
        ..html = '''
          <div style="font-family: sans-serif; padding: 20px; color: #1E293B;">
            <h2 style="color: #4F46E5;">Welcome to Zen Mart Pro!</h2>
            <p>Hello $name,</p>
            <p>Your account has been created as a <b>${role.toUpperCase()}</b>.</p>
            <p>You can now log in to the app using the following credentials:</p>
            <div style="background: #F1F5F9; padding: 15px; border-radius: 8px; margin: 20px 0;">
              <p style="margin: 5px 0;"><b>Email:</b> $email</p>
              <p style="margin: 5px 0;"><b>Password:</b> $password</p>
            </div>
            <p>Please change your password after your first login for security.</p>
            <br>
            <p>Best Regards,<br>Management Team</p>
          </div>
        ''';
      
      await send(message, smtpServer);
      await secondaryAuth.signOut();
    } finally {
      await secondaryApp.delete();
    }
  }

  Stream<UserModel?> getUserStream(String uid) {
    return _db.collection('users').doc(uid).snapshots().map((doc) {
      if (doc.exists) {
        return UserModel.fromFirestore(doc);
      }
      return null;
    });
  }

  Future<UserModel?> getUserData(String uid) async {
    try {
      DocumentSnapshot doc = await _db
          .collection('users')
          .doc(uid)
          .get()
          .timeout(const Duration(seconds: 10));
      if (doc.exists) {
        return UserModel.fromFirestore(doc);
      }
    } catch (e) {
      debugPrint('Error fetching user data: $e');
      rethrow;
    }
    return null;
  }

  Future<void> signOut() async {
    try {
      await GoogleSignIn().signOut();
    } catch (_) {}
    await _auth.signOut();
  }

  Future<void> updateUserProfile({required String uid, required String name, required String phone}) async {
    await _db.collection('users').doc(uid).update({
      'name': name,
      'phone': phone,
    });
  }

  Future<void> updateProfilePicture(String uid, String imageUrl) async {
    await _db.collection('users').doc(uid).update({
      'profilePicture': imageUrl,
    });
  }

  Future<void> generateReferralCode(String uid) async {
    final code = uid.length >= 6 ? uid.substring(0, 6).toUpperCase() : uid.toUpperCase();
    await _db.collection('users').doc(uid).update({
      'referralCode': code,
    });
  }

  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  Future<void> updatePassword(String currentPassword, String newPassword) async {
    User? user = _auth.currentUser;
    if (user != null && user.email != null) {
      AuthCredential credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );
      
      await user.reauthenticateWithCredential(credential);
      await user.updatePassword(newPassword);
    } else {
      throw Exception('No user logged in or email missing');
    }
  }
}