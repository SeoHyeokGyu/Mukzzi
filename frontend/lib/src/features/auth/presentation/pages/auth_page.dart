import 'package:flutter/material.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  bool _isLogin = true;
  late TextEditingController _emailController;
  late TextEditingController _passwordController;
  late TextEditingController _nicknameController;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
    _nicknameController = TextEditingController();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nicknameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 로고/타이틀
              Text(
                '먹찌',
                style: Theme.of(context).textTheme.displayLarge?.copyWith(
                      color: Colors.orange,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                '음식과 함께 성장하는 캐릭터',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.grey,
                    ),
              ),
              const SizedBox(height: 48),

              // 탭 선택
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _isLogin = true),
                      child: Column(
                        children: [
                          Text(
                            '로그인',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: _isLogin ? Colors.orange : Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 8),
                          if (_isLogin)
                            Container(
                              height: 3,
                              color: Colors.orange,
                            ),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _isLogin = false),
                      child: Column(
                        children: [
                          Text(
                            '회원가입',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: !_isLogin ? Colors.orange : Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 8),
                          if (!_isLogin)
                            Container(
                              height: 3,
                              color: Colors.orange,
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // 폼
              TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  hintText: '이메일',
                  prefixIcon: const Icon(Icons.email_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  hintText: '비밀번호',
                  prefixIcon: const Icon(Icons.lock_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              if (!_isLogin) ...[
                const SizedBox(height: 16),
                TextField(
                  controller: _nicknameController,
                  decoration: InputDecoration(
                    hintText: '닉네임 (2-12자)',
                    prefixIcon: const Icon(Icons.person_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 24),

              // 버튼
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {},
                  child: Text(_isLogin ? '로그인' : '회원가입'),
                ),
              ),
              const SizedBox(height: 16),

              // 소셜 로그인
              if (_isLogin) ...[
                Text(
                  '또는 소셜로 로그인',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _SocialButton(
                      emoji: '🍎',
                      label: 'Apple',
                      onPressed: () {},
                    ),
                    const SizedBox(width: 16),
                    _SocialButton(
                      emoji: '🔤',
                      label: 'Google',
                      onPressed: () {},
                    ),
                    const SizedBox(width: 16),
                    _SocialButton(
                      emoji: '💬',
                      label: 'Kakao',
                      onPressed: () {},
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SocialButton extends StatelessWidget {
  final String emoji;
  final String label;
  final VoidCallback onPressed;

  const _SocialButton({
    required this.emoji,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}
