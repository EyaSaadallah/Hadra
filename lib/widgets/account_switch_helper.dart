import 'package:flutter/material.dart';
import 'package:hadra/services/account_storage_service.dart';
import 'package:hadra/services/auth_service.dart';
import 'package:hadra/main.dart';

class AccountSwitchHelper {
  static void showAccountSwitcher(BuildContext context) async {
    final accountStorage = AccountStorageService();
    final authService = AuthService();

    List<SavedAccount> accounts = await accountStorage.getSavedAccounts();
    String? currentEmail = authService.currentUser?.email;

    if (!context.mounted) return;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Switch Account',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              const Divider(),

              // Account List
              if (accounts.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(40.0),
                  child: Column(
                    children: [
                      Icon(
                        Icons.account_circle_outlined,
                        size: 60,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'No saved accounts',
                        style: TextStyle(color: Colors.grey, fontSize: 16),
                      ),
                    ],
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: accounts.length,
                  itemBuilder: (context, index) {
                    final account = accounts[index];
                    final isCurrentAccount = account.email == currentEmail;

                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.grey[200],
                        backgroundImage:
                            (account.profilePic != null &&
                                account.profilePic!.isNotEmpty)
                            ? NetworkImage(account.profilePic!)
                            : null,
                        child:
                            (account.profilePic == null ||
                                account.profilePic!.isEmpty)
                            ? const Icon(Icons.person)
                            : null,
                      ),
                      title: Text(
                        account.name ?? account.email,
                        style: TextStyle(
                          fontWeight: isCurrentAccount
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                      subtitle: Text(account.email),
                      trailing: isCurrentAccount
                          ? const Icon(Icons.check_circle, color: Colors.blue)
                          : IconButton(
                              icon: const Icon(
                                Icons.delete_outline,
                                color: Colors.red,
                              ),
                              onPressed: () async {
                                // Confirm deletion
                                bool? confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('Remove Account'),
                                    content: Text(
                                      'Remove ${account.email} from saved accounts?',
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(context, false),
                                        child: const Text('Cancel'),
                                      ),
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(context, true),
                                        child: const Text(
                                          'Remove',
                                          style: TextStyle(color: Colors.red),
                                        ),
                                      ),
                                    ],
                                  ),
                                );

                                if (confirm == true) {
                                  await accountStorage.removeAccount(
                                    account.email,
                                  );
                                  if (context.mounted) {
                                    Navigator.pop(context);
                                    // Reopen the modal to show updated list
                                    showAccountSwitcher(context);
                                  }
                                }
                              },
                            ),
                      onTap: isCurrentAccount
                          ? null
                          : () async {
                              // Close the bottom sheet first
                              Navigator.pop(context);

                              // Show loading dialog
                              showDialog(
                                context: context,
                                barrierDismissible: false,
                                builder: (context) => WillPopScope(
                                  onWillPop: () async => false,
                                  child: const Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                ),
                              );

                              try {
                                // Sign out current user
                                await authService.signOut();

                                // Sign in with selected account
                                await authService.signIn(
                                  email: account.email,
                                  password: account.password,
                                );

                                // Small delay to ensure auth state propagates
                                await Future.delayed(
                                  const Duration(milliseconds: 300),
                                );

                                if (context.mounted) {
                                  // Close loading dialog
                                  Navigator.pop(context);

                                  // Reset the entire app by pushing a fresh AuthWrapper
                                  // This clears the navigation stack and forces all state to reset
                                  Navigator.of(
                                    context,
                                    rootNavigator: true,
                                  ).pushAndRemoveUntil(
                                    MaterialPageRoute(
                                      builder: (context) => const AuthWrapper(),
                                    ),
                                    (route) => false,
                                  );

                                  // Show success message
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Switched to ${account.name ?? account.email}',
                                      ),
                                      backgroundColor: Colors.green,
                                      duration: const Duration(seconds: 2),
                                    ),
                                  );
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  // Close loading dialog
                                  Navigator.pop(context);

                                  // Show error message
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Failed to switch account: $e',
                                      ),
                                      backgroundColor: Colors.red,
                                      duration: const Duration(seconds: 3),
                                    ),
                                  );
                                }
                              }
                            },
                    );
                  },
                ),

              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }
}
