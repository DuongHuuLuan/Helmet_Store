import 'package:b2205946_duonghuuluan_luanvan/domain/entity/evaluate/evaluate.dart';
import 'package:equatable/equatable.dart';

class EvaluateState extends Equatable {
  final List<EvaluateItem> evaluates;
  final bool isLoading;
  final bool isRefreshing;
  final bool isLoadingMore;
  final String? errorMessage;
  final Set<int> creatingOrderIds;
  final int page;
  final int total;
  final int totalPages;

  const EvaluateState({
    this.evaluates = const [],
    this.isLoading = false,
    this.isRefreshing = false,
    this.isLoadingMore = false,
    this.errorMessage,
    this.creatingOrderIds = const {},
    this.page = 1,
    this.total = 0,
    this.totalPages = 0,
  });

  bool get hasNextPage => page < totalPages;

  EvaluateState copyWith({
    List<EvaluateItem>? evaluates,
    bool? isLoading,
    bool? isRefreshing,
    bool? isLoadingMore,
    String? errorMessage,
    Set<int>? creatingOrderIds,
    int? page,
    int? total,
    int? totalPages,
    bool clearEvaluates = false,
  }) {
    return EvaluateState(
      evaluates: clearEvaluates ? const [] : (evaluates ?? this.evaluates),
      isLoading: isLoading ?? this.isLoading,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      errorMessage: errorMessage,
      creatingOrderIds: creatingOrderIds ?? this.creatingOrderIds,
      page: page ?? this.page,
      total: total ?? this.total,
      totalPages: totalPages ?? this.totalPages,
    );
  }

  @override
  List<Object?> get props => [
    evaluates,
    isLoading,
    isRefreshing,
    isLoadingMore,
    errorMessage,
    creatingOrderIds,
    page,
    total,
    totalPages,
  ];
}
