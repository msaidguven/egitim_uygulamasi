// lib/screens/home/widgets/home_header.dart

import 'package:egitim_uygulamasi/models/profile_model.dart';
import 'package:egitim_uygulamasi/screens/anasinifi/compare_page.dart';
import 'package:egitim_uygulamasi/screens/anasinifi/number_composition_page.dart';
import 'package:egitim_uygulamasi/screens/deneme/question_test_page.dart';
import 'package:egitim_uygulamasi/screens/login_screen.dart';
import 'package:flutter/material.dart';

class HomeHeader extends StatefulWidget {
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
  State<HomeHeader> createState() => _HomeHeaderState();
}

class _HomeHeaderState extends State<HomeHeader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _floatAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _floatAnim = Tween<double>(
      begin: -1.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLoggedIn = widget.profile != null;
    final avatarUrl = widget.profile?.avatarUrl;
    final fullName = widget.profile?.fullName;
    final initials = fullName != null && fullName.isNotEmpty
        ? fullName.substring(0, 1).toUpperCase()
        : '?';

    return AnimatedBuilder(
      animation: _floatAnim,
      builder: (context, child) {
        final offset = _floatAnim.value;
        return Container(
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top + 12,
            bottom: 22,
          ),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFECF4FF), Color(0xFFE5F0FF), Color(0xFFF0F8FF)],
            ),
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(28),
              bottomRight: Radius.circular(28),
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF2F6FE4).withValues(alpha: 0.14),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                top: -30 + (offset * 2),
                right: -18 + (offset * 1.5),
                child: Container(
                  width: 132,
                  height: 132,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF98C8FF).withValues(alpha: 0.28),
                  ),
                ),
              ),
              Positioned(
                top: 14 - (offset * 2),
                left: -36 + (offset * 1.2),
                child: Container(
                  width: 94,
                  height: 94,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFFFFD9A8).withValues(alpha: 0.25),
                  ),
                ),
              ),
              Positioned(
                bottom: -28 + (offset * 1.8),
                right: 58 - (offset * 1.3),
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFFB7EFD7).withValues(alpha: 0.24),
                  ),
                ),
              ),
              Positioned(
                top: 8 + (offset * 2.2),
                right: 78,
                child: _MascotBadge(offset: offset),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _LogoText(),
                          const SizedBox(height: 10),
                          if (isLoggedIn) ...[
                            Text(
                              'Merhaba, ${fullName ?? 'Kullanıcı'}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Color(0xFF0F172A),
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                height: 1.2,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.65),
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(
                                  color: const Color(0xFFCDE0FF),
                                ),
                              ),
                              child: const Text(
                                'Hedefini tamamla, puanını yükselt',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF2F5FAE),
                                ),
                              ),
                            ),
                          ] else ...[
                            const Text(
                              'Renkli ders kartları, mini testler ve haftalık yol haritası seni bekliyor.',
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF334155),
                                height: 1.35,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    if (widget.isAdmin)
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
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            gradient: const LinearGradient(
                              colors: [Color(0xFF2F6FE4), Color(0xFF38BDF8)],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(
                                  0xFF2F6FE4,
                                ).withValues(alpha: 0.25),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.person_outline_rounded,
                            color: Colors.white,
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
      },
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
          widget.onRoleChanged(value);
        }
      },
      itemBuilder: (context) {
        return <PopupMenuEntry<String?>>[
          ...roles.map((roleData) {
            final isSelected =
                (widget.impersonatedRole ?? 'admin') == roleData['role'];
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

class _MascotBadge extends StatelessWidget {
  final double offset;

  const _MascotBadge({required this.offset});

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: Offset(offset * 1.8, -offset * 1.2),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFFFB649), Color(0xFFFF8A00)],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFF9F1C).withValues(alpha: 0.35),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.75),
                width: 1.6,
              ),
            ),
            child: const Icon(
              Icons.smart_toy_rounded,
              size: 28,
              color: Colors.white,
            ),
          ),
          Positioned(
            top: -6 + (offset * 0.6),
            right: -8,
            child: Icon(
              Icons.auto_awesome_rounded,
              size: 14,
              color: const Color(0xFF2F6FE4).withValues(alpha: 0.9),
            ),
          ),
          Positioned(
            bottom: -6 - (offset * 0.5),
            left: -7,
            child: Icon(
              Icons.star_rounded,
              size: 12,
              color: const Color(0xFF34D399).withValues(alpha: 0.9),
            ),
          ),
        ],
      ),
    );
  }
}

class _LogoText extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2F6FE4), Color(0xFF38BDF8), Color(0xFF34D399)],
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2F6FE4).withValues(alpha: 0.3),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(Icons.auto_stories_rounded, color: Colors.white, size: 18),
          SizedBox(width: 8),
          Text(
            'DersTakip',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.2,
            ),
          ),
          SizedBox(width: 4),
          Text(
            '.net',
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
