import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import '../models/menu_model.dart';
import '../services/api_service.dart';
import '../config.dart';

final _rpFormat = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

/// Resolve image URL: if it's a relative path like /uploads/..., prepend backend base URL
String _resolveMenuImageUrl(String url) {
  if (url.isEmpty) return '';
  if (url.startsWith('http')) return url;
  return '${AppConfig.socketUrl}$url';
}

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  List<MenuModel> menus = [];
  List<Category> categories = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final results = await Future.wait([
        ApiService.getAllMenus(),
        ApiService.getCategories(),
      ]);
      if (mounted) {
        setState(() {
          menus = results[0] as List<MenuModel>;
          categories = results[1] as List<Category>;
          loading = false;
        });
      }
    } catch (e) {
      print('Error loading menu data: $e');
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _deleteMenu(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Hapus Menu?'),
        content: const Text('Menu yang dihapus tidak bisa dikembalikan.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      try {
        await ApiService.deleteMenu(id);
        _loadData();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: const Text('Gagal menghapus menu'), backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
      }
    }
  }

  Future<void> _toggleMenu(String id) async {
    try {
      await ApiService.toggleMenu(id);
      _loadData();
    } catch (e) {
      print('Error toggling menu: $e');
    }
  }

  Future<void> _toggleFavorite(String id) async {
    try {
      await ApiService.toggleFavorite(id);
      _loadData();
    } catch (e) {
      print('Error toggling favorite: $e');
    }
  }

  void _openMenuForm({MenuModel? menu}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => MenuFormModal(
        categories: categories,
        initialData: menu,
        onSave: (data) async {
          Navigator.pop(ctx);
          try {
            if (menu != null) {
              await ApiService.updateMenu(menu.id, data);
            } else {
              await ApiService.createMenu(data);
            }
            _loadData();
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(menu != null ? 'Menu diperbarui!' : 'Menu ditambahkan!'),
                  backgroundColor: const Color(0xFFF97316),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              );
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: const Text('Gagal menyimpan menu'), backgroundColor: Colors.red,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              );
            }
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 700;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          child: isMobile
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Manajemen Menu',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Color(0xFF1E293B)),
                    ),
                    const SizedBox(height: 4),
                    Text('Tambah, ubah, atau hapus daftar menu.',
                      style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _openMenuForm(),
                        icon: const Icon(Icons.add_rounded, size: 20),
                        label: const Text('Tambah Menu'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFF97316),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                    ),
                  ],
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Manajemen Menu',
                          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Color(0xFF1E293B)),
                        ),
                        const SizedBox(height: 4),
                        Text('Tambah, ubah, atau hapus daftar menu.',
                          style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),
                      ],
                    ),
                    ElevatedButton.icon(
                      onPressed: () => _openMenuForm(),
                      icon: const Icon(Icons.add_rounded, size: 20),
                      label: const Text('Tambah Menu'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF97316),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ],
                ),
        ),
        const SizedBox(height: 16),

        // Content
        Expanded(
          child: loading
              ? const Center(child: CircularProgressIndicator(color: Color(0xFFF97316)))
              : RefreshIndicator(
                  onRefresh: _loadData,
                  color: const Color(0xFFF97316),
                  child: isMobile ? _buildMobileList() : _buildDesktopTable(),
                ),
        ),
      ],
    );
  }

  // ==========================================
  // MOBILE VIEW — Card List
  // ==========================================
  Widget _buildMobileList() {
    if (menus.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.restaurant_rounded, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text('Belum ada menu.', style: TextStyle(color: Colors.grey.shade400, fontSize: 15)),
          ],
        ),
      );
    }

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      itemCount: menus.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final menu = menus[index];
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2)),
            ],
          ),
          child: Column(
            children: [
              // Top row: Image + Info
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    // Menu image
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Stack(
                        children: [
                          menu.image.isNotEmpty
                              ? Image.network(_resolveMenuImageUrl(menu.image), width: 60, height: 60, fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => _imagePlaceholder(60))
                              : _imagePlaceholder(60),
                          if (!menu.isActive)
                            Positioned.fill(
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.5),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Center(
                                  child: Text(
                                    'HABIS',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 1,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Menu info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            menu.name,
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 3),
                          if (menu.description.isNotEmpty)
                            Text(
                              menu.description,
                              style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              // Category badge
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  menu.category?.name ?? '-',
                                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.grey.shade600),
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Price
                              Text(
                                _rpFormat.format(menu.price),
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFFF97316)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Bottom row: Toggle + Actions
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                  ),
                  border: Border(top: BorderSide(color: Colors.grey.shade100)),
                ),
                child: Row(
                  children: [
                    // Active toggle
                    GestureDetector(
                      onTap: () => _toggleMenu(menu.id),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 40,
                            height: 22,
                            decoration: BoxDecoration(
                              color: menu.isActive ? const Color(0xFFF97316) : Colors.grey.shade300,
                              borderRadius: BorderRadius.circular(11),
                            ),
                            child: AnimatedAlign(
                              duration: const Duration(milliseconds: 200),
                              alignment: menu.isActive ? Alignment.centerRight : Alignment.centerLeft,
                              child: Container(
                                width: 18, height: 18,
                                margin: const EdgeInsets.symmetric(horizontal: 2),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(9),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            menu.isActive ? 'Tersedia' : 'Habis',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: menu.isActive ? const Color(0xFFF97316) : const Color(0xFFEF4444),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Favorite star toggle
                    GestureDetector(
                      onTap: () => _toggleFavorite(menu.id),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: menu.isFavorite ? const Color(0xFFFFF7ED) : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          menu.isFavorite ? Icons.star_rounded : Icons.star_outline_rounded,
                          size: 22,
                          color: menu.isFavorite ? const Color(0xFFF97316) : Colors.grey.shade400,
                        ),
                      ),
                    ),
                    const Spacer(),
                    // Edit button
                    SizedBox(
                      height: 32,
                      child: TextButton.icon(
                        onPressed: () => _openMenuForm(menu: menu),
                        icon: const Icon(Icons.edit_rounded, size: 15, color: Color(0xFF3B82F6)),
                        label: const Text('Edit', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF3B82F6))),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    // Delete button
                    SizedBox(
                      height: 32,
                      child: TextButton.icon(
                        onPressed: () => _deleteMenu(menu.id),
                        icon: const Icon(Icons.delete_rounded, size: 15, color: Color(0xFFEF4444)),
                        label: const Text('Hapus', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFFEF4444))),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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

  Widget _imagePlaceholder(double size) {
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(Icons.image_rounded, color: Colors.grey.shade400, size: size * 0.4),
    );
  }

  // ==========================================
  // DESKTOP VIEW — DataTable
  // ==========================================
  Widget _buildDesktopTable() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 2)),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
            headingTextStyle: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey.shade600, fontSize: 13),
            dataTextStyle: const TextStyle(fontSize: 13, color: Color(0xFF1E293B)),
            columns: const [
              DataColumn(label: Text('Menu')),
              DataColumn(label: Text('Kategori')),
              DataColumn(label: Text('Harga')),
              DataColumn(label: Text('Status')),
              DataColumn(label: Text('Aksi')),
            ],
            rows: menus.map((menu) {
              return DataRow(cells: [
                DataCell(
                  Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: menu.image.isNotEmpty
                            ? Image.network(_resolveMenuImageUrl(menu.image), width: 44, height: 44, fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  width: 44, height: 44,
                                  color: Colors.grey.shade200,
                                  child: const Icon(Icons.image, color: Colors.grey),
                                ))
                            : Container(width: 44, height: 44, color: Colors.grey.shade200,
                                child: const Icon(Icons.image, color: Colors.grey)),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(menu.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                          SizedBox(
                            width: 180,
                            child: Text(menu.description,
                              maxLines: 1, overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                DataCell(
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(menu.category?.name ?? '-',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey.shade600)),
                  ),
                ),
                DataCell(Text(_rpFormat.format(menu.price), style: const TextStyle(fontWeight: FontWeight.w600))),
                DataCell(
                  GestureDetector(
                    onTap: () => _toggleMenu(menu.id),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 44,
                      height: 24,
                      decoration: BoxDecoration(
                        color: menu.isActive ? const Color(0xFFF97316) : Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: AnimatedAlign(
                        duration: const Duration(milliseconds: 200),
                        alignment: menu.isActive ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          width: 20, height: 20,
                          margin: const EdgeInsets.symmetric(horizontal: 2),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                DataCell(
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(
                          menu.isFavorite ? Icons.star_rounded : Icons.star_outline_rounded,
                          size: 18,
                          color: menu.isFavorite ? const Color(0xFFF97316) : Colors.grey.shade400,
                        ),
                        onPressed: () => _toggleFavorite(menu.id),
                        tooltip: menu.isFavorite ? 'Hapus dari Favorit' : 'Tambah ke Favorit',
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit_rounded, size: 18, color: Color(0xFF3B82F6)),
                        onPressed: () => _openMenuForm(menu: menu),
                        tooltip: 'Edit',
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_rounded, size: 18, color: Color(0xFFEF4444)),
                        onPressed: () => _deleteMenu(menu.id),
                        tooltip: 'Hapus',
                      ),
                    ],
                  ),
                ),
              ]);
            }).toList(),
          ),
        ),
      ),
    );
  }
}

// ==========================================
// MENU FORM MODAL
// ==========================================
class MenuFormModal extends StatefulWidget {
  final List<Category> categories;
  final MenuModel? initialData;
  final Function(Map<String, dynamic>) onSave;

  const MenuFormModal({
    super.key,
    required this.categories,
    this.initialData,
    required this.onSave,
  });

  @override
  State<MenuFormModal> createState() => _MenuFormModalState();
}

class _MenuFormModalState extends State<MenuFormModal> {
  late TextEditingController _nameCtrl;
  late TextEditingController _priceCtrl;
  late TextEditingController _descCtrl;
  String? _selectedCategoryId;
  bool _hasSpicyLevel = false;
  bool _hasTempLevel = false;
  Uint8List? _selectedImageBytes;
  String? _selectedImageName;
  bool _isUploading = false;
  String _existingImageUrl = '';
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    final d = widget.initialData;
    _nameCtrl = TextEditingController(text: d?.name ?? '');
    _priceCtrl = TextEditingController(text: d != null ? d.price.toInt().toString() : '');
    _descCtrl = TextEditingController(text: d?.description ?? '');
    _selectedCategoryId = d?.categoryId ?? (widget.categories.isNotEmpty ? widget.categories.first.id : null);
    _hasSpicyLevel = d?.hasSpicyLevel ?? false;
    _hasTempLevel = d?.hasTempLevel ?? false;
    _existingImageUrl = d?.image ?? '';
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? picked = await _picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );
      if (picked != null) {
        final bytes = await picked.readAsBytes();
        setState(() {
          _selectedImageBytes = bytes;
          _selectedImageName = picked.name;
        });
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  void _showImagePickerOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: const Color(0xFFFFF7ED), borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.camera_alt_rounded, color: Color(0xFFF97316)),
              ),
              title: const Text('Ambil Foto', style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: const Text('Gunakan kamera HP'),
              onTap: () { Navigator.pop(ctx); _pickImage(ImageSource.camera); },
            ),
            const SizedBox(height: 4),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: const Color(0xFFFFF7ED), borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.photo_library_rounded, color: Color(0xFFF97316)),
              ),
              title: const Text('Pilih dari Galeri', style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: const Text('Ambil dari galeri foto'),
              onTap: () { Navigator.pop(ctx); _pickImage(ImageSource.gallery); },
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _priceCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.initialData != null;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.9),
      padding: EdgeInsets.only(bottom: bottomInset),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40, height: 4,
            decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 12, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    isEdit ? 'Edit Menu' : 'Tambah Menu Baru',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF1E293B)),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          // Form
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _label('Nama Menu'),
                  _textField(_nameCtrl, 'Nama menu...'),
                  const SizedBox(height: 16),
                  // Responsive: stack on small screens
                  LayoutBuilder(
                    builder: (context, constraints) {
                      if (constraints.maxWidth < 400) {
                        // Stack vertically on small screens
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _label('Kategori'),
                            _categoryDropdown(),
                            const SizedBox(height: 16),
                            _label('Harga (Rp)'),
                            _textField(_priceCtrl, '15000', keyboardType: TextInputType.number),
                          ],
                        );
                      }
                      // Side by side on larger screens
                      return Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _label('Kategori'),
                                _categoryDropdown(),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _label('Harga (Rp)'),
                                _textField(_priceCtrl, '15000', keyboardType: TextInputType.number),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  _label('Gambar Menu'),
                  // Image picker area
                  GestureDetector(
                    onTap: _showImagePickerOptions,
                    child: Container(
                      height: 150,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: _selectedImageBytes != null || _existingImageUrl.isNotEmpty
                              ? const Color(0xFFF97316)
                              : Colors.grey.shade200,
                          width: _selectedImageBytes != null ? 2 : 1,
                        ),
                      ),
                      child: _selectedImageBytes != null
                          // Show newly picked image
                          ? Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(13),
                                  child: Image.memory(_selectedImageBytes!, width: double.infinity, height: 150, fit: BoxFit.cover),
                                ),
                                Positioned(
                                  top: 8, right: 8,
                                  child: GestureDetector(
                                    onTap: () => setState(() { _selectedImageBytes = null; _selectedImageName = null; }),
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                                      child: const Icon(Icons.close, color: Colors.white, size: 18),
                                    ),
                                  ),
                                ),
                              ],
                            )
                          : _existingImageUrl.isNotEmpty
                              // Show existing image (when editing)
                              ? Stack(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(13),
                                      child: Image.network(
                                        _existingImageUrl.startsWith('http') ? _existingImageUrl : '${AppConfig.socketUrl}${_existingImageUrl}',
                                        width: double.infinity, height: 150, fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => Center(
                                          child: Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Icon(Icons.broken_image_rounded, size: 40, color: Colors.grey.shade400),
                                              const SizedBox(height: 8),
                                              Text('Gambar tidak tersedia', style: TextStyle(color: Colors.grey.shade400, fontSize: 12)),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      bottom: 8, right: 8,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: Colors.black54,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: const Text('Tap untuk ganti', style: TextStyle(color: Colors.white, fontSize: 11)),
                                      ),
                                    ),
                                  ],
                                )
                              // Show placeholder
                              : Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.add_a_photo_rounded, size: 36, color: Colors.grey.shade400),
                                    const SizedBox(height: 8),
                                    Text('Tap untuk pilih gambar', style: TextStyle(color: Colors.grey.shade500, fontSize: 13, fontWeight: FontWeight.w500)),
                                    const SizedBox(height: 4),
                                    Text('Kamera atau Galeri', style: TextStyle(color: Colors.grey.shade400, fontSize: 11)),
                                  ],
                                ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _label('Deskripsi'),
                  TextField(
                    controller: _descCtrl,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'Deskripsi menu...',
                      hintStyle: TextStyle(color: Colors.grey.shade400),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.grey.shade200)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.grey.shade200)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFF97316), width: 2)),
                      contentPadding: const EdgeInsets.all(14),
                    ),
                    style: const TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      children: [
                        _checkboxTile('Tersedia Level Pedas', _hasSpicyLevel, (v) => setState(() => _hasSpicyLevel = v ?? false)),
                        _checkboxTile('Tersedia Panas / Dingin', _hasTempLevel, (v) => setState(() => _hasTempLevel = v ?? false)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Responsive buttons
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final saveButton = ElevatedButton(
                        onPressed: _isUploading ? null : () async {
                          if (_nameCtrl.text.isEmpty || _priceCtrl.text.isEmpty || _selectedCategoryId == null) return;

                          String imageUrl = _existingImageUrl;

                          // Upload new image if selected
                          if (_selectedImageBytes != null) {
                            setState(() => _isUploading = true);
                            try {
                              imageUrl = await ApiService.uploadMenuImage(_selectedImageBytes!, _selectedImageName ?? 'menu.jpg');
                            } catch (e) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: const Text('Gagal upload gambar'),
                                    backgroundColor: Colors.red,
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                );
                                setState(() => _isUploading = false);
                              }
                              return;
                            }
                            if (mounted) setState(() => _isUploading = false);
                          }

                          widget.onSave({
                            'name': _nameCtrl.text,
                            'categoryId': _selectedCategoryId,
                            'price': double.tryParse(_priceCtrl.text) ?? 0,
                            'description': _descCtrl.text,
                            'image': imageUrl,
                            'hasSpicyLevel': _hasSpicyLevel,
                            'hasTempLevel': _hasTempLevel,
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFF97316),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          elevation: 0,
                        ),
                        child: _isUploading
                            ? const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
                                  SizedBox(width: 10),
                                  Text('Mengupload gambar...', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                                ],
                              )
                            : const Text('Simpan Menu', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                      );

                      if (constraints.maxWidth < 300) {
                        return Column(
                          children: [
                            SizedBox(width: double.infinity, child: saveButton),
                            const SizedBox(height: 8),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton(
                                onPressed: () => Navigator.pop(context),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                  side: BorderSide(color: Colors.grey.shade300),
                                ),
                                child: const Text('Batal', style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF475569))),
                              ),
                            ),
                          ],
                        );
                      }

                      return Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(context),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                side: BorderSide(color: Colors.grey.shade300),
                              ),
                              child: const Text('Batal', style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF475569))),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(flex: 2, child: saveButton),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _categoryDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(14),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedCategoryId,
          isExpanded: true,
          items: widget.categories.map((c) {
            return DropdownMenuItem(value: c.id, child: Text(c.name, style: const TextStyle(fontSize: 14)));
          }).toList(),
          onChanged: (v) => setState(() => _selectedCategoryId = v),
        ),
      ),
    );
  }

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(text, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF475569))),
  );

  Widget _textField(TextEditingController ctrl, String hint, {TextInputType? keyboardType}) => TextField(
    controller: ctrl,
    keyboardType: keyboardType,
    decoration: InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey.shade400),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.grey.shade200)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.grey.shade200)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFF97316), width: 2)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    ),
    style: const TextStyle(fontSize: 14),
  );

  Widget _checkboxTile(String label, bool value, Function(bool?) onChanged) => Row(
    children: [
      Checkbox(
        value: value,
        onChanged: onChanged,
        activeColor: const Color(0xFFF97316),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),
      Expanded(
        child: Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF475569))),
      ),
    ],
  );
}
