// lib/screens/features/drawer.dart

import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../utils/env.dart';

import '../../l10n/app_localizations.dart';
import '../../shared/constants.dart';
import '../../utils/theme.dart';
import 'about.dart';
import 'language_selection.dart';
import 'profile.dart';
import 'settings.dart';
import 'soundcapsule.dart';

typedef DrawerNavigateCallback = void Function(Widget page);

class SideDrawer extends StatelessWidget {
  final DrawerNavigateCallback? onNavigate;

  const SideDrawer({super.key, this.onNavigate});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: AppTheme.bg,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: FutureBuilder(
                future: loadProfiles(),
                builder: (context, snapshot) {
                  return Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: AppTheme.bg,
                        backgroundImage:
                            (profileFile != null && profileFile!.existsSync())
                            ? FileImage(profileFile!)
                            : const AssetImage('assets/icons/doinu.png')
                                  as ImageProvider,
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            username.isNotEmpty ? username : "Doinu",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.3,
                            ),
                          ),
                          const SizedBox(height: 2),
                          GestureDetector(
                            onTap: () {
                              if (onNavigate != null) {
                                onNavigate!(ProfilePage());
                              } else {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => ProfilePage(),
                                  ),
                                );
                              }
                            },
                            behavior: HitTestBehavior.opaque,
                            child: Text(
                              AppLocalizations.of(context).viewProfile,
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ),

            const SizedBox(height: 16),

            Divider(color: Colors.grey.shade800, height: .7),
            const SizedBox(height: 8),

            // --- Drawer Items ---
            _DrawerItem(
              icon: Icons.bubble_chart_outlined,
              title: AppLocalizations.of(context).timeSpent,
              onTap: () {
                if (onNavigate != null) {
                  onNavigate!(SoundCapsule());
                } else {
                  Navigator.of(
                    context,
                  ).push(MaterialPageRoute(builder: (_) => SoundCapsule()));
                }
              },
            ),
            _DrawerItem(
              icon: Icons.settings_outlined,
              title: AppLocalizations.of(context).settingsStorage,
              onTap: () {
                if (onNavigate != null) {
                  onNavigate!(SettingsPage());
                } else {
                  Navigator.of(
                    context,
                  ).push(MaterialPageRoute(builder: (_) => SettingsPage()));
                }
              },
            ),

            _DrawerItem(
              icon: Icons.language,
              title: AppLocalizations.of(context).language,
              onTap: () {
                if (onNavigate != null) {
                  onNavigate!(const LanguageSelectionPage());
                } else {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const LanguageSelectionPage(),
                    ),
                  );
                }
              },
            ),

            _DrawerItem(
              icon: Icons.info_outline,
              title: AppLocalizations.of(context).about,
              onTap: () {
                if (onNavigate != null) {
                  onNavigate!(AboutPage());
                } else {
                  Navigator.of(
                    context,
                  ).push(MaterialPageRoute(builder: (_) => AboutPage()));
                }
              },
            ),

            const Spacer(),

            if (Platform.isAndroid)
              _buildAndroidSupport(context)
            else
              _buildIOSSupport(context),

            Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 24, left: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "v${packageInfo.version}",
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.5,
                    ),
                  ),
                  if (packageInfo.installTime != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      "${AppLocalizations.of(context).installedOn} ${DateFormat('d MMM, yyyy').format(packageInfo.installTime!)}",
                      style: const TextStyle(
                        color: Colors.white24,
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAndroidSupport(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.card.withValues(alpha: 0.6),
            AppTheme.card.withValues(alpha: 0.3),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
          width: 0.8,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: Stack(
          children: [
            Positioned(
              right: -10,
              top: -10,
              child: Icon(
                Icons.favorite,
                size: 80,
                color: AppTheme.accent.withValues(alpha: 0.03),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        height: 44,
                        width: 44,
                        decoration: BoxDecoration(
                          color: AppTheme.accent.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.volunteer_activism,
                          color: AppTheme.accent,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppLocalizations.of(context).supportDoinu,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.4,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              AppLocalizations.of(context).supportMessage,
                              style: const TextStyle(
                                color: Colors.white60,
                                fontSize: 11,
                                fontWeight: FontWeight.w400,
                              ),
                              maxLines: 5,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        gradient: const LinearGradient(
                          colors: [AppTheme.accent, AppTheme.accentDark],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.accent.withValues(alpha: 0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          final Uri url = Uri.parse(Env.donation);
                          if (!await launchUrl(
                            url,
                            mode: LaunchMode.externalApplication,
                          )) {
                            debugPrint('Could not launch $url');
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                        ),
                        icon: const Icon(Icons.paypal, size: 18),
                        label: Text(
                          AppLocalizations.of(context).donatePayPal,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIOSSupport(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.card.withValues(alpha: 0.6),
            AppTheme.card.withValues(alpha: 0.3),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
          width: 0.8,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: Stack(
          children: [
            Positioned(
              right: -10,
              top: -10,
              child: Icon(
                Icons.language,
                size: 80,
                color: AppTheme.accent.withValues(alpha: 0.03),
              ),
            ),
            InkWell(
              onTap: () async {
                final Uri url = Uri.parse("https://doinu.org");
                if (!await launchUrl(
                  url,
                  mode: LaunchMode.externalApplication,
                )) {
                  debugPrint('Could not launch $url');
                }
              },
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Container(
                      height: 44,
                      width: 44,
                      decoration: BoxDecoration(
                        color: AppTheme.accent.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.public_rounded,
                        color: AppTheme.accent,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Partner with us",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.4,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            "Wanna add songs? Reach out",
                            style: TextStyle(
                              color: Colors.white60,
                              fontSize: 11,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.arrow_forward_rounded,
                        color: Colors.white24,
                        size: 14,
                      ),
                    ),
                    const SizedBox(width: 4),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback? onTap;

  const _DrawerItem({required this.icon, required this.title, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap ?? () {},
      splashColor: Colors.white10,
      highlightColor: Colors.white10,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 16),
              child: Icon(icon, color: Colors.white70, size: 26),
            ),
            const SizedBox(width: 14),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
