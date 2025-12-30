import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/constants/app_colors.dart';

// ViewModels
import 'viewmodels/auth_viewmodel.dart';
import 'viewmodels/calculator_viewmodel.dart';
import 'viewmodels/upload_viewmodel.dart';
import 'viewmodels/schedule_viewmodel.dart';
import 'viewmodels/schedule_builder_viewmodel.dart';

// Views
import 'views/login_view.dart';
import 'views/dashboard_view.dart';
import 'views/calculator_view.dart';
import 'views/upload_view.dart';
import 'views/schedule_view.dart';
import 'views/schedule_builder_view.dart';

// --- BU FONKSİYON UYGULAMANIN GİRİŞ KAPISIDIR ---
void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthViewModel()),
        ChangeNotifierProvider(create: (_) => CalculatorViewModel()),
        ChangeNotifierProvider(create: (_) => UploadViewModel()),
        ChangeNotifierProvider(create: (_) => ScheduleViewModel()),
        ChangeNotifierProvider(create: (_) => ScheduleBuilderViewModel()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Companion',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.background,
        primaryColor: AppColors.gold,
        fontFamily: 'Roboto',
        useMaterial3: true,
      ),
      home: Consumer<AuthViewModel>(
        builder: (context, authViewModel, child) {
          // Giriş yapılmışsa uygulamayı, yapılmamışsa Login ekranını aç
          return authViewModel.isLoggedIn 
              ? const CompanionApp() 
              : const LoginView();
        },
      ),
    );
  }
}

class CompanionApp extends StatefulWidget {
  const CompanionApp({super.key});

  @override
  State<CompanionApp> createState() => _CompanionAppState();
}

class _CompanionAppState extends State<CompanionApp> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _selectedIndex = 2; // Başlangıçta Ana Sayfa

  // Sayfalar
  final List<Widget> _pages = [
    const CalculatorView(),
    const ScheduleBuilderView(),
    const DashboardView(),
    const UploadView(),
    const ScheduleView(),
  ];

  @override
  void initState() {
    super.initState();
    // Uygulama açılınca gerekli verileri çekmeyi dene
    // build işlemi bittikten sonra çalışması için addPostFrameCallback kullanıyoruz
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Eğer giriş yapmış bir kullanıcı varsa verilerini çek
      final authVm = context.read<AuthViewModel>();
      if (authVm.currentUser != null) {
        final userId = authVm.currentUser!.id;
        context.read<UploadViewModel>().fetchFiles(userId);
        context.read<ScheduleViewModel>().init(userId);
      }
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthViewModel>().currentUser;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.background,
      
      // YAN MENÜ (DRAWER)
      drawer: Drawer(
        backgroundColor: AppColors.surface,
        child: Column(
          children: [
            UserAccountsDrawerHeader(
              decoration: const BoxDecoration(color: AppColors.background),
              accountName: Text(user?.name ?? "Misafir", style: const TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold)),
              accountEmail: Text(user?.studentNo ?? "Giriş Yapılmadı", style: const TextStyle(color: Colors.grey)),
              currentAccountPicture: CircleAvatar(
                backgroundColor: AppColors.gold,
                child: Text(user != null && user.name.isNotEmpty ? user.name[0] : "M", style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.settings, color: AppColors.white),
              title: const Text("Ayarlar", style: TextStyle(color: AppColors.white)),
              onTap: () {},
            ),
            const Spacer(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.redAccent),
              title: const Text("Çıkış Yap", style: TextStyle(color: Colors.redAccent)),
              onTap: () {
                context.read<AuthViewModel>().logout();
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),

      body: SafeArea(
        child: Column(
          children: <Widget>[
            // HEADER
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  IconButton(
                    icon: const Icon(Icons.menu, color: AppColors.white, size: 30),
                    onPressed: () => _scaffoldKey.currentState?.openDrawer(),
                  ),
                  const Text("Companion", style: TextStyle(color: AppColors.gold, fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 1)),
                  const CircleAvatar(
                    radius: 18, 
                    backgroundColor: AppColors.surface, 
                    child: Icon(Icons.person, color: AppColors.gold, size: 20)
                  ),
                ],
              ),
            ),
            Expanded(child: _pages[_selectedIndex]),
          ],
        ),
      ),
      
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: AppColors.background,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.gold,
        unselectedItemColor: Colors.grey,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.calculate_outlined), label: 'Hesap'),
          BottomNavigationBarItem(icon: Icon(Icons.build_circle_outlined), label: 'Oluştur'),
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Ana'),
          BottomNavigationBarItem(icon: Icon(Icons.upload_file), label: 'Yükle'),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_month), label: 'Takvim'),
        ],
      ),
    );
  }
}