import 'package:mukzzi/src/features/quest/data/datasources/quest_remote_data_source.dart';
import 'package:mukzzi/src/features/quest/domain/entities/quest.dart';

abstract class QuestRepository {
  Future<List<Quest>> getQuests({String? period});
  Future<void> claimReward(String userQuestId);
}

class QuestRepositoryImpl implements QuestRepository {
  final QuestRemoteDataSource remoteDataSource;

  QuestRepositoryImpl(this.remoteDataSource);

  @override
  Future<List<Quest>> getQuests({String? period}) async {
    return await remoteDataSource.fetchQuests(period: period);
  }

  @override
  Future<void> claimReward(String userQuestId) async {
    await remoteDataSource.claimReward(userQuestId);
  }
}
