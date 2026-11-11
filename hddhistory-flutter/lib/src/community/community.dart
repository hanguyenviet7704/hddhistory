library;

//* Dart imports
import 'dart:math' as math;
// Prefixed: retrofit exports a `Path` annotation that shadows dart:ui's Path,
// which the comment-thread rail painter needs.
import 'dart:ui' as ui;

//* Single project import
import 'package:hddhistory/hddhistory.dart';

//* Package imports
import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart' hide State;
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';
// Pinch/pan/swipe arbitration for the full-screen picture viewer — see
// `community_image_viewer.dart` for why this rather than InteractiveViewer.
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:retrofit/retrofit.dart';
// Chat needs scroll-to-INDEX: a jump to a pinned line has to reach a bubble
// whose height nobody knows and which may not be built yet.
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

//* Data Layer - Models, Datasources, Repositories
part 'data/community_exception.dart';
part 'data/models/community_model.dart';
part 'data/datasources/remote/community_api.dart';
part 'data/repositories/community_repository.dart';

//* Domain Layer - Entities, Repositories, Use Cases
part 'domain/entities/community_entity.dart';
part 'domain/repositories/i_community_repository.dart';
part 'domain/usecases/community_feed_usecases.dart';
part 'domain/usecases/community_topic_usecases.dart';
part 'domain/usecases/community_post_usecases.dart';
part 'domain/usecases/community_comment_usecases.dart';
part 'domain/usecases/community_chat_usecases.dart';
part 'domain/usecases/community_moderation_usecases.dart';
part 'domain/usecases/community_notification_usecases.dart';

//* Presentation Layer - Guest gate
part 'presentation/community_guest_gate.dart';

//* Presentation Layer - Cubits
part 'presentation/cubits/community_feed_state.dart';
part 'presentation/cubits/community_feed_cubit.dart';
part 'presentation/cubits/community_post_state.dart';
part 'presentation/cubits/community_post_cubit.dart';
part 'presentation/cubits/community_compose_state.dart';
part 'presentation/cubits/community_compose_cubit.dart';
part 'presentation/cubits/community_chat_state.dart';
part 'presentation/cubits/community_chat_cubit.dart';
part 'presentation/cubits/community_notification_state.dart';
part 'presentation/cubits/community_notification_cubit.dart';

//* Presentation Layer - Pages
part 'presentation/pages/community_page.dart';
part 'presentation/pages/community_topic_page.dart';
part 'presentation/pages/community_post_detail_page.dart';
part 'presentation/pages/community_chat_page.dart';
part 'presentation/pages/community_weekly_page.dart';
part 'presentation/pages/community_compose_page.dart';
part 'presentation/pages/community_notification_page.dart';

//* Presentation Layer - Widgets
part 'presentation/widgets/community_post_card.dart';
part 'presentation/widgets/community_weekly_card.dart';
part 'presentation/widgets/community_topic_row.dart';
part 'presentation/widgets/community_comment_tile.dart';
part 'presentation/widgets/community_composer_bar.dart';
part 'presentation/widgets/community_post_menu_sheet.dart';
part 'presentation/widgets/community_report_sheet.dart';
part 'presentation/widgets/community_glyph.dart';
part 'presentation/widgets/community_chat_mark.dart';
part 'presentation/widgets/community_chat_fab.dart';
part 'presentation/widgets/community_chat_pins.dart';
part 'presentation/widgets/community_avatar.dart';
part 'presentation/widgets/community_attached_course_card.dart';
part 'presentation/widgets/community_insight_card.dart';
part 'presentation/widgets/community_room_tile.dart';
part 'presentation/widgets/community_room_suggest_sheet.dart';
part 'presentation/widgets/community_attach_sheet.dart';
part 'presentation/widgets/community_share_sheet.dart';
part 'presentation/widgets/community_muted_banner.dart';
part 'presentation/widgets/community_image_viewer.dart';
part 'presentation/widgets/community_tour.dart';

//* Parts for generated files
part 'community.freezed.dart';
part 'community.g.dart';
