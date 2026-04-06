/// MoCA-P (Montreal Cognitive Assessment - Philippine Version) Constants
/// All patient-facing content is in Filipino for proper administration.
class MocaConstants {
  MocaConstants._();

  // App Info
  static const String appName = 'MoCA-P';
  static const String appVersion = '1.0.0';

  // MoCA Test Constants
  static const int totalPoints = 30;
  static const int normalThreshold = 26;
  static const int educationAdjustmentYears = 12;

  // Section Points
  static const int visuospatialPoints = 5;
  static const int namingPoints = 3;
  static const int attentionPoints = 6;
  static const int languagePoints = 3;
  static const int abstractionPoints = 2;
  static const int delayedRecallPoints = 5;
  static const int orientationPoints = 6;

  // Memory Words (MoCA-P Filipino)
  static const List<String> memoryWords = [
    'MUKHA',
    'SUTLA',
    'SIMBAHAN',
    'ROSAS',
    'PULA',
  ];

  // Memory Words - Category Hints (Filipino)
  static const List<String> memoryCategoryHints = [
    'bahagi ng katawan',
    'tela',
    'gusali',
    'bulaklak',
    'kulay',
  ];

  // Attention - Digit Sequences
  static const List<int> digitSpanForward = [2, 1, 8, 5, 4];
  static const List<int> digitSpanBackward = [7, 4, 2];

  // Attention - Letter Sequence for Vigilance
  static const String vigilanceLetters = 'FBACMNAAJKLBAFAKDEAAAJAMOFAAB';
  static const String targetLetter = 'A';

  // Serial 7s
  static const int serial7Start = 100;
  static const List<int> serial7Answers = [93, 86, 79, 72, 65];

  // Language - Sentences for Repetition (MoCA-P Filipino)
  static const List<String> repetitionSentences = [
    'Alam ko lang na si Juan ang tutulong sa araw na ito.',
    'Ang pusa ay laging nagtatago sa ilalim ng sopa kapag may mga aso sa kwarto.',
  ];

  // Abstraction Pairs (MoCA-P Filipino)
  static const List<Map<String, dynamic>> abstractionPairs = [
    {
      'item1': 'tren',
      'item2': 'bisikleta',
      'acceptedAnswers': [
        'sasakyan',
        'transportasyon',
        'paraan ng pagbiyahe',
        'pampasahero',
        'transportation',
        'vehicles',
      ],
    },
    {
      'item1': 'relo',
      'item2': 'ruler',
      'acceptedAnswers': [
        'panukat',
        'pansukat',
        'gamit sa pagsukat',
        'measuring',
        'measurement',
        'measuring instruments',
      ],
    },
  ];

  // Abstraction Example (Filipino)
  static const String abstractionExampleItem1 = 'saging';
  static const String abstractionExampleItem2 = 'kahel';
  static const String abstractionExampleAnswer = 'prutas';

  // Naming Animals (Filipino names + English)
  static const List<Map<String, String>> namingAnimalsFilipino = [
    {'filipino': 'Leon', 'english': 'Lion', 'description': 'Malaking pusa na may buhok sa leeg'},
    {'filipino': 'Rinoseronte', 'english': 'Rhinoceros', 'description': 'Malaking hayop na may sungay sa ilong'},
    {'filipino': 'Kamelyo', 'english': 'Camel', 'description': 'Hayop sa disyerto na may umbok sa likod'},
  ];

  // Fluency Test (MoCA-P uses letter "P" for Filipino)
  static const String fluencyLetter = 'P';
  static const int fluencyDurationSeconds = 60;
  static const int fluencyMinimumWords = 11;

  // Storage Keys
  static const String assessmentBoxKey = 'moca_assessment_box';
}
