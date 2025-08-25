import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// A new class to hold the data and controllers for a single member's form.
class MemberFormData {
  final TextEditingController fullnameController;
  final TextEditingController addressController;
  final TextEditingController acdvIdController;
  final TextEditingController roleController;
  String? selectedSex;
  DateTime? selectedDate;
  final GlobalKey<FormState> formKey;

  MemberFormData()
      : fullnameController = TextEditingController(),
        addressController = TextEditingController(),
        acdvIdController = TextEditingController(),
        roleController = TextEditingController(),
        formKey = GlobalKey<FormState>();

  void dispose() {
    fullnameController.dispose();
    addressController.dispose();
    acdvIdController.dispose();
    roleController.dispose();
  }
}

class x_teamAdd extends StatefulWidget {
  const x_teamAdd({super.key});

  @override
  State<x_teamAdd> createState() => _x_teamAddState();
}

class _x_teamAddState extends State<x_teamAdd> {
  final Color ilocateRed = const Color(0xFFC70000);

  // Controllers for text fields for team details
  final TextEditingController _teamNameController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  // A list to hold the state for each dynamically added member form.
  final List<MemberFormData> _memberForms = [MemberFormData()];
  
  // Form Key for validation of the team details section
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _teamNameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    for (var formData in _memberForms) {
      formData.dispose();
    }
    super.dispose();
  }

  /// A function to show the date picker for a specific form.
  void _showDatePicker(MemberFormData formData) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: formData.selectedDate ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: ilocateRed, // Header background color
              onPrimary: Colors.white, // Header text color
              onSurface: Colors.black, // Body text color
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: ilocateRed, // Button text color
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != formData.selectedDate) {
      setState(() {
        formData.selectedDate = picked;
      });
    }
  }

  /// Function to handle the "DONE" button press.
  void _onDone() {
    bool allFormsValid = true;

    // Validate team details form
    if (!_formKey.currentState!.validate()) {
      allFormsValid = false;
    }

    // Validate all member forms
    for (var formData in _memberForms) {
      if (!formData.formKey.currentState!.validate() ||
          formData.selectedDate == null ||
          formData.selectedSex == null) {
        allFormsValid = false;
        break; // Stop if any member form is incomplete
      }
    }

    if (allFormsValid) {
      final teamDetails = {
        'teamName': _teamNameController.text,
        'username': _usernameController.text,
        'email': _emailController.text,
        'phoneNo': _phoneController.text,
        'password': _passwordController.text,
      };

      final List<Map<String, String>> membersData = [];
      for (var formData in _memberForms) {
        membersData.add({
          'fullname': formData.fullnameController.text,
          'dateOfBirth': DateFormat('yyyy-MM-dd').format(formData.selectedDate!),
          'address': formData.addressController.text,
          'sex': formData.selectedSex!,
          'acdvId': formData.acdvIdController.text,
          'role': formData.roleController.text,
        });
      }

      final newTeamData = {
        ...teamDetails,
        'members': membersData,
      };

      print('New Team Data: $newTeamData');

      // Navigate back to x_Team.dart
      Navigator.pop(context, newTeamData);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill out all the fields.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Adds a new, empty MemberFormData object to the list.
  void _addMemberForm() {
    setState(() {
      _memberForms.add(MemberFormData());
    });
  }

  /// Removes a MemberFormData object from the list.
  void _removeMemberForm(MemberFormData formData) {
    setState(() {
      _memberForms.remove(formData);
      formData.dispose(); // Dispose of the controllers for the removed form
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        toolbarHeight: 120.0,
        backgroundColor: ilocateRed,
        title: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Text(
                'ADD RESCUE',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 26.0,
                ),
              ),
              Text(
                'TEAM',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 26.0,
                ),
              ),
            ],
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 30.0),
          onPressed: () => Navigator.of(context).pop(),
        ),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(10),
          ),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Team Details Section
                  const Text(
                    'Team Details:',
                    style: TextStyle(
                      fontSize: 20.0,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12.0),
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        _buildTextField('Team Name', _teamNameController),
                        _buildTextField('Username', _usernameController, type: 'username'),
                        _buildTextField('Email', _emailController, type: 'email'),
                        _buildTextField('Phone No.', _phoneController, type: 'phone'),
                        _buildTextField('Password', _passwordController, obscureText: true, type: 'password'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24.0),

                  // Dynamically build a form for each member in the list.
                  for (var i = 0; i < _memberForms.length; i++)
                    _buildMemberForm(_memberForms[i], i),

                  const SizedBox(height: 12.0),
                  // The "Add" button now takes full width.
                  SizedBox(
                    width: double.infinity,
                    child: InkWell(
                      onTap: _addMemberForm,
                      borderRadius: BorderRadius.circular(12.0),
                      splashColor: Colors.grey.withOpacity(0.3),
                      highlightColor: Colors.grey.withOpacity(0.1),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                        decoration: BoxDecoration(
                          border: Border.all(color: ilocateRed, width: 2.0),
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        child: Center(
                          child: Icon(
                            Icons.add_circle,
                            color: ilocateRed,
                            size: 24.0,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24.0),

                  // DONE button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _onDone,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ilocateRed,
                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                        // Updated to have more rounded corners
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30.0),
                        ),
                      ),
                      child: const Text(
                        'DONE',
                        style: TextStyle(
                          fontSize: 18.0,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
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

  // Helper widget to build a single member form.
  Widget _buildMemberForm(MemberFormData formData, int index) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Add Team Members ${index + 1}',
                style: const TextStyle(
                  fontSize: 20.0,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              // Show remove button if there's more than one form.
              if (_memberForms.length > 1)
                IconButton(
                  icon: Icon(Icons.close_rounded, color: ilocateRed),
                  onPressed: () => _removeMemberForm(formData),
                ),
            ],
          ),
          const SizedBox(height: 12.0),
          Form(
            key: formData.formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTextField('Fullname', formData.fullnameController, type: 'fullname'),
                _buildDatePickerField('Date of Birth', formData.selectedDate, formData),
                _buildAddressField('Address', formData.addressController),
                _buildRadioButtons(formData),
                _buildTextField('Accredited Community Disaster Volunteer (ACDV) ID Number', formData.acdvIdController),
                _buildTextField('Role', formData.roleController),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper widget for text fields with validation
  Widget _buildTextField(String label, TextEditingController controller, {bool obscureText = false, String type = 'text'}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label :',
            style: const TextStyle(
              fontSize: 16.0,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8.0),
          TextFormField(
            controller: controller,
            obscureText: obscureText,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'This field cannot be empty';
              }
              if (type == 'username') {
                if (value.contains(' ') || value.length < 4) {
                  return 'Username must be at least 4 characters and contain no spaces';
                }
              }
              if (type == 'email') {
                final bool isValid = RegExp(r"^[a-zA-Z0-9.]+@[a-zA-Z0-9]+\.[a-zA-Z]+").hasMatch(value);
                if (!isValid) {
                  return 'Please enter a valid email format';
                }
              }
              if (type == 'phone') {
                final bool isValid = RegExp(r"^(09|\+639)\d{9}$").hasMatch(value);
                if (!isValid) {
                  return 'Please enter a valid Philippine phone number (e.g., 09xxxxxxxxx)';
                }
              }
              if (type == 'password') {
                if (value.length < 8) {
                  return 'Password must be at least 8 characters long';
                }
                if (!value.contains(RegExp(r'[A-Z]'))) {
                  return 'Password must contain at least one uppercase letter';
                }
                if (!value.contains(RegExp(r'[a-z]'))) {
                  return 'Password must contain at least one lowercase letter';
                }
                if (!value.contains(RegExp(r'[0-9]'))) {
                  return 'Password must contain at least one number';
                }
                if (!value.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
                  return 'Password must contain at least one special character';
                }
              }
              if (type == 'fullname') {
                if (!value.contains(' ') || value.trim().split(' ').length < 2) {
                  return 'Please enter your full name (at least two words)';
                }
              }
              return null;
            },
            decoration: InputDecoration(
              errorStyle: const TextStyle(color: Colors.red),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.0),
                borderSide: BorderSide(color: ilocateRed, width: 2.0),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.0),
                borderSide: BorderSide(color: ilocateRed, width: 2.0),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.0),
                borderSide: BorderSide(color: ilocateRed, width: 2.0),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper widget for date picker field
  Widget _buildDatePickerField(String label, DateTime? date, MemberFormData formData) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label :',
            style: const TextStyle(
              fontSize: 16.0,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8.0),
          GestureDetector(
            onTap: () => _showDatePicker(formData),
            child: AbsorbPointer(
              child: TextFormField(
                validator: (value) {
                  if (formData.selectedDate == null) {
                    return 'Please select a date';
                  }
                  return null;
                },
                decoration: InputDecoration(
                  errorStyle: const TextStyle(color: Colors.red),
                  hintText: date == null ? '' : DateFormat('yyyy-MM-dd').format(date),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                    borderSide: BorderSide(color: ilocateRed, width: 2.0),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                    borderSide: BorderSide(color: ilocateRed, width: 2.0),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                    borderSide: BorderSide(color: ilocateRed, width: 2.0),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper widget for radio buttons
  Widget _buildRadioButtons(MemberFormData formData) {
    return FormField<String>(
      initialValue: formData.selectedSex,
      validator: (value) {
        if (formData.selectedSex == null) {
          return 'Please select a gender';
        }
        return null;
      },
      builder: (FormFieldState<String> state) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Sex :',
                style: TextStyle(
                  fontSize: 16.0,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8.0),
              Row(
                children: <Widget>[
                  Expanded(
                    child: RadioListTile<String>(
                      title: const Text('Male'),
                      value: 'Male',
                      groupValue: formData.selectedSex,
                      onChanged: (String? value) {
                        setState(() {
                          formData.selectedSex = value;
                          state.didChange(value);
                        });
                      },
                      activeColor: ilocateRed,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  Expanded(
                    child: RadioListTile<String>(
                      title: const Text('Female'),
                      value: 'Female',
                      groupValue: formData.selectedSex,
                      onChanged: (String? value) {
                        setState(() {
                          formData.selectedSex = value;
                          state.didChange(value);
                        });
                      },
                      activeColor: ilocateRed,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),
              if (state.hasError)
                Padding(
                  padding: const EdgeInsets.only(left: 16.0, top: 4.0),
                  child: Text(
                    state.errorText!,
                    style: const TextStyle(color: Colors.red, fontSize: 12.0),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  // Helper widget for address text field
  Widget _buildAddressField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label :',
            style: const TextStyle(
              fontSize: 16.0,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8.0),
          TextFormField(
            controller: controller,
            maxLines: 4,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'This field cannot be empty';
              }
              return null;
            },
            decoration: InputDecoration(
              errorStyle: const TextStyle(color: Colors.red),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.0),
                borderSide: BorderSide(color: ilocateRed, width: 2.0),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.0),
                borderSide: BorderSide(color: ilocateRed, width: 2.0),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.0),
                borderSide: BorderSide(color: ilocateRed, width: 2.0),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
