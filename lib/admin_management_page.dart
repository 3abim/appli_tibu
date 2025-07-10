import '../services/api_service.dart'; 
import 'package:appli_tibu/school_form_page.dart';
import 'package:appli_tibu/user_form_page.dart';
import 'package:flutter/material.dart';

// Le widget AdminManagementPage parent reste presque inchangé
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
  final GlobalKey<_UsersManagementTabState> _usersTabKey = GlobalKey<_UsersManagementTabState>();
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
  
  void _onAddButtonPressed() {
    // La logique ici reste la même, elle délègue l'action à l'onglet actif
    if (_tabController.index == 0) {
      _usersTabKey.currentState?.navigateToForm();
    } else {
      _schoolsTabKey.currentState?.navigateToSchoolForm();
    }
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
            Tab(icon: Icon(Icons.people), text: 'Administrateurs'),
            Tab(icon: Icon(Icons.school), text: 'Écoles'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _UsersManagementTab(key: _usersTabKey, role: widget.role),
          _SchoolsManagementTab(key: _schoolsTabKey, role: widget.role),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _onAddButtonPressed,
        backgroundColor: const Color(0xFF3575D3),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}


// --- WIDGET POUR L'ONGLET DE GESTION DES UTILISATEURS (REFAIT AVEC API) ---
class _UsersManagementTab extends StatefulWidget {
  final String role;
  const _UsersManagementTab({super.key, required this.role});

  @override
  State<_UsersManagementTab> createState() => _UsersManagementTabState();
}

class _UsersManagementTabState extends State<_UsersManagementTab> {
  late Future<List<dynamic>> _usersFuture;
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  void _loadUsers() {
    setState(() {
      _usersFuture = _apiService.getAdmins();
    });
  }

  // Cette méthode est maintenant publique pour être appelée depuis le parent
  void navigateToForm({Map<String, dynamic>? user}) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        // On passe les données au format attendu par UserFormPage
        builder: (context) => UserFormPage(user: user),
      ),
    );

    // Si le formulaire retourne true (succès), on recharge la liste
    if (result == true) {
      _loadUsers();
    }
  }

  void _deleteUser(String userId, String userName) {
     showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: Text('Êtes-vous sûr de vouloir supprimer $userName?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () async {
              try {
                await _apiService.deleteAdmin(userId);
                Navigator.of(context).pop();
                _loadUsers(); // Recharger la liste
              } catch (e) {
                 Navigator.of(context).pop();
                 ScaffoldMessenger.of(context).showSnackBar(
                   SnackBar(content: Text('Erreur: ${e.toString()}'))
                 );
              }
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
    return FutureBuilder<List<dynamic>>(
      future: _usersFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Erreur: ${snapshot.error}'));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('Aucun administrateur trouvé.'));
        }

        final users = snapshot.data!;
        return RefreshIndicator(
          onRefresh: () async => _loadUsers(),
          child: ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index] as Map<String, dynamic>;
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.blue.shade100,
                    child: Text(user['prenom']?[0] ?? '?'),
                  ),
                  title: Text('${user['prenom']} ${user['nom']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(user['email'] ?? ''),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.edit, color: Colors.orange.shade700),
                        onPressed: () => navigateToForm(user: user),
                      ),
                      IconButton(
                        icon: Icon(Icons.delete, color: Colors.red.shade700),
                        onPressed: () => _deleteUser(user['id'], '${user['prenom']} ${user['nom']}'),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

// --- WIDGET POUR L'ONGLET DE GESTION DES ÉCOLES (REFAIT AVEC API) ---
class _SchoolsManagementTab extends StatefulWidget {
  final String role;
  const _SchoolsManagementTab({super.key, required this.role});

  @override
  State<_SchoolsManagementTab> createState() => _SchoolsManagementTabState();
}

class _SchoolsManagementTabState extends State<_SchoolsManagementTab> {
  late Future<List<dynamic>> _schoolsFuture;
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _loadSchools();
  }

  void _loadSchools() {
    setState(() {
      _schoolsFuture = _apiService.getEcoles();
    });
  }

  void navigateToSchoolForm({Map<String, dynamic>? school}) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => SchoolFormPage(school: school),
      ),
    );

    if (result == true) {
      _loadSchools();
    }
  }

  void _deleteSchool(String schoolId, String schoolName) {
     showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: Text('Êtes-vous sûr de vouloir supprimer $schoolName?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () async {
              try {
                await _apiService.deleteEcole(schoolId);
                Navigator.of(context).pop();
                _loadSchools();
              } catch (e) {
                 Navigator.of(context).pop();
                 ScaffoldMessenger.of(context).showSnackBar(
                   SnackBar(content: Text('Erreur: ${e.toString()}'))
                 );
              }
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
    return FutureBuilder<List<dynamic>>(
      future: _schoolsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Erreur: ${snapshot.error}'));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('Aucune école trouvée.'));
        }

        final schools = snapshot.data!;
        return RefreshIndicator(
          onRefresh: () async => _loadSchools(),
          child: ListView.builder(
            itemCount: schools.length,
            itemBuilder: (context, index) {
              final school = schools[index] as Map<String, dynamic>;
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.green.shade100,
                    child: const Icon(Icons.school, color: Colors.green),
                  ),
                  title: Text(school['nom'], style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(school['ville']),
                      const SizedBox(height: 4),
                      Text(
                        'Budget: ${(school['budgetEuros'] as num? ?? 0).toStringAsFixed(2)} €',
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
                        onPressed: () => navigateToSchoolForm(school: school),
                      ),
                      IconButton(
                        icon: Icon(Icons.delete, color: Colors.red.shade700),
                        onPressed: () => _deleteSchool(school['id'], school['nom']),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}