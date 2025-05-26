import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RecruiterSignupForm extends StatefulWidget {
  const RecruiterSignupForm({super.key});

  @override
  State<RecruiterSignupForm> createState() => _RecruiterSignupFormState();
}

class _RecruiterSignupFormState extends State<RecruiterSignupForm> {
  final _formKey = GlobalKey<FormState>();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final TextEditingController _organizationController = TextEditingController();
  final TextEditingController _designationController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  String? _selectedIndustry;
  String? _selectedLanguage;
  bool _acceptsRuralHiring = false;
  bool _providesTraining = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _organizationController.dispose();
    _designationController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _registerRecruiter() async {
    if (_formKey.currentState!.validate()) {
      try {
        // Create user with email and password
        UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        // Store recruiter data in Firestore
        await _firestore.collection('recruiters').doc(userCredential.user!.uid).set({
          'name': _nameController.text.trim(),
          'email': _emailController.text.trim(),
          'phone': _phoneController.text.trim(),
          'organization': _organizationController.text.trim(),
          'designation': _designationController.text.trim(),
          'industry': _selectedIndustry,
          'address': _addressController.text.trim(),
          'language': _selectedLanguage,
          'acceptsRuralHiring': _acceptsRuralHiring,
          'providesTraining': _providesTraining,
          'timestamp': FieldValue.serverTimestamp(),
        });

        // Navigate back to the login screen
        Navigator.pop(context); // Pops the current screen (register screen), going back to the previous screen (login screen)

      } catch (e) {
        _showErrorDialog(e.toString());
      }
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Registration Failed'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Recruiter Registration')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildTextField(_nameController, 'Full Name', Icons.person),
              _buildTextField(_emailController, 'Email', Icons.email, isEmail: true),
              _buildTextField(_phoneController, 'Phone Number', Icons.phone, isPhone: true),
              _buildTextField(_organizationController, 'Organization', Icons.business),
              _buildTextField(_designationController, 'Designation', Icons.work),
              _buildDropdownField('Industry Type', ['Agriculture', 'Handicrafts', 'IT', 'Healthcare', 'Education','Textiles','Retail & Small Business'], (value) => setState(() => _selectedIndustry = value)),
              _buildTextField(_addressController, 'Address', Icons.location_on),
              _buildDropdownField('Preferred Language', ['English', 'Malayalam'], (value) => setState(() => _selectedLanguage = value)),
              _buildPasswordField(_passwordController, 'Password'),
              _buildPasswordField(_confirmPasswordController, 'Confirm Password', isConfirm: true),
              _buildCheckbox('Accepts Rural Hiring', _acceptsRuralHiring, (value) => setState(() => _acceptsRuralHiring = value!)),
              _buildCheckbox('Provides Skill Training', _providesTraining, (value) => setState(() => _providesTraining = value!)),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _registerRecruiter,
                child: const Text('Register as Recruiter'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper method for normal text fields
  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {bool isEmail = false, bool isPhone = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        keyboardType: isEmail ? TextInputType.emailAddress : isPhone ? TextInputType.phone : TextInputType.text,
        decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon), border: OutlineInputBorder()),
        validator: (value) {
          if (value == null || value.isEmpty) return 'Please enter $label';
          if (isEmail && !RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zAZ0-9.-]+\.[a-zA-Z]{2,}$').hasMatch(value)) return 'Enter a valid email';
          if (isPhone && !RegExp(r'^[0-9]{10}$').hasMatch(value)) return 'Enter a valid 10-digit phone number';
          return null;
        },
      ),
    );
  }

  // Helper method for password fields
  Widget _buildPasswordField(TextEditingController controller, String label, {bool isConfirm = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        obscureText: true,
        decoration: InputDecoration(labelText: label, prefixIcon: const Icon(Icons.lock), border: OutlineInputBorder()),
        validator: (value) {
          if (value == null || value.isEmpty) return 'Please enter $label';
          if (isConfirm && value != _passwordController.text) return 'Passwords do not match';
          return null;
        },
      ),
    );
  }

  // Helper method for dropdown fields
  Widget _buildDropdownField(String label, List<String> items, ValueChanged<String?> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: DropdownButtonFormField<String>(
        decoration: InputDecoration(labelText: label, border: OutlineInputBorder()),
        items: items.map((item) => DropdownMenuItem(value: item, child: Text(item))).toList(),
        onChanged: onChanged,
        validator: (value) => value == null ? 'Please select $label' : null,
      ),
    );
  }

  // Helper method for checkboxes
  Widget _buildCheckbox(String label, bool value, ValueChanged<bool?> onChanged) {
    return CheckboxListTile(
      title: Text(label),
      value: value,
      onChanged: onChanged,
    );
  }
}
