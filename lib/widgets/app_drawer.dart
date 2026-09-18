import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../controllers/theme_controller.dart';

class AppDrawer extends StatefulWidget {
  const AppDrawer({super.key});

  @override
  State<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {
  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final uid = currentUser?.uid;

    return Drawer(
      child: Column(
        children: [
          // User Header
          if (uid != null)
            StreamBuilder<DocumentSnapshot>(
              stream:
                  FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
              builder: (context, snapshot) {
                final data =
                    snapshot.data?.data() as Map<String, dynamic>? ?? {};
                final name = data['name'] ?? 'Bank Customer';
                final email = data['email'] ?? currentUser?.email ?? '';
                final accNo = data['accountNumber'] ?? '----------';
                final role = data['role'] ?? 'user';

                return UserAccountsDrawerHeader(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF1E293B), Color(0xFF334155)],
                    ),
                  ),
                  currentAccountPicture: CircleAvatar(
                    backgroundColor: Colors.indigo.shade100,
                    child: Text(
                      name.isNotEmpty ? name[0].toUpperCase() : 'B',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.indigo,
                      ),
                    ),
                  ),
                  accountName: Row(
                    children: [
                      Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                      if (role == 'admin') ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.purple,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text('ADMIN', style: TextStyle(fontSize: 9, color: Colors.white)),
                        ),
                      ],
                    ],
                  ),
                  accountEmail: Text('Acc: $accNo | $email'),
                );
              },
            )
          else
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.indigo),
              child: Center(
                child: Text('MyBank App',
                    style: TextStyle(color: Colors.white, fontSize: 20)),
              ),
            ),

          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _drawerItem(context, Icons.home, 'Home Dashboard', '/home'),
                _drawerItem(context, Icons.miscellaneous_services, 'Banking Services Hub', '/services'),
                _drawerItem(context, Icons.credit_card, 'Cards & Settings', '/cards'),
                _drawerItem(context, Icons.article, 'Account Statement', '/statement'),
                _drawerItem(context, Icons.receipt_long, 'Bill Payment', '/billPayment'),
                _drawerItem(context, Icons.phone_android, 'Mobile Load', '/mobilePayment'),
                const Divider(),

                // Admin Panel link (if logged in user is admin)
                if (uid != null)
                  StreamBuilder<DocumentSnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('users')
                        .doc(uid)
                        .snapshots(),
                    builder: (context, snap) {
                      final data = snap.data?.data() as Map<String, dynamic>? ?? {};
                      if (data['role'] == 'admin') {
                        return _drawerItem(
                          context,
                          Icons.admin_panel_settings,
                          'Bank Admin Panel',
                          '/admin',
                          iconColor: Colors.purple,
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),

                // Theme Toggle Switch Tile
                ValueListenableBuilder<ThemeMode>(
                  valueListenable: ThemeController.instance.themeNotifier,
                  builder: (context, mode, child) {
                    final isDark = mode == ThemeMode.dark;
                    return SwitchListTile(
                      secondary: Icon(
                        isDark ? Icons.nightlight_round : Icons.wb_sunny,
                        color: isDark ? Colors.amber : Colors.indigo,
                      ),
                      title: Text(isDark ? 'Dark Theme' : 'Light Theme'),
                      value: isDark,
                      onChanged: (val) {
                        ThemeController.instance.toggleTheme();
                      },
                    );
                  },
                ),

                const Divider(),
                _drawerItem(context, Icons.contact_support, 'Contact Us', '/contactUs'),
                _drawerItem(context, Icons.support_agent, '24/7 Helpline', '/helpline'),
                _drawerItem(context, Icons.quiz, 'FAQs', '/faq'),
                _drawerItem(context, Icons.gavel, 'Terms & Conditions', '/terms'),
                _drawerItem(context, Icons.security, 'Privacy Policy', '/privacy'),
                _drawerItem(context, Icons.help_outline, 'User Guide', '/userGuide'),
              ],
            ),
          ),

          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Logout', style: TextStyle(color: Colors.red)),
            onTap: () async {
              await FirebaseAuth.instance.signOut();
              if (context.mounted) {
                Navigator.pushReplacementNamed(context, '/login');
              }
            },
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _drawerItem(
    BuildContext context,
    IconData icon,
    String title,
    String route, {
    Color? iconColor,
  }) {
    return ListTile(
      leading: Icon(icon, color: iconColor ?? Colors.indigo),
      title: Text(title),
      onTap: () {
        Navigator.pop(context); // Close drawer
        Navigator.pushNamed(context, route);
      },
    );
  }
}
