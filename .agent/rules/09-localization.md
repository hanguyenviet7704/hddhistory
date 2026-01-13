---
description: Localization rules and guidelines for multi-language support using Flutter's l10n system
alwaysApply: false
---
# Localization Rules

## Localization Setup
The project uses Flutter's built-in localization system with ARB (Application Resource Bundle) files.

### Configuration Files
- `l10n.yaml` - Localization configuration
- `lib/config/l10n/arb/` - ARB files directory
- Generated files in `lib/config/l10n/`

### Supported Languages
- English (en) - Primary language
- Vietnamese (vi) - Secondary language  
- Add more languages as needed

## ARB File Structure

### English ARB File (app_en.arb)
```json
{
  "@@locale": "en",
  "appTitle": "Meup",
  "@appTitle": {
    "description": "The title of the application"
  },
  
  "welcomeMessage": "Welcome to Meup!",
  "@welcomeMessage": {
    "description": "Welcome message shown to users"
  },
  
  "loginTitle": "Login",
  "@loginTitle": {
    "description": "Title for the login screen"
  },
  
  "email": "Email",
  "@email": {
    "description": "Email field label"
  },
  
  "password": "Password",
  "@password": {
    "description": "Password field label"
  },
  
  "loginButton": "Login",
  "@loginButton": {
    "description": "Login button text"
  },
  
  "forgotPassword": "Forgot Password?",
  "@forgotPassword": {
    "description": "Forgot password link text"
  },
  
  "createAccount": "Create Account",
  "@createAccount": {
    "description": "Create account button text"
  }
}
```

### Vietnamese ARB File (app_vi.arb)
```json
{
  "@@locale": "vi",
  "appTitle": "Meup",
  "welcomeMessage": "Chào mừng đến với Meup!",
  "loginTitle": "Đăng nhập",
  "email": "Email",
  "password": "Mật khẩu",
  "loginButton": "Đăng nhập",
  "forgotPassword": "Quên mật khẩu?",
  "createAccount": "Tạo tài khoản"
}
```

## Parameterized Messages

### Simple Parameters
```json
{
  "welcomeUser": "Welcome, {userName}!",
  "@welcomeUser": {
    "description": "Welcome message with user name",
    "placeholders": {
      "userName": {
        "type": "String",
        "example": "John"
      }
    }
  }
}
```

### Multiple Parameters
```json
{
  "itemCount": "You have {count} {items} in your cart",
  "@itemCount": {
    "description": "Cart item count message",
    "placeholders": {
      "count": {
        "type": "int",
        "example": 5
      },
      "items": {
        "type": "String", 
        "example": "items"
      }
    }
  }
}
```

### Pluralization
```json
{
  "messageCount": "{count, plural, =0{No messages} =1{1 message} other{{count} messages}}",
  "@messageCount": {
    "description": "Number of messages with proper pluralization",
    "placeholders": {
      "count": {
        "type": "int",
        "example": 3
      }
    }
  }
}
```

### Date and Time Formatting
```json
{
  "lastLoginDate": "Last login: {date}",
  "@lastLoginDate": {
    "description": "Last login date message",
    "placeholders": {
      "date": {
        "type": "DateTime",
        "format": "yMMMd",
        "example": "Jan 1, 2024"
      }
    }
  },
  
  "meetingTime": "Meeting at {time}",
  "@meetingTime": {
    "description": "Meeting time message", 
    "placeholders": {
      "time": {
        "type": "DateTime",
        "format": "Hm",
        "example": "14:30"
      }
    }
  }
}
```

## Usage in Code

### Basic Usage
```dart
class LoginPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.text.loginTitle), // Uses localization
      ),
      body: Column(
        children: [
          Text(context.text.welcomeMessage),
          TextField(
            decoration: InputDecoration(
              labelText: context.text.email,
            ),
          ),
          TextField(
            decoration: InputDecoration(
              labelText: context.text.password,
            ),
            obscureText: true,
          ),
          ElevatedButton(
            onPressed: () => _login(context),
            child: Text(context.text.loginButton),
          ),
        ],
      ),
    );
  }
}
```

### Parameterized Messages
```dart
class WelcomeWidget extends StatelessWidget {
  final String userName;
  
  const WelcomeWidget({super.key, required this.userName});
  
  @override
  Widget build(BuildContext context) {
    return Text(
      context.text.welcomeUser(userName), // Parameterized message
    );
  }
}
```

### Plural Messages
```dart
class MessageCounter extends StatelessWidget {
  final int messageCount;
  
  const MessageCounter({super.key, required this.messageCount});
  
  @override
  Widget build(BuildContext context) {
    return Text(
      context.text.messageCount(messageCount), // Plural handling
    );
  }
}
```

### Date/Time Messages
```dart
class LastLoginDisplay extends StatelessWidget {
  final DateTime lastLogin;
  
  const LastLoginDisplay({super.key, required this.lastLogin});
  
  @override
  Widget build(BuildContext context) {
    return Text(
      context.text.lastLoginDate(lastLogin), // Date formatting
    );
  }
}
```

## Context Extension

### Creating Text Extension
```dart
// lib/core/extensions/context_extensions.dart
extension LocalizationExtension on BuildContext {
  AppLocalizations get text => AppLocalizations.of(this)!;
}

// Usage
Text(context.text.welcomeMessage)
```

## Feature-Specific Localization

### Organizing by Feature
Structure ARB files by feature for better maintainability:

```json
{
  "@@locale": "en",
  
  "_auth_section": "",
  "loginTitle": "Login",
  "loginButton": "Login", 
  "logoutButton": "Logout",
  "signUpTitle": "Sign Up",
  
  "_profile_section": "",
  "profileTitle": "Profile",
  "editProfile": "Edit Profile",
  "saveChanges": "Save Changes",
  "deleteAccount": "Delete Account",
  
  "_art_study_section": "",
  "pictureStudyTitle": "Picture Study",
  "startStudy": "Start Study",
  "completeStudy": "Complete Study",
  "studyProgress": "Study Progress"
}
```

### Validation Messages
```json
{
  "_validation_section": "",
  "emailRequired": "Email is required",
  "emailInvalid": "Please enter a valid email address",
  "passwordRequired": "Password is required", 
  "passwordMinLength": "Password must be at least 8 characters",
  "passwordsDoNotMatch": "Passwords do not match",
  "nameRequired": "Name is required",
  "nameMinLength": "Name must be at least 2 characters"
}
```

### Error Messages
```json
{
  "_error_section": "",
  "networkError": "Network connection failed. Please try again.",
  "serverError": "Server error occurred. Please try again later.",
  "unauthorizedError": "Access denied. Please login again.",
  "notFoundError": "The requested resource was not found.",
  "unknownError": "An unexpected error occurred.",
  "tryAgain": "Try Again",
  "dismiss": "Dismiss"
}
```

## Form Validation with Localization

### Form Field Validation
```dart
class LocalizedFormField extends StatelessWidget {
  final TextEditingController controller;
  final String labelKey;
  final String? Function(String?) validator;
  
  const LocalizedFormField({
    super.key,
    required this.controller,
    required this.labelKey,
    required this.validator,
  });
  
  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: _getLocalizedLabel(context, labelKey),
        border: const OutlineInputBorder(),
      ),
      validator: validator,
    );
  }
  
  String _getLocalizedLabel(BuildContext context, String key) {
    switch (key) {
      case 'email':
        return context.text.email;
      case 'password':
        return context.text.password;
      case 'name':
        return context.text.name;
      default:
        return key;
    }
  }
}
```

### Validation Helper
```dart
class ValidationHelper {
  static String? validateEmail(BuildContext context, String? value) {
    if (value == null || value.isEmpty) {
      return context.text.emailRequired;
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
      return context.text.emailInvalid;
    }
    return null;
  }
  
  static String? validatePassword(BuildContext context, String? value) {
    if (value == null || value.isEmpty) {
      return context.text.passwordRequired;
    }
    if (value.length < 8) {
      return context.text.passwordMinLength;
    }
    return null;
  }
  
  static String? validateName(BuildContext context, String? value) {
    if (value == null || value.isEmpty) {
      return context.text.nameRequired;
    }
    if (value.length < 2) {
      return context.text.nameMinLength;
    }
    return null;
  }
}
```

## Error Handling with Localization

### Localized Error Display
```dart
class LocalizedErrorDisplay extends StatelessWidget {
  final AppException exception;
  final VoidCallback? onRetry;
  
  const LocalizedErrorDisplay({
    super.key,
    required this.exception,
    this.onRetry,
  });
  
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _getErrorIcon(),
            size: 64,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: 16),
          Text(
            _getLocalizedErrorMessage(context),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: onRetry,
              child: Text(context.text.tryAgain),
            ),
          ],
        ],
      ),
    );
  }
  
  String _getLocalizedErrorMessage(BuildContext context) {
    return exception.when(
      serverError: (message, code, statusCode) => 
          message.isNotEmpty ? message : context.text.serverError,
      networkError: (message) => 
          message ?? context.text.networkError,
      unauthorizedError: (message) => 
          message ?? context.text.unauthorizedError,
      notFoundError: (message) => 
          message ?? context.text.notFoundError,
      validationError: (message, fieldErrors) => message,
      unknownError: (message, originalException) => 
          message.isNotEmpty ? message : context.text.unknownError,
    );
  }
  
  IconData _getErrorIcon() {
    return exception.when(
      serverError: (_, __, ___) => Icons.error_outline,
      networkError: (_) => Icons.wifi_off,
      unauthorizedError: (_) => Icons.lock_outline,
      validationError: (_, __) => Icons.warning_outlined,
      notFoundError: (_) => Icons.search_off,
      unknownError: (_, __) => Icons.help_outline,
    );
  }
}
```

## Testing Localization

### Testing Localized Text
```dart
group('LoginPage Localization', () {
  testWidgets('displays localized text for English', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const LoginPage(),
      ),
    );
    
    expect(find.text('Login'), findsOneWidget);
    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
  });
  
  testWidgets('displays localized text for Vietnamese', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('vi'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const LoginPage(),
      ),
    );
    
    expect(find.text('Đăng nhập'), findsOneWidget);
    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Mật khẩu'), findsOneWidget);
  });
});
```

## Code Generation

### Generate Localization Files from Google Sheets
The project uses automated localization generation from Google Sheets. Run the generation script:

```bash
# Generate ARB files from Google Sheets and run Flutter localization
./tools/macos/localization/generate_localization.sh
```

This script will:
1. Generate module-specific ARB files from Google Sheets
2. Merge module ARB files into app ARB files
3. Run Flutter's localization generation (`flutter gen-l10n`)

### Manual Flutter Localization Generation
If you need to regenerate only the Dart files from existing ARB files:

```bash
flutter gen-l10n
```

### Build Process Integration
Always regenerate localization files as part of the build process:

```bash
# Full development workflow with localization
flutter pub get
dart run build_runner build --delete-conflicting-outputs
./tools/macos/localization/generate_localization.sh
```

### Generated File Structure
The generation process creates:
- **Module ARB files**: `assets/arb/module/` - Feature-specific translations
- **App ARB files**: `assets/arb/app/` - Combined application translations  
- **Dart localization files**: `lib/config/l10n/` - Generated Flutter classes

## Best Practices

### Localization Guidelines
1. **Always use localization keys, never hardcode strings**
2. **Provide meaningful descriptions in ARB files**
3. **Use consistent naming conventions for keys**
4. **Group related strings with section comments**
5. **Test all supported languages**
6. **Validate pluralization rules for each language**

### Key Naming Conventions
```json
{
  // Feature prefix + specific purpose
  "authLoginTitle": "Login",
  "authLoginButton": "Login",
  "authEmailField": "Email",
  
  // Error messages with Error suffix
  "networkConnectionError": "Network connection failed",
  "validationEmailError": "Invalid email format",
  
  // Actions with Action suffix
  "saveAction": "Save",
  "cancelAction": "Cancel", 
  "deleteAction": "Delete",
  
  // Status messages with Status suffix
  "loadingStatus": "Loading...",
  "successStatus": "Operation completed successfully"
}
```

### Performance Considerations
1. **Use context.text extension for cleaner code**
2. **Avoid rebuilding widgets when locale changes**
3. **Cache translated strings when appropriate**
4. **Use const constructors for static text widgets**