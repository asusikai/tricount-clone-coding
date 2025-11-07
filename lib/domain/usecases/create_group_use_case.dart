import '../repositories/group_repository.dart';

/// 그룹 생성 UseCase
class CreateGroupUseCase {
  CreateGroupUseCase(this._repository);

  final GroupRepository _repository;

  /// 그룹 생성
  /// 
  /// [name] 그룹 이름
  /// [baseCurrency] 기본 통화 (예: 'KRW', 'USD')
  /// 
  /// 반환: 생성된 그룹 ID
  Future<String> call({
    required String name,
    required String baseCurrency,
  }) =>
      _repository.createGroup(
        name: name,
        baseCurrency: baseCurrency,
      );
}

