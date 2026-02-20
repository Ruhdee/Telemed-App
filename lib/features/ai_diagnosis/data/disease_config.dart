import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

/// Disease configuration matching the React `diseaseConfig.ts`.
///
/// Defines 8 disease models with their input fields, icons, and configuration.

enum InputType { number, text, select, image }

class DiseaseInput {
  final String key;
  final String label;
  final InputType type;
  final List<({String label, dynamic value})>? options;
  final String? placeholder;
  final double? min;
  final double? max;
  final double? step;

  const DiseaseInput({
    required this.key,
    required this.label,
    required this.type,
    this.options,
    this.placeholder,
    this.min,
    this.max,
    this.step,
  });
}

class DiseaseConfig {
  final String id;
  final String name;
  final String description;
  final IconData icon;
  final List<DiseaseInput> inputs;

  /// Backend route slug under `/api/predict/`.
  /// e.g. `heart` → POST `/api/predict/heart`
  final String endpoint;

  const DiseaseConfig({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.inputs,
    required this.endpoint,
  });
}

/// All disease models available in the AI diagnosis section.
final List<DiseaseConfig> diseaseModels = [
  DiseaseConfig(
    id: 'heart-disease',
    endpoint: 'heart',
    name: 'Heart Disease',
    description: 'Predict cardiovascular risk factors using patient metrics.',
    icon: LucideIcons.heart,
    inputs: [
      DiseaseInput(key: 'age', label: 'Age', type: InputType.number, min: 1, max: 120),
      DiseaseInput(key: 'sex', label: 'Sex', type: InputType.select, options: [(label: 'Male', value: 1), (label: 'Female', value: 0)]),
      DiseaseInput(key: 'cp', label: 'Chest Pain Type', type: InputType.select, options: [(label: 'Typical Angina', value: 0), (label: 'Atypical Angina', value: 1), (label: 'Non-anginal', value: 2), (label: 'Asymptomatic', value: 3)]),
      DiseaseInput(key: 'trestbps', label: 'Resting BP (mmHg)', type: InputType.number, min: 80, max: 200),
      DiseaseInput(key: 'chol', label: 'Cholesterol (mg/dl)', type: InputType.number, min: 100, max: 600),
      DiseaseInput(key: 'thalach', label: 'Max Heart Rate', type: InputType.number, min: 60, max: 220),
    ],
  ),
  DiseaseConfig(
    id: 'diabetes',
    endpoint: 'diabetes',
    name: 'Diabetes',
    description: 'Assess diabetes risk using health indicators.',
    icon: LucideIcons.syringe,
    inputs: [
      DiseaseInput(key: 'Pregnancies', label: 'Pregnancies', type: InputType.number, min: 0, max: 20),
      DiseaseInput(key: 'Glucose', label: 'Glucose Level', type: InputType.number, min: 0, max: 300),
      DiseaseInput(key: 'BloodPressure', label: 'Blood Pressure', type: InputType.number, min: 0, max: 200),
      DiseaseInput(key: 'BMI', label: 'BMI', type: InputType.number, min: 10, max: 60, step: 0.1),
      DiseaseInput(key: 'Age', label: 'Age', type: InputType.number, min: 1, max: 120),
    ],
  ),
  DiseaseConfig(
    id: 'parkinsons',
    endpoint: 'parkinsons',
    name: "Parkinson's Disease",
    description: 'Detect early signs of Parkinson\'s from voice metrics.',
    icon: LucideIcons.brain,
    inputs: [
      DiseaseInput(key: 'fo', label: 'Avg Vocal Freq (Hz)', type: InputType.number, min: 50, max: 300, step: 0.01),
      DiseaseInput(key: 'fhi', label: 'Max Vocal Freq (Hz)', type: InputType.number, min: 50, max: 600, step: 0.01),
      DiseaseInput(key: 'flo', label: 'Min Vocal Freq (Hz)', type: InputType.number, min: 50, max: 300, step: 0.01),
    ],
  ),
  DiseaseConfig(
    id: 'breast-cancer',
    endpoint: 'breast-cancer',
    name: 'Breast Cancer',
    description: 'Evaluate breast cancer indicators from cell measurements.',
    icon: LucideIcons.fileText,
    inputs: [
      DiseaseInput(key: 'radius_mean', label: 'Mean Radius', type: InputType.number, min: 0, max: 30, step: 0.01),
      DiseaseInput(key: 'texture_mean', label: 'Mean Texture', type: InputType.number, min: 0, max: 40, step: 0.01),
      DiseaseInput(key: 'perimeter_mean', label: 'Mean Perimeter', type: InputType.number, min: 0, max: 200, step: 0.01),
    ],
  ),
  DiseaseConfig(
    id: 'liver-disease',
    endpoint: 'liver',
    name: 'Liver Disease',
    description: 'Assess liver health based on blood test results.',
    icon: LucideIcons.activity,
    inputs: [
      DiseaseInput(key: 'Age', label: 'Age', type: InputType.number, min: 1, max: 120),
      DiseaseInput(key: 'Total_Bilirubin', label: 'Total Bilirubin', type: InputType.number, min: 0, max: 80, step: 0.1),
      DiseaseInput(key: 'Alkaline_Phosphotase', label: 'Alkaline Phosphatase', type: InputType.number, min: 0, max: 2500),
    ],
  ),
  DiseaseConfig(
    id: 'kidney-disease',
    endpoint: 'ckd',
    name: 'Kidney Disease',
    description: 'Evaluate kidney function from clinical parameters.',
    icon: LucideIcons.thermometer,
    inputs: [
      DiseaseInput(key: 'age', label: 'Age', type: InputType.number, min: 1, max: 120),
      DiseaseInput(key: 'bp', label: 'Blood Pressure', type: InputType.number, min: 50, max: 180),
      DiseaseInput(key: 'sg', label: 'Specific Gravity', type: InputType.number, min: 1.0, max: 1.03, step: 0.005),
      DiseaseInput(key: 'su', label: 'Sugar', type: InputType.select, options: [(label: '0', value: 0), (label: '1', value: 1), (label: '2', value: 2), (label: '3', value: 3)]),
    ],
  ),
  DiseaseConfig(
    id: 'hepatitis',
    endpoint: 'hepatitis',
    name: 'Hepatitis',
    description: 'Screen for hepatitis using clinical symptoms and tests.',
    icon: LucideIcons.eye,
    inputs: [
      DiseaseInput(key: 'Age', label: 'Age', type: InputType.number, min: 1, max: 120),
      DiseaseInput(key: 'Sex', label: 'Sex', type: InputType.select, options: [(label: 'Male', value: 1), (label: 'Female', value: 2)]),
      DiseaseInput(key: 'ALB', label: 'Albumin', type: InputType.number, min: 0, max: 10, step: 0.1),
      DiseaseInput(key: 'ALP', label: 'Alkaline Phosphatase', type: InputType.number, min: 0, max: 500),
    ],
  ),
  DiseaseConfig(
    id: 'pneumonia',
    endpoint: 'pneumonia',
    name: 'Pneumonia Detection',
    description: 'Detect pneumonia from chest X-ray images using AI.',
    icon: LucideIcons.image,
    inputs: [
      DiseaseInput(key: 'image', label: 'Chest X-Ray Image', type: InputType.image, placeholder: 'Upload chest X-ray'),
    ],
  ),
];
