# Account Switching Feature

## Overview
This feature allows users to save multiple accounts on their device and quickly switch between them without having to manually log out and re-enter credentials.

## Implementation Details

### 1. New Dependencies
- **shared_preferences**: Added to `pubspec.yaml` for local storage of account credentials

### 2. New Files Created

#### `lib/services/account_storage_service.dart`
- Manages local storage of multiple account credentials
- Provides methods to:
  - Save account credentials (email, password, name, profile picture)
  - Retrieve all saved accounts
  - Remove individual accounts
  - Update account information
  - Track the current active account

#### `lib/widgets/account_switch_helper.dart`
- Displays a modal bottom sheet with all saved accounts
- Features:
  - Shows account profile pictures and names
  - Indicates the currently active account with a checkmark
  - Allows switching to another account with a single tap
  - Provides option to remove saved accounts
  - Shows loading indicator during account switch
  - Displays success/error messages

### 3. Modified Files

#### `lib/services/auth_service.dart`
- **signIn method**: Now automatically saves account credentials when a user signs in
- **updateProfile method**: Updates saved account info when profile name or picture changes

#### `lib/screens/profile_screen.dart`
- Added "Switch Account" button below "Edit Profile" button
- Button only appears on the user's own profile (when `isMe` is true)
- Uses an icon (swap_horiz) to make the function clear

## How It Works

1. **First Login**: When a user logs in, their credentials are automatically saved locally
2. **Subsequent Logins**: Each new account login is added to the saved accounts list
3. **Switching Accounts**: 
   - User taps "Switch Account" button on their profile
   - Modal shows all saved accounts
   - User taps on desired account
   - App signs out current user and signs in with selected account
4. **Account Management**: Users can remove saved accounts they no longer want to keep

## Security Considerations

- Passwords are stored in plain text in local storage (shared_preferences)
- This is suitable for convenience but users should be aware
- Consider adding encryption for password storage in production
- Only use on trusted devices

## User Experience

- **Quick Switching**: No need to remember passwords for multiple accounts
- **Visual Feedback**: Profile pictures and names make it easy to identify accounts
- **Clean UI**: Integrated seamlessly into the existing profile screen
- **Error Handling**: Shows appropriate messages if switching fails

## Future Enhancements

Potential improvements:
1. Encrypt stored passwords for better security
2. Add biometric authentication before switching
3. Add option to enable/disable account saving
4. Show last login time for each account
5. Add account nicknames for easier identification
