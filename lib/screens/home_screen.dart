// lib/screens/home_screen.dart

import 'package:egitim_uygulamasi/features/test/data/models/test_session.dart';
import 'package:egitim_uygulamasi/features/test/presentation/views/questions_screen.dart';
import 'package:egitim_uygulamasi/models/grade_model.dart';
import 'package:egitim_uygulamasi/utils/date_utils.dart';
import 'package:egitim_uygulamasi/models/profile_model.dart';
import 'package:egitim_uygulamasi/screens/anasinifi/compare_page.dart';
import 'package:egitim_uygulamasi/screens/anasinifi/number_composition_page.dart';
import 'package:egitim_uygulamasi/screens/deneme/question_test_page.dart';
import 'package:egitim_uygulamasi/screens/lessons_screen.dart';
import 'package:egitim_uygulamasi/screens/login_screen.dart';
import 'package:egitim_uygulamasi/screens/outcomes_screen.dart';
import 'package:egitim_uygulamasi/viewmodels/grade_viewmodel.dart';
import 'package:egitim_uygulamasi/widgets/lesson_card.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

enum NextStepsDisplayState { hidden, collapsed, expanded }

class HomeScreen extends StatefulWidget {
  final Function(int) onNavigate;
  final Profile? profile;
  final Future<void> Function() onRefresh;
  final List<Map<String, dynamic>>? agendaData;
  final List<Map<String, dynamic>>? nextStepsData;
  final int currentCurriculumWeek;
  final NextStepsDisplayState nextStepsState;
  final VoidCallback onToggleNextSteps;
  final VoidCallback onExpandNextSteps;
  final String? impersonatedRole;
  final ValueChanged<String?> onRoleChanged;
  final String? currentRole;
  final List<TestSession>? unfinishedSessions;
  final bool isUnfinishedSessionsLoading;

  const HomeScreen({
    super.key,
    required this.onNavigate,
    required this.profile,
    required this.onRefresh,
    this.agendaData,
    this.nextStepsData,
    this.currentCurriculumWeek = 0,
    required this.nextStepsState,
    required this.onToggleNextSteps,
    required this.onExpandNextSteps,
    this.impersonatedRole,
    required this.onRoleChanged,
    this.currentRole,
    this.unfinishedSessions,
    this.isUnfinishedSessionsLoading = false,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GradeViewModel _gradeViewModel = GradeViewModel();

  @override
  void initState() {
    super.initState();
    if (widget.profile == null) {
      _gradeViewModel.addListener(() {
        if (mounted) setState(() {});
      });
      _gradeViewModel.fetchGrades();
    }
  }

  @override
  void dispose() {
    _gradeViewModel.dispose();
    super.dispose();
  }

  void _showGameSelectionDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.4,
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(30),
              topRight: Radius.circular(30),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 30,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                width: 60,
                height: 4,
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Text(
                  'Anasınıfı Oyunları',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  children: [
                    _buildGameCard(
                      context: context,
                      title: 'Sayı Karşılaştırma',
                      subtitle: 'Büyük/küçük sayıları öğren',
                      icon: Icons.compare_arrows_rounded,
                      iconColor: const Color(0xFF6C5CE7),
                      gradient: const LinearGradient(
                        colors: [Color(0xFF6C5CE7), Color(0xFFA29BFE)],
                      ),
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
                    const SizedBox(height: 16),
                    _buildGameCard(
                      context: context,
                      title: 'Sayı Oluşturma',
                      subtitle: 'Sayıları birleştirmeyi öğren',
                      icon: Icons.polyline_rounded,
                      iconColor: const Color(0xFF00B894),
                      gradient: const LinearGradient(
                        colors: [Color(0xFF00B894), Color(0xFF55EFC4)],
                      ),
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
    required Color iconColor,
    required Gradient gradient,
    required VoidCallback onTap,
  }) {
    return Container(
      height: 90,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: gradient,
        boxShadow: [
          BoxShadow(
            color: gradient.colors.first.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          splashColor: Colors.white.withValues(alpha: 0.3),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Icon(icon, color: Colors.white, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.white.withOpacity(0.7),
                  size: 28,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isStudent = widget.currentRole == 'student';
    final bool isAdmin = widget.profile?.role == 'admin';

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).primaryColor.withOpacity(0.1),
              Colors.white,
            ],
          ),
        ),
        child: RefreshIndicator(
          onRefresh: widget.onRefresh,
          color: Theme.of(context).primaryColor,
          backgroundColor: Colors.white,
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            slivers: [
              SliverAppBar(
                pinned: true,
                backgroundColor: Theme.of(context).primaryColor,
                elevation: 0,
                expandedHeight: 120,
                flexibleSpace: FlexibleSpaceBar(
                  background: _buildFixedUserInfo(context, isAdmin),
                ),
              ),
              SliverToBoxAdapter(
                child: _buildScrollableHeaderCards(context, isAdmin),
              ),
              if (widget.profile == null)
                _buildGuestContent(context)
              else if (isStudent)
                _buildStudentContent(context)
              else
                _buildTeacherContent(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFixedUserInfo(BuildContext context, bool isAdmin) {
    final isLoggedIn = widget.profile != null;
    final avatarUrl = widget.profile?.avatarUrl;
    final fullName = widget.profile?.fullName;
    final initials = fullName != null && fullName.isNotEmpty
        ? fullName.substring(0, 1).toUpperCase()
        : '?';

    return Container(
      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).primaryColor,
            Theme.of(context).primaryColor.withOpacity(0.95),
          ],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24.0, 12.0, 24.0, 12.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  isLoggedIn ? 'Hoş geldin 👋' : 'Merhaba!',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.95),
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                    letterSpacing: 0.3,
                  ),
                ),
                if (isLoggedIn) ...[
                  const SizedBox(height: 4),
                  SizedBox(
                    width: MediaQuery.of(context).size.width * 0.5,
                    child: Text(
                      fullName ?? 'Kullanıcı',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                        height: 1.1,
                        letterSpacing: -0.5,
                        overflow: TextOverflow.ellipsis,
                      ),
                      maxLines: 2,
                    ),
                  ),
                ],
              ],
            ),
            if (isAdmin)
              _buildAdminProfileMenu(context, avatarUrl, initials)
            else if (isLoggedIn)
              _buildUserAvatar(avatarUrl, initials)
            else
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  color: Colors.white.withOpacity(0.2),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3),
                    width: 2,
                  ),
                ),
                child: const Center(
                  child: Icon(
                    Icons.person_outline_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildScrollableHeaderCards(BuildContext context, bool isAdmin) {
    final isLoggedIn = widget.profile != null;

    return Container(
      padding: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Theme.of(context).primaryColor.withOpacity(0.85),
            Theme.of(context).primaryColor.withOpacity(0.85),
          ],
        ),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).primaryColor.withOpacity(0.3),
            blurRadius: 25,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hafta gösterge kartı
          if (isLoggedIn)
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.15),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFF6C5CE7),
                            const Color(0xFFA29BFE),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.calendar_month_rounded,
                          color: Colors.white,
                          size: 30,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            getCurrentPeriodInfo().displaySubtitle ??
                                'Eğitim Takvimi',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            getCurrentPeriodInfo().displayTitle,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.menu_book_rounded,
                                      color: Colors.white,
                                      size: 14,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${widget.agendaData?.length ?? 0} ders',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.school_rounded,
                                      color: Colors.white,
                                      size: 14,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      widget.profile?.grade?.name ?? '-',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LoginScreen(),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withOpacity(0.15)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Eğitime Başlayın',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Giriş yaparak kişisel öğrenme yolculuğunuza başlayın',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: 14,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.login_rounded,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          const SizedBox(height: 24),
          if (isLoggedIn)
            Padding(
              padding: const EdgeInsets.only(left: 24.0),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildQuickStat(
                      context: context,
                      icon: Icons.trending_up_rounded,
                      value:
                          '${_calculateAverageSuccess().toStringAsFixed(0)}%',
                      label: 'Ortalama Başarı',
                      color: const Color(0xFF00B894),
                    ),
                    const SizedBox(width: 12),
                    _buildQuickStat(
                      context: context,
                      icon: Icons.access_time_filled_rounded,
                      value: '${_calculateTotalProgress().toStringAsFixed(0)}%',
                      label: 'Tamamlanma',
                      color: const Color(0xFF6C5CE7),
                    ),
                    const SizedBox(width: 12),
                    _buildQuickStat(
                      context: context,
                      icon: Icons.emoji_events_rounded,
                      value: '${_calculateCompletedLessons()}',
                      label: 'Tamamlanan Ders',
                      color: const Color(0xFFFD79A8),
                    ),
                    const SizedBox(width: 24), // Sağdan boşluk için
                  ],
                ),
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
                    color: isSelected
                        ? Theme.of(context).primaryColor
                        : Colors.grey,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    roleData['label'],
                    style: TextStyle(
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
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
              children: const [
                Icon(Icons.gamepad_rounded, color: Colors.grey),
                SizedBox(width: 12),
                Text('Anasınıfı Oyunları'),
              ],
            ),
          ),
          const PopupMenuDivider(),
          PopupMenuItem<String?>(
            value: 'question_test_page',
            child: Row(
              children: const [
                Icon(Icons.science_outlined, color: Colors.grey),
                SizedBox(width: 12),
                Text('Deneme Sayfası'),
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
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white.withOpacity(0.2),
        border: Border.all(color: Colors.white.withOpacity(0.4), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: avatarUrl != null && avatarUrl.isNotEmpty
          ? ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.network(
                avatarUrl,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.3),
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(Colors.white),
                        ),
                      ),
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return Center(
                    child: Text(
                      initials,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  );
                },
              ),
            )
          : Center(
              child: Text(
                initials,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
    );
  }

  Widget _buildQuickStat({
    required BuildContext context,
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(child: Icon(icon, color: Colors.white, size: 20)),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingShimmer() {
    return SliverPadding(
      padding: const EdgeInsets.all(24.0),
      sliver: SliverList(
        delegate: SliverChildListDelegate([
          Shimmer.fromColors(
            baseColor: Colors.grey.shade300,
            highlightColor: Colors.grey.shade100,
            child: Column(
              children: List.generate(
                3,
                (index) => Container(
                  height: 120,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _buildGuestContent(BuildContext context) {
    if (_gradeViewModel.isLoading) {
      return _buildLoadingShimmer();
    }

    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
      sliver: SliverList(
        delegate: SliverChildListDelegate([
          _buildSectionHeader(
            context,
            title: 'Mevcut Sınıflar',
            subtitle: 'Uygulamada sunulan tüm sınıflar',
            icon: Icons.school_rounded,
            iconColor: Theme.of(context).primaryColor,
          ),
          const SizedBox(height: 16),
          if (_gradeViewModel.grades.isEmpty)
            _buildEmptyState(context)
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.0,
              ),
              itemCount: _gradeViewModel.grades.length,
              itemBuilder: (context, index) {
                final grade = _gradeViewModel.grades[index];
                final color = _getGradientColor(index);
                return _buildGradeCard(grade, color, index);
              },
            ),
        ]),
      ),
    );
  }

  Widget _buildStudentContent(BuildContext context) {
    if (widget.agendaData == null) {
      return _buildLoadingShimmer();
    }

    final hasNextSteps =
        widget.nextStepsData != null && widget.nextStepsData!.isNotEmpty;

    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      sliver: SliverList(
        delegate: SliverChildListDelegate([
          if (widget.isUnfinishedSessionsLoading) ...[
            _buildUnfinishedTestsLoading(context),
            const SizedBox(height: 24),
          ] else if (widget.unfinishedSessions != null &&
              widget.unfinishedSessions!.isNotEmpty) ...[
            _buildUnfinishedTests(context, widget.unfinishedSessions!),
            const SizedBox(height: 24),
          ],
          _buildSectionHeader(
            context,
            title: 'Bu Haftanın Dersleri',
            subtitle: 'Tamamlamanız gereken konular',
            icon: Icons.today_rounded,
            iconColor: const Color(0xFF6C5CE7),
          ),
          const SizedBox(height: 16),
          _buildDataView(context, widget.agendaData, _buildAgendaList),
          if (hasNextSteps) ...[
            const SizedBox(height: 32),
            _buildSectionHeader(
              context,
              title: 'Geçmiş Haftalar',
              subtitle: 'Tekrar yapabileceğiniz konular',
              icon: Icons.history_rounded,
              iconColor: const Color(0xFF00B894),
              trailing: IconButton(
                onPressed: widget.onToggleNextSteps,
                icon: Icon(
                  widget.nextStepsState == NextStepsDisplayState.expanded
                      ? Icons.expand_less_rounded
                      : Icons.expand_more_rounded,
                  color: const Color(0xFF00B894),
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (widget.nextStepsState != NextStepsDisplayState.hidden)
              _buildDataView(context, widget.nextStepsData, (ctx, data) {
                final displayData =
                    widget.nextStepsState == NextStepsDisplayState.expanded
                    ? data
                    : data.take(3).toList();
                final bool showMoreButton =
                    widget.nextStepsState == NextStepsDisplayState.collapsed &&
                    data.length > 3;
                return _buildNextStepsList(
                  ctx,
                  displayData,
                  showMoreButton,
                  data.length - 3,
                );
              }),
          ],
          if (widget.agendaData?.isEmpty ?? false) ...[
            const SizedBox(height: 40),
            _buildMotivationCard(context),
          ],
        ]),
      ),
    );
  }

  Widget _buildUnfinishedTestsLoading(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Yarım Kalan Testler',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                'Yükleniyor',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.orange,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 140,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: 3,
            itemBuilder: (context, index) {
              return Shimmer.fromColors(
                baseColor: Colors.grey.shade300,
                highlightColor: Colors.grey.shade100,
                child: Container(
                  width: 200,
                  margin: const EdgeInsets.only(right: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildUnfinishedTests(
    BuildContext context,
    List<TestSession> sessions,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Yarım Kalan Testler',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${sessions.length} test',
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.orange,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 140,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: sessions.length,
            itemBuilder: (context, index) {
              final session = sessions[index];
              return Container(
                width: 200,
                margin: const EdgeInsets.only(right: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                  border: Border.all(color: Colors.orange.withOpacity(0.2)),
                ),
                child: InkWell(
                  onTap: () => _resumeTest(context, session),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            session.lessonName ?? 'Ders',
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context).primaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            session.unitName ?? 'Ünite',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Devam Et',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const Icon(
                            Icons.play_circle_fill_rounded,
                            color: Colors.orange,
                            size: 24,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _resumeTest(BuildContext context, TestSession session) {
    if (session.unitId == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            QuestionsScreen(unitId: session.unitId!, sessionId: session.id),
      ),
    ).then((_) {
      widget.onRefresh();
    });
  }

  Widget _buildTeacherContent(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      sliver: SliverList(
        delegate: SliverChildListDelegate([
          _buildSectionHeader(
            context,
            title: 'Sınıflarım',
            subtitle: 'Yönettiğiniz sınıflar',
            icon: Icons.groups_rounded,
            iconColor: const Color(0xFFFD79A8),
          ),
          const SizedBox(height: 16),
          Column(
            children: [
              _buildClassCard(
                className: '5-A Sınıfı',
                studentCount: 28,
                averageSuccess: 76,
                progressColor: const Color(0xFFFDCB6E),
                onTap: () {},
              ),
              const SizedBox(height: 12),
              _buildClassCard(
                className: '6-B Sınıfı',
                studentCount: 32,
                averageSuccess: 85,
                progressColor: const Color(0xFF74B9FF),
                onTap: () {},
              ),
            ],
          ),
        ]),
      ),
    );
  }

  Widget _buildSectionHeader(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    Widget? trailing,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: iconColor, size: 24),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade800,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            if (trailing != null) trailing,
          ],
        ),
      ],
    );
  }

  Widget _buildClassCard({
    required String className,
    required int studentCount,
    required int averageSuccess,
    required Color progressColor,
    required VoidCallback onTap,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  className,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$studentCount öğrenci',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Genel Başarı',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          Text(
                            '%$averageSuccess',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: progressColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Stack(
                        children: [
                          Container(
                            height: 8,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          Container(
                            height: 8,
                            width: (averageSuccess / 100) * 200,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  progressColor,
                                  progressColor.withOpacity(0.7),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 20),
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: progressColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Icon(
                    Icons.arrow_forward_rounded,
                    color: progressColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataView(
    BuildContext context,
    List<Map<String, dynamic>>? data,
    Widget Function(BuildContext, List<Map<String, dynamic>>) builder,
  ) {
    if (data == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (data.isEmpty) {
      return _buildEmptyState(context);
    }
    return builder(context, data);
  }

  Widget _buildEmptyState(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(Icons.menu_book_rounded, size: 60, color: Colors.grey.shade300),
          const SizedBox(height: 20),
          Text(
            'Henüz ders yok',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Bu hafta için planlanmış ders bulunmuyor.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildAgendaList(
    BuildContext context,
    List<Map<String, dynamic>> data,
  ) {
    return Column(
      children: data.map((item) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: LessonCard(
            lessonId: item['lesson_id'] as int? ?? 0,
            lessonName: item['lesson_name'],
            topicTitle: item['topic_title'] ?? 'Konu Belirtilmemiş',
            progress: (item['progress_percentage'] ?? 0.0).toDouble(),
            successRate: (item['success_rate'] ?? 0.0).toDouble(),
            onTap: () => _navigateToOutcomes(context, item),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildNextStepsList(
    BuildContext context,
    List<Map<String, dynamic>> data,
    bool showMoreButton,
    int remainingCount,
  ) {
    return Column(
      children: [
        ...data.map((item) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: LessonCard(
              lessonId: item['lesson_id'] as int? ?? 0,
              lessonName: item['lesson_name'],
              topicTitle: item['topic_title'] ?? 'Genel Tekrar',
              curriculumWeek: item['curriculum_week'],
              progress: (item['progress_percentage'] ?? 0.0).toDouble(),
              successRate: (item['success_rate'] ?? 0.0).toDouble(),
              onTap: () => _navigateToOutcomes(context, item),
              isNextStep: true,
            ),
          );
        }),
        if (showMoreButton)
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: GestureDetector(
              onTap: widget.onExpandNextSteps,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Diğer $remainingCount haftayı göster',
                      style: TextStyle(
                        color: Theme.of(context).primaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.arrow_drop_down_rounded,
                      color: Theme.of(context).primaryColor,
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildMotivationCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF6C5CE7).withOpacity(0.1),
            const Color(0xFF00B894).withOpacity(0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF6C5CE7).withOpacity(0.2),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: const Icon(
              Icons.celebration_rounded,
              color: Color(0xFF6C5CE7),
              size: 32,
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Harika İş! 🎉',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Bu hafta için tüm derslerinizi tamamladınız. Başarılarınızı kutlayın!',
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _navigateToOutcomes(
    BuildContext context,
    Map<String, dynamic> data,
  ) async {
    await Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => OutcomesScreen(
          lessonId: data['lesson_id'],
          gradeId: data['grade_id'],
          lessonName: data['lesson_name'],
          gradeName: data['grade_name'],
          initialCurriculumWeek:
              data['curriculum_week'] ?? widget.currentCurriculumWeek,
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.easeInOut;
          final tween = Tween(
            begin: begin,
            end: end,
          ).chain(CurveTween(curve: curve));
          final offsetAnimation = animation.drive(tween);
          return SlideTransition(position: offsetAnimation, child: child);
        },
      ),
    );
    widget.onRefresh();
  }

  Widget _buildGradeCard(Grade grade, List<Color> colors, int index) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => LessonsScreen(grade: grade),
            ),
          );
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: colors,
            ),
            boxShadow: [
              BoxShadow(
                color: colors[0].withOpacity(0.2),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                top: -20,
                right: -20,
                child: Opacity(
                  opacity: 0.1,
                  child: Icon(Icons.school, size: 100, color: colors[1]),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        _getIconForGrade(index),
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          grade.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Derslere git',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Positioned(
                bottom: 20,
                right: 20,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.arrow_forward,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Color> _getGradientColor(int index) {
    final gradients = [
      [const Color(0xFF6366F1), const Color(0xFF8B5CF6)],
      [const Color(0xFF0EA5E9), const Color(0xFF3B82F6)],
      [const Color(0xFF10B981), const Color(0xFF059669)],
      [const Color(0xFFF59E0B), const Color(0xFFD97706)],
      [const Color(0xFFEF4444), const Color(0xFFDC2626)],
      [const Color(0xFF8B5CF6), const Color(0xFF7C3AED)],
      [const Color(0xFFEC4899), const Color(0xFFDB2777)],
      [const Color(0xFF14B8A6), const Color(0xFF0D9488)],
    ];

    return gradients[index % gradients.length];
  }

  IconData _getIconForGrade(int index) {
    final icons = [
      Icons.school,
      Icons.book,
      Icons.auto_stories,
      Icons.cast_for_education,
      Icons.menu_book,
      Icons.science,
      Icons.calculate,
      Icons.language,
    ];

    return icons[index % icons.length];
  }

  double _calculateAverageSuccess() {
    if (widget.agendaData == null || widget.agendaData!.isEmpty) return 0.0;

    double totalSuccess = 0;
    int count = 0;

    for (final item in widget.agendaData!) {
      final successRate = (item['success_rate'] ?? 0.0).toDouble();
      if (successRate > 0) {
        totalSuccess += successRate;
        count++;
      }
    }

    return count > 0 ? (totalSuccess / count) : 0.0;
  }

  double _calculateTotalProgress() {
    if (widget.agendaData == null || widget.agendaData!.isEmpty) return 0.0;

    double totalProgress = 0;

    for (final item in widget.agendaData!) {
      totalProgress += (item['progress_percentage'] ?? 0.0).toDouble();
    }

    return widget.agendaData!.isNotEmpty
        ? (totalProgress / widget.agendaData!.length)
        : 0.0;
  }

  int _calculateCompletedLessons() {
    if (widget.agendaData == null) return 0;

    return widget.agendaData!
        .where(
          (item) => (item['progress_percentage'] ?? 0.0).toDouble() >= 100.0,
        )
        .length;
  }
}
