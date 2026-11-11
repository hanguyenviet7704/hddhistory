part of '../../knowledge_graph.dart';

/// Khoảng chờ trước khi một lần gõ biến thành một lần gọi API.
///
/// 350ms: đủ dài để gõ trọn một từ tiếng Việt có dấu (bộ gõ telex bắn nhiều
/// sự kiện onChanged cho một chữ) mà vẫn chưa kịp thành độ trễ cảm nhận được.
const _kKgSearchDebounce = Duration(milliseconds: 350);

/// Số thực thể lấy về cho danh sách gợi ý ban đầu (khi ô tìm kiếm còn trống).
const _kKgBrowseLimit = 30;

/// Sở hữu cả hai màn hình của tính năng tra cứu đồ thị tri thức.
///
/// Là `@lazySingleton` giống các cubit điều hướng khác của dự án, nên khi
/// người dùng đi từ hồ sơ này sang hồ sơ khác thì [openEntity] phải tự dọn
/// trạng thái cũ — nếu không, hồ sơ cũ sẽ hiện lại trong lúc hồ sơ mới đang tải.
@lazySingleton
class KnowledgeGraphCubit extends Cubit<KnowledgeGraphState>
    with CubitUseCaseHandlerMixin<KnowledgeGraphState> {
  final SearchKgEntitiesUseCase _searchUseCase;
  final GetKgEntityProfileUseCase _profileUseCase;
  final GetKgRelatedEntitiesUseCase _relatedUseCase;

  Timer? _debounce;

  KnowledgeGraphCubit(
    this._searchUseCase,
    this._profileUseCase,
    this._relatedUseCase,
  ) : super(KnowledgeGraphState.initial());

  /// Nạp danh sách mở màn khi màn hình tìm kiếm mở lần đầu.
  ///
  /// Tự lành: chỉ gọi khi chưa có gì trong tay, nên quay lại tab không bắn
  /// thêm request — cùng lối `ensureXDataLoaded` của các màn hình khác.
  Future<void> ensureEntitiesLoaded() async {
    if (state.searchStatus != KgStatus.initial) return;
    await _runSearch('');
  }

  /// Gọi từ mỗi lần gõ. Việc hoãn nằm ở đây chứ không ở widget để màn hình
  /// không phải giữ Timer, và để lần gõ cuối cùng luôn là lần được gửi đi.
  void onQueryChanged(String query) {
    emit(state.copyWith(query: query));
    _debounce?.cancel();
    _debounce = Timer(_kKgSearchDebounce, () => unawaited(_runSearch(query)));
  }

  /// Gửi ngay, bỏ qua thời gian hoãn — dùng cho nút "tìm" trên bàn phím.
  Future<void> submitQuery() {
    _debounce?.cancel();
    return _runSearch(state.query);
  }

  Future<void> clearQuery() {
    _debounce?.cancel();
    emit(state.copyWith(query: ''));
    return _runSearch('');
  }

  Future<void> _runSearch(String query) => runUseCaseList<KgEntitySummary>(
    usecase: () => _searchUseCase(
      query: query.trim(),
      limit: _kKgBrowseLimit,
    ),
    buildLoadingState: () =>
        state.copyWith(searchStatus: KgStatus.loading, searchError: ''),
    onFailure: (message) => emit(
      state.copyWith(searchStatus: KgStatus.failure, searchError: message),
    ),
    onSuccess: (data) => emit(
      state.copyWith(
        searchStatus: KgStatus.success,
        results: data,
        searchError: '',
      ),
    ),
  );

  /// Mở hồ sơ một thực thể: hồ sơ và danh sách liên quan chạy song song.
  ///
  /// Song song chứ không nối tiếp vì hai lời gọi độc lập nhau; nối tiếp sẽ
  /// nhân đôi thời gian chờ trắng màn hình mà không đổi lại được gì.
  Future<void> openEntity(String id) async {
    // Dọn trước: cubit là singleton nên nếu không xoá, hồ sơ vừa xem sẽ nằm
    // lại dưới vòng xoay của hồ sơ đang tải.
    emit(
      state.copyWith(
        profile: null,
        profileStatus: KgStatus.loading,
        profileError: '',
        related: const [],
        relatedStatus: KgStatus.loading,
      ),
    );

    await Future.wait([_loadProfile(id), _loadRelated(id)]);
  }

  Future<void> _loadProfile(String id) => runUseCase<KgEntityProfile>(
    usecase: () => _profileUseCase(id),
    onFailure: (message) => emit(
      state.copyWith(profileStatus: KgStatus.failure, profileError: message),
    ),
    onSuccess: (data) =>
        emit(state.copyWith(profileStatus: KgStatus.success, profile: data)),
  );

  Future<void> _loadRelated(String id) => runUseCaseList<KgRelatedEntity>(
    usecase: () => _relatedUseCase(id: id),
    // Không đặt onFailure thành lỗi toàn màn hình: phần "liên quan" là phần
    // phụ, hỏng thì giấu đi chứ không che mất hồ sơ đã tải được.
    onFailure: (_) => emit(state.copyWith(relatedStatus: KgStatus.failure)),
    onSuccess: (data) => emit(
      state.copyWith(relatedStatus: KgStatus.success, related: data),
    ),
  );

  @override
  Future<void> close() {
    _debounce?.cancel();
    return super.close();
  }
}
