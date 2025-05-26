import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import 'login_screen.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _selectedIndex = 0;

  final String masterVideoDocId = 'skill-vds';
  final String subCollectionName = 'recommended_videos';

  void logout() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  Future<void> deleteUser(String id) async {
    await FirebaseFirestore.instance.collection('women_users').doc(id).delete();
  }

  Future<void> deleteRecruiter(String id) async {
    await FirebaseFirestore.instance.collection('recruiters').doc(id).delete();
  }

  Future<void> approveRecruiter(String id) async {
    await FirebaseFirestore.instance.collection('recruiters').doc(id).update({'approved': true});
  }

  Future<void> rejectRecruiter(String id) async {
    await deleteRecruiter(id);
  }

  void _addVideoDialog() {
    final titleController = TextEditingController();
    final categoryController = TextEditingController();
    final descriptionController = TextEditingController();
    final urlController = TextEditingController();
    final String uuid = const Uuid().v4();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add New Video'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(controller: titleController, decoration: const InputDecoration(labelText: 'Title')),
                TextField(controller: categoryController, decoration: const InputDecoration(labelText: 'Category')),
                TextField(controller: descriptionController, decoration: const InputDecoration(labelText: 'Description')),
                TextField(controller: urlController, decoration: const InputDecoration(labelText: 'URL')),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
            TextButton(
              onPressed: () async {
                await FirebaseFirestore.instance
                    .collection('recommended_videos')
                    .doc(masterVideoDocId)
                    .collection(subCollectionName)
                    .doc(uuid)
                    .set({
                  'Title': titleController.text,
                  'category': categoryController.text,
                  'description': descriptionController.text,
                  'url': urlController.text,
                });
                Navigator.of(context).pop();
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  void _addSchemeDialog() {
    final descriptionController = TextEditingController();
    final applyLinkController = TextEditingController();
    final String uuid = const Uuid().v4();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Government Scheme'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(controller: descriptionController, decoration: const InputDecoration(labelText: 'Description')),
                TextField(controller: applyLinkController, decoration: const InputDecoration(labelText: 'Apply Link')),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
            TextButton(
              onPressed: () async {
                await FirebaseFirestore.instance.collection('government_schemes').doc(uuid).set({
                  'description': descriptionController.text,
                  'link': applyLinkController.text,
                });
                Navigator.of(context).pop();
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_getTitle()),
        backgroundColor: Theme.of(context).primaryColor,
        actions: [
          IconButton(icon: const Icon(Icons.logout), onPressed: logout, tooltip: 'Logout'),
        ],
      ),
      body: _getBody(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Theme.of(context).primaryColor,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Users'),
          BottomNavigationBarItem(icon: Icon(Icons.business), label: 'Recruiters'),
          BottomNavigationBarItem(icon: Icon(Icons.video_library), label: 'Videos'),
          BottomNavigationBarItem(icon: Icon(Icons.account_balance), label: 'Schemes'),
        ],
      ),
      floatingActionButton: _selectedIndex == 2
          ? FloatingActionButton(onPressed: _addVideoDialog, tooltip: 'Add Video', child: const Icon(Icons.add))
          : _selectedIndex == 3
              ? FloatingActionButton(onPressed: _addSchemeDialog, tooltip: 'Add Scheme', child: const Icon(Icons.add))
              : null,
    );
  }

  String _getTitle() {
    switch (_selectedIndex) {
      case 0:
        return 'Manage Users';
      case 1:
        return 'Manage Recruiters';
      case 2:
        return 'Recommended Videos';
      case 3:
        return 'Government Schemes';
      default:
        return 'Admin Dashboard';
    }
  }

  Widget _getBody() {
    switch (_selectedIndex) {
      case 0:
        return _buildListView('women_users', 'name', 'email', deleteUser);
      case 1:
        return _buildListViewWithActions('recruiters', 'name', 'email', approveRecruiter, rejectRecruiter);
      case 2:
        return _buildCoursesSection();
      case 3:
        return _buildSchemesSection();
      default:
        return const SizedBox();
    }
  }

  Widget _buildCoursesSection() {
    return StreamBuilder(
      stream: FirebaseFirestore.instance
          .collection('recommended_videos')
          .doc(masterVideoDocId)
          .collection(subCollectionName)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No videos found'));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final doc = snapshot.data!.docs[index];
            return Card(
              elevation: 2,
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: const CircleAvatar(child: Icon(Icons.video_library)),
                title: Text(doc['Title'] ?? 'No Title'),
                subtitle: Text(doc['category'] ?? 'No Category'),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _showDeleteConfirmationDialog(() async {
                    await FirebaseFirestore.instance
                        .collection('recommended_videos')
                        .doc(masterVideoDocId)
                        .collection(subCollectionName)
                        .doc(doc.id)
                        .delete();
                  }),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSchemesSection() {
    return StreamBuilder(
      stream: FirebaseFirestore.instance.collection('government_schemes').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No schemes found'));
        }
        final docs = snapshot.data!.docs;
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final doc = docs[index];
            return Card(
              elevation: 2,
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: const CircleAvatar(child: Icon(Icons.account_balance)),
                title: Text(doc['description'] ?? 'No Description'),
                subtitle: Text(doc['link'] ?? ''),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _showDeleteConfirmationDialog(() async {
                    await FirebaseFirestore.instance.collection('government_schemes').doc(doc.id).delete();
                  }),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildListView(String collection, String titleField, String subtitleField, Function(String) deleteFunc) {
    return StreamBuilder(
      stream: FirebaseFirestore.instance.collection(collection).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No data found'));
        }
        final docs = snapshot.data!.docs;
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final doc = docs[index];
            return Card(
              elevation: 2,
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: const CircleAvatar(child: Icon(Icons.person)),
                title: Text(doc[titleField] ?? 'Unnamed'),
                subtitle: Text(doc[subtitleField] ?? ''),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _showDeleteConfirmationDialog(() => deleteFunc(doc.id)),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildListViewWithActions(
    String collection,
    String titleField,
    String subtitleField,
    Function(String) approveFunc,
    Function(String) rejectFunc,
  ) {
    return StreamBuilder(
      stream: FirebaseFirestore.instance.collection(collection).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No recruiters found'));
        }
        final docs = snapshot.data!.docs;
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final doc = docs[index];
            return Card(
              elevation: 2,
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: const CircleAvatar(child: Icon(Icons.business)),
                title: Text(doc[titleField] ?? 'Unnamed'),
                subtitle: Text(doc[subtitleField] ?? ''),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(icon: const Icon(Icons.check_circle, color: Colors.green), onPressed: () => approveFunc(doc.id)),
                    IconButton(icon: const Icon(Icons.cancel, color: Colors.red), onPressed: () => _showDeleteConfirmationDialog(() => rejectFunc(doc.id))),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _showDeleteConfirmationDialog(VoidCallback onConfirm) async {
    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Confirm Delete'),
          content: const Text('Are you sure you want to delete this item?'),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
            TextButton(
              onPressed: () {
                onConfirm();
                Navigator.of(context).pop();
              },
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }
}
