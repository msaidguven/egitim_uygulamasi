// lib/screens/home/widgets/home_header.dart

import 'package:egitim_uygulamasi/models/profile_model.dart';
import 'package:egitim_uygulamasi/screens/anasinifi/compare_page.dart';
import 'package:egitim_uygulamasi/screens/anasinifi/number_composition_page.dart';
import 'package:egitim_uygulamasi/screens/deneme/question_test_page.dart';
import 'package:egitim_uygulamasi/screens/login_screen.dart';
import 'package:flutter/material.dart';

class HomeHeader extends StatelessWidget {
  final Profile? profile;
  final bool isAdmin;
  final ValueChanged<String?> onRoleChanged;
  final String? impersonatedRole;

  const HomeHeader({
    super.key,
    required this.profile,
    required this.isAdmin,
    required this.onRoleChanged,
    this.impersonatedRole,
  });

  @override
  Widget build(BuildContext context) {
    final isLoggedIn = profile != null;
    final avatarUrl = profile?.avatarUrl;
    final fullName = profile?.fullName;
    final initials = fullName != null && fullName.isNotEmpty
        ? fullName.substring(0, 1).toUpperCase()
        : '?';

    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 16,
        bottom: 24,
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFFFFF), Color(0xFFF2F6FF), Color(0xFFEEF3FF)],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: -22,
            right: -14,
            child: Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF9EC3FF).withValues(alpha: 0.22),
              ),
            ),
          ),
          Positioned(
            bottom: -32,
            left: -10,
            child: Container(
              width: 92,
              height: 92,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFFFDAB5).withValues(alpha: 0.18),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _LogoText(),
                      const SizedBox(height: 6),
                      if (isLoggedIn) ...[
                        SizedBox(
                          width: MediaQuery.of(context).size.width * 0.58,
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              fullName ?? 'Kullanıcı',
                              style: const TextStyle(
                                color: Color(0xFF0F172A),
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                                height: 1.2,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.72),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: const Color(0xFFD8E4FF)),
                          ),
                          child: const Text(
                            'Bugün için hedefini tamamla',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF475569),
                            ),
                          ),
                        ),
                      ] else ...[
                        Text(
                          'Kaldığın yerden devam etmek için giriş yap',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                if (isAdmin)
                  _buildAdminProfileMenu(context, avatarUrl, initials)
                else if (isLoggedIn)
                  _buildUserAvatar(avatarUrl, initials)
                else
                  InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const LoginScreen(),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.white.withValues(alpha: 0.9),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: const Icon(
                        Icons.person_outline_rounded,
                        color: Color(0xFF64748B),
                        size: 24,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdminProfileMenu(
    BuildContext context,
    String? avatarUrl,
    String initials,
  ) {
    final List<Map<String, dynamic>> roles = [
      {'label': 'Admin', 'role': 'admin'},
      {'label': 'Öğrenci', 'role': 'student'},
      {'label': 'Öğretmen', 'role': 'teacher'},
    ];

    return PopupMenuButton<String?>(
      onSelected: (String? value) {
        if (value == 'show_games') {
          _showGameSelectionDialog(context);
        } else if (value == 'question_test_page') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const QuestionTestPage()),
          );
        } else {
          onRoleChanged(value);
        }
      },
      itemBuilder: (context) {
        return <PopupMenuEntry<String?>>[
          ...roles.map((roleData) {
            final isSelected =
                (impersonatedRole ?? 'admin') == roleData['role'];
            return PopupMenuItem<String?>(
              value: roleData['role'],
              child: Row(
                children: [
                  Icon(
                    isSelected ? Icons.check_circle : Icons.circle_outlined,
                    color: isSelected ? const Color(0xFF6366F1) : Colors.grey,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    roleData['label'],
                    style: TextStyle(
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.normal,
                      color: Colors.grey.shade900,
                    ),
                  ),
                ],
              ),
            );
          }),
          const PopupMenuDivider(),
          PopupMenuItem<String?>(
            value: 'show_games',
            child: Row(
              children: [
                Icon(
                  Icons.gamepad_rounded,
                  color: Colors.grey.shade600,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Text(
                  'Anasınıfı Oyunları',
                  style: TextStyle(color: Colors.grey.shade900),
                ),
              ],
            ),
          ),
          const PopupMenuDivider(),
          PopupMenuItem<String?>(
            value: 'question_test_page',
            child: Row(
              children: [
                Icon(
                  Icons.science_outlined,
                  color: Colors.grey.shade600,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Text(
                  'Deneme Sayfası',
                  style: TextStyle(color: Colors.grey.shade900),
                ),
              ],
            ),
          ),
        ];
      },
      child: _buildUserAvatar(avatarUrl, initials),
    );
  }

  Widget _buildUserAvatar(String? avatarUrl, String initials) {
    return Container(
      width: 48,
      height: 48,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: const LinearGradient(
          colors: [Color(0xFF4F46E5), Color(0xFFEC4899)],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Container(
          color: Colors.white,
          child: avatarUrl != null && avatarUrl.isNotEmpty
              ? Image.network(
                  avatarUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return _avatarFallback(initials);
                  },
                )
              : _avatarFallback(initials),
        ),
      ),
    );
  }

  Widget _avatarFallback(String initials) {
    return Center(
      child: Text(
        initials,
        style: const TextStyle(
          color: Color(0xFF0F172A),
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  void _showGameSelectionDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.35,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(top: 16, bottom: 24),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Text(
                  'Anasınıfı Oyunları',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade900,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  children: [
                    _buildGameCard(
                      context: context,
                      title: 'Sayı Karşılaştırma',
                      subtitle: 'Büyük/küçük sayıları öğren',
                      icon: Icons.compare_arrows_rounded,
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ComparePage(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildGameCard(
                      context: context,
                      title: 'Sayı Oluşturma',
                      subtitle: 'Sayıları birleştirmeyi öğren',
                      icon: Icons.polyline_rounded,
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const NumberCompositionPage(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildGameCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFFF5F7FA),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: Colors.grey.shade900,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: Colors.grey.shade400,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LogoText extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (bounds) => const LinearGradient(
        colors: [Color(0xFF4F46E5), Color(0xFF7C3AED), Color(0xFFEC4899)],
      ).createShader(bounds),
      child: RichText(
        text: const TextSpan(
          text: 'Ders Takip',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
          children: [
            TextSpan(
              text: '.net',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
