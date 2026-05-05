import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'config/supabase_config.dart';
import 'screens/auth/login_screen.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Supabase first with retry logic
  int retries = 0;
  const maxRetries = 3;
  
  while (retries < maxRetries) {
    try {
      print('🔧 Initializing Supabase (Attempt ${retries + 1}/$maxRetries)...');
      print('📍 URL: $SUPABASE_URL');
      print('🔑 Anon Key: ${SUPABASE_ANON_KEY.substring(0, 20)}...');
      
      await Supabase.initialize(
        url: SUPABASE_URL,
        anonKey: SUPABASE_ANON_KEY,
      ).timeout(const Duration(seconds: 10));
      
      print('✅ Supabase initialized successfully');
      print('🌐 Connection Status: READY');
      break;
    } catch (e, stackTrace) {
      retries++;
      print('❌ Attempt $retries failed: $e');
      print('📋 Stack Trace: $stackTrace');
      
      if (retries < maxRetries) {
        print('⏳ Retrying in 2 seconds...');
        await Future.delayed(const Duration(seconds: 2));
      } else {
        print('❌ Failed to initialize Supabase after $maxRetries attempts');
      }
    }
  }
  
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );
  
  runApp(const ProviderScope(child: SmartSackApp()));
}

class SmartSackApp extends StatelessWidget {
  const SmartSackApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Sack Farming',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      home: const LoginScreen(),
    );
  }
}

