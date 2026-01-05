// lib/screens/profile_screen.dart

import 'package:egitim_uygulamasi/admin/admin_auth_gate.dart';
import 'package:egitim_uygulamasi/models/profile_model.dart';
import 'package:egitim_uygulamasi/screens/admin/fix_true_false_screen.dart'; // YENİ: Import eklendi
import 'package:egitim_uygulamasi/screens/edit_profile_screen.dart';
import 'package:egitim_uygulamasi/viewmodels/profile_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = ProfileViewModel();

    return ChangeNotifierProvider(
      create: (_) => viewModel..fetchProfile(),
      child: Consumer<ProfileViewModel>(
        builder: (context, vm, child) {
          return Scaffold(
            body: vm.isLoading
                ? const Center(child: CircularProgressIndicator())
                : vm.errorMessage != null
                    ? Center(child: Text(vm.errorMessage!))
                    : vm.profile == null
                        ? const Center(child: Text('Profil bulunamadı.'))
                        : _ProfileBody(profile: vm.profile!),
          );
        },
      ),
    );
  }
}

class _ProfileBody extends StatelessWidget {
  final Profile profile;
  const _ProfileBody({required this.profile});

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
    final vm = Provider.of<ProfileViewModel>(context, listen: false);

    return DefaultTabController(
      length: 2,
      child: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 240.0,
              floating: false,
              pinned: true,
              actions: [
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => EditProfileScreen(profile: profile),
                      ),
                    ).then((updated) {
                      if (updated == true) {
                        vm.fetchProfile();
                      }
                    });
                  },
                ),
                _buildPopupMenu(context, vm),
              ],
              flexibleSpace: FlexibleSpaceBar(
                background: _buildHeader(context, profile),
              ),
              bottom: TabBar(
                tabs: const [
                  Tab(text: 'Hakkında'),
                  Tab(text: 'İlerleme'),
                ],
                indicatorColor: Theme.of(context).primaryColor,
                labelColor: Theme.of(context).primaryColor,
                unselectedLabelColor: Colors.grey,
              ),
            ),
          ];
        },
        body: TabBarView(
          children: [
            _buildAboutTab(context, profile),
            _buildProgressTab(context, profile),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, Profile profile) {
    final initials = _getInitials(profile.fullName);
    final avatarColor = Colors.primaries[profile.id.hashCode % Colors.primaries.length];
    final bool hasAvatarUrl = profile.avatarUrl != null && profile.avatarUrl!.isNotEmpty;

    Widget defaultAvatar = Container(
      color: avatarColor,
      alignment: Alignment.center,
      child: Text(initials, style: const TextStyle(fontSize: 32, color: Colors.white, fontWeight: FontWeight.bold)),
    );

    return Stack(
      fit: StackFit.expand,
      children: [
        Image.network(
          profile.coverPhotoUrl ?? 'invalid_url',
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [avatarColor.shade700, avatarColor.shade400],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            );
          },
        ),
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.black54, Colors.transparent],
              begin: Alignment.bottomCenter,
              end: Alignment.center,
            ),
          ),
        ),
        Positioned(
          bottom: 60,
          left: 16,
          child: Row(
            children: [
              CircleAvatar(
                radius: 40,
                backgroundColor: Colors.white,
                child: CircleAvatar(
                  radius: 38,
                  backgroundColor: avatarColor,
                  child: ClipOval(
                    child: hasAvatarUrl
                        ? Image.network(
                            profile.avatarUrl!,
                            fit: BoxFit.cover,
                            width: 76,
                            height: 76,
                            errorBuilder: (context, error, stackTrace) {
                              return defaultAvatar;
                            },
                          )
                        : defaultAvatar,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    profile.fullName ?? 'İsimsiz',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      shadows: [Shadow(blurRadius: 2, color: Colors.black54)],
                    ),
                  ),
                  if (profile.username != null)
                    Text(
                      '@${profile.username}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                        shadows: [Shadow(blurRadius: 2, color: Colors.black54)],
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAboutTab(BuildContext context, Profile profile) {
    return Material(
      color: Theme.of(context).canvasColor,
      child: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          if (profile.about != null && profile.about!.isNotEmpty) ...[
            _InfoCard(
              title: 'Hakkında',
              child: Text(profile.about!, style: const TextStyle(fontSize: 16)),
            ),
            const SizedBox(height: 16),
          ],
          _InfoCard(
            title: 'Detaylar',
            child: Column(
              children: [
                _InfoTile(icon: Icons.school_outlined, title: 'Sınıf', value: profile.grade?.name),
                _InfoTile(icon: Icons.location_city_outlined, title: 'Şehir', value: profile.city?.name),
                _InfoTile(icon: Icons.map_outlined, title: 'İlçe', value: profile.district?.name),
                _InfoTile(icon: Icons.home_work_outlined, title: 'Okul', value: profile.schoolName),
                if (profile.role == 'teacher')
                  _InfoTile(icon: Icons.book_outlined, title: 'Branş', value: profile.branch),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressTab(BuildContext context, Profile profile) {
    return Material(
      color: Theme.of(context).canvasColor,
      child: const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            'Yakında burada ders ilerlemeniz ve başarılarınız gösterilecek.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16),
          ),
        ),
      ),
    );
  }

  // DÜZELTME: PopupMenuButton içine yeni admin aracı eklendi.
  PopupMenuButton _buildPopupMenu(BuildContext context, ProfileViewModel vm) {
    return PopupMenuButton(
      onSelected: (value) async {
        if (value == 'admin') {
          Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AdminAuthGate()));
        } else if (value == 'fix_tf') { // YENİ: Yeni case eklendi
          Navigator.of(context).push(MaterialPageRoute(builder: (_) => const FixTrueFalseScreen()));
        } else if (value == 'logout') {
          await vm.signOut();
        }
      },
      itemBuilder: (context) => [
        if (vm.profile?.role == 'admin') ...[
          const PopupMenuItem(
            value: 'admin',
            child: ListTile(
              leading: Icon(Icons.admin_panel_settings),
              title: Text('Admin Paneli'),
            ),
          ),
          const PopupMenuItem( // YENİ: Onarım aracı için menü öğesi
            value: 'fix_tf',
            child: ListTile(
              leading: Icon(Icons.build_circle_outlined, color: Colors.orange),
              title: Text('D/Y Sorularını Onar'),
            ),
          ),
          const PopupMenuDivider(),
        ],
        const PopupMenuItem(
          value: 'logout',
          child: ListTile(
            leading: Icon(Icons.logout, color: Colors.red),
            title: Text('Çıkış Yap', style: TextStyle(color: Colors.red)),
          ),
        ),
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final Widget child;
  const _InfoCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const Divider(height: 24),
            child,
          ],
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? value;

  const _InfoTile({required this.icon, required this.title, this.value});

  @override
  Widget build(BuildContext context) {
    final bool hasValue = value != null && value!.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey.shade600),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(color: Colors.grey)),
              const SizedBox(height: 2),
              Text(
                hasValue ? value! : 'Belirtilmemiş',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: hasValue ? FontWeight.w500 : FontWeight.normal,
                  fontStyle: hasValue ? FontStyle.normal : FontStyle.italic,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
