import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'config/app_theme.dart';
import 'screens/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // تهيئة Supabase (بدون authCallbackUrl)
  await Supabase.initialize(
    url: 'https://wdhrhwxsuuhgtiukvlan.supabase.co',
    anonKey: 'sb_publishable_HegN_CSUoB-s7oSr-vazBw_gjozjhdC',
  );
  
  runApp(const SuperJeebApp());
}

class SuperJeebApp extends StatelessWidget {
  const SuperJeebApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Super Jeeb',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const LoginScreen(),
    );
  }
}
