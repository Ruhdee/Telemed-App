import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/app_logger.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/glass_panel.dart';
import '../domain/user_model.dart';
import '../providers/auth_provider.dart';

/// Register screen matching the React `RegisterModal.tsx`.
class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Step 1 fields (all roles)
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  // Step 2 fields (doctor only)
  final _specializationController = TextEditingController();
  final _experienceController = TextEditingController();
  final _registrationNumberController = TextEditingController();
  final _hospitalNameController = TextEditingController();
  final _qualificationController = TextEditingController();
  
  // Nurse field
  String _nurseShift = 'Morning';
  
  UserRole _selectedRole = UserRole.patient;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  int _currentStep = 1;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _specializationController.dispose();
    _experienceController.dispose();
    _registrationNumberController.dispose();
    _hospitalNameController.dispose();
    _qualificationController.dispose();
    super.dispose();
  }

  void _handleNext() {
    if (!_formKey.currentState!.validate()) return;
    
    if (_selectedRole == UserRole.doctor && _currentStep == 1) {
      setState(() => _currentStep = 2);
    }
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    // Prevent registration if doctor is still on step 1
    if (_selectedRole == UserRole.doctor && _currentStep == 1) {
      print('[Register] ERROR: Attempted to register doctor on step 1');
      return;
    }

    // Validate passwords match
    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Passwords do not match'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    // Validate doctor fields on step 2
    if (_selectedRole == UserRole.doctor) {
      if (_specializationController.text.trim().isEmpty ||
          _experienceController.text.trim().isEmpty ||
          _registrationNumberController.text.trim().isEmpty ||
          _hospitalNameController.text.trim().isEmpty ||
          _qualificationController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please fill all doctor registration fields'),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }
    }

    print('[Register] Starting registration for ${_selectedRole.name}');
    AppLogger.nav('Register attempt: ${_emailController.text}');

    await ref.read(authProvider.notifier).register(
      _nameController.text.trim(),
      _emailController.text.trim(),
      _passwordController.text,
      role: _selectedRole,
      phone: _phoneController.text.trim(),
      specialization: _selectedRole == UserRole.doctor 
          ? _specializationController.text.trim() 
          : null,
      experience: _selectedRole == UserRole.doctor && _experienceController.text.isNotEmpty
          ? int.tryParse(_experienceController.text.trim())
          : null,
      shift: _selectedRole == UserRole.nurse ? _nurseShift : null,
      registrationNumber: _selectedRole == UserRole.doctor
          ? _registrationNumberController.text.trim()
          : null,
      hospitalName: _selectedRole == UserRole.doctor
          ? _hospitalNameController.text.trim()
          : null,
      qualification: _selectedRole == UserRole.doctor
          ? _qualificationController.text.trim()
          : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    ref.listen(authProvider, (previous, next) {
      if (next.hasError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Registration failed: ${next.error}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    });

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.bgWarm, Colors.white],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      gradient: AppColors.goldGradient,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.goldPrimary.withValues(alpha: 0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Text('T', style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w800)),
                    ),
                  ).animate().fadeIn(duration: 400.ms).scale(begin: const Offset(0.8, 0.8)),

                  const SizedBox(height: 24),
                  Text('Create Account', style: Theme.of(context).textTheme.displayMedium).animate().fadeIn(delay: 100.ms),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _selectedRole == UserRole.doctor 
                            ? 'Step $_currentStep of 2'
                            : 'Join TeleMedCare today',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      if (_currentStep == 2 && _selectedRole == UserRole.doctor)
                        IconButton(
                          icon: const Icon(Icons.arrow_back, size: 20),
                          onPressed: () => setState(() => _currentStep = 1),
                        ),
                    ],
                  ).animate().fadeIn(delay: 150.ms),
                  const SizedBox(height: 40),

                  GlassPanel(
                    padding: const EdgeInsets.all(24),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (_currentStep == 1) ..._buildStep1Fields(),
                          if (_currentStep == 2 && _selectedRole == UserRole.doctor) 
                            ..._buildStep2DoctorFields(),

                          const SizedBox(height: 24),

                          AppButton(
                            label: _selectedRole == UserRole.doctor && _currentStep == 1
                                ? 'Next'
                                : 'Create Account',
                            variant: AppButtonVariant.primary,
                            isLoading: authState.isLoading,
                            onPressed: authState.isLoading ? null : () {
                              print('[Register] Button pressed - Role: ${_selectedRole.name}, Step: $_currentStep');
                              if (_selectedRole == UserRole.doctor && _currentStep == 1) {
                                print('[Register] Calling _handleNext');
                                _handleNext();
                              } else {
                                print('[Register] Calling _handleRegister');
                                _handleRegister();
                              }
                            },
                            width: double.infinity,
                          ),

                          const SizedBox(height: 16),

                          TextButton(
                            onPressed: () {
                              AppLogger.nav('Navigate to login');
                              context.go('/login');
                            },
                            child: RichText(
                              text: const TextSpan(
                                text: 'Already have an account? ',
                                style: TextStyle(color: AppColors.textSecondary),
                                children: [
                                  TextSpan(
                                    text: 'Sign In',
                                    style: TextStyle(color: AppColors.goldPrimary, fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.05, end: 0),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildStep1Fields() {
    return [
      // Name
      TextFormField(
        controller: _nameController,
        decoration: const InputDecoration(
          labelText: 'Full Name',
          hintText: 'John Doe',
          prefixIcon: Icon(Icons.person_outline),
        ),
        validator: (v) => (v == null || v.isEmpty) ? 'Name required' : null,
      ),
      const SizedBox(height: 16),

      // Email
      TextFormField(
        controller: _emailController,
        keyboardType: TextInputType.emailAddress,
        decoration: const InputDecoration(
          labelText: 'Email',
          hintText: 'you@example.com',
          prefixIcon: Icon(Icons.email_outlined),
        ),
        validator: (v) {
          if (v == null || v.isEmpty) return 'Email required';
          if (!v.contains('@')) return 'Invalid email';
          return null;
        },
      ),
      const SizedBox(height: 16),

      // Phone
      TextFormField(
        controller: _phoneController,
        keyboardType: TextInputType.phone,
        decoration: const InputDecoration(
          labelText: 'Phone Number',
          hintText: '+1 (555) 000-0000',
          prefixIcon: Icon(Icons.phone_outlined),
        ),
        validator: (v) => (v == null || v.isEmpty) ? 'Phone required' : null,
      ),
      const SizedBox(height: 16),

      // Role
      DropdownButtonFormField<UserRole>(
        value: _selectedRole,
        decoration: const InputDecoration(
          labelText: 'Role',
          prefixIcon: Icon(Icons.badge_outlined),
        ),
        items: UserRole.values.map((role) {
          return DropdownMenuItem(
            value: role,
            child: Text(role.name[0].toUpperCase() + role.name.substring(1)),
          );
        }).toList(),
        onChanged: (v) {
          if (v != null) setState(() => _selectedRole = v);
        },
      ),
      const SizedBox(height: 16),

      // Password (only for non-doctors on step 1, or all non-doctors)
      if (_selectedRole != UserRole.doctor) ...[
        TextFormField(
          controller: _passwordController,
          obscureText: _obscurePassword,
          decoration: InputDecoration(
            labelText: 'Password',
            hintText: '••••••••',
            prefixIcon: const Icon(Icons.lock_outline),
            suffixIcon: IconButton(
              icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
            ),
          ),
          validator: (v) {
            if (v == null || v.isEmpty) return 'Password required';
            if (v.length < 6) return 'Min 6 characters';
            return null;
          },
        ),
        const SizedBox(height: 16),

        TextFormField(
          controller: _confirmPasswordController,
          obscureText: _obscureConfirmPassword,
          decoration: InputDecoration(
            labelText: 'Confirm Password',
            hintText: '••••••••',
            prefixIcon: const Icon(Icons.lock_outline),
            suffixIcon: IconButton(
              icon: Icon(_obscureConfirmPassword ? Icons.visibility_off : Icons.visibility),
              onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
            ),
          ),
          validator: (v) {
            if (v == null || v.isEmpty) return 'Confirm password required';
            return null;
          },
        ),
      ],

      // Nurse shift
      if (_selectedRole == UserRole.nurse) ...[
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          value: _nurseShift,
          decoration: const InputDecoration(
            labelText: 'Shift',
            prefixIcon: Icon(Icons.access_time),
          ),
          items: ['Morning', 'Night'].map((shift) {
            return DropdownMenuItem(
              value: shift,
              child: Text(shift),
            );
          }).toList(),
          onChanged: (v) {
            if (v != null) setState(() => _nurseShift = v);
          },
        ),
      ],
    ];
  }

  List<Widget> _buildStep2DoctorFields() {
    return [
      // Specialization
      TextFormField(
        controller: _specializationController,
        decoration: const InputDecoration(
          labelText: 'Specialization',
          hintText: 'e.g. Cardiology',
          prefixIcon: Icon(Icons.medical_services_outlined),
        ),
        validator: (v) => (v == null || v.isEmpty) ? 'Specialization required' : null,
      ),
      const SizedBox(height: 16),

      // Experience & Registration Number
      Row(
        children: [
          Expanded(
            child: TextFormField(
              controller: _experienceController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Experience (Years)',
                hintText: 'e.g. 5',
                prefixIcon: Icon(Icons.work_outline),
              ),
              validator: (v) => (v == null || v.isEmpty) ? 'Experience required' : null,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: TextFormField(
              controller: _registrationNumberController,
              decoration: const InputDecoration(
                labelText: 'Reg. Number',
                hintText: 'Reg. ID',
                prefixIcon: Icon(Icons.badge_outlined),
              ),
              validator: (v) => (v == null || v.isEmpty) ? 'Reg. number required' : null,
            ),
          ),
        ],
      ),
      const SizedBox(height: 16),

      // Hospital Name
      TextFormField(
        controller: _hospitalNameController,
        decoration: const InputDecoration(
          labelText: 'Hospital / Clinic',
          hintText: 'Associated Hospital',
          prefixIcon: Icon(Icons.local_hospital_outlined),
        ),
        validator: (v) => (v == null || v.isEmpty) ? 'Hospital name required' : null,
      ),
      const SizedBox(height: 16),

      // Qualification
      TextFormField(
        controller: _qualificationController,
        decoration: const InputDecoration(
          labelText: 'Professional Qualification',
          hintText: 'e.g. MBBS, MD',
          prefixIcon: Icon(Icons.school_outlined),
        ),
        validator: (v) => (v == null || v.isEmpty) ? 'Qualification required' : null,
      ),
      const SizedBox(height: 16),

      // Password
      TextFormField(
        controller: _passwordController,
        obscureText: _obscurePassword,
        decoration: InputDecoration(
          labelText: 'Password',
          hintText: '••••••••',
          prefixIcon: const Icon(Icons.lock_outline),
          suffixIcon: IconButton(
            icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
          ),
        ),
        validator: (v) {
          if (v == null || v.isEmpty) return 'Password required';
          if (v.length < 6) return 'Min 6 characters';
          return null;
        },
      ),
      const SizedBox(height: 16),

      // Confirm Password
      TextFormField(
        controller: _confirmPasswordController,
        obscureText: _obscureConfirmPassword,
        decoration: InputDecoration(
          labelText: 'Confirm Password',
          hintText: '••••••••',
          prefixIcon: const Icon(Icons.lock_outline),
          suffixIcon: IconButton(
            icon: Icon(_obscureConfirmPassword ? Icons.visibility_off : Icons.visibility),
            onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
          ),
        ),
        validator: (v) {
          if (v == null || v.isEmpty) return 'Confirm password required';
          return null;
        },
      ),
    ];
  }
}
