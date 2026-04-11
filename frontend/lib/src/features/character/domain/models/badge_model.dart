import 'package:flutter/material.dart';

class BadgeModel {
  final String id;
  final String name;
  final String description;
  final String category; // 'meal' | 'attendance' | 'social'
  final IconData iconData;
  final bool isUnlocked;
  final String? unlockedAt; // ISO 8601
  final String condition;

  const BadgeModel({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.iconData,
    required this.isUnlocked,
    this.unlockedAt,
    required this.condition,
  });
}

const List<BadgeModel> mockBadges = [
  // 식사 (meal)
  BadgeModel(
    id: 'meal_001',
    name: '첫 걸음',
    description: '먹찌와의 첫 번째 식사를 기록했어요.',
    category: 'meal',
    iconData: Icons.restaurant,
    isUnlocked: true,
    unlockedAt: '2024-03-01T09:15:00Z',
    condition: '첫 번째 식사 기록',
  ),
  BadgeModel(
    id: 'meal_002',
    name: '삼시세끼',
    description: '하루도 빠짐없이 세 끼를 모두 기록한 날이 있어요.',
    category: 'meal',
    iconData: Icons.dining,
    isUnlocked: true,
    unlockedAt: '2024-03-05T21:30:00Z',
    condition: '하루에 아침·점심·저녁 3끼 모두 기록',
  ),
  BadgeModel(
    id: 'meal_003',
    name: '메뉴 탐험가',
    description: '다양한 음식을 골고루 도전하는 진정한 탐험가예요.',
    category: 'meal',
    iconData: Icons.explore,
    isUnlocked: false,
    condition: '서로 다른 메뉴 50종 기록',
  ),
  BadgeModel(
    id: 'meal_004',
    name: '밸런스 달인',
    description: '영양 밸런스를 7일 연속으로 지켜낸 균형의 달인이에요.',
    category: 'meal',
    iconData: Icons.balance,
    isUnlocked: false,
    condition: '영양 밸런스 목표 7일 연속 달성',
  ),
  BadgeModel(
    id: 'meal_005',
    name: '100끼 기록',
    description: '먹찌와 함께 100끼를 채웠어요. 믿음직한 파트너예요!',
    category: 'meal',
    iconData: Icons.emoji_events,
    isUnlocked: false,
    condition: '누적 식사 기록 100끼 달성',
  ),

  // 출석 (attendance)
  BadgeModel(
    id: 'att_001',
    name: '7일 연속',
    description: '일주일 동안 매일 먹찌를 찾아와 주었어요.',
    category: 'attendance',
    iconData: Icons.event_available,
    isUnlocked: true,
    unlockedAt: '2024-03-08T08:00:00Z',
    condition: '7일 연속 앱 접속 및 기록',
  ),
  BadgeModel(
    id: 'att_002',
    name: '30일 연속',
    description: '한 달 내내 먹찌 곁을 지켜준 든든한 파트너예요.',
    category: 'attendance',
    iconData: Icons.calendar_month,
    isUnlocked: false,
    condition: '30일 연속 앱 접속 및 기록',
  ),
  BadgeModel(
    id: 'att_003',
    name: '아침형 인간',
    description: '이른 아침에도 먹찌를 잊지 않는 성실한 유저예요.',
    category: 'attendance',
    iconData: Icons.wb_sunny,
    isUnlocked: false,
    condition: '오전 8시 이전 식사 기록 10회',
  ),

  // 소셜 (social)
  BadgeModel(
    id: 'soc_001',
    name: '첫 친구',
    description: '먹찌로 처음으로 친구를 사귀었어요.',
    category: 'social',
    iconData: Icons.person_add,
    isUnlocked: true,
    unlockedAt: '2024-03-10T14:22:00Z',
    condition: '첫 번째 친구 추가',
  ),
  BadgeModel(
    id: 'soc_002',
    name: '소셜 버터플라이',
    description: '넓은 인맥을 가진 먹찌 커뮤니티의 핵심 멤버예요.',
    category: 'social',
    iconData: Icons.groups,
    isUnlocked: false,
    condition: '친구 10명 추가',
  ),
  BadgeModel(
    id: 'soc_003',
    name: '방명록 스타',
    description: '친구들에게 따뜻한 응원을 많이 남겼어요.',
    category: 'social',
    iconData: Icons.comment,
    isUnlocked: false,
    condition: '친구 방명록에 응원 메시지 10회 작성',
  ),
  BadgeModel(
    id: 'soc_004',
    name: '먹찌 투어',
    description: '친구들의 먹찌를 부지런히 구경한 탐방가예요.',
    category: 'social',
    iconData: Icons.travel_explore,
    isUnlocked: false,
    condition: '친구 프로필 방문 20회',
  ),
];
