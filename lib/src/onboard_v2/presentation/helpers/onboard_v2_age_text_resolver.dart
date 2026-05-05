part of '../../onboard_v2.dart';

abstract final class OnboardV2AgeTextResolver {
  static String resolve(OnboardOptionEntity option) {
    final label = option.label.text.trim();
    if (label.isNotEmpty) return label;

    final title = option.title.text.trim();
    if (title.isNotEmpty) return title;

    final trackingLabel = option.trackingLabel.trim();
    if (trackingLabel.isNotEmpty) return trackingLabel;

    return option.id.toString();
  }
}
