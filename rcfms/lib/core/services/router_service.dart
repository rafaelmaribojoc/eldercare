import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../features/auth/bloc/auth_bloc.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/setup_signature_screen.dart';
import '../../features/auth/screens/profile_completion_screen.dart';
import '../../features/dashboard/screens/dashboard_screen.dart';
import '../../features/dashboard/screens/activity_log_screen.dart'; // Add import
import '../../features/residents/screens/residents_list_screen.dart';
import '../../features/residents/screens/resident_detail_screen.dart';
import '../../features/residents/screens/add_resident_screen.dart';
import '../../features/residents/screens/resident_case_files_screen.dart';
import '../../features/residents/screens/case_completeness_screen.dart';
import '../../features/timeline/screens/timeline_screen.dart';
import '../../features/forms/screens/form_list_screen.dart';
import '../../features/forms/screens/form_fill_screen.dart';
import '../../features/forms/screens/form_view_screen.dart';
import '../../features/forms/templates/form_templates.dart';
import '../../features/approvals/screens/approvals_screen.dart';
import '../../features/nfc/screens/nfc_scan_screen.dart';
import '../../features/wards/screens/wards_screen.dart';
import '../../features/wards/screens/ward_detail_screen.dart';
import '../../features/admin/screens/admin_dashboard_screen.dart';
import '../../features/admin/screens/user_management_screen.dart';
import '../../features/admin/screens/ward_management_screen.dart';
import '../../features/admin/screens/audit_logs_screen.dart';
import '../../features/settings/screens/settings_screen.dart';
import '../../features/analytics/screens/analytics_screen.dart';

import '../../features/settings/screens/profile_screen.dart';
import '../../features/settings/screens/appearance_settings_screen.dart';
import '../../features/settings/screens/notification_settings_screen.dart';
import '../../features/settings/screens/help_support_screen.dart';
import '../../core/widgets/shell_scaffold.dart';
import '../../data/models/resident_model.dart';
import '../../data/repositories/resident_repository.dart';
import '../../data/repositories/form_repository.dart';

// MoCA-P Assessment imports
import '../../features/moca/screens/visuospatial_screen.dart';
import '../../features/moca/screens/naming_screen.dart';
import '../../features/moca/screens/memory_screen.dart';
import '../../features/moca/screens/attention_screen.dart';
import '../../features/moca/screens/language_screen.dart';
import '../../features/moca/screens/abstraction_screen.dart';
import '../../features/moca/screens/delayed_recall_screen.dart';
import '../../features/moca/screens/orientation_screen.dart';
import '../../features/moca/screens/assessment_complete_screen.dart';
import '../../features/moca/screens/moca_analytics_screen.dart';

void _log(String message) {
  if (kDebugMode) {
    print('[Router] $message');
  }
}

/// Helper class to convert a Stream into a Listenable for GoRouter
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen(
          (dynamic _) => notifyListeners(),
        );
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

/// Application routing configuration
class RouterService {
  RouterService._();

  static final _rootNavigatorKey = GlobalKey<NavigatorState>();
  static final _shellNavigatorKey = GlobalKey<NavigatorState>();

  // Public route observer for RouteAware widgets
  static final RouteObserver<ModalRoute<void>> routeObserver =
      RouteObserver<ModalRoute<void>>();

  static void _log(String message) {
    if (kDebugMode) {
      print('[RouterService] $message');
    }
  }

  static final GoRouter router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/login',
    debugLogDiagnostics: true,
    observers: [routeObserver],
    refreshListenable: GoRouterRefreshStream(AuthBloc.staticStream),
    redirect: (context, state) {
      final authState = context.read<AuthBloc>().state;
      final isLoggedIn = authState is AuthAuthenticated;
      final isLoggingIn = state.matchedLocation == '/login';
      final isSettingUpSignature = state.matchedLocation == '/setup-signature';

      _log(
          'Redirect check - location: ${state.matchedLocation}, isLoggedIn: $isLoggedIn, authState: ${authState.runtimeType}');

      // Handle loading state - allow current location
      if (authState is AuthLoading || authState is AuthInitial) {
        _log('Auth loading, allowing current location');
        return null;
      }

      // If not logged in (including after logout), redirect to login
      if (!isLoggedIn && !isLoggingIn) {
        _log('Not logged in, redirecting to /login');
        return '/login';
      }

      // If logged in, check profile completion
      if (isLoggedIn) {
        final isProfileCompletionPage =
            state.matchedLocation == '/profile-completion';
        final isSetupSignaturePage =
            state.matchedLocation == '/setup-signature';

        // Force profile completion if not done
        // Allow BOTH profile-completion and setup-signature pages
        if (!authState.user.isProfileComplete &&
            !isProfileCompletionPage &&
            !isSetupSignaturePage) {
          _log('Profile incomplete, redirecting to /profile-completion');
          return '/profile-completion';
        }

        // Redirect away from completion page if already done
        if (authState.user.isProfileComplete && isProfileCompletionPage) {
          _log('Profile complete, redirecting to /dashboard');
          return '/dashboard';
        }

        // If logged in but on login page, redirect to dashboard
        if (isLoggingIn) {
          _log('Logged in at login page, redirecting to /dashboard');
          return '/dashboard';
        }
      }

      // If logged in and setting up signature, allow it
      if (isLoggedIn && isSettingUpSignature) {
        _log('Allowing signature setup');
        return null;
      }

      return null;
    },
    routes: [
      // Auth routes
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/profile-completion',
        name: 'profile-completion',
        builder: (context, state) => const ProfileCompletionScreen(),
      ),
      // Setup Signature moved inside ShellRoute

      // Main app shell
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) =>
            ShellScaffold(state: state, child: child),
        routes: [
          // Dashboard
          GoRoute(
            path: '/dashboard',
            name: 'dashboard',
            pageBuilder: (context, state) => NoTransitionPage(
              child: const DashboardScreen(),
            ),
            routes: [
              GoRoute(
                path: 'activity',
                name: 'activity-log',
                builder: (context, state) => const ActivityLogScreen(),
              ),
            ],
          ),

          // NFC Scan
          GoRoute(
            path: '/scan',
            name: 'scan',
            pageBuilder: (context, state) {
              final mode = state.uri.queryParameters['mode'];
              return NoTransitionPage(
                child: NFCScanScreen(mode: mode),
              );
            },
          ),

          // Residents
          GoRoute(
            path: '/residents',
            name: 'residents',
            pageBuilder: (context, state) {
              final filter = state.uri.queryParameters['filter'];
              final intent = state.uri.queryParameters['intent'];
              return NoTransitionPage(
                child: ResidentsListScreen(
                  initialFilter: filter,
                  intent: intent,
                ),
              );
            },
            routes: [
              GoRoute(
                path: 'add',
                name: 'add-resident',
                builder: (context, state) => const AddResidentScreen(),
              ),
              GoRoute(
                path: ':id',
                name: 'resident-detail',
                builder: (context, state) {
                  final viewMode = state.uri.queryParameters['mode'] == 'view';
                  return ResidentDetailScreen(
                    residentId: state.pathParameters['id']!,
                    isViewMode: viewMode,
                  );
                },
                routes: [
                  GoRoute(
                    path: 'timeline',
                    name: 'resident-timeline',
                    builder: (context, state) => TimelineScreen(
                      residentId: state.pathParameters['id']!,
                    ),
                  ),
                  GoRoute(
                    path: 'edit',
                    name: 'edit-resident',
                    builder: (context, state) {
                      final extra = state.extra;
                      ResidentModel? resident;
                      bool isAdmitting = false;

                      if (extra is ResidentModel) {
                        resident = extra;
                      } else if (extra is Map<String, dynamic>) {
                        resident = extra['resident'] as ResidentModel?;
                        isAdmitting = extra['isAdmitting'] == true;
                      }

                      return AddResidentScreen(
                        resident: resident,
                        isAdmitting: isAdmitting,
                      );
                    },
                  ),
                  GoRoute(
                    path: 'case-files',
                    name: 'resident-case-files',
                    builder: (context, state) {
                      final resident = state.extra as ResidentModel?;
                      return ResidentCaseFilesScreen(
                        residentId: state.pathParameters['id']!,
                        resident: resident,
                      );
                    },
                  ),
                ],
              ),
            ],
          ),

          // Wards
          GoRoute(
            path: '/wards',
            name: 'wards',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: WardsScreen(),
            ),
            routes: [
              GoRoute(
                path: ':wardId',
                name: 'ward-detail',
                builder: (context, state) => WardDetailScreen(
                  wardId: state.pathParameters['wardId']!,
                ),
              ),
            ],
          ),

          // Analytics
          GoRoute(
            path: '/analytics',
            name: 'analytics',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: AnalyticsScreen(),
            ),
          ),

          // Forms
          GoRoute(
            path: '/forms',
            name: 'forms',
            pageBuilder: (context, state) {
              final tab = state.uri.queryParameters['tab'];
              return NoTransitionPage(
                child: FormListScreen(initialTab: tab),
              );
            },
            routes: [
              GoRoute(
                path: 'fill/:templateId',
                name: 'form-fill',
                builder: (context, state) {
                  final templateId = state.pathParameters['templateId']!;
                  final residentId =
                      state.uri.queryParameters['residentId'] ?? '';
                  final residentName =
                      state.uri.queryParameters['residentName'] ??
                          'Unknown Resident';
                  final unit = state.uri.queryParameters['unit'];
                  final formId = state.uri.queryParameters['formId'];

                  // Try to find template by ID first, then by templateType
                  FormTemplate? template =
                      FormTemplatesRegistry.getById(templateId);
                  if (template == null && unit != null) {
                    template = FormTemplatesRegistry.getByTypeAndUnit(
                        templateId, unit);
                  }
                  template ??= FormTemplatesRegistry.getByType(templateId);

                  if (template == null) {
                    return Scaffold(
                      appBar: AppBar(title: const Text('Error')),
                      body: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error_outline,
                                size: 64, color: Colors.red),
                            const SizedBox(height: 16),
                            Text('Template "$templateId" not found'),
                            const SizedBox(height: 8),
                            ElevatedButton(
                              onPressed: () => context.go('/forms'),
                              child: const Text('Go Back'),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  // If formId is provided, this is an edit of existing form (e.g., returned form)
                  if (formId != null && formId.isNotEmpty) {
                    return _FormEditScreen(
                      templateId: templateId,
                      formId: formId,
                    );
                  }

                  // If residentId is provided, fetch resident data for smart defaults
                  if (residentId.isNotEmpty) {
                    return _FormFillScreenWithResidentData(
                      template: template,
                      residentId: residentId,
                      residentName: residentName,
                    );
                  }

                  return FormFillScreen(
                    template: template,
                    residentId: residentId,
                    residentName: residentName,
                  );
                },
              ),
              GoRoute(
                path: 'view/:formId',
                name: 'form-view',
                builder: (context, state) => FormViewScreen(
                  formId: state.pathParameters['formId']!,
                  reviewMode: state.uri.queryParameters['mode'] == 'review',
                ),
              ),
            ],
          ),

          // Approvals (for unit heads)
          GoRoute(
            path: '/approvals',
            name: 'approvals',
            pageBuilder: (context, state) => NoTransitionPage(
              child: const ApprovalsScreen(),
            ),
          ),

          // Settings
          GoRoute(
            path: '/settings',
            name: 'settings',
            pageBuilder: (context, state) => NoTransitionPage(
              child: const SettingsScreen(),
            ),
            routes: [
              GoRoute(
                path: 'profile',
                name: 'profile',
                builder: (context, state) => const ProfileScreen(),
              ),
              GoRoute(
                path: 'notifications',
                name: 'settings-notifications',
                builder: (context, state) => const NotificationSettingsScreen(),
              ),
              GoRoute(
                path: 'appearance',
                name: 'settings-appearance',
                builder: (context, state) => const AppearanceSettingsScreen(),
              ),
              GoRoute(
                path: 'help',
                name: 'settings-help',
                builder: (context, state) => const HelpSupportScreen(),
              ),
            ],
          ),

          // Case Completeness Dashboard
          GoRoute(
            path: '/case-completeness',
            name: 'case-completeness',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: CaseCompletenessScreen(),
            ),
          ),

          // Admin routes
          GoRoute(
            path: '/setup-signature',
            name: 'setup-signature',
            builder: (context, state) => const SetupSignatureScreen(),
          ),
          GoRoute(
            path: '/admin',
            name: 'admin',
            pageBuilder: (context, state) => NoTransitionPage(
              child: const AdminDashboardScreen(),
            ),
            routes: [
              GoRoute(
                path: 'users',
                name: 'user-management',
                builder: (context, state) => const UserManagementScreen(),
              ),
              GoRoute(
                path: 'wards',
                name: 'ward-management',
                builder: (context, state) => const WardManagementScreen(),
              ),
              GoRoute(
                path: 'audit-logs',
                name: 'audit-logs',
                builder: (context, state) => const AuditLogsScreen(),
              ),
            ],
          ),

          // MoCA-P Assessment routes - accessed only via resident selection (NFC or Browse)
        ],
      ),

      GoRoute(
        path: '/moca/analytics',
        name: 'moca-analytics',
        builder: (context, state) => const MocaAnalyticsScreen(),
      ),
      // MoCA-P Assessment routes (flat structure to avoid navigator key conflicts)
      // /moca redirects to dashboard - assessments must start from a resident
      GoRoute(
        path: '/moca',
        name: 'moca',
        redirect: (context, state) => '/dashboard',
      ),
      GoRoute(
        path: '/moca/visuospatial',
        name: 'moca-visuospatial',
        builder: (context, state) => const VisuospatialScreen(),
      ),
      GoRoute(
        path: '/moca/naming',
        name: 'moca-naming',
        builder: (context, state) => const NamingScreen(),
      ),
      GoRoute(
        path: '/moca/memory',
        name: 'moca-memory',
        builder: (context, state) => const MemoryScreen(),
      ),
      GoRoute(
        path: '/moca/attention',
        name: 'moca-attention',
        builder: (context, state) => const AttentionScreen(),
      ),
      GoRoute(
        path: '/moca/language',
        name: 'moca-language',
        builder: (context, state) => const LanguageScreen(),
      ),
      GoRoute(
        path: '/moca/abstraction',
        name: 'moca-abstraction',
        builder: (context, state) => const AbstractionScreen(),
      ),
      GoRoute(
        path: '/moca/delayed-recall',
        name: 'moca-delayed-recall',
        builder: (context, state) => const DelayedRecallScreen(),
      ),
      GoRoute(
        path: '/moca/orientation',
        name: 'moca-orientation',
        builder: (context, state) => const OrientationScreen(),
      ),
      GoRoute(
        path: '/moca/complete',
        name: 'moca-complete',
        builder: (context, state) => const AssessmentCompleteScreen(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Page not found',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              state.matchedLocation,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go('/dashboard'),
              child: const Text('Go to Dashboard'),
            ),
          ],
        ),
      ),
    ),
  );
}

/// Helper widget to fetch resident data and pass it to FormFillScreen
class _FormFillScreenWithResidentData extends StatefulWidget {
  final FormTemplate template;
  final String residentId;
  final String residentName;

  const _FormFillScreenWithResidentData({
    required this.template,
    required this.residentId,
    required this.residentName,
  });

  @override
  State<_FormFillScreenWithResidentData> createState() =>
      _FormFillScreenWithResidentDataState();
}

class _FormFillScreenWithResidentDataState
    extends State<_FormFillScreenWithResidentData> {
  Map<String, dynamic>? _residentData;
  bool _isLoading = true;
  // ignore: unused_field
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchResidentData();
  }

  Future<void> _fetchResidentData() async {
    try {
      final residentRepo = context.read<ResidentRepository>();
      final resident = await residentRepo.getResidentById(widget.residentId);

      if (mounted) {
        setState(() {
          _residentData = {
            'full_name': resident.fullName,
            'fullName': resident.fullName,
            'resident_code': resident.residentCode,
            'residentCode': resident.residentCode,
            'age': resident.age,
            'gender': resident.gender,
            'dateOfBirth': resident.dateOfBirth.toIso8601String(),
            'case_number': resident.caseNumber,
            'caseNumber': resident.caseNumber,
            'nickname': resident.nickname, // Added mapping for nickname
            'admission_date': resident.admissionDate?.toIso8601String(),
            'admissionDate': resident.admissionDate?.toIso8601String(),
            'date_admitted': resident.admissionDate
                ?.toIso8601String(), // Fix for forms expecting date_admitted
            'ward_name': resident.wardName, // Fixed: use wardName, not ID
            'wardName': resident.wardName, // Fixed: use wardName, not ID
            'ward_id':
                resident.currentWardId, // Keep ID for reference if needed
            'room_number': resident.roomNumber,
            'roomNumber': resident.roomNumber,
            'bed_number': resident.bedNumber,
            'bedNumber': resident.bedNumber,
            'primary_diagnosis': resident.primaryDiagnosis,
            'primaryDiagnosis': resident.primaryDiagnosis,
            'emergency_contact_name': resident.emergencyContactName,
            'emergencyContactName': resident.emergencyContactName,
            'emergency_contact_phone': resident.emergencyContactPhone,
            'emergencyContactPhone': resident.emergencyContactPhone,
            'emergency_contact_relation': resident.emergencyContactRelation,
            'emergencyContactRelation': resident.emergencyContactRelation,

            // Expanded Auto-Population Fields
            'place_of_birth': resident.placeOfBirth,
            'placeOfBirth': resident.placeOfBirth,
            'birthplace': resident
                .placeOfBirth, // Added for consistency with Intake Sheet
            'referred_by': resident.referredBy,
            'referredBy': resident.referredBy,
            'referring_party_address': resident.referringPartyAddress,
            'referringPartyAddress': resident.referringPartyAddress,
            'religion': resident.religion,
            'civil_status': resident.civilStatus,
            'civilStatus': resident.civilStatus,
            'educational_attainment': resident.educationalAttainment,
            'educationalAttainment': resident.educationalAttainment,
            'case_category': resident.caseCategory,
            'caseCategory': resident.caseCategory,
            // 'case_number': resident.caseNumber, // Duplicate removed
            // 'caseNumber': resident.caseNumber, // Duplicate removed
            'condition': resident.condition, // Added missing field
            'nature_of_disability': resident.natureOfDisability, // Added
            'natureOfDisability': resident.natureOfDisability,

            // Custodian
            'custodian_name': resident.custodianName,
            'custodianName': resident.custodianName,

            // Address Components
            'street_address': resident.streetAddress,
            'barangay': resident.barangay,
            'city': resident.city,
            'province': resident.province,
            'address': [
              resident.streetAddress,
              resident.barangay,
              resident.city,
              resident.province
            ].where((s) => s != null && s.isNotEmpty).join(', '),

            // Relative Details
            'nearest_relative_name': resident.nearestRelativeName,
            'nearestRelativeName': resident.nearestRelativeName,
            'nearest_relative_address': resident.nearestRelativeAddress,
            'nearestRelativeAddress': resident.nearestRelativeAddress,
            'nearest_relative_contact': resident.nearestRelativeContactNumber,
            'nearestRelativeContact': resident.nearestRelativeContactNumber,
            'nearest_relative_relation':
                resident.nearestRelativeRelation, // Added
            'nearestRelativeRelation': resident.nearestRelativeRelation,

            // Signatories
            'referring_contact_person': resident.referringContactPerson,
            'referring_contact_designation': resident
                .referredBy, // Initial assumption: Agency/Source is the designation/affiliation

            // Family Composition (Crucial for Custodian/Status lookup)
            'family_composition': resident.familyComposition,
            'familyComposition': resident.familyComposition,
          };

          // Add current user info for "Received By" or "Social Worker" fields
          final authState = context.read<AuthBloc>().state;
          if (authState is AuthAuthenticated) {
            _residentData!['current_user_name'] = authState.user.fullName;
            _residentData!['current_user_designation'] =
                authState.user.title ?? 'Social Worker';
            _residentData!['current_user_id'] = authState.user.id;
          }
          // Debug Print
          print(
              '[RouterService] Fetched resident data for ${resident.fullName}');
          print('[RouterService] Place of Birth: ${resident.placeOfBirth}');
          print('[RouterService] Referred By: ${resident.referredBy}');
          print(
              '[RouterService] Data Map keys: ${_residentData?.keys.toList()}');

          _isLoading = false;
        });
      } else {
        // If resident not found, proceed without smart defaults
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      _log('Error fetching resident data: $e');
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text('Loading resident data...'),
            ],
          ),
        ),
      );
    }

    return FormFillScreen(
      template: widget.template,
      residentId: widget.residentId,
      residentName: widget.residentName,
      residentData: _residentData,
    );
  }
}

/// Helper widget to fetch existing form data for editing (e.g., returned forms)
class _FormEditScreen extends StatefulWidget {
  final String templateId;
  final String formId;

  const _FormEditScreen({
    required this.templateId,
    required this.formId,
  });

  @override
  State<_FormEditScreen> createState() => _FormEditScreenState();
}

class _FormEditScreenState extends State<_FormEditScreen> {
  Map<String, dynamic>? _formData;
  String? _residentId;
  String? _residentName;
  FormTemplate? _template;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchFormData();
  }

  Future<void> _fetchFormData() async {
    try {
      final formRepo = context.read<FormRepository>();
      final form = await formRepo.getFormById(widget.formId);

      // Get the correct template based on form's unit
      FormTemplate? template = FormTemplatesRegistry.getByTypeAndUnit(
        form.templateType,
        form.unit,
      );
      template ??= FormTemplatesRegistry.getByType(form.templateType);

      if (mounted) {
        setState(() {
          _formData = form.formData;
          _residentId = form.residentId;
          _residentName = form.residentName ?? 'Unknown Resident';
          _template = template;
          _isLoading = false;
        });
      }
    } catch (e) {
      _log('Error fetching form data for edit: $e');
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Loading Form...')),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Loading form data...'),
            ],
          ),
        ),
      );
    }

    if (_error != null || _template == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(_error != null
                  ? 'Failed to load form: $_error'
                  : 'Template not found'),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () => context.go('/forms'),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      );
    }

    return FormFillScreen(
      template: _template!,
      residentId: _residentId ?? '',
      residentName: _residentName ?? 'Unknown Resident',
      initialData: _formData,
      existingSubmissionId: widget.formId,
      isEditing: true,
    );
  }
}
