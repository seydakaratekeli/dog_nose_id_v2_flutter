import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../theme/theme_provider.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String? email;
  String displayName = "Kullanıcı"; // Varsayılan isim
  int dogCount = 0;
  int lostCount = 0;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  // Profil verilerini çek (Sayfa her açıldığında tetiklenmeli)
  Future<void> _loadProfileData() async {
    final user = FirebaseAuth.instance.currentUser;
    email = user?.email;
    final uid = user?.uid;

    if (uid != null) {
      // 1. Kullanıcı Bilgilerini Çek (Ad Soyad için)
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (userDoc.exists) {
        setState(() {
          displayName = userDoc.data()?['displayName'] ?? "Kullanıcı";
        });
      }

      // 2. Köpek Sayısını Çek
      final dogs = await FirebaseFirestore.instance
          .collection("users")
          .doc(uid)
          .collection("dogs")
          .get();

      // 3. Kayıp Bildirim Sayısını Çek
      final lostDogs = await FirebaseFirestore.instance
          .collection("lost_dogs")
          .where('userId', isEqualTo: uid)
          .get();

      if (mounted) {
        setState(() {
          dogCount = dogs.docs.length;
          lostCount = lostDogs.docs.length;
          loading = false;
        });
      }
    } else {
        if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      context.go("/");
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Profilim")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // -----------------------------------
            // PROFIL KARTI
            // -----------------------------------
            Center(
              child: Column(
                children: [
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 48,
                        backgroundColor: theme.colorScheme.primaryContainer,
                        child: Icon(Icons.person, size: 50, color: theme.colorScheme.onPrimaryContainer),
                      ),
                      // DÜZENLEME BUTONU (Kalem ikonu)
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: () async {
                            // Düzenleme sayfasına git ve dönünce verileri yenile
                            await context.push("/edit-profile");
                            _loadProfileData(); 
                          },
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                              color: Colors.blue,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.edit, size: 18, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  Text(
                    displayName, // Artık isim görünüyor
                    style: theme.textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    email ?? "",
                    style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // -----------------------------------
            // İSTATISTIK KARTLARI
            // -----------------------------------
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildStat("Kayıtlı Köpek", dogCount.toString(), Icons.pets),
                    _buildStat("Kayıp Bildirim", lostCount.toString(), Icons.warning_amber),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 30),

            // -----------------------------------
            // MENU SEÇENEKLERİ
            // -----------------------------------
            Text(
              "Ayarlar",
              style: theme.textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 10),

            _buildMenuItem(
              icon: Icons.list_alt,
              title: "Köpeklerim",
              onTap: () => context.push("/my-dogs"), 
            ),

            _buildMenuItem(
              icon: Icons.history_edu,
              title: "İlanlarım ve Bildirimlerim",
              onTap: () => context.push("/my-reports"), 
            ),

            _buildMenuItem(
              icon: Icons.color_lens_outlined,
              title: "Karanlık Mod",
              trailing: Consumer<ThemeProvider>(
                builder: (context, themeProvider, child) {
                  return Switch(
                    value: themeProvider.isDarkMode,
                    onChanged: (value) {
                      themeProvider.toggleTheme(value);
                    },
                  );
                },
              ),
              onTap: () {}, // Switch kullanıldığı için boş kalabilir
            ),

            // "Hakkında" butonu SİLİNDİ ❌

            const SizedBox(height: 20),

            // -----------------------------------
            // ÇIKIŞ BUTONU
            // -----------------------------------
            Center(
              child: ElevatedButton.icon(
                onPressed: _logout,
                icon: const Icon(Icons.logout),
                label: const Text("Çıkış Yap"),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  backgroundColor: Colors.red.shade50,
                  foregroundColor: Colors.red,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ISTATISTIK KARTI WIDGET
  Widget _buildStat(String title, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 34, color: Colors.blueAccent),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(title, style: const TextStyle(color: Colors.grey)),
      ],
    );
  }

  // MENU ITEM WIDGET
  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Widget? trailing, // Opsiyonel parametre
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(icon, size: 28, color: Colors.grey.shade700),
        title: Text(title),
        trailing: trailing ?? const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}