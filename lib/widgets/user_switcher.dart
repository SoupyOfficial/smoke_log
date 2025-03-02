import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class UserSwitcher extends StatelessWidget {
  final List<Map<String, String>> accounts;
  final String currentEmail;
  final Function(String) onSwitchAccount;
  final String authType;

  const UserSwitcher({
    Key? key,
    required this.accounts,
    required this.currentEmail,
    required this.onSwitchAccount,
    required this.authType,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      onSelected: onSwitchAccount,
      itemBuilder: (context) {
        final List<PopupMenuEntry<String>> menuItems = [
          ...accounts.map((account) {
            final email = account['email'] ?? '';
            final accountAuthType = account['authType'] ?? 'password';
            final isCurrentUser = email == currentEmail;
            final icon = isCurrentUser ? Icons.check : null;

            return PopupMenuItem<String>(
              value: email,
              child: Row(
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 18),
                    const SizedBox(width: 8),
                  ],
                  Expanded(
                    child: Text(email),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    accountAuthType == 'google'
                        ? FontAwesomeIcons.google
                        : Icons.email,
                    size: 16,
                    color: Colors.grey,
                  ),
                ],
              ),
            );
          }),
          const PopupMenuDivider(),
          PopupMenuItem<String>(
            value: 'Add Account',
            child: Row(
              children: const [
                Icon(Icons.person_add, size: 18),
                SizedBox(width: 8),
                Text('Add Account'),
              ],
            ),
          ),
        ];
        return menuItems;
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            Text(currentEmail),
            const Icon(Icons.arrow_drop_down),
          ],
        ),
      ),
    );
  }
}
