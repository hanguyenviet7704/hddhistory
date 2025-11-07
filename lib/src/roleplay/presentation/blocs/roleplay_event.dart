part of '../../roleplay.dart';

@freezed
sealed class RoleplayEvent with _$RoleplayEvent {
  const factory RoleplayEvent.loadAllSections({@Default(false) bool isInit}) = _LoadAllSections;
  const factory RoleplayEvent.loadSection(String id) = _LoadSection;
  const factory RoleplayEvent.createSection(SectionEntity entity) = _CreateSection;
  const factory RoleplayEvent.updateSection(SectionEntity entity) = _UpdateSection;
  const factory RoleplayEvent.deleteSection(String id) = _DeleteSection;
}

