import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:skillaura/screens/user_profile_screen.dart';
import 'package:skillaura/screens/login_screen.dart';
import 'package:url_launcher/url_launcher.dart';

final FirebaseAuth _auth = FirebaseAuth.instance;
final FirebaseFirestore _firestore = FirebaseFirestore.instance;

class WomenDashboard extends StatefulWidget {
  const WomenDashboard({super.key});

  @override
  State<WomenDashboard> createState() => _WomenDashboardState();
}

class _WomenDashboardState extends State<WomenDashboard> {
  List<Map<String, dynamic>> recommendedJobs = [];
  List<Map<String, dynamic>> recommendedVideos = [];
  List<Map<String, dynamic>> governmentSchemes = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchRecommendations();
  }
  

  Future<void> fetchRecommendations() async {
    setState(() => isLoading = true);
    try {
      User? user = _auth.currentUser;
      if (user == null) return;

      final userDoc =
          await _firestore.collection('women_users').doc(user.uid).get();
      if (!userDoc.exists) return;
      final userData = userDoc.data();
      if (userData == null) return;

      List<String> userSkills = (userData['skills'] as List<dynamic>?)
              ?.cast<String>()
              .take(10)
              .toList() ??
          ['General Skills'];
      String userLocation = userData['location']?.toString() ?? 'Unknown';

      var jobDocs = <QueryDocumentSnapshot>[];

      final allJobs = await _firestore.collection('jobs').get();
      for (var doc in allJobs.docs) {
        final jobData = doc.data();
        final jobLocation =
            jobData['location']?.toString().toLowerCase() ?? '';
        final jobSkills =
            (jobData['skills_required'] as List<dynamic>?)?.cast<String>() ??
                [];

        final locationMatch =
            jobLocation.toLowerCase() == userLocation.toLowerCase();
        final skillsMatch =
            userSkills.any((skill) => jobSkills.contains(skill));

        if (locationMatch && skillsMatch) {
          jobDocs.add(doc);
        }
      }

      if (jobDocs.isEmpty) {
        recommendedJobs = [];
      }

      recommendedJobs = jobDocs.map<Map<String, dynamic>>((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['jobId'] = doc.id;
        return data;
      }).toList();

      final videoQuery = await _firestore
          .collection('recommended_videos')
          .where('category', whereIn: userSkills)
          .get();
      recommendedVideos = videoQuery.docs.map((doc) => doc.data()).toList();

      final schemeQuery =
          await _firestore.collection('government_schemes').get();
      governmentSchemes = schemeQuery.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      debugPrint("❌ Error fetching data: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }
Future<void> applyForJob(Map<String, dynamic> job) async {
  User? user = _auth.currentUser;
  if (user == null) return;

  try {
    // Check if already applied
    final existingApplications = await _firestore
        .collection('applications')
        .where('jobId', isEqualTo: job['jobId'])
        .where('userId', isEqualTo: user.uid)
        .get();

    if (existingApplications.docs.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Already applied for this job.')),
      );
      return;
    }

    final userDoc =
        await _firestore.collection('women_users').doc(user.uid).get();
    final userData = userDoc.data() ?? {};

    await _firestore.collection('applications').add({
      'jobId': job['jobId'],
      'jobTitle': job['title'],
      'recruiterId': job['recruiterId'],
      'userId': user.uid,
      'userName': userData['name'] ?? '',
      'userPhone': userData['phone'] ?? '',
       'appliedAt': DateTime.now().toIso8601String(),
      'status': 'pending',
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Application submitted successfully!')),
    );
    setState(() {}); // Refresh UI
  } catch (e) {
    debugPrint("❌ Failed to apply: $e");
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Failed to apply: $e")),
    );
  }
}

  void _logout() async {
    await _auth.signOut();
    Navigator.pushReplacement(
        context, MaterialPageRoute(builder: (_) => const LoginScreen()));
  }

  String getYouTubeThumbnail(String videoUrl) {
    Uri uri = Uri.parse(videoUrl);
    String? videoId;

    if (uri.host.contains('youtube.com')) {
      videoId = uri.queryParameters['v'];
    } else if (uri.host.contains('youtu.be')) {
      videoId = uri.pathSegments.isNotEmpty ? uri.pathSegments[0] : null;
    }

    return videoId != null
        ? "https://img.youtube.com/vi/$videoId/0.jpg"
        : "assets/default_thumbnail.jpg";
  }

  void _launchURL(String url) async {
    if (url.isEmpty) return;
    Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      debugPrint('Could not launch $url');
    }
  }

  Future<bool> _hasAlreadyApplied(String jobId) async {
    final user = _auth.currentUser;
    if (user == null) return false;

    final doc = await _firestore
        .collection('applications')
        .doc('${user.uid}_$jobId')
        .get();

    return doc.exists;
  }

  Future<void> _applyForJob(BuildContext context, Map<String, dynamic> job) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final jobId = job['jobId'];
    final docRef =
        _firestore.collection('applications').doc('${user.uid}_$jobId');
    await docRef.set({
      'userId': user.uid,
      'jobId': jobId,
      'appliedAt': FieldValue.serverTimestamp(),
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Applied successfully!")),
    );
     setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: const Text(
          "SkillAura",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color.fromARGB(255, 44, 118, 192),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined,
                color: Color.fromARGB(255, 44, 118, 192)),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.person_outlined,
                color: Color.fromARGB(255, 44, 118, 192)),
            onPressed: () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const UserProfileScreen()));
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout_outlined,
                color: Color.fromARGB(255, 44, 118, 192)),
            onPressed: _logout,
          ),
        ],
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.purple)))
          : RefreshIndicator(
              color: Colors.purple,
              onRefresh: fetchRecommendations,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildWelcomeHeader(),
                    _buildSectionHeader("Jobs For You"),
                    _buildJobsCarousel(),
                    _buildSectionHeader("Recommended Videos"),
                    _buildVideosGrid(),
                    _buildSectionHeader("Government Schemes"),
                    _buildSchemesList(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildWelcomeHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Welcome /സ്വാഗതം!",
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text("Discover opportunities tailored for you",
              style: TextStyle(fontSize: 16, color: Colors.grey[600])),
          const SizedBox(height: 20),
          TextField(
            decoration: InputDecoration(
              hintText: "Search opportunities...",
              prefixIcon: const Icon(Icons.search,
                  color: Color.fromARGB(255, 32, 65, 150)),
              filled: true,
              fillColor: Colors.grey[100],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 30, 20, 15),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title,
              style:
                  const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          TextButton(
            onPressed: () {},
            child: const Text("See All",
                style: TextStyle(color: Colors.blue)),
          ),
        ],
      ),
    );
  }

  Widget _buildJobsCarousel() {
    if (recommendedJobs.isEmpty) {
      return _buildEmptyState("No jobs available for your profile.");
    }

    return SizedBox(
      height: 220,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: recommendedJobs.length,
        itemBuilder: (context, index) {
          final job = recommendedJobs[index];
          return _buildJobCard(job);
        },
      ),
    );
  }

  Widget _buildJobCard(Map<String, dynamic> job) {
  // Ensure jobId exists
  final String? jobId = job['jobId'];
  if (jobId == null) {
    return const SizedBox.shrink(); 

  return FutureBuilder<bool>(
    future: _hasAlreadyApplied(jobId),
    builder: (context, snapshot) {
      final alreadyApplied = snapshot.data ?? false;

      return Container(
        width: 280,
        margin: const EdgeInsets.only(right: 16, bottom: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                job['title'] ?? '',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Text(
                job['description'] ?? 'No description available',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.black87),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.location_on, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      job['location'] ?? 'Unknown',
                      style: const TextStyle(fontSize: 14, color: Colors.grey),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: alreadyApplied
                    ? null
                    : () {
                        debugPrint("🚀 Apply button pressed for jobId: $jobId");
                        _applyForJob(context, job);
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: alreadyApplied
                      ? const Color.fromARGB(255, 70, 67, 67)
                      : const Color.fromARGB(255, 16, 42, 89),
                ),
                child: Text(alreadyApplied ? 'Applied' : 'Apply Now'),
              ),
            ],
          ),
        ),
      );
    },
  );
}



  Widget _buildVideosGrid() {
    if (recommendedVideos.isEmpty) {
      return _buildEmptyState("No recommended videos.");
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        itemCount: recommendedVideos.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2, mainAxisSpacing: 16, crossAxisSpacing: 16),
        itemBuilder: (context, index) {
          final video = recommendedVideos[index];
          return GestureDetector(
            onTap: () => _launchURL(video['url']),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Image.network(
                  getYouTubeThumbnail(video['url']),
                  height: 100,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
                const SizedBox(height: 6),
                Text(video['title'] ?? '',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSchemesList() {
    if (governmentSchemes.isEmpty) {
      return _buildEmptyState("No government schemes found.");
    }

    return ListView.builder(
      itemCount: governmentSchemes.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemBuilder: (context, index) {
        final scheme = governmentSchemes[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            title: Text(scheme['title'] ?? ''),
            subtitle: Text(scheme['description'] ?? ''),
            trailing: IconButton(
              icon: const Icon(Icons.launch),
              onPressed: () => _launchURL(scheme['link'] ?? ''),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(String message) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Center(
        child: Text(message,
            style: const TextStyle(color: Colors.grey, fontSize: 16)),
      ),
    );
  }
}

// ignore: unused_element
Future<bool> _hasAlreadyApplied(String jobId) async {
  final user = _auth.currentUser;
  if (user == null) return false;

  final doc = await _firestore
      .collection('job_applications')
      .doc('${user.uid}_$jobId')
      .get();

  return doc.exists;
}
