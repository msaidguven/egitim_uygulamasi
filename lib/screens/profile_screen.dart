// lib/screens/profile_screen.dart

import 'package:egitim_uygulamasi/admin/admin_auth_gate.dart';
import 'package:egitim_uygulamasi/models/profile_model.dart';
import 'package:egitim_uygulamasi/screens/admin/fix_true_false_screen.dart';
import 'package:egitim_uygulamasi/screens/edit_profile_screen.dart';
import 'package:egitim_uygulamasi/screens/login_screen.dart';
import 'package:egitim_uygulamasi/viewmodels/auth_viewmodel.dart';
import 'package:egitim_uygulamasi/viewmodels/profile_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:egitim_uygulamasi/providers.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // profileViewModelProvider'ı dinle
    final profileViewModel = ref.watch(profileViewModelProvider);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // Veri yüklenirken gösterilecek ekran
    if (profileViewModel.isLoading && profileViewModel.profile == null) {
      return Scaffold(
        backgroundColor: isDarkMode ? Colors.black : Colors.white,
        body: Center(
          child: CircularProgressIndicator(
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      );
    }

    // Hata durumunda gösterilecek ekran
    if (profileViewModel.errorMessage != null && profileViewModel.profile == null) {
      return Scaffold(
        backgroundColor: isDarkMode ? Colors.black : Colors.white,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  color: Colors.red,
                  size: 64,
                ),
                const SizedBox(height: 20),
                Text(
                  profileViewModel.errorMessage!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: () => ref.read(profileViewModelProvider.notifier).fetchProfile(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Tekrar Dene'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Profil bulunamadığında gösterilecek ekran
    if (profileViewModel.profile == null) {
      return Scaffold(
        backgroundColor: isDarkMode ? Colors.black : Colors.white,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.person_off_rounded,
                color: isDarkMode ? Colors.grey[600] : Colors.grey[400],
                size: 64,
              ),
              const SizedBox(height: 20),
              Text(
                'Profil bulunamadı veya yüklenemedi.',
                style: TextStyle(
                  fontSize: 16,
                  color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => ref.read(profileViewModelProvider.notifier).fetchProfile(),
                child: const Text('Yeniden Yükle'),
              ),
            ],
          ),
        ),
      );
    }

    // Profil verisi mevcutsa gösterilecek body
    return _ProfileBody(profile: profileViewModel.profile!);
  }
}

class _ProfileBody extends ConsumerStatefulWidget {
  final Profile profile;
  const _ProfileBody({required this.profile});

  @override
  ConsumerState<_ProfileBody> createState() => __ProfileBodyState();
}

class __ProfileBodyState extends ConsumerState<_ProfileBody> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    // Verilerin taze olduğundan emin olmak için fetchProfile'i burada çağırabiliriz.
    // Ancak bu, her profil ekranı açıldığında yeniden yükleme yapar.
    // İsteğe bağlı olarak eklenebilir:
    // WidgetsBinding.instance.addPostFrameCallback((_) {
    //   ref.read(profileViewModelProvider.notifier).fetchProfile();
    // });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String _getInitials(String? fullName) {
    if (fullName == null || fullName.isEmpty) return '?';
    List<String> names = fullName.split(' ').where((s) => s.isNotEmpty).toList();
    if (names.isEmpty) return '?';
    String initials = names[0][0];
    if (names.length > 1) {
      initials += names.last[0];
    }
    return initials.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    // En güncel profil verisini almak için ref.watch kullanıyoruz.
    final profile = ref.watch(profileViewModelProvider).profile ?? widget.profile;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDarkMode ? Colors.black : Colors.white,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 280.0,
              floating: false,
              pinned: true,
              backgroundColor: isDarkMode ? Colors.black : Colors.white,
              elevation: 0,
              leading: IconButton(
                icon: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: isDarkMode ? Colors.white : Colors.black,
                  size: 20,
                ),
                onPressed: () => ref.read(mainScreenIndexProvider.notifier).state = 0,
              ),
              actions: [
                IconButton(
                  icon: Icon(
                    Icons.edit_outlined,
                    color: isDarkMode ? Colors.white : Colors.black,
                    size: 20,
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => EditProfileScreen(profile: profile),
                      ),
                    ).then((updated) {
                      if (updated == true) {
                        ref.read(profileViewModelProvider.notifier).fetchProfile();
                      }
                    });
                  },
                ),
                _buildPopupMenu(context, ref, profile),
              ],
              flexibleSpace: _buildHeader(context, profile),
            ),
            SliverPersistentHeader(
              pinned: true,
              delegate: _SliverAppBarDelegate(
                TabBar(
                  controller: _tabController,
                  tabs: const [
                    Tab(text: 'Hakkında'),
                    Tab(text: 'İlerleme'),
                  ],
                  indicatorColor: Theme.of(context).colorScheme.primary,
                  labelColor: Theme.of(context).colorScheme.primary,
                  unselectedLabelColor: isDarkMode ? Colors.grey[500] : Colors.grey[500],
                  labelStyle: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                  unselectedLabelStyle: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                  indicatorSize: TabBarIndicatorSize.label,
                  indicatorWeight: 3,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                ),
              ),
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildAboutTab(context, profile),
            _buildProgressTab(context, profile),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, Profile profile) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final initials = _getInitials(profile.fullName);
    final avatarColor = Colors.primaries[profile.id.hashCode % Colors.primaries.length];
    final bool hasAvatarUrl = profile.avatarUrl != null && profile.avatarUrl!.isNotEmpty;

    return Container(
      color: isDarkMode ? Colors.grey[900] : Colors.grey[50],
      child: Stack(
        children: [
          // Background Shape
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 140,
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
              ),
            ),
          ),

          // Profile Content
          Positioned(
            top: 80,
            left: 0,
            right: 0,
            child: Column(
              children: [
                // Avatar
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isDarkMode ? Colors.grey[900]! : Colors.white,
                      width: 4,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: CircleAvatar(
                    radius: 60,
                    backgroundColor: isDarkMode ? Colors.grey[800] : Colors.white,
                    child: hasAvatarUrl
                        ? ClipOval(
                      child: Image.network(
                        profile.avatarUrl!,
                        width: 112,
                        height: 112,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return _buildDefaultAvatar(avatarColor, initials, 56);
                        },
                      ),
                    )
                        : _buildDefaultAvatar(avatarColor, initials, 56),
                  ),
                ),

                const SizedBox(height: 20),

                // Name
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    profile.fullName ?? 'İsimsiz',
                    style: TextStyle(
                      color: isDarkMode ? Colors.white : Colors.black,
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

                // Username
                if (profile.username != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      '@${profile.username}',
                      style: TextStyle(
                        color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),

                // Role Badge
                if (profile.role != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      decoration: BoxDecoration(
                        color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            profile.role == 'teacher' ? Icons.school_outlined : Icons.school,
                            size: 16,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            profile.role == 'teacher' ? 'Öğretmen' : 'Öğrenci',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: isDarkMode ? Colors.grey[300] : Colors.grey[700],
                            ),
                          ),
                        ],
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

  Widget _buildDefaultAvatar(Color color, String initials, double radius) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: color,
      child: Text(
        initials,
        style: const TextStyle(
          fontSize: 32,
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildAboutTab(BuildContext context, Profile profile) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // About Section
          if (profile.about != null && profile.about!.isNotEmpty) ...[
            _SectionTitle(title: 'Hakkında', isDarkMode: isDarkMode),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.grey[900] : Colors.grey[50],
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDarkMode ? Colors.grey[800]! : Colors.grey[200]!,
                  width: 1,
                ),
              ),
              child: Text(
                profile.about!,
                style: TextStyle(
                  fontSize: 15,
                  color: isDarkMode ? Colors.grey[300] : Colors.grey[700],
                  height: 1.6,
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],

          // Details Section
          _SectionTitle(title: 'Kişisel Bilgiler', isDarkMode: isDarkMode),
          const SizedBox(height: 12),

          Container(
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.grey[900] : Colors.grey[50],
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDarkMode ? Colors.grey[800]! : Colors.grey[200]!,
                width: 1,
              ),
            ),
            child: Column(
              children: [
                _InfoTile(
                  icon: Icons.school_outlined,
                  title: 'Sınıf',
                  value: profile.grade?.name,
                  isDarkMode: isDarkMode,
                ),
                _Divider(isDarkMode: isDarkMode),
                _InfoTile(
                  icon: Icons.location_city_outlined,
                  title: 'Şehir',
                  value: profile.city?.name,
                  isDarkMode: isDarkMode,
                ),
                _Divider(isDarkMode: isDarkMode),
                _InfoTile(
                  icon: Icons.map_outlined,
                  title: 'İlçe',
                  value: profile.district?.name,
                  isDarkMode: isDarkMode,
                ),
                _Divider(isDarkMode: isDarkMode),
                _InfoTile(
                  icon: Icons.home_work_outlined,
                  title: 'Okul',
                  value: profile.schoolName,
                  isDarkMode: isDarkMode,
                ),
                if (profile.role == 'teacher') ...[
                  _Divider(isDarkMode: isDarkMode),
                  _InfoTile(
                    icon: Icons.book_outlined,
                    title: 'Branş',
                    value: profile.branch,
                    isDarkMode: isDarkMode,
                  ),
                ],
              ],
            ),
          ),

        ],
      ),
    );
  }

  Widget _buildProgressTab(BuildContext context, Profile profile) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(title: 'Yakında Gelecek', isDarkMode: isDarkMode),
          const SizedBox(height: 12),

          // Feature Cards
          _FeatureCard(
            icon: Icons.leaderboard_outlined,
            title: 'Detaylı İstatistikler',
            description: 'Ders başarı oranlarınızı ve ilerlemenizi takip edin',
            isDarkMode: isDarkMode,
          ),

          const SizedBox(height: 12),

          _FeatureCard(
            icon: Icons.emoji_events_outlined,
            title: 'Başarı Rozetleri',
            description: 'Kazandığınız rozetleri ve ödülleri görüntüleyin',
            isDarkMode: isDarkMode,
          ),

          const SizedBox(height: 12),

          _FeatureCard(
            icon: Icons.timeline_outlined,
            title: 'Gelişim Grafikleri',
            description: 'Zaman içindeki gelişiminizi grafiklerle analiz edin',
            isDarkMode: isDarkMode,
          ),

          const SizedBox(height: 12),

          _FeatureCard(
            icon: Icons.compare_arrows_outlined,
            title: 'Sınıf Sıralaması',
            description: 'Sınıfınız içindeki sıralamanızı görüntüleyin',
            isDarkMode: isDarkMode,
          ),
        ],
      ),
    );
  }

  PopupMenuButton _buildPopupMenu(BuildContext context, WidgetRef ref, Profile profile) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return PopupMenuButton(
      onSelected: (value) async {
        if (value == 'admin') {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const AdminAuthGate()),
          );
        } else if (value == 'fix_tf') {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const FixTrueFalseScreen()),
          );
        } else if (value == 'logout') {
          // Merkezi signOut metodunu ref ile çağır
          await ref.read(authViewModelProvider.notifier).signOut(ref);
          // Ekran geçişlerini yönet
          if (context.mounted) {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => const LoginScreen()),
                  (Route<dynamic> route) => false,
            );
          }
        }
      },
      icon: Icon(
        Icons.more_vert_rounded,
        color: isDarkMode ? Colors.white : Colors.black,
      ),
      itemBuilder: (context) => [
        if (profile.role == 'admin') ...[
          PopupMenuItem(
            value: 'admin',
            child: ListTile(
              leading: Icon(
                Icons.admin_panel_settings,
                color: Theme.of(context).colorScheme.primary,
              ),
              title: Text(
                'Admin Paneli',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: isDarkMode ? Colors.white : Colors.black,
                ),
              ),
            ),
          ),
          PopupMenuItem(
            value: 'fix_tf',
            child: ListTile(
              leading: Icon(
                Icons.build_circle_outlined,
                color: Colors.orange,
              ),
              title: Text(
                'D/Y Sorularını Onar',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: isDarkMode ? Colors.white : Colors.black,
                ),
              ),
            ),
          ),
          const PopupMenuDivider(),
        ],
        PopupMenuItem(
          value: 'logout',
          child: ListTile(
            leading: const Icon(
              Icons.logout_rounded,
              color: Colors.red,
            ),
            title: const Text(
              'Çıkış Yap',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.red,
              ),
            ),
          ),
        ),
      ],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      color: isDarkMode ? Colors.grey[900] : Colors.white,
      elevation: 8,
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;

  _SliverAppBarDelegate(this._tabBar);

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Container(
      color: isDarkMode ? Colors.black : Colors.white,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final bool isDarkMode;

  const _SectionTitle({
    required this.title,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: isDarkMode ? Colors.white : Colors.black,
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? value;
  final bool isDarkMode;

  const _InfoTile({
    required this.icon,
    required this.title,
    this.value,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    final hasValue = value != null && value!.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.grey[800] : Colors.white,
              shape: BoxShape.circle,
              border: Border.all(
                color: isDarkMode ? Colors.grey[700]! : Colors.grey[200]!,
                width: 1,
              ),
            ),
            child: Icon(
              icon,
              color: isDarkMode ? Colors.grey[300] : Colors.grey[600],
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  hasValue ? value! : 'Belirtilmemiş',
                  style: TextStyle(
                    fontSize: 16,
                    color: isDarkMode ? Colors.white : Colors.black,
                    fontWeight: hasValue ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  final bool isDarkMode;
  const _Divider({required this.isDarkMode});

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      thickness: 1,
      indent: 72,
      endIndent: 16,
      color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
    );
  }
}

class _StatItem extends StatelessWidget {
  final String value;
  final String label;
  final bool isDarkMode;
  final Color? valueColor;

  const _StatItem({
    required this.value,
    required this.label,
    required this.isDarkMode,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: valueColor ?? Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final bool isDarkMode;

  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[900] : Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDarkMode ? Colors.grey[800]! : Colors.grey[200]!,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.grey[800] : Colors.white,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isDarkMode ? Colors.white : Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.arrow_forward_ios_rounded,
            color: isDarkMode ? Colors.grey[600] : Colors.grey[400],
            size: 16,
          ),
        ],
      ),
    );
  }
}
