import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BankBottomBar extends StatelessWidget {
  const BankBottomBar({super.key});

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          TextButton.icon(
            onPressed: () => Navigator.pushNamed(context, '/helpline'),
            icon: const Icon(Icons.support_agent),
            label: const Text('Helpline'),
          ),
          TextButton.icon(
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (context.mounted) {
                Navigator.pushNamedAndRemoveUntil(
                    context, '/login', (route) => false);
              }
            },
            icon: const Icon(Icons.logout, color: Colors.red),
            label: const Text('Logout', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
