import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:silagan_advmobprog/providers/theme_provider.dart';
import 'package:silagan_advmobprog/screens/home_screen.dart';
import 'package:silagan_advmobprog/screens/profile_screen.dart';
import 'package:silagan_advmobprog/screens/settings_screen.dart';
import 'package:silagan_advmobprog/screens/signin_screen.dart';
import 'package:silagan_advmobprog/screens/signup_screen.dart';
import 'package:silagan_advmobprog/screens/splash_screen.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations(<DeviceOrientation>[
    DeviceOrientation.portraitUp,
  ]);
  await dotenv.load(fileName: 'assets/.env');
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const SilaganAdvMobProg());
}

class SilaganAdvMobProg extends StatelessWidget {
  const SilaganAdvMobProg({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: ScreenUtilInit(
        designSize: const Size(412, 915),
        minTextAdapt: true,
        splitScreenMode: true,
        builder: (context, child) {
          final themeProvider = context.watch<ThemeProvider>();

          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'E-Commerce App',
            theme: ThemeData.light(useMaterial3: true),
            darkTheme: ThemeData.dark(useMaterial3: true),
            themeMode: themeProvider.themeMode,
            initialRoute: '/',
            routes: <String, WidgetBuilder>{
              '/': (context) => const SplashScreen(),
              '/signin': (context) => const LoginScreen(),
              '/signup': (context) => const SignupScreen(),
              '/profile': (context) => const ProfileScreen(),
              '/home': (context) => const HomeScreen(),
              '/settings': (context) => const SettingsScreen(),
            },
          );
        },
      ),
    );
  }
}
