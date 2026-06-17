import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/utils/app_logger.dart';
import '../models/user_model.dart';
import 'profile_photo_service.dart';
import 'user_service.dart';

class AuthService {
  final FirebaseAuth _auth;
  final UserService _userService;
  final ProfilePhotoService _profilePhotoService;

  AuthService({
    FirebaseAuth? auth,
    UserService? userService,
    ProfilePhotoService? profilePhotoService,
  }) : _auth = auth ?? FirebaseAuth.instance,
       _userService = userService ?? UserService(),
       _profilePhotoService = profilePhotoService ?? ProfilePhotoService();

  User? get currentFirebaseUser => _auth.currentUser;

  Future<void> loginWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      AppLogger.info('AuthService', 'Signing in with email/password.');
      await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    } on FirebaseAuthException catch (error) {
      AppLogger.error('AuthService.login', error);
      throw AuthServiceException(_messageForCode(error.code));
    } catch (error, stackTrace) {
      AppLogger.error('AuthService.login', error, stackTrace: stackTrace);
      throw const AuthServiceException('Unable to sign in. Please try again.');
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      AppLogger.info('AuthService', 'Sending password reset email.');
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (error) {
      AppLogger.error('AuthService.passwordReset', error);
      throw AuthServiceException(_messageForCode(error.code));
    } catch (error, stackTrace) {
      AppLogger.error(
        'AuthService.passwordReset',
        error,
        stackTrace: stackTrace,
      );
      throw const AuthServiceException(
        'Unable to send the password reset email.',
      );
    }
  }

  Future<AppUser?> getCurrentUserProfile() async {
    final firebaseUser = currentFirebaseUser;
    return firebaseUser == null ? null : _userService.getUser(firebaseUser.uid);
  }

  Future<void> updateCurrentUserProfile({
    required String fullName,
    required String displayName,
    String? phoneNumber,
    Uint8List? photoBytes,
    String? photoFilename,
  }) async {
    final firebaseUser = currentFirebaseUser;
    if (firebaseUser == null) {
      throw const AuthServiceException('No signed-in account was found.');
    }

    try {
      AppLogger.info('AuthService', 'Updating current user profile.');
      String? photoUrl;
      String? photoPublicId;
      if (photoBytes != null && photoFilename != null) {
        final idToken = await firebaseUser.getIdToken();
        if (idToken == null) {
          throw const AuthServiceException(
            'Unable to authenticate photo upload.',
          );
        }
        final upload = await _profilePhotoService.uploadProfilePhoto(
          idToken: idToken,
          bytes: photoBytes,
          filename: photoFilename,
        );
        photoUrl = upload.url;
        photoPublicId = upload.publicId;
        await firebaseUser.updatePhotoURL(photoUrl);
      }

      await firebaseUser.updateDisplayName(displayName.trim());
      await _userService.updateUser(firebaseUser.uid, {
        'fullName': fullName.trim(),
        'displayName': displayName.trim(),
        'phoneNumber': _nullableTrimmed(phoneNumber),
        'photoUrl': ?photoUrl,
        'photoPublicId': ?photoPublicId,
      });
    } on ProfilePhotoException catch (error) {
      AppLogger.error('AuthService.updateProfile.photo', error);
      throw AuthServiceException(error.message);
    } on FirebaseAuthException catch (error) {
      AppLogger.error('AuthService.updateProfile.auth', error);
      throw AuthServiceException(_messageForCode(error.code));
    } catch (error, stackTrace) {
      AppLogger.error(
        'AuthService.updateProfile',
        error,
        stackTrace: stackTrace,
      );
      throw const AuthServiceException(
        'Unable to update your profile. Please try again.',
      );
    }
  }

  Future<void> logout() async {
    try {
      AppLogger.info('AuthService', 'Signing out current user.');
      await _auth.signOut();
    } catch (error, stackTrace) {
      AppLogger.error('AuthService.logout', error, stackTrace: stackTrace);
      throw const AuthServiceException('Unable to sign out. Please try again.');
    }
  }

  Future<void> deleteAccount({required String password}) async {
    final firebaseUser = currentFirebaseUser;
    final email = firebaseUser?.email;

    if (firebaseUser == null || email == null) {
      throw const AuthServiceException('No signed-in account was found.');
    }

    try {
      AppLogger.info(
        'AuthService',
        'Reauthenticating before account deletion.',
      );
      final credential = EmailAuthProvider.credential(
        email: email,
        password: password,
      );
      await firebaseUser.reauthenticateWithCredential(credential);
      final profile = await _userService.getUser(firebaseUser.uid);
      if (profile?.photoPublicId != null) {
        final idToken = await firebaseUser.getIdToken(true);
        if (idToken == null) {
          throw const AuthServiceException(
            'Unable to authenticate account deletion.',
          );
        }
        await _profilePhotoService.deleteProfilePhoto(idToken: idToken);
      }
      await _userService.deleteUser(firebaseUser.uid);
      await firebaseUser.delete();
      AppLogger.info('AuthService', 'Account deletion completed.');
    } on FirebaseAuthException catch (error) {
      AppLogger.error('AuthService.deleteAccount.auth', error);
      throw AuthServiceException(_messageForCode(error.code));
    } on ProfilePhotoException catch (error) {
      AppLogger.error('AuthService.deleteAccount.photo', error);
      throw AuthServiceException(error.message);
    } catch (error, stackTrace) {
      AppLogger.error(
        'AuthService.deleteAccount',
        error,
        stackTrace: stackTrace,
      );
      throw const AuthServiceException(
        'Unable to delete your account. Please try again.',
      );
    }
  }

  Future<AppUser> signUpWithEmail({
    required String fullName,
    required String displayName,
    required String email,
    required String password,
    String? phoneNumber,
    Uint8List? photoBytes,
    String? photoFilename,
  }) async {
    UserCredential? credential;

    try {
      AppLogger.info('AuthService', 'Creating Firebase Auth account.');
      credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final firebaseUser = credential.user;
      if (firebaseUser == null) {
        throw const AuthServiceException('Unable to create your account.');
      }

      await firebaseUser.updateDisplayName(displayName.trim());
      AppLogger.info(
        'AuthService',
        'Firebase Auth account created for ${firebaseUser.uid}.',
      );

      String? photoUrl;
      String? photoPublicId;
      if (photoBytes != null && photoFilename != null) {
        AppLogger.info('AuthService', 'Uploading signup profile photo.');
        final idToken = await firebaseUser.getIdToken();
        if (idToken == null) {
          throw const AuthServiceException(
            'Unable to authenticate photo upload.',
          );
        }
        final upload = await _profilePhotoService.uploadProfilePhoto(
          idToken: idToken,
          bytes: photoBytes,
          filename: photoFilename,
        );
        photoUrl = upload.url;
        photoPublicId = upload.publicId;
        await firebaseUser.updatePhotoURL(photoUrl);
      }

      final now = DateTime.now().toUtc();
      final user = AppUser(
        uid: firebaseUser.uid,
        fullName: fullName.trim(),
        displayName: displayName.trim(),
        email: email.trim().toLowerCase(),
        emailLowercase: email.trim().toLowerCase(),
        phoneNumber: _nullableTrimmed(phoneNumber),
        photoUrl: photoUrl,
        photoPublicId: photoPublicId,
        createdAt: now,
        updatedAt: now,
      );

      await _userService.createUser(user);
      AppLogger.info('AuthService', 'Signup completed successfully.');
      return user;
    } on ProfilePhotoException catch (error) {
      AppLogger.error('AuthService.signup.photo', error);
      await _deleteCreatedUser(credential?.user);
      throw AuthServiceException(error.message);
    } on FirebaseAuthException catch (error) {
      AppLogger.error('AuthService.signup.auth', error);
      await _deleteCreatedUser(credential?.user);
      throw AuthServiceException(_messageForCode(error.code));
    } on FirebaseException catch (error) {
      AppLogger.error('AuthService.signup.firebase', error);
      await _deleteCreatedUser(credential?.user);
      throw AuthServiceException(_messageForFirebaseError(error));
    } on AuthServiceException {
      await _deleteCreatedUser(credential?.user);
      rethrow;
    } catch (error, stackTrace) {
      AppLogger.error('AuthService.signup', error, stackTrace: stackTrace);
      await _deleteCreatedUser(credential?.user);
      throw const AuthServiceException(
        'Unable to create your account. Please try again.',
      );
    }
  }

  Future<void> _deleteCreatedUser(User? user) async {
    if (user == null) {
      return;
    }

    try {
      AppLogger.info(
        'AuthService',
        'Removing incomplete Firebase Auth account.',
      );
      await user.delete();
    } catch (error, stackTrace) {
      AppLogger.error(
        'AuthService.cleanupIncompleteAccount',
        error,
        stackTrace: stackTrace,
      );
      // Cleanup is best-effort; the original signup error is more useful.
    }
  }

  static String? _nullableTrimmed(String? value) {
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }

  static String _messageForCode(String code) {
    return switch (code) {
      'email-already-in-use' => 'An account already exists for this email.',
      'invalid-email' => 'Enter a valid email address.',
      'invalid-credential' => 'The email or password is incorrect.',
      'user-disabled' => 'This account has been disabled.',
      'user-not-found' => 'No account exists for this email.',
      'wrong-password' => 'The email or password is incorrect.',
      'too-many-requests' => 'Too many attempts. Please try again later.',
      'requires-recent-login' =>
        'Please sign in again before deleting your account.',
      'operation-not-allowed' =>
        'Email signup is not enabled for this Firebase project.',
      'weak-password' => 'Choose a stronger password.',
      'network-request-failed' =>
        'Check your internet connection and try again.',
      _ => 'Unable to create your account. Please try again.',
    };
  }

  static String _messageForFirebaseError(FirebaseException error) {
    return switch (error.code) {
      'permission-denied' =>
        'Firestore denied access. Check the published user security rules.',
      'unavailable' => 'Firebase is temporarily unavailable. Please try again.',
      _ => error.message ?? 'Firebase could not create your user profile.',
    };
  }
}

class AuthServiceException implements Exception {
  final String message;

  const AuthServiceException(this.message);
}
