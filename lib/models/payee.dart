class Payee {
  final String id;
  final String name;
  final String accountNumber;
  final String bankName;

  Payee({
    required this.id,
    required this.name,
    required this.accountNumber,
    required this.bankName,
  });

  factory Payee.fromMap(String id, Map<String, dynamic> map) {
    return Payee(
      id: id,
      name: map['name'] ?? '',
      accountNumber: map['accountNumber'] ?? '',
      bankName: map['bankName'] ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'accountNumber': accountNumber,
        'bankName': bankName,
      };
}
