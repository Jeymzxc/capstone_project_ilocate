import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'database/firebase_db.dart';

// A new class to hold the data and controllers for a single member's form.
class AdminFormData {
  final TextEditingController fullnameController;
  final TextEditingController usernameController;
  final TextEditingController emailController;
  final TextEditingController phoneController;
  final TextEditingController passwordController;
  final TextEditingController acdvIdController;
  final TextEditingController addressController;
  String? selectedSex;
  DateTime? selectedDate;
  final GlobalKey<FormState> formKey;

  AdminFormData()
      : fullnameController = TextEditingController(),
        usernameController = TextEditingController(),
        emailController = TextEditingController(),
        phoneController = TextEditingController(),
        passwordController = TextEditingController(),
        acdvIdController = TextEditingController(),
        addressController = TextEditingController(),
        formKey = GlobalKey<FormState>();

  void dispose() {
    fullnameController.dispose();
    usernameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    passwordController.dispose();
    acdvIdController.dispose();
    addressController.dispose();
  }
}

// Placeholder for the z_Settings page to make the code runnable.
// You should replace this with your actual z_Settings.dart content.
class z_Settings extends StatelessWidget {
  const z_Settings({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: const Center(
        child: Text('This is the Settings Page'),
      ),
    );
  }
}

class z_settingsAdd extends StatefulWidget {
  const z_settingsAdd({super.key});

  @override
  State<z_settingsAdd> createState() => _z_settingsAddState();
}

class _z_settingsAddState extends State<z_settingsAdd> {
  final Color ilocateRed = const Color(0xFFC70000);
  bool _obscurePassword = true;
  bool _isLoading = false;

  // A single instance for the admin form.
  final AdminFormData _adminForm = AdminFormData();

  @override
  void dispose() {
    _adminForm.dispose();
    super.dispose();
  }

  // Reusable Show Dialog
  void _showCustomDialog({
    required String title,
    required String message,
    required Color headerColor,
    required IconData icon,
    bool isSuccess = false,
  }) {
    showDialog(
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

  /// A function to show the date picker for the form.
  void _showDatePicker(AdminFormData formData) async {
    final DateTime eighteenYearsAgo = DateTime(
      DateTime.now().year - 18,
      DateTime.now().month,
      DateTime.now().day,
    );

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: formData.selectedDate ?? eighteenYearsAgo, 
      firstDate: DateTime(1900),
      lastDate: eighteenYearsAgo, 
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
    // Check if the form is valid, and if date and sex are selected.
    if (_adminForm.formKey.currentState!.validate() &&
        _adminForm.selectedDate != null &&
        _adminForm.selectedSex != null) {
      // Loading Screen
      setState(() {
        _isLoading = true;
      });

      final newAdminData = {
        'fullname': _adminForm.fullnameController.text,
        'username': _adminForm.usernameController.text,
        'email': _adminForm.emailController.text,
        'phone': _adminForm.phoneController.text,
        'password': _adminForm.passwordController.text,
        'sex': _adminForm.selectedSex!,
        'acdvId': _adminForm.acdvIdController.text,
        'dateOfBirth': DateFormat('yyyy-MM-dd').format(_adminForm.selectedDate!),
        'address': _adminForm.addressController.text,
      };

      final result = await DatabaseService().createAdmin(newAdminData);

      setState(() {
        _isLoading = false;
      });

      String title;
      String message;
      bool isSuccess = result['success'] == true;

      if (isSuccess) {
        title = 'Success';
        message = 'Admin registered successfully!';
        _showCustomDialog(
          title: title,
          message: message,
          headerColor: Colors.green,
          icon: Icons.check_circle,
          isSuccess: isSuccess,
        );
      } else {
        title = 'Error';
        message = 'Failed to register admin. The following issues were found:\n';
        
        // Check for the 'duplicates' key before trying to access its values
        if (result.containsKey('duplicates')) {
          final duplicates = result['duplicates'] as Map<String, bool>;

          if (duplicates['username'] == true) {
            message += '- Username already exists.\n';
          }
          if (duplicates['email'] == true) {
            message += '- Email already exists.\n';
          }
          if (duplicates['phone'] == true) {
            message += '- Phone number already exists.\n';
          }
          if (duplicates['acdvId'] == true) {
            message += '- ACDVID already exists.\n';
          }
        }
        
        if (message == 'Failed to register admin. The following issues were found:\n') {
          message += '- Unknown error occurred.';
        }

        _showCustomDialog(
          title: title,
          message: message,
          headerColor: ilocateRed,
          icon: Icons.error,
        );
      }
    } else {
      _showCustomDialog(
        title: 'Incomplete Form',
        message: 'Please fill out all fields.',
        headerColor: ilocateRed,
        icon: Icons.warning,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
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
                    'ADMIN',
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
                    children: [
                      _buildAdminForm(_adminForm),
                      const SizedBox(height: 24.0),
                      // DONE button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _onDone,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: ilocateRed,
                            padding: const EdgeInsets.symmetric(vertical: 16.0),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24.0),
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
        // Overlay for the loading screen.
        if (_isLoading)
          const Opacity(
            opacity: 0.7,
            child: ModalBarrier(dismissible: false, color: Colors.black),
          ),
        if (_isLoading)
          const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFC70000)),
            ),
          ),
      ],
    );
  }

  // Helper widget to build the single admin form.
  Widget _buildAdminForm(AdminFormData formData) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Admin Details:',
            style: TextStyle(
              fontSize: 20.0,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12.0),
          Form(
            key: formData.formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTextField('Fullname', formData.fullnameController, type: 'fullname'),
                _buildTextField('Username', formData.usernameController, type: 'username'),
                _buildTextField('Email', formData.emailController, type: 'email'),
                _buildTextField('Phone No.', formData.phoneController, type: 'phone'),
                _buildTextField('Password', formData.passwordController, obscureText: true, type: 'password'),
                _buildRadioButtons(formData),
                _buildTextField('Accredited Community Disaster Volunteer (ACDV) ID Number', formData.acdvIdController),
                _buildDatePickerField('Date of Birth', formData.selectedDate, formData),
                _buildAddressField('Address', formData.addressController),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper widget for text fields with validation
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
                List<String> errors = [];

                if (value.length < 8) {
                  errors.add('at least 8 characters long');
                }
                if (!value.contains(RegExp(r'[A-Z]'))) {
                  errors.add('at least one uppercase letter');
                }
                if (!value.contains(RegExp(r'[a-z]'))) {
                  errors.add('at least one lowercase letter');
                }
                if (!value.contains(RegExp(r'[0-9]'))) {
                  errors.add('at least one number');
                }
                if (!value.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
                  errors.add('at least one special character');
                }

                if (errors.isNotEmpty) {
                  return 'Password must contain:\n- ${errors.join('\n- ')}';
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
  Widget _buildDatePickerField(String label, DateTime? date, AdminFormData formData) {
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
  Widget _buildRadioButtons(AdminFormData formData) {
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
