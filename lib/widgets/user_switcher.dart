import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserSwitcher extends StatelessWidget {
  /// List of alternate user accounts saved locally.
  final List<String> userEmails;
  final void Function(String) onSwitchAccount;

  const UserSwitcher({
    Key? key,
    required this.userEmails,
    required this.onSwitchAccount,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DropdownButton<String>(
      hint: const Text("Switch Account"),
      value: null,
      items: userEmails
          .map((email) => DropdownMenuItem<String>(
                value: email,
                child: Text(email),
              ))
          .toList(),
      onChanged: (value) {
        if (value != null) {
          onSwitchAccount(value);
        }
      },
    );
  }
}
