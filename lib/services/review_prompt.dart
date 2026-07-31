import 'dart:io';

import 'package:flutter/material.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../components/snackbar.dart';
import '../l10n/app_localizations.dart';
import '../utils/theme.dart';

class ReviewPromptService {
  static const String _keyFirstLaunch = 'first_launch_date_ms';
  static const String _keyHasPrompted = 'has_prompted_review_v1';

  /// Checks if 3 days (48+ hours) have passed since first launch and prompts once per lifetime.
  static Future<void> checkAndPrompt(BuildContext context) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Check first launch timestamp
      int? firstLaunchMs = prefs.getInt(_keyFirstLaunch);
      if (firstLaunchMs == null) {
        // Record first launch date
        await prefs.setInt(
          _keyFirstLaunch,
          DateTime.now().millisecondsSinceEpoch,
        );
        return;
      }

      // Check if already prompted once in app lifetime
      final bool hasPrompted = prefs.getBool(_keyHasPrompted) ?? false;
      if (hasPrompted) return;

      // Calculate days difference (2 days difference = 3rd calendar day / 48h+)
      final firstLaunchDate = DateTime.fromMillisecondsSinceEpoch(
        firstLaunchMs,
      );
      final daysPassed = DateTime.now().difference(firstLaunchDate).inDays;

      if (daysPassed >= 2) {
        // Mark as prompted immediately so it never shows again
        await prefs.setBool(_keyHasPrompted, true);

        if (!context.mounted) return;
        showStarReviewBottomSheet(context);
      }
    } catch (e) {
      debugPrint('⚠️ ReviewPromptService error: $e');
    }
  }

  /// Displays the interactive Star Review bottom sheet using in_app_review pub package.
  static void showStarReviewBottomSheet(BuildContext context) {
    int selectedStars = 5;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.card,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        side: BorderSide(color: AppTheme.cardBorder, width: 1),
      ),
      builder: (ctx) {
        final l10n = AppLocalizations.of(ctx);

        return StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 16,
                bottom: MediaQuery.of(ctx).padding.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Top Drag Handle
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppTheme.white20,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Header Badge Icon
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: AppTheme.accent.withAlpha(40),
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.star_rounded,
                        size: 42,
                        color: AppTheme.accent,
                      ),
                    ),
                  ),

                  const SizedBox(height: 18),

                  // Title
                  Text(
                    l10n.rateAppTitle,
                    style: AppTheme.text.h2.copyWith(
                      color: AppTheme.textPrimary,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 8),

                  // Description
                  Text(
                    l10n.rateAppDescription,
                    style: AppTheme.text.bodyMuted,
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 24),

                  // 5 Star Rating Row with Animated Scale
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      final starIndex = index + 1;
                      final isSelected = starIndex <= selectedStars;

                      return IconButton(
                        splashRadius: 24,
                        iconSize: 38,
                        icon: AnimatedScale(
                          scale: isSelected ? 1.05 : 0.95,
                          duration: const Duration(milliseconds: 150),
                          child: Icon(
                            isSelected
                                ? Icons.star_rounded
                                : Icons.star_outline_rounded,
                            color: isSelected
                                ? const Color(0xFFFFC107)
                                : AppTheme.white40,
                          ),
                        ),
                        onPressed: () {
                          selectedStars = starIndex;
                          setState(() {});
                        },
                      );
                    }),
                  ),

                  const SizedBox(height: 28),

                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.accent,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: const RoundedRectangleBorder(
                          borderRadius: AppTheme.rounded20,
                        ),
                      ),
                      onPressed: () async {
                        Navigator.pop(ctx);

                        // Trigger official in_app_review package with platform branching
                        try {
                          final InAppReview inAppReview = InAppReview.instance;
                          if (await inAppReview.isAvailable()) {
                            await inAppReview.requestReview();
                          } else if (Platform.isIOS) {
                            await inAppReview.openStoreListing(
                              appStoreId: '6760999984',
                            );
                          } else if (Platform.isAndroid) {
                            await inAppReview.openStoreListing();
                          }
                        } catch (e) {
                          debugPrint('⚠️ InAppReview error: $e');
                        }

                        if (context.mounted) {
                          info(l10n.thankYouForRating, Severity.success);
                        }
                      },
                      child: Text(
                        l10n.submitRating,
                        style: AppTheme.text.label.copyWith(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.white,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Maybe Later Button
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: TextButton.styleFrom(
                      foregroundColor: AppTheme.textMuted,
                    ),
                    child: Text(
                      l10n.maybeLater,
                      style: AppTheme.text.bodyMuted,
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
