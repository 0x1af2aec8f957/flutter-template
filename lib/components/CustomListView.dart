import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart' show CupertinoActivityIndicator;
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

import './NoData.dart';

typedef Future<bool> LoadMoreCallback<T>(bool isReset/* 是否是刷新 */); // 加载更多方法回调
typedef Widget _IndexedWidgetBuilder<T>(BuildContext context, T item, int index); // 列表项构建器

/// 上拉加载更多，下拉刷新
class CustomListView<T> extends StatefulWidget {
  final List<T> data;
  final Color? color;
  final Color? backgroundColor;
  final Widget loadingWidget;
  final bool hasRefresh; // 是否有下拉刷新功能
  final LoadMoreCallback<T>? onLoadMoreData;
  final ItemScrollController? itemScrollController;
  // final ItemPositionsListener itemPositionsListener;
  final ScrollOffsetController? scrollOffsetController;
  // final ScrollOffsetListener scrollOffsetListener;
  final IndexedWidgetBuilder separatorBuilder;
  final _IndexedWidgetBuilder<T> itemBuilder;
  final int initialScrollIndex;
  final double initialAlignment;
  final Axis scrollDirection;
  final bool reverse;
  final bool shrinkWrap;
  final ScrollPhysics physics;
  final int? semanticChildCount;
  final EdgeInsets? padding;
  final bool addSemanticIndexes;
  final bool addAutomaticKeepAlives;
  final bool addRepaintBoundaries;
  final double? minCacheExtent;

  CustomListView({
    super.key,
    this.data = const [],
    this.reverse = false,
    this.physics = const AlwaysScrollableScrollPhysics()/* 回弹动效（保持任何时候都能滚动 */,
    this.padding,
    this.color,
    this.backgroundColor,
    this.loadingWidget = const CupertinoActivityIndicator()/* ios */, // CircularProgressIndicator()/* android */
    this.hasRefresh = true,
    this.onLoadMoreData,
    this.shrinkWrap = false,
    required this.itemBuilder,
    this.minCacheExtent,
    this.scrollDirection = Axis.vertical,
    this.initialAlignment = 0.0,
    this.initialScrollIndex = 0,
    this.semanticChildCount,
    this.addSemanticIndexes = true,
    this.addRepaintBoundaries = true,
    this.addAutomaticKeepAlives = true,
    IndexedWidgetBuilder? separatorBuilder,
    this.itemScrollController,
    // ScrollOffsetListener? scrollOffsetListener,
    this.scrollOffsetController,
    // ItemPositionsListener? itemPositionsListener,
  }):
  assert(hasRefresh || (color == null && backgroundColor == null), 'hasRefresh 为 false 时，color 和 backgroundColor 无效'),
  assert(!hasRefresh || onLoadMoreData != null, 'hasRefresh 为 true 时，onLoadMoreData 不能为空'),
  separatorBuilder = separatorBuilder ?? ((BuildContext context, int index) => SizedBox.shrink());
  // itemScrollController = itemScrollController ?? ItemScrollController(),
  // scrollOffsetController = scrollOffsetController ?? ScrollOffsetController(),
  // scrollOffsetListener = scrollOffsetListener ?? ScrollOffsetListener.create(),
  // itemPositionsListener = itemPositionsListener ?? ItemPositionsListener.create();

  @override
  _CustomListView<T> createState() => _CustomListView<T>();
}

class _CustomListView<T> extends State<CustomListView<T>> {
  final itemPositionsListener = ItemPositionsListener.create();
  final scrollOffsetListener = ScrollOffsetListener.create();

  bool isLoading = false;
  late bool hasMoreData = widget.onLoadMoreData != null;

   Future<void> handleLoadMoreData() { // 上拉加载更多
    if (isLoading || !hasMoreData) return Future.value();

    setState(() {
      isLoading = true;
    });

    return widget.onLoadMoreData!(false).then((_hasMoreData) {
      setState(() {
        hasMoreData = _hasMoreData;
      });
    }).whenComplete((){
      setState(() {
        isLoading = false;
      });
    });
  }

  Future<void> handleRefresh() { // 下拉刷新
    return widget.onLoadMoreData!(false).then((_hasMoreData) {
      setState(() {
        hasMoreData = _hasMoreData;
      });
    });
  }

  void _itemPositionsListener() {
    final Iterable<ItemPosition> positions = itemPositionsListener.itemPositions.value;
    final bool isLoadMore = positions.any((position) => position.index == widget.data.length - 1 && position.itemTrailingEdge > 0); // 判断是否需要加载更多
    if (!isLoadMore) return;
    handleLoadMoreData(); // 加载更多
  }

  @override
  void initState() {
    super.initState();
    itemPositionsListener.itemPositions.addListener(_itemPositionsListener); // 监听列表项位置，上拉加载更多
    /* scrollOffsetListener.changes.listen((offset) {
      if (offset == 0) return;
    }); */
    // widget.itemScrollController.jumpTo(index: 1);
    // widget.scrollOffsetController.animateScroll(offset: 1, duration: Durations.short1);
  }

  @override
  void dispose() {
    itemPositionsListener.itemPositions.removeListener(_itemPositionsListener);
    // widget.itemScrollController.dispose();
    // widget.scrollOffsetController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.data.isEmpty && !hasMoreData) return NoData(); // 暂无数据
    if (widget.data.isEmpty/*  && isLoading */) return Center(child: CircularProgressIndicator()); // 加载中

    if (widget.hasRefresh) return RefreshIndicator( // 下拉刷新
      color: widget.color,
      backgroundColor: widget.backgroundColor,
      onRefresh: handleRefresh, // 下拉刷新
      child: _ListView,
    );

    return _ListView; // 不支持下拉刷新
  }

  Widget get _ListView => ScrollablePositionedList.separated(
    reverse: widget.reverse,
    physics: widget.physics,
    padding: widget.padding,
    itemCount: widget.data.length + 1/* LoadingWidget 占位 */,
    shrinkWrap: widget.shrinkWrap,
    itemBuilder: (BuildContext _context, int index) => index == widget.data.length ? _LoadingWidget : widget.itemBuilder(_context, widget.data.elementAt(index), index),
    minCacheExtent: widget.minCacheExtent,
    scrollDirection: widget.scrollDirection,
    separatorBuilder: widget.separatorBuilder,
    initialAlignment: widget.initialAlignment,
    initialScrollIndex: widget.initialScrollIndex,
    semanticChildCount: widget.semanticChildCount,
    addSemanticIndexes: widget.addSemanticIndexes,
    itemScrollController: widget.itemScrollController,
    scrollOffsetListener: scrollOffsetListener,
    addRepaintBoundaries: widget.addRepaintBoundaries,
    itemPositionsListener: itemPositionsListener,
    scrollOffsetController: widget.scrollOffsetController,
    addAutomaticKeepAlives: widget.addAutomaticKeepAlives,
  );

  Widget get _LoadingWidget => isLoading ? Padding(
    padding: EdgeInsets.symmetric(vertical: 10),
    child: widget.loadingWidget,
  ) : SizedBox.shrink();
}