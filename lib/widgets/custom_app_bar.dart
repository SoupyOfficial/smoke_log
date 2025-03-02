//// filepath: /c:/Users/JSCam/OneDrive/Documents/Development/smoke_log/lib/widgets/custom_app_bar.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'user_switcher.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;

  const CustomAppBar({
    Key? key,
    required this.title,
  }) : super(key: key);

  Future<void> _switchAccount(String email, BuildContext context) async {
    // Sign out the current user.
    await FirebaseAuth.instance.signOut();
    // TODO: Insert your re‑authentication logic for the selected account.
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content:
              Text('Switched account to $email. Implement sign‑in logic.')),
    );
  }

  Future<void> _signOut(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(title),
      actions: [
        UserSwitcher(
          userEmails: ['user1@example.com', 'user2@example.com'],
          onSwitchAccount: (email) {
            _switchAccount(email, context);
          },
        ),
        IconButton(
          icon: const Icon(Icons.logout),
          onPressed: () => _signOut(context),
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
