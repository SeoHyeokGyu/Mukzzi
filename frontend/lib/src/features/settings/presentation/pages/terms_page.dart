import 'package:flutter/material.dart';
import '../../../../core/widgets/gradient_scaffold.dart';

class TermsPage extends StatelessWidget {
  const TermsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return GradientScaffold(
      appBar: AppBar(title: const Text('이용약관')),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: _TermsContent(),
      ),
    );
  }
}

class _TermsContent extends StatelessWidget {
  const _TermsContent();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('이용약관', style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Text('최종 수정일: 2025년 1월 1일', style: textTheme.bodySmall),
        const SizedBox(height: 24),
        const _Section(
          title: '제1조 (목적)',
          body: '이 약관은 먹찌(이하 "서비스")가 제공하는 모바일 애플리케이션 서비스의 이용 조건 및 절차, '
              '이용자와 서비스 간의 권리·의무 및 책임사항을 규정함을 목적으로 합니다.',
        ),
        const _Section(
          title: '제2조 (서비스 이용)',
          body: '• 서비스는 만 14세 이상의 이용자만 이용할 수 있습니다.\n'
              '• 이용자는 서비스 이용 시 실명 또는 닉네임으로 활동할 수 있습니다.\n'
              '• 타인의 정보를 도용하거나 허위 정보를 제공하는 행위는 금지됩니다.',
        ),
        const _Section(
          title: '제3조 (서비스 제공 및 변경)',
          body: '서비스는 식사 기록, 영양 분석, 캐릭터 성장 등의 기능을 제공합니다. '
              '서비스의 내용은 운영상 또는 기술상 필요에 의해 변경될 수 있으며, '
              '변경 시 사전에 공지합니다.',
        ),
        const _Section(
          title: '제4조 (이용자 의무)',
          body: '이용자는 다음 행위를 하여서는 안 됩니다.\n\n'
              '• 타인의 개인정보 도용\n'
              '• 서비스의 정상적인 운영 방해\n'
              '• 불법적이거나 부당한 콘텐츠 게시\n'
              '• 서비스를 통한 상업적 활동',
        ),
        const _Section(
          title: '제5조 (서비스 중단)',
          body: '서비스는 시스템 점검, 천재지변, 기술적 장애 등의 사유로 일시적으로 중단될 수 있습니다. '
              '이 경우 서비스는 사전 또는 사후에 공지합니다.',
        ),
        const _Section(
          title: '제6조 (면책조항)',
          body: '서비스는 이용자가 기록한 식사 정보의 정확성에 대해 보장하지 않으며, '
              '제공되는 영양 정보는 참고용으로만 활용하시기 바랍니다.',
        ),
        const _Section(
          title: '제7조 (준거법)',
          body: '이 약관은 대한민국 법령에 따라 해석되며, 분쟁 발생 시 관할 법원은 서울중앙지방법원으로 합니다.',
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
