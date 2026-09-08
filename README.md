# Ask the Village

Real people. Real support. Real answers.

A private, judgment-free community where people can ask questions, share lived
experience, and find support through every season of life.

## Connect real sign-in

The authentication screens use Firebase Authentication and deliberately refuse
to continue when Firebase is not configured. From the `app` folder, run:

```bash
firebase login
dart pub global activate flutterfire_cli
flutterfire configure
flutter pub get
```

Select or create the **Ask the Village** Firebase project and configure Web,
Android, and iOS. In Firebase Authentication, enable Email/Password and Google.
Enable Apple after the Apple Developer Sign in with Apple configuration is
available. `flutterfire configure` replaces `lib/firebase_options.dart` with
the project's platform identifiers.
