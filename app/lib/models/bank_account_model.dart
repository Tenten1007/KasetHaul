class BankAccountModel {
  final String bankAccountId;
  final String bankName;
  final String accountNumber;
  final String accountName;
  final String contractorId;
  final bool isDefault; // บัญชีหลักสำหรับถอนเงิน (UC 3.1.33)

  const BankAccountModel({
    required this.bankAccountId,
    required this.bankName,
    required this.accountNumber,
    required this.accountName,
    required this.contractorId,
    this.isDefault = false,
  });

  factory BankAccountModel.fromJson(Map<String, dynamic> json) => BankAccountModel(
        bankAccountId: json['bankAccountId'] as String,
        bankName: json['bankName'] as String,
        accountNumber: json['accountNumber'] as String,
        accountName: json['accountName'] as String,
        contractorId: json['contractorId'] as String,
        isDefault: json['isDefault'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() => {
        'bankAccountId': bankAccountId,
        'bankName': bankName,
        'accountNumber': accountNumber,
        'accountName': accountName,
        'contractorId': contractorId,
        'isDefault': isDefault,
      };
}
