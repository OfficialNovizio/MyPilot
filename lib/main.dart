import 'package:emptyproject/screens/analytic_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'Working UI/app_controller.dart';
import 'Working UI/Shift/Shift Screen.dart';
import 'screens/totals_screen.dart';
import 'Working UI/Account/Account.dart';
import 'screens/settings_screen.dart';
import 'Working UI/Dashboard/Dashboard.dart';

//
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
//
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await GetStorage.init();
  Get.put(AppController());
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Two-Job Shift Planner',
      debugShowCheckedModeBanner: false,
      initialBinding: BindingsBuilder(() {
        Get.put<AppController>(AppController(), permanent: true);
        Get.put<DashboardState>(DashboardState(), permanent: true);
      }),
      home: DashboardScreen(),
    );
  }
}

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});
  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int idx = 0;
  final pages = const [
    DashboardScreen(),
    AnalyticsScreen(),
    TotalsScreen(),
    AccountScreen(),
    SettingsScreen(),
  ];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: pages[idx],
      bottomNavigationBar: NavigationBar(
        selectedIndex: idx,
        onDestinationSelected: (i) => setState(() => idx = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.calendar_month), label: 'Calendar'),
          NavigationDestination(icon: Icon(Icons.calendar_view_week), label: 'Week'),
          NavigationDestination(icon: Icon(Icons.summarize), label: 'Totals'),
          NavigationDestination(icon: Icon(Icons.work), label: 'Jobs'),
          NavigationDestination(icon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
    );
  }
}
