import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../utils/constants.dart';
import '../../utils/validators.dart';
import '../../providers/auth_provider.dart';
import '../../services/pocketbase_service.dart';
import '../../models/school.dart';
import '../../models/faculty.dart';
import '../../models/department.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/custom_dropdown.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/error_widget.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/responsive_builder.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _middleNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final _pbService = PocketBaseService();

  List<School> _schools = [];
  List<Faculty> _faculties = [];
  List<Department> _departments = [];

  School? _selectedSchool;
  Faculty? _selectedFaculty;
  Department? _selectedDepartment;
  String? _selectedAcademicRank;

  bool _isLoadingSchools = false;
  bool _isLoadingFaculties = false;
  bool _isLoadingDepartments = false;

  @override
  void initState() {
    super.initState();
    _loadSchools();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _middleNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _loadSchools() async {
    setState(() => _isLoadingSchools = true);
    try {
      final schools = await _pbService.getSchools();
      print('$schools');
      setState(() {
        _schools = schools;
        _isLoadingSchools = false;
      });
    } catch (e) {
      setState(() => _isLoadingSchools = false);
      if (mounted) {
        ErrorSnackBar.show(context, 'Failed to load schools');
      }
    }
  }

  Future<void> _loadFaculties(String schoolId) async {
    setState(() {
      _isLoadingFaculties = true;
      _faculties = [];
      _departments = [];
      _selectedFaculty = null;
      _selectedDepartment = null;
    });

    try {
      final faculties = await _pbService.getFacultiesBySchool(schoolId);
      setState(() {
        _faculties = faculties;
        _isLoadingFaculties = false;
      });
    } catch (e) {
      setState(() => _isLoadingFaculties = false);
      if (mounted) {
        ErrorSnackBar.show(context, 'Failed to load faculties');
      }
    }
  }

  Future<void> _loadDepartments(String facultyId) async {
    setState(() {
      _isLoadingDepartments = true;
      _departments = [];
      _selectedDepartment = null;
    });

    try {
      final departments = await _pbService.getDepartmentsByFaculty(facultyId);
      setState(() {
        _departments = departments;
        _isLoadingDepartments = false;
      });
    } catch (e) {
      setState(() => _isLoadingDepartments = false);
      if (mounted) {
        ErrorSnackBar.show(context, 'Failed to load departments');
      }
    }
  }

  Future<void> _handleSignup() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedSchool == null || _selectedFaculty == null || _selectedAcademicRank == null) {
      ErrorSnackBar.show(context, 'Please fill all required fields');
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    final success = await authProvider.signup(
      email: _emailController.text.trim(),
      password: _passwordController.text,
      confirmPassword: _confirmPasswordController.text,
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
      middleName: _middleNameController.text.trim().isEmpty ? null : _middleNameController.text.trim(),
      academicRank: _selectedAcademicRank!,
      schoolId: _selectedSchool!.id,
      facultyId: _selectedFaculty!.id,
      departmentId: _selectedDepartment?.id,
    );

    if (mounted) {
      if (success) {
        SuccessSnackBar.show(context, AppConstants.signupSuccess);
        Navigator.pushReplacementNamed(context, '/dashboard');
      } else {
        ErrorSnackBar.show(
          context,
          authProvider.errorMessage ?? 'Signup failed',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Account'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ResponsiveConstrainedBox(
        maxWidth: 700,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppConstants.paddingLarge),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(),
                const SizedBox(height: 32),
                _buildPersonalInfoSection(),
                const SizedBox(height: 24),
                _buildAcademicInfoSection(),
                const SizedBox(height: 24),
                _buildAccountInfoSection(),
                const SizedBox(height: 32),
                CustomButton(
                  label: 'Create Account',
                  onPressed: authProvider.isLoading ? null : _handleSignup,
                  isLoading: authProvider.isLoading,
                  width: double.infinity,
                )
                    .animate()
                    .fadeIn(delay: 1000.ms, duration: 600.ms)
                    .scale(begin: const Offset(0.95, 0.95), end: const Offset(1, 1)),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Already have an account? ',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Sign In'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Join ${AppConstants.appName}',
          style: Theme.of(context).textTheme.headlineMedium,
        )
            .animate()
            .fadeIn(duration: 600.ms)
            .slideY(begin: -0.3, end: 0),
        const SizedBox(height: 8),
        Text(
          'Create your tutor account to get started',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppTheme.textSecondary,
              ),
        )
            .animate()
            .fadeIn(delay: 200.ms, duration: 600.ms)
            .slideY(begin: -0.3, end: 0),
      ],
    );
  }

  Widget _buildPersonalInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Personal Information',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppTheme.primaryBlue,
              ),
        ),
        const SizedBox(height: 16),
        ResponsiveRow(
          children: [
            CustomTextField(
              controller: _firstNameController,
              label: 'First Name',
              hint: 'Enter your first name',
              prefixIcon: const Icon(Icons.person_outline),
              validator: Validators.validateFirstName,
              textCapitalization: TextCapitalization.words,
            ),
            CustomTextField(
              controller: _lastNameController,
              label: 'Last Name',
              hint: 'Enter your last name',
              prefixIcon: const Icon(Icons.person_outline),
              validator: Validators.validateLastName,
              textCapitalization: TextCapitalization.words,
            ),
          ],
        ),
        const SizedBox(height: 20),
        CustomTextField(
          controller: _middleNameController,
          label: 'Middle Name (Optional)',
          hint: 'Enter your middle name',
          prefixIcon: const Icon(Icons.person_outline),
          validator: Validators.validateMiddleName,
          textCapitalization: TextCapitalization.words,
        ),
      ],
    )
        .animate()
        .fadeIn(delay: 300.ms, duration: 600.ms)
        .slideX(begin: -0.2, end: 0);
  }

  Widget _buildAcademicInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Academic Information',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppTheme.primaryBlue,
              ),
        ),
        const SizedBox(height: 16),
        CustomDropdown<String>(
          label: 'Academic Rank',
          hint: 'Select your rank',
          value: _selectedAcademicRank,
          items: AppConstants.academicRanks
              .map((rank) => DropdownMenuItem(
                    value: rank,
                    child: Text(rank),
                  ))
              .toList(),
          onChanged: (value) {
            setState(() => _selectedAcademicRank = value);
          },
          validator: (value) => Validators.validateDropdown(value, fieldName: 'academic rank'),
          prefixIcon: const Icon(Icons.school_outlined),
        ),
        const SizedBox(height: 20),
        _isLoadingSchools
            ? const Center(child: SmallLoadingIndicator())
            : CustomDropdown<School>(
                label: 'School',
                hint: 'Select your school',
                value: _selectedSchool,
                items: _schools
                    .map((school) => DropdownMenuItem(
                          value: school,
                          child: Text(school.name),
                        ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedSchool = value;
                    _selectedFaculty = null;
                    _selectedDepartment = null;
                  });
                  if (value != null) {
                    _loadFaculties(value.id);
                  }
                },
                validator: (value) => Validators.validateDropdown(value, fieldName: 'school'),
                prefixIcon: const Icon(Icons.account_balance_outlined),
              ),
        const SizedBox(height: 20),
        _isLoadingFaculties
            ? const Center(child: SmallLoadingIndicator())
            : CustomDropdown<Faculty>(
                label: 'Faculty',
                hint: 'Select your faculty',
                value: _selectedFaculty,
                items: _faculties
                    .map((faculty) => DropdownMenuItem(
                          value: faculty,
                          child: Text(faculty.name),
                        ))
                    .toList(),
                onChanged: _selectedSchool == null
                    ? null
                    : (value) {
                        setState(() {
                          _selectedFaculty = value;
                          _selectedDepartment = null;
                        });
                        if (value != null) {
                          _loadDepartments(value.id);
                        }
                      },
                validator: (value) => Validators.validateDropdown(value, fieldName: 'faculty'),
                prefixIcon: const Icon(Icons.business_outlined),
                enabled: _selectedSchool != null,
              ),
        const SizedBox(height: 20),
        _isLoadingDepartments
            ? const Center(child: SmallLoadingIndicator())
            : CustomDropdown<Department>(
                label: 'Department (Optional)',
                hint: 'Select your department',
                value: _selectedDepartment,
                items: _departments
                    .map((dept) => DropdownMenuItem(
                          value: dept,
                          child: Text(dept.name),
                        ))
                    .toList(),
                onChanged: _selectedFaculty == null
                    ? null
                    : (value) {
                        setState(() => _selectedDepartment = value);
                      },
                prefixIcon: const Icon(Icons.category_outlined),
                enabled: _selectedFaculty != null,
              ),
      ],
    )
        .animate()
        .fadeIn(delay: 500.ms, duration: 600.ms)
        .slideX(begin: -0.2, end: 0);
  }

  Widget _buildAccountInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Account Information',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppTheme.primaryBlue,
              ),
        ),
        const SizedBox(height: 16),
        CustomTextField(
          controller: _emailController,
          label: 'Email Address',
          hint: 'Enter your email',
          keyboardType: TextInputType.emailAddress,
          prefixIcon: const Icon(Icons.email_outlined),
          validator: Validators.validateEmail,
        ),
        const SizedBox(height: 20),
        CustomTextField(
          controller: _passwordController,
          label: 'Password',
          hint: 'Enter your password',
          obscureText: true,
          prefixIcon: const Icon(Icons.lock_outlined),
          validator: Validators.validatePassword,
        ),
        const SizedBox(height: 20),
        CustomTextField(
          controller: _confirmPasswordController,
          label: 'Confirm Password',
          hint: 'Re-enter your password',
          obscureText: true,
          prefixIcon: const Icon(Icons.lock_outlined),
          validator: (value) => Validators.validateConfirmPassword(
            value,
            _passwordController.text,
          ),
        ),
      ],
    )
        .animate()
        .fadeIn(delay: 700.ms, duration: 600.ms)
        .slideX(begin: -0.2, end: 0);
  }
}