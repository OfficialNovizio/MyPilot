import 'package:emptyproject/Working%20UI/Constants.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'Working UI/Dashboard/Dashboard.dart';

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

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      navigatorKey: navigatorKey,
      title: 'Two-Job Shift Planner',
      debugShowCheckedModeBanner: false,
      home: DashboardScreen(),
    );
  }
}
