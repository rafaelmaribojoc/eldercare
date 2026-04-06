/// Standard options for Resident Form Dropdowns
class FormOptions {
  // Suffixes
  static const List<String> suffixes = [
    'JR.',
    'SR.',
    'II',
    'III',
    'IV',
    'V',
  ];

  // Referred By Options
  static const List<String> referralSources = [
    'CSWDO', // City Social Welfare and Development Office
    'MSWDO', // Municipal Social Welfare and Development Office
    'DSWD FIELD OFFICE - CIU', // Crisis Intervention Unit
    'BARANGAY COUNCIL / BHERT', // Barangay Health Emergency Response Team
    'LAW ENFORCEMENT (PNP - WCPC)', // Women and Children Protection Center
    'REGIONAL/FAMILY COURTS',
    'PUBLIC/PRIVATE HOSPITALS',
    'GERIATRIC INSTITUTIONS',
    'SWDA / LICENSED NGOS', // Social Welfare and Development Agencies
    'OSCA', // Office of Senior Citizen Affairs
    'WALK-IN / SELF-REFERRAL',
    'FAMILY MEMBER / RELATIVE REFERRAL',
    'LEGISLATIVE / GOVERNMENT OFFICE ENDORSEMENT',
    'OTHERS',
  ];

  // Case Categories
  static const List<String> caseCategories = [
    'ABANDONED',
    'NEGLECTED',
    'UNATTACHED',
    'HOMELESS',
  ];

  // Physical Conditions (DSWD RCRF / General Health)
  static const List<String> conditions = [
    'AMBULATORY',
    'SEMI-AMBULATORY',
    'BEDRIDDEN',
    'FRAILTY',
    'WITH CHRONIC ILLNESS',
    'MENTALLY CHALLENGED',
    'NORMAL / HEALTHY',
  ];

  // Nature of Disability
  static const List<String> disabilities = [
    'PSYCHOSOCIAL DISABILITY',
    'VISUAL DISABILITY',
    'HEARING DISABILITY',
    'SPEECH IMPAIRMENT',
    'PHYSICAL DISABILITY (ORTHOPEDIC)',
    'MENTAL DISABILITY',
    'INTELLECTUAL DISABILITY',
    'LEARNING DISABILITY',
    'NONE',
    'OTHERS',
  ];

  // Educational Attainment
  static const List<String> educationLevels = [
    'NONE / NO FORMAL EDUCATION',
    'PRESCHOOL / KINDERGARTEN',
    'ELEMENTARY LEVEL',
    'ELEMENTARY GRADUATE',
    'HIGH SCHOOL LEVEL',
    'HIGH SCHOOL GRADUATE',
    'JUNIOR HIGH SCHOOL LEVEL',
    'JUNIOR HIGH SCHOOL GRADUATE',
    'SENIOR HIGH SCHOOL LEVEL',
    'SENIOR HIGH SCHOOL GRADUATE',
    'VOCATIONAL / TECHNICAL',
    'COLLEGE LEVEL',
    'COLLEGE GRADUATE',
    'POST-GRADUATE',
  ];

  // Years of Education (0 to 20+)
  static List<String> get yearsOfEducation {
    return List.generate(21, (index) => index.toString())..add('20+');
  }

  // Grade Levels for dynamic selection
  static const List<String> elementaryGrades = [
    'GRADE 1',
    'GRADE 2',
    'GRADE 3',
    'GRADE 4',
    'GRADE 5',
    'GRADE 6',
  ];

  static const List<String> highSchoolGrades = [
    'FIRST YEAR (GRADE 7)',
    'SECOND YEAR (GRADE 8)',
    'THIRD YEAR (GRADE 9)',
    'FOURTH YEAR (GRADE 10)',
  ];

  static const List<String> seniorHighGrades = [
    'GRADE 11',
    'GRADE 12',
  ];

  static const List<String> collegeYears = [
    '1ST YEAR',
    '2ND YEAR',
    '3RD YEAR',
    '4TH YEAR',
  ];

  static const List<String> vocationalDurations = [
    '6 MONTHS',
    '1 YEAR',
    '2 YEARS',
    '3 YEARS',
  ];

  // Religion
  static const List<String> religions = [
    'ROMAN CATHOLIC',
    'ISLAM',
    'IGLESIA NI CRISTO',
    'PHILIPPINE INDEPENDENT CHURCH (AGLIPAYAN)',
    'SEVENTH-DAY ADVENTIST',
    'BIBLE BAPTIST',
    'BORN AGAIN CHRISTIAN',
    'JEHOVAH\'S WITNESSES',
    'CHURCH OF JESUS CHRIST OF LATTER-DAY SAINTS',
    'UNITED CHURCH OF CHRIST IN THE PHILIPPINES',
    'EVANGELICAL',
    'NONE',
    'OTHERS',
  ];

  // Civil Status
  static const List<String> civilStatuses = [
    'SINGLE',
    'MARRIED',
    'WIDOWED',
    'SEPARATED',
    'DIVORCED',
    'COMMON LAW / LIVE-IN',
  ];

  // Relationships (Family, Emergency, Guardian)
  static const List<String> relationships = [
    'SPOUSE',
    'MOTHER',
    'FATHER',
    'SON',
    'DAUGHTER',
    'BROTHER',
    'SISTER',
    'GRANDMOTHER',
    'GRANDFATHER',
    'GRANDSON',
    'GRANDDAUGHTER',
    'AUNT',
    'UNCLE',
    'NIECE',
    'NEPHEW',
    'COUSIN',
    'MOTHER-IN-LAW',
    'FATHER-IN-LAW',
    'SON-IN-LAW',
    'DAUGHTER-IN-LAW',
    'SISTER-IN-LAW',
    'BROTHER-IN-LAW',
    'STEP-PARENT',
    'STEP-CHILD',
    'GUARDIAN',
    'CAREGIVER',
    'SOCIAL WORKER',
    'BARANGAY OFFICIAL',
    'OTHERS',
  ];
  // Staff Designations (DSWD RCRF)
  static const List<String> staffDesignations = [
    'SOCIAL WORKER',
    'HOUSEPARENT',
    'NURSE',
    'PSYCHOLOGIST',
    'PSYCHOMETRICIAN',
    'PARAMEDIC / CAREGIVER',
    'ADMINISTRATIVE AIDE',
    'CENTER HEAD',
    'SECURITY GUARD',
    'UTILITY WORKER',
    'COOK',
    'DRIVER',
    'VOLUNTEER',
    'OTHERS',
  ];
}
