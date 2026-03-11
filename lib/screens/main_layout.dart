import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';

class MainLayout extends ConsumerStatefulWidget {
  final Widget child;

  const MainLayout({super.key, required this.child});

  @override
  ConsumerState<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends ConsumerState<MainLayout> {
  int _currentIndex = 0;

  final List<String> _routes = [
    '/',
    '/create-quiz',
    '/my-quizzes',
    '/study',
    '/profile',
  ];

  final List<String> _labels = [
    'Home',
    'Create',
    'My Quizzes',
    'Study',
    'Profile',
  ];

  final List<IconData> _icons = [
    Icons.home_outlined,
    Icons.add_circle_outline,
    Icons.folder_outlined,
    Icons.school_outlined,
    Icons.person_outline,
  ];

  final List<IconData> _selectedIcons = [
    Icons.home,
    Icons.add_circle,
    Icons.folder,
    Icons.school,
    Icons.person,
  ];

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);
    final location = GoRouterState.of(context).matchedLocation;
    
    // Update current index based on route
    for (int i = 0; i < _routes.length; i++) {
      if (location == _routes[i] || 
          (i == 0 && location == '/') ||
          (i == 2 && location.startsWith('/quiz/'))) {
        _currentIndex = i;
        break;
      }
    }

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: Text(
          _labels[_currentIndex],
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          // Profile Icon in Top Right
          GestureDetector(
            onTap: () => context.push('/profile'),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Hero(
                tag: 'profile-avatar',
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Theme.of(context).colorScheme.primary,
                        Theme.of(context).colorScheme.secondary,
                      ],
                    ),
                    shape: BoxShape.circle,
                    image: currentUser?.profileImageUrl != null
                        ? DecorationImage(
                            image: NetworkImage(currentUser!.profileImageUrl!),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: currentUser?.profileImageUrl == null
                      ? Center(
                          child: Text(
                            currentUser?.name.substring(0, 1).toUpperCase() ?? 'U',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        )
                      : null,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: widget.child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(_routes.length, (index) {
                final isSelected = _currentIndex == index;
                return InkWell(
                  onTap: () {
                    if (_currentIndex != index) {
                      context.go(_routes[index]);
                    }
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Theme.of(context).colorScheme.primaryContainer
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isSelected ? _selectedIcons[index] : _icons[index],
                          color: isSelected
                              ? Theme.of(context).colorScheme.primary
                              : Colors.grey.shade500,
                          size: 24,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _labels[index],
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                            color: isSelected
                                ? Theme.of(context).colorScheme.primary
                                : Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}
