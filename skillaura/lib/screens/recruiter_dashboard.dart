import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'recruiter_profile.dart';
import 'post_job.dart';
import 'login_screen.dart';
import 'applicant_list_screen.dart';

class RecruiterDashboard extends StatefulWidget {
  const RecruiterDashboard({super.key});

  @override
  State<RecruiterDashboard> createState() => _RecruiterDashboardState();
}

class _RecruiterDashboardState extends State<RecruiterDashboard> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? recruiter;
  Map<String, dynamic>? recruiterData;

  bool _isLoading = true;
  int jobCount = 0;
  int applicationCount = 0;
  List<Map<String, dynamic>> jobList = [];

  @override
  void initState() {
    super.initState();
    _initializeDashboard();
  }

  Future<void> _initializeDashboard() async {
    recruiter = _auth.currentUser;
    if (recruiter == null) return;

    await Future.wait([
      _getRecruiterData(),
      _fetchRecruiterJobs(),
      _fetchApplicationCount(),
    ]);

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _getRecruiterData() async {
    try {
      final doc = await _firestore.collection('recruiters').doc(recruiter!.uid).get();
      if (doc.exists) {
        recruiterData = doc.data();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading profile: $e')),
      );
    }
  }

  Future<void> _fetchRecruiterJobs() async {
    try {
      final jobsSnapshot = await _firestore
          .collection('jobs')
          .where('recruiterId', isEqualTo: recruiter!.uid)
          .get();

      final fetchedJobs = jobsSnapshot.docs
          .map((doc) => {'id': doc.id, ...doc.data()})
          .toList();

      setState(() {
        jobList = fetchedJobs;
        jobCount = fetchedJobs.length;
      });
    } catch (e) {
      debugPrint('Error fetching jobs: $e');
    }
  }

  Future<void> _fetchApplicationCount() async {
    try {
      final jobsSnapshot = await _firestore
          .collection('jobs')
          .where('recruiterId', isEqualTo: recruiter!.uid)
          .get();

      final jobIds = jobsSnapshot.docs.map((doc) => doc.id).toList();
      int totalApplications = 0;

      for (String jobId in jobIds) {
        final appSnapshot = await _firestore
            .collection('applications')
            .where('jobId', isEqualTo: jobId)
            .get();
        totalApplications += appSnapshot.docs.length;
      }

      setState(() => applicationCount = totalApplications);
    } catch (e) {
      debugPrint('Error fetching application count: $e');
    }
  }

  Future<void> _deleteJob(String jobId) async {
    try {
      await _firestore.collection('jobs').doc(jobId).delete();
      setState(() {
        jobList.removeWhere((job) => job['id'] == jobId);
        jobCount--;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Job deleted successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete job: $e')),
      );
    }
  }

  void _showJobDetailDialog(Map<String, dynamic> job) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(job['title'] ?? 'Job Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (job['description'] != null) Text("Description: ${job['description']}"),
            if (job['location'] != null) Text("Location: ${job['location']}"),
            if (job['salary'] != null) Text("Salary: ${job['salary']}"),
            if (job['type'] != null) Text("Type: ${job['type']}"),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          UserAccountsDrawerHeader(
            accountName: Text(recruiterData?['organization'] ?? ''),
            accountEmail: Text(recruiterData?['email'] ?? ''),
            currentAccountPicture: const CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(Icons.business, size: 40, color: Colors.blue),
            ),
            decoration: const BoxDecoration(color: Colors.blue),
          ),
          ListTile(
            leading: const Icon(Icons.dashboard),
            title: const Text('Dashboard'),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('Profile'),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const RecruiterProfileScreen()),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.post_add),
            title: const Text('Post a Job'),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PostJobScreen()),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Logout'),
            onTap: () async {
              await _auth.signOut();
              if (mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardCard(String title, int count) {
    return Card(
      elevation: 4,
      child: Container(
        padding: const EdgeInsets.all(16),
        width: 120,
        child: Column(
          children: [
            Text('$count', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 14)),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Quick Actions', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        ElevatedButton.icon(
          icon: const Icon(Icons.post_add),
          label: const Text('Post a Job'),
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const PostJobScreen()),
          ),
        ),
      ],
    );
  }

  Widget _buildPostedJobs() {
    if (jobList.isEmpty) {
      return const Center(child: Text('No jobs posted yet.'));
    }

    return ListView.builder(
      itemCount: jobList.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (context, index) {
        final job = jobList[index];
        return Card(
          elevation: 4,
          margin: const EdgeInsets.symmetric(vertical: 8),
          child: ListTile(
            onTap: () => _showJobDetailDialog(job),
            title: Text(job['title'] ?? 'No title'),
            subtitle: Text(job['location'] ?? 'No location'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.list_alt),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ApplicantListScreen(
                          jobId: job['id'],
                          jobTitle: job['title'],
                        ),
                      ),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _deleteJob(job['id']),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRecruiterProfile() {
    return Column(
      children: [
        const CircleAvatar(radius: 40, backgroundColor: Colors.blue),
        const SizedBox(height: 10),
        Text(
          recruiterData?['organization'] ?? '',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        Text(
          recruiterData?['email'] ?? '',
          style: const TextStyle(fontSize: 14, color: Colors.grey),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Recruiter Dashboard'), backgroundColor: Colors.blue),
      drawer: _buildDrawer(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildRecruiterProfile(),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildDashboardCard('Posted Jobs', jobCount),
                      _buildDashboardCard('Applications', applicationCount),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _buildQuickActions(),
                  const SizedBox(height: 20),
                  const Text('Posted Jobs', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  _buildPostedJobs(),
                ],
              ),
            ),
    );
  }
}
