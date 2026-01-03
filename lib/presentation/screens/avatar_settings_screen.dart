import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:street/presentation/providers/auth_provider.dart';

class AvatarSettingsScreen extends StatefulWidget {
  const AvatarSettingsScreen({super.key});

  @override
  State<AvatarSettingsScreen> createState() => _AvatarSettingsScreenState();
}

class _AvatarSettingsScreenState extends State<AvatarSettingsScreen> {
  String? _selectedAvatar;
  bool _isUpdating = false;
  final ImagePicker _picker = ImagePicker();

  final List<String> _avatarStyles = [
    'avataaars',
    'big-smile',
    'bottts',
    'fun-emoji',
    'icons',
    'initials',
    'lorelei',
    'micah',
    'miniavs',
    'open-peeps',
    'personas',
    'pixel-art',
  ];

  @override
  void initState() {
    super.initState();
    final auth = Provider.of<AuthProvider>(context, listen: false);
    _selectedAvatar = auth.avatar ?? _generateRandomAvatar('avataaars', auth.userId);
  }

  String _generateRandomAvatar(String style, String? userId) {
    final id = userId ?? DateTime.now().millisecondsSinceEpoch.toString();
    return 'https://api.dicebear.com/7.x/$style/png?seed=$id&size=150';
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    
    return Scaffold(
      backgroundColor: const Color(0xFF0F0C29),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => context.canPop() ? context.pop() : context.go('/profile'),
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
        ),
        title: const Text('Avatar Settings', style: TextStyle(color: Colors.white)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Current Avatar
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF302B63), Color(0xFF24243E)],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.cyan.withOpacity(0.3)),
              ),
              child: Column(
                children: [
                  const Text('Current Avatar', style: TextStyle(color: Colors.white70, fontSize: 16)),
                  const SizedBox(height: 16),
                  CircleAvatar(
                    radius: 60,
                    backgroundImage: NetworkImage(_selectedAvatar ?? ''),
                    onBackgroundImageError: (_, __) {},
                  ),
                  const SizedBox(height: 16),
                  Text(auth.username ?? 'Player', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // Avatar Styles
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.3),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Choose Avatar Style', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1,
                    ),
                    itemCount: _avatarStyles.length,
                    itemBuilder: (context, index) {
                      final style = _avatarStyles[index];
                      final avatarUrl = _generateRandomAvatar(style, auth.userId);
                      
                      return GestureDetector(
                        onTap: () => setState(() => _selectedAvatar = avatarUrl),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _selectedAvatar == avatarUrl ? Colors.cyan : Colors.white24,
                              width: _selectedAvatar == avatarUrl ? 3 : 1,
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              avatarUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                color: Colors.grey[800],
                                child: const Icon(Icons.person, color: Colors.white54),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _pickImageFromGallery,
                    icon: const Icon(Icons.photo_library),
                    label: const Text('Upload Photo'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple,
                      padding: const EdgeInsets.all(16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _generateNewRandomAvatar,
                    icon: const Icon(Icons.shuffle),
                    label: const Text('Random'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      padding: const EdgeInsets.all(16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 30),

            // Save Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isUpdating ? null : _updateAvatar,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.all(16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isUpdating
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Save Avatar', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _generateNewRandomAvatar() {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final randomSeed = DateTime.now().millisecondsSinceEpoch.toString();
    final newAvatar = 'https://api.dicebear.com/7.x/avataaars/png?seed=$randomSeed&size=150';
    setState(() => _selectedAvatar = newAvatar);
  }

  Future<void> _pickImageFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        // For now, we'll use a placeholder. In a real app, you'd upload to your server
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Custom image upload will be implemented with server integration'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking image: $e')),
      );
    }
  }

  Future<void> _updateAvatar() async {
    if (_selectedAvatar == null) return;
    
    setState(() => _isUpdating = true);
    
    final auth = Provider.of<AuthProvider>(context, listen: false);

    try {
      // Update local auth provider directly
      await auth.updateAvatar(_selectedAvatar!);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Avatar updated successfully!'), backgroundColor: Colors.green),
      );
      
      if (context.canPop()) {
        context.pop();
      } else {
        context.go('/profile');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating avatar: $e')),
      );
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }
}