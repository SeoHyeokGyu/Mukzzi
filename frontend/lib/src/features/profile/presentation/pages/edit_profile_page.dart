import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/gradient_scaffold.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/models/user_model.dart';
import '../providers/user_provider.dart';

class EditProfilePage extends ConsumerStatefulWidget {
  const EditProfilePage({super.key});

  @override
  ConsumerState<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends ConsumerState<EditProfilePage> {
  late TextEditingController _nicknameController;
  late TextEditingController _emailController;
  late TextEditingController _passwordController;
  late TextEditingController _confirmPasswordController;
  final Set<String> _selectedAllergies = {};
  final List<String> _allergenList = const [
    '우유', '계란', '밀', '대두', '땅콩', '새우', '게', '조개류', '생선', '돼지고기', '토마토', '복숭아'
  ];

  @override
  void initState() {
    super.initState();
    final user = ref.read(userProvider).user;
    _nicknameController = TextEditingController(text: user?.nickname);
    _emailController = TextEditingController(text: user?.email);
    _passwordController = TextEditingController();
    _confirmPasswordController = TextEditingController();
    if (user != null && user.allergies.isNotEmpty) {
      _selectedAllergies.addAll(user.allergies.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty));
    }
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_passwordController.text.isNotEmpty &&
        _passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('비밀번호가 일치하지 않습니다.')),
      );
      return;
    }

    final user = ref.read(userProvider).user;
    if (user == null) return;

    final request = UserUpdateRequest(
      nickname: _nicknameController.text,
      email: _emailController.text,
      password: _passwordController.text.isEmpty ? null : _passwordController.text,
      allergies: _selectedAllergies.join(','),
    );

    final success = await ref.read(userProvider.notifier).updateProfile(
          request,
        );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('정보가 수정되었습니다.')),
      );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final userState = ref.watch(userProvider);

    return GradientScaffold(
      appBar: AppBar(title: const Text('프로필 편집')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('닉네임', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            TextField(
              controller: _nicknameController,
              decoration: const InputDecoration(
                hintText: '닉네임을 입력하세요',
              ),
            ),
            const SizedBox(height: 20),
            Text('이메일', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                hintText: '이메일을 입력하세요',
              ),
            ),
            const SizedBox(height: 32),
            const Divider(),
            const SizedBox(height: 32),
            Text('새 비밀번호 (변경 시에만 입력)', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                hintText: '새 비밀번호',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _confirmPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                hintText: '비밀번호 확인',
              ),
            ),
            const SizedBox(height: 32),
            const Divider(),
            const SizedBox(height: 32),
            Text('알레르기 정보', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            Text(
              '해당하는 알레르기 유발 성분을 선택해 주세요.',
              style: TextStyle(fontSize: 13, color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.6)),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _allergenList.map((allergen) {
                final isSelected = _selectedAllergies.contains(allergen);
                final primaryColor =
                    Theme.of(context).extension<AppColorTokens>()!.primary;
                return FilterChip(
                  label: Text(allergen),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedAllergies.add(allergen);
                      } else {
                        _selectedAllergies.remove(allergen);
                      }
                    });
                  },
                  selectedColor: primaryColor.withValues(alpha: 0.15),
                  checkmarkColor: primaryColor,
                  labelStyle: TextStyle(
                    color: isSelected ? primaryColor : null,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 48),
            if (userState.error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  userState.error!,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            AppGradientButton(
              label: '저장하기',
              isLoading: userState.isLoading,
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }
}
