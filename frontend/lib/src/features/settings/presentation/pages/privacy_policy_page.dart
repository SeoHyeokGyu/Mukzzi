import 'package:flutter/material.dart';
import '../../../../core/widgets/gradient_scaffold.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return GradientScaffold(
      appBar: AppBar(title: const Text('개인정보처리방침')),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: _PolicyContent(),
      ),
    );
  }
}

class _PolicyContent extends StatelessWidget {
  const _PolicyContent();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('개인정보처리방침', style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Text('최종 수정일: 2025년 1월 1일', style: textTheme.bodySmall),
        const SizedBox(height: 24),
        const _Section(
          title: '1. 수집하는 개인정보',
          body: '먹찌 서비스는 회원가입 및 서비스 이용 과정에서 아래와 같은 개인정보를 수집합니다.\n\n'
              '• 필수: 이메일 주소, 닉네임\n'
              '• 서비스 이용 중 생성되는 정보: 식사 기록, 앱 사용 이력',
        ),
        const _Section(
          title: '2. 개인정보의 이용 목적',
          body: '수집한 개인정보는 다음의 목적을 위해 이용합니다.\n\n'
              '• 서비스 제공 및 계정 관리\n'
              '• 식사 기록 및 건강 데이터 분석\n'
              '• 서비스 개선을 위한 통계 분석',
        ),
        const _Section(
          title: '3. 개인정보의 보유 및 이용 기간',
          body: '이용자의 개인정보는 서비스 이용 기간 동안 보유하며, 회원 탈퇴 시 즉시 삭제합니다. '
              '단, 관계 법령에 의거하여 보존할 필요가 있는 경우 해당 기간 동안 보관합니다.',
        ),
        const _Section(
          title: '4. 개인정보의 제3자 제공',
          body: '먹찌는 이용자의 개인정보를 원칙적으로 외부에 제공하지 않습니다. '
              '다만, 이용자의 동의가 있거나 법령의 규정에 의한 경우에는 예외로 합니다.',
        ),
        const _Section(
          title: '5. 이용자의 권리',
          body: '이용자는 언제든지 자신의 개인정보를 조회하거나 수정할 수 있으며, '
              '개인정보의 삭제 및 처리 정지를 요청할 수 있습니다.',
        ),
        const _Section(
          title: '6. 문의처',
          body: '개인정보 처리에 관한 문의사항은 아래로 연락 주시기 바랍니다.\n\n'
              '이메일: privacy@mukzzi.app',
        ),
        const SizedBox(height: 32),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final String body;
  const _Section({required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text(body, style: textTheme.bodyMedium?.copyWith(height: 1.6)),
        ],
      ),
    );
  }
}
