import 'package:flutter/material.dart';
import 'form_field_builders.dart';

/// Nutrition and Dietetics Form Templates
class NutritionServiceForms {
  NutritionServiceForms._();

  /// Get form fields for nutrition service templates
  /// [readOnlyFieldKeys] - When non-null, fields whose key is in this set are read-only (e.g. resident-sourced).
  static List<Widget> getFormFields(
    String templateType,
    Map<String, dynamic> data,
    void Function(String, dynamic) onChanged, {
    bool readOnly = false,
    Set<String>? readOnlyFieldKeys,
    List<String>? residentNames,
    List<dynamic>? residents,
  }) {
    bool ro(String key) => readOnly || (readOnlyFieldKeys?.contains(key) ?? false);
    switch (templateType) {
      case 'nt_screening':
        return _nutritionScreening(data, onChanged,
            residentNames: residentNames, residents: residents);
      case 'nt_meal_plan':
        return _mealPlan(data, onChanged,
            residentNames: residentNames, residents: residents);
      case 'nt_diet_diary':
        return _dietDiary(data, onChanged);
      case 'nt_diet_orders':
        return _dietOrders(data, onChanged, residentNames: residentNames);
      case 'nt_malnourished_list':
        return _malnourishedList(data, onChanged, residentNames: residentNames);
      case 'nt_ncp_mnt':
        return _ncpMnt(data, onChanged, ro: ro);
      case 'nt_progress_notes':
        return _progressNotes(data, onChanged, ro: ro);
      case 'nt_status_summary':
        return _statusSummary(data, onChanged,
            residentNames: residentNames, residents: residents);
      case 'nt_bmi_summary':
        return _bmiSummary(data, onChanged,
            residentNames: residentNames, residents: residents);
      case 'nt_dietary_kardex':
        return _dietaryKardex(data, onChanged,
            residentNames: residentNames, residents: residents);
      default:
        return [const Text('Unknown form type')];
    }
  }

  static bool _defaultRo(String key) => false;

  // 1. DSWD 11 Nutrition Screening Form
  static List<Widget> _nutritionScreening(
    Map<String, dynamic> data,
    void Function(String, dynamic) onChanged, {
    List<String>? residentNames,
    List<dynamic>? residents,
  }) {
    // Helper for tallying
    void recalculateScores(Map<String, dynamic> currentData) {
      // 1. Screening Score (A-F)
      double screeningScore = 0;
      for (var letter in ['a', 'b', 'c', 'd', 'e', 'f']) {
        final val = double.tryParse(currentData['mna_${letter}_score'] ?? '0');
        if (val != null) screeningScore += val;
      }
      onChanged('screening_score', screeningScore.toString());
      onChanged('scr_b1', screeningScore.toString()); // Box 1 match

      // 2. Section K Score
      int kYesCount = 0;
      if (currentData['chk_k1y'] == true) kYesCount++;
      if (currentData['chk_k2y'] == true) kYesCount++;
      if (currentData['chk_k3y'] == true) kYesCount++;

      double kScore = 0.0;
      if (kYesCount == 2) kScore = 0.5;
      if (kYesCount == 3) kScore = 1.0;
      onChanged('mna_k_score', kScore.toString());

      // 3. Assessment Score (G-R)
      double assessmentScore = 0;
      // Questions G, H, I, J, L, M, N, O, P, Q, R (K is handled separately)
      for (var letter in ['g', 'h', 'i', 'j', 'l', 'n', 'o', 'p', 'q', 'r']) {
        final val = double.tryParse(currentData['mna_${letter}_score'] ?? '0');
        if (val != null) assessmentScore += val;
      }
      // Add K and M specifically
      assessmentScore += kScore;
      final mVal = double.tryParse(currentData['mna_m_score'] ?? '0');
      if (mVal != null) assessmentScore += mVal;

      onChanged('assessment_score', assessmentScore.toString());

      // 4. Total Assessment Score
      double totalScore = screeningScore + assessmentScore;
      onChanged('total_assessment_score', totalScore.toString());

      // 5. Malnutrition Indicator
      String indicator = '';
      if (totalScore >= 24) {
        indicator = 'Normal (24 to 30 points)';
      } else if (totalScore >= 17) {
        indicator = 'At risk of malnutrition (17 to 23.5 points)';
      } else {
        indicator = 'Malnourished (Less than 17 points)';
      }
      onChanged('indicator_result', indicator);
      onChanged('chk_indicator_normal', indicator.startsWith('Normal'));
      onChanged('chk_indicator_at_risk', indicator.contains('At risk'));
      onChanged(
          'chk_indicator_malnourished', indicator.startsWith('Malnourished'));
    }

    // Set initial date
    if (data['date'] == null) {
      onChanged('date', DateTime.now().toIso8601String());
    }

    return [
      FormFieldBuilders.sectionHeader('BASIC INFORMATION'),
      FormFieldBuilders.typeAhead(
        label: 'Name of Client',
        value: (data['client_name'] ?? '') as String,
        additionalSuggestions: residentNames ?? [],
        onChanged: (v) {
          onChanged('client_name', v);
          if (residents != null) {
            try {
              final resident = residents.firstWhere(
                (r) =>
                    '${r['first_name']} ${r['last_name']}'.toUpperCase() ==
                    v.toUpperCase(),
                orElse: () => null,
              );
              if (resident != null) {
                onChanged('age', resident['age']?.toString() ?? '');
                onChanged('sex', resident['gender'] ?? 'Male');
                onChanged('address', resident['address'] ?? '');
                onChanged('hrn', resident['resident_code'] ?? '');
                onChanged('ward', resident['ward_name'] ?? '');
                onChanged('diagnosis', resident['primary_diagnosis'] ?? '');
                if (resident['date_of_birth'] != null) {
                  onChanged('birthdate', resident['date_of_birth']);
                }
              }
            } catch (_) {}
          }
        },
        required: true,
      ),
      FormFieldBuilders.textField(
        label: 'Address',
        value: data['address'] ?? '',
        onChanged: (v) => onChanged('address', v),
      ),
      Row(
        children: [
          Expanded(
            child: FormFieldBuilders.textField(
              label: 'Age',
              value: data['age']?.toString() ?? '',
              keyboardType: TextInputType.number,
              onChanged: (v) => onChanged('age', int.tryParse(v)),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: FormFieldBuilders.dropdown(
              label: 'Sex',
              value: data['sex'] ?? 'Male',
              items: const ['Male', 'Female'],
              onChanged: (v) => onChanged('sex', v),
            ),
          ),
        ],
      ),
      Row(
        children: [
          Expanded(
            child: FormFieldBuilders.datePicker(
              label: 'Date',
              value: data['date'],
              onChanged: (v) => onChanged('date', v?.toIso8601String()),
              required: true,
            ),
          ),
        ],
      ),
      Row(
        children: [
          Expanded(
            child: FormFieldBuilders.textField(
              label: 'HRN (Case No.)',
              value: data['hrn'] ?? '',
              onChanged: (v) => onChanged('hrn', v),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: FormFieldBuilders.textField(
              label: 'Ward/Rm No.',
              value: data['ward'] ?? '',
              onChanged: (v) => onChanged('ward', v),
            ),
          ),
        ],
      ),
      Row(
        children: [
          Expanded(
            child: FormFieldBuilders.textField(
              label: 'Height (cm)',
              value: data['height_cm']?.toString(),
              keyboardType: TextInputType.number,
              onChanged: (v) {
                final height = double.tryParse(v);
                onChanged('height_cm', height);
                data['height_cm'] = height;
                _calculateBmiAndMna(data, onChanged, recalculateScores);
              },
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: FormFieldBuilders.textField(
              label: 'Weight (kg)',
              value: data['weight_kg']?.toString(),
              keyboardType: TextInputType.number,
              onChanged: (v) {
                final weight = double.tryParse(v);
                onChanged('weight_kg', weight);
                data['weight_kg'] = weight;
                _calculateBmiAndMna(data, onChanged, recalculateScores);
              },
            ),
          ),
        ],
      ),
      const SizedBox(height: 24),
      FormFieldBuilders.sectionHeader('PART I: NUTRITION RISK CLASSIFICATION'),
      FormFieldBuilders.infoText('A. CLINICAL CONDITION'),
      FormFieldBuilders.checkbox(
        label: 'Anorexia Nervosa',
        value: data['chk_anorexia_nervosa'] ?? false,
        onChanged: (v) => onChanged('chk_anorexia_nervosa', v),
      ),
      FormFieldBuilders.checkbox(
        label: 'Cachexia',
        value: data['chk_cachexia'] ?? false,
        onChanged: (v) => onChanged('chk_cachexia', v),
      ),
      FormFieldBuilders.checkbox(
        label: 'Cerebrovascular accident',
        value: data['chk_cerebrovascular_accident'] ?? false,
        onChanged: (v) => onChanged('chk_cerebrovascular_accident', v),
      ),
      FormFieldBuilders.checkbox(
        label: 'Coma',
        value: data['chk_coma'] ?? false,
        onChanged: (v) => onChanged('chk_coma', v),
      ),
      FormFieldBuilders.checkbox(
        label: 'Diabetes Mellitus',
        value: data['chk_diabetes_mellitus'] ?? false,
        onChanged: (v) => onChanged('chk_diabetes_mellitus', v),
      ),
      FormFieldBuilders.checkbox(
        label: 'Gastrointestinal disease',
        value: data['chk_gastrointestinal_disease'] ?? false,
        onChanged: (v) => onChanged('chk_gastrointestinal_disease', v),
      ),
      FormFieldBuilders.checkbox(
        label: 'Liver disease',
        value: data['chk_liver_disease'] ?? false,
        onChanged: (v) => onChanged('chk_liver_disease', v),
      ),
      FormFieldBuilders.checkbox(
        label: 'Malabsorption',
        value: data['chk_malabsorption'] ?? false,
        onChanged: (v) => onChanged('chk_malabsorption', v),
      ),
      FormFieldBuilders.checkbox(
        label: 'Multiple Trauma',
        value: data['chk_multiple_trauma'] ?? false,
        onChanged: (v) => onChanged('chk_multiple_trauma', v),
      ),
      FormFieldBuilders.checkbox(
        label: 'Non-healing wounds',
        value: data['chk_non_healing_wounds'] ?? false,
        onChanged: (v) => onChanged('chk_non_healing_wounds', v),
      ),
      FormFieldBuilders.checkbox(
        label: 'On tube feeding',
        value: data['chk_on_tube_feeding'] ?? false,
        onChanged: (v) => onChanged('chk_on_tube_feeding', v),
      ),
      FormFieldBuilders.checkbox(
        label: 'Renal Disease',
        value: data['chk_renal_disease'] ?? false,
        onChanged: (v) => onChanged('chk_renal_disease', v),
      ),
      FormFieldBuilders.checkbox(
        label: 'Sepsis',
        value: data['chk_sepsis'] ?? false,
        onChanged: (v) => onChanged('chk_sepsis', v),
      ),
      FormFieldBuilders.checkbox(
        label: 'Serum albumin <3.5 gm/L',
        value: data['chk_serum_albumin_low'] ?? false,
        onChanged: (v) => onChanged('chk_serum_albumin_low', v),
      ),
      const SizedBox(height: 16),
      FormFieldBuilders.infoText('B. INTAKE/WEIGHT HISTORY'),
      FormFieldBuilders.checkbox(
        label: 'Unintentional weight loss in the past 3 months',
        value: data['chk_unintentional_weight_loss'] ?? false,
        onChanged: (v) => onChanged('chk_unintentional_weight_loss', v),
      ),
      FormFieldBuilders.checkbox(
        label: 'Reduced dietary intake',
        value: data['chk_reduced_dietary_intake'] ?? false,
        onChanged: (v) => onChanged('chk_reduced_dietary_intake', v),
      ),
      FormFieldBuilders.checkbox(
        label: 'BMI below 18.5 and above 30',
        value: data['chk_bmi_below_18_5_or_above_30'] ?? false,
        onChanged: (v) => onChanged('chk_bmi_below_18_5_or_above_30', v),
      ),
      const SizedBox(height: 24),
      FormFieldBuilders.sectionHeader(
          'PART II: MINI-NUTRITION ASSESSMENT (MNA)'),
      FormFieldBuilders.infoText('SCREENING'),
      _buildMnaDropdownSelection(
        'A. Has food intake declined over the past 3 months due to loss of appetite, digestive problems, chewing or swallowing difficulties?',
        'mna_a_score',
        const [
          '0 = severe decrease',
          '1 = moderate decrease',
          '2 = no decrease'
        ],
        data['mna_a_score'],
        (key, val) {
          onChanged(key, val);
          data[key] = val; // Update local map for immediate tally
          recalculateScores(data);
        },
      ),
      _buildMnaDropdownSelection(
        'B. Weight loss during the last 3 months',
        'mna_b_score',
        const [
          '0 = weight loss greater than 3kg',
          '1 = does not know',
          '2 = weight loss between 1 and 3kg',
          '3 = no weight loss'
        ],
        data['mna_b_score'],
        (key, val) {
          onChanged(key, val);
          data[key] = val;
          recalculateScores(data);
        },
      ),
      _buildMnaDropdownSelection(
        'C. Mobility',
        'mna_c_score',
        const [
          '0 = bed or chair bound',
          '1 = able to get out of bed/chair but does not go out',
          '2 = goes out'
        ],
        data['mna_c_score'],
        (key, val) {
          onChanged(key, val);
          data[key] = val;
          recalculateScores(data);
        },
      ),
      _buildMnaDropdownSelection(
        'D. Has suffered psychological stress or acute disease in the past 3 months?',
        'mna_d_score',
        const ['0 = yes', '2 = no'],
        data['mna_d_score'],
        (key, val) {
          onChanged(key, val);
          data[key] = val;
          recalculateScores(data);
        },
      ),
      _buildMnaDropdownSelection(
        'E. Neuropsychological problems',
        'mna_e_score',
        const [
          '0 = severe dementia or depression',
          '1 = mild dementia',
          '2 = no psychological problems'
        ],
        data['mna_e_score'],
        (key, val) {
          onChanged(key, val);
          data[key] = val;
          recalculateScores(data);
        },
      ),
      _buildMnaDropdownSelection(
        'F. Body Mass Index (BMI)',
        'mna_f_score',
        const [
          '0 = BMI less than 19',
          '1 = BMI 19 to less than 21',
          '2 = BMI 21 to less than 23',
          '3 = BMI 23 or greater'
        ],
        data['mna_f_score'],
        (key, val) {
          onChanged(key, val);
          data[key] = val;
          recalculateScores(data);
        },
      ),
      Row(
        children: [
          Expanded(
            child: FormFieldBuilders.textField(
              label: 'Screening Score (Box 1)',
              value: data['scr_b1']?.toString() ?? '',
              keyboardType: TextInputType.number,
              onChanged: (v) => onChanged('scr_b1', v),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: FormFieldBuilders.textField(
              label: 'Screening Score (Box 2)',
              value: data['scr_b2']?.toString() ?? '',
              keyboardType: TextInputType.number,
              onChanged: (v) => onChanged('scr_b2', v),
            ),
          ),
        ],
      ),
      const SizedBox(height: 24),
      FormFieldBuilders.infoText('ASSESSMENT'),
      _buildMnaDropdownSelection(
        'G. Lives independently (not in nursing home or hospital)',
        'mna_g_score',
        const ['0 = no', '1 = yes'],
        data['mna_g_score'],
        (key, val) {
          onChanged(key, val);
          data[key] = val;
          recalculateScores(data);
        },
      ),
      _buildMnaDropdownSelection(
        'H. Takes more than 3 prescription drugs per day',
        'mna_h_score',
        const ['0 = yes', '1 = no'],
        data['mna_h_score'],
        (key, val) {
          onChanged(key, val);
          data[key] = val;
          recalculateScores(data);
        },
      ),
      _buildMnaDropdownSelection(
        'I. Pressure sores or skin ulcers',
        'mna_i_score',
        const ['0 = yes', '1 = no'],
        data['mna_i_score'],
        (key, val) {
          onChanged(key, val);
          data[key] = val;
          recalculateScores(data);
        },
      ),
      _buildMnaDropdownSelection(
        'J. How many full meals does the patient eat daily?',
        'mna_j_score',
        const ['0 = 1 meal', '1 = 2 meals', '2 = 3 meals'],
        data['mna_j_score'],
        (key, val) {
          onChanged(key, val);
          data[key] = val;
          recalculateScores(data);
        },
      ),
      FormFieldBuilders.infoText(
          'K. Selected consumption markers for protein intake'),
      Row(
        children: [
          Expanded(
            child: FormFieldBuilders.checkbox(
              label: 'Dairy (milk, cheese) - Yes',
              value: data['chk_k1y'] ?? false,
              onChanged: (v) {
                onChanged('chk_k1y', v);
                if (v == true) {
                  onChanged('chk_k1n', false);
                  data['chk_k1n'] = false;
                }
                data['chk_k1y'] = v;
                recalculateScores(data);
              },
            ),
          ),
          Expanded(
            child: FormFieldBuilders.checkbox(
              label: 'Dairy (milk, cheese) - No',
              value: data['chk_k1n'] ?? false,
              onChanged: (v) {
                onChanged('chk_k1n', v);
                if (v == true) {
                  onChanged('chk_k1y', false);
                  data['chk_k1y'] = false;
                }
                data['chk_k1n'] = v;
                recalculateScores(data);
              },
            ),
          ),
        ],
      ),
      Row(
        children: [
          Expanded(
            child: FormFieldBuilders.checkbox(
              label: 'Legumes or eggs - Yes',
              value: data['chk_k2y'] ?? false,
              onChanged: (v) {
                onChanged('chk_k2y', v);
                if (v == true) {
                  onChanged('chk_k2n', false);
                  data['chk_k2n'] = false;
                }
                data['chk_k2y'] = v;
                recalculateScores(data);
              },
            ),
          ),
          Expanded(
            child: FormFieldBuilders.checkbox(
              label: 'Legumes or eggs - No',
              value: data['chk_k2n'] ?? false,
              onChanged: (v) {
                onChanged('chk_k2n', v);
                if (v == true) {
                  onChanged('chk_k2y', false);
                  data['chk_k2y'] = false;
                }
                data['chk_k2n'] = v;
                recalculateScores(data);
              },
            ),
          ),
        ],
      ),
      Row(
        children: [
          Expanded(
            child: FormFieldBuilders.checkbox(
              label: 'Meat/Fish/Poultry - Yes',
              value: data['chk_k3y'] ?? false,
              onChanged: (v) {
                onChanged('chk_k3y', v);
                if (v == true) {
                  onChanged('chk_k3n', false);
                  data['chk_k3n'] = false;
                }
                data['chk_k3y'] = v;
                recalculateScores(data);
              },
            ),
          ),
          Expanded(
            child: FormFieldBuilders.checkbox(
              label: 'Meat/Fish/Poultry - No',
              value: data['chk_k3n'] ?? false,
              onChanged: (v) {
                onChanged('chk_k3n', v);
                if (v == true) {
                  onChanged('chk_k3y', false);
                  data['chk_k3y'] = false;
                }
                data['chk_k3n'] = v;
                recalculateScores(data);
              },
            ),
          ),
        ],
      ),
      FormFieldBuilders.dropdown(
        label: 'K. Score',
        value: data['mna_k_score']?.toString(),
        items: const ['0.0', '0.5', '1.0'],
        onChanged: (v) => onChanged('mna_k_score', v),
      ),
      _buildMnaDropdownSelection(
        'L. Consumes two or more servings of fruit or vegetables per day?',
        'mna_l_score',
        const ['0 = no', '1 = yes'],
        data['mna_l_score'],
        (key, val) {
          onChanged(key, val);
          data[key] = val;
          recalculateScores(data);
        },
      ),
      _buildMnaDropdownSelection(
        'M. How much fluid consumed per day?',
        'mna_m_score',
        const [
          '0.0 = less than 3 cups',
          '0.5 = 3 to 5 cups',
          '1.0 = more than 5 cups'
        ],
        data['mna_m_score'],
        (key, val) {
          onChanged(key, val);
          data[key] = val;
          if (val != null) {
            // Robustly split score for Box 1 / Box 2 (e.g., 0.5 -> 0 and 5)
            final scoreStr = val.split(' = ')[0].trim();
            final parts = scoreStr.split('.');
            onChanged('mna_m_b1', parts[0]);
            onChanged('mna_m_b2', parts.length > 1 ? parts[1] : '0');
            data['mna_m_score'] = scoreStr;
          }
          recalculateScores(data);
        },
      ),
      Row(
        children: [
          Expanded(
            child: FormFieldBuilders.textField(
              label: 'M. Fluid Score (Box 1)',
              value: data['mna_m_b1']?.toString() ?? '',
              onChanged: (v) => onChanged('mna_m_b1', v),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: FormFieldBuilders.textField(
              label: 'M. Fluid Score (Box 2)',
              value: data['mna_m_b2']?.toString() ?? '',
              onChanged: (v) => onChanged('mna_m_b2', v),
            ),
          ),
        ],
      ),
      _buildMnaDropdownSelection(
        'N. Mode of feeding',
        'mna_n_score',
        const [
          '0 = unable to eat without assistance',
          '1 = self-fed with some difficulty',
          '2 = self-fed without any problem'
        ],
        data['mna_n_score'],
        (key, val) {
          onChanged(key, val);
          data[key] = val;
          recalculateScores(data);
        },
      ),
      _buildMnaDropdownSelection(
        'O. Self-view of nutritional status',
        'mna_o_score',
        const [
          '0 = views self as being malnourished',
          '1 = is uncertain of nutritional state',
          '2 = views self as having no nutritional problem'
        ],
        data['mna_o_score'],
        (key, val) {
          onChanged(key, val);
          data[key] = val;
          recalculateScores(data);
        },
      ),
      _buildMnaDropdownSelection(
        'P. Comparison with other people of the same age',
        'mna_p_score',
        const [
          '0.0 = not as good',
          '0.5 = does not know',
          '1.0 = as good',
          '2.0 = better'
        ],
        data['mna_p_score'],
        (key, val) {
          onChanged(key, val);
          data[key] = val;
          recalculateScores(data);
        },
      ),
      _buildMnaDropdownSelection(
        'Q. Mid-arm circumference (MAC) in cm',
        'mna_q_score',
        const [
          '0.0 = MAC less than 21',
          '0.5 = MAC 21 to 22',
          '1.0 = MAC greater than 22'
        ],
        data['mna_q_score'],
        (key, val) {
          onChanged(key, val);
          data[key] = val;
          recalculateScores(data);
        },
      ),
      _buildMnaDropdownSelection(
        'R. Calf circumference (CC) in cm',
        'mna_r_score',
        const ['0 = CC less than 31', '1 = CC 31 or greater'],
        data['mna_r_score'],
        (key, val) {
          onChanged(key, val);
          data[key] = val;
          recalculateScores(data);
        },
      ),
      const SizedBox(height: 24),
      FormFieldBuilders.sectionHeader('TOTALS & INDICATORS'),
      FormFieldBuilders.textField(
        label: 'Assessment Score (max 16 points)',
        value: data['assessment_score']?.toString() ?? '',
        keyboardType: TextInputType.number,
        onChanged: (v) => onChanged('assessment_score', double.tryParse(v)),
      ),
      FormFieldBuilders.textField(
        label: 'Screening Score',
        value: data['screening_score']?.toString() ?? '',
        keyboardType: TextInputType.number,
        onChanged: (v) => onChanged('screening_score', v),
      ),
      FormFieldBuilders.textField(
        label: 'Total Assessment Score (max 30 points)',
        value: data['total_assessment_score']?.toString() ?? '',
        keyboardType: TextInputType.number,
        onChanged: (v) =>
            onChanged('total_assessment_score', double.tryParse(v)),
      ),
      const SizedBox(height: 16),
      const SizedBox(height: 16),
      FormFieldBuilders.dropdown(
        label: 'Malnutrition Indicator Score (Result)',
        value: data['indicator_result'], // Allow null instead of ''
        items: const [
          'Normal (24 to 30 points)',
          'At risk of malnutrition (17 to 23.5 points)',
          'Malnourished (Less than 17 points)'
        ],
        onChanged: (v) {
          onChanged('indicator_result', v);
          // Auto-set the boolean flags for Word checkboxes
          onChanged('chk_indicator_normal', v?.startsWith('Normal') ?? false);
          onChanged(
              'chk_indicator_at_risk', v != null && v.contains('At risk'));
          onChanged('chk_indicator_malnourished',
              v?.startsWith('Malnourished') ?? false);
        },
      ),
    ];
  }

  // 2. DSWD HA_Meal Plan
  // 2. DSWD HA_Meal Plan
  static List<Widget> _mealPlan(
    Map<String, dynamic> data,
    void Function(String, dynamic) onChanged, {
    List<String>? residentNames,
    List<dynamic>? residents,
  }) {
    return [
      FormFieldBuilders.sectionHeader('BASIC INFORMATION'),
      FormFieldBuilders.typeAhead(
        label: 'Name of Client',
        value: data['client_name'] ?? '',
        additionalSuggestions: residentNames ?? [],
        onChanged: (v) {
          onChanged('client_name', v);
          if (residents != null) {
            try {
              final res = residents.firstWhere(
                (r) =>
                    '${r['first_name']} ${r['last_name']}'.toUpperCase() ==
                    v.toUpperCase(),
                orElse: () => null,
              );
              if (res != null) {
                onChanged('age', res['age']?.toString() ?? '');
                onChanged('sex', res['gender'] ?? 'Male');
                onChanged('address', res['address'] ?? '');
                onChanged('height', res['height']?.toString() ?? '');
                onChanged('weight', res['weight']?.toString() ?? '');
                onChanged('diagnosis', res['primary_diagnosis'] ?? '');
              }
            } catch (_) {}
          }
        },
      ),
      Row(
        children: [
          Expanded(
            child: FormFieldBuilders.textField(
              label: 'Age',
              value: data['age']?.toString() ?? '',
              onChanged: (v) => onChanged('age', v),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: FormFieldBuilders.dropdown(
              label: 'Sex',
              value: data['sex'] ?? 'Male',
              items: const ['Male', 'Female'],
              onChanged: (v) => onChanged('sex', v),
            ),
          ),
        ],
      ),
      FormFieldBuilders.textField(
        label: 'Address',
        value: data['address'] ?? '',
        onChanged: (v) => onChanged('address', v),
      ),
      Row(
        children: [
          Expanded(
            child: FormFieldBuilders.textField(
              label: 'Height (cm)',
              value: data['height']?.toString() ?? '',
              onChanged: (v) => onChanged('height', v),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: FormFieldBuilders.textField(
              label: 'Weight (kg)',
              value: data['weight']?.toString() ?? '',
              onChanged: (v) => onChanged('weight', v),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: FormFieldBuilders.textField(
              label: 'DBW',
              value: data['dbw']?.toString() ?? '',
              onChanged: (v) => onChanged('dbw', v),
            ),
          ),
        ],
      ),
      Row(
        children: [
          Expanded(
            child: FormFieldBuilders.datePicker(
              label: 'Date / Week of',
              value: data['week_of'] ?? data['date'],
              onChanged: (v) => onChanged('week_of', v?.toIso8601String()),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: FormFieldBuilders.textField(
              label: 'Dietary Prescription',
              value: data['diet_prescription'] ?? '',
              onChanged: (v) => onChanged('diet_prescription', v),
            ),
          ),
        ],
      ),
      const SizedBox(height: 24),
      FormFieldBuilders.sectionHeader('MEAL SECTION (Nutrient Breakdown)'),
      const SizedBox(height: 16),
      _buildMealGridRow('Breakfast', 'bf', data, onChanged),
      _buildMealGridRow('AM Snacks', 'am', data, onChanged),
      _buildMealGridRow('Lunch', 'lun', data, onChanged),
      _buildMealGridRow('PM Snacks', 'pm', data, onChanged),
      _buildMealGridRow('Dinner', 'din', data, onChanged),
      _buildMealGridRow('Bedtime', 'bed', data, onChanged),
      const SizedBox(height: 24),
      FormFieldBuilders.sectionHeader('ADEQUACY & REMARKS'),
      Row(
        children: [
          Expanded(
            child: FormFieldBuilders.textField(
              label: '% CHO Adequacy',
              value: data['cho_adequacy'] ?? '',
              onChanged: (v) => onChanged('cho_adequacy', v),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: FormFieldBuilders.textField(
              label: '% CHON Adequacy',
              value: data['chon_adequacy'] ?? '',
              onChanged: (v) => onChanged('chon_adequacy', v),
            ),
          ),
        ],
      ),
      Row(
        children: [
          Expanded(
            child: FormFieldBuilders.textField(
              label: '% Fat Adequacy',
              value: data['fat_adequacy'] ?? '',
              onChanged: (v) => onChanged('fat_adequacy', v),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: FormFieldBuilders.textField(
              label: '% Calories',
              value: data['cal_adequacy'] ?? '',
              onChanged: (v) => onChanged('cal_adequacy', v),
            ),
          ),
        ],
      ),
      FormFieldBuilders.textArea(
        label: 'Remarks',
        value: data['remarks'] ?? '',
        onChanged: (v) => onChanged('remarks', v),
      ),
    ];
  }

  static Widget _buildMealGridRow(
    String label,
    String prefix,
    Map<String, dynamic> data,
    void Function(String, dynamic) onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Text(label.toUpperCase(),
              style:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        ),
        Row(
          children: [
            Expanded(
              flex: 2,
              child: FormFieldBuilders.textField(
                label: 'Food Item',
                value: data['${prefix}_food'] ?? '',
                onChanged: (v) => onChanged('${prefix}_food', v),
              ),
            ),
            const SizedBox(width: 4),
            Expanded(
              flex: 1,
              child: FormFieldBuilders.textField(
                label: 'Amount',
                value: data['${prefix}_amount'] ?? '',
                onChanged: (v) => onChanged('${prefix}_amount', v),
              ),
            ),
          ],
        ),
        Row(
          children: [
            Expanded(
              child: FormFieldBuilders.textField(
                label: 'CHO',
                value: data['${prefix}_cho'] ?? '',
                onChanged: (v) => onChanged('${prefix}_cho', v),
              ),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: FormFieldBuilders.textField(
                label: 'CHON',
                value: data['${prefix}_chon'] ?? '',
                onChanged: (v) => onChanged('${prefix}_chon', v),
              ),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: FormFieldBuilders.textField(
                label: 'Fat',
                value: data['${prefix}_fat'] ?? '',
                onChanged: (v) => onChanged('${prefix}_fat', v),
              ),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: FormFieldBuilders.textField(
                label: 'Cal',
                value: data['${prefix}_cal'] ?? '',
                onChanged: (v) => onChanged('${prefix}_cal', v),
              ),
            ),
          ],
        ),
        const Divider(),
      ],
    );
  }

  // 3. NCP Bi-Annual Report_DSWD 11 HA
  static List<Widget> _ncpBiAnnual(
    Map<String, dynamic> data,
    void Function(String, dynamic) onChanged,
  ) {
    return [
      FormFieldBuilders.sectionHeader(
          'NUTRITION CARE PROCESS (NCP) BI-ANNUAL REPORT'),
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Reporting Period',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                Row(
                  children: [
                    Expanded(
                      child: CheckboxListTile(
                        title: const Text('1st Semester\n(January-June)'),
                        value: data['period'] == 'January-June (1st Semester)',
                        onChanged: (v) {
                          if (v == true) {
                            onChanged('period', 'January-June (1st Semester)');
                          }
                        },
                        controlAffinity: ListTileControlAffinity.leading,
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                      ),
                    ),
                    Expanded(
                      child: CheckboxListTile(
                        title: const Text('2nd Semester\n(July-December)'),
                        value: data['period'] == 'July-December (2nd Semester)',
                        onChanged: (v) {
                          if (v == true) {
                            onChanged('period', 'July-December (2nd Semester)');
                          }
                        },
                        controlAffinity: ListTileControlAffinity.leading,
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 1,
            child: FormFieldBuilders.textField(
              label: 'Year',
              value: data['year']?.toString() ?? DateTime.now().year.toString(),
              keyboardType: TextInputType.number,
              onChanged: (v) => onChanged('year', v),
            ),
          ),
        ],
      ),
      const SizedBox(height: 16),

      // UNIFIED HORIZONTAL SCROLL FOR TABLE
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- HEADER ROW ---
            Row(
              children: [
                _buildHeaderCell('Metrics', width: 250, align: TextAlign.left),
                _buildHeaderCell('Below 65\nM   F', width: 90),
                _buildHeaderCell('65 to 74\nM   F', width: 90),
                _buildHeaderCell('75 to 84\nM   F', width: 90),
                _buildHeaderCell('85 & up\nM   F', width: 90),
                _buildHeaderCell('Total\nM   F', width: 90),
                _buildHeaderCell('Total\nM+F', width: 80),
              ],
            ),
            const SizedBox(height: 8),

            // --- DATA ROWS ---
            _buildGridRow(
                'Number of clients admitted', 'admitted', data, onChanged),
            _buildSectionHeaderRow(
                'Number of nutritionally-at-risk (NAR) patients'),
            _buildGridRow('a. Wasting', 'wasting', data, onChanged, indent: 1),
            _buildGridRow(
                'i. Moderate acute malnutrition', 'mam', data, onChanged,
                indent: 2),
            _buildGridRow(
                'ii. Severe acute malnutrition', 'sam', data, onChanged,
                indent: 2),
            _buildGridRow('b. Stunting', 'stunting', data, onChanged,
                indent: 1),
            _buildGridRow('c. Underweight', 'underweight', data, onChanged,
                indent: 1),
            _buildGridRow('d. Overweight', 'overweight', data, onChanged,
                indent: 1),
            _buildGridRow('e. Obese', 'obese', data, onChanged, indent: 1),

            _buildSectionHeaderRow(
                'f. Disease and other co-morbidities (Please specify)'),
            _buildGridRow('i. (Specify)', 'comorb_1', data, onChanged,
                indent: 2, labelEditable: true),
            _buildGridRow('ii. (Specify)', 'comorb_2', data, onChanged,
                indent: 2, labelEditable: true),
            _buildGridRow('iii. (Specify)', 'comorb_3', data, onChanged,
                indent: 2, labelEditable: true),
            _buildGridRow('iv. (Specify)', 'comorb_4', data, onChanged,
                indent: 2, labelEditable: true),

            const SizedBox(height: 8),
            const Divider(),
            _buildGridRow('Number of NAR clients given nutrition screening',
                'screened', data, onChanged),
            _buildGridRow('Number of clients given nutrition assessment',
                'assessed', data, onChanged),
            _buildGridRow('Number of patients given nutrition intervention',
                'intervention', data, onChanged),
            _buildGridRow('Number of patients with nutrition documentation',
                'documentation', data, onChanged),
            _buildGridRow(
                'Number of patients given nutrition care process (ADIME)',
                'adime',
                data,
                onChanged),
          ],
        ),
      ),

      const SizedBox(height: 24),

      // SIGNATORIES
      Row(
        children: [
          Expanded(
            child: Column(
              children: [
                FormFieldBuilders.sectionHeader('Prepared by:',
                    showUnderline: true),
                FormFieldBuilders.textField(
                  label: 'Name',
                  value: data['prepared_by'] ?? 'Jason O. Molina, RND',
                  onChanged: (v) => onChanged('prepared_by', v),
                ),
                FormFieldBuilders.editableDropdown(
                  label: 'Designation',
                  value: data['prepared_by_designation'] ??
                      'Nutritionist-Dietitian II',
                  items: const ['Nutritionist-Dietitian II'],
                  onChanged: (v) => onChanged('prepared_by_designation', v),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              children: [
                FormFieldBuilders.sectionHeader('Noted By:',
                    showUnderline: true),
                FormFieldBuilders.textField(
                  label: 'Name',
                  value: data['noted_by'] ?? 'Dr. Justine Tan',
                  onChanged: (v) => onChanged('noted_by', v),
                ),
                FormFieldBuilders.editableDropdown(
                  label: 'Designation',
                  value: data['noted_by_designation'] ?? 'Physician',
                  items: const ['Physician', 'Center Head', 'SWO IV'],
                  onChanged: (v) => onChanged('noted_by_designation', v),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              children: [
                FormFieldBuilders.sectionHeader('Approved by:',
                    showUnderline: true),
                FormFieldBuilders.textField(
                  label: 'Name',
                  value: data['approved_by'] ?? 'Candelaria C. Tingson, RSW',
                  onChanged: (v) => onChanged('approved_by', v),
                ),
                FormFieldBuilders.editableDropdown(
                  label: 'Designation',
                  value: data['approved_by_designation'] ?? 'Center Head',
                  items: const ['Center Head', 'Regional Director'],
                  onChanged: (v) => onChanged('approved_by_designation', v),
                ),
              ],
            ),
          ),
        ],
      ),
    ];
  }

  static Widget _buildHeaderCell(String text,
      {double width = 80, TextAlign align = TextAlign.center}) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(4),
      alignment:
          align == TextAlign.center ? Alignment.center : Alignment.centerLeft,
      child: Text(text,
          textAlign: align,
          style: const TextStyle(fontWeight: FontWeight.bold)),
    );
  }

  static Widget _buildSectionHeaderRow(String title) {
    return Container(
      width: 250 + (90 * 5) + 80 + 20, // Approx full width
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      color: Colors.grey[200],
      child: Text(
        title,
        style: const TextStyle(
            fontWeight: FontWeight.bold, color: Color(0xFF00897B)),
      ),
    );
  }

  static Widget _buildGridRow(
    String label,
    String keyPrefix,
    Map<String, dynamic> data,
    void Function(String, dynamic) onChanged, {
    int indent = 0,
    bool labelEditable = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        children: [
          Container(
            width: 250,
            padding: EdgeInsets.only(left: indent * 16.0, right: 8.0),
            alignment: Alignment.centerLeft,
            child: labelEditable
                ? FormFieldBuilders.textField(
                    label: 'Specify',
                    value: data['${keyPrefix}_label'] ?? '',
                    onChanged: (v) => onChanged('${keyPrefix}_label', v))
                : Text(label, style: const TextStyle(fontSize: 13)),
          ),
          // Grouped inputs to match headers (M/F pairs)
          _buildPairInput(keyPrefix, 'b65', data, onChanged),
          _buildPairInput(keyPrefix, '6574', data, onChanged),
          _buildPairInput(keyPrefix, '7584', data, onChanged),
          _buildPairInput(keyPrefix, '85up', data, onChanged),
          _buildPairInput(keyPrefix, 'total', data, onChanged, isBold: true),
          _buildTableInput(keyPrefix, 'grand_total', data, onChanged,
              width: 80, isBold: true),
        ],
      ),
    );
  }

  static Widget _buildPairInput(
    String prefix,
    String midfix,
    Map<String, dynamic> data,
    void Function(String, dynamic) onChanged, {
    bool isBold = false,
  }) {
    return SizedBox(
      width: 90,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildTableInput(prefix, '${midfix}_m', data, onChanged,
              width: 42, isBold: isBold),
          const SizedBox(width: 2),
          _buildTableInput(prefix, '${midfix}_f', data, onChanged,
              width: 42, isBold: isBold),
        ],
      ),
    );
  }

  static Widget _buildTableInput(
    String prefix,
    String suffix,
    Map<String, dynamic> data,
    void Function(String, dynamic) onChanged, {
    bool isBold = false,
    double width = 40,
  }) {
    return Container(
      width: width,
      height: 32,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[400]!),
        borderRadius: BorderRadius.circular(4),
        color: Colors.white,
      ),
      alignment: Alignment.center,
      child: TextFormField(
        initialValue: data['${prefix}_$suffix'] ?? '',
        onChanged: (v) => onChanged('${prefix}_$suffix', v),
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 13,
          fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
        ),
        decoration: const InputDecoration(
          isDense: true,
          contentPadding: EdgeInsets.zero,
          border: InputBorder.none,
          focusedBorder: InputBorder.none,
          enabledBorder: InputBorder.none,
        ),
      ),
    );
  }

  // 4. Diet Diary_DSWD 11 HA
  static List<Widget> _dietDiary(
    Map<String, dynamic> data,
    void Function(String, dynamic) onChanged,
  ) {
    return [
      FormFieldBuilders.sectionHeader('DIET DIARY'),

      // --- HEADER ---
      Row(
        children: [
          Expanded(
            child: FormFieldBuilders.textField(
              label: 'Name of Client',
              value: data['client_name'] ?? '',
              onChanged: (v) => onChanged('client_name', v),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: FormFieldBuilders.textField(
              label: 'Age',
              value: data['age']?.toString() ?? '',
              onChanged: (v) => onChanged('age', v),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: FormFieldBuilders.dropdown(
              label: 'Sex',
              value: data['sex'] ?? 'Male',
              items: const ['Male', 'Female'],
              onChanged: (v) => onChanged('sex', v),
            ),
          ),
        ],
      ),
      FormFieldBuilders.textField(
        label: 'Address',
        value: data['address'] ?? '',
        onChanged: (v) => onChanged('address', v),
      ),
      Row(
        children: [
          Expanded(
            child: FormFieldBuilders.textField(
              label: 'Height (cm)',
              value: data['height']?.toString() ?? '',
              onChanged: (v) => onChanged('height', v),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: FormFieldBuilders.textField(
              label: 'Weight (kg)',
              value: data['weight']?.toString() ?? '',
              onChanged: (v) => onChanged('weight', v),
            ),
          ),
        ],
      ),
      Row(
        children: [
          Expanded(
            child: FormFieldBuilders.textField(
              label: 'DBW',
              value: data['dbw']?.toString() ?? '',
              onChanged: (v) => onChanged('dbw', v),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: FormFieldBuilders.datePicker(
              label: 'Date of Recording',
              value: data['date'],
              onChanged: (v) => onChanged('date', v?.toIso8601String()),
            ),
          ),
        ],
      ),
      FormFieldBuilders.textField(
        label: 'Dietary Prescription',
        value: data['diet_prescription'] ?? '',
        onChanged: (v) => onChanged('diet_prescription', v),
      ),
      const SizedBox(height: 16),

      // --- MEALS TABLE ---
      ..._buildMealSection('Breakfast', 'bf', data, onChanged),
      ..._buildMealSection('AM Snacks', 'am', data, onChanged),
      ..._buildMealSection('Lunch', 'lun', data, onChanged),
      ..._buildMealSection('PM Snacks', 'pm', data, onChanged),
      ..._buildMealSection('Dinner', 'din', data, onChanged),
      ..._buildMealSection('Bedtime Snacks', 'bed', data, onChanged),

      const SizedBox(height: 16),
      FormFieldBuilders.sectionHeader('ADEQUACY & REMARKS'),
      Row(
        children: [
          Expanded(
            child: FormFieldBuilders.textField(
              label: '% CHO Adequacy',
              value: data['cho_adequacy'] ?? '',
              onChanged: (v) => onChanged('cho_adequacy', v),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: FormFieldBuilders.textField(
              label: '% CHON Adequacy',
              value: data['chon_adequacy'] ?? '',
              onChanged: (v) => onChanged('chon_adequacy', v),
            ),
          ),
        ],
      ),
      Row(
        children: [
          Expanded(
            child: FormFieldBuilders.textField(
              label: '% Fat Adequacy',
              value: data['fat_adequacy'] ?? '',
              onChanged: (v) => onChanged('fat_adequacy', v),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: FormFieldBuilders.textField(
              label: '% Calories',
              value: data['cal_adequacy'] ?? '',
              onChanged: (v) => onChanged('cal_adequacy', v),
            ),
          ),
        ],
      ),
      FormFieldBuilders.textArea(
        label: 'Remarks',
        value: data['remarks'] ?? '',
        onChanged: (v) => onChanged('remarks', v),
      ),
    ];
  }

  static List<Widget> _buildMealSection(
    String title,
    String prefix,
    Map<String, dynamic> data,
    void Function(String, dynamic) onChanged,
  ) {
    return [
      FormFieldBuilders.sectionHeader(title),
      Row(
        children: [
          Expanded(
              flex: 3,
              child: FormFieldBuilders.textField(
                  label: 'Food Item',
                  value: data['${prefix}_food'] ?? '',
                  onChanged: (v) => onChanged('${prefix}_food', v))),
          const SizedBox(width: 8),
          Expanded(
              flex: 2,
              child: FormFieldBuilders.textField(
                  label: 'Amount',
                  value: data['${prefix}_amount'] ?? '',
                  onChanged: (v) => onChanged('${prefix}_amount', v))),
        ],
      ),
      Row(
        children: [
          Expanded(
              child: FormFieldBuilders.textField(
                  label: 'CHO (g)',
                  value: data['${prefix}_cho'] ?? '',
                  onChanged: (v) => onChanged('${prefix}_cho', v))),
          const SizedBox(width: 8),
          Expanded(
              child: FormFieldBuilders.textField(
                  label: 'CHON (g)',
                  value: data['${prefix}_chon'] ?? '',
                  onChanged: (v) => onChanged('${prefix}_chon', v))),
          const SizedBox(width: 8),
          Expanded(
              child: FormFieldBuilders.textField(
                  label: 'Fat (g)',
                  value: data['${prefix}_fat'] ?? '',
                  onChanged: (v) => onChanged('${prefix}_fat', v))),
          const SizedBox(width: 8),
          Expanded(
              child: FormFieldBuilders.textField(
                  label: 'Cal',
                  value: data['${prefix}_cal'] ?? '',
                  onChanged: (v) => onChanged('${prefix}_cal', v))),
        ],
      ),
      const SizedBox(height: 8),
    ];
  }

  // 5. List of Diet Orders of Clients_Form
  static List<Widget> _dietOrders(
    Map<String, dynamic> data,
    void Function(String, dynamic) onChanged, {
    List<String>? residentNames,
  }) {
    Widget buildDietRow(String label, String keyPrefix) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FormFieldBuilders.infoText(label),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: FormFieldBuilders.multiSelect(
                  label: 'List of Clients',
                  values: List<String>.from(data['${keyPrefix}_clients'] ?? []),
                  options: residentNames ?? [],
                  onChanged: (v) => onChanged('${keyPrefix}_clients', v),
                  allowCustom: true,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 1,
                child: FormFieldBuilders.textField(
                  label: 'Remarks',
                  value: data['${keyPrefix}_remarks'] ?? '',
                  onChanged: (v) => onChanged('${keyPrefix}_remarks', v),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 1,
                child: FormFieldBuilders.textField(
                  label: 'Total',
                  value: data['${keyPrefix}_total']?.toString() ?? '',
                  keyboardType: TextInputType.number,
                  onChanged: (v) => onChanged('${keyPrefix}_total', v),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
        ],
      );
    }

    return [
      FormFieldBuilders.sectionHeader('CLIENT CENSUS AND DIET LIST'),
      FormFieldBuilders.datePicker(
        label: 'Date Conducted',
        value: data['date'],
        onChanged: (v) => onChanged('date', v?.toIso8601String()),
        required: true,
      ),
      const SizedBox(height: 16),
      buildDietRow('Diabetic Diet', 'diabetic'),
      buildDietRow('Soft Diet', 'soft'),
      buildDietRow('Hypoallergenic Diet (no egg, chicken, seafood, etc)',
          'hypoallergenic'),
      buildDietRow('Low Purine Diet', 'low_purine'),
      buildDietRow('No Pork (Islam and Adventist)', 'no_pork'),
      buildDietRow('Low salt, low fat', 'low_salt_fat'),
      buildDietRow('Enteral Feeding (Blenderized)', 'enteral'),
      buildDietRow('Full Diet', 'full'),
      const SizedBox(height: 16),
      FormFieldBuilders.sectionHeader('TOTAL SUMMARY'),
      Row(
        children: [
          Expanded(
            child: FormFieldBuilders.textField(
              label: 'Overall Client Total',
              value: data['grand_total_clients']?.toString() ?? '',
              keyboardType: TextInputType.number,
              onChanged: (v) => onChanged('grand_total_clients', v),
            ),
          ),
        ],
      ),
      const SizedBox(height: 24),
      FormFieldBuilders.sectionHeader('DEMOGRAPHICS TOTALS'),
      Row(
        children: [
          Expanded(
            child: FormFieldBuilders.textField(
              label: 'Total Clients',
              value: data['total_clients']?.toString() ?? '',
              keyboardType: TextInputType.number,
              onChanged: (v) => onChanged('total_clients', v),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: FormFieldBuilders.textField(
              label: 'Total Regular/Full Diet',
              value: data['total_regular_diet']?.toString() ?? '',
              keyboardType: TextInputType.number,
              onChanged: (v) => onChanged('total_regular_diet', v),
            ),
          ),
        ],
      ),
      Row(
        children: [
          Expanded(
            child: FormFieldBuilders.textField(
              label: 'Total Soft Diet',
              value: data['total_soft_diet']?.toString() ?? '',
              keyboardType: TextInputType.number,
              onChanged: (v) => onChanged('total_soft_diet', v),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: FormFieldBuilders.textField(
              label: 'Total Therapeutic Diet',
              value: data['total_therapeutic_diet']?.toString() ?? '',
              keyboardType: TextInputType.number,
              onChanged: (v) => onChanged('total_therapeutic_diet', v),
            ),
          ),
        ],
      ),
      const SizedBox(height: 8),
      FormFieldBuilders.infoText('Therapeutic Diet Breakdown'),
      Row(
        children: [
          Expanded(
            child: FormFieldBuilders.textField(
              label: 'Diabetic Diet',
              value: data['total_diabetic']?.toString() ?? '',
              keyboardType: TextInputType.number,
              onChanged: (v) => onChanged('total_diabetic', v),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: FormFieldBuilders.textField(
              label: 'Low Purine Diet',
              value: data['total_low_purine']?.toString() ?? '',
              keyboardType: TextInputType.number,
              onChanged: (v) => onChanged('total_low_purine', v),
            ),
          ),
        ],
      ),
      Row(
        children: [
          Expanded(
            child: FormFieldBuilders.textField(
              label: 'Low Salt, Low Fat',
              value: data['total_low_salt_fat']?.toString() ?? '',
              keyboardType: TextInputType.number,
              onChanged: (v) => onChanged('total_low_salt_fat', v),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: FormFieldBuilders.textField(
              label: 'Hypoallergenic Diet',
              value: data['total_hypoallergenic']?.toString() ?? '',
              keyboardType: TextInputType.number,
              onChanged: (v) => onChanged('total_hypoallergenic', v),
            ),
          ),
        ],
      ),
      Row(
        children: [
          Expanded(
            child: FormFieldBuilders.textField(
              label: 'Other Diets: No Pork',
              value: data['total_no_pork']?.toString() ?? '',
              keyboardType: TextInputType.number,
              onChanged: (v) => onChanged('total_no_pork', v),
            ),
          ),
          const SizedBox(width: 8),
          Spacer(),
        ],
      ),
      const SizedBox(height: 8),
      FormFieldBuilders.infoText('Total Clients on Nutrition Support'),
      Row(
        children: [
          Expanded(
            child: FormFieldBuilders.textField(
              label: 'Overall Nutrition Support',
              value: data['total_nutrition_support']?.toString() ?? '',
              keyboardType: TextInputType.number,
              onChanged: (v) => onChanged('total_nutrition_support', v),
            ),
          ),
        ],
      ),
      Row(
        children: [
          Expanded(
            child: FormFieldBuilders.textField(
              label: 'Tube Feeding',
              value: data['total_tube_feeding']?.toString() ?? '',
              keyboardType: TextInputType.number,
              onChanged: (v) => onChanged('total_tube_feeding', v),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: FormFieldBuilders.textField(
              label: 'Parenteral Feeding',
              value: data['total_parenteral']?.toString() ?? '',
              keyboardType: TextInputType.number,
              onChanged: (v) => onChanged('total_parenteral', v),
            ),
          ),
        ],
      ),
    ];
  }

  // 6. List of Malnourished Clients_Form
  static List<Widget> _malnourishedList(
    Map<String, dynamic> data,
    void Function(String, dynamic) onChanged, {
    List<String>? residentNames,
  }) {
    List<Map<String, dynamic>> malnourishedList =
        (data['malnourished_list'] as List?)?.cast<Map<String, dynamic>>() ??
            [];

    return [
      FormFieldBuilders.sectionHeader('LIST OF MALNOURISHED CLIENTS'),
      FormFieldBuilders.datePicker(
        label: 'Coverage Month',
        value: data['coverage_month'],
        onChanged: (v) {
          if (v != null) {
            final months = [
              'January',
              'February',
              'March',
              'April',
              'May',
              'June',
              'July',
              'August',
              'September',
              'October',
              'November',
              'December'
            ];
            final monthStr = "${months[v.month - 1]} ${v.year}";
            onChanged('coverage_month', monthStr);
          }
        },
      ),
      FormFieldBuilders.datePicker(
        label: 'Date',
        value: data['date'],
        onChanged: (v) => onChanged('date', v?.toIso8601String()),
      ),
      const SizedBox(height: 16),
      FormFieldBuilders.sectionHeader('CLIENTS LIST'),
      StatefulBuilder(builder: (context, setState) {
        return Column(
          children: [
            for (int i = 0; i < malnourishedList.length; i++)
              Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Client ${i + 1}',
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold)),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () {
                              setState(() {
                                malnourishedList.removeAt(i);
                                onChanged(
                                    'malnourished_list', malnourishedList);
                              });
                            },
                          ),
                        ],
                      ),
                      FormFieldBuilders.typeAhead(
                        label: 'Name',
                        value: malnourishedList[i]['name'] ?? '',
                        useStaffSuggestions: false,
                        additionalSuggestions: residentNames ?? [],
                        onChanged: (v) {
                          malnourishedList[i]['name'] = v;
                          onChanged('malnourished_list', malnourishedList);
                        },
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: FormFieldBuilders.dropdown(
                              label: 'Gender',
                              value: malnourishedList[i]['gender'],
                              items: const ['Male', 'Female'],
                              onChanged: (v) {
                                malnourishedList[i]['gender'] = v;
                                onChanged(
                                    'malnourished_list', malnourishedList);
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: FormFieldBuilders.textField(
                              label: 'Weight (kg)',
                              value: malnourishedList[i]['weight'] ?? '',
                              keyboardType: TextInputType.number,
                              onChanged: (v) {
                                malnourishedList[i]['weight'] = v;
                                onChanged(
                                    'malnourished_list', malnourishedList);
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: FormFieldBuilders.textField(
                              label: 'CC (cm)',
                              value: malnourishedList[i]['cc'] ?? '',
                              keyboardType: TextInputType.number,
                              onChanged: (v) {
                                malnourishedList[i]['cc'] = v;
                                onChanged(
                                    'malnourished_list', malnourishedList);
                              },
                            ),
                          ),
                        ],
                      ),
                      FormFieldBuilders.textField(
                        label: 'Target Wt & CC',
                        value: malnourishedList[i]['target'] ?? '',
                        onChanged: (v) {
                          malnourishedList[i]['target'] = v;
                          onChanged('malnourished_list', malnourishedList);
                        },
                      ),
                      FormFieldBuilders.textArea(
                        label: 'Interventions & Diet Order',
                        value: malnourishedList[i]['interventions'] ?? '',
                        onChanged: (v) {
                          malnourishedList[i]['interventions'] = v;
                          onChanged('malnourished_list', malnourishedList);
                        },
                      ),
                      FormFieldBuilders.textField(
                        label: 'Remarks',
                        value: malnourishedList[i]['remarks'] ?? '',
                        onChanged: (v) {
                          malnourishedList[i]['remarks'] = v;
                          onChanged('malnourished_list', malnourishedList);
                        },
                      ),
                    ],
                  ),
                ),
              ),
            TextButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('Add Client'),
              onPressed: () {
                setState(() {
                  malnourishedList.add({
                    'name': '',
                    'gender': 'Male',
                    'weight': '',
                    'cc': '',
                    'target': '',
                    'interventions': '',
                    'remarks': '',
                  });
                  onChanged('malnourished_list', malnourishedList);
                });
              },
            ),
          ],
        );
      }),
    ];
  }

  // 7. Medical Nutrition Therapy Form (Nutrition Care Plan)
  static List<Widget> _ncpMnt(
    Map<String, dynamic> data,
    void Function(String, dynamic) onChanged, {
    bool Function(String) ro = _defaultRo,
  }) {
    return [
      FormFieldBuilders.sectionHeader('MEDICAL NUTRITION THERAPY FORM'),
      FormFieldBuilders.sectionHeader('BASIC INFORMATION'),
      Row(
        children: [
          Expanded(
            flex: 2,
            child: FormFieldBuilders.textField(
              label: 'Name of Patient',
              value: data['client_name'] ?? '',
              onChanged: (v) => onChanged('client_name', v),
              required: true,
              readOnly: ro('client_name'),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: FormFieldBuilders.textField(
              label: 'Client No.',
              value: data['client_no'] ?? '',
              onChanged: (v) => onChanged('client_no', v),
              readOnly: ro('client_no'),
            ),
          ),
        ],
      ),
      Row(
        children: [
          Expanded(
            flex: 2,
            child: FormFieldBuilders.textField(
              label: 'Age',
              value: data['age']?.toString() ?? '',
              onChanged: (v) => onChanged('age', v),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: FormFieldBuilders.checkbox(
              label: 'Years',
              value: data['cb_age_yrs'] ?? false,
              onChanged: (v) {
                onChanged('cb_age_yrs', v);
                if (v == true) onChanged('cb_age_mos', false);
              },
            ),
          ),
          Expanded(
            child: FormFieldBuilders.checkbox(
              label: 'Months',
              value: data['cb_age_mos'] ?? false,
              onChanged: (v) {
                onChanged('cb_age_mos', v);
                if (v == true) onChanged('cb_age_yrs', false);
              },
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: FormFieldBuilders.dropdown(
              label: 'Gender',
              value: data['gender'] ?? 'Male',
              items: const ['Male', 'Female'],
              onChanged: (v) => onChanged('gender', v),
            ),
          ),
        ],
      ),
      Row(
        children: [
          Expanded(
            flex: 2,
            child: FormFieldBuilders.typeAhead(
              label: 'Name of Attending Physician',
              value: data['physician'] ?? '',
              onChanged: (v) => onChanged('physician', v),
              useStaffSuggestions: true,
              filterUnit: 'medical',
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: FormFieldBuilders.textField(
              label: 'Religion',
              value: data['religion'] ?? '',
              onChanged: (v) => onChanged('religion', v),
            ),
          ),
        ],
      ),
      Row(
        children: [
          Expanded(
            child: FormFieldBuilders.datePicker(
              label: 'Date of Birth',
              value: data['dob'],
              onChanged: (v) => onChanged('dob', v?.toIso8601String()),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: FormFieldBuilders.datePicker(
              label: 'Date of admission at HA',
              value: data['date_admission'],
              onChanged: (v) =>
                  onChanged('date_admission', v?.toIso8601String()),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: FormFieldBuilders.datePicker(
              label: 'Date assessed',
              value: data['date_assessed'],
              onChanged: (v) =>
                  onChanged('date_assessed', v?.toIso8601String()),
            ),
          ),
        ],
      ),
      FormFieldBuilders.textArea(
        label: 'Medical Diagnosis',
        value: data['medical_diagnosis'] ?? '',
        onChanged: (v) => onChanged('medical_diagnosis', v),
      ),
      const SizedBox(height: 16),
      FormFieldBuilders.sectionHeader('NUTRITION ASSESSMENT'),
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left Column
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FormFieldBuilders.textField(
                  label: 'Present Diet of Client',
                  value: data['present_diet'] ?? '',
                  onChanged: (v) => onChanged('present_diet', v),
                ),
                Row(
                  children: [
                    Expanded(
                      child: FormFieldBuilders.checkbox(
                        label: 'No change',
                        value: data['cb_diet_no_change'] ?? false,
                        onChanged: (v) => onChanged('cb_diet_no_change', v),
                      ),
                    ),
                    Expanded(
                      child: FormFieldBuilders.checkbox(
                        label: 'Mostly liquids',
                        value: data['cb_diet_mostly_liquids'] ?? false,
                        onChanged: (v) =>
                            onChanged('cb_diet_mostly_liquids', v),
                      ),
                    ),
                  ],
                ),
                const Text('Food Intake:',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                FormFieldBuilders.checkbox(
                  label: 'Sub-Optimal',
                  value: data['cb_intake_sub_optimal'] ?? false,
                  onChanged: (v) {
                    onChanged('cb_intake_sub_optimal', v);
                    if (v == true) {
                      onChanged('cb_intake_starvation', false);
                      onChanged('cb_intake_poor', false);
                    }
                  },
                ),
                FormFieldBuilders.checkbox(
                  label: 'Starvation',
                  value: data['cb_intake_starvation'] ?? false,
                  onChanged: (v) {
                    onChanged('cb_intake_starvation', v);
                    if (v == true) {
                      onChanged('cb_intake_sub_optimal', false);
                      onChanged('cb_intake_poor', false);
                    }
                  },
                ),
                FormFieldBuilders.checkbox(
                  label: 'Poor intake',
                  value: data['cb_intake_poor'] ?? false,
                  onChanged: (v) {
                    onChanged('cb_intake_poor', v);
                    if (v == true) {
                      onChanged('cb_intake_sub_optimal', false);
                      onChanged('cb_intake_starvation', false);
                    }
                  },
                ),
                const Text('Functional Capacity:',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                FormFieldBuilders.checkbox(
                  label: 'Bedridden',
                  value: data['cb_capacity_bedridden'] ?? false,
                  onChanged: (v) {
                    onChanged('cb_capacity_bedridden', v);
                    if (v == true) {
                      onChanged('cb_capacity_ambulatory', false);
                      onChanged('cb_capacity_needs_assistance', false);
                    }
                  },
                ),
                FormFieldBuilders.checkbox(
                  label: 'Ambulatory',
                  value: data['cb_capacity_ambulatory'] ?? false,
                  onChanged: (v) {
                    onChanged('cb_capacity_ambulatory', v);
                    if (v == true) {
                      onChanged('cb_capacity_bedridden', false);
                      onChanged('cb_capacity_needs_assistance', false);
                    }
                  },
                ),
                FormFieldBuilders.checkbox(
                  label: 'Needs assistance',
                  value: data['cb_capacity_needs_assistance'] ?? false,
                  onChanged: (v) {
                    onChanged('cb_capacity_needs_assistance', v);
                    if (v == true) {
                      onChanged('cb_capacity_bedridden', false);
                      onChanged('cb_capacity_ambulatory', false);
                    }
                  },
                ),
                FormFieldBuilders.textField(
                  label: 'Chewing/Swallowing Difficulties',
                  value: data['chewing_difficulty'] ?? '',
                  onChanged: (v) => onChanged('chewing_difficulty', v),
                ),
                Row(
                  children: [
                    Expanded(
                      child: FormFieldBuilders.textField(
                        label: 'Constipation',
                        value: data['constipation'] ?? '',
                        onChanged: (v) => onChanged('constipation', v),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FormFieldBuilders.textField(
                        label: 'Diarrhea',
                        value: data['diarrhea'] ?? '',
                        onChanged: (v) => onChanged('diarrhea', v),
                      ),
                    ),
                  ],
                ),
                FormFieldBuilders.textField(
                  label: 'Food Allergies',
                  value: data['food_allergies'] ?? '',
                  onChanged: (v) => onChanged('food_allergies', v),
                ),
                FormFieldBuilders.textField(
                  label: 'Food intolerance',
                  value: data['food_intolerance'] ?? '',
                  onChanged: (v) => onChanged('food_intolerance', v),
                ),
                FormFieldBuilders.textArea(
                  label: 'Medications',
                  value: data['medications'] ?? '',
                  onChanged: (v) => onChanged('medications', v),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // Right Column
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: FormFieldBuilders.textField(
                        label: 'Height',
                        value: data['height'] ?? '',
                        onChanged: (v) => onChanged('height', v),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FormFieldBuilders.textField(
                        label: 'Weight',
                        value: data['weight'] ?? '',
                        onChanged: (v) => onChanged('weight', v),
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Expanded(
                      child: FormFieldBuilders.textField(
                        label: 'Usual weight (kg)',
                        value: data['usual_weight'] ?? '',
                        onChanged: (v) => onChanged('usual_weight', v),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FormFieldBuilders.textField(
                        label: 'BMI',
                        value: data['bmi'] ?? '',
                        onChanged: (v) => onChanged('bmi', v),
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Expanded(
                      child: FormFieldBuilders.textField(
                        label: 'Weight change (%)',
                        value: data['weight_change_pct'] ?? '',
                        onChanged: (v) => onChanged('weight_change_pct', v),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FormFieldBuilders.textField(
                        label: 'over __ weeks/months',
                        value: data['weight_change_duration'] ?? '',
                        onChanged: (v) =>
                            onChanged('weight_change_duration', v),
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Expanded(
                      child: FormFieldBuilders.textField(
                        label: '% IBW',
                        value: data['pct_ibw'] ?? '',
                        onChanged: (v) => onChanged('pct_ibw', v),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FormFieldBuilders.textField(
                        label: 'CC (cm)',
                        value: data['cc_cm'] ?? '',
                        onChanged: (v) => onChanged('cc_cm', v),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text('Biochemical Data:',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                Table(
                  border: TableBorder.all(color: Colors.grey.shade300),
                  children: [
                    TableRow(children: [
                      _buildLabCell('Albumin', 'lab_albumin', data, onChanged),
                      _buildLabCell(
                          'Hematocrit', 'lab_hematocrit', data, onChanged),
                    ]),
                    TableRow(children: [
                      _buildLabCell('BUN', 'lab_bun', data, onChanged),
                      _buildLabCell(
                          'Hemoglobin', 'lab_hemoglobin', data, onChanged),
                    ]),
                    TableRow(children: [
                      _buildLabCell('Calcium', 'lab_calcium', data, onChanged),
                      _buildLabCell('LDL', 'lab_ldl', data, onChanged),
                    ]),
                    TableRow(children: [
                      _buildLabCell(
                          'Cholesterol', 'lab_cholesterol', data, onChanged),
                      _buildLabCell(
                          'Phosphate', 'lab_phosphate', data, onChanged),
                    ]),
                    TableRow(children: [
                      _buildLabCell(
                          'Creatinine', 'lab_creatinine', data, onChanged),
                      _buildLabCell(
                          'Potassium', 'lab_potassium', data, onChanged),
                    ]),
                    TableRow(children: [
                      _buildLabCell('Glucose', 'lab_glucose', data, onChanged),
                      _buildLabCell('Sodium', 'lab_sodium', data, onChanged),
                    ]),
                    TableRow(children: [
                      _buildLabCell('HbA1C', 'lab_hba1c', data, onChanged),
                      _buildLabCell('Triglycerides', 'lab_triglycerides', data,
                          onChanged),
                    ]),
                    TableRow(children: [
                      _buildLabCell('HDL', 'lab_hdl', data, onChanged),
                      _buildLabCell('URR', 'lab_urr', data, onChanged),
                    ]),
                  ],
                ),
                FormFieldBuilders.textField(
                  label: '*Labs were based on',
                  value: data['labs_based_on'] ?? '',
                  onChanged: (v) => onChanged('labs_based_on', v),
                ),
                Row(
                  children: [
                    Expanded(
                      child: FormFieldBuilders.textField(
                        label: 'BP',
                        value: data['bp'] ?? '',
                        onChanged: (v) => onChanged('bp', v),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FormFieldBuilders.textField(
                        label: 'Acid Base Gas (ABG)',
                        value: data['abg'] ?? '',
                        onChanged: (v) => onChanged('abg', v),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
      const SizedBox(height: 16),
      Row(
        children: [
          const Text('Nutritional Status:',
              style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(width: 16),
          Expanded(
            child: FormFieldBuilders.checkbox(
              label: 'Normal',
              value: data['cb_status_normal'] ?? false,
              onChanged: (v) {
                onChanged('cb_status_normal', v);
                if (v == true) {
                  onChanged('cb_status_moderate', false);
                  onChanged('cb_status_severe', false);
                }
              },
            ),
          ),
          Expanded(
            child: FormFieldBuilders.checkbox(
              label: 'Moderate Malnutrition',
              value: data['cb_status_moderate'] ?? false,
              onChanged: (v) {
                onChanged('cb_status_moderate', v);
                if (v == true) {
                  onChanged('cb_status_normal', false);
                  onChanged('cb_status_severe', false);
                }
              },
            ),
          ),
          Expanded(
            child: FormFieldBuilders.checkbox(
              label: 'Severe Malnutrition',
              value: data['cb_status_severe'] ?? false,
              onChanged: (v) {
                onChanged('cb_status_severe', v);
                if (v == true) {
                  onChanged('cb_status_normal', false);
                  onChanged('cb_status_moderate', false);
                }
              },
            ),
          ),
        ],
      ),
      const SizedBox(height: 24),
      FormFieldBuilders.sectionHeader(
          'NUTRITION DIAGNOSIS (Problem, Etiology, Signs and Symptoms)'),
      FormFieldBuilders.textField(
        label: 'Problem',
        value: data['dx_problem'] ?? '',
        onChanged: (v) => onChanged('dx_problem', v),
      ),
      const Center(child: Text('related to')),
      FormFieldBuilders.textField(
        label: 'Etiology',
        value: data['dx_etiology'] ?? '',
        onChanged: (v) => onChanged('dx_etiology', v),
      ),
      const Center(child: Text('as evidenced by')),
      FormFieldBuilders.textField(
        label: 'Signs and Symptoms',
        value: data['dx_signs_symptoms'] ?? '',
        onChanged: (v) => onChanged('dx_signs_symptoms', v),
      ),
      const SizedBox(height: 24),
      FormFieldBuilders.sectionHeader('NUTRITION INTERVENTION'),
      FormFieldBuilders.textField(
        label: 'Total Energy Requirement',
        value: data['ter'] ?? '',
        onChanged: (v) => onChanged('ter', v),
      ),
      Row(
        children: [
          Expanded(
            child: FormFieldBuilders.textField(
              label: 'Carbohydrate grams/day',
              value: data['cho_grams'] ?? '',
              onChanged: (v) => onChanged('cho_grams', v),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: FormFieldBuilders.textField(
              label: 'Protein grams per day',
              value: data['pro_grams'] ?? '',
              onChanged: (v) => onChanged('pro_grams', v),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: FormFieldBuilders.textField(
              label: 'Fat grams/day',
              value: data['fat_grams'] ?? '',
              onChanged: (v) => onChanged('fat_grams', v),
            ),
          ),
        ],
      ),
      Row(
        children: [
          Expanded(
            flex: 1,
            child: FormFieldBuilders.checkbox(
              label: 'Others (e.g. micronutrients)',
              value: data['cb_is_micronutrients'] ?? false,
              onChanged: (v) => onChanged('cb_is_micronutrients', v),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: FormFieldBuilders.textField(
              label: 'Details',
              value: data['micronutrients'] ?? '',
              onChanged: (v) => onChanged('micronutrients', v),
            ),
          ),
        ],
      ),
      Row(
        children: [
          Expanded(
            child: FormFieldBuilders.checkbox(
              label: 'Shift diet to:',
              value: data['cb_is_diet_shift'] ?? false,
              onChanged: (v) => onChanged('cb_is_diet_shift', v),
            ),
          ),
          Expanded(
            child: FormFieldBuilders.checkbox(
              label: 'Per orem',
              value: data['cb_shift_per_orem'] ?? false,
              onChanged: (v) {
                onChanged('cb_shift_per_orem', v);
                if (v == true) {
                  onChanged('cb_shift_tube_feeding', false);
                  onChanged('cb_shift_tpn_ppn', false);
                }
              },
            ),
          ),
          Expanded(
            child: FormFieldBuilders.checkbox(
              label: 'Tube Feeding',
              value: data['cb_shift_tube_feeding'] ?? false,
              onChanged: (v) {
                onChanged('cb_shift_tube_feeding', v);
                if (v == true) {
                  onChanged('cb_shift_per_orem', false);
                  onChanged('cb_shift_tpn_ppn', false);
                }
              },
            ),
          ),
          Expanded(
            child: FormFieldBuilders.checkbox(
              label: 'TPN/PPN',
              value: data['cb_shift_tpn_ppn'] ?? false,
              onChanged: (v) {
                onChanged('cb_shift_tpn_ppn', v);
                if (v == true) {
                  onChanged('cb_shift_per_orem', false);
                  onChanged('cb_shift_tube_feeding', false);
                }
              },
            ),
          ),
        ],
      ),
      FormFieldBuilders.checkbox(
        label: 'Diabetic Diet',
        value: data['cb_is_diabetic_diet'] ?? false,
        onChanged: (v) => onChanged('cb_is_diabetic_diet', v),
      ),
      Row(
        children: [
          Expanded(
            flex: 1,
            child: FormFieldBuilders.checkbox(
              label: 'Nutrition Education on',
              value: data['cb_is_nutrition_education'] ?? false,
              onChanged: (v) => onChanged('cb_is_nutrition_education', v),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: FormFieldBuilders.textField(
              label: 'Details',
              value: data['nutrition_education'] ?? '',
              onChanged: (v) => onChanged('nutrition_education', v),
            ),
          ),
        ],
      ),
      Row(
        children: [
          Expanded(
            flex: 1,
            child: FormFieldBuilders.checkbox(
              label: 'Nutrition Counseling on',
              value: data['cb_is_nutrition_counseling'] ?? false,
              onChanged: (v) => onChanged('cb_is_nutrition_counseling', v),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: FormFieldBuilders.textField(
              label: 'Details',
              value: data['nutrition_counseling'] ?? '',
              onChanged: (v) => onChanged('nutrition_counseling', v),
            ),
          ),
        ],
      ),
      Row(
        children: [
          Expanded(
            flex: 1,
            child: FormFieldBuilders.checkbox(
              label: 'Request for Laboratory Results',
              value: data['cb_is_req_lab_results'] ?? false,
              onChanged: (v) => onChanged('cb_is_req_lab_results', v),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: FormFieldBuilders.textField(
              label: 'Details',
              value: data['req_lab_results'] ?? '',
              onChanged: (v) => onChanged('req_lab_results', v),
            ),
          ),
        ],
      ),
      Row(
        children: [
          Expanded(
            flex: 1,
            child: FormFieldBuilders.checkbox(
              label: 'Others',
              value: data['cb_is_intervention_others'] ?? false,
              onChanged: (v) => onChanged('cb_is_intervention_others', v),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: FormFieldBuilders.textField(
              label: 'Details',
              value: data['intervention_others'] ?? '',
              onChanged: (v) => onChanged('intervention_others', v),
            ),
          ),
        ],
      ),
      const SizedBox(height: 24),
      FormFieldBuilders.sectionHeader('NUTRITION MONITORING AND EVALUATION'),
      Row(
        children: [
          Expanded(
            child: FormFieldBuilders.checkbox(
              label: 'Adequacy of intake:',
              value: data['cb_is_eval_adequacy'] ?? false,
              onChanged: (v) => onChanged('cb_is_eval_adequacy', v),
            ),
          ),
          Expanded(
            child: FormFieldBuilders.checkbox(
              label: 'Calories',
              value: data['cb_eval_calories'] ?? false,
              onChanged: (v) => onChanged('cb_eval_calories', v),
            ),
          ),
          Expanded(
            child: FormFieldBuilders.checkbox(
              label: 'Protein',
              value: data['cb_eval_protein'] ?? false,
              onChanged: (v) => onChanged('cb_eval_protein', v),
            ),
          ),
          Expanded(
            child: FormFieldBuilders.checkbox(
              label: 'Fluid',
              value: data['cb_eval_fluid'] ?? false,
              onChanged: (v) => onChanged('cb_eval_fluid', v),
            ),
          ),
        ],
      ),
      Row(
        children: [
          Expanded(
            child: FormFieldBuilders.checkbox(
              label: 'Compliance to Diet',
              value: data['cb_eval_compliance'] ?? false,
              onChanged: (v) => onChanged('cb_eval_compliance', v),
            ),
          ),
          Expanded(
            child: FormFieldBuilders.checkbox(
              label: 'GI Tolerance',
              value: data['cb_eval_gi_tolerance'] ?? false,
              onChanged: (v) => onChanged('cb_eval_gi_tolerance', v),
            ),
          ),
          Expanded(
            child: FormFieldBuilders.checkbox(
              label: 'Weight Changes',
              value: data['cb_eval_weight_changes'] ?? false,
              onChanged: (v) => onChanged('cb_eval_weight_changes', v),
            ),
          ),
        ],
      ),
      FormFieldBuilders.textArea(
        label: 'Remarks',
        value: data['eval_remarks'] ?? '',
        onChanged: (v) => onChanged('eval_remarks', v),
      ),
    ];
  }

  static Widget _buildLabCell(String label, String key,
      Map<String, dynamic> data, void Function(String, dynamic) onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      child: TextField(
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(fontSize: 12),
          border: const OutlineInputBorder(),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        ),
        controller: TextEditingController(text: data[key] ?? '')
          ..selection = TextSelection.fromPosition(
              TextPosition(offset: (data[key] ?? '').toString().length)),
        onChanged: (v) => onChanged(key, v),
      ),
    );
  }

  // 8. Nutrition Progress Notes
  static List<Widget> _progressNotes(
    Map<String, dynamic> data,
    void Function(String, dynamic) onChanged, {
    bool Function(String) ro = _defaultRo,
  }) {
    List<Map<String, dynamic>> notesList =
        (data['notes_list'] as List?)?.cast<Map<String, dynamic>>() ?? [];

    return [
      FormFieldBuilders.sectionHeader('NUTRITION PROGRESS NOTES'),
      FormFieldBuilders.textField(
        label: 'Name of Client',
        value: data['client_name'] ?? '',
        onChanged: (v) => onChanged('client_name', v),
        readOnly: ro('client_name'),
      ),
      Row(
        children: [
          Expanded(
            child: FormFieldBuilders.textField(
              label: 'Age',
              value: data['age']?.toString() ?? '',
              onChanged: (v) => onChanged('age', v),
              readOnly: ro('age'),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: FormFieldBuilders.dropdown(
              label: 'Sex',
              value: data['sex'] ?? 'Male',
              items: const ['Male', 'Female'],
              onChanged: (v) => onChanged('sex', v),
              readOnly: ro('sex'),
            ),
          ),
        ],
      ),
      Row(
        children: [
          Expanded(
            child: FormFieldBuilders.textField(
              label: 'Height',
              value: data['height'] ?? '',
              onChanged: (v) => onChanged('height', v),
              readOnly: ro('height'),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: FormFieldBuilders.textField(
              label: 'Weight',
              value: data['weight'] ?? '',
              onChanged: (v) => onChanged('weight', v),
              readOnly: ro('weight'),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: FormFieldBuilders.textField(
              label: 'DBW',
              value: data['dbw'] ?? '',
              onChanged: (v) => onChanged('dbw', v),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: FormFieldBuilders.textField(
              label: 'Calf Circumference',
              value: data['cc'] ?? '',
              onChanged: (v) => onChanged('cc', v),
              readOnly: ro('cc'),
            ),
          ),
        ],
      ),
      FormFieldBuilders.textField(
        label: 'Nutritional Status',
        value: data['nutritional_status'] ?? '',
        onChanged: (v) => onChanged('nutritional_status', v),
      ),
      FormFieldBuilders.textArea(
        label: 'Dietary Prescription (Including Diet Order)',
        value: data['dietary_prescription'] ?? '',
        onChanged: (v) => onChanged('dietary_prescription', v),
      ),
      const SizedBox(height: 16),
      FormFieldBuilders.sectionHeader('PROGRESS ENTRIES'),
      StatefulBuilder(builder: (context, setState) {
        return Column(
          children: [
            for (int i = 0; i < notesList.length; i++)
              Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Entry ${i + 1}',
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold)),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () {
                              setState(() {
                                notesList.removeAt(i);
                                onChanged('notes_list', notesList);
                              });
                            },
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: FormFieldBuilders.datePicker(
                              label: 'Date',
                              value: notesList[i]['date'],
                              onChanged: (v) {
                                notesList[i]['date'] = v?.toIso8601String();
                                onChanged('notes_list', notesList);
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: FormFieldBuilders.timePicker(
                              label: 'Time Code',
                              value: notesList[i]['time_code'] ?? '',
                              onChanged: (v) {
                                final newList =
                                    List<Map<String, dynamic>>.from(notesList);
                                newList[i]['time_code'] = v;
                                onChanged('notes_list', newList);
                              },
                            ),
                          ),
                        ],
                      ),
                      FormFieldBuilders.textArea(
                        label: 'Progress or Status',
                        value: notesList[i]['progress_status'] ?? '',
                        onChanged: (v) {
                          notesList[i]['progress_status'] = v;
                          onChanged('notes_list', notesList);
                        },
                      ),
                      FormFieldBuilders.textField(
                        label: 'Actions to be Taken / Signature',
                        value: notesList[i]['actions_signature'] ?? '',
                        onChanged: (v) {
                          notesList[i]['actions_signature'] = v;
                          onChanged('notes_list', notesList);
                        },
                      ),
                    ],
                  ),
                ),
              ),
            TextButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('Add Progress Note'),
              onPressed: () {
                setState(() {
                  notesList.add({
                    'date': DateTime.now().toIso8601String(),
                    'time_code': '',
                    'progress_status': '',
                    'actions_signature': '',
                  });
                  onChanged('notes_list', notesList);
                });
              },
            ),
          ],
        );
      }),
    ];
  }

  static List<Widget> _statusSummary(
    Map<String, dynamic> data,
    void Function(String, dynamic) onChanged, {
    List<String>? residentNames,
    List<dynamic>? residents,
    String? title,
  }) {
    List<Map<String, dynamic>> clientsList =
        (data['clients_list'] as List?)?.cast<Map<String, dynamic>>() ?? [];

    return [
      FormFieldBuilders.sectionHeader(
          title ?? 'SUMMARY OF CLIENT NUTRITION STATUS'),
      Row(
        children: [
          Expanded(
            child: FormFieldBuilders.dropdown(
              label: 'Quarter',
              value: data['quarter'] ?? '1st',
              items: const ['1st', '2nd', '3rd', '4th'],
              onChanged: (v) => onChanged('quarter', v),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: FormFieldBuilders.textField(
              label: 'Year',
              value: data['year']?.toString() ?? DateTime.now().year.toString(),
              keyboardType: TextInputType.number,
              onChanged: (v) => onChanged('year', v),
            ),
          ),
        ],
      ),
      const SizedBox(height: 16),
      FormFieldBuilders.sectionHeader('CLIENTS LIST'),
      StatefulBuilder(builder: (context, setState) {
        void calculateCounts() {
          int malnourished = 0;
          int overweight = 0;
          int obese = 0;

          for (final c in clientsList) {
            final s = c['status']?.toString().toLowerCase() ?? '';
            if (s == 'underweight' || s == 'malnourished') malnourished++;
            if (s == 'overweight') overweight++;
            if (s == 'obese') obese++;
          }

          onChanged('total_malnourished', malnourished.toString());
          onChanged('total_overweight', overweight.toString());
          onChanged('total_obese', obese.toString());
        }

        void calculateRow(int index) {
          if (index < 0 || index >= clientsList.length) return;
          final row = clientsList[index];
          final weightStr = row['curr_wt']?.toString() ?? '';
          final heightStr = row['height']?.toString() ?? '';
          final idbwStr = row['idbw']?.toString() ?? '';

          final weight = double.tryParse(weightStr);
          final heightCm = double.tryParse(heightStr);
          final idbw = double.tryParse(idbwStr);

          // 1. Calculate BMI
          if (weight != null && heightCm != null && heightCm > 0) {
            final heightM = heightCm / 100;
            final bmiValue = weight / (heightM * heightM);
            row['bmi'] = bmiValue.toStringAsFixed(1);

            // 2. Determine Status
            if (bmiValue < 18.5) {
              row['status'] = 'Underweight';
            } else if (bmiValue < 25.0) {
              row['status'] = 'Normal';
            } else if (bmiValue < 30.0) {
              row['status'] = 'Overweight';
            } else {
              row['status'] = 'Obese';
            }
          }

          // 3. Calculate % IBW
          if (weight != null && idbw != null && idbw > 0) {
            final pctIbw = (weight / idbw) * 100;
            row['pct_ibw'] = pctIbw.toStringAsFixed(1);
          }

          calculateCounts();
        }

        return Column(
          children: [
            for (int i = 0; i < clientsList.length; i++)
              Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Client ${i + 1}',
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold)),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () {
                              setState(() {
                                clientsList.removeAt(i);
                                // Re-index No.
                                for (int j = 0; j < clientsList.length; j++) {
                                  clientsList[j]['no'] = (j + 1).toString();
                                }
                                onChanged('clients_list', clientsList);
                                calculateCounts();
                              });
                            },
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          SizedBox(
                            width: 60,
                            child: FormFieldBuilders.textField(
                              label: 'No.',
                              value: clientsList[i]['no'] ?? (i + 1).toString(),
                              enabled: false,
                              onChanged: (v) {
                                clientsList[i]['no'] = v;
                                onChanged('clients_list', clientsList);
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: FormFieldBuilders.typeAhead(
                              label: 'Name',
                              value: clientsList[i]['name'] ?? '',
                              useStaffSuggestions: false,
                              additionalSuggestions: residentNames ?? [],
                              onChanged: (v) {
                                clientsList[i]['name'] = v;
                                if (residents != null) {
                                  try {
                                    final resident = residents.firstWhere((r) =>
                                        '${r.firstName} ${r.lastName}'
                                            .trim()
                                            .toLowerCase() ==
                                        v.trim().toLowerCase());

                                    setState(() {
                                      clientsList[i]['gender'] =
                                          resident.gender;
                                      clientsList[i]['ward'] =
                                          resident.wardName;
                                      onChanged('clients_list', clientsList);
                                    });
                                  } catch (_) {}
                                }
                                onChanged('clients_list', clientsList);
                              },
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: FormFieldBuilders.dropdown(
                              label: 'Gender',
                              value: clientsList[i]['gender'],
                              items: const ['Male', 'Female'],
                              onChanged: (v) {
                                clientsList[i]['gender'] = v;
                                onChanged('clients_list', clientsList);
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: FormFieldBuilders.textField(
                              label: 'Ward',
                              value: clientsList[i]['ward'] ?? '',
                              onChanged: (v) {
                                clientsList[i]['ward'] = v;
                                onChanged('clients_list', clientsList);
                              },
                            ),
                          ),
                        ],
                      ),
                      FormFieldBuilders.textField(
                        label: 'Diet Order',
                        value: clientsList[i]['diet_order'] ?? '',
                        onChanged: (v) {
                          clientsList[i]['diet_order'] = v;
                          onChanged('clients_list', clientsList);
                        },
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: FormFieldBuilders.textField(
                              label: 'Ideal DBW (kg)',
                              value: clientsList[i]['idbw'] ?? '',
                              keyboardType: TextInputType.number,
                              onChanged: (v) {
                                clientsList[i]['idbw'] = v;
                                calculateRow(i);
                                onChanged('clients_list', clientsList);
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: FormFieldBuilders.textField(
                              label: 'Prev Wt (kg)',
                              value: clientsList[i]['prev_wt'] ?? '',
                              keyboardType: TextInputType.number,
                              onChanged: (v) {
                                clientsList[i]['prev_wt'] = v;
                                onChanged('clients_list', clientsList);
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: FormFieldBuilders.textField(
                              label: 'Curr Wt (kg)',
                              value: clientsList[i]['curr_wt'] ?? '',
                              keyboardType: TextInputType.number,
                              onChanged: (v) {
                                clientsList[i]['curr_wt'] = v;
                                calculateRow(i);
                                onChanged('clients_list', clientsList);
                              },
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: FormFieldBuilders.textField(
                              label: '% IBW',
                              value: clientsList[i]['pct_ibw'] ?? '',
                              onChanged: (v) {
                                clientsList[i]['pct_ibw'] = v;
                                onChanged('clients_list', clientsList);
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: FormFieldBuilders.textField(
                              label: '% UBW',
                              value: clientsList[i]['pct_ubw'] ?? '',
                              onChanged: (v) {
                                clientsList[i]['pct_ubw'] = v;
                                onChanged('clients_list', clientsList);
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: FormFieldBuilders.textField(
                              label: '% Wt Change',
                              value: clientsList[i]['pct_wt_change'] ?? '',
                              onChanged: (v) {
                                clientsList[i]['pct_wt_change'] = v;
                                onChanged('clients_list', clientsList);
                              },
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: FormFieldBuilders.textField(
                              label: 'Height (cm)',
                              value: clientsList[i]['height'] ?? '',
                              keyboardType: TextInputType.number,
                              onChanged: (v) {
                                clientsList[i]['height'] = v;
                                calculateRow(i);
                                onChanged('clients_list', clientsList);
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: FormFieldBuilders.textField(
                              label: 'Calf Circ',
                              value: clientsList[i]['calf_circ'] ?? '',
                              keyboardType: TextInputType.number,
                              onChanged: (v) {
                                clientsList[i]['calf_circ'] = v;
                                onChanged('clients_list', clientsList);
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: FormFieldBuilders.textField(
                              label: 'BMI',
                              value: clientsList[i]['bmi'] ?? '',
                              keyboardType: TextInputType.number,
                              onChanged: (v) {
                                clientsList[i]['bmi'] = v;
                                onChanged('clients_list', clientsList);
                              },
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: FormFieldBuilders.textField(
                              label: 'Nutrition Status',
                              value: clientsList[i]['status'] ?? '',
                              onChanged: (v) {
                                clientsList[i]['status'] = v;
                                calculateCounts();
                                onChanged('clients_list', clientsList);
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: FormFieldBuilders.textField(
                              label: 'Target',
                              value: clientsList[i]['target'] ?? '',
                              onChanged: (v) {
                                clientsList[i]['target'] = v;
                                onChanged('clients_list', clientsList);
                              },
                            ),
                          ),
                        ],
                      ),
                      FormFieldBuilders.textField(
                        label: 'Nutrition Risk',
                        value: clientsList[i]['risk'] ?? '',
                        onChanged: (v) {
                          clientsList[i]['risk'] = v;
                          onChanged('clients_list', clientsList);
                        },
                      ),
                      FormFieldBuilders.textArea(
                        label: 'Intervention',
                        value: clientsList[i]['intervention'] ?? '',
                        onChanged: (v) {
                          clientsList[i]['intervention'] = v;
                          onChanged('clients_list', clientsList);
                        },
                      ),
                      FormFieldBuilders.textArea(
                        label: 'Remarks/Findings',
                        value: clientsList[i]['remarks'] ?? '',
                        onChanged: (v) {
                          clientsList[i]['remarks'] = v;
                          onChanged('clients_list', clientsList);
                        },
                      ),
                    ],
                  ),
                ),
              ),
            TextButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('Add Client'),
              onPressed: () {
                setState(() {
                  clientsList.add({
                    'no': (clientsList.length + 1).toString(),
                    'name': '',
                    'gender': 'Male',
                    'ward': '',
                    'diet_order': '',
                    'idbw': '',
                    'prev_wt': '',
                    'curr_wt': '',
                    'pct_ibw': '',
                    'pct_ubw': '',
                    'pct_wt_change': '',
                    'height': '',
                    'calf_circ': '',
                    'bmi': '',
                    'status': '',
                    'target': '',
                    'risk': '',
                    'intervention': '',
                    'remarks': '',
                  });
                  onChanged('clients_list', clientsList);
                });
              },
            ),
          ],
        );
      }),
      const SizedBox(height: 16),
      FormFieldBuilders.sectionHeader('SUMMARY STATUS'),
      Table(
        border: TableBorder.all(color: Colors.grey.shade300),
        columnWidths: const {
          0: FlexColumnWidth(4),
          1: FlexColumnWidth(1),
        },
        children: [
          _buildSummaryRow(
            'Total Number of Malnourished (Nutritionally-at-risk)',
            data['total_malnourished']?.toString() ?? '0',
          ),
          _buildSummaryRow(
            'Overweight',
            data['total_overweight']?.toString() ?? '0',
          ),
          _buildSummaryRow(
            'Obese',
            data['total_obese']?.toString() ?? '0',
          ),
        ],
      ),
      const SizedBox(height: 16),
      FormFieldBuilders.textArea(
        label: 'Remarks/Findings',
        value: data['remarks'] ?? '',
        onChanged: (v) => onChanged('remarks', v),
      ),
    ];
  }

  // 10. BMI Summary Form
  static List<Widget> _bmiSummary(
    Map<String, dynamic> data,
    void Function(String, dynamic) onChanged, {
    List<String>? residentNames,
    List<dynamic>? residents,
  }) {
    return _statusSummary(data, onChanged,
        residentNames: residentNames,
        residents: residents,
        title: 'BMI SUMMARY');
  }

  static TableRow _buildSummaryRow(String label, String value) {
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            value,
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  /// Helper to build dropdown selection for MNA scores
  static Widget _buildMnaDropdownSelection(
    String label,
    String key,
    List<String> options,
    dynamic currentValue,
    Function onChanged,
  ) {
    return FormFieldBuilders.dropdown(
      label: label,
      value: (currentValue != null)
          ? options.firstWhere(
              (o) => o.startsWith(currentValue.toString()),
              orElse: () => options.first,
            )
          : null,
      items: options,
      onChanged: (v) {
        if (v != null) {
          final score = v.split(' = ')[0].trim();
          onChanged(key, score);
        }
      },
    );
  }

  // 11. Dietary Kardex and Meal Distribution Plan
  static List<Widget> _dietaryKardex(
    Map<String, dynamic> data,
    void Function(String, dynamic) onChanged, {
    List<String>? residentNames,
    List<dynamic>? residents,
  }) {
    // Recalculate Totals Helper
    void recalculateTotals(Map<String, dynamic> currentData) {
      final rows = [
        'veg',
        'fru',
        'milk',
        'rice_l',
        'rice_m',
        'rice_h',
        'meat_l',
        'meat_m',
        'meat_h',
        'fat',
        'sugar'
      ];
      final cols = [
        'cho',
        'chon',
        'fat',
        'cal',
        'b',
        'l',
        's',
        'am',
        'pm',
        'mn'
      ];

      Map<String, double> totals = {for (var c in cols) c: 0.0};

      for (var row in rows) {
        for (var col in cols) {
          final val =
              double.tryParse(currentData['${row}_$col']?.toString() ?? '0');
          if (val != null) totals[col] = totals[col]! + val;
        }
      }

      for (var col in cols) {
        onChanged('total_$col', totals[col]!.toStringAsFixed(1));
      }
    }

    return [
      FormFieldBuilders.sectionHeader('CLIENT PROFILE'),
      FormFieldBuilders.typeAhead(
        label: 'Name',
        value: data['client_name'] ?? '',
        additionalSuggestions: residentNames ?? [],
        onChanged: (v) {
          onChanged('client_name', v);
          if (residents != null) {
            try {
              final res = residents.firstWhere(
                (r) =>
                    '${r['first_name']} ${r['last_name']}'.toUpperCase() ==
                    v.toUpperCase(),
                orElse: () => null,
              );
              if (res != null) {
                onChanged('hrn', res['resident_code'] ?? '');
                onChanged('age', res['age']?.toString() ?? '');
                onChanged('sex', res['gender'] ?? 'Male');
                onChanged('ward', res['ward_name'] ?? '');
                onChanged('birthdate', res['date_of_birth'] ?? '');
                onChanged('address', res['address'] ?? '');
                onChanged('religion', res['religion'] ?? '');
                onChanged('diagnosis', res['primary_diagnosis'] ?? '');
              }
            } catch (_) {}
          }
        },
      ),
      Row(
        children: [
          Expanded(
            child: FormFieldBuilders.textField(
              label: 'HRN (Case No.)',
              value: data['hrn'] ?? '',
              onChanged: (v) => onChanged('hrn', v),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: FormFieldBuilders.textField(
              label: 'Age',
              value: data['age'] ?? '',
              onChanged: (v) => onChanged('age', v),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: FormFieldBuilders.dropdown(
              label: 'Sex',
              value: data['sex'] ?? 'Male',
              items: const ['Male', 'Female'],
              onChanged: (v) => onChanged('sex', v),
            ),
          ),
        ],
      ),
      Row(
        children: [
          Expanded(
            child: FormFieldBuilders.textField(
              label: 'Ward/Rm No.',
              value: data['ward'] ?? '',
              onChanged: (v) => onChanged('ward', v),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: FormFieldBuilders.datePicker(
              label: 'Birthdate',
              value: data['birthdate'],
              onChanged: (v) => onChanged('birthdate', v?.toIso8601String()),
            ),
          ),
        ],
      ),
      FormFieldBuilders.textField(
        label: 'Address',
        value: data['address'] ?? '',
        onChanged: (v) => onChanged('address', v),
      ),
      Row(
        children: [
          Expanded(
            child: FormFieldBuilders.textField(
              label: 'Occupation',
              value: data['occupation'] ?? '',
              onChanged: (v) => onChanged('occupation', v),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: FormFieldBuilders.textField(
              label: 'Religion',
              value: data['religion'] ?? '',
              onChanged: (v) => onChanged('religion', v),
            ),
          ),
        ],
      ),
      FormFieldBuilders.textField(
        label: 'Medical Diagnosis',
        value: data['diagnosis'] ?? '',
        onChanged: (v) => onChanged('diagnosis', v),
      ),
      FormFieldBuilders.textField(
        label: 'Diet Order',
        value: data['diet_order'] ?? '',
        onChanged: (v) => onChanged('diet_order', v),
      ),
      Row(
        children: [
          Expanded(
            child: FormFieldBuilders.datePicker(
              label: 'Date of Admission/Consultation',
              value: data['date_admitted'],
              onChanged: (v) =>
                  onChanged('date_admitted', v?.toIso8601String()),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: FormFieldBuilders.typeAhead(
              label: 'Physician',
              value: data['physician'] ?? '',
              useStaffSuggestions: true,
              filterUnit: 'medical',
              onChanged: (v) => onChanged('physician', v),
            ),
          ),
        ],
      ),
      const SizedBox(height: 24),
      FormFieldBuilders.sectionHeader('DIETARY KARDEX AND MEAL DISTRIBUTION'),
      const SizedBox(height: 16),
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Column(
          children: [
            // Super Header Row
            Row(
              children: [
                _buildKardexHeaderCell('FOOD ITEM', width: 140, height: 60),
                _buildKardexHeaderCell('# OF EX.', width: 50, height: 60),
                _buildKardexHeaderCell('HHM', width: 50, height: 60),
                _buildKardexHeaderCell('CHO (g)', width: 50, height: 60),
                _buildKardexHeaderCell('CHON (g)', width: 50, height: 60),
                _buildKardexHeaderCell('FAT (g)', width: 50, height: 60),
                _buildKardexHeaderCell('Cal', width: 50, height: 60),
                _buildKardexHeaderCell('B', width: 40, height: 60),
                _buildKardexHeaderCell('L', width: 40, height: 60),
                _buildKardexHeaderCell('S', width: 40, height: 60),
                Column(
                  children: [
                    _buildKardexHeaderCell('SNACKS', width: 120, height: 30),
                    Row(
                      children: [
                        _buildKardexHeaderCell('AM', width: 40, height: 30),
                        _buildKardexHeaderCell('PM', width: 40, height: 30),
                        _buildKardexHeaderCell('MN', width: 40, height: 30),
                      ],
                    ),
                  ],
                ),
                _buildKardexHeaderCell('NOTES', width: 100, height: 60),
              ],
            ),
            // Data Rows
            _buildExchangeRow('Vegetable', 'veg', data, (k, v) {
              onChanged(k, v);
              recalculateTotals({...data, k: v});
            }),
            _buildExchangeRow('Fruits', 'fru', data, (k, v) {
              onChanged(k, v);
              recalculateTotals({...data, k: v});
            }),
            _buildExchangeRow('Milk', 'milk', data, (k, v) {
              onChanged(k, v);
              recalculateTotals({...data, k: v});
            }),
            // Rice Group
            _buildExchangeRow('Rice: Low Protein', 'rice_l', data, (k, v) {
              onChanged(k, v);
              recalculateTotals({...data, k: v});
            }),
            _buildExchangeRow('Medium Protein', 'rice_m', data, (k, v) {
              onChanged(k, v);
              recalculateTotals({...data, k: v});
            }, isSubRow: true),
            _buildExchangeRow('High Protein', 'rice_h', data, (k, v) {
              onChanged(k, v);
              recalculateTotals({...data, k: v});
            }, isSubRow: true),
            // Meat Group
            _buildExchangeRow('Meat (L)', 'meat_l', data, (k, v) {
              onChanged(k, v);
              recalculateTotals({...data, k: v});
            }),
            _buildExchangeRow('(M)', 'meat_m', data, (k, v) {
              onChanged(k, v);
              recalculateTotals({...data, k: v});
            }, isSubRow: true),
            _buildExchangeRow('(H)', 'meat_h', data, (k, v) {
              onChanged(k, v);
              recalculateTotals({...data, k: v});
            }, isSubRow: true),
            _buildExchangeRow('Fat', 'fat', data, (k, v) {
              onChanged(k, v);
              recalculateTotals({...data, k: v});
            }),
            _buildExchangeRow('Sugar', 'sugar', data, (k, v) {
              onChanged(k, v);
              recalculateTotals({...data, k: v});
            }),
            // Totals Row
            Container(
              color: Colors.grey.shade100,
              child: Row(
                children: [
                  _buildKardexHeaderCell('TOTALS', width: 140),
                  _buildKardexHeaderCell('', width: 50),
                  _buildKardexHeaderCell('', width: 50),
                  _buildKardexTotalCell(data['total_cho'] ?? '0', width: 50),
                  _buildKardexTotalCell(data['total_chon'] ?? '0', width: 50),
                  _buildKardexTotalCell(data['total_fat'] ?? '0', width: 50),
                  _buildKardexTotalCell(data['total_cal'] ?? '0', width: 50),
                  _buildKardexTotalCell(data['total_b'] ?? '0', width: 40),
                  _buildKardexTotalCell(data['total_l'] ?? '0', width: 40),
                  _buildKardexTotalCell(data['total_s'] ?? '0', width: 40),
                  _buildKardexTotalCell(data['total_am'] ?? '0', width: 40),
                  _buildKardexTotalCell(data['total_pm'] ?? '0', width: 40),
                  _buildKardexTotalCell(data['total_mn'] ?? '0', width: 40),
                  _buildKardexHeaderCell('', width: 100),
                ],
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 16),
      FormFieldBuilders.textArea(
        label: 'Notes / Explanations for Table (General)',
        value: data['table_notes_general'] ?? '',
        onChanged: (v) => onChanged('table_notes_general', v),
        hint: 'General observations...',
      ),
      const SizedBox(height: 24),
      FormFieldBuilders.sectionHeader('SAMPLE MENU'),
      Row(
        children: [
          Expanded(
            child: FormFieldBuilders.textArea(
              label: 'Breakfast (6:00 AM)',
              value: data['breakfast_menu'] ?? '',
              onChanged: (v) => onChanged('breakfast_menu', v),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: FormFieldBuilders.textArea(
              label: 'AM Snacks (9:00 AM)',
              value: data['am_snack_menu'] ?? '',
              onChanged: (v) => onChanged('am_snack_menu', v),
            ),
          ),
        ],
      ),
      Row(
        children: [
          Expanded(
            child: FormFieldBuilders.textArea(
              label: 'Lunch (12:00 NN)',
              value: data['lunch_menu'] ?? '',
              onChanged: (v) => onChanged('lunch_menu', v),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: FormFieldBuilders.textArea(
              label: 'PM Snacks (3:00 PM)',
              value: data['pm_snack_menu'] ?? '',
              onChanged: (v) => onChanged('pm_snack_menu', v),
            ),
          ),
        ],
      ),
      Row(
        children: [
          Expanded(
            child: FormFieldBuilders.textArea(
              label: 'Supper (6:00 PM)',
              value: data['supper_menu'] ?? '',
              onChanged: (v) => onChanged('supper_menu', v),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: FormFieldBuilders.textArea(
              label: 'Bedtime Snacks (9:00 PM)',
              value: data['bedtime_snack_menu'] ?? '',
              onChanged: (v) => onChanged('bedtime_snack_menu', v),
            ),
          ),
        ],
      ),
      const SizedBox(height: 16),
      FormFieldBuilders.textArea(
        label: 'Remarks',
        value: data['remarks'] ?? '',
        onChanged: (v) => onChanged('remarks', v),
      ),
    ];
  }

  static Widget _buildExchangeRow(
    String label,
    String prefix,
    Map<String, dynamic> data,
    void Function(String, dynamic) onChanged, {
    bool isSubRow = false,
  }) {
    return Row(
      children: [
        Container(
          width: 140,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          alignment: Alignment.centerLeft,
          decoration:
              BoxDecoration(border: Border.all(color: Colors.grey.shade300)),
          child: Text(
            label,
            style: TextStyle(
              fontWeight: isSubRow ? FontWeight.normal : FontWeight.bold,
              fontSize: 11,
              fontStyle: isSubRow ? FontStyle.italic : FontStyle.normal,
            ),
          ),
        ),
        _buildExchangeCell('${prefix}_ex', data, onChanged, width: 50),
        _buildExchangeCell('${prefix}_hhm', data, onChanged, width: 50),
        _buildExchangeCell('${prefix}_cho', data, onChanged, width: 50),
        _buildExchangeCell('${prefix}_chon', data, onChanged, width: 50),
        _buildExchangeCell('${prefix}_fat', data, onChanged, width: 50),
        _buildExchangeCell('${prefix}_cal', data, onChanged, width: 50),
        _buildExchangeCell('${prefix}_b', data, onChanged, width: 40),
        _buildExchangeCell('${prefix}_l', data, onChanged, width: 40),
        _buildExchangeCell('${prefix}_s', data, onChanged, width: 40),
        _buildExchangeCell('${prefix}_am', data, onChanged, width: 40),
        _buildExchangeCell('${prefix}_pm', data, onChanged, width: 40),
        _buildExchangeCell('${prefix}_mn', data, onChanged, width: 40),
        _buildExchangeCell('${prefix}_notes', data, onChanged, width: 100),
      ],
    );
  }

  static Widget _buildExchangeCell(
    String key,
    Map<String, dynamic> data,
    void Function(String, dynamic) onChanged, {
    double width = 50,
  }) {
    return Container(
      width: width,
      height: 40,
      decoration:
          BoxDecoration(border: Border.all(color: Colors.grey.shade300)),
      child: TextField(
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 11),
        decoration: const InputDecoration(
          border: InputBorder.none,
          contentPadding: EdgeInsets.zero,
        ),
        controller: TextEditingController(text: data[key]?.toString() ?? '')
          ..selection = TextSelection.fromPosition(
              TextPosition(offset: (data[key]?.toString() ?? '').length)),
        onChanged: (v) => onChanged(key, v),
      ),
    );
  }

  static Widget _buildKardexHeaderCell(String label,
      {double width = 50, double? height}) {
    return Container(
      width: width,
      height: height,
      padding: const EdgeInsets.all(4),
      alignment: Alignment.center,
      decoration: BoxDecoration(
          color: Colors.grey.shade200,
          border: Border.all(color: Colors.grey.shade300)),
      child: Text(label,
          textAlign: TextAlign.center,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10)),
    );
  }

  static Widget _buildKardexTotalCell(String label, {double width = 50}) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(8),
      alignment: Alignment.center,
      decoration:
          BoxDecoration(border: Border.all(color: Colors.grey.shade300)),
      child: Text(label,
          textAlign: TextAlign.center,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10)),
    );
  }

  static void _calculateBmiAndMna(
    Map<String, dynamic> data,
    void Function(String, dynamic) onChanged,
    void Function(Map<String, dynamic>) recalculateScores,
  ) {
    final h = double.tryParse(data['height_cm']?.toString() ?? '0');
    final w = double.tryParse(data['weight_kg']?.toString() ?? '0');

    if (h != null && w != null && h > 0) {
      final bmi = w / ((h / 100) * (h / 100));
      String score = '0';
      if (bmi >= 23) {
        score = '3';
      } else if (bmi >= 21) {
        score = '2';
      } else if (bmi >= 19) {
        score = '1';
      }

      onChanged('mna_f_score', score);
      data['mna_f_score'] = score;
      recalculateScores(data);
    }
  }
}
