class AppStrings {
  AppStrings._();

  // ============================================================
  // App
  // ============================================================
  static const String appName = 'KasetHaul';
  static const String appTagline = 'แพลตฟอร์มขนส่งสินค้าเกษตร';

  // ============================================================
  // Auth — OTP (UC 3.1.1, 3.1.2, 3.1.17, 3.1.18)
  // ============================================================
  static const String phoneHint = 'กรุณากรอกเบอร์โทรศัพท์';
  static const String otpHint = 'กรุณากรอกรหัส OTP';
  static const String otpSent = 'ส่ง OTP ไปยังเบอร์โทรศัพท์ของคุณแล้ว';
  static const String otpInvalid = 'รหัส OTP ไม่ถูกต้อง หรือหมดอายุ กรุณาลองใหม่อีกครั้ง';
  static const String phoneInvalid = 'กรุณากรอกเบอร์โทรศัพท์ให้ถูกต้อง';
  static const String userNotFound = 'ไม่พบข้อมูลผู้ใช้ กรุณาสมัครสมาชิก';
  static const String phoneAlreadyExists = 'เบอร์นี้เป็นสมาชิกแล้ว กรุณาเข้าสู่ระบบ';

  // ============================================================
  // Login Admin (UC 3.1.36)
  // ============================================================
  static const String usernameHint = 'กรุณากรอกชื่อผู้ใช้';
  static const String passwordHint = 'กรุณากรอกรหัสผ่าน';
  static const String loginFailed = 'ชื่อผู้ใช้หรือรหัสผ่านไม่ถูกต้อง';

  // ============================================================
  // General validation
  // ============================================================
  static const String fieldRequired = 'กรุณากรอกข้อมูลให้ครบถ้วน';
  static const String dataInvalid = 'กรุณากรอกข้อมูลให้ถูกต้อง';
  static const String errorOccurred = 'เกิดข้อผิดพลาด กรุณาลองใหม่อีกครั้ง';
  static const String networkError = 'ไม่สามารถเชื่อมต่อได้ กรุณาตรวจสอบอินเทอร์เน็ต';
  static const String loadingText = 'กำลังโหลด...';
  static const String savingText = 'กำลังบันทึก...';

  // ============================================================
  // Job Status (UC 3.1.4–3.1.13, 3.1.28)
  // ============================================================
  static const String jobStatusWaiting = 'รอผู้รับจ้าง';
  static const String jobStatusNoBid = 'ยังไม่มีผู้รับจ้างยืนยันรับงาน';
  static const String jobStatusAccepted = 'รับงานแล้ว';
  static const String jobStatusEnRoute = 'กำลังดำเนินทางไปรับสินค้า';
  static const String jobStatusArrived = 'ถึงจุดรับสินค้า';
  static const String jobStatusInTransit = 'กำลังขนส่งสินค้า';
  static const String jobStatusDelivered = 'จัดส่งสำเร็จ';
  static const String jobStatusCancelled = 'ยกเลิก';

  // ============================================================
  // Bidding Status (UC 3.1.7–3.1.9, 3.1.28–3.1.30)
  // ============================================================
  static const String biddingStatusPending = 'รอการตอบรับ';
  static const String biddingStatusSelected = 'ได้รับเลือก';
  static const String biddingStatusCancelled = 'ยกเลิก';

  // ============================================================
  // Truck Status (UC 3.1.21–3.1.25, 3.1.37–3.1.39)
  // ============================================================
  static const String truckStatusPending = 'รอตรวจสอบ';
  static const String truckStatusApproved = 'อนุมัติแล้ว';
  static const String truckStatusRejected = 'ถูกปฏิเสธ';
  static const String truckStatusDeleted = 'ถูกลบ';
  static const String truckStatusOnJob = 'กำลังรับงานขนส่ง';

  // ============================================================
  // Transaction Type & Status
  // ============================================================
  static const String transactionTypeDeposit = 'เติมเงิน';
  static const String transactionTypePayment = 'จ่ายค่างาน';
  static const String transactionTypeReceive = 'รับค่างาน';
  static const String transactionTypeWithdraw = 'ถอนเงิน';
  static const String transactionStatusSuccess = 'สำเร็จ';
  static const String transactionStatusPending = 'รอดำเนินการ';
  static const String transactionStatusCancelled = 'ยกเลิก';

  // ============================================================
  // Assign Contractor (UC 3.1.9)
  // ============================================================
  static const String biddingUnavailable = 'ข้อเสนอนี้ถูกยกเลิกหรือไม่สามารถใช้งานได้';

  // ============================================================
  // Cancel Bidding / Edit Bidding (UC 3.1.29–3.1.30)
  // ============================================================
  static const String cannotEditBidding = 'ไม่สามารถแก้ไขได้ เนื่องจากประกาศงานนี้ปิดรับข้อเสนอแล้ว';
  static const String cannotCancelBidding = 'ไม่สามารถยกเลิกได้ เนื่องจากประกาศงานนี้ปิดรับข้อเสนอแล้ว';

  // ============================================================
  // Remove Truck (UC 3.1.25)
  // ============================================================
  static const String cannotRemoveTruckOnJob =
      'ไม่สามารถลบได้ เนื่องจากรถบรรทุกคันนี้กำลังติดงานขนส่ง';

  // ============================================================
  // Submit Bidding (UC 3.1.28)
  // ============================================================
  static const String noAvailableTruck = 'คุณไม่มีรถบรรทุกที่พร้อมรับงานในขณะนี้';

  // ============================================================
  // Track GPS (UC 3.1.14)
  // ============================================================
  static const String locationUnavailable = 'ไม่สามารถระบุตำแหน่งของรถขนส่งในขณะนี้';

  // ============================================================
  // Verify Identity (UC 3.1.19)
  // ============================================================
  static const String thaiIdConnectionError = 'ไม่สามารถเชื่อมต่อระบบยืนยันตัวตนได้ขณะนี้';

  // ============================================================
  // Deposit (UC 3.1.15)
  // ============================================================
  static const String depositMinError = 'จำนวนเงินขั้นต่ำในการเติมคือ ฿100';
  static const String depositMaxError = 'จำนวนเงินสูงสุดในการเติมคือ ฿100,000';

  // ============================================================
  // Withdraw (UC 3.1.34)
  // ============================================================
  static const String withdrawFeeNote = 'ค่าธรรมเนียมการถอน ฿30';
  static const String insufficientBalance = 'ยอดเงินในกระเป๋าไม่เพียงพอ';

  // ============================================================
  // Auth — Phone/OTP input fields & actions
  // ============================================================
  static const String phoneNumber = 'หมายเลขโทรศัพท์';
  static const String phoneRequired = 'กรุณากรอกหมายเลขโทรศัพท์';
  static const String invalidPhone = 'หมายเลขโทรศัพท์ไม่ถูกต้อง';
  static const String sendOtp = 'ส่งรหัส OTP';
  static const String confirm = 'ยืนยัน';
  static const String otpSentTo = 'ส่งรหัส OTP ไปยัง';

  // ============================================================
  // Buttons
  // ============================================================
  static const String btnLogin = 'เข้าสู่ระบบ';
  static const String btnRegister = 'สมัครสมาชิก';
  static const String btnSend = 'ส่ง';
  static const String btnConfirm = 'ยืนยัน';
  static const String btnCancel = 'ยกเลิก';
  static const String btnEdit = 'แก้ไข';
  static const String btnSave = 'บันทึก';
  static const String btnDelete = 'ลบ';
  static const String btnApprove = 'อนุมัติ';
  static const String btnReject = 'ปฏิเสธ';
  static const String btnNext = 'ถัดไป';
  static const String btnBack = 'ย้อนกลับ';
  static const String btnPost = 'โพสต์งาน';
  static const String btnBid = 'เสนอราคา';
  static const String btnAssign = 'เลือกผู้รับจ้าง';
  static const String btnPay = 'ชำระเงิน';
  static const String btnDeposit = 'เติมเงิน';
  static const String btnWithdraw = 'ถอนเงิน';
  static const String btnVerify = 'ยืนยันตัวตน';
  static const String btnUploadSlip = 'อัปโหลดสลิป';
}
