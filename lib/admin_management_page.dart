// Assurez-vous d'importer le nouveau formulaire
import 'package:appli_tibu/school_form_page.dart';
import 'package:appli_tibu/user_form_page.dart';
import 'package:flutter/material.dart';

class AdminManagementPage extends StatefulWidget {
  final String token;
  final String role;
  const AdminManagementPage({super.key, required this.token, required this.role});

  @override
  State<AdminManagementPage> createState() => _AdminManagementPageState();
}

class _AdminManagementPageState extends State<AdminManagementPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Clé pour l'onglet des utilisateurs (inchangé)
  final GlobalKey<_UsersManagementTabState> _usersTabKey = GlobalKey<_UsersManagementTabState>();
  
  // --- NOUVEAU : On crée une clé pour l'onglet des écoles ---
  // Cela nous permettra d'appeler sa fonction d'ajout depuis le FloatingActionButton
  final GlobalKey<_SchoolsManagementTabState> _schoolsTabKey = GlobalKey<_SchoolsManagementTabState>();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestion'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF3575D3),
        elevation: 1,
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF3575D3),
          unselectedLabelColor: Colors.grey,
          indicatorColor: const Color(0xFF3575D3),
          tabs: const [
            Tab(icon: Icon(Icons.people), text: 'Utilisateurs'),
            Tab(icon: Icon(Icons.school), text: 'Écoles'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _UsersManagementTab(key: _usersTabKey, role: widget.role),
          // --- MODIFIÉ : On passe la nouvelle clé à l'onglet des écoles ---
          _SchoolsManagementTab(key: _schoolsTabKey, role: widget.role),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (_tabController.index == 0) {
            // Logique pour ajouter un utilisateur (inchangé)
            _usersTabKey.currentState?._navigateToForm();
          } else {
            // --- MODIFIÉ : On appelle la fonction d'ajout pour les écoles ---
            _schoolsTabKey.currentState?._navigateToSchoolForm();
          }
        },
        backgroundColor: const Color(0xFF3575D3),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

// --- WIDGET POUR L'ONGLET DE GESTION DES UTILISATEURS (INCHANGÉ) ---
class _UsersManagementTab extends StatefulWidget {
  final String role;
  const _UsersManagementTab({super.key, required this.role});

  @override
  State<_UsersManagementTab> createState() => _UsersManagementTabState();
}

class _UsersManagementTabState extends State<_UsersManagementTab> {
  final List<Map<String, String>> _users = [
    {'name': 'Alice Martin', 'email': 'alice@tibu.ma', 'company': 'Tibu Inc.'},
    {'name': 'Bob Durand', 'email': 'bob@innovate.com', 'company': 'Innovate Corp.'},
    {'name': 'Charlie Dupont', 'email': 'charlie@health.com', 'company': 'HealthFirst Ltd.'},
  ];

  void _navigateToForm({Map<String, String>? user}) async {
    if (!mounted) return;
    final result = await Navigator.push<Map<String, String>>(
      context,
      MaterialPageRoute(
        builder: (context) => UserFormPage(user: user),
      ),
    );

    if (result != null) {
      setState(() {
        if (user == null) {
          _users.add(result);
        } else {
          final index = _users.indexOf(user);
          if (index != -1) {
            _users[index] = result;
          }
        }
      });
    }
  }

  void _deleteUser(Map<String, String> user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: Text('Êtes-vous sûr de vouloir supprimer ${user['name']}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _users.remove(user);
              });
              Navigator.of(context).pop();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: _users.length,
      itemBuilder: (context, index) {
        final user = _users[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.blue.shade100,
              child: Text(user['name']![0]),
            ),
            title: Text(user['name']!, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('${user['email']}\n${user['company']}'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(Icons.edit, color: Colors.orange.shade700),
                  onPressed: () => _navigateToForm(user: user),
                ),
                IconButton(
                  icon: Icon(Icons.delete, color: Colors.red.shade700),
                  onPressed: () => _deleteUser(user),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// --- WIDGET POUR L'ONGLET DE GESTION DES ÉCOLES (ENTIÈREMENT REFAIT) ---


class _SchoolsManagementTab extends StatefulWidget {
  final String role;
  const _SchoolsManagementTab({super.key, required this.role});

  @override
  State<_SchoolsManagementTab> createState() => _SchoolsManagementTabState();
}

class _SchoolsManagementTabState extends State<_SchoolsManagementTab> {
  final List<Map<String, dynamic>> _schools = [
    {'name': 'École Al Amal', 'city': 'Casablanca', 'gains': 5250.50},
    {'name': 'École Ibn Tofail', 'city': 'Rabat', 'gains': 3100.00},
    {'name': 'École La Plume', 'city': 'Marrakech', 'gains': 4200.75},
  ];

  void _navigateToSchoolForm({Map<String, dynamic>? school}) async {
    if (!mounted) return;
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (context) => SchoolFormPage(school: school),
      ),
    );

    if (result != null) {
      setState(() {
        if (school == null) {
          _schools.add(result);
        } else {
          final index = _schools.indexOf(school);
          if (index != -1) {
            _schools[index] = result;
          }
        }
      });
    }
  }

  void _deleteSchool(Map<String, dynamic> school) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: Text('Êtes-vous sûr de vouloir supprimer ${school['name']}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _schools.remove(school);
              });
              Navigator.of(context).pop();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: _schools.length,
      itemBuilder: (context, index) {
        final school = _schools[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.green.shade100,
              child: const Icon(Icons.school, color: Colors.green),
            ),
            title: Text(school['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
            
            // --- MODIFIÉ : On utilise une Column dans le subtitle pour afficher la ville ET le budget ---
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(school['city']),
                const SizedBox(height: 4),
                Text(
                  'Budget: ${(school['gains'] as double).toStringAsFixed(2)} MAD',
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    color: Color.fromARGB(255, 39, 114, 42),
                  ),
                ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(Icons.edit, color: Colors.orange.shade700),
                  onPressed: () => _navigateToSchoolForm(school: school),
                ),
                IconButton(
                  icon: Icon(Icons.delete, color: Colors.red.shade700),
                  onPressed: () => _deleteSchool(school),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}