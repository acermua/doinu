import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations.dart';
import '../../services/language_provider.dart';
import '../../utils/theme.dart';

class LanguageSelectionPage extends ConsumerStatefulWidget {
  const LanguageSelectionPage({super.key});

  @override
  ConsumerState<LanguageSelectionPage> createState() =>
      _LanguageSelectionPageState();
}

class _LanguageSelectionPageState extends ConsumerState<LanguageSelectionPage> {
  final List<String> availableLanguages = ['en', 'es', 'eu'];
  String? _selectedCode;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    // Initialize with current locale
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final current =
          ref.read(languageProvider).asData?.value ?? const Locale('en');
      setState(() {
        _selectedCode = current.languageCode;
      });
    });
  }

  void _toggleLanguage(String code) {
    if (_loading) return;
    setState(() {
      _selectedCode = code;
    });
  }

  Future<void> _applyLanguages() async {
    if (_selectedCode == null) return;

    setState(() => _loading = true);

    // Simulate a small delay for the "premium feel" or just proceed
    // The snippet had a loading state, we'll keep it briefly
    await Future.delayed(const Duration(milliseconds: 500));

    ref.read(languageProvider.notifier).setLocale(Locale(_selectedCode!));

    if (mounted) {
      setState(() => _loading = false);
      Navigator.pop(context);
    }
  }

  String _getLanguageName(String code) {
    switch (code) {
      case 'en':
        return 'English';
      case 'es':
        return 'Español';
      case 'eu':
        return 'Euskara';
      default:
        return code.toUpperCase();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    // Ensure we have a selection (fallback to provider if initState hasn't run or something)
    final currentLocale =
        _selectedCode ??
        ref.watch(languageProvider).asData?.value.languageCode ??
        'en';

    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              // --- Collapsible AppBar ---
              SliverAppBar(
                pinned: true,
                expandedHeight: 160,
                backgroundColor: AppTheme.bg,
                leading: const BackButton(color: Colors.white),
                flexibleSpace: LayoutBuilder(
                  builder: (context, constraints) {
                    final minHeight = kToolbarHeight;
                    final maxHeight = 160.0;
                    final collapsePercent =
                        ((constraints.maxHeight - minHeight) /
                                (maxHeight - minHeight))
                            .clamp(0.0, 1.0);

                    return FlexibleSpaceBar(
                      centerTitle: false,
                      titlePadding: EdgeInsets.only(
                        left: collapsePercent < 0.5 ? 16 + 40 : 16,
                        bottom: 16,
                        right: 16,
                      ),
                      title: AnimatedOpacity(
                        duration: const Duration(milliseconds: 200),
                        opacity: collapsePercent < 0.5 ? 1.0 : 0.0,
                        child: Text(
                          l10n.language,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                        ),
                      ),
                      background: Padding(
                        padding: const EdgeInsets.only(left: 16, bottom: 32),
                        child: Align(
                          alignment: Alignment.bottomLeft,
                          child: Opacity(
                            opacity: collapsePercent,
                            child: Text(
                              l10n.language,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 28,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              // --- Section Title ---
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.selectPreferredLanguage,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        l10n.selectLanguageDescription,
                        style: const TextStyle(
                          color: Colors.white38,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // --- Choice Chips ---
              SliverPadding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                sliver: SliverToBoxAdapter(
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: availableLanguages.map((code) {
                      final isSelected = currentLocale == code;
                      return ChoiceChip(
                        label: Text(
                          _getLanguageName(code),
                          style: TextStyle(
                            color: isSelected ? AppTheme.accent : Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        selected: isSelected,
                        selectedColor: AppTheme.card,
                        backgroundColor: Colors.grey[900],
                        side: BorderSide(
                          color: isSelected
                              ? AppTheme.accent
                              : Colors.grey.shade800,
                          width: isSelected ? 1 : 0,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        showCheckmark: false,
                        // visualDensity: const VisualDensity(vertical: -2), // Optional compact
                        onSelected: (_) => _toggleLanguage(code),
                      );
                    }).toList(),
                  ),
                ),
              ),

              // --- Set Language Button ---
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 20,
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.accent,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: _loading ? null : _applyLanguages,
                      child: Text(
                        l10n.updateLanguage,
                        style: const TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),

          // --- Loading Overlay with Linear Progress ---
          if (_loading)
            Container(
              color: AppTheme.bg.withAlpha(240),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 200,
                      child: LinearProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppTheme.accent,
                        ),
                        backgroundColor: Colors.white12,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      l10n.updatingLanguage,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      l10n.hangTight,
                      style: const TextStyle(
                        color: Colors.white38,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
