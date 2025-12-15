import 'package:flutter/material.dart';

// 1. SABİTLER VE RENKLER
class AppColors {
  AppColors._();
  static const Color background = Color(0xFF0F151C);
  static const Color surface = Color(0xFF1E2732);
  static const Color gold = Color(0xFFD4AF37);
  static const Color goldAccent = Color(0xFFF6C858);
  static const Color white = Color(0xFFE0E0E0);
  static const Color grey = Color(0xFF9E9E9E);
  static const Color green = Color(0xFF4CAF50);
}

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kampüs Asistanı',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.background,
        primaryColor: AppColors.gold,
        fontFamily: 'Roboto',
        useMaterial3: true,
      ),
      home: const CompanionApp(),
    );
  }
}

// 2. ANA İSKELET
class CompanionApp extends StatefulWidget {
  const CompanionApp({super.key});

  @override
  State<CompanionApp> createState() => _CompanionAppState();
}

class _CompanionAppState extends State<CompanionApp> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _selectedIndex = 2; // Başlangıçta Ana Sayfa

  final List<Widget> _pages = <Widget>[
    const CalculatorView(),  // 0: Hesaplama
    const InstitutionView(), // 1: Kurum
    const DashboardView(),   // 2: Ana Sayfa
    const UploadView(),      // 3: Yükle
    const ScheduleView(),    // 4: Program
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  // Profil Menüsü
  void _openProfileMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        height: 250,
        child: Column(
          children: [
            Container(width: 50, height: 5, decoration: BoxDecoration(color: Colors.grey, borderRadius: BorderRadius.circular(10))),
            const SizedBox(height: 20),
            const CircleAvatar(radius: 30, backgroundColor: AppColors.gold, child: Text("KÖ", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black))),
            const SizedBox(height: 10),
            const Text("Kubilay Özkan", style: TextStyle(color: AppColors.white, fontSize: 20, fontWeight: FontWeight.bold)),
            const Text("Bilgisayar Mühendisliği", style: TextStyle(color: AppColors.goldAccent)),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.redAccent),
              title: const Text("Çıkış Yap", style: TextStyle(color: Colors.redAccent)),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.background,
      
      // YAN MENÜ
      drawer: Drawer(
        backgroundColor: AppColors.surface,
        child: Column(
          children: [
            const UserAccountsDrawerHeader(
              decoration: BoxDecoration(color: AppColors.background),
              accountName: Text("Kubilay Özkan", style: TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold)),
              accountEmail: Text("Öğrenci No: 123456789", style: TextStyle(color: Colors.grey)),
              currentAccountPicture: CircleAvatar(
                backgroundColor: AppColors.gold,
                child: Text("KÖ", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.settings, color: AppColors.white),
              title: const Text("Ayarlar", style: TextStyle(color: AppColors.white)),
              onTap: () {},
            ),
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
                  InkWell(
                    onTap: _openProfileMenu,
                    child: Row(
                      children: <Widget>[
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: const [
                            Text("Hesabım", style: TextStyle(color: AppColors.white, fontWeight: FontWeight.bold)),
                            Text("Kubilay Özkan", style: TextStyle(color: AppColors.grey, fontSize: 10)),
                          ],
                        ),
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: AppColors.gold)),
                          child: const CircleAvatar(radius: 16, backgroundColor: Colors.transparent, child: Icon(Icons.person, color: AppColors.white)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(child: IndexedStack(index: _selectedIndex, children: _pages)),
          ],
        ),
      ),
      bottomNavigationBar: CustomBottomNav(selectedIndex: _selectedIndex, onItemTapped: _onItemTapped),
    );
  }
}

// ---------------- EKRANLAR ----------------

// 1. ANA SAYFA (Dashboard)
class DashboardView extends StatelessWidget {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // LOGO
          SizedBox(
            height: 120,
            child: Image.asset(
              'assets/images/logo.png',
              fit: BoxFit.contain,
              errorBuilder: (c, o, s) => Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.school, size: 60, color: AppColors.gold),
                  Text("Logo Yüklenemedi", style: TextStyle(color: AppColors.grey)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 30),
          // Hoşgeldin Kartı
          Container(
            padding: const EdgeInsets.all(20),
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [AppColors.gold.withOpacity(0.2), AppColors.surface]),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.gold.withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text("Hoş Geldin, Kubilay", style: TextStyle(color: AppColors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                SizedBox(height: 5),
                Text("Derslerinde başarılar dileriz.", style: TextStyle(color: Colors.white70)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// 2. KURUM EKRANI (Institution) - CANVAS VE DİĞER LİNKLER SİLİNDİ
class InstitutionView extends StatelessWidget {
  const InstitutionView({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Akademik İşlemler", style: TextStyle(color: AppColors.white, fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          
          // DERS PROGRAMI OLUŞTURMA KARTI
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(25),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.gold.withOpacity(0.5)),
            ),
            child: Column(
              children: [
                const Icon(Icons.edit_calendar, color: AppColors.gold, size: 50),
                const SizedBox(height: 15),
                const Text("Otomatik Ders Programı", style: TextStyle(color: AppColors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                const Text(
                  "Derslerini seç, çakışmaları kontrol edip programını oluşturalım.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.gold,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                  ),
                  child: const Text("Oluştur", style: TextStyle(fontWeight: FontWeight.bold)),
                )
              ],
            ),
          ),
          
          // CANVAS VE DİĞER BAĞLANTILAR KISMI BURADAN SİLİNDİ
        ],
      ),
    );
  }
}

// 3. HESAPLAMA EKRANI
class CalculatorView extends StatelessWidget {
  const CalculatorView({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        children: [
          const Text("AGNO Simülasyonu", style: TextStyle(color: AppColors.white, fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          
          // Özet Kartı
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(15)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStat("Mevcut", "3.05"),
                _buildStat("Tahmini", "3.20", color: AppColors.green),
                _buildStat("Kredi", "18"),
              ],
            ),
          ),
          const SizedBox(height: 20),
          
          // Ders Ekleme Listesi
          Expanded(
            child: ListView.separated(
              itemCount: 6,
              separatorBuilder: (c, i) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Text("Ders ${index + 1}", style: const TextStyle(color: AppColors.white)),
                      ),
                      // Kredi
                      Expanded(
                        child: Container(
                          alignment: Alignment.center,
                          padding: const EdgeInsets.all(5),
                          child: const Text("3 Kr", style: TextStyle(color: AppColors.grey, fontSize: 12)),
                        ),
                      ),
                      // Not
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(8)),
                        child: const Text("AA", style: TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.gold,
              foregroundColor: Colors.black,
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text("HESAPLA", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildStat(String label, String value, {Color? color}) {
    return Column(children: [
      Text(value, style: TextStyle(color: color ?? AppColors.goldAccent, fontSize: 22, fontWeight: FontWeight.bold)),
      Text(label, style: const TextStyle(color: AppColors.grey, fontSize: 12)),
    ]);
  }
}

// 4. YÜKLEME EKRANI
class UploadView extends StatelessWidget {
  const UploadView({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Dosya Yükle", style: TextStyle(color: AppColors.white, fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          
          // Drop Zone
          Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.surface.withOpacity(0.5),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.gold, style: BorderStyle.solid, width: 1),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.cloud_upload_outlined, size: 60, color: AppColors.gold),
                SizedBox(height: 10),
                Text("Dosyaları Buraya Sürükle", style: TextStyle(color: AppColors.white, fontWeight: FontWeight.bold)),
                Text("PDF, DOCX, PPTX (Max 50MB)", style: TextStyle(color: AppColors.grey, fontSize: 12)),
              ],
            ),
          ),
          
          const SizedBox(height: 20),
          Center(
            child: ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.folder_open),
              label: const Text("Cihazdan Seç"),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.surface,
                foregroundColor: AppColors.white,
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
              ),
            ),
          ),

          const SizedBox(height: 30),
          const Text("Son Yüklenenler", style: TextStyle(color: AppColors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          
          // Son Dosyalar Listesi
          Expanded(
            child: ListView(
              children: [
                _buildFileItem("Ders_Programi.pdf", "2.4 MB", "Bugün"),
                _buildFileItem("Proje_Raporu.docx", "5.1 MB", "Dün"),
                _buildFileItem("Sunum.pptx", "12 MB", "12 Ara"),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFileItem(String name, String size, String date) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(10)),
        child: const Icon(Icons.insert_drive_file, color: AppColors.gold),
      ),
      title: Text(name, style: const TextStyle(color: AppColors.white)),
      subtitle: Text(size, style: const TextStyle(color: AppColors.grey, fontSize: 12)),
      trailing: Text(date, style: const TextStyle(color: AppColors.grey)),
    );
  }
}

// 5. PROGRAM EKRANI
class ScheduleView extends StatelessWidget {
  const ScheduleView({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Bugün", style: TextStyle(color: AppColors.white, fontSize: 24, fontWeight: FontWeight.bold)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(20)),
                child: const Text("15 Aralık Pzt", style: TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // Ders Akışı
          Expanded(
            child: ListView(
              children: [
                _buildTimelineItem("09:00", "10:30", "Veri Yapıları", "Amfi-2", "Ahmet Y.", true),
                _buildTimelineItem("10:45", "12:15", "Olasılık", "D-203", "Mehmet K.", false),
                _buildTimelineItem("13:00", "15:00", "Yemek Arası", "Yemekhane", "", false, isBreak: true),
                _buildTimelineItem("15:00", "17:00", "Bilgisayar Ağları", "Lab-1", "Ayşe S.", false),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineItem(String start, String end, String title, String loc, String prof, bool isCurrent, {bool isBreak = false}) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Zaman Sütunu
          SizedBox(
            width: 50,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(start, style: const TextStyle(color: AppColors.white, fontWeight: FontWeight.bold)),
                Text(end, style: const TextStyle(color: AppColors.grey, fontSize: 12)),
              ],
            ),
          ),
          const SizedBox(width: 10),
          
          // Çizgi ve Nokta
          Column(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: isCurrent ? AppColors.gold : (isBreak ? Colors.green : AppColors.surface),
                  shape: BoxShape.circle,
                  border: isCurrent ? Border.all(color: AppColors.goldAccent, width: 2) : null,
                ),
              ),
              Expanded(child: Container(width: 2, color: AppColors.surface)),
            ],
          ),
          const SizedBox(width: 15),
          
          // Kart
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: 20),
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: isBreak ? AppColors.surface.withOpacity(0.5) : (isCurrent ? AppColors.gold : AppColors.surface),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(color: isCurrent ? Colors.black : AppColors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                  if (!isBreak) ...[
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        Icon(Icons.location_on, size: 14, color: isCurrent ? Colors.black54 : AppColors.grey),
                        const SizedBox(width: 4),
                        Text(loc, style: TextStyle(color: isCurrent ? Colors.black54 : AppColors.grey)),
                        const SizedBox(width: 10),
                        Icon(Icons.person, size: 14, color: isCurrent ? Colors.black54 : AppColors.grey),
                        const SizedBox(width: 4),
                        Text(prof, style: TextStyle(color: isCurrent ? Colors.black54 : AppColors.grey)),
                      ],
                    )
                  ]
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ALT MENÜ
class CustomBottomNav extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemTapped;

  const CustomBottomNav({super.key, required this.selectedIndex, required this.onItemTapped});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 10),
      decoration: const BoxDecoration(color: AppColors.background, border: Border(top: BorderSide(color: Colors.white10))),
      child: BottomNavigationBar(
        backgroundColor: AppColors.background,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.goldAccent,
        unselectedItemColor: AppColors.gold,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        currentIndex: selectedIndex,
        onTap: onItemTapped,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.calculate_outlined, size: 28), label: 'Hesap'),
          BottomNavigationBarItem(icon: Icon(Icons.account_balance_outlined, size: 28), label: 'Kurum'),
          BottomNavigationBarItem(icon: Icon(Icons.home, size: 28), label: 'Ana Sayfa'),
          BottomNavigationBarItem(icon: Icon(Icons.upload_file, size: 28), label: 'Yükle'),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_month_outlined, size: 28), label: 'Program'),
        ],
      ),
    );
  }
}