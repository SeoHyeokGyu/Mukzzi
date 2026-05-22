package usecase

import "github.com/SeoHyeokGyu/Mukzzi/backend/internal/domain"

// CalcAppearance 당일 섭취량과 목표치를 바탕으로 캐릭터 파츠 4종을 계산한다.
// intake가 nil이거나 MealCount == 0이면 당일 미기록으로 간주해 nil을 반환한다.
func CalcAppearance(intake *domain.DailyIntake, goal *domain.UserNutritionGoal) *domain.AppearanceChangedEvent {
	if intake == nil || intake.MealCount == 0 {
		return nil
	}

	goalKcal := float64(goal.DailyKcalTarget)
	if goalKcal == 0 {
		goalKcal = 2000
	}

	calorieRatio := intake.TotalCalories / goalKcal

	return &domain.AppearanceChangedEvent{
		BodyType:   calcBodyType(intake, calorieRatio),
		Muscle:     calcMuscle(intake, calorieRatio),
		SkinTone:   calcSkinTone(intake),
		Expression: calcExpression(intake, calorieRatio),
		Changed:    true,
	}
}

// calcBodyType 칼로리 충족률 기준 0~4
func calcBodyType(intake *domain.DailyIntake, calorieRatio float64) int {
	if calorieRatio < 0.5 {
		return 0
	}
	macroCal := intake.TotalCarbs*4 + intake.TotalProtein*4 + intake.TotalFat*9
	carbsRatio := 0.0
	if macroCal > 0 {
		carbsRatio = intake.TotalCarbs * 4 / macroCal * 100
	}
	switch {
	case calorieRatio >= 1.4 && carbsRatio >= 65:
		return 4
	case calorieRatio >= 1.1 || carbsRatio >= 65:
		return 3
	case calorieRatio >= 0.7:
		return 2
	default:
		return 1
	}
}

// calcMuscle 단백질 비율 기준 0~4
func calcMuscle(intake *domain.DailyIntake, calorieRatio float64) int {
	if calorieRatio < 0.5 {
		return 0
	}
	macroCal := intake.TotalCarbs*4 + intake.TotalProtein*4 + intake.TotalFat*9
	if macroCal == 0 {
		return 0
	}
	proteinRatio := intake.TotalProtein * 4 / macroCal * 100
	switch {
	case proteinRatio < 10:
		return 0
	case proteinRatio < 15:
		return 1
	case proteinRatio < 22:
		return 2
	case proteinRatio < 30 && calorieRatio >= 0.7:
		return 3
	case proteinRatio >= 30 && calorieRatio >= 0.7:
		return 4
	default:
		return 2
	}
}

// calcSkinTone 비타민 점수·식이섬유 달성률 기준 0~4
// VitaminScore는 0~100 스케일, 식이섬유 목표 25g 고정
func calcSkinTone(intake *domain.DailyIntake) int {
	const fiberTarget = 25.0

	vitaminRate := intake.VitaminScore
	fiberRate := intake.TotalFiber / fiberTarget * 100

	switch {
	case vitaminRate >= 80 && fiberRate >= 80:
		return 4
	case vitaminRate >= 60 && fiberRate >= 60:
		return 3
	case vitaminRate >= 40 || fiberRate >= 40:
		return 2
	case vitaminRate >= 20 || fiberRate >= 20:
		return 1
	default:
		return 0
	}
}

// calcExpression 3대 영양소 균형 편차 기준 0~4
// 권장 중심값: 탄수화물 60%, 단백질 17%, 지방 23%
func calcExpression(intake *domain.DailyIntake, calorieRatio float64) int {
	if calorieRatio < 0.5 {
		return 0
	}
	macroCal := intake.TotalCarbs*4 + intake.TotalProtein*4 + intake.TotalFat*9
	if macroCal == 0 {
		return 0
	}
	carbsRatio := intake.TotalCarbs * 4 / macroCal * 100
	proteinRatio := intake.TotalProtein * 4 / macroCal * 100
	fatRatio := intake.TotalFat * 9 / macroCal * 100

	deviation := absFloat(carbsRatio-60) + absFloat(proteinRatio-17) + absFloat(fatRatio-23)

	switch {
	case deviation < 6 && calorieRatio >= 0.7:
		return 4
	case deviation < 12 && calorieRatio >= 0.7:
		return 3
	case deviation < 18:
		return 2
	case deviation < 25:
		return 1
	default:
		return 0
	}
}

func absFloat(v float64) float64 {
	if v < 0 {
		return -v
	}
	return v
}
