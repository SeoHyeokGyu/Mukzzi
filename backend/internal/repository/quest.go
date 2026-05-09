package repository

import (
	"context"

	"gorm.io/gorm"

	"github.com/SeoHyeokGyu/Mukzzi/backend/internal/domain"
)

type questRepository struct {
	db *gorm.DB
}

func NewQuestRepository(db *gorm.DB) domain.QuestRepository {
	return &questRepository{db: db}
}

func (r *questRepository) GetByID(ctx context.Context, id int64) (*domain.QuestDefinition, error) {
	var q domain.QuestDefinition
	if err := r.db.WithContext(ctx).First(&q, id).Error; err != nil {
		return nil, err
	}
	return &q, nil
}

func (r *questRepository) GetActiveQuestsByUserID(ctx context.Context, userID int64) ([]domain.UserQuest, error) {
	var quests []domain.UserQuest
	// status가 PROGRESS 또는 COMPLETED(보상 미수령)인 퀘스트 조회
	if err := r.db.WithContext(ctx).
		Preload("Quest").
		Where("user_id = ? AND status IN ?", userID, []string{"PROGRESS", "COMPLETED"}).
		Find(&quests).Error; err != nil {
		return nil, err
	}
	return quests, nil
}

func (r *questRepository) GetQuestDefinitionByCode(ctx context.Context, code string) (*domain.QuestDefinition, error) {
	var q domain.QuestDefinition
	if err := r.db.WithContext(ctx).Where("code = ?", code).First(&q).Error; err != nil {
		return nil, err
	}
	return &q, nil
}

func (r *questRepository) UpdateUserQuest(ctx context.Context, uq *domain.UserQuest) error {
	return r.db.WithContext(ctx).Save(uq).Error
}

func (r *questRepository) CreateUserQuest(ctx context.Context, uq *domain.UserQuest) error {
	return r.db.WithContext(ctx).Create(uq).Error
}

func (r *questRepository) GetAvailableDailyQuests(ctx context.Context, limit int) ([]domain.QuestDefinition, error) {
	var quests []domain.QuestDefinition
	if err := r.db.WithContext(ctx).
		Where("type = ? AND is_active = ?", domain.QuestTypeDaily, true).
		Order("RANDOM()").
		Limit(limit).
		Find(&quests).Error; err != nil {
		return nil, err
	}
	return quests, nil
}

func (r *questRepository) GetAvailableQuestsByType(ctx context.Context, qType domain.QuestType) ([]domain.QuestDefinition, error) {
	var quests []domain.QuestDefinition
	if err := r.db.WithContext(ctx).
		Where("type = ? AND is_active = ?", qType, true).
		Find(&quests).Error; err != nil {
		return nil, err
	}
	return quests, nil
}

func (r *questRepository) DeleteQuestsByUserIDAndType(ctx context.Context, userID int64, qType domain.QuestType) error {
	// GORM Unscoped로 물리 삭제 (새로운 퀘스트 할당을 위해)
	return r.db.WithContext(ctx).Unscoped().
		Where("user_id = ? AND quest_id IN (SELECT id FROM quests WHERE type = ?)", userID, qType).
		Delete(&domain.UserQuest{}).Error
}

func (r *questRepository) GetUserQuestByID(ctx context.Context, id int64) (*domain.UserQuest, error) {
	var uq domain.UserQuest
	if err := r.db.WithContext(ctx).Preload("Quest").First(&uq, id).Error; err != nil {
		return nil, err
	}
	return &uq, nil
}
