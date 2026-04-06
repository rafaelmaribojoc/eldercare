import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/services.dart'; // Added for FilteringTextInputFormatter
import 'package:intl/intl.dart';
import '../../../core/services/pdf_service.dart';
import '../../../core/widgets/custom_snackbar.dart';

import '../../../core/theme/app_colors.dart';
import '../../../data/models/ward_model.dart';
import '../../../data/models/resident_model.dart';
import '../../../data/repositories/resident_repository.dart';
import '../../../core/constants/form_options.dart';
import '../../../data/repositories/address_repository.dart';
import '../../../data/repositories/admin_repository.dart'; // Added
import '../../../data/models/user_model.dart'; // Added
import '../../../core/utils/text_formatters.dart';
import '../../../core/utils/responsive.dart';

class AddResidentScreen extends StatefulWidget {
  final ResidentModel? resident;
  final bool isAdmitting;

  const AddResidentScreen({super.key, this.resident, this.isAdmitting = false});

  @override
  State<AddResidentScreen> createState() => _AddResidentScreenState();
}

class _AddResidentScreenState extends State<AddResidentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _middleNameController = TextEditingController();
  final _nicknameController = TextEditingController();
  final _placeOfBirthController = TextEditingController();
  // _referringAddressController removed in favor of structured address
  final _streetAddressController = TextEditingController();
  final _custodianNameController = TextEditingController();

  final _emergencyNameController = TextEditingController();
  final _emergencyPhoneController = TextEditingController();
  // Removed medical controllers
  // final _allergiesController = TextEditingController();
  // final _diagnosisController = TextEditingController();
  // final _notesController = TextEditingController();

  DateTime? _dateOfBirth;
  DateTime? _admissionDate;
  DateTime? _applicationDate;
  String _gender = 'male';
  WardModel? _selectedWard;
  List<WardModel> _wards = [];
  Uint8List? _photoBytes;
  bool _isLoading = false;
  int _currentStep = 0;

  // New Dropdown State Variables
  final _addressRepository = AddressRepository();
  final _adminRepository = AdminRepository(); // Added

  List<UserModel> _houseparents = []; // Added
  String? _selectedHouseparentId; // Added
  List<UserModel> _socialWorkers = []; // Added for Social Worker assignment
  String? _selectedSocialWorkerId;

  final _mentalHealthConditionController = TextEditingController(); // Added

  // Mental Health Conditions
  final List<String> _mentalHealthConditions = [
    'MAJOR NCD DUE TO ALZHEIMER’S DISEASE',
    'MAJOR NCD DUE TO VASCULAR DISEASE',
    'MAJOR NCD WITH LEWY BODIES',
    'MAJOR NCD DUE TO PARKINSON’S DISEASE',
    'FRONTO-TEMPORAL NCD',
    'MILD NEUROCOGNITIVE DISORDER',
    'TRAUMATIC BRAIN INJURY',
    'SUBSTANCE/MEDICATION-INDUCED NCD',
    'SCHIZOPHRENIA',
    'BIPOLAR DISORDER',
    'MAJOR DEPRESSIVE DISORDER',
    'ANXIETY DISORDER',
    'OTHERS',
  ];

  String? _selectedSuffix;

  // Referral
  String? _selectedReferralSource;
  final _referralOtherController = TextEditingController();
  final _referralContactPersonController = TextEditingController(); // Added

  // Referral Address State
  String? _referralSelectedProvince;
  String? _referralSelectedCity;
  String? _referralSelectedBarangay;
  final _referralStreetAddressController = TextEditingController();
  List<String> _referralCityList = [];
  List<String> _referralBarangayList = [];

  // Case & Condition
  String? _selectedCaseCategory;
  final _caseNumberController = TextEditingController(); // Added
  final _conditionController = TextEditingController();
  final _disabilityController = TextEditingController();

  // Address
  String? _selectedProvince;
  String? _selectedCity;
  String? _selectedBarangay;
  List<String> _provinceList = [];
  List<String> _cityList = [];
  List<String> _barangayList = [];

  // Place of Birth State
  String? _pobSelectedProvince;
  String? _pobSelectedCity;
  List<String> _pobCityList = [];

  // Social
  String? _selectedCivilStatus;

  // Education & Religion
  String? _selectedEducation;
  String? _selectedYearsEducation;
  String? _selectedGradeLevel;
  List<String> _gradeLevelOptions = [];
  bool _isK12 = false;
  String? _selectedReligion;
  final _religionOtherController = TextEditingController();

  // Relationships
  String? _selectedEmergencyRelation;
  final _emergencyRelationOtherController = TextEditingController();

  // Actually we need `_nearestRelativeRelationship` if we are mapping FROM the family member list to the DB format.
  // BUT we don't need a UI controller for it anymore as it's part of the family member data.
  // However, `_saveResident` still references it? No, I updated `_saveResident` to pull from family member.
  // So I can remove these too.

  // Ward Capacity
  List<String> _availableBeds = [];
  String? _selectedBed;
  bool _loadingBeds = false;

  // Family Composition Data
  // Keys: name, relationship, age, occupation, address, contact
  List<Map<String, String>> _familyMembers = [];
  // _familyFormKey was unused and removed
  // Selection State
  String? _selectedNearestRelativeName;
  String? _selectedEmergencyContactName;
  String? _selectedCustodianName;

  String _admissionStatus = 'admitted'; // 'admitted' or 'pre_admission'
  bool _isIdentityUnknown = false;

  // Temporary list of hidden values to filter out locally before refresh
  final Set<String> _tempHiddenValues = {};

  // Responsive layout helper
  Widget _buildResponsiveRow({
    required List<Widget> children,
    List<int>? flexes,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < Breakpoints.tablet) {
          // Phone: Column
          return Column(
            children: children
                .map((c) => Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: c,
                    ))
                .toList(),
          );
        } else {
          // Tablet/Desktop: Row
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: List.generate(children.length, (index) {
              return Expanded(
                flex:
                    flexes != null && flexes.length > index ? flexes[index] : 1,
                child: Padding(
                  padding: EdgeInsets.only(
                      right: index < children.length - 1 ? 16.0 : 0),
                  child: children[index],
                ),
              );
            }),
          );
        }
      },
    );
  }

  @override
  void initState() {
    super.initState();
    _isLoading = true; // Start loading
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initData();
    });
    _nicknameController.addListener(_syncNameWithNickname);
  }

  Future<void> _initData() async {
    // Artificial delay to ensure push animation completes smoothly if needed
    // await Future.delayed(const Duration(milliseconds: 100));

    await _loadLocations();
    if (!mounted) return;

    await _loadWards(); // Can run in parallel or after
    if (!mounted) return;

    await _loadHouseparents(); // Added
    if (!mounted) return;

    if (widget.resident != null) {
      if (mounted) {
        setState(() {
          _initializeWithResident(widget.resident!);
          // Force 'admitted' status if this is an admission flow
          if (widget.isAdmitting) {
            _admissionStatus = 'admitted';
            _admissionDate ??= DateTime.now();
            // Trigger suggestion for Admission Case Number (C-...)
            // removing old pre-admission suggestion
            _suggestNextNumber(_admissionDate!, isAdmission: true);
          }
          _isLoading = false;
        });
      }
    } else {
      if (mounted) {
        setState(() {
          _admissionDate = DateTime.now();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadHouseparents() async {
    try {
      final houseparents = await _adminRepository.getHouseparents();
      final socialWorkers = await _adminRepository.getSocialWorkers();
      if (mounted) {
        setState(() {
          _houseparents = houseparents;
          _socialWorkers = socialWorkers;
        });
      }
    } catch (e) {
      debugPrint('Error loading houseparents: $e');
    }
  }

  @override
  void dispose() {
    _nicknameController.removeListener(_syncNameWithNickname);
    _firstNameController.dispose();
    _lastNameController.dispose();
    _middleNameController.dispose();
    _nicknameController.dispose();
    _placeOfBirthController.dispose();
    _streetAddressController.dispose();
    _custodianNameController.dispose();
    _emergencyNameController.dispose();
    _emergencyPhoneController.dispose();
    _referralOtherController.dispose();
    _referralContactPersonController.dispose(); // Added
    _referralStreetAddressController.dispose();
    _religionOtherController.dispose();
    _emergencyRelationOtherController.dispose();
    _caseNumberController.dispose(); // Added
    _conditionController.dispose();
    super.dispose();
  }

  void _syncNameWithNickname() {
    if (_isIdentityUnknown) {
      String honorific;
      if (_dateOfBirth != null) {
        final age = DateTime.now().year - _dateOfBirth!.year;
        if (age < 18) {
          honorific = _gender == 'female' ? 'Nene' : 'Toto';
        } else if (age < 60) {
          honorific = _gender == 'female' ? 'Manang' : 'Manong';
        } else {
          honorific = _gender == 'female' ? 'Lola' : 'Lolo';
        }
      } else {
        // Default to Senior if no DOB
        honorific = _gender == 'female' ? 'Lola' : 'Lolo';
      }

      _firstNameController.text = honorific;
      _lastNameController.text = _nicknameController.text.trim().isEmpty
          ? 'Resident'
          : _nicknameController.text.trim();
    }
  }

  void _initializeWithResident(ResidentModel resident) {
    _firstNameController.text = resident.firstName;
    _lastNameController.text = resident.lastName;
    _middleNameController.text = resident.middleName ?? '';
    // _suffixController handled by dropdown
    if (resident.suffix != null &&
        FormOptions.suffixes.contains(resident.suffix)) {
      _selectedSuffix = resident.suffix;
    }

    _selectedHouseparentId = resident.houseparentId; // Added
    _selectedSocialWorkerId = resident.socialWorkerId;

    _conditionController.text = resident.condition ?? '';
    if ((resident.firstName == 'Unknown' ||
            resident.firstName == 'Lolo' ||
            resident.firstName == 'Lola') &&
        (resident.lastName == 'Resident' ||
            resident.lastName == resident.nickname)) {
      _isIdentityUnknown = true;
    }

    _nicknameController.text = resident.nickname ?? '';
    // Place of Birth - Attempt split "City, Province"
    if (resident.placeOfBirth != null) {
      final parts = resident.placeOfBirth!.split(', ');
      if (parts.length >= 2) {
        _pobSelectedCity = parts[0].trim();
        _pobSelectedProvince = parts[1].trim();

        // Legacy Fix: Map Compostela Valley to Davao de Oro
        if (_pobSelectedProvince?.toUpperCase() == 'COMPOSTELA VALLEY') {
          _pobSelectedProvince = 'DAVAO DE ORO';
        }

        // Case-Insensitive Matching
        final provMatch = _provinceList.firstWhere(
            (p) => p.toUpperCase() == _pobSelectedProvince?.toUpperCase(),
            orElse: () => '');

        if (provMatch.isNotEmpty) {
          _pobSelectedProvince = provMatch;
          _pobCityList = _addressRepository.getCities(_pobSelectedProvince!);

          final cityMatch = _pobCityList.firstWhere(
              (c) => c.toUpperCase() == _pobSelectedCity?.toUpperCase(),
              orElse: () => '');

          if (cityMatch.isNotEmpty) {
            _pobSelectedCity = cityMatch;
          } else {
            // Check for loose match (contains)
            final looseCityMatch = _pobCityList.firstWhere(
                (c) => c
                    .toUpperCase()
                    .contains(_pobSelectedCity?.toUpperCase() ?? 'XYZ'),
                orElse: () => '');
            if (looseCityMatch.isNotEmpty) {
              _pobSelectedCity = looseCityMatch;
            } else {
              _pobSelectedCity = null;
            }
          }
        } else {
          // If Province not found, try to find by City alone in common provinces?
          // Too expensive. Just leave null.
          _pobSelectedProvince = null;
          _pobSelectedCity = null;
        }
      } else {
        // Data is not in "City, Province" format.
        // Try to match entire string as Province or City?
        // For now, accept that structured data is required.
      }
    }

    // Referral
    _referralOtherController.text = resident.referredBy ?? '';
    _selectedReferralSource =
        resident.referredBy; // Keep for reference if needed
    // _setDropdownValue(resident.referredBy, FormOptions.referralSources,
    //    (v) => _selectedReferralSource = v, _referralOtherController);
    _referralContactPersonController.text =
        resident.referringContactPerson ?? ''; // Added

    // Attempt parse Referral Address "Street, Barangay, City, Province"
    // IMPROVED: Reverse Parsing to handle commas in street name
    _parseReferralAddress(resident);

    // Case
    _caseNumberController.text = resident.caseNumber ?? ''; // Added
    if (resident.caseCategory != null &&
        FormOptions.caseCategories.contains(resident.caseCategory)) {
      _selectedCaseCategory = resident.caseCategory;
    }

    _conditionController.text = resident.condition ?? '';
    _disabilityController.text = resident.natureOfDisability ?? '';

    // Address
    _selectedProvince = resident.province;
    // Legacy Fix: Map Compostela Valley to Davao de Oro
    if (_selectedProvince?.toUpperCase() == 'COMPOSTELA VALLEY') {
      _selectedProvince = 'DAVAO DE ORO';
    }

    if (_selectedProvince != null) {
      _cityList = _addressRepository.getCities(_selectedProvince!);
      _selectedCity = resident.city;
      if (_selectedCity != null) {
        _barangayList =
            _addressRepository.getBarangays(_selectedProvince!, _selectedCity!);
        _selectedBarangay = resident.barangay;
      }
    }
    _streetAddressController.text = resident.streetAddress ?? '';

    // Social
    _selectedCivilStatus = resident.civilStatus?.toUpperCase();
    _mentalHealthConditionController.text =
        resident.mentalHealthCondition ?? ''; // Added

    // Education - special handling for dynamic logic
    _selectedEducation = resident.educationalAttainment;
    // Trigger option population
    if (_selectedEducation != null) {
      if (_selectedEducation!.contains('Elementary Level')) {
        _gradeLevelOptions = FormOptions.elementaryGrades;
      } else if (_selectedEducation!.contains('Senior High School Level')) {
        _gradeLevelOptions = FormOptions.seniorHighGrades;
      } else if (_selectedEducation!.contains('High School Level') ||
          _selectedEducation!.contains('Junior High School Level')) {
        _gradeLevelOptions = FormOptions.highSchoolGrades;
      } else if (_selectedEducation!.contains('College Level')) {
        _gradeLevelOptions = FormOptions.collegeYears;
      } else if (_selectedEducation!.contains('Vocational')) {
        _gradeLevelOptions = FormOptions.vocationalDurations;
      }
    }

    _selectedYearsEducation = resident.yearsOfEducation;

    // Attempt to restore Grade Level selection based on Years
    if (_gradeLevelOptions.isNotEmpty && _selectedYearsEducation != null) {
      final years = int.tryParse(_selectedYearsEducation!);
      if (years != null) {
        // Logic must match _onGradeLevelChanged
        for (var option in _gradeLevelOptions) {
          int optionYears = 0;
          if (_selectedEducation!.contains('Elementary Level')) {
            optionYears = int.tryParse(option.split(' ').last) ?? 0;
          } else if (_selectedEducation!.contains('Senior High School Level')) {
            optionYears = int.tryParse(option.split(' ').last) ?? 0;
          } else if (_selectedEducation!.contains('High School Level') ||
              _selectedEducation!.contains('Junior High School Level')) {
            if (option.contains('First')) optionYears = 7;
            if (option.contains('Second')) optionYears = 8;
            if (option.contains('Third')) optionYears = 9;
            if (option.contains('Fourth')) optionYears = 10;
          } else if (_selectedEducation!.contains('College Level')) {
            int n = 0;
            if (option.contains('1st')) n = 1;
            if (option.contains('2nd')) n = 2;
            if (option.contains('3rd')) n = 3;
            if (option.contains('4th')) n = 4;
            optionYears = 10 + n;
          } else if (_selectedEducation!.contains('Vocational')) {
            int n = 0;
            if (option.contains('1 Year')) n = 1;
            if (option.contains('2 Years')) n = 2;
            if (option.contains('3 Years')) n = 3;
            if (option.contains('6 Months')) n = 0; // round down to 10?
            optionYears = 10 + n;
          }

          if (optionYears == years) {
            _selectedGradeLevel = option;
            break;
          }
        }
      }
    }

    _setDropdownValue(resident.religion, FormOptions.religions,
        (v) => _selectedReligion = v, _religionOtherController);

    // NR Initialization moved to logic below (if matching family member exists)
    // But we need to populate _familyMembers first! Done at end of function.
    // We should try to auto-select if NR name matches a family member?
    // Yes.
    if (resident.nearestRelativeName != null) {
      _selectedNearestRelativeName = resident.nearestRelativeName;
    }

    if (resident.custodianName != null) {
      _selectedCustodianName = resident.custodianName;
    }

    // Emergency
    if (resident.emergencyContactName != null) {
      _selectedEmergencyContactName = resident.emergencyContactName;
      // We might need to handle "Others" if not in family list?
      // If name is not in family list, set to "Others" and populate manual fields.
      // We'll check this after family list is loaded.
    }

    // Medical fields removed from UI
    // _diagnosisController.text = resident.primaryDiagnosis ?? '';
    // _allergiesController.text = resident.allergies ?? '';
    // _notesController.text = resident.medicalNotes ?? '';

    _dateOfBirth = resident.dateOfBirth;
    _isK12 = _dateOfBirth != null && _dateOfBirth!.year >= 1999;
    _admissionDate = resident.admissionDate;
    _applicationDate = resident.applicationDate;
    _admissionStatus = resident.status;
    _gender = resident.gender;

    // Room logic removed.
    // If Ward has capacity, Room logic depends on facility structure.
    // The prompt says "based on the capacity of that ward".
    // If beds are 1..N, maybe Room is just text or also derived?
    // I will keep Room as text for now unless specified structure exists.
    // Actually prompt: "room number and bed number should also be a dropdown".
    // I only implemented Bed dropdown based on capacity.
    // I'll make Room number a text field that is optional or maybe pre-filled?
    // Or maybe Room is part of the Bed key?
    // For now I'll handle Bed. Room might be free text.

    if (resident.bedNumber != null) {
      _selectedBed = resident.bedNumber;
    }

    if (resident.familyComposition != null) {
      _familyMembers = List<Map<String, String>>.from(
          resident.familyComposition!.map((e) => Map<String, String>.from(e)));
    }
  }

  void _setDropdownValue(
    String? value,
    List<String> options,
    Function(String?) onSelect,
    TextEditingController? otherController,
  ) {
    if (value == null || value.isEmpty) return;
    if (options.contains(value)) {
      onSelect(value);
    } else if (otherController != null && options.contains('OTHERS')) {
      onSelect('OTHERS');
      otherController.text = value;
    } else if (otherController != null) {
      // Force "OTHERS" if value exists but not in list
      onSelect('OTHERS');
      otherController.text = value.toUpperCase();
    }
  }

  Future<void> _loadLocations() async {
    await _addressRepository.initialize();
    if (mounted) {
      setState(() {
        _provinceList = _addressRepository.getProvinces();

        // Refresh lists for current selections (if any)
        if (_selectedProvince != null) {
          _cityList = _addressRepository.getCities(_selectedProvince!);
          if (_selectedCity != null) {
            _barangayList = _addressRepository.getBarangays(
                _selectedProvince!, _selectedCity!);
          }
        }

        if (_pobSelectedProvince != null) {
          _pobCityList = _addressRepository.getCities(_pobSelectedProvince!);
        }

        if (_referralSelectedProvince != null) {
          bool? isCity;
          if (_selectedReferralSource == 'CSWDO') isCity = true;
          if (_selectedReferralSource == 'MSWDO') isCity = false;

          _referralCityList = _addressRepository
              .getCities(_referralSelectedProvince!, isCity: isCity);

          if (_referralSelectedCity != null) {
            _referralBarangayList = _addressRepository.getBarangays(
                _referralSelectedProvince!, _referralSelectedCity!);
          }
        }
      });
    }
  }

  Future<void> _loadWards() async {
    try {
      final repository = context.read<ResidentRepository>();
      final wards = await repository.getWards();
      if (!mounted) return;

      setState(() {
        _wards = wards;
        if (widget.resident != null && widget.resident!.currentWardId != null) {
          try {
            _selectedWard = _wards
                .firstWhere((w) => w.id == widget.resident!.currentWardId);
            // Load beds for selected ward
            if (_selectedWard != null) _onWardChanged(_selectedWard);
          } catch (_) {
            if (wards.isNotEmpty) {
              _selectedWard = wards.first;
              _onWardChanged(_selectedWard);
            }
          }
        } else if (wards.isNotEmpty) {
          _selectedWard = wards.first;
          _onWardChanged(_selectedWard);
        }
      });
    } catch (e) {
      // Handle error
    }
  }

  Future<void> _onWardChanged(WardModel? ward) async {
    if (ward == null) {
      setState(() => _availableBeds = []);
      return;
    }

    setState(() => _loadingBeds = true);

    try {
      final repository = context.read<ResidentRepository>();
      final residents = await repository.getResidentsByWardId(ward.id);
      if (!mounted) return;

      // Get occupied beds, excluding current resident if editing
      final occupiedBeds = residents
          .where((r) =>
              r.bedNumber != null &&
              (widget.resident == null || r.id != widget.resident!.id))
          .map((r) => r.bedNumber!)
          .toSet();

      setState(() {
        // Assuming capacity is just a number, we generate beds 1..N
        _availableBeds =
            List.generate(ward.capacity, (index) => (index + 1).toString())
                .where((bed) => !occupiedBeds.contains(bed))
                .toList();

        // Also ensure current resident's bed is in the list if editing/keeping same
        if (widget.resident != null &&
            widget.resident!.wardId == ward.id &&
            widget.resident!.bedNumber != null &&
            !_availableBeds.contains(widget.resident!.bedNumber!)) {
          _availableBeds.add(widget.resident!.bedNumber!);
          _availableBeds.sort((a, b) => int.parse(a).compareTo(int.parse(b)));
        }
      });
    } catch (e) {
      print('Error loading beds: $e');
    } finally {
      if (mounted) setState(() => _loadingBeds = false);
    }
  }

  void _onProvinceChanged(String? value) {
    setState(() {
      _selectedProvince = value;
      _selectedCity = null;
      _selectedBarangay = null;
      _cityList = value != null ? _addressRepository.getCities(value) : [];
      _barangayList = [];
    });
  }

  void _onCityChanged(String? value) {
    setState(() {
      _selectedCity = value;
      _selectedBarangay = null;
      _barangayList = value != null
          ? _addressRepository.getBarangays(_selectedProvince!, value)
          : [];
    });
  }

  void _onPobProvinceChanged(String? value) {
    setState(() {
      final oldPobProvince = _pobSelectedProvince;
      _pobSelectedProvince = value;
      _pobSelectedCity = null;
      _pobCityList = value != null ? _addressRepository.getCities(value) : [];

      // Auto-fill Home Address Province:
      // 1. If currently empty
      // 2. OR if it matches the OLD POB value (implying it was auto-filled or consistent)
      if (value != null) {
        bool shouldUpdate = false;
        if (_selectedProvince == null || _selectedProvince!.isEmpty) {
          shouldUpdate = true;
        } else if (_selectedProvince == oldPobProvince) {
          shouldUpdate = true;
        }

        if (shouldUpdate) {
          _selectedProvince = value;
          _cityList = _addressRepository.getCities(value);
          _selectedCity = null;
          _selectedBarangay = null;
          _barangayList = [];
        }
      }
    });
  }

  void _onPobCityChanged(String? value) {
    setState(() {
      final oldPobCity = _pobSelectedCity;
      _pobSelectedCity = value;

      // Auto-fill Home Address City if:
      // 1. Province matches AND
      // 2. (City is empty OR matches OLD POB City)
      if (value != null && _selectedProvince == _pobSelectedProvince) {
        bool shouldUpdate = false;
        if (_selectedCity == null || _selectedCity!.isEmpty) {
          shouldUpdate = true;
        } else if (_selectedCity == oldPobCity) {
          shouldUpdate = true;
        }

        if (shouldUpdate) {
          _selectedCity = value;
          _barangayList =
              _addressRepository.getBarangays(_selectedProvince!, value);
          _selectedBarangay = null;
        }
      }
    });
  }

  void _onReferralProvinceChanged(String? value) {
    setState(() {
      _referralSelectedProvince = value;
      _referralSelectedCity = null;
      _referralSelectedBarangay = null;

      bool? isCity;
      if (_selectedReferralSource == 'CSWDO') isCity = true;
      if (_selectedReferralSource == 'MSWDO') isCity = false;

      _referralCityList = value != null
          ? _addressRepository.getCities(value, isCity: isCity)
          : [];
      _referralBarangayList = [];
    });
  }

  void _onReferralCityChanged(String? value) {
    setState(() {
      _referralSelectedCity = value;
      _referralSelectedBarangay = null;
      _referralBarangayList = value != null
          ? _addressRepository.getBarangays(_referralSelectedProvince!, value)
          : [];
    });
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 500,
      maxHeight: 500,
      imageQuality: 80,
    );

    if (image != null) {
      final bytes = await image.readAsBytes();
      if (!mounted) return;
      setState(() {
        _photoBytes = bytes;
      });
    }
  }

  void _onEducationChanged(String? value) {
    setState(() {
      _selectedEducation = value;
      _selectedGradeLevel = null;
      _gradeLevelOptions = [];

      if (value != null) {
        if (value.contains('ELEMENTARY GRADUATE')) {
          _selectedYearsEducation = '6';
        } else if (value.contains('SENIOR HIGH SCHOOL GRADUATE')) {
          _selectedYearsEducation = '12';
        } else if (value.contains('HIGH SCHOOL GRADUATE') ||
            value.contains('JUNIOR HIGH SCHOOL GRADUATE')) {
          _selectedYearsEducation = '10';
        } else if (value.contains('COLLEGE GRADUATE')) {
          _selectedYearsEducation = _isK12 ? '16' : '14';
        } else if (value.contains('POST-GRADUATE')) {
          _selectedYearsEducation = _isK12 ? '18' : '16';
        } else if (value.contains('LEVEL')) {
          // Reset years if level is selected, wait for grade selection
          _selectedYearsEducation = null;

          if (value.contains('ELEMENTARY LEVEL')) {
            _gradeLevelOptions = FormOptions.elementaryGrades;
          } else if (value.contains('SENIOR HIGH SCHOOL LEVEL')) {
            // Check Senior High before generic High School
            _gradeLevelOptions = FormOptions.seniorHighGrades;
          } else if (value.contains('HIGH SCHOOL LEVEL') ||
              value.contains('JUNIOR HIGH SCHOOL LEVEL')) {
            _gradeLevelOptions = FormOptions.highSchoolGrades;
          } else if (value.contains('COLLEGE LEVEL')) {
            _gradeLevelOptions = FormOptions.collegeYears;
          }
        } else if (value.contains('VOCATIONAL')) {
          _gradeLevelOptions = FormOptions.vocationalDurations;
          // Default to Base Year
          _selectedYearsEducation = (_isK12 ? 12 : 10).toString();
        } else {
          _selectedYearsEducation = null;
        }
      } else {
        _selectedYearsEducation = null;
      }
    });
  }

  void _onGradeLevelChanged(String? value) {
    setState(() {
      _selectedGradeLevel = value;
      if (value != null && _selectedEducation != null) {
        int years = 0;
        if (_selectedEducation!.contains('ELEMENTARY LEVEL')) {
          final grade = int.tryParse(value.split(' ').last) ?? 0;
          years = grade;
        } else if (_selectedEducation!.contains('SENIOR HIGH SCHOOL LEVEL')) {
          // Grade 11-12
          final grade = int.tryParse(value.split(' ').last) ?? 0;
          years = grade;
        } else if (_selectedEducation!.contains('HIGH SCHOOL LEVEL') ||
            _selectedEducation!.contains('JUNIOR HIGH SCHOOL LEVEL')) {
          // 4 years (Old/JHS): 1st-4th Year -> 7-10
          if (value.contains('FIRST')) years = 7;
          if (value.contains('SECOND')) years = 8;
          if (value.contains('THIRD')) years = 9;
          if (value.contains('FOURTH')) years = 10;
        } else if (_selectedEducation!.contains('COLLEGE LEVEL')) {
          // 1st-5th Year. Base 10 (Old curriculum assumed for seniors) or 12?
          // Using Base 10 + N for consistent progression from HS grad (10)
          int n = 0;
          if (value.contains('1ST')) n = 1;
          if (value.contains('2ND')) n = 2;
          if (value.contains('3RD')) n = 3;
          if (value.contains('4TH')) n = 4;

          int base = _isK12 ? 12 : 10;
          years = base + n;
        } else if (_selectedEducation!.contains('VOCATIONAL')) {
          int n = 0;
          if (value.contains('1 YEAR')) n = 1;
          if (value.contains('2 YEARS')) n = 2;
          if (value.contains('3 YEARS')) n = 3;
          if (value.contains('6 MONTHS')) n = 0;

          int base = _isK12 ? 12 : 10;
          years = base + n;
        }

        if (years > 0) {
          _selectedYearsEducation = years.toString();
        }
      }
    });
  }

  Future<void> _selectDate(BuildContext context, bool isBirthDate) async {
    final now = DateTime.now();
    final initialDate = isBirthDate
        ? (_dateOfBirth ?? DateTime(now.year - 70))
        : (_admissionDate ?? now);

    final date = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1900),
      lastDate: now,
    );

    if (date != null) {
      setState(() {
        if (isBirthDate) {
          _dateOfBirth = date;
          if (_dateOfBirth!.year >= 1999) {
            _isK12 = true;
          } else {
            _isK12 = false;
          }
          if (_selectedGradeLevel != null) {
            _onGradeLevelChanged(_selectedGradeLevel);
          }
          _syncNameWithNickname();
        } else {
          _admissionDate = date;
          // Auto-Suggest Next Number (Admission: C-)
          _suggestNextNumber(date, isAdmission: true);
        }
      });
    }
  }

  // _syncNearestRelative removed

  void _onSavePressed() {
    if (_formKey.currentState!.validate()) {
      _showReviewDialog();
    }
  }

  void _showReviewDialog() {
    showDialog(
        context: context,
        builder: (context) {
          bool isConfirmed = false;

          return StatefulBuilder(builder: (context, setState) {
            return AlertDialog(
              title: const Text('REVIEW RESIDENT DETAILS',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              content: SizedBox(
                width: 500, // Constrain width
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildReviewSection('ENTRY INFORMATION', [
                        _buildReviewItem(
                            'TYPE',
                            _admissionStatus == 'admitted'
                                ? 'DIRECT ADMISSION'
                                : 'PRE-ADMISSION'),
                        _buildReviewItem(
                            'APP. DATE',
                            _applicationDate != null
                                ? DateFormat('MMMM d, yyyy')
                                    .format(_applicationDate!)
                                    .toUpperCase()
                                : '-'),
                      ]),
                      const Divider(height: 24),
                      _buildReviewSection('PERSONAL INFORMATION', [
                        _buildReviewItem('NAME',
                            '${_firstNameController.text} ${_middleNameController.text} ${_lastNameController.text} ${_selectedSuffix ?? ''}'),
                        _buildReviewItem('NICKNAME', _nicknameController.text),
                        _buildReviewItem(
                            'BIRTHDATE',
                            _dateOfBirth != null
                                ? DateFormat('MMMM d, yyyy')
                                    .format(_dateOfBirth!)
                                    .toUpperCase()
                                : '-'),
                        _buildReviewItem(
                            'AGE',
                            _dateOfBirth != null
                                ? '${DateTime.now().year - _dateOfBirth!.year}'
                                : '-'),
                        _buildReviewItem('SEX', _gender.toUpperCase()),
                        if (_selectedSocialWorkerId != null)
                          _buildReviewItem(
                              'SOCIAL WORKER',
                              _socialWorkers
                                  .firstWhere(
                                      (u) => u.id == _selectedSocialWorkerId,
                                      orElse: () => UserModel(
                                          id: '',
                                          email: '',
                                          fullName: 'Unknown',
                                          workId: '',
                                          role: '',
                                          createdAt: DateTime.now()))
                                  .fullName),
                        if (_mentalHealthConditionController.text.isNotEmpty)
                          _buildReviewItem('MENTAL HEALTH CONDITION',
                              _mentalHealthConditionController.text),
                        _buildReviewItem(
                            'BIRTHPLACE',
                            '${_pobSelectedCity ?? ''}, ${_pobSelectedProvince ?? ''}'
                                .replaceAll(RegExp(r'^, |,$'), '')),
                      ]),
                      const Divider(height: 24),
                      _buildReviewSection('ADDRESS', [
                        _buildReviewItem(
                            'HOME',
                            [
                              _streetAddressController.text,
                              _selectedBarangay,
                              _selectedCity,
                              _selectedProvince
                            ]
                                .where((s) => s != null && s.isNotEmpty)
                                .join(', ')
                                .toUpperCase()),
                      ]),
                      const Divider(height: 24),
                      _buildReviewSection('REFERRAL', [
                        _buildReviewItem(
                            'SOURCE',
                            _selectedReferralSource == 'Others'
                                ? _referralOtherController.text
                                : (_selectedReferralSource ?? '-')),
                        _buildReviewItem('CONTACT PERSON',
                            _referralContactPersonController.text),
                        _buildReviewItem(
                            'ADDRESS',
                            [
                              _referralStreetAddressController.text,
                              _referralSelectedBarangay,
                              _referralSelectedCity,
                              _referralSelectedProvince
                            ]
                                .where((s) => s != null && s.isNotEmpty)
                                .join(', ')
                                .toUpperCase()),
                      ]),
                      const Divider(height: 24),
                      _buildReviewSection('CASE & ADMISSION', [
                        _buildReviewItem(
                            'CATEGORY', _selectedCaseCategory ?? '-'),
                        _buildReviewItem(
                            'CONDITION', _conditionController.text),
                        _buildReviewItem(
                            'ADMISSION',
                            _admissionDate != null
                                ? DateFormat('MMMM d, yyyy')
                                    .format(_admissionDate!)
                                    .toUpperCase()
                                : '-'),
                        _buildReviewItem(
                            'WARD', _selectedWard?.name.toUpperCase() ?? '-'),
                        _buildReviewItem('BED', _selectedBed ?? '-'),
                        _buildReviewItem(
                            'CASE NO.', _caseNumberController.text), // Added
                      ]),
                      const Divider(height: 24),
                      _buildReviewSection('SOCIAL & EDUCATION', [
                        _buildReviewItem(
                            'CIVIL STATUS', _selectedCivilStatus ?? '-'),
                        _buildReviewItem(
                            'RELIGION',
                            _selectedReligion == 'Others'
                                ? _religionOtherController.text
                                : (_selectedReligion ?? '-')),
                        _buildReviewItem(
                            'EDUCATION', _selectedEducation ?? '-'),
                        if (_selectedGradeLevel != null)
                          _buildReviewItem('GRADE/YEAR', _selectedGradeLevel!),
                        if (_selectedYearsEducation != null)
                          _buildReviewItem('TOTAL YEARS',
                              '$_selectedYearsEducation (${_isK12 ? "K-12" : "OLD CURRICULUM"})'),
                      ]),
                      const Divider(height: 24),
                      _buildReviewSection('FAMILY & CONTACTS', [
                        _buildReviewItem(
                            'TOTAL MEMBERS', '${_familyMembers.length} LISTED'),
                        _buildReviewItem('NEAREST RELATIVE',
                            _selectedNearestRelativeName ?? '-'),
                        _buildReviewItem(
                            'CUSTODIAN',
                            _selectedCustodianName == 'Others'
                                ? _custodianNameController.text
                                : (_selectedCustodianName ?? '-')),
                        _buildReviewItem(
                            'EMERGENCY CONTACT',
                            _selectedEmergencyContactName == 'Others'
                                ? '${_emergencyNameController.text} (RELATION: ${_selectedEmergencyRelation == 'Others' ? _emergencyRelationOtherController.text : _selectedEmergencyRelation})'
                                : (_selectedEmergencyContactName ?? '-')),
                        if (_selectedEmergencyContactName == 'Others' ||
                            _familyMembers.any((m) =>
                                m['name'] == _selectedEmergencyContactName &&
                                m['contact'] != null))
                          _buildReviewItem(
                              'CONTACT NUM',
                              _selectedEmergencyContactName == 'Others'
                                  ? _emergencyPhoneController.text
                                  : (_familyMembers.firstWhere(
                                          (element) =>
                                              element['name'] ==
                                              _selectedEmergencyContactName,
                                          orElse: () => {})['contact'] ??
                                      '-')),
                      ]),
                      const SizedBox(height: 24),
                      // CHECKBOX DISCLAIMER
                      InkWell(
                        onTap: () {
                          setState(() {
                            isConfirmed = !isConfirmed;
                          });
                        },
                        borderRadius: BorderRadius.circular(4),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                width: 24,
                                height: 24,
                                child: Checkbox(
                                  value: isConfirmed,
                                  onChanged: (v) {
                                    setState(() {
                                      isConfirmed = v ?? false;
                                    });
                                  },
                                  materialTapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Text(
                                  'I hereby certify that all information provided above is true and correct to the best of my knowledge.',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontStyle: FontStyle.italic,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('CANCEL'),
                ),
                ElevatedButton(
                  onPressed: isConfirmed
                      ? () {
                          Navigator.pop(context); // Close dialog
                          _saveResident(); // Proceed to save
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey.shade300,
                  ),
                  child: const Text('CONFIRM & SAVE'),
                ),
              ],
            );
          } // End StatefulBuilder builder
              ); // End StatefulBuilder
        } // End showDialog builder
        );
  }

  Widget _buildReviewSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: AppColors.primary)),
        const SizedBox(height: 8),
        ...children,
      ],
    );
  }

  Widget _buildReviewItem(String label, String value) {
    if (value.isEmpty || value == '-') return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              '$label:',
              style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                  color: Colors.grey.shade700),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveResident() async {
    if (_dateOfBirth == null) {
      CustomSnackBar.show(context, message: 'Please select date of birth', isError: true);
      return;
    }

    // Check for Duplicates (New Admission only)
    if (widget.resident == null) {
      final firstName = _firstNameController.text.trim();
      final lastName = _lastNameController.text.trim();

      final exists =
          await context.read<ResidentRepository>().checkResidentExists(
                firstName: firstName,
                lastName: lastName,
              );
      if (!mounted) return;

      if (exists) {
        if (!mounted) return;
        final proceed = await showDialog<bool>(
          context: context,
          builder: (c) => AlertDialog(
            title: const Text('Possible Duplicate'),
            content: Text(
                'A resident named "$firstName $lastName" already exists in the system.\n\nDo you still want to proceed with saving?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(c, false),
                child: const Text('CANCEL'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(c, true),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('PROCEED ANYWAY',
                    style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        );

        if (proceed != true) return;
      }
    }

    // Validation for Direct Admission
    if (_admissionStatus == 'admitted') {
      if (_selectedWard == null) {
        CustomSnackBar.show(context, message: 'Please select a ward for admission', isError: true);
        return;
      }
      if (_admissionDate == null) {
        CustomSnackBar.show(context, message: 'Please select admission date', isError: true);
        return;
      }
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final repository = context.read<ResidentRepository>();
      String? nrName, nrAddress, nrContact, nrRelation;

      if (_selectedNearestRelativeName != null) {
        final member = _familyMembers.firstWhere(
            (m) => m['name'] == _selectedNearestRelativeName,
            orElse: () => {});
        if (member.isNotEmpty) {
          nrName = member['name'];
          nrAddress = member['address'];
          nrContact = member['contact'];
          nrRelation = member['relationship'];
        }
      }

      String? ecName, ecPhone, ecRelation;
      if (_selectedEmergencyContactName == 'Others') {
        ecName = _emergencyNameController.text.trim().isEmpty
            ? null
            : _emergencyNameController.text.trim();
        ecPhone = _emergencyPhoneController.text.trim().isEmpty
            ? null
            : _emergencyPhoneController.text.trim();
        ecRelation = _selectedEmergencyRelation == 'Others'
            ? _emergencyRelationOtherController.text.trim()
            : _selectedEmergencyRelation;
      } else if (_selectedEmergencyContactName != null) {
        final member = _familyMembers.firstWhere(
            (m) => m['name'] == _selectedEmergencyContactName,
            orElse: () => {});
        if (member.isNotEmpty) {
          ecName = member['name'];
          ecPhone = member['contact']; // Use member contact
          ecRelation = member['relationship'];
        }
      }

      final finalFamilyComposition =
          List<Map<String, dynamic>>.from(_familyMembers);

      if (widget.resident != null) {
        // Update existing
        await repository.updateResident(
          id: widget.resident!.id,
          firstName: _firstNameController.text.trim(),
          lastName: _lastNameController.text.trim(),
          middleName: _middleNameController.text.trim().isEmpty
              ? null
              : _middleNameController.text.trim(),
          suffix: _selectedSuffix,
          nickname: _nicknameController.text.trim().isEmpty
              ? null
              : _nicknameController.text.trim(),
          placeOfBirth:
              (_pobSelectedCity != null && _pobSelectedProvince != null)
                  ? '$_pobSelectedCity, $_pobSelectedProvince'
                  : widget.resident?.placeOfBirth,
          dateOfBirth: _dateOfBirth,
          gender: _gender,
          wardId: _admissionStatus == 'admitted' ? _selectedWard?.id : null,
          roomNumber: null,
          bedNumber: _selectedBed,
          admissionDate: _admissionStatus == 'admitted' ? _admissionDate : null,
          applicationDate: _applicationDate,
          referredBy: _referralOtherController.text.trim(),
          referringContactPerson:
              _referralContactPersonController.text.trim(), // Added
          referringPartyAddress: (_referralSelectedCity != null &&
                  _referralSelectedProvince != null)
              ? '${_referralStreetAddressController.text.trim()}, ${_referralSelectedBarangay ?? ''}, $_referralSelectedCity, $_referralSelectedProvince'
              : null,
          caseCategory: _selectedCaseCategory,
          caseNumber: _caseNumberController.text.trim().isEmpty
              ? null
              : _caseNumberController.text.trim(), // Added
          condition: _conditionController.text.trim(),
          natureOfDisability: _disabilityController.text.trim().isEmpty
              ? null
              : _disabilityController.text.trim(),
          province: _selectedProvince,
          city: _selectedCity,
          barangay: _selectedBarangay,
          streetAddress: _streetAddressController.text.trim().isEmpty
              ? null
              : _streetAddressController.text.trim(),
          civilStatus: _selectedCivilStatus,
          educationalAttainment: _selectedEducation,
          yearsOfEducation: _selectedYearsEducation,
          religion: _selectedReligion == 'Others'
              ? _religionOtherController.text.trim()
              : _selectedReligion,
          nearestRelativeName: nrName ?? '',
          nearestRelativeAddress: nrAddress ?? '',
          nearestRelativeContactNumber: nrContact ?? '',
          nearestRelativeRelation: nrRelation ?? '',
          custodianName: (_selectedCustodianName == 'Others'
                  ? _custodianNameController.text.trim()
                  : _selectedCustodianName) ??
              '',
          familyComposition: finalFamilyComposition,
          emergencyContactName: ecName ?? '',
          emergencyContactPhone: ecPhone ?? '',
          emergencyContactRelation: ecRelation ?? '',
          allergies: null,
          primaryDiagnosis: null,
          medicalNotes: null,
          photoBytes: _photoBytes,
          status: _admissionStatus,
          houseparentId: _selectedHouseparentId, // Added
          socialWorkerId: _selectedSocialWorkerId,
          mentalHealthCondition:
              _mentalHealthConditionController.text.trim().isEmpty
                  ? null
                  : _mentalHealthConditionController.text.trim(), // Added
        );
      } else {
        // Create new
        await repository.addResident(
          firstName: _firstNameController.text.trim(),
          lastName: _lastNameController.text.trim(),
          middleName: _middleNameController.text.trim().isEmpty
              ? null
              : _middleNameController.text.trim(),
          suffix: _selectedSuffix,
          nickname: _nicknameController.text.trim().isEmpty
              ? null
              : _nicknameController.text.trim(),
          placeOfBirth:
              (_pobSelectedCity != null && _pobSelectedProvince != null)
                  ? '$_pobSelectedCity, $_pobSelectedProvince'
                  : null,
          dateOfBirth: _dateOfBirth!,
          gender: _gender,
          wardId: _admissionStatus == 'admitted' ? _selectedWard?.id : null,
          roomNumber: null,
          bedNumber: _selectedBed,
          admissionDate: _admissionStatus == 'admitted'
              ? (_admissionDate ?? DateTime.now())
              : null,
          applicationDate: _applicationDate ?? DateTime.now(),
          referredBy: _referralOtherController.text.trim(),
          referringContactPerson:
              _referralContactPersonController.text.trim(), // Added
          referringPartyAddress: [
            _referralStreetAddressController.text.trim(),
            if (_referralSelectedBarangay != null) _referralSelectedBarangay,
            if (_referralSelectedCity != null) _referralSelectedCity,
            if (_referralSelectedProvince != null) _referralSelectedProvince
          ]
              .where((part) => part != null && part.toString().isNotEmpty)
              .join(', '),
          caseCategory: _selectedCaseCategory,
          caseNumber: _caseNumberController.text.trim().isEmpty
              ? null
              : _caseNumberController.text.trim(), // Added
          condition: _conditionController.text.trim(),
          natureOfDisability: _disabilityController.text.trim().isEmpty
              ? null
              : _disabilityController.text.trim(),
          // Note: repository parameter is named `maxProvince` in existing code but maps to `province`
          maxProvince: _selectedProvince,
          city: _selectedCity,
          barangay: _selectedBarangay,
          streetAddress: _streetAddressController.text.trim().isEmpty
              ? null
              : _streetAddressController.text.trim(),
          civilStatus: _selectedCivilStatus,
          educationalAttainment: _selectedEducation,
          yearsOfEducation: _selectedYearsEducation,
          religion: _selectedReligion == 'Others'
              ? _religionOtherController.text.trim()
              : _selectedReligion,
          nearestRelativeName: nrName,
          nearestRelativeAddress: nrAddress,
          nearestRelativeContactNumber: nrContact,
          nearestRelativeRelation: nrRelation,
          custodianName: _selectedCustodianName == 'Others'
              ? _custodianNameController.text.trim()
              : _selectedCustodianName,
          familyComposition: finalFamilyComposition,

          emergencyContactName: ecName,
          emergencyContactPhone: ecPhone,
          emergencyContactRelation: ecRelation,
          allergies: null,
          primaryDiagnosis: null,
          medicalNotes: null,
          photoBytes: _photoBytes,
          status: _admissionStatus,
          houseparentId: _selectedHouseparentId, // Added
          socialWorkerId: _selectedSocialWorkerId,
          mentalHealthCondition:
              _mentalHealthConditionController.text.trim().isEmpty
                  ? null
                  : _mentalHealthConditionController.text.trim(), // Added
        );
      } // End if/else

      // Create a model for PDF Generation
      // We reuse the data we just gathered
      final residentForPdf = ResidentModel(
        id: widget.resident?.id ?? 'temp_id',
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        middleName: _middleNameController.text.trim(),
        suffix: _selectedSuffix,
        nickname: _nicknameController.text.trim(),
        placeOfBirth: (_pobSelectedCity != null && _pobSelectedProvince != null)
            ? '$_pobSelectedCity, $_pobSelectedProvince'
            : null,
        dateOfBirth: _dateOfBirth ?? DateTime.now(),
        gender: _gender,
        wardId: _selectedWard
            ?.name, // Use name for display in PDF if ID not resolved
        bedNumber: _selectedBed,
        status: _admissionStatus,
        admissionDate: _admissionDate,
        applicationDate: _applicationDate ?? DateTime.now(),
        caseCategory: _selectedCaseCategory,
        caseNumber: _caseNumberController.text.trim(),
        condition: _conditionController.text.trim(),
        natureOfDisability: _disabilityController.text.trim().isEmpty
            ? null
            : _disabilityController.text.trim(),
        province: _selectedProvince,
        city: _selectedCity,
        barangay: _selectedBarangay,
        streetAddress: _streetAddressController.text.trim(),
        referredBy: _referralOtherController.text,
        referringContactPerson: _referralContactPersonController.text, // Added
        referringPartyAddress: [
          _referralStreetAddressController.text.trim(),
          if (_referralSelectedBarangay != null) _referralSelectedBarangay,
          if (_referralSelectedCity != null) _referralSelectedCity,
          if (_referralSelectedProvince != null) _referralSelectedProvince
        ]
            .where((part) => part != null && part.toString().isNotEmpty)
            .join(', '),
        civilStatus: _selectedCivilStatus,
        educationalAttainment: _selectedEducation,
        religion: _selectedReligion == 'OTHERS'
            ? _religionOtherController.text
            : _selectedReligion,
        nearestRelativeName: nrName,
        custodianName: _selectedCustodianName == 'OTHERS'
            ? _custodianNameController.text
            : _selectedCustodianName,
        emergencyContactName: ecName,

        createdAt: widget.resident?.createdAt ?? DateTime.now(),
        houseparentId: _selectedHouseparentId,
        socialWorkerId: _selectedSocialWorkerId,
        // We can try to look up names if needed for PDF, or just IDs for now.
        // PDF probably needs names.
        houseparentName: _selectedHouseparentId != null
            ? _houseparents
                .firstWhere((u) => u.id == _selectedHouseparentId,
                    orElse: () => UserModel(
                        id: '',
                        email: '',
                        fullName: '',
                        workId: '',
                        role: '',
                        createdAt: DateTime.now()))
                .fullName
            : null,
        socialWorkerName: _selectedSocialWorkerId != null
            ? _socialWorkers
                .firstWhere((u) => u.id == _selectedSocialWorkerId,
                    orElse: () => UserModel(
                        id: '',
                        email: '',
                        fullName: '',
                        workId: '',
                        role: '',
                        createdAt: DateTime.now()))
                .fullName
            : null,
      );

      if (!mounted) return;

      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Success'),
          content: Text(
              'Resident ${widget.resident != null ? "updated" : "saved"} successfully.\n\nWould you like to generate a PDF Summary?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext); // Close dialog
                context.pop(); // Close form
              },
              child: const Text('CLOSE'),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(dialogContext);
                PdfService.generateResidentProfile(residentForPdf);
                context.pop(); // Close form
              },
              icon: const Icon(Icons.print, size: 18),
              label: const Text('VIEW PDF'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    } catch (e) {
      if (mounted) {
        CustomSnackBar.showError(
          context, 
          error: e,
          fallbackMessage: 'Failed to save resident profile',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Only show 2 steps for Pre-admission (skip location)
    // Actually, let's keep the step but make it optional/disabled or different content?
    // Better: Conditional steps.

    final steps = [
      Step(
        title: const Text('BASIC INFORMATION'),
        isActive: _currentStep >= 0,
        state: _currentStep > 0 ? StepState.complete : StepState.indexed,
        content: _buildBasicInfoStep(),
      ),
      if (_admissionStatus == 'admitted')
        Step(
          title: const Text('WARD & LOCATION'),
          isActive: _currentStep >= 1,
          state: _currentStep > 1 ? StepState.complete : StepState.indexed,
          content: _buildLocationStep(),
        ),
      Step(
        title: const Text('ADDITIONAL DETAILS'),
        isActive: _currentStep >= (_admissionStatus == 'admitted' ? 2 : 1),
        state: _currentStep > (_admissionStatus == 'admitted' ? 2 : 1)
            ? StepState.complete
            : StepState.indexed,
        content: _buildAdditionalStep(),
      ),
    ];

    // Check if form is "dirty" - For simplicity, if we are adding a new resident and have typed anything,
    // or if we are editing.
    // Optimization: We could be more granular, but safety first.
    // If it's a new entry, we check if key fields are empty.

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;

        bool shouldPop = true;

        // Comprehensive dirty check: If ANY controller has text, warn user.
        final controllers = [
          _firstNameController,
          _middleNameController,
          _lastNameController,
          _nicknameController,
          _streetAddressController, // Home Address
          _referralStreetAddressController, // Referral Address
          _caseNumberController, // Added
          _conditionController,
          _disabilityController,
          _custodianNameController,
          _emergencyNameController,
          _emergencyPhoneController,
          _religionOtherController,
          _referralOtherController,
          _referralContactPersonController,
          _emergencyRelationOtherController
        ];

        bool hasContent = controllers.any((c) => c.text.trim().isNotEmpty);

        // Also check if any dropdowns are selected (non-null) if typically null on start
        // For editing, we might need a different logic (check vs original), but user asked for "unsaved changes" warning.
        // If editing, widget.resident != null, so hasContent is always true!
        // This means back button ALWAYS prompts on edit, which is cleaner/safer than "did I change anything?".
        // For "Add", it correctly checks if we started typing.
        if (widget.resident != null) {
          // On Edit mode, we assume "Dirty" if we entered the screen,
          // OR we could check if values changed.
          // Simplest for now: If editing, always warn to be safe.
          hasContent = true;
        }

        if (hasContent) {
          final result = await showDialog<bool>(
            context: context,
            builder: (c) => AlertDialog(
              title: const Text('Discard Changes?'),
              content: const Text(
                  'You have unsaved changes. Are you sure you want to leave this page? All progress will be lost.'),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(c, false),
                    child: const Text('KEEP EDITING')),
                TextButton(
                    onPressed: () => Navigator.pop(c, true),
                    child: const Text('DISCARD & LEAVE',
                        style: TextStyle(color: Colors.red))),
              ],
            ),
          );
          shouldPop = result ?? false;
        }

        if (shouldPop && context.mounted) {
          Navigator.pop(context);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () async {
              // Dispatch PopScope logic manually since standard back button
              // in AppBar calls Navigator.pop directly which PopScope intercepts,
              // but checking `onPopInvoked` handles system back gesture.
              // For explicit button, we trigger the maybePop
              Navigator.maybePop(context);
            },
          ),
          title: Text(
              widget.resident != null ? 'Edit Resident' : 'Add New Resident'),
          actions: [
            IconButton(
              icon: const Icon(Icons.info_outline),
              onPressed: _showRequirementsDialog,
              tooltip: 'Requirements Checklist',
            ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Form(
                key: _formKey,
                autovalidateMode: AutovalidateMode
                    .onUserInteraction, // Validation only after interaction
                child: Stepper(
                  key: ValueKey(_admissionStatus),
                  currentStep: _currentStep,
                  onStepContinue: () {
                    final isLastStep = _currentStep == steps.length - 1;
                    if (!isLastStep) {
                      setState(() {
                        _currentStep++;
                      });
                    } else {
                      _onSavePressed();
                    }
                  },
                  onStepCancel: () {
                    if (_currentStep > 0) {
                      setState(() {
                        _currentStep--;
                      });
                    }
                  },
                  controlsBuilder: (context, details) {
                    final isLastStep = _currentStep == steps.length - 1;
                    return Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed:
                                  _isLoading ? null : details.onStepContinue,
                              child: _isLoading && isLastStep
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : Text(isLastStep
                                      ? 'Save ${_admissionStatus == "pre_admission" ? "Profile" : "Resident"}'
                                      : 'Continue'),
                            ),
                          ),
                          if (_currentStep > 0) ...[
                            const SizedBox(width: 12),
                            Expanded(
                              child: OutlinedButton(
                                onPressed: details.onStepCancel,
                                child: const Text('Back'),
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                  steps: steps,
                ),
              ),
      ),
    );
  }

  Future<void> _selectApplicationDate(BuildContext context) async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _applicationDate ?? now,
      firstDate: DateTime(1900),
      lastDate: now,
    );

    if (date != null) {
      setState(() {
        _applicationDate = date;

        // Auto-Suggest Next Number (Pre-Admission: A-)
        if (_admissionStatus == 'pre_admission') {
          _suggestNextNumber(date, isAdmission: false);
        }
      });
    }
  }

  Future<void> _suggestNextNumber(DateTime date,
      {required bool isAdmission}) async {
    final prefixLetter = isAdmission ? 'C' : 'A';
    final datePart = DateFormat('yyMM').format(date);
    final fullPrefix = '$prefixLetter-$datePart';

    // Temporary loading state
    _caseNumberController.text = '$fullPrefix...';

    if (!mounted) return;

    // Fetch latest from DB
    final latest = await context
        .read<ResidentRepository>()
        .getLatestCaseNumber(fullPrefix);

    if (!mounted) return;

    if (latest == null) {
      // No existing number, start at 01
      _caseNumberController.text = '${fullPrefix}01';
    } else {
      // Increment logic
      try {
        // e.g. A-250505 -> remove "A-2505" -> "05"
        final sequenceStr = latest.substring(fullPrefix.length);
        final sequence = int.parse(sequenceStr);
        final nextSequence = sequence + 1;
        // Pad to match existing length, minimum 2
        final padding = sequenceStr.length < 2 ? 2 : sequenceStr.length;
        _caseNumberController.text =
            '$fullPrefix${nextSequence.toString().padLeft(padding, '0')}';
      } catch (e) {
        // Fallback if parsing fails
        _caseNumberController.text = '${fullPrefix}01';
      }
    }
  }

  Widget _buildBasicInfoStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Admission Type Selector (Only for New Residents)
        if (widget.resident == null) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('ENTRY TYPE',
                    style: Theme.of(context).textTheme.labelLarge),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: RadioListTile<String>(
                        title: const Text('DIRECT ADMISSION'),
                        value: 'admitted',
                        groupValue: _admissionStatus,
                        contentPadding: EdgeInsets.zero,
                        onChanged: (value) {
                          setState(() {
                            _admissionStatus = value!;
                            if (_currentStep > 0) _currentStep = 0;
                          });
                        },
                      ),
                    ),
                    Expanded(
                      child: RadioListTile<String>(
                        title: const Text('PRE-ADMISSION'),
                        value: 'pre_admission',
                        groupValue: _admissionStatus,
                        contentPadding: EdgeInsets.zero,
                        onChanged: (value) {
                          setState(() {
                            _admissionStatus = value!;
                            if (_currentStep > 0) _currentStep = 0;
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Application Date removed from here
        const SizedBox(height: 24),

        // Photo picker
        Center(
          child: InkWell(
            onTap: _pickImage,
            customBorder: const CircleBorder(),
            child: CircleAvatar(
              radius: 50,
              backgroundColor: AppColors.primaryLight.withOpacity(0.2),
              backgroundImage:
                  _photoBytes != null ? MemoryImage(_photoBytes!) : null,
              child: _photoBytes == null
                  ? const Icon(
                      Icons.add_a_photo,
                      size: 32,
                      color: AppColors.primary,
                    )
                  : null,
            ),
          ),
        ),
        Center(
          child: TextButton(
            onPressed: _pickImage,
            child: const Text('ADD PHOTO'),
          ),
        ),
        const SizedBox(height: 16),

        // Identity Unknown Checkbox
        CheckboxListTile(
          title: const Text('IDENTITY UNKNOWN / NO OFFICIAL NAME'),
          subtitle: const Text(
              'SETS FIRST NAME BASED ON AGE/SEX (E.G. LOLO/MANONG/TOTO). NICKNAME BECOMES LAST NAME.'),
          value: _isIdentityUnknown,
          controlAffinity: ListTileControlAffinity.leading,
          contentPadding: EdgeInsets.zero,
          onChanged: (bool? value) {
            setState(() {
              _isIdentityUnknown = value ?? false;
              if (_isIdentityUnknown) {
                // Trigger sync immediately
                _syncNameWithNickname();
                _middleNameController.clear();
                _selectedSuffix = null;
              } else {
                // Clear defaults if they match the auto-filled values
                if (_lastNameController.text == 'Resident' ||
                    _lastNameController.text == _nicknameController.text) {
                  _lastNameController.clear();
                }
                if (_firstNameController.text == 'Lolo' ||
                    _firstNameController.text == 'Lola') {
                  _firstNameController.clear();
                }
              }
            });
          },
        ),
        const SizedBox(height: 8),

        // Name fields
        _buildResponsiveRow(
          flexes: [3, 2, 3, 1],
          children: [
            TextFormField(
              controller: _firstNameController,
              enabled: !_isIdentityUnknown, // Disable if unknown
              textCapitalization: TextCapitalization.characters,
              inputFormatters: [UpperCaseTextFormatter()],
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'FIRST NAME *',
                prefixIcon: Icon(Icons.person),
              ),
              validator: (value) =>
                  value?.isEmpty ?? true ? 'First name is required' : null,
            ),
            TextFormField(
              controller: _middleNameController,
              textCapitalization: TextCapitalization.characters,
              inputFormatters: [UpperCaseTextFormatter()],
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'MIDDLE NAME',
                prefixIcon: Icon(Icons.person_outline),
              ),
            ),
            TextFormField(
              controller: _lastNameController,
              enabled: !_isIdentityUnknown, // Disable if unknown
              textCapitalization: TextCapitalization.characters,
              inputFormatters: [UpperCaseTextFormatter()],
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'LAST NAME *',
                prefixIcon: Icon(Icons.person),
              ),
              validator: (value) =>
                  value?.isEmpty ?? true ? 'Last name is required' : null,
            ),
            DropdownButtonFormField<String>(
              initialValue: _selectedSuffix,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'SUFFIX',
                prefixIcon: Icon(Icons.person_outline),
              ),
              items: [
                const DropdownMenuItem(value: null, child: Text('None')),
                ...FormOptions.suffixes
                    .map((s) => DropdownMenuItem(value: s, child: Text(s))),
              ],
              onChanged: (value) => setState(() => _selectedSuffix = value),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildResponsiveRow(
          children: [
            TextFormField(
              controller: _nicknameController,
              textCapitalization: TextCapitalization.characters,
              inputFormatters: [UpperCaseTextFormatter()],
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'NICKNAME',
                prefixIcon: Icon(Icons.face),
              ),
            ),
            // Demographics
            InkWell(
              onTap: () => _selectDate(context, true),
              borderRadius: BorderRadius.circular(4),
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'DATE OF BIRTH *',
                  prefixIcon: Icon(Icons.cake),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        _dateOfBirth != null
                            ? DateFormat('MMMM d, yyyy')
                                .format(_dateOfBirth!)
                                .toUpperCase()
                            : 'SELECT DATE',
                        style: TextStyle(
                          color: _dateOfBirth != null
                              ? AppColors.textPrimaryLight
                              : AppColors.textSecondaryLight,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (_dateOfBirth != null) ...[
                      const SizedBox(width: 8),
                      Text(
                        'AGE: ${DateTime.now().year - _dateOfBirth!.year}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            DropdownButtonFormField<String>(
              initialValue: _gender,
              decoration: const InputDecoration(
                labelText: 'SEX *',
                prefixIcon: Icon(Icons.wc),
              ),
              items: const [
                DropdownMenuItem(value: 'male', child: Text('MALE')),
                DropdownMenuItem(value: 'female', child: Text('FEMALE')),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _gender = value;
                    _syncNameWithNickname();
                  });
                }
              },
            ),
          ],
        ),
        const SizedBox(height: 24),
        const Text('PLACE OF BIRTH',
            style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        _buildResponsiveRow(
          children: [
            DropdownButtonFormField<String>(
              initialValue: _pobSelectedProvince,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'PROVINCE',
                prefixIcon: Icon(Icons.location_city),
              ),
              items: _provinceList.isEmpty
                  ? []
                  : _provinceList
                      .map((p) => DropdownMenuItem(
                          value: p,
                          child: Text(p.toUpperCase(),
                              overflow: TextOverflow.ellipsis)))
                      .toList(),
              onChanged: _onPobProvinceChanged,
            ),
            DropdownButtonFormField<String>(
              initialValue: _pobSelectedCity,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'CITY/MUNICIPALITY',
                prefixIcon: Icon(Icons.location_city),
              ),
              items: _pobCityList.isEmpty
                  ? []
                  : _pobCityList
                      .map((c) => DropdownMenuItem(
                          value: c,
                          child: Text(c.toUpperCase(),
                              overflow: TextOverflow.ellipsis)))
                      .toList(),
              onChanged: _onPobCityChanged,
            ),
          ],
        ),
        const SizedBox(height: 24),

        Text('REFERRAL INFORMATION',
            style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 12),
        _buildResponsiveRow(children: [
          RawAutocomplete<String>(
            textEditingController: _referralOtherController,
            focusNode: FocusNode(),
            optionsBuilder: (TextEditingValue textEditingValue) {
              // Show all options if empty or matching
              if (textEditingValue.text.isEmpty) {
                return FormOptions.referralSources;
              }
              return FormOptions.referralSources.where((String option) {
                return option
                    .toLowerCase()
                    .contains(textEditingValue.text.toLowerCase());
              });
            },
            onSelected: (String selection) {
              // Logic to update city list based on CSWDO/MSWDO
              if (_referralSelectedProvince != null) {
                bool? isCity;
                if (selection == 'CSWDO') isCity = true;
                if (selection == 'MSWDO') isCity = false;

                if (isCity != null) {
                  setState(() {
                    _referralCityList = _addressRepository
                        .getCities(_referralSelectedProvince!, isCity: isCity);
                    // Clear city if invalid
                    if (_referralSelectedCity != null &&
                        !_referralCityList.contains(_referralSelectedCity)) {
                      _referralSelectedCity = null;
                      _referralSelectedBarangay = null;
                      _referralBarangayList = [];
                    }
                  });
                }
              }
            },
            fieldViewBuilder:
                (context, controller, focusNode, onEditingComplete) {
              return TextFormField(
                controller:
                    controller, // This is _referralOtherController attached by RawAutocomplete
                focusNode: focusNode,
                textCapitalization: TextCapitalization.characters,
                inputFormatters: [UpperCaseTextFormatter()],
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'REFERRED BY *',
                  prefixIcon: Icon(Icons.record_voice_over),
                  hintText: 'Select or Type (e.g. CSWDO)',
                ),
                validator: (v) => v?.trim().isEmpty == true ? 'Required' : null,
                onEditingComplete: onEditingComplete,
              );
            },
            optionsViewBuilder: (context, onSelected, options) {
              return _buildAutocompleteOptionsView(
                  context, onSelected, options, 'referred_by');
            },
          ),
          TextFormField(
            controller: _referralContactPersonController,
            textCapitalization: TextCapitalization.characters,
            inputFormatters: [UpperCaseTextFormatter()],
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: 'REFERRING PERSON NAME',
              prefixIcon: Icon(Icons.person),
            ),
          ),
        ]),
        const SizedBox(height: 24),
        const Text('REFERRING PARTY ADDRESS',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        const SizedBox(height: 12),
        _buildResponsiveRow(
          children: [
            DropdownButtonFormField<String>(
              initialValue: _referralSelectedProvince,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'PROVINCE',
                prefixIcon: Icon(Icons.location_city),
              ),
              items: _provinceList.isEmpty
                  ? []
                  : _provinceList
                      .map((p) => DropdownMenuItem(
                          value: p,
                          child: Text(p.toUpperCase(),
                              overflow: TextOverflow.ellipsis)))
                      .toList(),
              onChanged: _onReferralProvinceChanged,
              validator: (v) => v == null ? 'Required' : null,
            ),
            DropdownButtonFormField<String>(
              initialValue: _referralSelectedCity,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'CITY/MUNICIPALITY',
                prefixIcon: Icon(Icons.location_city),
              ),
              items: _referralCityList.isEmpty
                  ? []
                  : _referralCityList
                      .map((c) => DropdownMenuItem(
                          value: c,
                          child: Text(c.toUpperCase(),
                              overflow: TextOverflow.ellipsis)))
                      .toList(),
              onChanged: _onReferralCityChanged,
              validator: (v) => v == null ? 'Required' : null,
            ),
            DropdownButtonFormField<String>(
              initialValue: _referralSelectedBarangay,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'BARANGAY',
                prefixIcon: Icon(Icons.holiday_village),
              ),
              items: _referralBarangayList.isEmpty
                  ? []
                  : _referralBarangayList
                      .map((b) => DropdownMenuItem(
                          value: b,
                          child: Text(b.toUpperCase(),
                              overflow: TextOverflow.ellipsis)))
                      .toList(),
              onChanged: (value) =>
                  setState(() => _referralSelectedBarangay = value),
            ),
          ],
        ),
        const SizedBox(height: 8),
        RawAutocomplete<String>(
          textEditingController: _referralStreetAddressController,
          focusNode: FocusNode(),
          optionsBuilder: (TextEditingValue textEditingValue) async {
            if (textEditingValue.text.length < 2) return [];
            return await context
                .read<ResidentRepository>()
                .getDistinctColumnValues(
                    'referring_party_address', textEditingValue.text);
          },
          fieldViewBuilder:
              (context, controller, focusNode, onEditingComplete) {
            return TextFormField(
              controller: controller,
              focusNode: focusNode,
              textCapitalization: TextCapitalization.characters,
              inputFormatters: [UpperCaseTextFormatter()],
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'STREET / BUILDING / OFFICE INFO',
                prefixIcon: Icon(Icons.location_on),
              ),
              onEditingComplete: onEditingComplete,
            );
          },
          optionsViewBuilder: (context, onSelected, options) {
            return _buildAutocompleteOptionsView(
              context,
              (String selection) {
                // Smart Reverse Parse for Autocomplete
                final parts = selection.split(', ');

                // Need at least 3 parts to confidently identify loc
                if (parts.length >= 3) {
                  String? prov, city, brgy, street;

                  // 1. Province (Last)
                  prov = parts.last.trim();

                  if (_provinceList.contains(prov)) {
                    // 2. City (2nd Last)
                    bool? isCity;
                    if (_selectedReferralSource == 'CSWDO') isCity = true;
                    if (_selectedReferralSource == 'MSWDO') isCity = false;
                    // We can't easily check city validity without loading the list,
                    // but we can try to guess or load it.
                    // Optimization: Load the city list for the matched province
                    final checkCityList =
                        _addressRepository.getCities(prov, isCity: isCity);

                    final potentialCity = parts[parts.length - 2].trim();
                    if (checkCityList.contains(potentialCity)) {
                      city = potentialCity;

                      // 3. Brgy (3rd Last)
                      final checkBrgyList =
                          _addressRepository.getBarangays(prov, city);
                      final potentialBrgy = parts[parts.length - 3].trim();

                      if (checkBrgyList.contains(potentialBrgy)) {
                        brgy = potentialBrgy;

                        // 4. Remainder is Street
                        final streetParts = parts.sublist(0, parts.length - 3);
                        street = streetParts.join(', ').trim();
                      }
                    }
                  }

                  setState(() {
                    if (prov != null &&
                        city != null &&
                        brgy != null &&
                        street != null) {
                      _referralSelectedProvince = prov;

                      bool? isCity;
                      if (_selectedReferralSource == 'CSWDO') isCity = true;
                      if (_selectedReferralSource == 'MSWDO') isCity = false;
                      _referralCityList =
                          _addressRepository.getCities(prov, isCity: isCity);
                      _referralSelectedCity = city;
                      _referralBarangayList =
                          _addressRepository.getBarangays(prov, city);
                      _referralSelectedBarangay = brgy;

                      _referralStreetAddressController.text = street;
                    } else {
                      // Fallback
                      _referralStreetAddressController.text = selection;
                    }
                  });
                } else {
                  // Just text
                  onSelected(selection);
                }
              },
              options,
              'referring_party_address',
            );
          },
        ),

        const SizedBox(height: 24),
        Text(
            _admissionStatus == 'admitted'
                ? 'ADMISSION & CONTROL DETAILS'
                : 'APPLICATION & CONTROL DETAILS',
            style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 12),
        // Date and Control Number Row
        _buildResponsiveRow(children: [
          // Date Field (Dynamic: Admission or Application)
          InkWell(
            onTap: () => _admissionStatus == 'admitted'
                ? _selectDate(context, false)
                : _selectApplicationDate(context),
            borderRadius: BorderRadius.circular(4),
            child: InputDecorator(
              decoration: InputDecoration(
                labelText: _admissionStatus == 'admitted'
                    ? 'ADMISSION DATE *'
                    : 'APPLICATION DATE',
                prefixIcon: const Icon(Icons.calendar_today),
              ),
              child: Text(
                (_admissionStatus == 'admitted'
                    ? (_admissionDate != null
                        ? DateFormat('MMMM d, yyyy')
                            .format(_admissionDate!)
                            .toUpperCase()
                        : 'SELECT DATE')
                    : (_applicationDate != null
                        ? DateFormat('MMMM d, yyyy')
                            .format(_applicationDate!)
                            .toUpperCase()
                        : DateFormat('MMMM d, yyyy')
                            .format(DateTime.now())
                            .toUpperCase())),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          // Case/App Control Number Field
          TextFormField(
            controller: _caseNumberController,
            textCapitalization: TextCapitalization.characters,
            inputFormatters: [UpperCaseTextFormatter()],
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(
              labelText: _admissionStatus == 'admitted'
                  ? 'CASE CONTROL NUMBER'
                  : 'APPLICATION CONTROL NUMBER',
              hintText: _admissionStatus == 'admitted'
                  ? 'e.g. C-250592'
                  : 'e.g. A-250592',
              prefixIcon: const Icon(Icons.numbers),
              helperText: 'Format: [A/C]-YYMM + Sequence',
            ),
            validator: (value) {
              if (_admissionStatus == 'admitted' &&
                  (value == null || value.isEmpty)) {
                return 'Case Number is required for admission';
              }
              return null;
            },
          ),
        ]),
        const SizedBox(height: 16),
        _buildResponsiveRow(children: [
          DropdownButtonFormField<String>(
            initialValue: _selectedCaseCategory?.toUpperCase(),
            decoration: const InputDecoration(
              labelText: 'CASE CATEGORY',
              prefixIcon: Icon(Icons.category),
            ),
            items: FormOptions.caseCategories
                .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                .toList(),
            onChanged: (value) => setState(() => _selectedCaseCategory = value),
            validator: (v) => v == null ? 'Required' : null,
          ),
          RawAutocomplete<String>(
            textEditingController: _conditionController,
            focusNode: FocusNode(),
            optionsBuilder: (TextEditingValue textEditingValue) async {
              // Fetch DB + Defaults
              final dbValues = await context
                  .read<ResidentRepository>()
                  .getDistinctColumnValues('condition', textEditingValue.text);

              final defaultValues = FormOptions.conditions
                  .where((c) => c
                      .toLowerCase()
                      .contains(textEditingValue.text.toLowerCase()))
                  .toList();

              // Merge and dedup
              final Set<String> allValues = {...dbValues, ...defaultValues};
              return allValues.toList();
            },
            fieldViewBuilder:
                (context, controller, focusNode, onEditingComplete) {
              return TextFormField(
                controller: controller,
                focusNode: focusNode,
                textCapitalization: TextCapitalization.characters,
                inputFormatters: [UpperCaseTextFormatter()],
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'HEALTH STATUS / CONDITION *',
                  prefixIcon: Icon(Icons.health_and_safety),
                ),
                onEditingComplete: onEditingComplete,
                validator: (v) => v?.trim().isEmpty == true
                    ? 'Health Status is required'
                    : null,
              );
            },
            optionsViewBuilder: (context, onSelected, options) {
              return _buildAutocompleteOptionsView(
                  context, onSelected, options, 'condition');
            },
          ),
          RawAutocomplete<String>(
            textEditingController: _disabilityController,
            focusNode: FocusNode(),
            optionsBuilder: (TextEditingValue textEditingValue) async {
              // Fetch DB + Defaults
              final dbValues = await context
                  .read<ResidentRepository>()
                  .getDistinctColumnValues(
                      'nature_of_disability', textEditingValue.text);

              final defaultValues = FormOptions.disabilities
                  .where((c) => c
                      .toLowerCase()
                      .contains(textEditingValue.text.toLowerCase()))
                  .toList();

              // Merge and dedup
              final Set<String> allValues = {...dbValues, ...defaultValues};
              return allValues.toList();
            },
            fieldViewBuilder:
                (context, controller, focusNode, onEditingComplete) {
              return TextFormField(
                controller: controller,
                focusNode: focusNode,
                textCapitalization: TextCapitalization.characters,
                inputFormatters: [UpperCaseTextFormatter()],
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'NATURE OF DISABILITY (IF APPLICABLE)',
                  prefixIcon: Icon(Icons.accessible),
                ),
                onEditingComplete: onEditingComplete,
              );
            },
            optionsViewBuilder: (context, onSelected, options) {
              return _buildAutocompleteOptionsView(
                  context, onSelected, options, 'nature_of_disability');
            },
          ),
        ]),
        const SizedBox(height: 16),
        _buildResponsiveRow(children: [
          RawAutocomplete<String>(
            textEditingController: _mentalHealthConditionController,
            focusNode: FocusNode(),
            optionsBuilder: (TextEditingValue textEditingValue) {
              return _mentalHealthConditions
                  .where((c) => c
                      .toLowerCase()
                      .contains(textEditingValue.text.toLowerCase()))
                  .toList();
            },
            fieldViewBuilder:
                (context, controller, focusNode, onEditingComplete) {
              return TextFormField(
                controller: controller,
                focusNode: focusNode,
                textCapitalization: TextCapitalization.characters,
                inputFormatters: [UpperCaseTextFormatter()],
                textInputAction: TextInputAction.done,
                decoration: const InputDecoration(
                  labelText: 'MENTAL HEALTH CONDITION (IF APPLICABLE)',
                  prefixIcon: Icon(Icons.psychology),
                ),
                onEditingComplete: onEditingComplete,
              );
            },
            optionsViewBuilder: (context, onSelected, options) {
              return _buildAutocompleteOptionsView(
                  context, onSelected, options, 'mental_health_condition');
            },
          ),
        ]),

        const SizedBox(height: 24),
        Text('COMPLETE ADDRESS', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        _buildResponsiveRow(
          flexes: [2, 2, 2],
          children: [
            DropdownButtonFormField<String>(
              initialValue: _selectedProvince,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'PROVINCE',
                prefixIcon: Icon(Icons.location_city),
              ),
              items: _provinceList.isEmpty
                  ? []
                  : _provinceList
                      .map((p) => DropdownMenuItem(
                          value: p,
                          child: Text(p.toUpperCase(),
                              overflow: TextOverflow.ellipsis)))
                      .toList(),
              onChanged: _onProvinceChanged,
            ),
            DropdownButtonFormField<String>(
              initialValue: _selectedCity,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'CITY/MUNICIPALITY',
                prefixIcon: Icon(Icons.location_city),
              ),
              items: _cityList.isEmpty
                  ? []
                  : _cityList
                      .map((c) => DropdownMenuItem(
                          value: c,
                          child: Text(c.toUpperCase(),
                              overflow: TextOverflow.ellipsis)))
                      .toList(),
              onChanged: _onCityChanged,
            ),
            DropdownButtonFormField<String>(
              initialValue: _selectedBarangay,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'BARANGAY',
                prefixIcon: Icon(Icons.home_work),
              ),
              items: _barangayList.isEmpty
                  ? []
                  : _barangayList
                      .map((b) => DropdownMenuItem(
                          value: b,
                          child: Text(b.toUpperCase(),
                              overflow: TextOverflow.ellipsis)))
                      .toList(),
              onChanged: (value) => setState(() => _selectedBarangay = value),
            ),
          ],
        ),
        const SizedBox(height: 16),
        RawAutocomplete<String>(
          textEditingController: _streetAddressController,
          focusNode: FocusNode(),
          optionsBuilder: (TextEditingValue textEditingValue) async {
            if (textEditingValue.text.length < 2) return [];
            return await context
                .read<ResidentRepository>()
                .getDistinctColumnValues(
                    'street_address', textEditingValue.text);
          },
          fieldViewBuilder:
              (context, controller, focusNode, onEditingComplete) {
            return TextFormField(
              controller: controller,
              focusNode: focusNode,
              textCapitalization: TextCapitalization.characters,
              inputFormatters: [UpperCaseTextFormatter()],
              textInputAction: TextInputAction.done,
              decoration: const InputDecoration(
                labelText: 'HOUSE NO. / STREET / PUROK',
                prefixIcon: Icon(Icons.home),
              ),
              maxLines: 1,
              onEditingComplete: onEditingComplete,
            );
          },
          optionsViewBuilder: (context, onSelected, options) {
            return _buildAutocompleteOptionsView(
                context, onSelected, options, 'street_address');
          },
        ),
        const SizedBox(height: 24),
        const Text('CASE MANAGEMENT / SUPERVISION',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        const SizedBox(height: 12),
        // Social Worker Dropdown
        DropdownButtonFormField<String>(
          decoration: const InputDecoration(
            labelText: 'ASSIGNED SOCIAL WORKER',
            prefixIcon: Icon(Icons.person_outline),
            helperText:
                'Assign a social worker for case management and intervention.',
          ),
          initialValue: _selectedSocialWorkerId,
          items: [
            const DropdownMenuItem(
                value: null, child: Text('None / Unassigned')),
            if (_selectedSocialWorkerId != null &&
                !_socialWorkers.any((u) => u.id == _selectedSocialWorkerId))
              DropdownMenuItem(
                value: _selectedSocialWorkerId,
                child: Text(
                  'Unknown/Inactive Social Worker',
                  style: const TextStyle(fontStyle: FontStyle.italic),
                ),
              ),
            ..._socialWorkers.map((user) => DropdownMenuItem(
                  value: user.id,
                  child: Text(user.fullName.toUpperCase()),
                )),
          ],
          onChanged: (value) {
            setState(() {
              _selectedSocialWorkerId = value;
            });
          },
          validator: (value) => value == null ? 'Required' : null,
        ),

        if (_admissionStatus == 'admitted') ...[
          const SizedBox(height: 24),
          DropdownButtonFormField<String>(
            decoration: const InputDecoration(
              labelText: 'ASSIGNED HOUSEPARENT',
              prefixIcon: Icon(Icons.manage_accounts),
            ),
            // Fix: Ensure value exists in items or is null
            initialValue:
                (_houseparents.any((u) => u.id == _selectedHouseparentId)
                    ? _selectedHouseparentId
                    : null),
            items: [
              const DropdownMenuItem(
                  value: null, child: Text('None / Unassigned')),
              ..._houseparents.map((user) => DropdownMenuItem(
                    value: user.id,
                    child: Text(user.fullName.toUpperCase(),
                        overflow: TextOverflow.ellipsis),
                  )),
            ],
            onChanged: (value) {
              setState(() {
                _selectedHouseparentId = value;
              });
            },
            validator: (value) => value == null ? 'Required' : null,
          ),
        ],
      ],
    );
  }

  Widget _buildDropdownWithOtherWidget({
    required String label,
    required String? value,
    required List<String> items,
    required Function(String?) onChanged,
    required TextEditingController otherController,
    IconData? icon,
    String? autocompleteColumn,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<String>(
          initialValue: value,
          isExpanded: true,
          decoration: InputDecoration(
            labelText: label,
            prefixIcon: icon != null ? Icon(icon) : null,
          ),
          items: items
              .map((item) => DropdownMenuItem(
                    value: item,
                    child: Text(item),
                  ))
              .toList(),
          onChanged: onChanged,
          validator: validator,
        ),
        if (value == 'Others') ...[
          const SizedBox(height: 8),
          if (autocompleteColumn != null)
            RawAutocomplete<String>(
              textEditingController: otherController,
              focusNode: FocusNode(),
              optionsBuilder: (TextEditingValue textEditingValue) async {
                if (textEditingValue.text.length < 2) return [];
                return await context
                    .read<ResidentRepository>()
                    .getDistinctColumnValues(
                        autocompleteColumn, textEditingValue.text);
              },
              fieldViewBuilder:
                  (context, controller, focusNode, onEditingComplete) {
                return TextFormField(
                  controller: controller,
                  focusNode: focusNode,
                  textCapitalization: TextCapitalization.characters,
                  inputFormatters: [UpperCaseTextFormatter()],
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: 'PLEASE SPECIFY ($label)',
                    prefixIcon: const Icon(Icons.edit),
                  ),
                  validator: (v) =>
                      v?.isNotEmpty == true ? null : 'Please specify',
                  onEditingComplete: onEditingComplete,
                );
              },
              optionsViewBuilder: (context, onSelected, options) {
                return _buildAutocompleteOptionsView(
                    context, onSelected, options, autocompleteColumn);
              },
            )
          else
            TextFormField(
              controller: otherController,
              textCapitalization: TextCapitalization.characters,
              inputFormatters: [UpperCaseTextFormatter()],
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: 'PLEASE SPECIFY ($label)',
                prefixIcon: const Icon(Icons.edit),
              ),
              validator: (v) => v?.isNotEmpty == true ? null : 'Please specify',
            ),
        ],
      ],
    );
  }

  Widget _buildLocationStep() {
    return Column(
      children: [
        _buildResponsiveRow(
          children: [
            DropdownButtonFormField<WardModel>(
              initialValue: _selectedWard,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'WARD *',
                prefixIcon: Icon(Icons.room),
              ),
              items: _wards
                  .map((ward) => DropdownMenuItem(
                        value: ward,
                        child: Text(
                          '${ward.name.toUpperCase()} (${ward.availableBeds} BEDS FREE)',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _selectedWard = value;
                  _selectedBed = null;
                });
                _onWardChanged(value);
              },
              validator: (value) =>
                  value == null ? 'Please select a ward' : null,
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildResponsiveRow(
          children: [
            DropdownButtonFormField<String>(
              initialValue: _selectedBed,
              decoration: const InputDecoration(
                labelText: 'BED NUMBER',
                prefixIcon: Icon(Icons.bed),
              ),
              items: _availableBeds
                  .map((bed) => DropdownMenuItem(value: bed, child: Text(bed)))
                  .toList(),
              onChanged: _loadingBeds
                  ? null
                  : (value) => setState(() => _selectedBed = value),
              validator: (value) =>
                  value == null ? 'Please select a bed' : null,
              hint: _loadingBeds ? const Text('Loading...') : null,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAdditionalStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'SOCIAL INFORMATION',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        const SizedBox(height: 12),
        _buildResponsiveRow(children: [
          DropdownButtonFormField<String>(
            initialValue: _selectedCivilStatus,
            decoration: const InputDecoration(
              labelText: 'CIVIL STATUS',
              prefixIcon: Icon(Icons.people_outline),
            ),
            items: FormOptions.civilStatuses
                .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                .toList(),
            onChanged: (value) => setState(() => _selectedCivilStatus = value),
          ),
          _buildDropdownWithOtherWidget(
            label: 'RELIGION',
            value: _selectedReligion,
            items: FormOptions.religions,
            icon: Icons.church,
            otherController: _religionOtherController,
            autocompleteColumn: 'religion',
            onChanged: (v) => setState(() => _selectedReligion = v),
          ),
        ]),
        const SizedBox(height: 16),
        _buildResponsiveRow(children: [
          DropdownButtonFormField<String>(
            initialValue: _selectedEducation,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'EDUCATIONAL ATTAINMENT',
              prefixIcon: Icon(Icons.school),
            ),
            items: FormOptions.educationLevels
                .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                .toList(),
            onChanged: _onEducationChanged,
          ),
          InputDecorator(
            decoration: const InputDecoration(
              labelText: 'K-12 GRADUATE?',
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              border: OutlineInputBorder(),
            ),
            child: InkWell(
              onTap: () {
                setState(() {
                  _isK12 = !_isK12;
                  if (_selectedGradeLevel != null) {
                    _onGradeLevelChanged(_selectedGradeLevel);
                  } else if (_selectedEducation != null) {
                    _onEducationChanged(_selectedEducation);
                  }
                });
              },
              borderRadius: BorderRadius.circular(4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _isK12 ? '12 BASE YEARS' : '10 BASE YEARS',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                  Switch(
                    value: _isK12,
                    onChanged: (val) {
                      setState(() {
                        _isK12 = val;
                        if (_selectedGradeLevel != null) {
                          _onGradeLevelChanged(_selectedGradeLevel);
                        } else if (_selectedEducation != null) {
                          _onEducationChanged(_selectedEducation);
                        }
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
        ]),
        const SizedBox(height: 16),
        _buildResponsiveRow(children: [
          DropdownButtonFormField<String>(
            initialValue: _selectedGradeLevel,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'HIGHEST GRADE/YEAR',
              prefixIcon: Icon(Icons.stars),
            ),
            // Show options if available, or just empty list disabled
            items: _gradeLevelOptions.isEmpty
                ? []
                : _gradeLevelOptions
                    .map((g) => DropdownMenuItem(
                        value: g,
                        child: Text(g, overflow: TextOverflow.ellipsis)))
                    .toList(),
            onChanged:
                _gradeLevelOptions.isNotEmpty ? _onGradeLevelChanged : null,
            // Only validate if options exist (meaning it's applicable)
            validator: (v) =>
                _gradeLevelOptions.isNotEmpty && v == null ? 'Required' : null,
          ),
          TextFormField(
            controller: TextEditingController(text: _selectedYearsEducation),
            readOnly: true,
            decoration: const InputDecoration(
              labelText: 'YEARS OF EDUCATION',
              prefixIcon: Icon(Icons.timer),
              filled: true,
            ),
          ),
        ]),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                'FAMILY COMPOSITION (SOURCE OF TRUTH)',
                style: Theme.of(context).textTheme.titleSmall,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            TextButton.icon(
              onPressed: _showAddFamilyMemberDialog,
              icon: const Icon(Icons.add),
              label: const Text('ADD MEMBER'),
              // Remove fixed size or use shrink wrap if needed, mainly ensure Expanded sibling helps
            ),
          ],
        ),
        if (_familyMembers.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                border: Border.all(color: Colors.amber),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                  'PLEASE ADD FAMILY MEMBERS FIRST. YOU WILL SELECT NEAREST RELATIVE AND EMERGENCY CONTACT FROM THIS LIST.',
                  style: TextStyle(fontStyle: FontStyle.italic)),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _familyMembers.length,
            itemBuilder: (context, index) {
              final member = _familyMembers[index];
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 4),
                child: ListTile(
                  title: Text(member['name'] ?? ''),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                          '${member['relationship']} • ${member['age']} yo • ${member['occupation']}'),
                      if (member['contact']?.isNotEmpty == true)
                        Text('📞 ${member['contact']}'),
                      if (member['address']?.isNotEmpty == true)
                        Text('🏠 ${member['address']}'),
                    ],
                  ),
                  onTap: () => _showAddFamilyMemberDialog(index: index),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () {
                      setState(() {
                        final name = _familyMembers[index]['name'];
                        if (name == _selectedNearestRelativeName) {
                          _selectedNearestRelativeName = null;
                        }
                        if (name == _selectedEmergencyContactName) {
                          _selectedEmergencyContactName = null;
                        }
                        if (name == _selectedCustodianName) {
                          _selectedCustodianName = null;
                        }
                        _familyMembers.removeAt(index);
                      });
                    },
                  ),
                ),
              );
            },
          ),
        const SizedBox(height: 24),
        Text(
          'FAMILY BACKGROUND',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        _buildResponsiveRow(children: [
          Builder(builder: (context) {
            final options =
                _familyMembers.map((m) => m['name']).toSet().toList();
            final validVal = (options.contains(_selectedNearestRelativeName))
                ? _selectedNearestRelativeName
                : null;
            return DropdownButtonFormField<String>(
              initialValue: validVal,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'NEAREST RELATIVE',
                prefixIcon: Icon(Icons.person_pin),
              ),
              items: options.map((name) {
                return DropdownMenuItem(
                    value: name,
                    child: Text(name ?? '', overflow: TextOverflow.ellipsis));
              }).toList(),
              onChanged: (v) =>
                  setState(() => _selectedNearestRelativeName = v),
            );
          }),
          Builder(builder: (context) {
            final options = [
              ..._familyMembers.map((m) => m['name']).toSet(),
              'Others'
            ];
            final validVal = (options.contains(_selectedCustodianName))
                ? _selectedCustodianName
                : null;
            return DropdownButtonFormField<String>(
              initialValue: validVal,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'CUSTODIAN',
                prefixIcon: Icon(Icons.accessibility_new),
              ),
              items: options
                  .map((name) => DropdownMenuItem(
                      value: name,
                      child: Text(name ?? '', overflow: TextOverflow.ellipsis)))
                  .toList(),
              onChanged: (v) => setState(() => _selectedCustodianName = v),
            );
          }),
        ]),
        if (_selectedCustodianName == 'Others') ...[
          const SizedBox(height: 8),
          TextFormField(
            controller: _custodianNameController,
            textCapitalization: TextCapitalization.characters,
            inputFormatters: [UpperCaseTextFormatter()],
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: 'PLEASE SPECIFY (CUSTODIAN)',
              prefixIcon: Icon(Icons.edit),
            ),
          ),
        ],
        const SizedBox(height: 16),
        _buildResponsiveRow(children: [
          Builder(builder: (context) {
            final options = [
              ..._familyMembers.map((m) => m['name']).toSet(),
              'Others'
            ];
            final validVal = (options.contains(_selectedEmergencyContactName))
                ? _selectedEmergencyContactName
                : null;
            return DropdownButtonFormField<String>(
              initialValue: validVal,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'CONTACT NAME',
                prefixIcon: Icon(Icons.contact_phone),
              ),
              items: options
                  .map((name) => DropdownMenuItem(
                      value: name,
                      child: Text(name ?? '', overflow: TextOverflow.ellipsis)))
                  .toList(),
              onChanged: (v) =>
                  setState(() => _selectedEmergencyContactName = v),
            );
          }),
          if (_selectedEmergencyContactName == 'Others')
            DropdownButtonFormField<String>(
              initialValue: _selectedEmergencyRelation,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'RELATIONSHIP',
                prefixIcon: Icon(Icons.link),
              ),
              items: FormOptions.relationships
                  .map((item) => DropdownMenuItem(
                        value: item,
                        child: Text(item),
                      ))
                  .toList(),
              onChanged: (v) => setState(() => _selectedEmergencyRelation = v),
            )
          else
            const SizedBox.shrink(),
        ]),
        if (_selectedEmergencyContactName == 'Others' &&
            _selectedEmergencyRelation == 'Others') ...[
          const SizedBox(height: 8),
          TextFormField(
            controller: _emergencyRelationOtherController,
            textCapitalization: TextCapitalization.characters,
            inputFormatters: [UpperCaseTextFormatter()],
            decoration: const InputDecoration(
              labelText: 'PLEASE SPECIFY (RELATIONSHIP)',
              prefixIcon: Icon(Icons.edit),
            ),
          ),
        ],
        if (_selectedEmergencyContactName == 'Others') ...[
          const SizedBox(height: 8),
          _buildResponsiveRow(children: [
            TextFormField(
              controller: _emergencyNameController,
              textCapitalization: TextCapitalization.characters,
              inputFormatters: [UpperCaseTextFormatter()],
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'NAME',
                prefixIcon: Icon(Icons.person),
              ),
            ),
            TextFormField(
              controller: _emergencyPhoneController,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.done,
              decoration: const InputDecoration(
                labelText: 'PHONE NUMBER',
                prefixIcon: Icon(Icons.phone),
              ),
            ),
          ]),
        ],
      ],
    );
  }

  Future<void> _showAddFamilyMemberDialog({int? index}) async {
    final isEditing = index != null;
    final Map<String, String>? existingMember =
        isEditing ? _familyMembers[index] : null;

    final familyFormKey = GlobalKey<FormState>();

    // Name Components
    final familyFirstNameController = TextEditingController(
        text: existingMember?['first_name'] ?? existingMember?['name'] ?? '');
    final familyMiddleNameController =
        TextEditingController(text: existingMember?['middle_name'] ?? '');
    final familyLastNameController =
        TextEditingController(text: existingMember?['last_name'] ?? '');
    String? familySuffix = existingMember?['suffix'];

    // Validate Suffix
    if (familySuffix != null) {
      if (familySuffix.isEmpty) {
        familySuffix = null;
      } else if (!FormOptions.suffixes.contains(familySuffix)) {
        familySuffix = null;
      }
    }

    /* REMOVE OLD nameController */
    /* final nameController = ... */
    final ageController =
        TextEditingController(text: existingMember?['age'] ?? '');
    final occupationController =
        TextEditingController(text: existingMember?['occupation'] ?? '');
    final contactController =
        TextEditingController(text: existingMember?['contact'] ?? '');
    String? selectedCivilStatus = existingMember?['civil_status'];
    // Validate Civil Status
    if (selectedCivilStatus != null &&
        !FormOptions.civilStatuses.contains(selectedCivilStatus)) {
      // If invalid value, reset to null to avoid crash
      selectedCivilStatus = null;
    }

    final relationOtherController =
        TextEditingController(); // For family relative "Others"

    // Structured Address State
    final streetController = TextEditingController(
        text: existingMember?['street'] ??
            (isEditing ? '' : _streetAddressController.text));
    String? selectedProvince =
        existingMember?['province'] ?? (isEditing ? null : _selectedProvince);
    String? selectedCity =
        existingMember?['city'] ?? (isEditing ? null : _selectedCity);
    String? selectedBarangay =
        existingMember?['barangay'] ?? (isEditing ? null : _selectedBarangay);

    List<String> dialogCityList = [];
    List<String> dialogBarangayList = [];

    // Initial Load & Validation
    if (selectedProvince != null) {
      if (!_provinceList.contains(selectedProvince)) {
        selectedProvince = null;
        selectedCity = null;
        selectedBarangay = null;
      } else {
        dialogCityList = _addressRepository.getCities(selectedProvince);

        if (selectedCity != null) {
          if (!dialogCityList.contains(selectedCity)) {
            selectedCity = null;
            selectedBarangay = null;
          } else {
            dialogBarangayList =
                _addressRepository.getBarangays(selectedProvince, selectedCity);

            if (selectedBarangay != null &&
                !dialogBarangayList.contains(selectedBarangay)) {
              selectedBarangay = null;
            }
          }
        }
      }
    }

    String? selectedRelation = existingMember?['relationship'];
    // Validate Relationship
    if (selectedRelation != null &&
        !FormOptions.relationships.contains(selectedRelation)) {
      relationOtherController.text = selectedRelation;
      selectedRelation = 'Others';
    }

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(builder: (context, setDialogState) {
        return AlertDialog(
          title: Text(isEditing ? 'Edit Family Member' : 'Add Family Member'),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: Breakpoints.tablet),
            child: Form(
              key: familyFormKey,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Name Fields
                    TextFormField(
                      controller: familyFirstNameController,
                      textCapitalization: TextCapitalization.characters,
                      inputFormatters: [UpperCaseTextFormatter()],
                      textInputAction: TextInputAction.next,
                      decoration:
                          const InputDecoration(labelText: 'FIRST NAME *'),
                      validator: (v) =>
                          v?.isNotEmpty == true ? null : 'Required',
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: familyMiddleNameController,
                      textCapitalization: TextCapitalization.characters,
                      inputFormatters: [UpperCaseTextFormatter()],
                      textInputAction: TextInputAction.next,
                      decoration:
                          const InputDecoration(labelText: 'MIDDLE NAME'),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            controller: familyLastNameController,
                            textCapitalization: TextCapitalization.characters,
                            inputFormatters: [UpperCaseTextFormatter()],
                            textInputAction: TextInputAction.next,
                            decoration:
                                const InputDecoration(labelText: 'LAST NAME *'),
                            validator: (v) =>
                                v?.isNotEmpty == true ? null : 'Required',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 1,
                          child: DropdownButtonFormField<String>(
                            initialValue: familySuffix,
                            isExpanded: true,
                            decoration:
                                const InputDecoration(labelText: 'SUFFIX'),
                            items: [
                              const DropdownMenuItem(
                                  value: null, child: Text('None')),
                              ...FormOptions.suffixes.map((s) =>
                                  DropdownMenuItem(value: s, child: Text(s))),
                            ],
                            onChanged: (v) =>
                                setDialogState(() => familySuffix = v),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: ageController,
                      decoration: const InputDecoration(labelText: 'AGE'),
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly
                      ], // Numbers only
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: selectedCivilStatus,
                      isExpanded: true,
                      decoration:
                          const InputDecoration(labelText: 'CIVIL STATUS'),
                      items: FormOptions.civilStatuses
                          .map(
                              (s) => DropdownMenuItem(value: s, child: Text(s)))
                          .toList(),
                      onChanged: (v) =>
                          setDialogState(() => selectedCivilStatus = v),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: selectedRelation,
                      isExpanded: true,
                      decoration:
                          const InputDecoration(labelText: 'RELATIONSHIP *'),
                      items: FormOptions.relationships
                          .map(
                              (r) => DropdownMenuItem(value: r, child: Text(r)))
                          .toList(),
                      onChanged: (v) =>
                          setDialogState(() => selectedRelation = v),
                      validator: (v) => v == null ? 'Required' : null,
                    ),
                    if (selectedRelation == 'Others') ...[
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: relationOtherController,
                        textCapitalization: TextCapitalization.characters,
                        inputFormatters: [UpperCaseTextFormatter()],
                        textInputAction: TextInputAction.next,
                        decoration:
                            const InputDecoration(labelText: 'PLEASE SPECIFY'),
                        validator: (v) =>
                            v?.isNotEmpty == true ? null : 'Required',
                      ),
                    ],
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: occupationController,
                      textCapitalization: TextCapitalization.characters,
                      inputFormatters: [UpperCaseTextFormatter()],
                      decoration:
                          const InputDecoration(labelText: 'OCCUPATION'),
                    ),

                    const SizedBox(height: 24),
                    Text('Address',
                        style: Theme.of(context).textTheme.titleSmall),
                    const Divider(),

                    // Province
                    DropdownButtonFormField<String>(
                        initialValue: selectedProvince,
                        isExpanded: true,
                        decoration:
                            const InputDecoration(labelText: 'PROVINCE'),
                        items: _provinceList
                            .map((p) => DropdownMenuItem(
                                value: p, child: Text(p.toUpperCase())))
                            .toList(),
                        onChanged: (val) {
                          setDialogState(() {
                            selectedProvince = val;
                            selectedCity = null;
                            selectedBarangay = null;
                            dialogCityList = val != null
                                ? _addressRepository.getCities(val)
                                : [];
                            dialogBarangayList = [];
                          });
                        }),
                    const SizedBox(height: 12),
                    // City
                    DropdownButtonFormField<String>(
                        initialValue: selectedCity,
                        isExpanded: true,
                        decoration: const InputDecoration(
                            labelText: 'CITY/MUNICIPALITY'),
                        items: dialogCityList
                            .map((c) => DropdownMenuItem(
                                value: c, child: Text(c.toUpperCase())))
                            .toList(),
                        onChanged: (val) {
                          setDialogState(() {
                            selectedCity = val;
                            selectedBarangay = null;
                            dialogBarangayList = val != null
                                ? _addressRepository.getBarangays(
                                    selectedProvince!, val)
                                : [];
                          });
                        }),
                    const SizedBox(height: 12),
                    // Barangay
                    DropdownButtonFormField<String>(
                        initialValue: selectedBarangay,
                        isExpanded: true,
                        decoration:
                            const InputDecoration(labelText: 'BARANGAY'),
                        items: dialogBarangayList
                            .map((b) => DropdownMenuItem(
                                value: b, child: Text(b.toUpperCase())))
                            .toList(),
                        onChanged: (val) {
                          setDialogState(() => selectedBarangay = val);
                        }),
                    const SizedBox(height: 12),
                    // Street
                    TextFormField(
                      controller: streetController,
                      textCapitalization: TextCapitalization.characters,
                      inputFormatters: [UpperCaseTextFormatter()],
                      decoration:
                          const InputDecoration(labelText: 'STREET ADDRESS'),
                      maxLines: 1,
                    ),

                    const SizedBox(height: 16),
                    TextFormField(
                      controller: contactController,
                      decoration:
                          const InputDecoration(labelText: 'CONTACT NUMBER'),
                      keyboardType: TextInputType.phone,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly
                      ], // Numbers only
                      textInputAction: TextInputAction.done,
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (familyFormKey.currentState!.validate()) {
                  final relation = selectedRelation == 'Others'
                      ? relationOtherController.text.trim()
                      : selectedRelation!;

                  // Construct Full Address
                  final parts = [
                    streetController.text.trim(),
                    selectedBarangay,
                    selectedCity,
                    selectedProvince
                  ].where((p) => p != null && p.isNotEmpty).join(', ');

                  final newMember = {
                    'name':
                        '${familyFirstNameController.text.trim()} ${familyMiddleNameController.text.trim()} ${familyLastNameController.text.trim()} ${familySuffix ?? ''}'
                            .replaceAll(RegExp(r'\s+'), ' ')
                            .trim(),
                    'first_name': familyFirstNameController.text.trim(),
                    'middle_name': familyMiddleNameController.text.trim(),
                    'last_name': familyLastNameController.text.trim(),
                    'suffix': familySuffix ?? '', // Ensure String
                    'age': ageController.text.trim(),
                    'civil_status': selectedCivilStatus ?? '',
                    'relationship': relation,
                    'occupation': occupationController.text.trim(),
                    'contact': contactController.text.trim(),
                    // Storing components + full string
                    'address': parts,
                    'street': streetController.text.trim(),
                    'barangay': selectedBarangay ?? '',
                    'city': selectedCity ?? '',
                    'province': selectedProvince ?? '',
                  };

                  setState(() {
                    if (isEditing) {
                      // Rename handling
                      final oldName = _familyMembers[index]['name'];
                      if (oldName == _selectedNearestRelativeName) {
                        _selectedNearestRelativeName = newMember['name'];
                      }
                      if (oldName == _selectedEmergencyContactName) {
                        _selectedEmergencyContactName = newMember['name'];
                      }
                      if (oldName == _selectedCustodianName) {
                        _selectedCustodianName = newMember['name'];
                      }

                      _familyMembers[index] = newMember;
                    } else {
                      _familyMembers.add(newMember);
                    }
                  });

                  Navigator.pop(context);
                }
              },
              child: Text(isEditing ? 'Update' : 'Add'),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildAutocompleteOptionsView(
      BuildContext context,
      AutocompleteOnSelected<String> onSelected,
      Iterable<String> options,
      String column) {
    // Filter out locally hidden values
    final filteredOptions = options.where(
        (opt) => !_tempHiddenValues.contains('$column:${opt.toLowerCase()}'));

    return Align(
      alignment: Alignment.topLeft,
      child: Material(
        elevation: 4.0,
        child: SizedBox(
          width: MediaQuery.of(context).size.width * 0.9,
          child: ListView.builder(
            padding: EdgeInsets.zero,
            shrinkWrap: true,
            itemCount: filteredOptions.length,
            itemBuilder: (BuildContext context, int index) {
              final String option = filteredOptions.elementAt(index);

              // Check if default
              bool isDefault = false;
              if (column == 'mental_health_condition') {
                isDefault = true;
              } else if (column == 'condition') {
                isDefault = FormOptions.conditions.contains(option);
              } else if (column == 'nature_of_disability') {
                isDefault = FormOptions.disabilities.contains(option);
              } else if (column == 'religion') {
                isDefault = FormOptions.religions.contains(option);
              }

              return ListTile(
                title: Text(option.toUpperCase()),
                trailing: isDefault
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.close, size: 16),
                        onPressed: () => _confirmHideOption(column, option),
                        tooltip: 'Remove suggestion',
                      ),
                onTap: () => onSelected(option),
              );
            },
          ),
        ),
      ),
    );
  }

  Future<void> _confirmHideOption(String column, String value) async {
    // Check if value is a default option
    bool isDefault = false;
    if (column == 'condition') {
      isDefault = FormOptions.conditions.contains(value);
    } else if (column == 'nature_of_disability') {
      isDefault = FormOptions.disabilities.contains(value);
    } else if (column == 'religion') {
      isDefault = FormOptions.religions.contains(value);
    } else if (column == 'street_address') {
      // Addresses are dynamic, never default protected really
      isDefault = false;
    }
    // Add logic for other columns if needed (e.g. relation)

    if (isDefault) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cannot remove default system options.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Remove Suggestion?'),
        content: Text('Do you want to hide "$value" from future suggestions?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(c, true),
              child: const Text('Remove')),
        ],
      ),
    );

    if (confirm == true) {
      if (mounted) {
        await context
            .read<ResidentRepository>()
            .hideAutocompleteValue(column, value);
        setState(() {
          _tempHiddenValues.add('$column:${value.toLowerCase()}');
        });
      }
    }
  }

  void _showRequirementsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.assignment_turned_in, color: AppColors.primary),
            SizedBox(width: 8),
            Text('Requirements Checklist'),
          ],
        ),
        content: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: Breakpoints.tablet),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                    'Please ensure the following details/documents are ready (if applicable):',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(height: 12),
                _RequirementItem('Referral Letter'),
                _RequirementItem('Social Case Study Report'),
                _RequirementItem('Chest X-Ray'),
                _RequirementItem('Medical Certificate'),
                _RequirementItem('Laboratory (Latest):'),
                Padding(
                  padding: EdgeInsets.only(left: 24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                          '• Blood Chemistry (FBS, SGPT, SGOT, Uric Creatinine, Cholesterol, BUN, Electrolytes)',
                          style: TextStyle(fontSize: 13)),
                      Text('• Urinalysis', style: TextStyle(fontSize: 13)),
                      Text('• Stool', style: TextStyle(fontSize: 13)),
                    ],
                  ),
                ),
                _RequirementItem('Ultrasound (If necessary)'),
                _RequirementItem('Psychological Evaluation'),
                _RequirementItem('Vaccination Card'),
                _RequirementItem('RT-PCR / Antigen Result'),
                _RequirementItem('OSCA ID'),
                SizedBox(height: 12),
                Divider(),
                Text(
                    'Note: You can save the profile even without these documents and update it later.',
                    style: TextStyle(
                        fontStyle: FontStyle.italic,
                        fontSize: 12,
                        color: Colors.grey)),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  void _parseReferralAddress(ResidentModel resident) {
    if (resident.referringPartyAddress != null) {
      final parts = resident.referringPartyAddress!.split(', ');

      // We expect at least 3 parts: Brgy, City, Prov (Street optional/empty)
      if (parts.length >= 3) {
        String? prov, city, brgy, street;

        // 1. Try to find Province (Start from end)
        prov = parts.last.trim();

        // Legacy Fix: Map Compostela Valley to Davao de Oro
        if (prov.toUpperCase() == 'COMPOSTELA VALLEY') {
          prov = 'DAVAO DE ORO';
        }

        if (_provinceList.contains(prov)) {
          _referralSelectedProvince = prov;

          // 2. Try to find City (2nd to last)
          bool? isCity;
          if (_selectedReferralSource == 'CSWDO') isCity = true;
          if (_selectedReferralSource == 'MSWDO') isCity = false;

          _referralCityList =
              _addressRepository.getCities(prov, isCity: isCity);

          if (parts.length >= 2) {
            city = parts[parts.length - 2].trim();
            if (_referralCityList.contains(city)) {
              _referralSelectedCity = city;

              // 3. Try to find Barangay (3rd to last)
              _referralBarangayList =
                  _addressRepository.getBarangays(prov, city);

              if (parts.length >= 3) {
                brgy = parts[parts.length - 3].trim();
                if (_referralBarangayList.contains(brgy)) {
                  _referralSelectedBarangay = brgy;

                  // 4. Remainder is Street
                  if (parts.length > 3) {
                    final streetParts = parts.sublist(0, parts.length - 3);
                    street = streetParts.join(', ').trim();
                  }
                }
              }
            }
          }
        }

        if (street != null) {
          _referralStreetAddressController.text = street;
        } else {
          // Fallback logic
          if (_referralSelectedProvince != null &&
              _referralSelectedCity != null &&
              _referralSelectedBarangay != null &&
              parts.length > 3) {
            final streetParts = parts.sublist(0, parts.length - 3);
            _referralStreetAddressController.text =
                streetParts.join(', ').trim();
          } else {
            // Complete fallback if parsing failed despite matching some parts
            _referralStreetAddressController.text =
                resident.referringPartyAddress!;
          }
        }
      } else {
        // Fallback for short addresses
        _referralStreetAddressController.text = resident.referringPartyAddress!;
      }
    }
  }
}

class _RequirementItem extends StatelessWidget {
  final String text;
  const _RequirementItem(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle_outline, size: 16, color: Colors.green),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 14))),
        ],
      ),
    );
  }
}
