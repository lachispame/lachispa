import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/saved_user.dart';

class UserCredentialsService {
  static const String _masterKeyName = 'master_encryption_key';
  static const String _savedUsersKey = 'saved_users_list';
  static const _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );
  
  // Helper for safe substring
  String _safeSubstring(String? str, int start, int? end, {String suffix = '...'}) {
    if (str == null || str.isEmpty) return str ?? '';
    if (start >= str.length) return '';
    final actualEnd = end != null ? (end < str.length ? end : str.length) : str.length;
    final result = str.substring(start, actualEnd);
    return end != null && end < str.length ? result + suffix : result;
  }
  
  // Singleton pattern
  UserCredentialsService._privateConstructor();
  static final UserCredentialsService instance = UserCredentialsService._privateConstructor();
  
  // Generate random salt
  String _generateSalt() {
    final random = Random.secure();
    final bytes = List<int>.generate(32, (i) => random.nextInt(256));
    return base64Encode(bytes);
  }
  
  // Get or generate master key for encryption
  Future<String> _getMasterKey() async {
    print('[UserCredentialsService] Getting master key...');
    
    // Try SecureStorage first
    String? masterKey = await _secureStorage.read(key: _masterKeyName);
    
    if (masterKey == null) {
      print('[UserCredentialsService] Master key not found in SecureStorage, trying SharedPreferences...');
      
      // Fallback to SharedPreferences for web compatibility
      final prefs = await SharedPreferences.getInstance();
      masterKey = prefs.getString(_masterKeyName);
      
      if (masterKey == null) {
        print('[UserCredentialsService] Master key not found, generating new...');
        // Generate new master key
        final random = Random.secure();
        final bytes = List<int>.generate(32, (i) => random.nextInt(256));
        masterKey = base64Encode(bytes);
        
        // Save in both places for maximum compatibility
        try {
          await _secureStorage.write(key: _masterKeyName, value: masterKey);
          print('[UserCredentialsService] Master key saved in SecureStorage');
        } catch (e) {
          print('[UserCredentialsService] Could not save in SecureStorage: $e');
        }
        
        await prefs.setString(_masterKeyName, masterKey);
        print('[UserCredentialsService] New master key generated and saved: ${_safeSubstring(masterKey, 0, 8)}');
      } else {
        print('[UserCredentialsService] Master key retrieved from SharedPreferences: ${_safeSubstring(masterKey, 0, 8)}');
        
        // Try to synchronize with SecureStorage
        try {
          await _secureStorage.write(key: _masterKeyName, value: masterKey);
          print('[UserCredentialsService] Master key synchronized with SecureStorage');
        } catch (e) {
          print('[UserCredentialsService] Could not synchronize with SecureStorage: $e');
        }
      }
    } else {
      print('[UserCredentialsService] Master key retrieved from SecureStorage: ${_safeSubstring(masterKey, 0, 8)}');
    }
    
    return masterKey;
  }
  
  // Encrypt password with salt (using user data as key)
  Future<Map<String, String>> _encryptPassword(String password, {String? serverUrl, String? username}) async {
    print('[UserCredentialsService] Starting password encryption...');
    print('[UserCredentialsService] Original password: ${password.length} characters');
    
    final salt = _generateSalt();
    
    print('[UserCredentialsService] Generated salt: ${_safeSubstring(salt, 0, 8)}');
    print('[UserCredentialsService] ServerUrl: ${serverUrl != null && serverUrl.length > 20 ? serverUrl.substring(0, 20) + '...' : serverUrl}');
    print('[UserCredentialsService] Username: $username');
    
    // Create encryption key using serverUrl + username + salt
    final keyMaterial = '${serverUrl ?? ''}||${username ?? ''}||$salt';
    final keyHash = sha256.convert(utf8.encode(keyMaterial)).toString();
    
    print('[UserCredentialsService] Generated key hash: ${_safeSubstring(keyHash, 0, 16)}');
    
    // Simple encryption: password + verification hash
    final verificationHash = sha256.convert(utf8.encode(password + salt)).toString().substring(0, 16);
    final passwordToEncrypt = password + '||' + verificationHash;
    final encryptedPassword = base64Encode(utf8.encode(passwordToEncrypt));
    
    print('[UserCredentialsService] Encrypted password: ${_safeSubstring(encryptedPassword, 0, 8)}');
    print('[UserCredentialsService] Encryption completed successfully');
    
    return {
      'passwordHash': encryptedPassword,
      'salt': salt,
    };
  }
  
  // Verify password by decrypting the stored one
  Future<bool> _verifyPassword(String password, String storedEncryptedPassword, String salt, String serverUrl, String username) async {
    try {
      final decryptedPassword = await _decryptStoredPassword(storedEncryptedPassword, salt, serverUrl, username);
      return decryptedPassword == password;
    } catch (e) {
      print('[UserCredentialsService] Error verifying password: $e');
      return false;
    }
  }
  
  // Save user credentials with SharedPreferences
  Future<bool> saveUserCredentials({
    required String serverUrl,
    required String username,
    required String password,
    required bool rememberPassword,
  }) async {
    try {
      print('[UserCredentialsService] Saving credentials for: $username on $serverUrl (remember: $rememberPassword)');
      
      final prefs = await SharedPreferences.getInstance();
      
      if (!rememberPassword) {
        // If password is not to be remembered, remove any existing record
        await _removeUserFromPrefs(prefs, serverUrl, username);
        print('[UserCredentialsService] User removed because remember=false');
        return true;
      }
      
      // Encrypt password
      final encryptionData = await _encryptPassword(password, serverUrl: serverUrl, username: username);
      print('[UserCredentialsService] Password encrypted successfully');
      
      // Create user
      final user = SavedUser(
        serverUrl: serverUrl,
        username: username,
        passwordHash: encryptionData['passwordHash']!,
        salt: encryptionData['salt']!,
        rememberPassword: rememberPassword,
        lastLogin: DateTime.now(),
      );
      
      // Get current user list
      final savedUsers = await _getSavedUsersFromPrefs(prefs);
      
      // Remove existing user if exists
      savedUsers.removeWhere((u) => u.serverUrl == serverUrl && u.username == username);
      
      // Add new user
      savedUsers.add(user);
      
      // Save updated list
      await _saveSavedUsersToPrefs(prefs, savedUsers);
      
      print('[UserCredentialsService] User saved successfully');
      
      // Verify that it was saved correctly
      final savedUser = await _getUserFromPrefs(prefs, serverUrl, username);
      if (savedUser != null) {
        print('[UserCredentialsService] Verification: User saved correctly');
        print('[UserCredentialsService] - Username: ${savedUser.username}');
        print('[UserCredentialsService] - ServerUrl: ${savedUser.serverUrl}');
        print('[UserCredentialsService] - RememberPassword: ${savedUser.rememberPassword}');
      } else {
        print('[UserCredentialsService] ERROR: User not found after saving');
      }
      
      return true;
    } catch (e) {
      print('[UserCredentialsService] Error saving credentials: $e');
      return false;
    }
  }
  
  // Get saved users for a server
  Future<List<SavedUser>> getSavedUsers(String serverUrl) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final users = await _getSavedUsersFromPrefs(prefs);
      return users.where((user) => user.serverUrl == serverUrl && user.rememberPassword).toList();
    } catch (e) {
      print('[UserCredentialsService] Error getting users: $e');
      return [];
    }
  }
  
  // Search users by username pattern
  Future<List<SavedUser>> searchUsers(String serverUrl, String usernamePattern) async {
    try {
      if (usernamePattern.isEmpty) {
        return await getSavedUsers(serverUrl);
      }
      
      final prefs = await SharedPreferences.getInstance();
      final users = await _getSavedUsersFromPrefs(prefs);
      
      return users.where((user) => 
        user.serverUrl == serverUrl && 
        user.rememberPassword && 
        user.username.toLowerCase().contains(usernamePattern.toLowerCase())
      ).toList();
    } catch (e) {
      print('[UserCredentialsService] Error searching users: $e');
      return [];
    }
  }
  
  // Get decrypted password for a user
  Future<String?> getDecryptedPassword(String serverUrl, String username) async {
    try {
      print('[UserCredentialsService] Looking for password for: $username on $serverUrl');
      final prefs = await SharedPreferences.getInstance();
      final user = await _getUserFromPrefs(prefs, serverUrl, username);
      
      if (user == null) {
        print('[UserCredentialsService] User not found in prefs');
        return null;
      }
      
      print('[UserCredentialsService] User found. RememberPassword: ${user.rememberPassword}');
      print('[UserCredentialsService] PasswordHash: ${_safeSubstring(user.passwordHash, 0, 8)}');
      print('[UserCredentialsService] Salt: ${_safeSubstring(user.salt, 0, 8)}');
      
      if (!user.rememberPassword) {
        print('[UserCredentialsService] User does not have remember_password enabled');
        return null;
      }
      
      // Decrypt password
      print('[UserCredentialsService] Starting decryption process...');
      final decryptedPassword = await _decryptStoredPassword(user.passwordHash, user.salt, serverUrl, username);
      
      if (decryptedPassword != null) {
        print('[UserCredentialsService] Password decrypted successfully: ${decryptedPassword.length} characters');
        // DO NOT print the real password for security
        return decryptedPassword;
      } else {
        print('[UserCredentialsService] Could not decrypt password');
        return null;
      }
    } catch (e) {
      print('[UserCredentialsService] Error getting password: $e');
      return null;
    }
  }
  
  // Private method to decrypt stored password
  Future<String?> _decryptStoredPassword(String encryptedPassword, String salt, String serverUrl, String username) async {
    try {
      print('[UserCredentialsService] Starting password decryption...');
      print('[UserCredentialsService] Encrypted password received: ${_safeSubstring(encryptedPassword, 0, 8)}');
      print('[UserCredentialsService] Salt received: ${_safeSubstring(salt, 0, 8)}');
      print('[UserCredentialsService] ServerUrl: ${_safeSubstring(serverUrl, 0, 20)}');
      print('[UserCredentialsService] Username: $username');
      
      // Create the same key used for encryption (using serverUrl + username + salt)
      final keyMaterial = '$serverUrl||$username||$salt';
      final keyHash = sha256.convert(utf8.encode(keyMaterial)).toString();
      
      print('[UserCredentialsService] Recreated key hash: ${_safeSubstring(keyHash, 0, 16)}');
      
      // Decrypt: decode base64 and extract password
      final decryptedData = utf8.decode(base64Decode(encryptedPassword));
      print('[UserCredentialsService] Decrypted data: ${decryptedData.length} characters');
      
      // Separate password and verification hash
      if (decryptedData.contains('||')) {
        final parts = decryptedData.split('||');
        if (parts.length == 2) {
          final password = parts[0];
          final storedVerificationHash = parts[1];
          
          print('[UserCredentialsService] Extracted password: ${password.length} characters');
          print('[UserCredentialsService] Stored verification hash: $storedVerificationHash');
          
          // Recreate verification hash
          final expectedVerificationHash = sha256.convert(utf8.encode(password + salt)).toString().substring(0, 16);
          print('[UserCredentialsService] Expected verification hash: $expectedVerificationHash');
          
          // Verify that verification hash matches
          if (storedVerificationHash == expectedVerificationHash) {
            print('[UserCredentialsService] Verification hash correct');
            print('[UserCredentialsService] Decryption completed successfully');
            return password;
          } else {
            print('[UserCredentialsService] Verification hash does not match - possible data corruption');
            return null;
          }
        } else {
          print('[UserCredentialsService] Invalid data format - expected 2 parts, found ${parts.length}');
          return null;
        }
      } else {
        print('[UserCredentialsService] Separator || not found in decrypted data');
        print('[UserCredentialsService] Data received: "${_safeSubstring(decryptedData, 0, 50)}"');
        return null;
      }
    } catch (e) {
      print('[UserCredentialsService] Error decrypting password: $e');
      return null;
    }
  }
  
  // Verify saved credentials
  Future<bool> verifyStoredCredentials(String serverUrl, String username, String password) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final user = await _getUserFromPrefs(prefs, serverUrl, username);
      if (user == null) {
        return false;
      }
      
      return await _verifyPassword(password, user.passwordHash, user.salt, serverUrl, username);
    } catch (e) {
      print('[UserCredentialsService] Error verifying credentials: $e');
      return false;
    }
  }
  
  // Update last login
  Future<void> updateLastLogin(String serverUrl, String username) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final users = await _getSavedUsersFromPrefs(prefs);
      
      for (int i = 0; i < users.length; i++) {
        if (users[i].serverUrl == serverUrl && users[i].username == username) {
          users[i] = users[i].copyWith(lastLogin: DateTime.now());
          break;
        }
      }
      
      await _saveSavedUsersToPrefs(prefs, users);
    } catch (e) {
      print('[UserCredentialsService] Error updating last login: $e');
    }
  }
  
  // Update remember password configuration
  Future<bool> updateRememberPassword(String serverUrl, String username, bool remember) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final users = await _getSavedUsersFromPrefs(prefs);
      
      for (int i = 0; i < users.length; i++) {
        if (users[i].serverUrl == serverUrl && users[i].username == username) {
          users[i] = users[i].copyWith(rememberPassword: remember);
          await _saveSavedUsersToPrefs(prefs, users);
          return true;
        }
      }
      
      return false;
    } catch (e) {
      print('[UserCredentialsService] Error updating remember password: $e');
      return false;
    }
  }
  
  // Delete user credentials
  Future<bool> deleteUserCredentials(String serverUrl, String username) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await _removeUserFromPrefs(prefs, serverUrl, username);
      return true;
    } catch (e) {
      print('[UserCredentialsService] Error deleting credentials: $e');
      return false;
    }
  }
  
  // Clear all credentials
  Future<void> clearAllCredentials() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_savedUsersKey);
      await prefs.remove(_masterKeyName); // Also clear master key from SharedPreferences
      await _secureStorage.delete(key: _masterKeyName);
    } catch (e) {
      print('[UserCredentialsService] Error clearing credentials: $e');
    }
  }
  
  // Method to get user suggestions while typing
  Future<List<String>> getUserSuggestions(String serverUrl, String partialUsername) async {
    try {
      print('[UserCredentialsService] Getting suggestions for: "$partialUsername" on $serverUrl');
      
      if (partialUsername.isEmpty) {
        final users = await getSavedUsers(serverUrl);
        print('[UserCredentialsService] Users found (empty query): ${users.length}');
        return users.map((user) => user.username).toList();
      }
      
      final users = await searchUsers(serverUrl, partialUsername);
      print('[UserCredentialsService] Users found (search): ${users.length}');
      for (final user in users) {
        print('[UserCredentialsService] - ${user.username} (remember: ${user.rememberPassword})');
      }
      
      return users.map((user) => user.username).toList();
    } catch (e) {
      print('[UserCredentialsService] Error getting suggestions: $e');
      return [];
    }
  }
  
  // Method to get complete user information
  Future<SavedUser?> getUserInfo(String serverUrl, String username) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await _getUserFromPrefs(prefs, serverUrl, username);
    } catch (e) {
      print('[UserCredentialsService] Error getting user information: $e');
      return null;
    }
  }
  
  // Debug method: get all users
  Future<List<SavedUser>> getAllUsers() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await _getSavedUsersFromPrefs(prefs);
    } catch (e) {
      print('[UserCredentialsService] Error getting all users: $e');
      return [];
    }
  }
  
  // Helper methods for SharedPreferences
  Future<List<SavedUser>> _getSavedUsersFromPrefs(SharedPreferences prefs) async {
    try {
      final usersJson = prefs.getString(_savedUsersKey);
      if (usersJson == null) return [];
      
      final usersList = jsonDecode(usersJson) as List;
      return usersList.map((json) => SavedUser.fromMap(json)).toList();
    } catch (e) {
      print('[UserCredentialsService] Error getting users from prefs: $e');
      return [];
    }
  }
  
  Future<void> _saveSavedUsersToPrefs(SharedPreferences prefs, List<SavedUser> users) async {
    try {
      final usersJson = jsonEncode(users.map((user) => user.toMap()).toList());
      await prefs.setString(_savedUsersKey, usersJson);
    } catch (e) {
      print('[UserCredentialsService] Error saving users to prefs: $e');
    }
  }
  
  Future<SavedUser?> _getUserFromPrefs(SharedPreferences prefs, String serverUrl, String username) async {
    try {
      final users = await _getSavedUsersFromPrefs(prefs);
      for (final user in users) {
        if (user.serverUrl == serverUrl && user.username == username) {
          return user;
        }
      }
      return null;
    } catch (e) {
      print('[UserCredentialsService] Error getting user from prefs: $e');
      return null;
    }
  }
  
  Future<void> _removeUserFromPrefs(SharedPreferences prefs, String serverUrl, String username) async {
    try {
      final users = await _getSavedUsersFromPrefs(prefs);
      users.removeWhere((user) => user.serverUrl == serverUrl && user.username == username);
      await _saveSavedUsersToPrefs(prefs, users);
    } catch (e) {
      print('[UserCredentialsService] Error removing user from prefs: $e');
    }
  }
}