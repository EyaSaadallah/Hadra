import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class SavedAccount {
  final String email;
  final String password;
  final String? name;
  final String? profilePic;

  SavedAccount({
    required this.email,
    required this.password,
    this.name,
    this.profilePic,
  });

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'password': password,
      'name': name,
      'profilePic': profilePic,
    };
  }

  factory SavedAccount.fromMap(Map<String, dynamic> map) {
    return SavedAccount(
      email: map['email'] ?? '',
      password: map['password'] ?? '',
      name: map['name'],
      profilePic: map['profilePic'],
    );
  }
}

class AccountStorageService {
  static const String _accountsKey = 'saved_accounts';
  static const String _currentAccountKey = 'current_account_email';

  // Save a new account
  Future<void> saveAccount({
    required String email,
    required String password,
    String? name,
    String? profilePic,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    // Get existing accounts
    List<SavedAccount> accounts = await getSavedAccounts();

    // Check if account already exists
    accounts.removeWhere((account) => account.email == email);

    // Add new account
    accounts.add(
      SavedAccount(
        email: email,
        password: password,
        name: name,
        profilePic: profilePic,
      ),
    );

    // Save to preferences
    List<String> accountsJson = accounts
        .map((account) => json.encode(account.toMap()))
        .toList();

    await prefs.setStringList(_accountsKey, accountsJson);
    await prefs.setString(_currentAccountKey, email);
  }

  // Get all saved accounts
  Future<List<SavedAccount>> getSavedAccounts() async {
    final prefs = await SharedPreferences.getInstance();
    List<String>? accountsJson = prefs.getStringList(_accountsKey);

    if (accountsJson == null || accountsJson.isEmpty) {
      return [];
    }

    return accountsJson.map((accountStr) {
      Map<String, dynamic> accountMap = json.decode(accountStr);
      return SavedAccount.fromMap(accountMap);
    }).toList();
  }

  // Get current account email
  Future<String?> getCurrentAccountEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_currentAccountKey);
  }

  // Set current account
  Future<void> setCurrentAccount(String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_currentAccountKey, email);
  }

  // Remove an account
  Future<void> removeAccount(String email) async {
    final prefs = await SharedPreferences.getInstance();
    List<SavedAccount> accounts = await getSavedAccounts();

    accounts.removeWhere((account) => account.email == email);

    List<String> accountsJson = accounts
        .map((account) => json.encode(account.toMap()))
        .toList();

    await prefs.setStringList(_accountsKey, accountsJson);

    // If removed account was current, clear current
    String? currentEmail = await getCurrentAccountEmail();
    if (currentEmail == email) {
      await prefs.remove(_currentAccountKey);
    }
  }

  // Clear all accounts
  Future<void> clearAllAccounts() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_accountsKey);
    await prefs.remove(_currentAccountKey);
  }

  // Update account info (name, profile pic)
  Future<void> updateAccountInfo({
    required String email,
    String? name,
    String? profilePic,
  }) async {
    List<SavedAccount> accounts = await getSavedAccounts();

    for (int i = 0; i < accounts.length; i++) {
      if (accounts[i].email == email) {
        accounts[i] = SavedAccount(
          email: accounts[i].email,
          password: accounts[i].password,
          name: name ?? accounts[i].name,
          profilePic: profilePic ?? accounts[i].profilePic,
        );
        break;
      }
    }

    final prefs = await SharedPreferences.getInstance();
    List<String> accountsJson = accounts
        .map((account) => json.encode(account.toMap()))
        .toList();

    await prefs.setStringList(_accountsKey, accountsJson);
  }
}
