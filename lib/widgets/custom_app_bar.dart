import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../screens/login_screen.dart';
import '../services/credential_service.dart';
import 'user_switcher.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;

  const CustomAppBar({
    Key? key,
    required this.title,
  }) : super(key: key);

  Future<void> _switchAccount(String email, BuildContext context) async {
    await FirebaseAuth.instance.signOut();

    // Retrieve the saved password for the provided email.
    final password = await CredentialService().getPasswordForEmail(email);
    if (password == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No saved credential for $email')),
      );
      return;
    }

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Switched account to $email')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to switch account: $e')),
      );
    }
  }

  Future<void> _signOut(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
  }

  Future<List<String>> _getUserEmails() async {
    final accounts = await CredentialService().getUserAccounts();
    return accounts.map((account) => account['email']!).toList();
  }

  Future<void> _handleAccountSelection(
      String email, BuildContext context) async {
    if (email == 'Add Account') {
      // Sign out then redirect to the login screen.
      await _signOut(context);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    } else {
      await _switchAccount(email, context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(title),
      actions: [
        FutureBuilder<List<String>>(
          future: _getUserEmails(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting ||
                snapshot.hasError) {
              print(snapshot.error);
              return const SizedBox();
            }
            // Append the "Add Account" option.
            final userEmails = (snapshot.data ?? [])..add('Add Account');
            return UserSwitcher(
              userEmails: userEmails,
              onSwitchAccount: (email) =>
                  _handleAccountSelection(email, context),
            );
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
