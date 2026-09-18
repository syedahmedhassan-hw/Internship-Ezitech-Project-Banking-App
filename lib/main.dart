import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

import 'controllers/theme_controller.dart';
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/welcome_screen.dart';
import 'screens/home_screen.dart';
import 'screens/admin_screen.dart';
import 'screens/services_screen.dart';
import 'screens/cheque_services_screen.dart';
import 'screens/add_payee_screen.dart';
import 'screens/funds_transfer_screen.dart';
import 'screens/bill_payment_screen.dart';
import 'screens/mobile_payment_screen.dart';
import 'screens/statement_screen.dart';
import 'screens/cards_screen.dart';
import 'screens/generic_info_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const BankApp());
}

class BankApp extends StatelessWidget {
  const BankApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeController.instance.themeNotifier,
      builder: (context, themeMode, child) {
        return MaterialApp(
          title: 'MyBank Digital',
          debugShowCheckedModeBanner: false,
          themeMode: themeMode,

          // Light Theme Design Token Config
          theme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.light,
            colorSchemeSeed: Colors.indigo,
            scaffoldBackgroundColor: const Color(0xFFF8FAFC),
            fontFamily: 'Roboto',
            appBarTheme: const AppBarTheme(
              elevation: 0,
              backgroundColor: Colors.transparent,
              iconTheme: IconThemeData(color: Colors.black87),
              titleTextStyle: TextStyle(
                color: Colors.black87,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            cardTheme: CardThemeData(
              color: Colors.white,
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),

          // Dark Theme Design Token Config
          darkTheme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.dark,
            colorSchemeSeed: Colors.indigo,
            scaffoldBackgroundColor: const Color(0xFF0F172A),
            fontFamily: 'Roboto',
            appBarTheme: const AppBarTheme(
              elevation: 0,
              backgroundColor: Colors.transparent,
              iconTheme: IconThemeData(color: Colors.white),
              titleTextStyle: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            cardTheme: CardThemeData(
              color: const Color(0xFF1E293B),
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),

          initialRoute: '/welcome',
          routes: {
            '/welcome': (_) => const WelcomeScreen(),
            '/login': (_) => const LoginScreen(),
            '/signup': (_) => const SignupScreen(),
            '/home': (_) => const HomeScreen(),
            '/admin': (_) => const AdminScreen(),
            '/services': (_) => const ServicesScreen(),
            '/chequeServices': (_) => const ChequeServicesScreen(),
            '/addPayee': (_) => const AddPayeeScreen(),
            '/fundsTransfer': (_) => const FundsTransferScreen(),
            '/billPayment': (_) => const BillPaymentScreen(),
            '/mobilePayment': (_) => const MobilePaymentScreen(),
            '/statement': (_) => const StatementScreen(),
            '/cards': (_) => const CardsScreen(),
            '/faq': (_) => const GenericInfoScreen(title: 'Frequently Asked Questions'),
            '/terms': (_) => const GenericInfoScreen(title: 'Terms & Conditions'),
            '/privacy': (_) => const GenericInfoScreen(title: 'Privacy Policy'),
            '/userGuide': (_) => const GenericInfoScreen(title: 'User Guide & Tutorials'),
            '/contactUs': (_) => const GenericInfoScreen(title: 'Contact Us'),
            '/helpline': (_) => const GenericInfoScreen(title: '24/7 Helpline & Support'),
          },
        );
      },
    );
  }
}
