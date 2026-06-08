import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'config/supabase_config.dart';
import 'core/theme.dart';
import 'providers/app_provider.dart';

import 'screens/auth/splash_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/auth/pending_screen.dart';

import 'screens/manager/manager_dashboard_screen.dart';
import 'screens/manager/manager_demandes_screen.dart';
import 'screens/manager/manager_devis_screen.dart';
import 'screens/manager/manager_technicians_screen.dart';
import 'screens/manager/manager_missions_screen.dart';
import 'screens/manager/manager_stats_screen.dart';
import 'screens/manager/manager_profil_screen.dart';
import 'screens/manager/manager_company_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await dotenv.load(fileName: '.env');
    await SupabaseConfig.initialize();
  } catch (e) {
    debugPrint('[Entreprise] init error: $e');
  }
  try {
    await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  } catch (_) {}

  runApp(
    ChangeNotifierProvider(
      create: (_) => AppProvider(),
      child: const ElecEntrepriseApp(),
    ),
  );
}

class ElecEntrepriseApp extends StatefulWidget {
  const ElecEntrepriseApp({super.key});
  @override State<ElecEntrepriseApp> createState() => _ElecEntrepriseAppState();
}

class _ElecEntrepriseAppState extends State<ElecEntrepriseApp> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    final app = context.read<AppProvider>();
    _router = GoRouter(
      initialLocation: '/',
      refreshListenable: app,
      redirect: (context, state) {
        final app   = context.read<AppProvider>();
        final loc   = state.matchedLocation;
        if (loc == '/') return null;
        final authRoutes = ['/', '/login', '/register', '/pending'];
        if (!app.isLoggedIn && !authRoutes.contains(loc)) return '/login';
        if (app.isLoggedIn && app.isPending && loc != '/pending') return '/pending';
        if (app.isLoggedIn && app.isActive &&
            (loc == '/login' || loc == '/register' || loc == '/pending')) return '/manager';
        return null;
      },
      routes: [
        GoRoute(path: '/',         builder: (ctx, st) => const SplashScreen()),
        GoRoute(path: '/login',    builder: (ctx, st) => const LoginScreen()),
        GoRoute(path: '/register', builder: (ctx, st) => const RegisterScreen()),
        GoRoute(path: '/pending',  builder: (ctx, st) => const PendingScreen()),

        GoRoute(path: '/manager',  builder: (ctx, st) => const ManagerDashboardScreen()),
        GoRoute(path: '/manager/demandes', builder: (ctx, st) => const ManagerDemandesScreen()),
        GoRoute(
          path: '/manager/demandes/:id',
          builder: (ctx, state) {
            final id     = state.pathParameters['id']!;
            final demande = ctx.read<AppProvider>().demandes
                .where((d) => d['id'] == id).firstOrNull;
            return ManagerDevisScreen(demandeId: id, demande: demande);
          },
        ),
        GoRoute(path: '/manager/missions',    builder: (ctx, st) => const ManagerMissionsScreen()),
        GoRoute(path: '/manager/technicians', builder: (ctx, st) => const ManagerTechniciansScreen()),
        GoRoute(path: '/manager/stats',       builder: (ctx, st) => const ManagerStatsScreen()),
        GoRoute(path: '/manager/profil',      builder: (ctx, st) => const ManagerProfilScreen()),
        GoRoute(path: '/manager/company',     builder: (ctx, st) => const ManagerCompanyScreen()),
      ],
    );
  }

  @override
  void dispose() { _router.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => AnnotatedRegion<SystemUiOverlayStyle>(
    value: const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
    child: MaterialApp.router(
      title: 'Elecapp Entreprise',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: _router,
    ),
  );
}
