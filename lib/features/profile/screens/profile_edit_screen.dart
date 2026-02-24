import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:recall_app/core/l10n/app_localizations.dart';
import 'package:recall_app/core/theme/app_theme.dart';
import 'package:recall_app/providers/auth_provider.dart';
import 'package:recall_app/providers/profile_provider.dart';

class ProfileEditScreen extends ConsumerStatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  ConsumerState<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends ConsumerState<ProfileEditScreen>
    with SingleTickerProviderStateMixin {
  final _nameController = TextEditingController();
  final _bioController = TextEditingController();
  final _nameFocus = FocusNode();
  final _bioFocus = FocusNode();
  bool _initialized = false;
  bool _saving = false;
  bool _uploading = false;

  late final AnimationController _animController;
  late final Animation<double> _headerSlide;
  late final Animation<double> _nameSlide;
  late final Animation<double> _bioSlide;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fade = CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
    );
    _headerSlide = CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.0, 0.55, curve: Curves.easeOutCubic),
    );
    _nameSlide = CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.12, 0.65, curve: Curves.easeOutCubic),
    );
    _bioSlide = CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.24, 0.75, curve: Curves.easeOutCubic),
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _nameController.dispose();
    _bioController.dispose();
    _nameFocus.dispose();
    _bioFocus.dispose();
    super.dispose();
  }

  void _initFields(UserProfile? profile) {
    if (_initialized || profile == null) return;
    _nameController.text = profile.displayName;
    _bioController.text = profile.bio;
    _initialized = true;
  }

  Future<void> _save() async {
    _nameFocus.unfocus();
    _bioFocus.unfocus();
    if (mounted) setState(() => _saving = true);
    try {
      await ref.read(profileProvider.notifier).saveProfile(
            displayName: _nameController.text.trim(),
            bio: _bioController.text.trim(),
          );
      if (!mounted) return;

      final l10n = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(CupertinoIcons.checkmark_circle_fill,
                  color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Text(l10n.profileSaved),
            ],
          ),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          backgroundColor: AppTheme.green,
          duration: const Duration(seconds: 2),
        ),
      );

      final router = GoRouter.of(context);
      if (router.canPop()) {
        router.pop();
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _pickAvatar() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 80,
    );
    if (picked == null) return;

    setState(() => _uploading = true);
    final bytes = await picked.readAsBytes();
    final ext = picked.path.split('.').last.toLowerCase();
    final fileExt = (ext == 'png' || ext == 'webp') ? ext : 'jpg';

    await ref.read(profileProvider.notifier).uploadAndSetAvatar(bytes, fileExt);
    if (mounted) setState(() => _uploading = false);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final profileAsync = ref.watch(profileProvider);
    final user = ref.watch(currentUserProvider);
    final isGuest = user == null;
    final cs = Theme.of(context).colorScheme;

    profileAsync.whenData(_initFields);
    final profile = profileAsync.valueOrNull;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        title: Text(l10n.editProfile),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: _saving
                  ? const Padding(
                      key: ValueKey('saving'),
                      padding: EdgeInsets.all(12),
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : FilledButton.tonal(
                      key: const ValueKey('save-btn'),
                      onPressed: _save,
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      ),
                      child: Text(l10n.save),
                    ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        children: [
          // -- Avatar header --
          _staggered(
            animation: _headerSlide,
            fade: _fade,
            offset: 24,
            child: _buildAvatarSection(context, profile, isGuest, l10n),
          ),
          const SizedBox(height: 28),

          // -- Name field --
          _staggered(
            animation: _nameSlide,
            fade: _fade,
            offset: 20,
            child: _buildFieldCard(
              context: context,
              icon: CupertinoIcons.person,
              label: l10n.displayName,
              child: TextField(
                controller: _nameController,
                focusNode: _nameFocus,
                maxLength: 30,
                textInputAction: TextInputAction.next,
                onSubmitted: (_) => _bioFocus.requestFocus(),
                decoration: InputDecoration(
                  hintText: l10n.displayNameHint,
                  counterText: '',
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  filled: false,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 10),
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // -- Bio field --
          _staggered(
            animation: _bioSlide,
            fade: _fade,
            offset: 20,
            child: _buildFieldCard(
              context: context,
              icon: CupertinoIcons.text_quote,
              label: l10n.bio,
              child: TextField(
                controller: _bioController,
                focusNode: _bioFocus,
                maxLength: 160,
                maxLines: 4,
                minLines: 2,
                decoration: InputDecoration(
                  hintText: l10n.bioHint,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  filled: false,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 10),
                ),
                buildCounter: (context,
                    {required currentLength, required isFocused, required maxLength}) {
                  return Text(
                    '$currentLength / $maxLength',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant.withValues(alpha: 0.5),
                          fontSize: 11,
                        ),
                  );
                },
              ),
            ),
          ),

          // -- Guest sync note --
          if (isGuest) ...[
            const SizedBox(height: 20),
            _staggered(
              animation: _bioSlide,
              fade: _fade,
              offset: 16,
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.gold.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.gold.withValues(alpha: 0.5)),
                ),
                child: Row(
                  children: [
                    Icon(CupertinoIcons.info_circle,
                        size: 18, color: cs.onSurface.withValues(alpha: 0.6)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        l10n.profileSyncNote,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: cs.onSurface.withValues(alpha: 0.7),
                              height: 1.45,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // -- Avatar section with gradient ring --
  Widget _buildAvatarSection(
    BuildContext context,
    UserProfile? profile,
    bool isGuest,
    AppLocalizations l10n,
  ) {
    final hasAvatar = profile?.avatarUrl.isNotEmpty == true;
    final initials = _initials(profile?.displayName ?? '');

    return Column(
      children: [
        const SizedBox(height: 12),
        Center(
          child: GestureDetector(
            onTap: isGuest ? null : _pickAvatar,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              width: 108,
              height: 108,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: SweepGradient(
                  colors: [
                    AppTheme.indigo.withValues(alpha: 0.5),
                    AppTheme.cyan.withValues(alpha: 0.4),
                    AppTheme.purple.withValues(alpha: 0.4),
                    AppTheme.indigo.withValues(alpha: 0.5),
                  ],
                  transform: const GradientRotation(math.pi / 4),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(3),
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Theme.of(context).colorScheme.surface,
                  ),
                  padding: const EdgeInsets.all(3),
                  child: Stack(
                    children: [
                      // Avatar or initials
                      ClipOval(
                        child: Container(
                          width: 96,
                          height: 96,
                          decoration: BoxDecoration(
                            color: AppTheme.gold.withValues(alpha: 0.35),
                          ),
                          child: hasAvatar
                              ? Image.network(
                                  profile!.avatarUrl,
                                  fit: BoxFit.cover,
                                  width: 96,
                                  height: 96,
                                  errorBuilder: (_, __, ___) =>
                                      _buildInitialsAvatar(context, initials),
                                )
                              : _buildInitialsAvatar(context, initials),
                        ),
                      ),
                      // Upload overlay
                      if (_uploading)
                        ClipOval(
                          child: Container(
                            width: 96,
                            height: 96,
                            color: Colors.black.withValues(alpha: 0.4),
                            child: const Center(
                              child: SizedBox(
                                width: 28,
                                height: 28,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                      // Camera badge
                      if (!isGuest && !_uploading)
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(7),
                            decoration: BoxDecoration(
                              color: AppTheme.indigo,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Theme.of(context).colorScheme.surface,
                                width: 2.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.indigo.withValues(alpha: 0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Icon(
                              CupertinoIcons.camera_fill,
                              size: 14,
                              color: Colors.white,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        if (!isGuest)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: GestureDetector(
              onTap: _pickAvatar,
              child: Text(
                l10n.changeAvatar,
                style: GoogleFonts.notoSansTc(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.indigo.withValues(alpha: 0.8),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildInitialsAvatar(BuildContext context, String initials) {
    return Center(
      child: Text(
        initials,
        style: GoogleFonts.notoSerifTc(
          fontSize: 32,
          fontWeight: FontWeight.w600,
          color: AppTheme.indigo.withValues(alpha: 0.7),
          letterSpacing: 1,
        ),
      ),
    );
  }

  // -- Soft field card wrapper --
  Widget _buildFieldCard({
    required BuildContext context,
    required IconData icon,
    required String label,
    required Widget child,
  }) {
    return Container(
      decoration: AppTheme.softCardDecoration(borderRadius: 16),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: AppTheme.indigo.withValues(alpha: 0.7)),
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.notoSansTc(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.55),
                  letterSpacing: 0.4,
                ),
              ),
            ],
          ),
          child,
        ],
      ),
    );
  }

  // -- Stagger helper --
  Widget _staggered({
    required Animation<double> animation,
    required Animation<double> fade,
    required double offset,
    required Widget child,
  }) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        final t = animation.value;
        return Opacity(
          opacity: fade.value.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, offset * (1 - t)),
            child: child,
          ),
        );
      },
    );
  }

  String _initials(String name) {
    if (name.trim().isEmpty) return '?';
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return parts.first[0].toUpperCase();
  }
}
