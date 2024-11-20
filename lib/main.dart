import 'package:flutter/material.dart';
// import 'package:flutter/rendering.dart';
import 'package:get/get.dart';
import 'package:spendify/routes/app_pages.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart' as dotenv;

Future<void> main() async {
  // debugRepaintRainbowEnabled = true;

  await dotenv.dotenv.load(fileName: '.env');
  final supaUri = dotenv.dotenv.env['SUPABASE_URL']; //get env key
  final supaAnon = dotenv.dotenv.env['SUPABASE_ANONKEY'];
  await Supabase.initialize(
    url: supaUri!,
    anonKey: supaAnon!,
  );
  runApp(const MyApp());
}

final supabaseC = Supabase.instance.client;

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      
      debugShowCheckedModeBanner: false,
      title: 'Spendify',
      initialRoute: Routes.SPLASH,
      getPages: AppPages.routes,
    );
  }
}
