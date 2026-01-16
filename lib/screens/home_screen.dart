// lib/screens/home_screen.dart

import 'dart:ui';
import 'package:egitim_uygulamasi/models/profile_model.dart';
import 'package:egitim_uygulamasi/screens/anasinifi/compare_page.dart';
import 'package:egitim_uygulamasi/screens/anasinifi/number_composition_page.dart';
import 'package:egitim_uygulamasi/screens/outcomes_screen.dart';
import 'package:egitim_uygulamasi/screens/statistics_screen.dart';
import 'package:egitim_uygulamasi/widgets/lesson_card.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

enum NextStepsDisplayState {
  hidden,
  collapsed,
  expanded,
}

class HomeScreen extends StatelessWidget {
  final Function(int) onNavigate;
  final Profile? profile;
  final Future<void> Function() onRefresh;
  final List<Map<String, dynamic>>? agendaData;
  final List<Map<String, dynamic>>? nextStepsData;
  final int currentWeek;
  final NextStepsDisplayState nextStepsState;
  final VoidCallback onToggleNextSteps;
  final VoidCallback onExpandNextSteps;
  final String? impersonatedRole;
  final ValueChanged<String?> onRoleChanged;
  final String? currentRole;

  const HomeScreen({
    super.key,
    required this.onNavigate,
    required this.profile,
    required this.onRefresh,
    this.agendaData,
    this.nextStepsData,
    this.currentWeek = 0,
    required this.nextStepsState,
    required this.onToggleNextSteps,
    required this.onExpandNextSteps,
    this.impersonatedRole,
    required this.onRoleChanged,
    this.currentRole,
  });

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
                color: Colors.black.withOpacity(0.2),
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
            color: gradient.colors.first.withOpacity(0.3),
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
          splashColor: Colors.white.withOpacity(0.2),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
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
                          color: Colors.white.withOpacity(0.9),
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
    final bool isStudent = currentRole == 'student';
    final bool isAdmin = profile?.role == 'admin';

    return Scaffold(
      extendBodyBehindAppBar: true,
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
          onRefresh: onRefresh,
          color: Theme.of(context).primaryColor,
          backgroundColor: Colors.white,
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            slivers: [
              // Başlık Alanı
              SliverAppBar(
                expandedHeight: 300.0,
                collapsedHeight: 100.0,
                backgroundColor: Colors.transparent,
                elevation: 0,
                pinned: false,
                floating: false,
                snap: false,
                flexibleSpace: _buildModernHeader(context, isAdmin),
              ),

              // İçerik
              if (profile == null)
                _buildLoadingShimmer()
              else if (isStudent && agendaData == null)
                _buildLoadingShimmer()
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

  Widget _buildModernHeader(BuildContext context, bool isAdmin) {
    final isLoggedIn = profile != null;
    final avatarUrl = profile?.avatarUrl;
    final fullName = profile?.fullName;
    final initials = fullName != null && fullName.isNotEmpty
        ? fullName.substring(0, 1).toUpperCase()
        : '?';

    return LayoutBuilder(
      builder: (context, constraints) {
        final top = constraints.biggest.height;
        return Stack(
          children: [
            // Arka plan
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Theme.of(context).primaryColor,
                    Theme.of(context).primaryColor.withOpacity(0.9),
                    Theme.of(context).primaryColor.withOpacity(0.8),
                  ],
                ),
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(top < 150 ? 0 : 30),
                ),
              ),
            ),

            // Dekoratif elementler
            Positioned(
              top: -50,
              right: -50,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.05),
                ),
              ),
            ),
            Positioned(
              bottom: 30,
              left: -100,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.03),
                ),
              ),
            ),

            // İçerik
            Positioned.fill(
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 20),
                        // Üst bar
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isLoggedIn ? 'Hoş geldin' : 'Merhaba',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.9),
                                    fontSize: 16,
                                    fontWeight: FontWeight.w300,
                                  ),
                                ),
                                if (isLoggedIn)
                                  Text(
                                    fullName ?? 'Kullanıcı',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      height: 1.2,
                                    ),
                                  ),
                              ],
                            ),
                            if (isAdmin)
                              _buildAdminProfileMenu(context, avatarUrl, initials)
                            else
                              _buildUserAvatar(avatarUrl, initials),
                          ],
                        ),
                        const SizedBox(height: 20),
                        // İstatistik kartları
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              _buildStatCard(
                                icon: Icons.calendar_today_rounded,
                                value: '$currentWeek',
                                label: 'Hafta',
                                color: Colors.white,
                                bgColor: Colors.white.withOpacity(0.2),
                              ),
                              const SizedBox(width: 12),
                              _buildStatCard(
                                icon: Icons.menu_book_rounded,
                                value: '${agendaData?.length ?? 0}',
                                label: 'Ders',
                                color: const Color(0xFF00B894),
                                bgColor: const Color(0xFF00B894).withOpacity(0.2),
                              ),
                              const SizedBox(width: 12),
                              _buildStatCard(
                                icon: Icons.school_rounded,
                                value: profile?.grade?.name ?? '-',
                                label: 'Sınıf',
                                color: const Color(0xFFFD79A8),
                                bgColor: const Color(0xFFFD79A8).withOpacity(0.2),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildAdminProfileMenu(BuildContext context, String? avatarUrl, String initials) {
    final List<Map<String, dynamic>> roles = [
      {'label': 'Admin', 'role': 'admin'},
      {'label': 'Öğrenci', 'role': 'student'},
      {'label': 'Öğretmen', 'role': 'teacher'},
    ];

    return PopupMenuButton<String?>(
      onSelected: (String? value) {
        if (value == 'show_games') {
          _showGameSelectionDialog(context);
        } else {
          onRoleChanged(value);
        }
      },
      itemBuilder: (context) {
        return <PopupMenuEntry<String?>>[
          ...roles.map((roleData) {
            final isSelected = (impersonatedRole ?? 'admin') == roleData['role'];
            return PopupMenuItem<String?>(
              value: roleData['role'],
              child: Row(
                children: [
                  Icon(
                    isSelected ? Icons.check_circle : Icons.circle_outlined,
                    color: isSelected ? Theme.of(context).primaryColor : Colors.grey,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    roleData['label'],
                    style: TextStyle(
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
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
        ];
      },
      child: _buildUserAvatar(avatarUrl, initials),
    );
  }

  Widget _buildUserAvatar(String? avatarUrl, String initials) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        color: Colors.white.withOpacity(0.2),
        border: Border.all(color: Colors.white.withOpacity(0.3), width: 2),
      ),
      child: avatarUrl != null && avatarUrl.isNotEmpty
          ? ClipRRect(
        borderRadius: BorderRadius.circular(13),
        child: Image.network(
          avatarUrl,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Center(
              child: Text(
                initials,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
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
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
    required Color bgColor,
  }) {
    return Container(
      width: 100,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 12,
            ),
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

  Widget _buildStudentContent(BuildContext context) {
    final hasNextSteps = nextStepsData != null && nextStepsData!.isNotEmpty;

    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      sliver: SliverList(
        delegate: SliverChildListDelegate([
          // Bu Hafta Bölümü
          _buildSectionHeader(
            context,
            title: 'Bu Haftanın Dersleri',
            subtitle: 'Tamamlamanız gereken konular',
            icon: Icons.today_rounded,
            iconColor: const Color(0xFF6C5CE7),
          ),
          const SizedBox(height: 16),
          _buildDataView(context, agendaData, _buildAgendaList),

          // Geçmiş Haftalar Bölümü
          if (hasNextSteps) ...[
            const SizedBox(height: 32),
            _buildSectionHeader(
              context,
              title: 'Geçmiş Haftalar',
              subtitle: 'Tekrar yapabileceğiniz konular',
              icon: Icons.history_rounded,
              iconColor: const Color(0xFF00B894),
              trailing: IconButton(
                onPressed: onToggleNextSteps,
                icon: Icon(
                  nextStepsState == NextStepsDisplayState.expanded
                      ? Icons.expand_less_rounded
                      : Icons.expand_more_rounded,
                  color: const Color(0xFF00B894),
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (nextStepsState != NextStepsDisplayState.hidden)
              _buildDataView(
                context,
                nextStepsData,
                    (ctx, data) {
                  final displayData = nextStepsState == NextStepsDisplayState.expanded
                      ? data
                      : data.take(3).toList();
                  final bool showMoreButton =
                      nextStepsState == NextStepsDisplayState.collapsed &&
                          data.length > 3;
                  return _buildNextStepsList(
                    ctx,
                    displayData,
                    showMoreButton,
                    data.length - 3,
                  );
                },
              ),
          ],

          // Motivasyon Mesajı
          if (agendaData?.isEmpty ?? false) ...[
            const SizedBox(height: 40),
            _buildMotivationCard(context),
          ],
        ]),
      ),
    );
  }

  Widget _buildTeacherContent(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      sliver: SliverList(
        delegate: SliverChildListDelegate([
          // Sınıflar Bölümü
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
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade700,
                    ),
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
          Icon(
            Icons.menu_book_rounded,
            size: 60,
            color: Colors.grey.shade300,
          ),
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
            style: TextStyle(
              color: Colors.grey.shade600,
            ),
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
            ));
        },
      ).toList(),
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
                weekNo: item['week_no'],
                progress: (item['progress_percentage'] ?? 0.0).toDouble(),
                successRate: (item['success_rate'] ?? 0.0).toDouble(),
                onTap: () => _navigateToOutcomes(context, item),
                isNextStep: true,
              ));
          },
        ).toList(),
        if (showMoreButton)
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: GestureDetector(
              onTap: onExpandNextSteps,
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
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
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
          initialWeek: data['week_no'] ?? currentWeek,
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.easeInOut;
          final tween = Tween(begin: begin, end: end).chain(
            CurveTween(curve: curve),
          );
          final offsetAnimation = animation.drive(tween);
          return SlideTransition(
            position: offsetAnimation,
            child: child,
          );
        },
      ),
    );
    onRefresh();
  }
}