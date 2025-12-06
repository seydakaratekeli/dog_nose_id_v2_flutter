import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String? email;
  int dogCount = 0;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    final user = FirebaseAuth.instance.currentUser;
    email = user?.email;

    // Kayıtlı köpek sayısını çek
    final uid = user?.uid;

    if (uid != null) {
      final dogs = await FirebaseFirestore.instance
          .collection("users")
          .doc(uid)
          .collection("dogs")
          .get();

      dogCount = dogs.docs.length;
    }

    if (mounted) {
      setState(() {
        loading = false;
      });
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
                  CircleAvatar(
                    radius: 48,
                    backgroundColor: theme.colorScheme.primaryContainer,
                    child: const Icon(Icons.person, size: 50),
                  ),
                  const SizedBox(height: 12),

                  Text(
                    email ?? "Bilinmeyen Kullanıcı",
                    style: theme.textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.bold),
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
                    _buildStat("Kayıp Bildirim", "0", Icons.warning_amber),
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
              onTap: () => context.go("/home"), // HomePage’de liste var
            ),

            _buildMenuItem(
              icon: Icons.color_lens_outlined,
              title: "Tema Değiştir",
              onTap: () {
                // Tema sistemi sana bağlı – istersen buradan trigger edebiliriz
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Tema fonksiyonu eklenmedi.")),
                );
              },
            ),

            _buildMenuItem(
              icon: Icons.info_outline,
              title: "Hakkında",
              onTap: () {},
            ),

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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // -----------------------------------
  // ISTATISTIK KARTI WIDGET
  // -----------------------------------
  Widget _buildStat(String title, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 34),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(title),
      ],
    );
  }

  // -----------------------------------
  // MENU ITEM WIDGET
  // -----------------------------------
  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(icon, size: 28),
        title: Text(title),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
