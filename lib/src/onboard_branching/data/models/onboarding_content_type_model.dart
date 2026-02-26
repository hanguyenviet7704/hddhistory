part of '../../onboard_branching.dart';

enum OnboardingContentType {
  @JsonValue('fact')
  fact,
  @JsonValue('activation')
  activation,
  @JsonValue('branch')
  branch,
  @JsonValue('fixed')
  fixed,
  @JsonValue('person_admire')
  personAdmire,
  @JsonValue('unknown')
  unknown,
}
