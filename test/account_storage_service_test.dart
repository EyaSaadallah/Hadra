import 'package:flutter_test/flutter_test.dart';
import 'package:hadra/services/account_storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('AccountStorageService Tests', () {
    late AccountStorageService accountStorage;

    setUp(() async {
      // Initialize SharedPreferences with mock
      SharedPreferences.setMockInitialValues({});
      accountStorage = AccountStorageService();
    });

    test('Save and retrieve account', () async {
      // Save an account
      await accountStorage.saveAccount(
        email: 'test@example.com',
        password: 'password123',
        name: 'Test User',
        profilePic: 'https://example.com/pic.jpg',
      );

      // Retrieve saved accounts
      List<SavedAccount> accounts = await accountStorage.getSavedAccounts();

      expect(accounts.length, 1);
      expect(accounts[0].email, 'test@example.com');
      expect(accounts[0].password, 'password123');
      expect(accounts[0].name, 'Test User');
      expect(accounts[0].profilePic, 'https://example.com/pic.jpg');
    });

    test('Save multiple accounts', () async {
      // Save first account
      await accountStorage.saveAccount(
        email: 'user1@example.com',
        password: 'pass1',
        name: 'User One',
      );

      // Save second account
      await accountStorage.saveAccount(
        email: 'user2@example.com',
        password: 'pass2',
        name: 'User Two',
      );

      // Retrieve saved accounts
      List<SavedAccount> accounts = await accountStorage.getSavedAccounts();

      expect(accounts.length, 2);
      expect(accounts.any((a) => a.email == 'user1@example.com'), true);
      expect(accounts.any((a) => a.email == 'user2@example.com'), true);
    });

    test('Update existing account', () async {
      // Save account
      await accountStorage.saveAccount(
        email: 'test@example.com',
        password: 'oldpass',
        name: 'Old Name',
      );

      // Save again with same email (should update)
      await accountStorage.saveAccount(
        email: 'test@example.com',
        password: 'newpass',
        name: 'New Name',
      );

      // Retrieve saved accounts
      List<SavedAccount> accounts = await accountStorage.getSavedAccounts();

      expect(accounts.length, 1);
      expect(accounts[0].password, 'newpass');
      expect(accounts[0].name, 'New Name');
    });

    test('Remove account', () async {
      // Save two accounts
      await accountStorage.saveAccount(
        email: 'user1@example.com',
        password: 'pass1',
      );
      await accountStorage.saveAccount(
        email: 'user2@example.com',
        password: 'pass2',
      );

      // Remove first account
      await accountStorage.removeAccount('user1@example.com');

      // Retrieve saved accounts
      List<SavedAccount> accounts = await accountStorage.getSavedAccounts();

      expect(accounts.length, 1);
      expect(accounts[0].email, 'user2@example.com');
    });

    test('Get current account email', () async {
      // Save account (which sets it as current)
      await accountStorage.saveAccount(
        email: 'current@example.com',
        password: 'pass',
      );

      String? currentEmail = await accountStorage.getCurrentAccountEmail();

      expect(currentEmail, 'current@example.com');
    });

    test('Update account info', () async {
      // Save account
      await accountStorage.saveAccount(
        email: 'test@example.com',
        password: 'pass',
        name: 'Old Name',
      );

      // Update account info
      await accountStorage.updateAccountInfo(
        email: 'test@example.com',
        name: 'Updated Name',
        profilePic: 'https://example.com/new.jpg',
      );

      // Retrieve saved accounts
      List<SavedAccount> accounts = await accountStorage.getSavedAccounts();

      expect(accounts[0].name, 'Updated Name');
      expect(accounts[0].profilePic, 'https://example.com/new.jpg');
      expect(accounts[0].password, 'pass'); // Password should remain unchanged
    });

    test('Clear all accounts', () async {
      // Save multiple accounts
      await accountStorage.saveAccount(
        email: 'user1@example.com',
        password: 'pass1',
      );
      await accountStorage.saveAccount(
        email: 'user2@example.com',
        password: 'pass2',
      );

      // Clear all
      await accountStorage.clearAllAccounts();

      // Retrieve saved accounts
      List<SavedAccount> accounts = await accountStorage.getSavedAccounts();

      expect(accounts.length, 0);
    });

    test('Handle empty accounts list', () async {
      List<SavedAccount> accounts = await accountStorage.getSavedAccounts();

      expect(accounts.length, 0);
    });
  });
}
