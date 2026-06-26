import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/gradient_scaffold.dart';
import '../../../../core/widgets/app_button.dart';
import '../providers/auth_provider.dart';

class AuthPage extends ConsumerStatefulWidget {
  const AuthPage({super.key});

  @override
  ConsumerState<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends ConsumerState<AuthPage> {
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

  Future<void> _submit() async {
    if (_isLogin) {
      final success = await ref.read(authProvider.notifier).login(
            _emailController.text,
            _passwordController.text,
          );
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('반가워요! 로그인이 완료되었습니다.'),
            backgroundColor: AppColors.orange,
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 2),
          ),
        );
        context.go('/home');
      }
    } else {
      final success = await ref.read(authProvider.notifier).register(
            _emailController.text.split('@')[0],
            _emailController.text,
            _passwordController.text,
            _nicknameController.text.isEmpty ? null : _nicknameController.text,
          );
      
      if (success && mounted) {
        // 회원가입 성공 시 알림 다이얼로그 표시 (절대 누락 안 됨)
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Text('🎉 환영합니다!'),
            content: const Text('회원가입이 완료되었습니다.\n로그인 후 먹찌와 함께 시작해보세요!'),
            actions: [
              FilledButton(
                onPressed: () {
                  Navigator.pop(context);
                  setState(() => _isLogin = true);
                },
                child: const Text('로그인하러 가기'),
              ),
            ],
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AuthState>(authProvider, (previous, next) {
      if (next.error != null && next.error != previous?.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error!),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    });

    final authState = ref.watch(authProvider);
    final d = MediaQuery.of(context).disableAnimations ? Duration.zero : null;

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
                  .fadeIn(duration: d ?? 600.ms)
                  .scale(begin: const Offset(0.8, 0.8), duration: d ?? 600.ms),
              const SizedBox(height: 8),
              Text(
                '음식과 함께 성장하는 캐릭터',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context).extension<AppColorTokens>()!.textSub,
                    ),
              )
                  .animate()
                  .fadeIn(delay: d ?? 200.ms, duration: d ?? 400.ms),
              const SizedBox(height: 48),

              // 탭 선택
              Row(
                children: [
                  Expanded(
                    child: Semantics(
                      label: '로그인 탭',
                      selected: _isLogin,
                      button: true,
                      child: GestureDetector(
                        onTap: () => setState(() => _isLogin = true),
                        child: Column(
                          children: [
                            Text(
                              '로그인',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: _isLogin ? AppColors.orange : Theme.of(context).extension<AppColorTokens>()!.textSub,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              height: 3,
                              color: _isLogin ? AppColors.orange : Colors.transparent,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Semantics(
                      label: '회원가입 탭',
                      selected: !_isLogin,
                      button: true,
                      child: GestureDetector(
                        onTap: () => setState(() => _isLogin = false),
                        child: Column(
                          children: [
                            Text(
                              '회원가입',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: !_isLogin ? AppColors.orange : Theme.of(context).extension<AppColorTokens>()!.textSub,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              height: 3,
                              color: !_isLogin ? AppColors.orange : Colors.transparent,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              )
                  .animate()
                  .fadeIn(delay: d ?? 300.ms, duration: d ?? 400.ms),
              const SizedBox(height: 32),

              // 폼
              TextField(
                controller: _emailController,
                keyboardType: _isLogin ? TextInputType.text : TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: _isLogin ? '이메일 또는 아이디' : '이메일',
                  hintText: _isLogin ? 'example@email.com 또는 아이디' : 'example@email.com',
                  prefixIcon: const Icon(Icons.email_outlined),
                ),
              )
                  .animate()
                  .fadeIn(delay: d ?? 400.ms, duration: d ?? 300.ms)
                  .slideX(begin: -0.2, end: 0, duration: d ?? 300.ms),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                obscureText: true,
                textInputAction: _isLogin ? TextInputAction.done : TextInputAction.next,
                onSubmitted: (_) => _submit(),
                decoration: const InputDecoration(
                  labelText: '비밀번호',
                  prefixIcon: Icon(Icons.lock_outlined),
                ),
              )
                  .animate()
                  .fadeIn(delay: d ?? 450.ms, duration: d ?? 300.ms)
                  .slideX(begin: -0.2, end: 0, duration: d ?? 300.ms),
              if (!_isLogin) ...[
                const SizedBox(height: 16),
                TextField(
                  controller: _nicknameController,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _submit(),
                  decoration: const InputDecoration(
                    labelText: '닉네임',
                    hintText: '2-12자',
                    prefixIcon: Icon(Icons.person_outlined),
                  ),
                )
                    .animate()
                    .fadeIn(delay: d ?? 500.ms, duration: d ?? 300.ms)
                    .slideX(begin: -0.2, end: 0, duration: d ?? 300.ms),
              ],
              const SizedBox(height: 24),

              // 버튼
              AppGradientButton(
                label: _isLogin ? '로그인' : '회원가입',
                isLoading: authState.isLoading,
                onPressed: _submit,
              )
                  .animate()
                  .fadeIn(delay: d ?? 550.ms, duration: d ?? 300.ms),
              const SizedBox(height: 16),

              // 소셜 로그인
              if (_isLogin) ...[
                Text(
                  '또는 소셜로 로그인',
                  style: Theme.of(context).textTheme.bodySmall,
                )
                    .animate()
                    .fadeIn(delay: d ?? 600.ms, duration: d ?? 300.ms),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _AppleButton(onPressed: () {})
                        .animate()
                        .fadeIn(delay: d ?? 650.ms, duration: d ?? 300.ms)
                        .scale(begin: const Offset(0.8, 0.8), duration: d ?? 300.ms),
                    const SizedBox(width: 16),
                    _GoogleButton(onPressed: () {})
                        .animate()
                        .fadeIn(delay: d ?? 700.ms, duration: d ?? 300.ms)
                        .scale(begin: const Offset(0.8, 0.8), duration: d ?? 300.ms),
                    const SizedBox(width: 16),
                    _KakaoButton(onPressed: () {})
                        .animate()
                        .fadeIn(delay: d ?? 750.ms, duration: d ?? 300.ms)
                        .scale(begin: const Offset(0.8, 0.8), duration: d ?? 300.ms),
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
  final VoidCallback onPressed;
  final Widget icon;
  final String label;
  final Color backgroundColor;
  final Color labelColor;
  final Color borderColor;

  const _SocialButton({
    required this.onPressed,
    required this.icon,
    required this.label,
    required this.backgroundColor,
    required this.labelColor,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 80,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            icon,
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(fontSize: 11, color: labelColor, fontWeight: FontWeight.w500),
            ),
          ],
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
    return _SocialButton(
      onPressed: onPressed,
      label: 'Apple',
      backgroundColor: AppColors.appleBlack,
      labelColor: Colors.white,
      borderColor: AppColors.appleBlack,
      icon: const Icon(Icons.apple, color: Colors.white, size: 26),
    );
  }
}

class _GoogleButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _GoogleButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return _SocialButton(
      onPressed: onPressed,
      label: 'Google',
      backgroundColor: AppColors.googleWhite,
      labelColor: const Color(0xFF444444),
      borderColor: const Color(0xFFDDDDDD),
      icon: const _GoogleLogo(),
    );
  }
}

class _GoogleLogo extends StatelessWidget {
  const _GoogleLogo();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 26,
      height: 26,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Text(
            'G',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Color(0xFF4285F4),
              height: 1,
            ),
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
    return _SocialButton(
      onPressed: onPressed,
      label: 'Kakao',
      backgroundColor: AppColors.kakaoYellow,
      labelColor: const Color(0xFF191919),
      borderColor: AppColors.kakaoYellow,
      icon: const Icon(Icons.chat_bubble, color: Color(0xFF191919), size: 24),
    );
  }
}
