import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../components/generalcards.dart';
import '../../components/snackbar.dart';
import '../../l10n/app_localizations.dart';
import '../../services/systemconfig.dart';
import '../../shared/constants.dart';
import '../../utils/theme.dart';

class AboutPage extends ConsumerStatefulWidget {
  const AboutPage({super.key});

  @override
  ConsumerState<AboutPage> createState() => _AboutPageState();
}

class _AboutPageState extends ConsumerState<AboutPage> {
  late ScrollController _scrollController;
  bool _isTitleCollapsed = false;
  bool _showUpdateAvailable = true;

  @override
  void initState() {
    super.initState();

    _scrollController = ScrollController()
      ..addListener(() {
        final offset = _scrollController.offset;
        if (offset > 120 && !_isTitleCollapsed) {
          setState(() => _isTitleCollapsed = true);
        } else if (offset <= 120 && _isTitleCollapsed) {
          setState(() => _isTitleCollapsed = false);
        }
      });

    _loadPackageInfo();
    checkForUpdate();
    if (mounted) setState(() {});
  }

  Future<void> _loadPackageInfo() async {
    final info = await PackageInfo.fromPlatform();
    setState(() => packageInfo = info);
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: getDominantDarker(AppTheme.accent),
                letterSpacing: 1,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  SliverToBoxAdapter _buildCreditsSection() {
    return SliverToBoxAdapter(
      child: Column(
        children: [
          // const SizedBox(height: 20),
          // Divider(color: Colors.grey.shade800),
          const SizedBox(height: 40),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context).credits,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 16),

                // HiveMinds
                _buildLegacyCreditRow(
                  iconAsset: 'assets/icons/case.png',
                  title: 'HiveMinds',
                  subtitle: 'thehiveminds.in',
                  url: 'https://thehiveminds.in',
                ),

                // Mail
                _buildLegacyCreditRow(
                  iconData: Icons.mail_outline,
                  title: AppLocalizations.of(context).contactUs,
                  subtitle: 'info@thehiveminds.in',
                  url: 'mailto:info@thehiveminds.in',
                ),

                // Hivefy
                _buildLegacyCreditRow(
                  iconAsset: 'assets/icons/github.png',
                  title: 'Hivefy',
                  subtitle: AppLocalizations.of(context).sourceCode,
                  url: 'https://github.com/Harish-Srinivas-07/hivefy',
                ),

                const SizedBox(height: 40),

                // Legal text
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        style: TextStyle(
                          color: Colors.white54,
                          fontSize: 12,
                          height: 1.5,
                        ),
                        children: [
                          TextSpan(
                            text:
                                "${AppLocalizations.of(context).byUsingAppAgreeTo} ",
                            style: AppTheme.text.body,
                          ),
                          WidgetSpan(
                            alignment: PlaceholderAlignment.baseline,
                            baseline: TextBaseline.alphabetic,
                            child: GestureDetector(
                              onTap: () async {
                                final uri = Uri.parse(
                                  'https://doinuadmin.vercel.app/terms',
                                );
                                try {
                                  await launchUrl(
                                    uri,
                                    mode: LaunchMode.externalApplication,
                                  );
                                } catch (e) {
                                  debugPrint('--> URL launch failed: $e');
                                  if (await canLaunchUrl(uri)) {
                                    await launchUrl(
                                      uri,
                                      mode: LaunchMode.inAppWebView,
                                    );
                                  } else {
                                    info(
                                      'Oops! Something went wrong, please visit https://doinuadmin.vercel.app/terms',
                                      Severity.error,
                                    );
                                  }
                                }
                              },
                              child: Text(
                                AppLocalizations.of(context).termsConditions,
                                style: TextStyle(
                                  color: AppTheme.accent,
                                  fontWeight: FontWeight.w600,
                                  decoration: TextDecoration.underline,
                                  // fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                          TextSpan(
                            text: " ${AppLocalizations.of(context).and} ",
                            style: AppTheme.text.body,
                          ),
                          WidgetSpan(
                            alignment: PlaceholderAlignment.baseline,
                            baseline: TextBaseline.alphabetic,
                            child: GestureDetector(
                              onTap: () async {
                                final uri = Uri.parse(
                                  'https://doinuadmin.vercel.app/privacy',
                                );
                                try {
                                  await launchUrl(
                                    uri,
                                    mode: LaunchMode.externalApplication,
                                  );
                                } catch (e) {
                                  debugPrint('--> URL launch failed: $e');
                                  if (await canLaunchUrl(uri)) {
                                    await launchUrl(
                                      uri,
                                      mode: LaunchMode.inAppWebView,
                                    );
                                  } else {
                                    info(
                                      'Oops! Something went wrong, please visit https://doinuadmin.vercel.app/privacy',
                                      Severity.error,
                                    );
                                  }
                                }
                              },
                              child: Text(
                                AppLocalizations.of(context).privacyPolicy,
                                style: TextStyle(
                                  color: AppTheme.accent,
                                  fontWeight: FontWeight.w600,
                                  decoration: TextDecoration.underline,
                                  // fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                          const TextSpan(text: "."),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Center(
                  child: Text(
                    AppLocalizations.of(context).visitOurWebsite,
                    style: const TextStyle(
                      color: Colors.white24,
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegacyCreditRow({
    String? iconAsset,
    IconData? iconData,
    required String title,
    required String subtitle,
    required String url,
  }) {
    return GestureDetector(
      onTap: () async {
        final uri = Uri.parse(url);
        try {
          if (url.startsWith('mailto:')) {
            await launchUrl(uri);
            return;
          }
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } catch (e) {
          debugPrint('--> URL launch failed: $e');
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.inAppWebView);
          }
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            if (iconAsset != null)
              Image.asset(iconAsset, height: 28, width: 28, color: Colors.white)
            else
              Icon(iconData, size: 28, color: Colors.white),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(color: Colors.white54, fontSize: 13),
                  ),
                ],
              ),
            ),
            const Icon(Icons.open_in_new, color: Colors.white38, size: 18),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          // --- Collapsible Sliver AppBar ---
          SliverAppBar(
            pinned: true,
            expandedHeight: 160,
            backgroundColor: getDominantDarker(AppTheme.accent),
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
                    left: _isTitleCollapsed ? 72 : 16,
                    bottom: 16,
                    right: 16,
                  ),
                  title: AnimatedOpacity(
                    duration: const Duration(milliseconds: 200),
                    opacity: _isTitleCollapsed ? 1.0 : 0.0,
                    child: Text(
                      l10n.about,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 22,
                      ),
                    ),
                  ),
                  background: Container(
                    color: AppTheme.bg,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 16, bottom: 32),
                      child: Align(
                        alignment: Alignment.bottomLeft,
                        child: Opacity(
                          opacity: collapsePercent,
                          child: Text(
                            l10n.about,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 28,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                // --- App Name & Label ---
                Center(
                  child: Column(
                    children: [
                      Text(
                        packageInfo.appName,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        l10n.appInfo,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: getDominantDarker(AppTheme.accent),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                _infoRow(
                  l10n.version,
                  'v${packageInfo.version} • Build ${packageInfo.buildNumber}',
                ),
                _infoRow(l10n.packageName, packageInfo.packageName),
                _infoRow(
                  l10n.signature,
                  packageInfo.buildSignature.isNotEmpty
                      ? packageInfo.buildSignature
                      : 'N/A',
                ),
                _infoRow(
                  l10n.installer,
                  packageInfo.installerStore ?? 'Unknown',
                ),
                const SizedBox(height: 20),
                if (isAppUpdateAvailable && _showUpdateAvailable) ...[
                  const SizedBox(height: 20),
                  GeneralCards(
                    iconPath: 'assets/icons/alert.png',
                    title: l10n.updateAvailable,
                    content: l10n.updateMessage,
                    downloadUrl:
                        'https://play.google.com/store/apps/details?id=com.hiveminds.doinu',
                    onClose: () {
                      _showUpdateAvailable = false;
                      setState(() {});
                    },
                  ),
                ],
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: GestureDetector(
                    onTap: () async {
                      final uri = Uri.parse(
                        'https://play.google.com/store/apps/details?id=com.hiveminds.doinu',
                      );
                      try {
                        // Try external application first
                        await launchUrl(
                          uri,
                          mode: LaunchMode.externalApplication,
                        );
                      } catch (e) {
                        debugPrint('--> URL launch failed: $e');
                        // Fallback to in-app browser if external fails
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(uri, mode: LaunchMode.inAppWebView);
                        } else {
                          info(
                            'Cannot open link: https://play.google.com/store/apps/details?id=com.hiveminds.doinu',
                            Severity.error,
                          );
                        }
                      }
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black87,
                        borderRadius: BorderRadius.circular(40),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                      child: Row(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.orange.withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                            ),
                            padding: const EdgeInsets.all(8),
                            child: const Icon(
                              Icons.reviews,
                              color: Colors.orange,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: RichText(
                              text: TextSpan(
                                text: l10n.reviewOnPlayStore,
                                style: GoogleFonts.figtree(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 14,
                                ),
                                children: [
                                  TextSpan(
                                    text: l10n.playStore,
                                    style: GoogleFonts.figtree(
                                      color: AppTheme.accent,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(right: 10),
                            child: const Icon(
                              Icons.open_in_new,
                              color: Colors.white38,
                              size: 18,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Divider(color: Colors.grey.shade800),

                // const SizedBox(height: 20),
              ],
            ),
          ),

          // _buildDonationSection(),//ios Remove
          _buildCreditsSection(),
        ],
      ),
    );
  }

  //   SliverToBoxAdapter _buildDonationSection() {
  //     return SliverToBoxAdapter(
  //       child: Padding(
  //         padding: const EdgeInsets.symmetric(vertical: 8),
  //         child: Container(
  //           decoration: BoxDecoration(
  //             gradient: LinearGradient(
  //               colors: [AppTheme.card, AppTheme.card.withValues(alpha: 0.8)],
  //               begin: Alignment.topLeft,
  //               end: Alignment.bottomRight,
  //             ),
  //             borderRadius: BorderRadius.zero,
  //             border: Border(
  //               top: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
  //               bottom: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
  //             ),
  //             boxShadow: [
  //               BoxShadow(
  //                 color: Colors.black.withValues(alpha: 0.2),
  //                 blurRadius: 10,
  //                 offset: const Offset(0, 4),
  //               ),
  //             ],
  //           ),
  //           child: Stack(
  //             children: [
  //               // Decorative background icon
  //               Positioned(
  //                 right: -10,
  //                 top: -10,
  //                 child: Icon(
  //                   Icons.favorite,
  //                   size: 70,
  //                   color: AppTheme.accent.withValues(alpha: 0.05),
  //                 ),
  //               ),

  //               Padding(
  //                 padding: const EdgeInsets.all(16),
  //                 child: Column(
  //                   crossAxisAlignment: CrossAxisAlignment.start,
  //                   children: [
  //                     Row(
  //                       children: [
  //                         Container(
  //                           padding: const EdgeInsets.all(6),
  //                           decoration: BoxDecoration(
  //                             color: AppTheme.accent.withValues(alpha: 0.1),
  //                             shape: BoxShape.circle,
  //                           ),
  //                           child: const Icon(
  //                             Icons.volunteer_activism,
  //                             color: AppTheme.accent,
  //                             size: 16,
  //                           ),
  //                         ),
  //                         const SizedBox(width: 12),
  //                         Text(
  //                           AppLocalizations.of(context).supportDoinu,
  //                           style: const TextStyle(
  //                             color: Colors.white,
  //                             fontSize: 15,
  //                             fontWeight: FontWeight.bold,
  //                             letterSpacing: 0.5,
  //                           ),
  //                         ),
  //                       ],
  //                     ),
  //                     const SizedBox(height: 8),
  //                     Text(
  //                       AppLocalizations.of(context).supportMessage,
  //                       style: const TextStyle(
  //                         color: Colors.white70,
  //                         fontSize: 12,
  //                         height: 1.4,
  //                       ),
  //                     ),
  //                     const SizedBox(height: 12),
  //                     SizedBox(
  //                       width: double.infinity,
  //                       child: Container(
  //                         decoration: BoxDecoration(
  //                           borderRadius: BorderRadius.circular(12),
  //                           gradient: const LinearGradient(
  //                             colors: [AppTheme.accent, AppTheme.accentDark],
  //                             begin: Alignment.topLeft,
  //                             end: Alignment.bottomRight,
  //                           ),
  //                           boxShadow: [
  //                             BoxShadow(
  //                               color: AppTheme.accent.withValues(alpha: 0.4),
  //                               blurRadius: 8,
  //                               offset: const Offset(0, 2),
  //                             ),
  //                           ],
  //                         ),
  //                         child: ElevatedButton.icon(
  //                           onPressed: () async {
  //                             final Uri url = Uri.parse(Env.donation);
  //                             if (!await launchUrl(
  //                               url,
  //                               mode: LaunchMode.externalApplication,
  //                             )) {
  //                               debugPrint('Could not launch $url');
  //                             }
  //                           },
  //                           style: ElevatedButton.styleFrom(
  //                             backgroundColor: Colors.transparent,
  //                             shadowColor: Colors.transparent,
  //                             foregroundColor: Colors.white,
  //                             padding: const EdgeInsets.symmetric(vertical: 8),
  //                             shape: RoundedRectangleBorder(
  //                               borderRadius: BorderRadius.circular(12),
  //                             ),
  //                           ),
  //                           icon: const Icon(Icons.paypal, size: 18),
  //                           label: Text(
  //                             AppLocalizations.of(context).donatePayPal,
  //                             style: const TextStyle(
  //                               fontSize: 13,
  //                               fontWeight: FontWeight.w700,
  //                               letterSpacing: 0.5,
  //                             ),
  //                           ),
  //                         ),
  //                       ),
  //                     ),
  //                   ],
  //                 ),
  //               ),
  //             ],
  //           ),
  //         ),
  //       ),
  //     );
  //   }
}
