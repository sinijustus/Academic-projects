import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class ApplicantListScreen extends StatelessWidget {
  final String jobId;
  final String jobTitle;

  const ApplicantListScreen({super.key, required this.jobId, required this.jobTitle});

  Future<List<Map<String, dynamic>>> fetchApplicants() async {
    final firestore = FirebaseFirestore.instance;

    final applicationDocs = await firestore
        .collection('applications')
        .where('jobId', isEqualTo: jobId)
        .get();

    List<Map<String, dynamic>> applicants = [];

    for (final doc in applicationDocs.docs) {
      final data = doc.data();
      final userId = data['userId'];

      // Fetch user data from the 'women_users' collection
      final userDoc = await firestore.collection('women_users').doc(userId).get();

      if (userDoc.exists) {
        applicants.add({
          'name': userDoc.data()?['name'] ?? 'N/A',
          'phone': userDoc.data()?['phone'] ?? 'N/A',
          'location': userDoc.data()?['location'] ?? 'N/A',
        });
      }
    }

    return applicants;
  }

  Future<void> _launchPhone(String phone) async {
    final Uri phoneUri = Uri(scheme: 'tel', path: phone);
    if (await canLaunch(phoneUri.toString())) {
      await launch(phoneUri.toString());
    } else {
      throw 'Could not launch $phone';
    }
  }

  Future<void> _launchEmail(String email) async {
    final Uri emailUri = Uri(scheme: 'mailto', path: email);
    if (await canLaunch(emailUri.toString())) {
      await launch(emailUri.toString());
    } else {
      throw 'Could not send email to $email';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Applicants for $jobTitle'), backgroundColor: Colors.blue),
      body: FutureBuilder<List<Map<String, dynamic>>>( // Fetch applicants data
        future: fetchApplicants(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error fetching applicants: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No applicants yet.'));
          }

          final applicants = snapshot.data!;
          return ListView.builder(
            itemCount: applicants.length,
            itemBuilder: (context, index) {
              final applicant = applicants[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: const Icon(Icons.person),
                  title: Text(applicant['name']),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Phone: ${applicant['phone']}'),
                      Text('Location: ${applicant['location']}'),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.call),
                        onPressed: () {
                          _launchPhone(applicant['phone']);
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.email),
                        onPressed: () {
                          _launchEmail(applicant['phone']); // Assuming you have an email field in your data
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
