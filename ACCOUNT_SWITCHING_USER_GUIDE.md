# Account Switching - User Guide

## How to Use the Account Switching Feature

### For End Users

#### 1. **Automatic Account Saving**
When you log in to your account, your credentials are automatically saved to your device. You don't need to do anything special - just log in normally.

#### 2. **Accessing the Switch Account Feature**
1. Navigate to your **Profile** screen (tap your profile icon)
2. You'll see two buttons:
   - **Edit Profile** - Edit your profile information
   - **Switch Account** - Switch between saved accounts

#### 3. **Switching Between Accounts**
1. Tap the **Switch Account** button
2. A modal will appear showing all your saved accounts
3. Each account displays:
   - Profile picture
   - Name
   - Email address
   - Current account has a blue checkmark ✓
4. Tap on any account to switch to it
5. The app will automatically:
   - Sign out of the current account
   - Sign in to the selected account
   - Show a success message

#### 4. **Removing Saved Accounts**
1. Open the **Switch Account** modal
2. Tap the **trash/delete icon** (🗑️) next to the account you want to remove
3. Confirm the removal in the dialog
4. The account will be removed from your saved accounts
   - Note: This only removes it from the saved list
   - It doesn't delete the actual account

#### 5. **Adding New Accounts**
1. Sign out of your current account (tap logout in profile)
2. Log in with a different account
3. The new account will automatically be added to your saved accounts

### Visual Guide

```
┌─────────────────────────────┐
│     Your Profile            │
│                             │
│  [Profile Picture]          │
│  Name                       │
│  Bio                        │
│  Posts | Followers | Following│
│                             │
│  ┌───────────────────────┐ │
│  │   Edit Profile        │ │
│  └───────────────────────┘ │
│                             │
│  ┌───────────────────────┐ │
│  │ ⇄  Switch Account     │ │ ← Click here
│  └───────────────────────┘ │
│                             │
└─────────────────────────────┘

When clicked, shows:

┌─────────────────────────────┐
│  Switch Account        ✕    │
├─────────────────────────────┤
│                             │
│  ○ John Doe            ✓    │
│    john@email.com           │
│                             │
│  ○ Jane Smith          🗑️   │
│    jane@email.com           │
│                             │
│  ○ Work Account        🗑️   │
│    work@email.com           │
│                             │
└─────────────────────────────┘
```

### Tips & Best Practices

✅ **DO:**
- Use this feature on your personal device
- Keep your accounts organized
- Remove accounts you no longer use
- Use strong, unique passwords for each account

❌ **DON'T:**
- Save accounts on shared or public devices
- Save sensitive accounts on untrusted devices
- Share your device with saved accounts unlocked

### Troubleshooting

**Q: I can't see the Switch Account button**
- A: The button only appears on YOUR profile, not on other users' profiles

**Q: Account switching failed**
- A: Check your internet connection
- A: The saved password might be outdated if you changed it
- A: Try logging in manually and the credentials will update

**Q: I want to remove all saved accounts**
- A: Remove them one by one using the delete icon
- A: Or clear app data (this will log you out)

**Q: Is my password secure?**
- A: Passwords are stored locally on your device
- A: Only use this feature on trusted devices
- A: Consider using device encryption/lock screen

### Privacy & Security

🔒 **What's Stored:**
- Email address
- Password (in local storage)
- Name
- Profile picture URL

🔒 **Where It's Stored:**
- Only on your device
- Not synced to cloud
- Cleared when you uninstall the app

🔒 **Security Recommendations:**
1. Use a strong device lock screen (PIN/Pattern/Biometric)
2. Don't save accounts on shared devices
3. Remove saved accounts before selling/giving away device
4. Log out from sensitive accounts when done

### For Developers

See `ACCOUNT_SWITCHING_FEATURE.md` for technical implementation details.
