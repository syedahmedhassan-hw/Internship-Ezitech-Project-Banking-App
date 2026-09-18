import 'package:flutter/material.dart';
import '../widgets/app_drawer.dart';

class GenericInfoScreen extends StatelessWidget {
  final String title;
  final String? body;

  const GenericInfoScreen({
    super.key,
    required this.title,
    this.body,
  });

  @override
  Widget build(BuildContext context) {
    final lowerTitle = title.toLowerCase();

    return Scaffold(
      appBar: AppBar(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
      drawer: const AppDrawer(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: _buildBodyForTitle(context, lowerTitle),
      ),
    );
  }

  Widget _buildBodyForTitle(BuildContext context, String lowerTitle) {
    if (lowerTitle.contains('terms')) {
      return _buildTermsContent(context);
    } else if (lowerTitle.contains('privacy')) {
      return _buildPrivacyContent(context);
    } else if (lowerTitle.contains('guide')) {
      return _buildUserGuideContent(context);
    } else if (lowerTitle.contains('contact')) {
      return _buildContactUsContent(context);
    } else if (lowerTitle.contains('helpline')) {
      return _buildHelplineContent(context);
    } else if (lowerTitle.contains('faq')) {
      return _buildFaqContent(context);
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Text(body ?? 'No details available.', style: const TextStyle(fontSize: 15)),
      ),
    );
  }

  Widget _buildTermsContent(BuildContext context) {
    final terms = [
      ('1. Account Eligibility & Responsibilities',
       'Customers must be at least 18 years of age with a valid CNIC to open and maintain an account with MyBank. Account holders are solely responsible for maintaining the confidentiality of their PIN, password, and biometric credentials.'),
      ('2. Daily Transaction & Transfer Limits',
       'Standard digital accounts are subject to a daily transfer limit of Rs. 250,000. Higher limits can be unlocked via biometric verification at any MyBank branch.'),
      ('3. Electronic Funds Transfer Policy',
       'All electronic transfers completed via 10-digit Account Numbers or IBANs are instant and irrevocable once authorized by the user via OTP or PIN.'),
      ('4. Account Suspension & Anti-Fraud Security',
       'MyBank reserves the right to freeze or restrict any account suspected of fraudulent activities, unauthorized transactions, or violations of State Bank regulations.'),
      ('5. Service Charges & Fee Schedule',
       'Online banking services, account maintenance, and digital statement generation are free of charge. Physical cheque book issuance is charged at published tariff rates.'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _headerBanner(
          title: 'Terms & Conditions',
          subtitle: 'Effective Date: January 2026 | MyBank Digital Banking Governance',
          icon: Icons.gavel,
          color: Colors.indigo,
        ),
        const SizedBox(height: 20),
        ...terms.map((t) => _cardSection(t.$1, t.$2)),
      ],
    );
  }

  Widget _buildPrivacyContent(BuildContext context) {
    final privacy = [
      ('1. Information Collection & Usage',
       'We collect personal identification data (Full Name, CNIC, Phone Number, Email) and transactional logs solely to fulfill digital banking operations, comply with Know-Your-Customer (KYC) laws, and protect against fraud.'),
      ('2. End-to-End Encryption & Storage Security',
       'All communication between your mobile application and MyBank cloud servers is encrypted using 256-bit SSL/TLS protocol. Financial credentials and biometric hash tokens are stored in secure hardware enclaves.'),
      ('3. Data Sharing & Third-Party Protections',
       'MyBank strictly does NOT sell, lease, or share your personal data with third-party advertisers. Information is only shared with statutory regulatory authorities when legally mandated.'),
      ('4. User Rights & Data Control',
       'Customers have the right to request access to their stored banking records, request account closure, or update their residential address and phone number via the Services hub.'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _headerBanner(
          title: 'Privacy Policy',
          subtitle: 'Your Data Protection & Privacy Rights at MyBank',
          icon: Icons.shield,
          color: Colors.teal,
        ),
        const SizedBox(height: 20),
        ...privacy.map((p) => _cardSection(p.$1, p.$2)),
      ],
    );
  }

  Widget _buildUserGuideContent(BuildContext context) {
    final steps = [
      ('Step 1: Logging in & Account Dashboard',
       'Enter your registered email and password to log in. You will immediately see your live account balance, 10-digit account number, and credit card details.'),
      ('Step 2: Instant Funds Transfer',
       'Navigate to "Send Funds", enter the beneficiary\'s 10-digit Account Number, specify the amount, and tap "Transfer Money" to send funds instantly.'),
      ('Step 3: Paying Utility Bills & Mobile Load',
       'Tap "Bill Payment" or "Mobile Load" on the Home Screen. Select your service provider, enter your consumer ID, and confirm payment.'),
      ('Step 4: Requesting Cheque Books & Deposits',
       'Visit the "Services" screen and select "Online Cheque". You can order a new cheque book or deposit a physical cheque by scanning front and back photos.'),
      ('Step 5: Account Security & Freezing Card',
       'If your card is misplaced, navigate to "Cards" or "Services" and toggle "Freeze Card" to immediately block all incoming transactions.'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _headerBanner(
          title: 'User Guide & Tutorials',
          subtitle: 'Master MyBank Mobile App Features Step-by-Step',
          icon: Icons.menu_book,
          color: Colors.blue,
        ),
        const SizedBox(height: 20),
        ...steps.map((s) => _cardSection(s.$1, s.$2)),
      ],
    );
  }

  Widget _buildContactUsContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _headerBanner(
          title: 'Contact Us',
          subtitle: 'We are here to assist you 24/7 across all channels',
          icon: Icons.contact_support,
          color: Colors.purple,
        ),
        const SizedBox(height: 20),
        _contactTile(
          icon: Icons.email,
          color: Colors.indigo,
          title: 'Email Customer Support',
          value: 'support@mybank.com',
          actionText: 'Send Email',
        ),
        const SizedBox(height: 12),
        _contactTile(
          icon: Icons.phone_in_talk,
          color: Colors.green,
          title: '24/7 Helpline Number',
          value: '+92 (021) 111-222-333',
          actionText: 'Call Now',
        ),
        const SizedBox(height: 12),
        _contactTile(
          icon: Icons.location_city,
          color: Colors.orange,
          title: 'Head Office Address',
          value: 'MyBank Tower, I.I. Chundrigar Road, Karachi, Pakistan',
          actionText: 'Locate Branch',
        ),
        const SizedBox(height: 12),
        _contactTile(
          icon: Icons.chat_bubble_outline,
          color: Colors.teal,
          title: 'WhatsApp Banking Assist',
          value: '+92 300 0800123',
          actionText: 'Chat on WhatsApp',
        ),
      ],
    );
  }

  Widget _buildHelplineContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _headerBanner(
          title: '24/7 Emergency Helpline',
          subtitle: 'Immediate assistance for card blocking, fraud, & account emergencies',
          icon: Icons.support_agent,
          color: Colors.red,
        ),
        const SizedBox(height: 20),
        Card(
          color: Colors.red.shade50,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.red.shade200),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 48),
                const SizedBox(height: 12),
                const Text(
                  'Lost Card or Suspected Fraud?',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Call our dedicated Fraud & Emergency hotline immediately to freeze your account and block your card.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.redAccent, fontSize: 13),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.phone, color: Colors.white),
                  label: const Text('Call Emergency Hotline: 0800-12345'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        _cardSection(
          'Standard Support Services',
          'For routine inquiries regarding balance checks, account statements, cheque clearing status, or bill payment confirmation, contact our general customer care hotline at +92 (021) 111-222-333.',
        ),
      ],
    );
  }

  Widget _buildFaqContent(BuildContext context) {
    final faqs = [
      ('How do I find my 10-digit Account Number?',
       'Your 10-digit Account Number is prominently displayed on your Home Screen under the Available Balance card, as well as on your Profile screen.'),
      ('How can I deposit physical cheques online?',
       'Navigate to "Services" -> "Online Cheque" -> "Deposit Cheque". Enter the 6-digit cheque number, issuing bank, amount, and upload photos of both sides.'),
      ('What happens if I freeze my card?',
       'Freezing your card instantly blocks all point-of-sale (POS) purchases, online payments, and ATM withdrawals. You can unfreeze it anytime with one tap.'),
      ('Is there any fee for transferring money to other MyBank accounts?',
       'No! Account-to-account transfers within MyBank are 100% free of charge and instant.'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _headerBanner(
          title: 'Frequently Asked Questions',
          subtitle: 'Quick answers to common questions about MyBank',
          icon: Icons.quiz,
          color: Colors.indigo,
        ),
        const SizedBox(height: 20),
        ...faqs.map((f) => ExpansionTile(
              title: Text(f.$1, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Text(f.$2, style: const TextStyle(color: Colors.grey, fontSize: 13)),
                ),
              ],
            )),
      ],
    );
  }

  Widget _headerBanner({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: color.withOpacity(0.2),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
                const SizedBox(height: 4),
                Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _cardSection(String title, String description) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 8),
            Text(description, style: const TextStyle(color: Colors.grey, fontSize: 13, height: 1.4)),
          ],
        ),
      ),
    );
  }

  Widget _contactTile({
    required IconData icon,
    required Color color,
    required String title,
    required String value,
    required String actionText,
  }) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.12),
          child: Icon(icon, color: color),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        subtitle: Text(value, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        trailing: ElevatedButton(
          onPressed: () {},
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: Text(actionText, style: const TextStyle(fontSize: 11)),
        ),
      ),
    );
  }
}
