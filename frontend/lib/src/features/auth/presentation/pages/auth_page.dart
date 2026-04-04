import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/gradient_scaffold.dart';
import '../../../../core/widgets/app_button.dart';

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
    return GradientScaffold(
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
                      color: AppColors.orange,
                      fontWeight: FontWeight.bold,
                    ),
              )
                  .animate()
                  .fadeIn(duration: 600.ms)
                  .scale(begin: const Offset(0.8, 0.8), duration: 600.ms),
              const SizedBox(height: 8),
              Text(
                '음식과 함께 성장하는 캐릭터',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              )
                  .animate()
                  .fadeIn(delay: 200.ms, duration: 400.ms),
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
                              color:
                                  _isLogin ? AppColors.orange : AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          if (_isLogin)
                            Container(
                              height: 3,
                              color: AppColors.orange,
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
                              color:
                                  !_isLogin ? AppColors.orange : AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          if (!_isLogin)
                            Container(
                              height: 3,
                              color: AppColors.orange,
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              )
                  .animate()
                  .fadeIn(delay: 300.ms, duration: 400.ms),
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
              )
                  .animate()
                  .fadeIn(delay: 400.ms, duration: 300.ms)
                  .slideX(begin: -0.2, end: 0, duration: 300.ms),
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
              )
                  .animate()
                  .fadeIn(delay: 450.ms, duration: 300.ms)
                  .slideX(begin: -0.2, end: 0, duration: 300.ms),
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
                )
                    .animate()
                    .fadeIn(delay: 500.ms, duration: 300.ms)
                    .slideX(begin: -0.2, end: 0, duration: 300.ms),
              ],
              const SizedBox(height: 24),

              // 버튼
              AppGradientButton(
                label: _isLogin ? '로그인' : '회원가입',
                onPressed: () {},
              )
                  .animate()
                  .fadeIn(delay: 550.ms, duration: 300.ms),
              const SizedBox(height: 16),

              // 소셜 로그인
              if (_isLogin) ...[
                Text(
                  '또는 소셜로 로그인',
                  style: Theme.of(context).textTheme.bodySmall,
                )
                    .animate()
                    .fadeIn(delay: 600.ms, duration: 300.ms),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _AppleButton(onPressed: () {})
                        .animate()
                        .fadeIn(delay: 650.ms, duration: 300.ms)
                        .scale(begin: const Offset(0.8, 0.8), duration: 300.ms),
                    const SizedBox(width: 16),
                    _GoogleButton(onPressed: () {})
                        .animate()
                        .fadeIn(delay: 700.ms, duration: 300.ms)
                        .scale(begin: const Offset(0.8, 0.8), duration: 300.ms),
                    const SizedBox(width: 16),
                    _KakaoButton(onPressed: () {})
                        .animate()
                        .fadeIn(delay: 750.ms, duration: 300.ms)
                        .scale(begin: const Offset(0.8, 0.8), duration: 300.ms),
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

class _AppleButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _AppleButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: AppColors.appleBlack,
        side: const BorderSide(color: AppColors.appleBlack),
      ),
      child: const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('🍎', style: TextStyle(fontSize: 24)),
          SizedBox(height: 4),
          Text(
            'Apple',
            style: TextStyle(fontSize: 12, color: Colors.white),
          ),
        ],
      ),
    );
  }
}

class _GoogleButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _GoogleButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: AppColors.googleWhite,
        side: const BorderSide(color: Color(0xFFDDDDDD)),
      ),
      child: const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('🔤', style: TextStyle(fontSize: 24)),
          SizedBox(height: 4),
          Text(
            'Google',
            style: TextStyle(fontSize: 12, color: Colors.black),
          ),
        ],
      ),
    );
  }
}

class _KakaoButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _KakaoButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: AppColors.kakaoYellow,
        side: const BorderSide(color: AppColors.kakaoYellow),
      ),
      child: const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('💬', style: TextStyle(fontSize: 24)),
          SizedBox(height: 4),
          Text(
            'Kakao',
            style: TextStyle(fontSize: 12, color: Colors.black),
          ),
        ],
      ),
    );
  }
}
