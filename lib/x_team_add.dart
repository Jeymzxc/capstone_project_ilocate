import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'database/firebase_db.dart';
import 'package:firebase_database/firebase_database.dart';

// A new class to hold the data and controllers for a single member's form.
class MemberFormData {
  final TextEditingController fullnameController;
  final TextEditingController addressController;
  final TextEditingController acdvIdController;
  String? selectedSex;
  DateTime? selectedDate;
  String? selectedRole; 
  final GlobalKey<FormState> formKey;

  MemberFormData()
      : fullnameController = TextEditingController(),
        addressController = TextEditingController(),
        acdvIdController = TextEditingController(),
        formKey = GlobalKey<FormState>();

  void dispose() {
    fullnameController.dispose();
    addressController.dispose();
    acdvIdController.dispose();
  }
}

class x_teamAdd extends StatefulWidget {
  const x_teamAdd({super.key});

  @override
  State<x_teamAdd> createState() => _x_teamAddState();
}

class _x_teamAddState extends State<x_teamAdd> {
  final Color ilocateRed = const Color(0xFFC70000);
  final DatabaseService _databaseService = DatabaseService(); 
  bool _obscurePassword = true;
  bool _isLoading = false;

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

  // List of roles for the dropdown menu
  final List<String> _roles = [
    'Team Leader',
    'Medic',
    'Search and Rescue',
    'Communications Officer',
    'Coordinator'
  ];

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

    // Reusable Show Dialog
  Future<void> _showCustomDialog({
    required String title,
    required String message,
    required Color headerColor,
    required IconData icon,
    bool isSuccess = false,
  }) {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.transparent,
          contentPadding: const EdgeInsets.all(0),
          content: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              color: Colors.white,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(height: 4, color: headerColor),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(icon, color: headerColor, size: 32),
                            const SizedBox(width: 8.0),
                            Text(
                              title.toUpperCase(),
                              style: TextStyle(
                                fontSize: 20.0,
                                fontWeight: FontWeight.bold,
                                color: headerColor,
                              ),
                            ),
                          ],
                        ),
                        const Divider(color: Colors.black26),
                        const SizedBox(height: 8.0),
                        Text(
                          message,
                          style: const TextStyle(fontSize: 14.0),
                        ),
                        const SizedBox(height: 24.0),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            ElevatedButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                                if (isSuccess) {
                                  Navigator.pop(context, true);
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                splashFactory: NoSplash.splashFactory,
                                backgroundColor: headerColor,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30.0),
                                ),
                              ),
                              child: const Text(
                                'OK',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ],
                        )
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
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

    // Function to handle the "DONE" button press.
    void _onDone() async {
      bool allFormsValid = true;

      // Validate team details form
      if (!_formKey.currentState!.validate()) {
        allFormsValid = false;
      }

      // Validate all member forms
      for (var formData in _memberForms) {
        if (!formData.formKey.currentState!.validate() ||
            formData.selectedDate == null ||
            formData.selectedSex == null ||
            formData.selectedRole == null) {
          allFormsValid = false;
          break;
        }
      }

      if (allFormsValid) {
        final teamDetails = {
          'teamName': _teamNameController.text.trim(),
          'username': _usernameController.text.trim(),
          'email': _emailController.text.trim(),
          'phoneNo': _phoneController.text.trim(),
          'password': _passwordController.text.trim(),
        };

        final Map<String, Map<String, String>> membersData = {};
        for (var formData in _memberForms) {
          final newKey = FirebaseDatabase.instance.ref().child("teams/members").push().key;
          membersData[newKey!] = {
            'fullname': formData.fullnameController.text.trim(),
            'dateOfBirth': DateFormat('yyyy-MM-dd').format(formData.selectedDate!),
            'address': formData.addressController.text.trim(),
            'sex': formData.selectedSex!,
            'acdvId': formData.acdvIdController.text.trim(),
            'role': formData.selectedRole!,
          };
        }

        final newTeamData = {
          ...teamDetails,
          'members': membersData,
        };

          setState(() {
          _isLoading = true;
        });

        try {
          final response = await _databaseService.createTeam(newTeamData);

          String title;
          String message;
          Color headerColor;
          IconData icon;
          bool isSuccess = response['success'] == true;

          if (isSuccess) {
            title = 'Success';
            message = 'Team successfully registered!';
            headerColor = Colors.green;
            icon = Icons.check_circle;
          } else {
            title = 'Error';
            message = 'Failed to register team. The following issues were found:\n';
            
            if (response.containsKey('duplicates')) {
              final duplicates = response['duplicates'] as Map<String, dynamic>;
              
              // Correctly handle each type of duplicate
              if (duplicates['username'] is bool && duplicates['username'] == true) {
                message += '- Username already exists.\n';
              }
              if (duplicates['email'] is bool && duplicates['email'] == true) {
                message += '- Email already exists.\n';
              }
              if (duplicates['phoneNo'] is bool && duplicates['phoneNo'] == true) {
                message += '- Phone number already exists.\n';
              }

              if (duplicates.containsKey('acdvId') && duplicates['acdvId'] is List) {
                final duplicateIds = duplicates['acdvId'] as List<dynamic>;
                message += '- The following ACDV IDs already exist:\n';
                for (var id in duplicateIds) {
                  message += '  - "$id"\n';
                }
              }
            }

            if (message == 'Failed to register team. The following issues were found:\n') {
              message += '- Unknown error occurred.';
            }
            headerColor = ilocateRed;
            icon = Icons.error;
          }
            await _showCustomDialog(
              title: title,
              message: message,
              headerColor: headerColor,
              icon: icon,
            );

            if (isSuccess) {
              if (!mounted) return;
              Navigator.pop(context, {'success': true});
            }

        } catch (e) {
          print('Firebase error while creating team: $e');
          _showCustomDialog(
            title: 'Error',
            message: 'An unexpected error occurred. Please try again.',
            headerColor: ilocateRed,
            icon: Icons.error,
          );
        } finally {
          setState(() => _isLoading = false);
        }
      } else {
        _showCustomDialog(
          title: 'Incomplete Form',
          message: 'Please fill out all the fields.',
          headerColor: ilocateRed,
          icon: Icons.warning,
        );
      }
    }

  // Adds a new, empty MemberFormData object to the list.
  void _addMemberForm() {
    setState(() {
      _memberForms.add(MemberFormData());
    });
  }

  // Removes a MemberFormData object from the list.
  void _removeMemberForm(MemberFormData formData) {
    setState(() {
      _memberForms.remove(formData);
      formData.dispose(); // Dispose of the controllers for the removed form
    });
  }

  @override
  Widget build(BuildContext context) {
    // The Stack is the root widget.
    return Stack(
      children: [
        // The Scaffold is the first child, forming the base UI layer.
        Scaffold(
          appBar: AppBar(
            automaticallyImplyLeading: false,
            toolbarHeight: 120.0,
            backgroundColor: ilocateRed,
            title: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Text(
                    'ADD',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 26.0,
                    ),
                  ),
                  Text(
                    'TEAMS',
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
              onPressed: () => Navigator.pop(context),
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
                      ListView.builder(
                        physics: const NeverScrollableScrollPhysics(),
                        shrinkWrap: true,
                        itemCount: _memberForms.length,
                        itemBuilder: (context, index) {
                          return _buildMemberForm(_memberForms[index], index);
                        },
                      ),
                      const SizedBox(height: 12.0),
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
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _onDone,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: ilocateRed,
                            padding: const EdgeInsets.symmetric(vertical: 16.0),
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
        ),
        // The loading overlay is a separate child of the Stack,
        // positioned on top of the Scaffold.
        if (_isLoading)
          Container(
            color: Colors.black.withOpacity(0.5),
            child: const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFC70000)),
              ),
            ),
          ),
      ],
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
                _buildRoleDropdown(formData), 
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  // Helper widget for role dropdown
  Widget _buildRoleDropdown(MemberFormData formData) {

    // Function to disable from picking team leader twice.
    final bool isTeamLeaderSelected = _memberForms
      .any((member) => member.selectedRole == 'Team Leader');

    final List<String> availableRoles = _roles.where((role) {
    if (role == formData.selectedRole) {
      return true;
    }
    if (isTeamLeaderSelected && role == 'Team Leader') {
      return false;
    }
    return true;
  }).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Role :',
            style: TextStyle(
              fontSize: 16.0,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8.0),
          DropdownButtonFormField<String>(
            value: formData.selectedRole,
            onChanged: (String? newValue) {
              setState(() {
                formData.selectedRole = newValue;
              });
            },
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please select a role';
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
              items: availableRoles.map((String role) {
              return DropdownMenuItem<String>(
                value: role,
                child: Text(role),
              );
            }).toList(),
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
            obscureText: type == 'password' ? _obscurePassword : obscureText,
            maxLength: type == 'phone' ? 11 : null,
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
              helperText: type == 'password'
                  ? 'Password must be at least 8 characters long.\nInclude uppercase, lowercase, number, and a special character. \nExample: Password#123'
                  : null,
              helperStyle: const TextStyle(
                fontSize: 12.0,
                color: Colors.grey,
              ),
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
              suffixIcon: type == 'password'
                  ? IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility : Icons.visibility_off,
                        color: Colors.grey,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    )
                  : null,
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
