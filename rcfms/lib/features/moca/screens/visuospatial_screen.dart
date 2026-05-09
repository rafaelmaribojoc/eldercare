import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../bloc/moca_assessment_bloc.dart';
import '../constants/moca_colors.dart';
import '../widgets/drawing_canvas.dart';
import '../widgets/section_header.dart';

class VisuospatialScreen extends StatefulWidget {
  const VisuospatialScreen({super.key});

  @override
  State<VisuospatialScreen> createState() => _VisuospatialScreenState();
}

class _VisuospatialScreenState extends State<VisuospatialScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final GlobalKey<DrawingCanvasState> _trailCanvasKey = GlobalKey();
  final GlobalKey<DrawingCanvasState> _cubeCanvasKey = GlobalKey();
  final GlobalKey<DrawingCanvasState> _clockCanvasKey = GlobalKey();

  int _trailScore = 0;
  int _cubeScore = 0;
  int _clockContourScore = 0;
  int _clockNumbersScore = 0;
  int _clockHandsScore = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  int get totalScore =>
      _trailScore +
      _cubeScore +
      _clockContourScore +
      _clockNumbersScore +
      _clockHandsScore;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          SectionHeader(
            title: 'Visuospatial / Executive',
            subtitle: 'Pagguhit ng linya, pagkopya ng cube, at pagguhit ng orasan',
            currentSection: 1,
            totalSections: 8,
            color: MocaColors.visuospatialColor,
          ),
          TabBar(
            controller: _tabController,
            labelColor: MocaColors.visuospatialColor,
            unselectedLabelColor: MocaColors.textSecondary,
            indicatorColor: MocaColors.visuospatialColor,
            tabs: const [
              Tab(text: 'Trail'),
              Tab(text: 'Cube'),
              Tab(text: 'Clock'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              // Disable swipe to prevent conflicts with drawing canvas
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildTrailMaking(),
                _buildCubeCopy(),
                _buildClockDrawing(),
              ],
            ),
          ),
          _buildBottomBar(),
        ],
      ),
    );
  }

  Widget _buildTrailMaking() {
    return SingleChildScrollView(
      // NeverScrollableScrollPhysics when canvas is touched would need state
      // Instead, we use the drawing canvas gesture handling to claim touches
      physics: const ClampingScrollPhysics(),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Pagsunod ng Linya / Trail Making (1 puntos)',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Gumuhit ng linya na nag-uugnay sa mga numero at letra nang palitan: 1 → A → 2 → B → 3 → C → 4 → D → 5 → E',
          ),
          const SizedBox(height: 20),
          // Drawing canvas handles its own gesture conflicts
          AspectRatio(
            aspectRatio: 1,
            child: DrawingCanvas(
              key: _trailCanvasKey,
              strokeColor: MocaColors.visuospatialColor,
              showGuide: true,
              guideWidget: CustomPaint(painter: _TrailGuidePainter()),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton.icon(
                onPressed: () => _trailCanvasKey.currentState?.clear(),
                icon: const Icon(Icons.clear),
                label: const Text('Clear'),
              ),
              TextButton.icon(
                onPressed: () => _trailCanvasKey.currentState?.undo(),
                icon: const Icon(Icons.undo),
                label: const Text('Undo'),
              ),
            ],
          ),
          const Divider(height: 32),
          const Text(
            'Iskor ang gawaing ito:',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          _buildScoreToggle(
            'Natapos nang tama ang trail (walang mali)',
            _trailScore == 1,
            (value) => setState(() => _trailScore = value ? 1 : 0),
          ),
        ],
      ),
    );
  }

  Widget _buildCubeCopy() {
    return SingleChildScrollView(
      physics: const ClampingScrollPhysics(),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Pagkopya ng Cube (1 puntos)',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text('Kopyahin ang 3D na cube nang tama hangga\'t maaari.'),
          const SizedBox(height: 20),
          // Fixed cube template - square aspect ratio and centered
          Center(
            child: AspectRatio(
              aspectRatio: 1.0, // Perfect square
              child: Container(
                constraints: const BoxConstraints(
                  maxWidth: 200,
                  maxHeight: 200,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: MocaColors.border),
                ),
                child: CustomPaint(
                  painter: _CubeTemplatePainter(),
                  size: Size.infinite,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Iguhit dito:',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          // Drawing canvas handles its own gesture conflicts
          AspectRatio(
            aspectRatio: 1.5,
            child: DrawingCanvas(
              key: _cubeCanvasKey,
              strokeColor: MocaColors.visuospatialColor,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton.icon(
                onPressed: () => _cubeCanvasKey.currentState?.clear(),
                icon: const Icon(Icons.clear),
                label: const Text('Clear'),
              ),
              TextButton.icon(
                onPressed: () => _cubeCanvasKey.currentState?.undo(),
                icon: const Icon(Icons.undo),
                label: const Text('Undo'),
              ),
            ],
          ),
          const Divider(height: 32),
          const Text(
            'Iskor ang gawaing ito:',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          _buildScoreToggle(
            'Naikopya nang tama ang cube (3D, kumpleto ang linya)',
            _cubeScore == 1,
            (value) => setState(() => _cubeScore = value ? 1 : 0),
          ),
        ],
      ),
    );
  }

  Widget _buildClockDrawing() {
    return SingleChildScrollView(
      physics: const ClampingScrollPhysics(),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Pagguhit ng Orasan (3 puntos)',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Gumuhit ng orasan na nagpapakita ng oras na "alas-onse y diyes" (11:10). Isama ang lahat ng numero at kamay ng orasan.',
          ),
          const SizedBox(height: 20),
          // Drawing canvas handles its own gesture conflicts
          AspectRatio(
            aspectRatio: 1,
            child: DrawingCanvas(
              key: _clockCanvasKey,
              strokeColor: MocaColors.visuospatialColor,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton.icon(
                onPressed: () => _clockCanvasKey.currentState?.clear(),
                icon: const Icon(Icons.clear),
                label: const Text('Clear'),
              ),
              TextButton.icon(
                onPressed: () => _clockCanvasKey.currentState?.undo(),
                icon: const Icon(Icons.undo),
                label: const Text('Undo'),
              ),
            ],
          ),
          const Divider(height: 32),
          const Text(
            'Iskor ang bawat bahagi (1 puntos bawat isa):',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          _buildScoreToggle(
            'Hugis: May bilog na orasan',
            _clockContourScore == 1,
            (value) => setState(() => _clockContourScore = value ? 1 : 0),
          ),
          _buildScoreToggle(
            'Numero: Lahat ng 12 numero ay nasa tamang posisyon',
            _clockNumbersScore == 1,
            (value) => setState(() => _clockNumbersScore = value ? 1 : 0),
          ),
          _buildScoreToggle(
            'Kamay: Ang oras at minutong kamay ay nasa tamang oras',
            _clockHandsScore == 1,
            (value) => setState(() => _clockHandsScore = value ? 1 : 0),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreToggle(String label, bool value, Function(bool) onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: value ? MocaColors.successLight : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => onChanged(!value),
          borderRadius: BorderRadius.circular(8),
          splashColor: (value ? MocaColors.success : MocaColors.primary)
              .withOpacity(0.1),
          highlightColor: (value ? MocaColors.success : MocaColors.primary)
              .withOpacity(0.05),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: value ? MocaColors.success : MocaColors.border,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  value ? Icons.check_circle : Icons.circle_outlined,
                  color: value ? MocaColors.success : MocaColors.textSecondary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      color:
                          value ? MocaColors.success : MocaColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 400;

    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 12 : 20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child:
            isSmallScreen ? _buildCompactBottomBar() : _buildNormalBottomBar(),
      ),
    );
  }

  Widget _buildNormalBottomBar() {
    return Row(
      children: [
        Flexible(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: MocaColors.visuospatialColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              'Score: $totalScore/5',
              style: TextStyle(
                fontFamily: MocaColors.fontFamily,
                fontWeight: FontWeight.bold,
                color: MocaColors.visuospatialColor,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        OutlinedButton(
          onPressed: _onBack,
          child: Text(
            'Back',
            style: TextStyle(fontFamily: MocaColors.fontFamily),
          ),
        ),
        const SizedBox(width: 8),
        ElevatedButton(
          onPressed: _onContinue,
          style: ElevatedButton.styleFrom(
            backgroundColor: MocaColors.visuospatialColor,
            foregroundColor: Colors.white,
          ),
          child: Text(
            'Continue',
            style: TextStyle(fontFamily: MocaColors.fontFamily),
          ),
        ),
      ],
    );
  }

  Widget _buildCompactBottomBar() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: MocaColors.visuospatialColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            'Score: $totalScore/5',
            style: TextStyle(
              fontFamily: MocaColors.fontFamily,
              fontWeight: FontWeight.bold,
              color: MocaColors.visuospatialColor,
              fontSize: 13,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _onBack,
                child: Text(
                  'Back',
                  style: TextStyle(
                    fontFamily: MocaColors.fontFamily,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton(
                onPressed: _onContinue,
                style: ElevatedButton.styleFrom(
                  backgroundColor: MocaColors.visuospatialColor,
                  foregroundColor: Colors.white,
                ),
                child: Text(
                  'Continue',
                  style: TextStyle(
                    fontFamily: MocaColors.fontFamily,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _onContinue() async {
    // If section has tabs, Continue advances through tabs first.
    if (_tabController.index < _tabController.length - 1) {
      _tabController.animateTo(_tabController.index + 1);
      return;
    }

    if (totalScore == 0) {
      final shouldContinue = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Confirm Continue'),
          content: const Text(
            'The score for this section is 0. Are you sure you want to continue?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Continue'),
            ),
          ],
        ),
      );

      if (shouldContinue != true || !mounted) return;
    }

    context.read<MocaAssessmentBloc>().add(
          MocaSaveSectionResult(
            section: 'visuospatial',
            score: totalScore,
            maxScore: 5,
            details: {
              'trail': _trailScore,
              'cube': _cubeScore,
              'clock_contour': _clockContourScore,
              'clock_numbers': _clockNumbersScore,
              'clock_hands': _clockHandsScore,
            },
          ),
        );
    context.read<MocaAssessmentBloc>().add(MocaNextSection());
    context.go('/moca/naming');
  }

  void _onBack() {
    // If section has tabs, Back goes to the previous tab first.
    if (_tabController.index > 0) {
      _tabController.animateTo(_tabController.index - 1);
      return;
    }

    // First MoCA section: return to where the assessment started.
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/dashboard');
    }
  }
}

/// Official MoCA-P Trail Making Test Pattern
/// Numbers (1-5) and Letters (A-E) in alternating sequence
/// Based on Montreal Cognitive Assessment - Philippine Version
class _TrailGuidePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Circle fill paint (solid gray circles)
    final fillPaint = Paint()
      ..color = const Color(0xFF757575)
      ..style = PaintingStyle.fill;

    // Circle border paint
    final borderPaint = Paint()
      ..color = const Color(0xFF424242)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    // Official MoCA-P trail pattern positions (carefully arranged for proper alternation)
    // The pattern should be solvable without crossing lines
    final positions = [
      {'label': '1', 'x': 0.12, 'y': 0.28},
      {'label': 'A', 'x': 0.28, 'y': 0.12},
      {'label': '2', 'x': 0.48, 'y': 0.22},
      {'label': 'B', 'x': 0.72, 'y': 0.10},
      {'label': '3', 'x': 0.88, 'y': 0.32},
      {'label': 'C', 'x': 0.78, 'y': 0.52},
      {'label': '4', 'x': 0.58, 'y': 0.62},
      {'label': 'D', 'x': 0.38, 'y': 0.52},
      {'label': '5', 'x': 0.18, 'y': 0.72},
      {'label': 'E', 'x': 0.35, 'y': 0.88},
    ];

    // Draw "Begin" indicator at position 1
    _drawBeginIndicator(canvas, size, positions[0]);

    // Draw "End" indicator at position E
    _drawEndIndicator(canvas, size, positions.last);

    // Calculate circle radius based on canvas size (proportional)
    final circleRadius = size.width * 0.055;

    for (var pos in positions) {
      final x = size.width * (pos['x'] as double);
      final y = size.height * (pos['y'] as double);
      final center = Offset(x, y);

      // Draw filled circle
      canvas.drawCircle(center, circleRadius, fillPaint);
      // Draw border
      canvas.drawCircle(center, circleRadius, borderPaint);

      // Draw label (white text for contrast)
      textPainter.text = TextSpan(
        text: pos['label'] as String,
        style: TextStyle(
          color: Colors.white,
          fontSize: circleRadius * 0.9,
          fontWeight: FontWeight.bold,
          fontFamily: 'Roboto',
        ),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(x - textPainter.width / 2, y - textPainter.height / 2),
      );
    }
  }

  void _drawBeginIndicator(Canvas canvas, Size size, Map<String, dynamic> pos) {
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
      text: const TextSpan(
        text: 'Simula',
        style: TextStyle(
          color: Color(0xFF757575),
          fontSize: 10,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
    textPainter.layout();
    final x = size.width * (pos['x'] as double);
    final y = size.height * (pos['y'] as double);
    textPainter.paint(
      canvas,
      Offset(x - textPainter.width / 2, y + size.width * 0.07),
    );
  }

  void _drawEndIndicator(Canvas canvas, Size size, Map<String, dynamic> pos) {
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
      text: const TextSpan(
        text: 'Dulo',
        style: TextStyle(
          color: Color(0xFF757575),
          fontSize: 10,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
    textPainter.layout();
    final x = size.width * (pos['x'] as double);
    final y = size.height * (pos['y'] as double);
    textPainter.paint(
      canvas,
      Offset(x - textPainter.width / 2, y + size.width * 0.07),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Official MoCA-P 3D Necker Cube Template
/// A transparent 3D cube showing all 12 edges for accurate copy assessment
class _CubeTemplatePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF424242)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final cx = size.width / 2;
    final cy = size.height / 2;

    // Cube dimensions (proportional to canvas)
    final cubeWidth = size.width * 0.35;
    final cubeHeight = size.height * 0.45;
    final depth = size.width * 0.18;

    // Front face vertices (bottom-left origin)
    final frontBL = Offset(cx - cubeWidth / 2, cy + cubeHeight / 3);
    final frontBR = Offset(cx + cubeWidth / 3, cy + cubeHeight / 3);
    final frontTL = Offset(cx - cubeWidth / 2, cy - cubeHeight / 2.5);
    final frontTR = Offset(cx + cubeWidth / 3, cy - cubeHeight / 2.5);

    // Back face vertices (offset diagonally up-right for 3D perspective)
    final backBL = Offset(frontBL.dx + depth, frontBL.dy - depth * 0.7);
    final backBR = Offset(frontBR.dx + depth, frontBR.dy - depth * 0.7);
    final backTL = Offset(frontTL.dx + depth, frontTL.dy - depth * 0.7);
    final backTR = Offset(frontTR.dx + depth, frontTR.dy - depth * 0.7);

    // Draw all 12 edges of the cube

    // Front face (4 edges)
    canvas.drawLine(frontBL, frontBR, paint);
    canvas.drawLine(frontBR, frontTR, paint);
    canvas.drawLine(frontTR, frontTL, paint);
    canvas.drawLine(frontTL, frontBL, paint);

    // Back face (4 edges)
    canvas.drawLine(backBL, backBR, paint);
    canvas.drawLine(backBR, backTR, paint);
    canvas.drawLine(backTR, backTL, paint);
    canvas.drawLine(backTL, backBL, paint);

    // Connecting edges (4 depth lines)
    canvas.drawLine(frontBL, backBL, paint);
    canvas.drawLine(frontBR, backBR, paint);
    canvas.drawLine(frontTR, backTR, paint);
    canvas.drawLine(frontTL, backTL, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
