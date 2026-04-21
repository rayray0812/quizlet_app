import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hive/hive.dart';
import 'package:recall_app/core/constants/app_constants.dart';
import 'package:recall_app/core/l10n/app_localizations.dart';
import 'package:recall_app/core/theme/app_theme.dart';
import 'package:recall_app/features/onboarding/widgets/onboarding_page.dart';
import 'package:recall_app/providers/study_set_provider.dart';
import 'package:recall_app/services/sample_set_seeder.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  bool _navigating = false;

  Future<void> _completeOnboarding() async {
    if (_navigating) return;
    _navigating = true;

    final settingsBox = Hive.box(AppConstants.hiveSettingsBox);
    final alreadySeeded =
        settingsBox.get(_sampleSeededKey, defaultValue: false) as bool;
    final existing = ref.read(studySetsProvider);

    if (!alreadySeeded && existing.isEmpty) {
      final l10n = AppLocalizations.of(context);
      try {
        await SampleSetSeeder.seed(
          ref.read(studySetsProvider.notifier),
          title: l10n.sampleSetTitle,
          description: l10n.sampleSetDescription,
        );
        await settingsBox.put(_sampleSeededKey, true);
      } catch (e) {
        debugPrint('Sample set seeding failed: $e');
      }
    }

    await settingsBox.put(AppConstants.settingHasSeenOnboarding, true);

    if (!mounted) return;
    context.go('/');
  }

  static const String _sampleSeededKey = 'sample_set_seeded';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final pages = [
      OnboardingPage(
        title: l10n.onboardingWelcome,
        description: l10n.onboardingWelcomeDesc,
        iconColor: AppTheme.indigo,
        customIcon: SizedBox(
          width: 120,
          height: 120,
          child: Image.asset(
            'assets/branding/logo_clean.png',
            fit: BoxFit.contain,
          ),
        ),
      ),
      OnboardingPage(
        icon: Icons.psychology_rounded,
        title: l10n.onboardingFeatures,
        description: l10n.onboardingFeaturesDesc,
        iconColor: AppTheme.purple,
        extra: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _FeatureChip(
              icon: Icons.repeat_rounded,
              label: 'SRS',
              color: AppTheme.purple,
            ),
            _FeatureChip(
              icon: Icons.local_fire_department_rounded,
              label: l10n.dailyChallenge,
              color: AppTheme.orange,
            ),
            _FeatureChip(
              icon: Icons.camera_alt_rounded,
              label: l10n.photoToFlashcard,
              color: AppTheme.cyan,
            ),
          ],
        ),
      ),
      OnboardingPage(
        icon: Icons.rocket_launch_rounded,
        title: l10n.onboardingStart,
        description: l10n.onboardingStartDesc,
        iconColor: AppTheme.green,
      ),
    ];

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: TextButton(
                  onPressed: () {
                    _completeOnboarding();
                  },
                  child: Text(l10n.skip),
                ),
              ),
            ),
            // Pages
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (page) => setState(() => _currentPage = page),
                children: pages,
              ),
            ),
            // Dot indicators
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  pages.length,
                  (index) => AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: _currentPage == index ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _currentPage == index
                          ? AppTheme.indigo
                          : AppTheme.indigo.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
            ),
            // Next / Get Started button
            Padding(
              padding: const EdgeInsets.fromLTRB(40, 0, 40, 32),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    if (_currentPage == pages.length - 1) {
                      _completeOnboarding();
                    } else {
                      _pageController.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.indigo,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    _currentPage == pages.length - 1
                        ? l10n.getStarted
                        : l10n.next,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeatureChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _FeatureChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 6),
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
