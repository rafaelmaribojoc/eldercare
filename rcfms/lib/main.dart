import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;
import 'package:flutter_web_plugins/url_strategy.dart';

import 'core/constants/supabase_config.dart';
import 'core/theme/app_theme.dart';
import 'core/services/router_service.dart';
import 'core/widgets/custom_error_view.dart'; // Import CustomErrorView
import 'features/auth/bloc/auth_bloc.dart';

import 'features/settings/bloc/settings_bloc.dart';
import 'features/settings/bloc/settings_state.dart';
import 'features/moca/moca.dart';
import 'data/repositories/auth_repository.dart';
import 'data/repositories/resident_repository.dart';
import 'data/repositories/form_repository.dart';
import 'core/services/nfc_service.dart';

void main() async {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    usePathUrlStrategy();

    // Set global error widget builder to replace the "Grey Screen of Death"
    ErrorWidget.builder = (FlutterErrorDetails details) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: CustomErrorView(errorDetails: details),
      );
    };

    // Allow all orientations for responsive design
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    // Initialize Supabase
    await Supabase.initialize(
      url: SupabaseConfig.url,
      anonKey: SupabaseConfig.anonKey,
    );

    // Pass all uncaught errors from the framework to the console
    FlutterError.onError = (FlutterErrorDetails details) {
      FlutterError.presentError(details);
      debugPrint('Flutter Error: ${details.exception}');
    };

    runApp(const RCFMSApp());
  }, (error, stack) {
    // Catch any async errors that happen outside of the Flutter framework
    debugPrint('Async Error: $error\n$stack');
  });
}

class RCFMSApp extends StatelessWidget {
  const RCFMSApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider(create: (_) => AuthRepository()),
        RepositoryProvider(create: (_) => ResidentRepository()),
        RepositoryProvider(create: (_) => FormRepository()),
        RepositoryProvider(create: (_) => NfcService()),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (context) => AuthBloc(
              authRepository: context.read<AuthRepository>(),
            )..add(AuthCheckRequested()),
          ),
          BlocProvider(
            create: (context) => MocaAssessmentBloc(),
          ),
          BlocProvider(
            create: (context) => SettingsBloc(),
          ),
        ],
        child: BlocBuilder<AuthBloc, AuthState>(
          builder: (context, authState) {
            return BlocBuilder<SettingsBloc, SettingsState>(
              builder: (context, settingsState) {
                return MaterialApp.router(
                  title: 'RCFMS - Resident Care & Facility Management',
                  debugShowCheckedModeBanner: false,
                  theme: AppTheme.light,
                  darkTheme: AppTheme.dark,
                  themeMode: settingsState.themeMode,
                  routerConfig: RouterService.router,
                );
              },
            );
          },
        ),
      ),
    );
  }
}
