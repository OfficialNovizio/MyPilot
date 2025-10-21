import 'package:emptyproject/screens/analytic_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'Working UI/app_controller.dart';
import 'Working UI/Shift/Shift Screen.dart';
import 'screens/totals_screen.dart';
import 'screens/jobs_screen.dart';
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
    JobsScreen(),
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

// import 'package:emptyproject/controllers/debt_controller.dart';
// import 'package:emptyproject/screens/debt/debt_home.dart';
// import 'package:emptyproject/services/storage_service.dart';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
//
// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();
//   await StorageService.init();
//   runApp(const MyApp());
// }
//
// class MyApp extends StatelessWidget {
//   const MyApp({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     return GetMaterialApp(
//       theme: ThemeData.dark(useMaterial3: true),
//       home: const DebtShell(),
//       debugShowCheckedModeBanner: false,
//     );
//   }
// }
//
// class DebtShell extends StatefulWidget {
//   const DebtShell({super.key});
//   @override
//   State<DebtShell> createState() => _DebtShellState();
// }
//
// class _DebtShellState extends State<DebtShell> {
//   int _idx = 0;
//
//   @override
//   void initState() {
//     super.initState();
//     Get.put(DebtController());
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final tabs = [
//       const DebtHome(),
//       const DebtListScreen(),
//       const PlanScreen(),
//       const DebtSettingsScreen(),
//     ];
//     final items = const [
//       BottomNavigationBarItem(icon: Icon(Icons.dashboard_outlined), label: 'Overview'),
//       BottomNavigationBarItem(icon: Icon(Icons.account_balance_wallet_outlined), label: 'Debts'),
//       BottomNavigationBarItem(icon: Icon(Icons.timeline_outlined), label: 'Plan'),
//       BottomNavigationBarItem(icon: Icon(Icons.settings_outlined), label: 'Settings'),
//     ];
//     return Scaffold(
//       appBar: AppBar(title: const Text('Debt Manager')),
//       body: tabs[_idx],
//       bottomNavigationBar: NavigationBar(
//         selectedIndex: _idx,
//         destinations: [for (final i in items) NavigationDestination(icon: i.icon!, label: i.label!)],
//         onDestinationSelected: (i)=>setState(()=>_idx=i),
//       ),
//     );
//   }
// }

// lib/widgets/glass.dart

class Glass extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final EdgeInsets margin;
  final Color? surface;
  final List<Widget>? actions;
  final String? title;
  final Widget? leading;
  const Glass({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(12),
    this.margin = const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    this.surface,
    this.actions,
    this.title,
    this.leading,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: (surface ?? theme.colorScheme.surface).withOpacity(.92),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor.withOpacity(.12)),
        boxShadow: const [BoxShadow(blurRadius: 16, color: Colors.black26, offset: Offset(0, 4))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (title != null) ...[
          Row(children: [
            if (leading != null) ...[leading!, const SizedBox(width: 8)],
            Text(title!, style: const TextStyle(fontWeight: FontWeight.w700)),
            const Spacer(),
            if (actions != null) ...actions!,
          ]),
          const SizedBox(height: 8),
        ],
        child,
      ]),
    );
  }
}

class SubtleBackdrop extends StatelessWidget {
  final Widget child;
  const SubtleBackdrop({super.key, required this.child});
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0B0D12), Color(0xFF0E1116)],
        ),
      ),
      child: Stack(children: [
        // faint grid
        Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(painter: _GridPainter()),
          ),
        ),
        child,
      ]),
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = const Color(0xFF1F2430).withOpacity(.35)
      ..strokeWidth = 1;
    const step = 28.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), p);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), p);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
