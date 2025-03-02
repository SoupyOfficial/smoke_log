import 'package:flutter/material.dart';

class UserSwitcher extends StatelessWidget {
  /// List of alternate user accounts saved locally.
  final List<String> userEmails;
  final void Function(String) onSwitchAccount;
  final String? currentEmail;

  const UserSwitcher({
    Key? key,
    required this.userEmails,
    required this.onSwitchAccount,
    this.currentEmail,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DropdownButton<String>(
      value: currentEmail,
      hint: const Text("Switch Account"),
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
