import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

enum InputType { number, text, select, image }

class DiseaseInputOption {
  final String label;
  final dynamic value;
  const DiseaseInputOption({required this.label, required this.value});
}

class DiseaseInput {
  final String key;
  final String label;
  final InputType type;
  final List<DiseaseInputOption>? options;
  final String? placeholder;
  final num? min;
  final num? max;
  final num? step;

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

enum DiseaseModelType { tabular, image }

class DiseaseConfig {
  final String id;
  final String name;
  final String description;
  final IconData icon;
  final DiseaseModelType type;
  final String endpoint;
  final List<DiseaseInput> inputs;

  const DiseaseConfig({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.type,
    required this.endpoint,
    this.inputs = const [],
  });
}

const List<DiseaseConfig> diseaseModels = [
  // --- Tabular Models ---
  DiseaseConfig(
    id: 'heart-disease',
    name: 'Heart Disease',
    description: 'Predict heart disease risk based on cardiovascular metrics.',
    icon: LucideIcons.heart,
    type: DiseaseModelType.tabular,
    endpoint: '/api/predict/heart',
    inputs: [
      DiseaseInput(key: 'age', label: 'Age', type: InputType.number, min: 1, max: 120),
      DiseaseInput(key: 'sex', label: 'Sex', type: InputType.select, options: [DiseaseInputOption(label: 'Male', value: 1), DiseaseInputOption(label: 'Female', value: 0)]),
      DiseaseInput(key: 'cp', label: 'Chest Pain Type', type: InputType.select, options: [DiseaseInputOption(label: 'Typical Angina', value: 0), DiseaseInputOption(label: 'Atypical Angina', value: 1), DiseaseInputOption(label: 'Non-anginal Pain', value: 2), DiseaseInputOption(label: 'Asymptomatic', value: 3)]),
      DiseaseInput(key: 'trestbps', label: 'Resting Blood Pressure (mm Hg)', type: InputType.number, min: 80, max: 200),
      DiseaseInput(key: 'chol', label: 'Serum Cholestoral (mg/dl)', type: InputType.number, min: 100, max: 600),
      DiseaseInput(key: 'fbs', label: 'Fasting Blood Sugar > 120 mg/dl', type: InputType.select, options: [DiseaseInputOption(label: 'True', value: 1), DiseaseInputOption(label: 'False', value: 0)]),
      DiseaseInput(key: 'restecg', label: 'Resting ECG Results', type: InputType.select, options: [DiseaseInputOption(label: 'Normal', value: 0), DiseaseInputOption(label: 'ST-T Wave Abnormality', value: 1), DiseaseInputOption(label: 'Left Ventricular Hypertrophy', value: 2)]),
      DiseaseInput(key: 'thalach', label: 'Max Heart Rate Achieved', type: InputType.number, min: 60, max: 220),
      DiseaseInput(key: 'exang', label: 'Exercise Induced Angina', type: InputType.select, options: [DiseaseInputOption(label: 'Yes', value: 1), DiseaseInputOption(label: 'No', value: 0)]),
      DiseaseInput(key: 'oldpeak', label: 'ST Depression Induced by Exercise', type: InputType.number, step: 0.1),
      DiseaseInput(key: 'slope', label: 'Slope of Peak Exercise ST Segment', type: InputType.select, options: [DiseaseInputOption(label: 'Upsloping', value: 0), DiseaseInputOption(label: 'Flat', value: 1), DiseaseInputOption(label: 'Downsloping', value: 2)]),
      DiseaseInput(key: 'ca', label: 'Number of Major Vessels', type: InputType.number, min: 0, max: 3),
      DiseaseInput(key: 'thal', label: 'Thalassemia', type: InputType.select, options: [DiseaseInputOption(label: 'Normal', value: 1), DiseaseInputOption(label: 'Fixed Defect', value: 2), DiseaseInputOption(label: 'Reversable Defect', value: 3)]),
    ],
  ),
  DiseaseConfig(
    id: 'diabetes',
    name: 'Diabetes',
    description: 'Assess the likelihood of diabetes based on health indicators.',
    icon: LucideIcons.syringe,
    type: DiseaseModelType.tabular,
    endpoint: '/api/predict/diabetes',
    inputs: [
      DiseaseInput(key: 'Pregnancies', label: 'Number of Pregnancies', type: InputType.number, min: 0, max: 20),
      DiseaseInput(key: 'Glucose', label: 'Glucose Level', type: InputType.number, min: 0, max: 300),
      DiseaseInput(key: 'BloodPressure', label: 'Blood Pressure', type: InputType.number, min: 0, max: 200),
      DiseaseInput(key: 'SkinThickness', label: 'Skin Thickness', type: InputType.number, min: 0, max: 100),
      DiseaseInput(key: 'Insulin', label: 'Insulin Level', type: InputType.number, min: 0, max: 900),
      DiseaseInput(key: 'BMI', label: 'BMI', type: InputType.number, step: 0.1, min: 10, max: 60),
      DiseaseInput(key: 'DiabetesPedigreeFunction', label: 'Diabetes Pedigree Function', type: InputType.number, step: 0.001),
      DiseaseInput(key: 'Age', label: 'Age', type: InputType.number, min: 1, max: 120),
    ],
  ),
  DiseaseConfig(
    id: 'liver-disease',
    name: 'Liver Disease',
    description: 'Screen for liver disease using blood markers.',
    icon: LucideIcons.activity,
    type: DiseaseModelType.tabular,
    endpoint: '/api/predict/liver',
    inputs: [
      DiseaseInput(key: 'age', label: 'Age', type: InputType.number, min: 1, max: 120),
      DiseaseInput(key: 'gender', label: 'Gender', type: InputType.select, options: [DiseaseInputOption(label: 'Male', value: 1), DiseaseInputOption(label: 'Female', value: 0)]),
      DiseaseInput(key: 'total_bilirubin', label: 'Total Bilirubin', type: InputType.number, step: 0.1),
      DiseaseInput(key: 'direct_bilirubin', label: 'Direct Bilirubin', type: InputType.number, step: 0.1),
      DiseaseInput(key: 'alkphos', label: 'Alkaline Phosphotase', type: InputType.number),
      DiseaseInput(key: 'sgpt', label: 'Alamine Aminotransferase', type: InputType.number),
      DiseaseInput(key: 'sgot', label: 'Aspartate Aminotransferase', type: InputType.number),
      DiseaseInput(key: 'total_proteins', label: 'Total Proteins', type: InputType.number, step: 0.1),
      DiseaseInput(key: 'albumin', label: 'Albumin', type: InputType.number, step: 0.1),
      DiseaseInput(key: 'ag_ratio', label: 'Albumin and Globulin Ratio', type: InputType.number, step: 0.1),
    ],
  ),
  DiseaseConfig(
    id: 'kidney-disease',
    name: 'Kidney Disease (CKD)',
    description: 'Chronic Kidney Disease prediction.',
    icon: LucideIcons.activity,
    type: DiseaseModelType.tabular,
    endpoint: '/api/predict/ckd',
    inputs: [
      DiseaseInput(key: 'age', label: 'Age', type: InputType.number),
      DiseaseInput(key: 'bp', label: 'Blood Pressure', type: InputType.number),
      DiseaseInput(key: 'sg', label: 'Specific Gravity', type: InputType.number, step: 0.005),
      DiseaseInput(key: 'al', label: 'Albumin', type: InputType.number),
      DiseaseInput(key: 'su', label: 'Sugar', type: InputType.number),
      DiseaseInput(key: 'rbc', label: 'Red Blood Cells', type: InputType.select, options: [DiseaseInputOption(label: 'Normal', value: 1), DiseaseInputOption(label: 'Abnormal', value: 0)]),
      DiseaseInput(key: 'pc', label: 'Pus Cell', type: InputType.select, options: [DiseaseInputOption(label: 'Normal', value: 1), DiseaseInputOption(label: 'Abnormal', value: 0)]),
      DiseaseInput(key: 'pcc', label: 'Pus Cell Clumps', type: InputType.select, options: [DiseaseInputOption(label: 'Present', value: 1), DiseaseInputOption(label: 'Not Present', value: 0)]),
      DiseaseInput(key: 'ba', label: 'Bacteria', type: InputType.select, options: [DiseaseInputOption(label: 'Present', value: 1), DiseaseInputOption(label: 'Not Present', value: 0)]),
      DiseaseInput(key: 'bgr', label: 'Blood Glucose Random', type: InputType.number),
      DiseaseInput(key: 'bu', label: 'Blood Urea', type: InputType.number),
      DiseaseInput(key: 'sc', label: 'Serum Creatinine', type: InputType.number, step: 0.1),
      DiseaseInput(key: 'sod', label: 'Sodium', type: InputType.number),
      DiseaseInput(key: 'pot', label: 'Potassium', type: InputType.number, step: 0.1),
      DiseaseInput(key: 'hemo', label: 'Hemoglobin', type: InputType.number, step: 0.1),
      DiseaseInput(key: 'pcv', label: 'Packed Cell Volume', type: InputType.number),
      DiseaseInput(key: 'wc', label: 'White Blood Cell Count', type: InputType.number),
      DiseaseInput(key: 'rc', label: 'Red Blood Cell Count', type: InputType.number, step: 0.1),
      DiseaseInput(key: 'htn', label: 'Hypertension', type: InputType.select, options: [DiseaseInputOption(label: 'Yes', value: 1), DiseaseInputOption(label: 'No', value: 0)]),
      DiseaseInput(key: 'dm', label: 'Diabetes Mellitus', type: InputType.select, options: [DiseaseInputOption(label: 'Yes', value: 1), DiseaseInputOption(label: 'No', value: 0)]),
      DiseaseInput(key: 'cad', label: 'Coronary Artery Disease', type: InputType.select, options: [DiseaseInputOption(label: 'Yes', value: 1), DiseaseInputOption(label: 'No', value: 0)]),
      DiseaseInput(key: 'appet', label: 'Appetite', type: InputType.select, options: [DiseaseInputOption(label: 'Good', value: 1), DiseaseInputOption(label: 'Poor', value: 0)]),
      DiseaseInput(key: 'pe', label: 'Pedal Edema', type: InputType.select, options: [DiseaseInputOption(label: 'Yes', value: 1), DiseaseInputOption(label: 'No', value: 0)]),
      DiseaseInput(key: 'ane', label: 'Anemia', type: InputType.select, options: [DiseaseInputOption(label: 'Yes', value: 1), DiseaseInputOption(label: 'No', value: 0)]),
    ],
  ),

  // --- Image Models ---
  DiseaseConfig(
    id: 'pneumonia',
    name: 'Pneumonia Detection',
    description: 'Upload a Chest X-ray to detect pneumonia.',
    icon: LucideIcons.image,
    type: DiseaseModelType.image,
    endpoint: '/api/predict/pneumonia',
  ),
  DiseaseConfig(
    id: 'tuberculosis',
    name: 'Tuberculosis (TB)',
    description: 'Upload a Chest X-ray to screen for TB.',
    icon: LucideIcons.image,
    type: DiseaseModelType.image,
    endpoint: '/api/predict/tb',
  ),
  DiseaseConfig(
    id: 'brain-tumor',
    name: 'Brain Tumor',
    description: 'Upload an MRI scan to detect brain tumors.',
    icon: LucideIcons.brain,
    type: DiseaseModelType.image,
    endpoint: '/api/predict/brain-tumor',
  ),
  DiseaseConfig(
    id: 'retinopathy',
    name: 'Diabetic Retinopathy',
    description: 'Upload a retinal scan image.',
    icon: LucideIcons.eye,
    type: DiseaseModelType.image,
    endpoint: '/api/predict/retinopathy',
  ),
  DiseaseConfig(
    id: 'skin-disease',
    name: 'Skin Disease',
    description: 'Upload an image of the skin condition.',
    icon: LucideIcons.thermometer,
    type: DiseaseModelType.image,
    endpoint: '/api/predict/skin',
  ),
];
