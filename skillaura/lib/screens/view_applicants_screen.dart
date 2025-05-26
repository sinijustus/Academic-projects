import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ViewApplicantsScreen extends StatelessWidget {
  final String jobId;

  const ViewApplicantsScreen({super.key, required this.jobId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Applicants")),
      body: FutureBuilder<QuerySnapshot>(
        future: FirebaseFirestore.instance
            .collection('applications')
            .where('jobId', isEqualTo: jobId)
            .get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No applicants yet.'));
          }

          return ListView(
            children: snapshot.data!.docs.map((doc) {
              var data = doc.data() as Map<String, dynamic>;
              return Card(
                child: ListTile(
                  title: Text(data['applicantName'] ?? 'No name'),
                  subtitle: Text("Location: ${data['location'] ?? 'N/A'}\nAge: ${data['age'] ?? 'N/A'}"),
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}
