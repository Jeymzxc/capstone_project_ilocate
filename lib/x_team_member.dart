import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'database/firebase_db.dart';

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

class x_teamMember extends StatefulWidget {
  final String teamId;
  final bool hasTeamLeader; 
  const x_teamMember({super.key, required this.teamId, this.hasTeamLeader = false});

  @override
  State<x_teamMember> createState() => _x_teamMemberState();
}

class _x_teamMemberState extends State<x_teamMember> {
  final Color ilocateRed = const Color(0xFFC70000);
  final DatabaseService _databaseService = DatabaseService();
  bool _isLoading = false;

  // A list to hold the state for each dynamically added form.
  final List<MemberFormData> _memberForms = [MemberFormData()];

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

  // Function to handle the "DONE" button press.
  void _onDone() async {
    bool allFormsValid = true;

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
      setState(() {
        _isLoading = true;
      });

      try {
        // Loop through each member form and add them one by one.
        for (var formData in _memberForms) {
          final memberData = {
            'fullname': formData.fullnameController.text.trim(),
            'dateOfBirth': DateFormat('yyyy-MM-dd').format(formData.selectedDate!),
            'address': formData.addressController.text.trim(),
            'sex': formData.selectedSex!,
            'acdvId': formData.acdvIdController.text.trim(),
            'role': formData.selectedRole!,
          };
          
          final result = await _databaseService.addTeamMember(widget.teamId, memberData);
          
          if (result['success'] == false) {
            String errorMessage = result['message'] ?? 'An unknown error occurred while adding a member.';
    
            if (errorMessage.contains('ACDV ID already exists.')) {
              // Get the ACDV ID from the form and append it to the message
              errorMessage = '- ACDV ID "${memberData['acdvId']}" already exists.';
            }
            
            await _showCustomDialog(
              title: 'Error',
              message: errorMessage,
              headerColor: ilocateRed,
              icon: Icons.error,
            );
            return; 
          }
        }

        // If the loop completes successfully for all members, show a success dialog.
        await _showCustomDialog(
          title: 'Success',
          message: 'Members successfully added!',
          headerColor: Colors.green,
          icon: Icons.check_circle,
        );

        if (!mounted) return;
        Navigator.pop(context, {'success': true});
      } catch (e) {
        print('Firebase error while adding members: $e');
        await _showCustomDialog(
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
                'ADD',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 26.0,
                ),
              ),
              Text(
                'MEMBERS',
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
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      _buildMemberForms(),
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
                      const SizedBox(height: 16.0),
                    ],
                  ),
                ),
              ),
              if (_isLoading)
                Container(
                  color: Colors.black54,
                  child: const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFC70000)),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMemberForms() {
    return Column(
      children: [
        const SizedBox(height: 24.0),
        _buildFormTitle('Team Members'),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _memberForms.length,
          itemBuilder: (context, index) {
            return _buildMemberForm(_memberForms[index], index);
          },
        ),
      ],
    );
  }

  Widget _buildFormTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 22.0,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
    );
  }

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
                'Member ${index + 1}',
                style: const TextStyle(
                  fontSize: 20.0,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
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
                _buildTextField('Fullname', formData.fullnameController,
                    type: 'fullname'),
                _buildDatePickerField(
                    'Date of Birth', formData.selectedDate, formData),
                _buildAddressField('Address', formData.addressController),
                _buildRadioButtons(formData),
                _buildTextField(
                    'Accredited Community Disaster Volunteer (ACDV) ID Number',
                    formData.acdvIdController),
                _buildRoleDropdown(formData),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleDropdown(MemberFormData formData) {
    final bool isTeamLeaderSelectedByAnother = _memberForms
        .any((member) => member != formData && member.selectedRole == 'Team Leader');
    
    final bool isTeamLeaderTaken = widget.hasTeamLeader || isTeamLeaderSelectedByAnother;

    final List<String> availableRoles = _roles.where((role) {
      if (role == 'Team Leader' && isTeamLeaderTaken) {
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

  Widget _buildTextField(String label, TextEditingController controller,
      {bool obscureText = false, String type = 'text'}) {
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
              if (type == 'username' &&
                  (value.contains(' ') || value.length < 4)) {
                return 'Username must be at least 4 characters and contain no spaces';
              }
              if (type == 'email' &&
                  !RegExp(r"^[a-zA-Z0-9.]+@[a-zA-Z0-9]+\.[a-zA-Z]+").hasMatch(value)) {
                return 'Please enter a valid email format';
              }
              if (type == 'phone' &&
                  !RegExp(r"^(09|\+639)\d{9}$").hasMatch(value)) {
                return 'Please enter a valid Philippine phone number (e.g., 09xxxxxxxxx)';
              }
              if (type == 'password' &&
                  (value.length < 8 ||
                      !value.contains(RegExp(r'[A-Z]')) ||
                      !value.contains(RegExp(r'[a-z]')) ||
                      !value.contains(RegExp(r'[0-9]')) ||
                      !value.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]')))) {
                return 'Password must be at least 8 characters long and contain at least one uppercase letter, one lowercase letter, one number, and one special character.';
              }
              if (type == 'fullname' &&
                  (!value.contains(' ') || value.trim().split(' ').length < 2)) {
                return 'Please enter your full name (at least two words)';
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

  Widget _buildDatePickerField(
      String label, DateTime? date, MemberFormData formData) {
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