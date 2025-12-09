import 'package:flutter/material.dart';
import 'package:egitim_uygulamasi/screens/category_detail_screen.dart';
import 'package:egitim_uygulamasi/viewmodels/category_viewmodel.dart';
import 'package:egitim_uygulamasi/viewmodels/auth_viewmodel.dart';
import 'package:egitim_uygulamasi/models/category_model.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final CategoryViewModel _viewModel = CategoryViewModel();
  final AuthViewModel _authViewModel = AuthViewModel();

  @override
  void initState() {
    super.initState();
    // ViewModel'deki değişiklikleri dinlemek için listener ekliyoruz.
    _viewModel.addListener(_onViewModelUpdated);
    // Veri çekme işlemini başlatıyoruz.
    _viewModel.fetchCategories();
  }

  @override
  void dispose() {
    // Sayfa kapandığında memory leak olmaması için listener'ı kaldırıyoruz.
    _viewModel.removeListener(_onViewModelUpdated);
    _authViewModel.dispose();
    super.dispose();
  }

  void _onViewModelUpdated() {
    // ViewModel'den haber geldiğinde (notifyListeners çağrıldığında)
    // arayüzü yeniden çizmek için setState çağırıyoruz.
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Eğitim Kategorileri'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await _authViewModel.signOut();
            },
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    // ViewModel'in durumuna göre arayüzü çiziyoruz.
    if (_viewModel.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_viewModel.errorMessage != null) {
      return Center(child: Text(_viewModel.errorMessage!));
    }
    if (_viewModel.categories.isEmpty) {
      return const Center(child: Text('Gösterilecek kategori bulunamadı.'));
    }

    // Veri başarıyla geldiyse listeyi oluştur.
    return ListView.builder(
      itemCount: _viewModel.categories.length,
      itemBuilder: (BuildContext context, int index) {
        final category = _viewModel.categories[index];

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
          child: ListTile(
            leading: const Icon(Icons.school_outlined),
            title: Text(category.name),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16.0),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CategoryDetailScreen(
                    categoryName: category.name,
                    categoryId: category.id, // Kategori ID'sini de gönderiyoruz
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
