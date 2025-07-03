// fichier: lib/admin/admin_shell_page.dart

import 'package:flutter/material.dart';
import 'admin_dashboard_page.dart';
import 'admin_management_page.dart';
import 'admin_settings_page.dart';

class AdminShellPage extends StatefulWidget {
  final String token;
  final String role;

  const AdminShellPage({
    super.key,
    required this.token,
    required this.role,
  });

  @override
  State<AdminShellPage> createState() => _AdminShellPageState();
}

class _AdminShellPageState extends State<AdminShellPage> {
  int _selectedIndex = 0;

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    // On prépare la liste des pages à afficher.
    // On passe le token et le role à chaque page pour qu'elles puissent les utiliser.
    _pages = [
      AdminDashboardPage(token: widget.token),
      AdminManagementPage(token: widget.token, role: widget.role),
      AdminSettingsPage(token: widget.token, role: widget.role),
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        // On garde le même style que pour les collaborateurs
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: const Color(0xFF3575D3),
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed, // Pour que le fond soit toujours blanc
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            activeIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.folder_open_outlined),
            activeIcon: const Icon(Icons.folder_open),
            label: 'Gestion',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            activeIcon: Icon(Icons.settings),
            label: 'Paramètres',
          ),
        ],
      ),
    );
  }
}