import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../model/genre.dart';
import '../../provider.dart';
import '../book_list_page.dart';

class AdvancedSearchPage extends ConsumerStatefulWidget {
  const AdvancedSearchPage({super.key});

  @override
  ConsumerState<AdvancedSearchPage> createState() => _AdvancedSearchPageState();
}

class _AdvancedSearchPageState extends ConsumerState<AdvancedSearchPage> {
  final _nameController = TextEditingController();
  final _minPriceController = TextEditingController();
  final _maxPriceController = TextEditingController();

  Set<String> _selectedGenreIds = {};
  String? _selectedAuthorId;

  @override
  void dispose() {
    _nameController.dispose();
    _minPriceController.dispose();
    _maxPriceController.dispose();
    super.dispose();
  }

  void _applyFilters() {
    final query = _nameController.text.trim();
    final minPrice = double.tryParse(_minPriceController.text);
    final maxPrice = double.tryParse(_maxPriceController.text);

    // Gửi dữ liệu về BookListPage qua notifier
    ref.read(bookListProvider.notifier).applyAdvancedFilters(
      query: query.isEmpty ? null : query,
      genreIds: _selectedGenreIds.isEmpty ? null : _selectedGenreIds.toList(),
      minPrice: minPrice,
      maxPrice: maxPrice,
      authorId: _selectedAuthorId,
    );

    // Quay lại trang danh sách sách
    context.pop();
  }

  void _clearAll() {
    setState(() {
      _nameController.clear();
      _minPriceController.clear();
      _maxPriceController.clear();
      _selectedGenreIds.clear();
      _selectedAuthorId = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final genresAsync = ref.watch(genresProvider);
    final authorsAsync = ref.watch(allAuthorsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF09121F),
      appBar: AppBar(
        title: const Text('Tìm kiếm nâng cao'),
        centerTitle: true,
        backgroundColor: const Color(0xFF0E2A47),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
        actions: [
          TextButton(
            onPressed: _clearAll,
            child: const Text('Xóa tất cả', style: TextStyle(color: Colors.white70)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Tên sách
            _buildTextField(_nameController, 'Tên sách, tác giả...', Icons.search),

            const SizedBox(height: 16),

            // Thể loại
            Card(
              color: const Color(0xFF18223A),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: genresAsync.when(
                  data: (genres) => _buildMultiGenreChips(genres),
                  loading: () => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                  error: (_, __) => const Text('Lỗi tải thể loại', style: TextStyle(color: Colors.redAccent)),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Khoảng giá
            Card(
              color: const Color(0xFF18223A),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Expanded(child: _buildTextField(_minPriceController, 'Giá từ (đ)', Icons.attach_money, keyboardType: TextInputType.number)),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Text('→', style: TextStyle(color: Colors.white54, fontSize: 18)),
                    ),
                    Expanded(child: _buildTextField(_maxPriceController, 'Giá đến (đ)', Icons.attach_money, keyboardType: TextInputType.number)),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Tác giả
            Card(
              color: const Color(0xFF18223A),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: authorsAsync.when(
                  data: (authors) => DropdownButtonFormField<String?>(
                    value: _selectedAuthorId,
                    decoration: const InputDecoration(
                      labelText: 'Tác giả',
                      labelStyle: TextStyle(color: Colors.white70),
                      border: InputBorder.none,
                    ),
                    dropdownColor: const Color(0xFF18223A),
                    style: const TextStyle(color: Colors.white),
                    icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white70),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('Tất cả tác giả')),
                      ...authors.map((a) => DropdownMenuItem(
                        value: a.userId,
                        child: Text(a.fullName),
                      )),
                    ],
                    onChanged: (v) => setState(() => _selectedAuthorId = v),
                  ),
                  loading: () => const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                  ),
                  error: (_, __) => const Text('Lỗi tải tác giả', style: TextStyle(color: Colors.redAccent)),
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Nút Tìm kiếm
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _applyFilters,
                icon: const Icon(Icons.search, size: 20),
                label: const Text('Tìm kiếm', style: TextStyle(fontSize: 16)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2ECC71),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  elevation: 8,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController c, String hint, IconData icon, {TextInputType? keyboardType}) {
    return TextField(
      controller: c,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white54),
        prefixIcon: Icon(icon, color: Colors.white70),
        filled: true,
        fillColor: const Color(0xFF18223A),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      ),
    );
  }

  Widget _buildMultiGenreChips(List<Genre> genres) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: genres.map((g) {
        final isSelected = _selectedGenreIds.contains(g.genreId);
        return FilterChip(
          label: Text(g.genreName),
          selected: isSelected,
          selectedColor: const Color(0xFF2ECC71),
          checkmarkColor: Colors.white,
          labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.white70),
          backgroundColor: const Color(0xFF1E2A45),
          side: BorderSide(color: isSelected ? const Color(0xFF2ECC71) : Colors.white24),
          onSelected: (selected) {
            setState(() {
              if (selected) {
                _selectedGenreIds.add(g.genreId);
              } else {
                _selectedGenreIds.remove(g.genreId);
              }
            });
          },
        );
      }).toList(),
    );
  }
}