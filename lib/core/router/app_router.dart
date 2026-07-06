import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/login_screen.dart';
import '../../features/auth/splash_screen.dart';
import '../../features/lobby/lobby_screen.dart';
import '../../features/match/match_screen.dart';
import '../../features/mission/mission_screen.dart';
import '../../features/profile/profile_screen.dart';
import '../../features/ranking/ranking_screen.dart';
import '../../features/room/room_screen.dart';
import '../../features/settings/settings_screen.dart';
import '../../features/shop/shop_screen.dart';
import '../auth/auth_provider.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authNotifier = ref.watch(authProvider.notifier);

  return GoRouter(
    initialLocation: '/splash',
    redirect: (context, state) {
      final authState = ref.read(authProvider);
      final status = authState.status;
      final location = state.uri.path;

      final isOnAuthScreen =
          location == '/splash' || location == '/login';

      if (status == AuthStatus.unknown) {
        return location == '/splash' ? null : '/splash';
      }

      if (status == AuthStatus.unauthenticated) {
        return location == '/login' ? null : '/login';
      }

      if (status == AuthStatus.authenticated) {
        return isOnAuthScreen ? '/home' : null;
      }

      return null;
    },
    refreshListenable: _AuthStatusListenable(ref, authNotifier),
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => HomeShell(child: child),
        routes: [
          GoRoute(
            path: '/home',
            builder: (context, state) => const LobbyScreen(),
          ),
          GoRoute(
            path: '/profile',
            builder: (context, state) => const ProfileScreen(),
          ),
          GoRoute(
            path: '/shop',
            builder: (context, state) => const ShopScreen(),
          ),
          GoRoute(
            path: '/missions',
            builder: (context, state) => const MissionScreen(),
          ),
          GoRoute(
            path: '/ranking',
            builder: (context, state) => const RankingScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/room/:id',
        builder: (context, state) {
          final roomId = state.pathParameters['id'] ?? '';
          return RoomScreen(roomId: roomId);
        },
      ),
      GoRoute(
        path: '/match',
        builder: (context, state) => const MatchScreen(),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
    ],
  );
});

/// Bridges Riverpod state changes to GoRouter's [Listenable] refresh mechanism.
class _AuthStatusListenable extends ChangeNotifier {
  final Ref _ref;

  _AuthStatusListenable(this._ref, AuthNotifier _) {
    _ref.listen<AuthState>(authProvider, (_, __) => notifyListeners());
  }
}

class HomeShell extends ConsumerStatefulWidget {
  final Widget child;

  const HomeShell({super.key, required this.child});

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  static const _tabs = ['/home', '/profile', '/shop', '/missions', '/ranking'];

  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: widget.child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() => _currentIndex = index);
          context.go(_tabs[index]);
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.sports_esports), label: 'Play'),
          NavigationDestination(icon: Icon(Icons.person), label: 'Profile'),
          NavigationDestination(icon: Icon(Icons.store), label: 'Shop'),
          NavigationDestination(icon: Icon(Icons.assignment), label: 'Missions'),
          NavigationDestination(icon: Icon(Icons.leaderboard), label: 'Ranking'),
        ],
      ),
    );
  }
}
