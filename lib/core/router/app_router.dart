import 'package:go_router/go_router.dart';
import '../../features/splash/splash_screen.dart';
import '../../features/auth/login_screen.dart';
import '../../features/auth/registration_screen.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      name: 'splash',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/login',
      name: 'login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/register',
      name: 'register',
      builder: (context, state) => const RegistrationScreen(),
    ),

    // --- Placeholder routes for screens not yet built ---
    // Uncomment and point to the real screen as each one gets built.

    // GoRoute(
    //   path: '/staff-login',
    //   name: 'staffLogin',
    //   builder: (context, state) => const StaffLoginScreen(),
    // ),
    // GoRoute(
    //   path: '/onboarding',
    //   name: 'onboarding',
    //   builder: (context, state) => const OnboardingScreen(),
    // ),
    // GoRoute(
    //   path: '/governance-dashboard',
    //   name: 'governanceDashboard',
    //   builder: (context, state) => const GovernanceDashboardScreen(),
    // ),
    // GoRoute(
    //   path: '/staff-dashboard',
    //   name: 'staffDashboard',
    //   builder: (context, state) => const StaffHomeDashboardScreen(),
    // ),
    // GoRoute(
    //   path: '/batch-minting',
    //   name: 'batchMinting',
    //   builder: (context, state) => const BatchMintingScreen(),
    // ),
    // GoRoute(
    //   path: '/user-management',
    //   name: 'userManagement',
    //   builder: (context, state) => const UserStakeholderScreen(),
    // ),
    // GoRoute(
    //   path: '/patient-verification',
    //   name: 'patientVerification',
    //   builder: (context, state) => const PatientVerificationScreen(),
    // ),
    // GoRoute(
    //   path: '/validation-success',
    //   name: 'validationSuccess',
    //   builder: (context, state) => const ValidationSuccessScreen(),
    // ),
    // GoRoute(
    //   path: '/counterfeit-catch',
    //   name: 'counterfeitCatch',
    //   builder: (context, state) => const CounterfeitCatchScreen(),
    // ),
    // GoRoute(
    //   path: '/custody-transfer',
    //   name: 'custodyTransfer',
    //   builder: (context, state) => const TransferOfCustodyScreen(),
    // ),
  ],
);