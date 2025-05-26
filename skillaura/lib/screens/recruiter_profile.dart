// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'edit_recruiter_profile.dart'; // Import the Edit Screen

class RecruiterProfileScreen extends StatefulWidget {
  const RecruiterProfileScreen({super.key});

  @override
  State<RecruiterProfileScreen> createState() => _RecruiterProfileScreenState();
}

class _RecruiterProfileScreenState extends State<RecruiterProfileScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  User? recruiter;
  Map<String, dynamic>? recruiterData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _getRecruiterData();
  }

  Future<void> _getRecruiterData() async {
    try {
      recruiter = _auth.currentUser;
      if (recruiter != null) {
        DocumentSnapshot doc =
            await _firestore.collection('recruiters').doc(recruiter!.uid).get();
        if (doc.exists) {
          setState(() {
            recruiterData = doc.data() as Map<String, dynamic>?;
            _isLoading = false;
          });
        } else {
          setState(() => _isLoading = false);
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading profile: $e')),
      );
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recruiter Profile'),
        centerTitle: true,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : recruiterData == null
              ? const Center(child: Text('No Profile Data Found'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      // Profile Header
                      Container(
                        // ignore: deprecated_member_use
                        color: Theme.of(context).primaryColor.withOpacity(0.1),
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            const CircleAvatar(
                              radius: 50,
                              backgroundImage:
                                  AssetImage('assets/images/profile.png'),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              recruiterData?['name'] ?? 'Name Not Set',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              recruiterData?['organization'] ??
                                  'Organization Not Set',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              recruiterData?['address'] ?? 'Address Not Set',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Profile Details
                      _buildInfoSection('Company Information', [
                        _buildInfoTile(
                            'Industry', recruiterData?['industry'] ?? 'Not Set'),
                        _buildInfoTile(
                            'Designation', recruiterData?['designation'] ?? 'Not Set'),
                        _buildInfoTile('Rural Hiring',
                            recruiterData?['acceptsRuralHiring'] == true ? 'Yes' : 'No'),
                        _buildInfoTile('Provides Training',
                            recruiterData?['providesTraining'] == true ? 'Yes' : 'No'),
                      ]),

                      const SizedBox(height: 20),

                      _buildInfoSection('Contact Details', [
                        _buildInfoTile(
                            'Email', recruiterData?['email'] ?? 'Not Set'),
                        _buildInfoTile(
                            'Phone', recruiterData?['phone'] ?? 'Not Set'),
                      ]),

                      const SizedBox(height: 30),

                      // Edit Profile Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    EditRecruiterProfileScreen(recruiterData!),
                              ),
                            );
                            _getRecruiterData(); // Refresh profile after editing
                          },
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.all(16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text('Edit Profile'),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildInfoSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ...children,
      ],
    );
  }

  Widget _buildInfoTile(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 16,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
