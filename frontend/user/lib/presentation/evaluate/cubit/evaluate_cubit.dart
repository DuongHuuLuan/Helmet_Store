import 'package:b2205946_duonghuuluan_luanvan/presentation/evaluate/cubit/evaluate_state.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/entity/evaluate/evaluate.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/usecase/evaluate/create_evaluate_usecase.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/usecase/evaluate/get_evaluate_by_order_usecase.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/usecase/evaluate/get_evaluate_detail_usecase.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/usecase/evaluate/get_my_evaluates_usecase.dart';
import 'package:bloc/bloc.dart';

class EvaluateCubit extends Cubit<EvaluateState> {
  final GetMyEvaluatesUseCase _getMyEvaluates;
  final GetEvaluateByOrderUseCase _getEvaluateByOrder;
  final GetEvaluateDetailUseCase _getEvaluateDetail;
  final CreateEvaluateUseCase _createEvaluate;
  EvaluateCubit(
    this._getMyEvaluates,
    this._getEvaluateByOrder,
    this._getEvaluateDetail,
    this._createEvaluate,
  ) : super(const EvaluateState());

  final List<EvaluateItem> _evaluates = [];
  final Set<int> _creatingOrderIds = {};
  final Map<int, int> _evaluateIdByOrder = {};
  final Set<int> _checkedOrderIds = {};
  int _page = 1;
  int _perPage = 8;
  int _total = 0;
  int _totalPages = 0;

  bool get hasNextPage => _page < _totalPages;
  Set<int> get reviewedOrderIds => Set.unmodifiable(_evaluateIdByOrder.keys.toSet());
  bool hasEvaluateForOrder(int orderId) => _evaluateIdByOrder.containsKey(orderId);
  int? evaluateIdForOrder(int orderId) => _evaluateIdByOrder[orderId];

  void _emitState() {
    emit(EvaluateState(
      evaluates: List.unmodifiable(_evaluates),
      isLoading: state.isLoading,
      isRefreshing: state.isRefreshing,
      isLoadingMore: state.isLoadingMore,
      errorMessage: state.errorMessage,
      creatingOrderIds: Set.unmodifiable(_creatingOrderIds),
      page: _page,
      total: _total,
      totalPages: _totalPages,
    ));
  }

  Future<void> load({int perPage = 8}) async {
    if (state.isLoading || _evaluates.isNotEmpty) return;
    _perPage = perPage;
    await refresh();
  }

  Future<void> refresh() async {
    if (state.isRefreshing) return;
    emit(state.copyWith(isRefreshing: true, isLoading: _evaluates.isEmpty, errorMessage: null));
    final result = await _getMyEvaluates(page: 1, perPage: _perPage);
    result.fold(
      (failure) => emit(state.copyWith(isLoading: false, isRefreshing: false, errorMessage: failure.message)),
      (page) {
        _evaluates
          ..clear()
          ..addAll(page.items);
        _page = page.page;
        _perPage = page.perPage;
        _total = page.total;
        _totalPages = page.totalPages;
        _rebuildEvaluateIndex();
        emit(state.copyWith(
          isLoading: false,
          isRefreshing: false,
          evaluates: List.unmodifiable(_evaluates),
          page: _page,
          total: _total,
          totalPages: _totalPages,
        ));
      },
    );
  }

  Future<void> loadMore() async {
    if (state.isLoadingMore || !hasNextPage) return;
    emit(state.copyWith(isLoadingMore: true, errorMessage: null));
    final nextPage = _page + 1;
    final result = await _getMyEvaluates(page: nextPage, perPage: _perPage);
    result.fold(
      (failure) {
        emit(state.copyWith(isLoadingMore: false, errorMessage: failure.message));
      },
      (page) {
        _evaluates.addAll(page.items);
        _page = page.page;
        _perPage = page.perPage;
        _total = page.total;
        _totalPages = page.totalPages;
        _rebuildEvaluateIndex();
        emit(state.copyWith(
          isLoadingMore: false,
          evaluates: List.unmodifiable(_evaluates),
          page: _page,
          total: _total,
          totalPages: _totalPages,
        ));
      },
    );
  }

  Future<void> syncEvaluateStatusForOrders(List<int> orderIds) async {
    final uniqueIds = orderIds.where((e) => e > 0).toSet().toList()..sort();
    final pending = uniqueIds.where((id) => !_checkedOrderIds.contains(id)).toList();
    if (pending.isEmpty) return;
    var changed = false;
    for (final orderId in pending) {
      final result = await _getEvaluateByOrder(orderId);
      result.fold(
        (_) => null,
        (found) {
          if (found != null) {
            _evaluateIdByOrder[orderId] = found.id;
            changed = true;
          }
        },
      );
      _checkedOrderIds.add(orderId);
    }
    if (changed) _emitState();
  }

  Future<EvaluateItem> getEvaluateDetail(int evaluateId) async {
    final result = await _getEvaluateDetail(evaluateId);
    return result.fold(
      (failure) {
        emit(state.copyWith(errorMessage: failure.message));
        throw failure;
      },
      (item) => item,
    );
  }

  Future<EvaluateItem> createEvaluate({
    required int orderId,
    required int rate,
    String? content,
    List<String> imagePaths = const [],
  }) async {
    if (_creatingOrderIds.contains(orderId)) {
      throw StateError("Đang gửi đánh giá cho đơn này");
    }
    _creatingOrderIds.add(orderId);
    _emitState();
    final result = await _createEvaluate(
      orderId: orderId,
      rate: rate,
      content: content,
      imagePaths: imagePaths,
    );
    return result.fold(
      (failure) {
        _creatingOrderIds.remove(orderId);
        _emitState();
        throw failure;
      },
      (created) {
        _evaluateIdByOrder[created.orderId] = created.id;
        _checkedOrderIds.add(created.orderId);
        _evaluates.removeWhere((e) => e.id == created.id || e.orderId == created.orderId);
        _evaluates.insert(0, created);
        _total += 1;
        _creatingOrderIds.remove(orderId);
        _emitState();
        return created;
      },
    );
  }

  void _rebuildEvaluateIndex() {
    for (final e in _evaluates) {
      _evaluateIdByOrder[e.orderId] = e.id;
      _checkedOrderIds.add(e.orderId);
    }
  }
}
