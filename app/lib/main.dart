import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/live_camera_ocr_screen.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: AppColors.oledCanvas,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );
  runApp(const SplitBillZeroHostApp());
}

class SplitBillZeroHostApp extends StatelessWidget {
  const SplitBillZeroHostApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SplitBill Zero Host',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.oledCanvas,
        primaryColor: AppColors.electricCyan,
        fontFamily: 'Inter',
        useMaterial3: true,
      ),
      home: const LiveCameraOcrScreen(),
    );
  }
}
