// ignore_for_file: use_build_context_synchronously, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  User? user;
  Map<String, dynamic>? userData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _getUserData();
  }

  Future<void> _getUserData() async {
    try {
      user = _auth.currentUser;
      if (user != null) {
        DocumentSnapshot doc = await _firestore.collection('women_users').doc(user!.uid).get();
        if (doc.exists) {
          setState(() {
            userData = doc.data() as Map<String, dynamic>?;
            _isLoading = false;
          });
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
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'My Profile',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.purple,
          ),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.purple),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.purple),
              ),
            )
          : SingleChildScrollView(
              child: Column(
                children: [
                  // Profile Header with background decoration
                  Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(30),
                        bottomRight: Radius.circular(30),
                      ),
                    ),
                    child: Column(
                      children: [
                        const SizedBox(height: 20),
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            Container(
                              width: 110,
                              height: 110,
                              decoration: BoxDecoration(
                                color: Colors.purple.withOpacity(0.2),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const CircleAvatar(
                              radius: 50,
                              backgroundColor: Colors.white,
                              backgroundImage: AssetImage('assets/images/profile.png'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          userData?['name'] ?? 'Name not set',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.location_on,
                              size: 16,
                              color: Colors.purple,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              userData?['location'] ?? 'Location not set',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 30),
                      ],
                    ),
                  ),

                  // Quick stats
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 25,
                    ),
                    child: Row(
                      children: [
                        _buildStatItem('Skills', 
                            (userData?['skills'] as List<dynamic>?)?.length.toString() ?? '0'),
                        _buildStatItem('Age', userData?['age']?.toString() ?? 'N/A'),
                        _buildStatItem('Education', 
                            userData?['education'] != null ? '1' : '0'),
                      ],
                    ),
                  ),

                  // Profile Details Cards
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        _buildInfoCard(
                          'Personal Information',
                          [
                            _buildInfoRow(Icons.cake, 'Age', 
                                '${userData?['age'] ?? 'Not set'}'),
                            _buildInfoRow(Icons.phone, 'Phone', 
                                userData?['phone'] ?? 'Not set'),
                            _buildInfoRow(Icons.email, 'Email', 
                                user?.email ?? 'Not set'),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildInfoCard(
                          'Education',
                          [
                            _buildInfoRow(Icons.school, 'Degree', 
                                userData?['education'] ?? 'Not set'),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildSkillsCard('Skills', userData?['skills'] ?? []),
                        const SizedBox(height: 30),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => EditProfileScreen(userData!),
                              ),
                            ).then((_) => _getUserData());
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.purple,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              vertical: 16,
                              horizontal: 24,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            elevation: 2,
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.edit),
                              SizedBox(width: 8),
                              Text(
                                'Edit Profile',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 30),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 5),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.purple,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(String title, List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.purple,
            ),
          ),
          const SizedBox(height: 5),
          const Divider(),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }

  Widget _buildSkillsCard(String title, List<dynamic> skills) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.purple,
            ),
          ),
          const SizedBox(height: 5),
          const Divider(),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: skills.map<Widget>((skill) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.purple.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.purple.withOpacity(0.3),
                  ),
                ),
                child: Text(
                  skill.toString(),
                  style: const TextStyle(
                    color: Colors.purple,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.purple.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: Colors.purple,
              size: 20,
            ),
          ),
          const SizedBox(width: 15),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class EditProfileScreen extends StatefulWidget {
  final Map<String, dynamic> userData;
  const EditProfileScreen(this.userData, {super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  late TextEditingController nameController;
  late TextEditingController ageController;
  late TextEditingController locationController;
  late TextEditingController skillsController;
  late TextEditingController phoneController;
  late TextEditingController educationController;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.userData['name']);
    ageController = TextEditingController(text: widget.userData['age']?.toString());
    locationController = TextEditingController(text: widget.userData['location']);
    skillsController = TextEditingController(text: widget.userData['skills']?.join(', '));
    phoneController = TextEditingController(text: widget.userData['phone']);
    educationController = TextEditingController(text: widget.userData['education']);
  }

  @override
  void dispose() {
    nameController.dispose();
    ageController.dispose();
    locationController.dispose();
    skillsController.dispose();
    phoneController.dispose();
    educationController.dispose();
    super.dispose();
  }

  Future<void> _updateProfile() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        await _firestore.collection('users').doc(_auth.currentUser!.uid).update({
          'name': nameController.text.trim(),
          'age': int.tryParse(ageController.text.trim()) ?? 0,
          'location': locationController.text.trim(),
          'skills': skillsController.text.split(',').map((e) => e.trim()).toList(),
          'phone': phoneController.text.trim(),
          'education': educationController.text.trim(),
        });
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile updated successfully')),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating profile: $e')),
        );
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Edit Profile',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.purple,
          ),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.purple),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _buildTextField(
                      controller: nameController,
                      label: 'Name',
                      icon: Icons.person,
                      validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                    ),
                    _buildTextField(
                      controller: ageController,
                      label: 'Age',
                      icon: Icons.cake,
                      keyboardType: TextInputType.number,
                      validator: (v) {
                        if (v?.isEmpty ?? true) return 'Required';
                        if (int.tryParse(v!) == null) return 'Invalid age';
                        return null;
                      },
                    ),
                    _buildTextField(
                      controller: locationController,
                      label: 'Location',
                      icon: Icons.location_on,
                      validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                    ),
                    _buildTextField(
                      controller: phoneController,
                      label: 'Phone',
                      icon: Icons.phone,
                      keyboardType: TextInputType.phone,
                      validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                    ),
                    _buildTextField(
                      controller: educationController,
                      label: 'Education',
                      icon: Icons.school,
                      validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                    ),
                    _buildTextField(
                      controller: skillsController,
                      label: 'Skills (comma separated)',
                      icon: Icons.psychology,
                      validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                      maxLines: 3,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _updateProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.all(16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 2,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Save Changes',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    int? maxLines,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: Colors.purple),
          filled: true,
          fillColor: Colors.grey[50],
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: const BorderSide(color: Colors.purple),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: const BorderSide(color: Colors.red),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: const BorderSide(color: Colors.red),
          ),
        ),
        keyboardType: keyboardType,
        validator: validator,
        maxLines: maxLines ?? 1,
      ),
    );
  }
}