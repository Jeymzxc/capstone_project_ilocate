import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'database/firebase_db.dart';

class UserFormData {
  final TextEditingController fullnameController;
  final TextEditingController phoneController;
  final TextEditingController addressController;
  final TextEditingController devuidController;
  String? selectedSex;
  DateTime? selectedDate;
  final GlobalKey<FormState> formKey;

  UserFormData()
      : fullnameController = TextEditingController(),
        phoneController = TextEditingController(),
        addressController = TextEditingController(),
        devuidController = TextEditingController(),
        formKey = GlobalKey<FormState>();

  void dispose() {
    fullnameController.dispose();
    phoneController.dispose();
    addressController.dispose();
    devuidController.dispose();
  }
}

class z_settingsRegister extends StatefulWidget {
  const z_settingsRegister({super.key});

  @override
  State<z_settingsRegister> createState() => _z_settingsRegisterState();
}

class _z_settingsRegisterState extends State<z_settingsRegister> {
  final Color ilocateRed = const Color(0xFFC70000);
  bool _isLoading = false;

  // A single instance for the user form.
  final UserFormData _userForm = UserFormData();

  @override
  void dispose() {
    _userForm.dispose();
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

  // A function to show the date picker for the form.
  void _showDatePicker(UserFormData formData) async {
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

// Function to handle the "REGISTER" button press.
void _onRegister() async {
  if (_userForm.formKey.currentState!.validate() &&
      _userForm.selectedDate != null &&
      _userForm.selectedSex != null) {
    // Show loading
    setState(() {
      _isLoading = true;
    });

    final Map<String, String> newUserData = {
      'fullname': _userForm.fullnameController.text,
      'phone': _userForm.phoneController.text,
      'address': _userForm.addressController.text,
      'dateOfBirth': DateFormat('yyyy-MM-dd').format(_userForm.selectedDate!),
      'sex': _userForm.selectedSex!,
      'devuid': _userForm.devuidController.text,
    };

    final result = await DatabaseService().createDevice(newUserData);

    setState(() {
      _isLoading = false;
    });

    bool isSuccess = result['success'] == true;
    String title, message;
    Color headerColor;
    IconData icon;

    if (isSuccess) {
      title = 'Success';
      message = 'Device registered successfully!';
      headerColor = Colors.green;
      icon = Icons.check_circle;

      _showCustomDialog(
        title: title,
        message: message,
        headerColor: headerColor,
        icon: icon,
        isSuccess: true,
      );
    } else {
      title = 'Error';
      message = 'Failed to register device. The following issues were found:\n';

      if (result['devuid'] == true) {
        message += '- DEVUID already exists.\n';
      }
      if (result['phone'] == true) {
        message += '- Phone number already exists.\n';
      }

      if (message == 'Failed to register device. The following issues were found:\n') {
        message += '- An unknown error occurred.';
      }

      _showCustomDialog(
        title: title,
        message: message,
        headerColor: ilocateRed,
        icon: Icons.error,
      );
    }
  } else {
    // Incomplete form
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
                'REGISTER',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 26.0,
                ),
              ),
              Text(
                'DEVICE',
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
      body: Stack(
        children: [
          // Main content
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      _buildUserForm(_userForm),
                      const SizedBox(height: 24.0),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _onRegister,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: ilocateRed,
                            padding: const EdgeInsets.symmetric(vertical: 16.0),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24.0),
                            ),
                          ),
                          child: const Text(
                            'REGISTER',
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

          // Loading overlay
          if (_isLoading) ...[
            const Opacity(
              opacity: 0.7,
              child: ModalBarrier(dismissible: false, color: Colors.black),
            ),
            const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFC70000)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // Helper widget to build the single user form.
  Widget _buildUserForm(UserFormData formData) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'USER DETAILS:',
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
                _buildTextField('Phone No.', formData.phoneController, type: 'phone'),
                _buildAddressField('Address', formData.addressController),
                _buildDatePickerField('Date of Birth', formData.selectedDate, formData),
                _buildRadioButtons(formData),
                _buildTextField('DEVUID', formData.devuidController, type: 'devuid'),
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
            maxLength: type == 'phone' ? 11 : (type == 'devuid' ? 16 : null),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'This field cannot be empty';
              }
              if (type == 'devuid') {
                if (value.length != 16) {
                  return 'DEVUID must be exactly 16 characters long';
                }
              }
              if (type == 'phone') {
                final bool isValid = RegExp(r"^(09|\+639)\d{9}$").hasMatch(value);
                if (!isValid) {
                  return 'Please enter a valid Philippine phone number (e.g., 09xxxxxxxxx)';
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
  Widget _buildDatePickerField(String label, DateTime? date, UserFormData formData) {
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
  Widget _buildRadioButtons(UserFormData formData) {
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