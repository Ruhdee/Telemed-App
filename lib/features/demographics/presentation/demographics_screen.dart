import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/app_logger.dart';
import '../../../core/constants/api_constants.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/glass_panel.dart';

class DemographicsScreen extends ConsumerStatefulWidget {
  const DemographicsScreen({super.key});

  @override
  ConsumerState<DemographicsScreen> createState() => _DemographicsScreenState();
}

class _DemographicsScreenState extends ConsumerState<DemographicsScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Vital Stats
  final _ageController = TextEditingController();
  String _gender = 'Male';
  final _heightController = TextEditingController(); // cm
  final _weightController = TextEditingController(); // kg

  // Medical History
  final _medicalHistoryController = TextEditingController();
  final _medicationsController = TextEditingController();
  final _allergiesController = TextEditingController();
  final _familyHistoryController = TextEditingController();

  // Lifestyle
  bool _smoking = false;
  bool _alcohol = false;
  final _sleepController = TextEditingController(); // hours
  String _physicalActivity = 'Moderate';

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadDemographics();
    
    // Listen to height/weight changes to auto-calculate BMI
    _heightController.addListener(_updateScreen);
    _weightController.addListener(_updateScreen);
  }

  void _updateScreen() => setState(() {});

  @override
  void dispose() {
    _ageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _medicalHistoryController.dispose();
    _medicationsController.dispose();
    _allergiesController.dispose();
    _familyHistoryController.dispose();
    _sleepController.dispose();
    super.dispose();
  }

  double get _bmi {
    final heightCm = double.tryParse(_heightController.text) ?? 0;
    final weightKg = double.tryParse(_weightController.text) ?? 0;
    if (heightCm > 0 && weightKg > 0) {
      final heightM = heightCm / 100;
      return weightKg / (heightM * heightM);
    }
    return 0;
  }

  Future<void> _loadDemographics() async {
    setState(() => _isLoading = true);
    try {
      final apiClient = ref.read(apiClientProvider);
      final response = await apiClient.get(ApiConstants.demographicsEndpoint);
      if (response.data != null && response.data is Map<String, dynamic>) {
        final data = response.data['data'] as Map<String, dynamic>? ?? response.data;
        
        _ageController.text = data['age']?.toString() ?? '';
        _gender = data['gender'] ?? 'Male';
        _heightController.text = data['height']?.toString() ?? '';
        _weightController.text = data['weight']?.toString() ?? '';
        
        _medicalHistoryController.text = data['medicalHistory'] ?? '';
        _medicationsController.text = data['currentMedications'] ?? '';
        _allergiesController.text = data['allergies'] ?? '';
        _familyHistoryController.text = data['familyHistory'] ?? '';
        
        _smoking = data['smoking'] ?? false;
        _alcohol = data['alcohol'] ?? false;
        _sleepController.text = data['sleepHours']?.toString() ?? '';
        _physicalActivity = data['physicalActivity'] ?? 'Moderate';
      }
    } catch (e) {
      AppLogger.error('Demographics', 'Failed to load', e);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveDemographics() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    try {
      final apiClient = ref.read(apiClientProvider);
      final age = int.tryParse(_ageController.text) ?? 0;
      final height = double.tryParse(_heightController.text) ?? 0;
      final weight = double.tryParse(_weightController.text) ?? 0;
      final sleep = int.tryParse(_sleepController.text) ?? 0;

      final data = {
        'age': age,
        'gender': _gender,
        'height': height,
        'weight': weight,
        'bmi': _bmi,
        'medicalHistory': _medicalHistoryController.text,
        'currentMedications': _medicationsController.text,
        'allergies': _allergiesController.text,
        'familyHistory': _familyHistoryController.text,
        'smoking': _smoking,
        'alcohol': _alcohol,
        'sleepHours': sleep,
        'physicalActivity': _physicalActivity,
      };

      await apiClient.post(ApiConstants.demographicsEndpoint, data: data);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Health Profile Saved Successfully'), backgroundColor: AppColors.success),
        );
      }
    } catch (e) {
      AppLogger.error('Demographics', 'Failed to save', e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save profile: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _ageController.text.isEmpty) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('My Health Profile')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle('Vital Statistics', LucideIcons.activity),
              GlassPanel(
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(child: _buildTextField('Age', _ageController, TextInputType.number)),
                        const SizedBox(width: 16),
                        Expanded(child: _buildDropdown('Gender', _gender, ['Male', 'Female', 'Other'], (v) => setState(() => _gender = v!))),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(child: _buildTextField('Height (cm)', _heightController, TextInputType.number)),
                        const SizedBox(width: 16),
                        Expanded(child: _buildTextField('Weight (kg)', _weightController, TextInputType.number)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.goldPrimary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Calculated BMI', style: TextStyle(fontWeight: FontWeight.bold)),
                          Text(
                            _bmi > 0 ? _bmi.toStringAsFixed(1) : '--',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: _bmi > 25 ? AppColors.error : AppColors.success,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),
              _buildSectionTitle('Medical History', LucideIcons.fileText),
              GlassPanel(
                child: Column(
                  children: [
                    _buildTextField('Past Medical History', _medicalHistoryController, TextInputType.text, maxLines: 2),
                    const SizedBox(height: 16),
                    _buildTextField('Current Medications', _medicationsController, TextInputType.text, maxLines: 2),
                    const SizedBox(height: 16),
                    _buildTextField('Allergies', _allergiesController, TextInputType.text),
                    const SizedBox(height: 16),
                    _buildTextField('Family History', _familyHistoryController, TextInputType.text),
                  ],
                ),
              ),

              const SizedBox(height: 24),
              _buildSectionTitle('Lifestyle', LucideIcons.heart),
              GlassPanel(
                child: Column(
                  children: [
                    SwitchListTile(
                      title: const Text('Do you smoke?'),
                      value: _smoking,
                      onChanged: (v) => setState(() => _smoking = v),
                      contentPadding: EdgeInsets.zero,
                    ),
                    SwitchListTile(
                      title: const Text('Do you consume alcohol?'),
                      value: _alcohol,
                      onChanged: (v) => setState(() => _alcohol = v),
                      contentPadding: EdgeInsets.zero,
                    ),
                    const SizedBox(height: 8),
                    _buildTextField('Average Sleep (Hours)', _sleepController, TextInputType.number),
                    const SizedBox(height: 16),
                    _buildDropdown(
                      'Physical Activity Level',
                      _physicalActivity,
                      ['Sedentary', 'Light', 'Moderate', 'Active', 'Very Active'],
                      (v) => setState(() => _physicalActivity = v!),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),
              AppButton(
                label: 'Save Health Profile',
                variant: AppButtonVariant.primary,
                width: double.infinity,
                isLoading: _isLoading,
                onPressed: _saveDemographics,
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.goldPrimary),
          const SizedBox(width: 8),
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, TextInputType type, {int maxLines = 1}) {
    return TextFormField(
      controller: controller,
      keyboardType: type,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
      validator: (v) {
        if (v == null || v.isEmpty) return 'Required';
        return null;
      },
    );
  }

  Widget _buildDropdown(String label, String value, List<String> options, ValueChanged<String?> onChanged) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
      items: options.map((o) => DropdownMenuItem(value: o, child: Text(o))).toList(),
      onChanged: onChanged,
    );
  }
}
