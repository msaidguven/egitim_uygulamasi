import 'package:flutter/material.dart';
import 'package:egitim_uygulamasi/viewmodels/category_detail_viewmodel.dart';

class CategoryDetailScreen extends StatefulWidget {
  final String categoryName;
  final int categoryId;

  const CategoryDetailScreen({
    super.key,
    required this.categoryName,
    required this.categoryId,
  });

  @override
  State<CategoryDetailScreen> createState() => _CategoryDetailScreenState();
}

class _CategoryDetailScreenState extends State<CategoryDetailScreen> {
  final CategoryDetailViewModel _viewModel = CategoryDetailViewModel();

  @override
  void initState() {
    super.initState();
    _viewModel.addListener(_onViewModelUpdated);
    // ViewModel'e hangi kategorinin kurslarını getireceğini söylüyoruz.
    _viewModel.fetchCourses(widget.categoryId);
  }

  @override
  void dispose() {
    _viewModel.removeListener(_onViewModelUpdated);
    super.dispose();
  }

  void _onViewModelUpdated() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.categoryName)),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_viewModel.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_viewModel.errorMessage != null) {
      return Center(child: Text(_viewModel.errorMessage!));
    }
    if (_viewModel.courses.isEmpty) {
      return const Center(
        child: Text('Bu kategoride henüz kurs bulunmamaktadır.'),
      );
    }

    return ListView.builder(
      itemCount: _viewModel.courses.length,
      itemBuilder: (context, index) {
        final course = _viewModel.courses[index];
        return Card(
          margin: const EdgeInsets.all(10.0),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  course.name,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8.0),
                Text(course.description),
              ],
            ),
          ),
        );
      },
    );
  }
}
