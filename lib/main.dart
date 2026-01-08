import 'package:emptyproject/Working%20UI/Constants.dart';
import 'package:emptyproject/Working%20UI/Shared%20Preferences.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'Working UI/Dashboard/Dashboard.dart';
import 'Working UI/Login User/Login User.dart';
import 'Working UI/Login User/Onboarding User.dart';

// void main() => runApp(const MyApp());
//
// class MyApp extends StatelessWidget {
//   const MyApp({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       debugShowCheckedModeBanner: false,
//       theme: ThemeData(
//         brightness: Brightness.dark,
//         scaffoldBackgroundColor: const Color(0xFF0B0C0E),
//         fontFamily: 'SF Pro Display',
//         useMaterial3: true,
//         colorScheme: const ColorScheme.dark(
//           primary: Color(0xFF31F27A),
//           secondary: Color(0xFF1F2126),
//           surface: Color(0xFF111317),
//         ),
//       ),
//       home:  homeShell(),
//     );
//   }
// }

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await GetStorage.init();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool? onBoardingCompleted = false;
  @override
  void initState() {
    super.initState();
    _loadOnboarding();
  }

  Future<void> _loadOnboarding() async {
    final v = await getLocalData('Onboarding'); // whatever it returns
    if (!mounted) return;

    setState(() {
      onBoardingCompleted = (v == 'Completed');
    });
  }

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      navigatorKey: navigatorKey,
      title: 'Two-Job Shift Planner',
      debugShowCheckedModeBanner: false,
      home: onBoardingCompleted! ? LoginScreen() : AppOnboardingScreen(),
      // home: DashboardScreen(),
    );
  }
}
