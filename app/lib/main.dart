import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'core/config/app_config.dart';
import 'core/constants/app_routes.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/pages/admin_login_page.dart';
import 'features/auth/pages/client_home_page.dart';
import 'features/auth/pages/contractor_home_page.dart';
import 'features/auth/pages/dev_preview_page.dart';
import 'features/auth/pages/phone_input_page.dart';
import 'features/auth/pages/role_select_page.dart';

/// Firebase config แยกตามแพลตฟอร์ม (project เดียวกัน: kasethaul)
const _androidOptions = FirebaseOptions(
  apiKey: 'AIzaSyAggQu4dMEp8-lRRdaT91tA8hZbUqN8cG8',
  appId: '1:333020362164:android:dab408f41a59ecddbd2ee1',
  messagingSenderId: '333020362164',
  projectId: 'kasethaul',
  storageBucket: 'kasethaul.firebasestorage.app',
);

const _webOptions = FirebaseOptions(
  apiKey: 'AIzaSyDvmsjYmDUJZJvWO8loEIyk-tNCgbkbnHM',
  appId: '1:333020362164:web:2d59119ac66ed023bd2ee1',
  messagingSenderId: '333020362164',
  projectId: 'kasethaul',
  authDomain: 'kasethaul.firebaseapp.com',
  storageBucket: 'kasethaul.firebasestorage.app',
);

/// แยก init ออกเพื่อให้ integration_test สามารถ await ได้
Future<void> initializeApp() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (Firebase.apps.isEmpty) {
    try {
      await Firebase.initializeApp(
        options: kIsWeb ? _webOptions : _androidOptions,
      );
      if (kDebugMode) {
        await FirebaseAuth.instance
            .setSettings(appVerificationDisabledForTesting: true);
      }
    } catch (e) {
      // บน web ยังไม่ได้ตั้ง FirebaseOptions สำหรับ web → ปล่อยให้แอปรันต่อ
      // เพื่อใช้ตรวจ UX/UI ได้ (ฟีเจอร์ที่ต้องต่อ Firebase จะใช้ไม่ได้)
      debugPrint('Firebase init skipped (UI preview mode): $e');
    }
  }
  runApp(const KasetHaulApp());
}

void main() => initializeApp();

class KasetHaulApp extends StatelessWidget {
  const KasetHaulApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConfig.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.clientTheme,
      initialRoute: AppRoutes.roleSelect,
      routes: {
        AppRoutes.roleSelect: (_) => const RoleSelectPage(),
        AppRoutes.clientLogin: (_) => const PhoneInputPage(role: 'client'),
        AppRoutes.contractorLogin: (_) =>
            const PhoneInputPage(role: 'contractor'),
        AppRoutes.adminLogin: (_) => const AdminLoginPage(),
        // dev-only: พรีวิว UI บน web โดยไม่ต้องล็อกอิน
        if (kDebugMode) '/dev/preview': (_) => const DevPreviewPage(),
        AppRoutes.clientHome: (ctx) => ClientHomePage(
              clientId: ModalRoute.of(ctx)!.settings.arguments as String,
            ),
        AppRoutes.contractorHome: (ctx) => ContractorHomePage(
              contractorId: ModalRoute.of(ctx)!.settings.arguments as String,
            ),
      },
    );
  }
}
