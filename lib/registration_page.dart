import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'background_image_wrapper.dart'; // Assuming you have this widget
import 'header_footer.dart'; // Import the header and footer

class RegistrationPage extends StatefulWidget {
  @override
  _RegistrationPageState createState() => _RegistrationPageState();
}

class _RegistrationPageState extends State<RegistrationPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _vehicleNoController = TextEditingController();
  final TextEditingController _idController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  // Function to save data to Firestore
  Future<void> _saveToFirestore() async {
    try {
      CollectionReference users =
          FirebaseFirestore.instance.collection('users');

      final userData = {
        "id": _idController.text.trim(),
        "name": _nameController.text.trim(),
        "age": int.tryParse(_ageController.text.trim()) ?? 0,
        "vehicle_number": _vehicleNoController.text.trim(),
        "username": _usernameController.text.trim(),
        "password": _passwordController.text.trim(),
      };

      await users.add(userData);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Registration Successful')),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BackgroundImageWrapper(
        child: HeaderFooter(
          title: "User Registration", // ✅ Pass the title for header
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Form
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        _buildTextField(_idController, "Profile ID"),
                        _buildTextField(_nameController, "Name"),
                        _buildTextField(_ageController, "Age", isNumber: true),
                        _buildTextField(_vehicleNoController, "Vehicle Number"),
                        _buildTextField(_usernameController, "Username"),
                        _buildTextField(_passwordController, "Password",
                            isPassword: true),
                        _buildTextField(
                            _confirmPasswordController, "Confirm Password",
                            isPassword: true),

                        SizedBox(height: 40),

                        // Submit Button
                        ElevatedButton(
                          onPressed: () {
                            if (_formKey.currentState!.validate()) {
                              _saveToFirestore();
                            }
                          },
                          child: Text('Register'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            padding: EdgeInsets.symmetric(
                                vertical: 16, horizontal: 40),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Helper function to create text fields
  Widget _buildTextField(TextEditingController controller, String label,
      {bool isNumber = false, bool isPassword = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextFormField(
        controller: controller,
        obscureText: isPassword,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please enter your $label';
          }
          if (isPassword && value.length < 6) {
            return 'Password must be at least 6 characters';
          }
          if (label == "Confirm Password" &&
              value != _passwordController.text) {
            return 'Passwords do not match';
          }
          return null;
        },
      ),
    );
  }
}
