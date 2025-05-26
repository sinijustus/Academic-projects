// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class EditRecruiterProfileScreen extends StatefulWidget {
  final Map<String, dynamic> recruiterData;

  const EditRecruiterProfileScreen(this.recruiterData, {super.key});

  @override
  State<EditRecruiterProfileScreen> createState() => _EditRecruiterProfileScreenState();
}

class _EditRecruiterProfileScreenState extends State<EditRecruiterProfileScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _companyNameController;
  late TextEditingController _industryController;
  late TextEditingController _companySizeController;
  late TextEditingController _websiteController;
  late TextEditingController _phoneController;

  @override
  void initState() {
    super.initState();
    _companyNameController = TextEditingController(text: widget.recruiterData['companyName']);
    _industryController = TextEditingController(text: widget.recruiterData['industry']);
    _companySizeController = TextEditingController(text: widget.recruiterData['companySize']);
    _websiteController = TextEditingController(text: widget.recruiterData['website']);
    _phoneController = TextEditingController(text: widget.recruiterData['phone']);
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      String? recruiterId = _auth.currentUser?.uid;
      if (recruiterId != null) {
        await _firestore.collection('recruiters').doc(recruiterId).update({
          'companyName': _companyNameController.text,
          'industry': _industryController.text,
          'companySize': _companySizeController.text,
          'website': _websiteController.text,
          'phone': _phoneController.text,
        });

        // ignore: duplicate_ignore
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully!')),
        );

        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating profile: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profile')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _companyNameController,
                decoration: const InputDecoration(labelText: 'Company Name'),
                validator: (value) => value!.isEmpty ? 'Enter company name' : null,
              ),
              TextFormField(
                controller: _industryController,
                decoration: const InputDecoration(labelText: 'Industry'),
                validator: (value) => value!.isEmpty ? 'Enter industry' : null,
              ),
              TextFormField(
                controller: _companySizeController,
                decoration: const InputDecoration(labelText: 'Company Size'),
                validator: (value) => value!.isEmpty ? 'Enter company size' : null,
              ),
              TextFormField(
                controller: _websiteController,
                decoration: const InputDecoration(labelText: 'Website'),
                validator: (value) => value!.isEmpty ? 'Enter website' : null,
              ),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(labelText: 'Phone'),
                validator: (value) => value!.isEmpty ? 'Enter phone number' : null,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _updateProfile,
                child: const Text('Save Changes'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
