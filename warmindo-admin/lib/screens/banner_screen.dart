import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import '../config.dart';

class BannerScreen extends StatefulWidget {
  const BannerScreen({super.key});

  @override
  State<BannerScreen> createState() => _BannerScreenState();
}

class _BannerScreenState extends State<BannerScreen> {
  List<Map<String, dynamic>> _banners = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadBanners();
  }

  Future<void> _loadBanners() async {
    setState(() => _loading = true);
    try {
      final res = await http.get(Uri.parse('${AppConfig.apiBaseUrl}/banners/all'));
      if (res.statusCode == 200) {
        final List<dynamic> data = json.decode(res.body);
        setState(() => _banners = data.cast<Map<String, dynamic>>());
      }
    } catch (e) {
      debugPrint('Error loading banners: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _createBannerWithFile(String title, String subtitle, File imageFile) async {
    try {
      final uri = Uri.parse('${AppConfig.apiBaseUrl}/banners');
      final request = http.MultipartRequest('POST', uri);
      request.fields['title'] = title;
      request.fields['subtitle'] = subtitle;
      request.fields['sortOrder'] = _banners.length.toString();
      request.files.add(await http.MultipartFile.fromPath('image', imageFile.path));

      final response = await request.send();
      if (response.statusCode == 200) {
        _loadBanners();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('✅ Banner berhasil ditambahkan'),
              backgroundColor: const Color(0xFFF97316),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('❌ Gagal upload banner'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error creating banner: $e');
    }
  }

  Future<void> _toggleBanner(String id, bool currentStatus) async {
    try {
      await http.put(
        Uri.parse('${AppConfig.apiBaseUrl}/banners/$id'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'isActive': !currentStatus}),
      );
      _loadBanners();
    } catch (e) {
      debugPrint('Error toggling banner: $e');
    }
  }

  Future<void> _deleteBanner(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Hapus Banner?', style: TextStyle(fontWeight: FontWeight.w700)),
        content: const Text('Banner yang dihapus tidak bisa dikembalikan.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await http.delete(Uri.parse('${AppConfig.apiBaseUrl}/banners/$id'));
        _loadBanners();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('🗑️ Banner dihapus'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
      } catch (e) {
        debugPrint('Error deleting banner: $e');
      }
    }
  }

  void _showAddDialog() {
    final titleCtrl = TextEditingController();
    final subtitleCtrl = TextEditingController();
    File? selectedImage;
    String? selectedImageName;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF7ED),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.add_photo_alternate_rounded, color: Color(0xFFF97316), size: 22),
              ),
              const SizedBox(width: 12),
              const Text('Tambah Banner', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Image Picker
                GestureDetector(
                  onTap: () async {
                    final picker = ImagePicker();
                    final picked = await picker.pickImage(
                      source: ImageSource.gallery,
                      maxWidth: 1200,
                      maxHeight: 600,
                      imageQuality: 85,
                    );
                    if (picked != null) {
                      setDialogState(() {
                        selectedImage = File(picked.path);
                        selectedImageName = picked.name;
                      });
                    }
                  },
                  child: Container(
                    height: 140,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF7ED),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: selectedImage != null ? const Color(0xFFF97316) : const Color(0xFFFED7AA),
                        width: 2,
                        strokeAlign: BorderSide.strokeAlignInside,
                      ),
                    ),
                    child: selectedImage != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                Image.file(selectedImage!, fit: BoxFit.cover),
                                Positioned(
                                  bottom: 0,
                                  left: 0,
                                  right: 0,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.bottomCenter,
                                        end: Alignment.topCenter,
                                        colors: [Colors.black.withOpacity(0.6), Colors.transparent],
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.check_circle, color: Colors.white, size: 16),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Text(
                                            selectedImageName ?? 'Gambar dipilih',
                                            style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        const Icon(Icons.swap_horiz_rounded, color: Colors.white, size: 18),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.cloud_upload_outlined, size: 40, color: const Color(0xFFF97316).withOpacity(0.6)),
                              const SizedBox(height: 8),
                              const Text('Tap untuk upload gambar', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFFF97316))),
                              const SizedBox(height: 4),
                              Text('JPG, PNG, WebP (Max 5MB)', style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: titleCtrl,
                  decoration: InputDecoration(
                    labelText: 'Judul Banner',
                    hintText: 'Contoh: Promo Spesial',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFF97316), width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: subtitleCtrl,
                  decoration: InputDecoration(
                    labelText: 'Subtitle (Opsional)',
                    hintText: 'Contoh: Diskon 20% semua mie',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFF97316), width: 2),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Batal', style: TextStyle(color: Colors.grey.shade600)),
            ),
            FilledButton.icon(
              onPressed: () {
                if (titleCtrl.text.isNotEmpty && selectedImage != null) {
                  Navigator.pop(ctx);
                  _createBannerWithFile(titleCtrl.text, subtitleCtrl.text, selectedImage!);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('⚠️ Judul dan gambar wajib diisi'),
                      backgroundColor: Colors.amber.shade700,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  );
                }
              },
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Tambah'),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFF97316),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build full image URL for display
  String _getImageUrl(String imageUrl) {
    if (imageUrl.startsWith('http')) return imageUrl;
    // Local upload — prepend server base URL
    final base = AppConfig.apiBaseUrl.replaceAll('/api', '');
    return '$base$imageUrl';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: CustomScrollView(
        slivers: [
          // Header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Banner Promo',
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Color(0xFF1E293B)),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${_banners.length} banner • ${_banners.where((b) => b['isActive'] == true).length} aktif',
                        style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                      ),
                    ],
                  ),
                  FilledButton.icon(
                    onPressed: _showAddDialog,
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text('Tambah'),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFF97316),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Banner List
          if (_loading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator(color: Color(0xFFF97316))),
            )
          else if (_banners.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.photo_library_outlined, size: 64, color: Colors.grey.shade300),
                    const SizedBox(height: 16),
                    Text('Belum ada banner', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.grey.shade400)),
                    const SizedBox(height: 8),
                    Text('Tambahkan banner promo untuk ditampilkan\ndi halaman customer',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13, color: Colors.grey.shade400)),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final banner = _banners[index];
                    final isActive = banner['isActive'] == true;
                    final imageUrl = _getImageUrl(banner['imageUrl'] ?? '');

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: isActive ? const Color(0xFFFED7AA) : Colors.grey.shade200),
                          boxShadow: [
                            BoxShadow(
                              color: isActive ? const Color(0xFFF97316).withOpacity(0.08) : Colors.black.withOpacity(0.03),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Banner Image
                            ClipRRect(
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                              child: Stack(
                                children: [
                                  Image.network(
                                    imageUrl,
                                    height: 140,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Container(
                                      height: 140,
                                      color: Colors.grey.shade100,
                                      child: Icon(Icons.broken_image_rounded, size: 40, color: Colors.grey.shade300),
                                    ),
                                  ),
                                  if (!isActive)
                                    Container(
                                      height: 140,
                                      color: Colors.black.withOpacity(0.4),
                                      child: const Center(
                                        child: Text('NONAKTIF', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14, letterSpacing: 2)),
                                      ),
                                    ),
                                ],
                              ),
                            ),

                            // Banner Info
                            Padding(
                              padding: const EdgeInsets.all(14),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          banner['title'] ?? 'Untitled',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 15,
                                            color: isActive ? const Color(0xFF1E293B) : Colors.grey,
                                          ),
                                        ),
                                        if (banner['subtitle'] != null && banner['subtitle'].isNotEmpty)
                                          Padding(
                                            padding: const EdgeInsets.only(top: 3),
                                            child: Text(
                                              banner['subtitle'],
                                              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  // Toggle Active
                                  Switch(
                                    value: isActive,
                                    activeColor: const Color(0xFFF97316),
                                    onChanged: (_) => _toggleBanner(banner['id'], isActive),
                                  ),
                                  // Delete
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline_rounded, color: Colors.red, size: 20),
                                    onPressed: () => _deleteBanner(banner['id']),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  childCount: _banners.length,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
