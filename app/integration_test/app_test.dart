// Integration test entry point สำหรับ KasetHaul — ครอบคลุมทุก 39 UC
// รันด้วย: flutter test integration_test/app_test.dart -d <device-id> --timeout 180s
import 'package:integration_test/integration_test.dart';

import 'tests/auth_test.dart' as auth;
import 'tests/register_test.dart' as register;
import 'tests/client_profile_test.dart' as client_profile;
import 'tests/post_job_test.dart' as post_job;
import 'tests/wallet_test.dart' as wallet;
import 'tests/job_bidding_test.dart' as job_bidding;
import 'tests/client_job_test.dart' as client_job;
import 'tests/bidding_test.dart' as bidding;
import 'tests/contractor_profile_test.dart' as contractor_profile;
import 'tests/truck_test.dart' as truck;
import 'tests/contractor_action_test.dart' as contractor_action;
import 'tests/job_status_test.dart' as job_status;
import 'tests/admin_test.dart' as admin;
import 'tests/e2e_post_job_test.dart' as e2e_post_job;
import 'tests/e2e_bid_test.dart' as e2e_bid;
import 'tests/e2e_wallet_test.dart' as e2e_wallet;
import 'tests/e2e_profile_edit_test.dart' as e2e_profile;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // UC 3.1.1, 3.1.16 — Login
  auth.main();
  // UC 3.1.2, 3.1.17 — Register
  register.main();
  // UC 3.1.3, 3.1.15 — Client Profile & Statistics
  client_profile.main();
  // UC 3.1.4, 3.1.9, 3.1.12 — Post/Edit/Cancel Job
  post_job.main();
  // UC 3.1.5, 3.1.6 — List & View Job (Client)
  client_job.main();
  // UC 3.1.7, 3.1.8, 3.1.10, 3.1.11, 3.1.13 — Bidding & Payment & GPS
  job_bidding.main();
  // UC 3.1.14 — Wallet & Deposit
  wallet.main();
  // UC 3.1.18, 3.1.19, 3.1.34 — Contractor Profile & Earnings
  contractor_profile.main();
  // UC 3.1.20–3.1.24 — Truck CRUD
  truck.main();
  // UC 3.1.25, 3.1.26 — Search Jobs & View Detail
  bidding.main();
  // UC 3.1.27, 3.1.28, 3.1.29, 3.1.32, 3.1.33 — Bid & Review & Withdraw
  contractor_action.main();
  // UC 3.1.30, 3.1.31 — My Jobs & Update Status
  job_status.main();
  // UC 3.1.35–3.1.39 — Admin
  admin.main();

  // ─── Deep E2E: form fill + real submission ───
  // E2E UC 3.1.4 — Post Job form ครบ 4 steps
  e2e_post_job.main();
  // E2E UC 3.1.26 — Bid Job: เลือกรถ กรอกราคา ส่งข้อเสนอ
  e2e_bid.main();
  // E2E UC 3.1.14 — Top-Up: กรอกจำนวน กดดำเนินการ
  e2e_wallet.main();
  // E2E UC 3.1.3, 3.1.19 — Edit Profile: กรอกชื่อ บันทึก
  e2e_profile.main();
}
