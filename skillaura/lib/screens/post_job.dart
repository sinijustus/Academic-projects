// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PostJobScreen extends StatefulWidget {
  const PostJobScreen({super.key});

  @override
  State<PostJobScreen> createState() => _PostJobScreenState();
}

class _PostJobScreenState extends State<PostJobScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _formKey = GlobalKey<FormState>();

  String jobTitle = '';
  String jobDescription = '';
  String jobLocation = '';
  String jobCategory = '';
  List<String> selectedSkills = [];

  bool isPosting = false;

  final List<String> jobCategories = [
    'Handicrafts & Home Jobs',
    'Work-from-Home Jobs',
    'Government & NGO Jobs',
    'Field Jobs',
    'Other',
  ];

  final List<String> availableSkills = [
    'Tailoring',
    'Cooking',
    'Sewing',
    'Handcrafts',
    'Embroidery',
    'Jewelry Making',
    'Marketing',
    'Data Entry',
    'Customer Support',
    'Handicrafts',
    'Painting',
  ];

  Future<void> _postJob() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      setState(() => isPosting = true);

      User? recruiter = _auth.currentUser;
      if (recruiter != null) {
        try {
          await _firestore.collection('jobs').add({
            'recruiterId': recruiter.uid,
            'title': jobTitle,
            'description': jobDescription,
            'location': jobLocation,
            'category': jobCategory,
            'skills_required': selectedSkills,
            'postedAt': Timestamp.now(),
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Job posted successfully!')),
          );

          Navigator.pop(context);
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error posting job: $e')),
          );
        }
      }

      setState(() => isPosting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Post a Job')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Job Title'),
                  onSaved: (value) => jobTitle = value!.trim(),
                  validator: (value) =>
                      value!.isEmpty ? 'Enter job title' : null,
                ),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Job Description'),
                  maxLines: 3,
                  onSaved: (value) => jobDescription = value!.trim(),
                  validator: (value) =>
                      value!.isEmpty ? 'Enter job description' : null,
                ),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Location'),
                  onSaved: (value) => jobLocation = value!.trim(),
                  validator: (value) =>
                      value!.isEmpty ? 'Enter job location' : null,
                ),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: 'Category'),
                  value: jobCategories.contains(jobCategory) ? jobCategory : null,
                  items: jobCategories.map((category) {
                    return DropdownMenuItem(
                        value: category, child: Text(category));
                  }).toList(),
                  onChanged: (value) => setState(() => jobCategory = value!),
                  validator: (value) =>
                      value == null ? 'Please select a category' : null,
                ),
                const SizedBox(height: 20),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: 'Select Skills'),
                  items: availableSkills.map((skill) {
                    return DropdownMenuItem(
                        value: skill, child: Text(skill));
                  }).toList(),
                  onChanged: (value) {
                    if (value != null && !selectedSkills.contains(value)) {
                      setState(() {
                        selectedSkills.add(value);
                      });
                    }
                  },
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8.0,
                  children: selectedSkills.map((skill) {
                    return Chip(
                      label: Text(skill),
                      onDeleted: () {
                        setState(() {
                          selectedSkills.remove(skill);
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),
                isPosting
                    ? const CircularProgressIndicator()
                    : ElevatedButton(
                        onPressed: _postJob,
                        child: const Text('Post Job'),
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
