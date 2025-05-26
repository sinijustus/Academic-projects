import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RuralWomenSignupForm extends StatefulWidget {
  @override
  _RuralWomenSignupFormState createState() => _RuralWomenSignupFormState();
}

class _RuralWomenSignupFormState extends State<RuralWomenSignupForm> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _skillController = TextEditingController();
  final _interestController = TextEditingController();
  final _locationController = TextEditingController();

  String? _selectedRole = "Women User";
  String? _lookingFor;
  bool _isLoading = false;

  List<String> skills = [];
  List<String> interests = [];

  final List<String> roles = ["Women User", "Recruiter", "Admin"];
  final List<String> lookingForOptions = ["Job Opportunities", "Skill Training", "Business Support"];
  final List<String> predefinedSkills = ["Tailoring", "Handicrafts", "Farming", "Beauty Services", "Cooking"];
  final List<String> predefinedInterests = ["Education", "Healthcare", "Technology", "Entrepreneurship", "Cooking and Food"];

  void addToList(String text, List<String> list, TextEditingController controller) {
    if (text.trim().isNotEmpty && !list.contains(text.trim())) {
      setState(() {
        list.add(text.trim());
        controller.clear();
      });
    }
  }

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedRole == "Women User") {
      if (interests.isEmpty || skills.isEmpty || _lookingFor == null || _locationController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Please fill all fields.")),
        );
        return;
      }
    }

    setState(() => _isLoading = true);

    try {
      FirebaseAuth auth = FirebaseAuth.instance;
      FirebaseFirestore firestore = FirebaseFirestore.instance;

      UserCredential userCredential = await auth.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      String userId = userCredential.user!.uid;

      Map<String, dynamic> userData = {
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'role': _selectedRole,
        'userId': userId,
        'createdAt': FieldValue.serverTimestamp(),
      };

      if (_selectedRole == "Women User") {
        userData.addAll({
          'phone': _phoneController.text.trim(),
          'skills': skills,
          'interests': interests,
          'lookingFor': _lookingFor,
          'location': _locationController.text.trim(),
        });
      }

      String collectionPath = _selectedRole == "Women User"
          ? "women_users"
          : _selectedRole == "Recruiter"
              ? "recruiters"
              : "admins";

      await firestore.collection(collectionPath).doc(userId).set(userData);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Signup successful!", style: TextStyle(fontSize: 16))),
      );

      Navigator.pop(context);
    } catch (e) {
      String errorMessage = "Signup failed! Please try again.";
      if (e is FirebaseAuthException) {
        if (e.code == 'email-already-in-use') errorMessage = "This email is already registered.";
        else if (e.code == 'weak-password') errorMessage = "The password is too weak.";
        else if (e.code == 'invalid-email') errorMessage = "Invalid email address.";
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage, style: TextStyle(fontSize: 16))),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        obscureText: isPassword,
        keyboardType: keyboardType,
        validator: (value) => value!.isEmpty ? "Required" : null,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: Colors.deepPurple),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: Colors.white,
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String? value,
    required String label,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: DropdownButtonFormField<String>(
        value: value,
        isExpanded: true,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: Colors.white,
        ),
        items: items.map((item) => DropdownMenuItem(value: item, child: Text(item))).toList(),
        onChanged: onChanged,
        validator: (val) => val == null ? "Required" : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.deepPurple[50],
      appBar: AppBar(
        title: Text("Sign Up", style: TextStyle(fontSize: 20)),
        centerTitle: true,
        backgroundColor: Colors.deepPurple,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                elevation: 4,
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        Text("Create Your Account", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.deepPurple)),
                        SizedBox(height: 20),
                        _buildDropdown(value: _selectedRole, label: "Select Role", items: roles, onChanged: (val) => setState(() => _selectedRole = val)),
                        _buildTextField(controller: _nameController, label: "Full Name", icon: Icons.person),
                        _buildTextField(controller: _emailController, label: "Email", icon: Icons.email, keyboardType: TextInputType.emailAddress),
                        if (_selectedRole == "Women User")
                          _buildTextField(controller: _phoneController, label: "Phone Number", icon: Icons.phone, keyboardType: TextInputType.phone),
                        _buildTextField(controller: _passwordController, label: "Password", icon: Icons.lock, isPassword: true),

                        if (_selectedRole == "Women User") ...[
                          // Location
                          _buildTextField(controller: _locationController, label: "Location", icon: Icons.location_on),

                          // Interests
                          Align(alignment: Alignment.centerLeft, child: Text("Interests")),
                          _buildDropdown(value: null, label: "Choose Interest", items: predefinedInterests, onChanged: (val) {
                            if (val != null) addToList(val, interests, _interestController);
                          }),
                          Row(
                            children: [
                              Expanded(child: TextField(controller: _interestController, decoration: InputDecoration(hintText: 'Add custom interest'))),
                              IconButton(icon: Icon(Icons.add), onPressed: () => addToList(_interestController.text, interests, _interestController)),
                            ],
                          ),
                          Wrap(spacing: 6, children: interests.map((i) => Chip(label: Text(i))).toList()),

                          // Skills
                          Align(alignment: Alignment.centerLeft, child: Text("Skills")),
                          _buildDropdown(value: null, label: "Choose Skill", items: predefinedSkills, onChanged: (val) {
                            if (val != null) addToList(val, skills, _skillController);
                          }),
                          Row(
                            children: [
                              Expanded(child: TextField(controller: _skillController, decoration: InputDecoration(hintText: 'Add custom skill'))),
                              IconButton(icon: Icon(Icons.add), onPressed: () => addToList(_skillController.text, skills, _skillController)),
                            ],
                          ),
                          Wrap(spacing: 6, children: skills.map((s) => Chip(label: Text(s))).toList()),

                          _buildDropdown(value: _lookingFor, label: "Looking For", items: lookingForOptions, onChanged: (val) => setState(() => _lookingFor = val)),
                        ],

                        SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: _isLoading ? null : _signUp,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.deepPurple,
                            padding: EdgeInsets.symmetric(horizontal: 40, vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: _isLoading
                              ? CircularProgressIndicator(color: Colors.white)
                              : Text("Sign Up", style: TextStyle(fontSize: 16, color: Colors.white)),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
