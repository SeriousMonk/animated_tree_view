import 'package:animated_tree_view/animated_tree_view.dart';
import 'package:flutter/material.dart';

class ExpandableNodeItem<Data, Tree extends ITreeNode<Data>>
    extends StatelessWidget {
  final TreeNodeWidgetBuilder<Tree> builder;
  final AutoScrollController scrollController;
  final Tree node;
  final Animation<double> animation;
  final Indentation indentation;
  final ExpansionIndicatorBuilder<Data>? expansionIndicatorBuilder;
  final bool remove;
  final int? index;
  final ValueSetter<Tree>? onItemTap;
  final ValueSetter<Tree> onToggleExpansion;
  final bool showRootNode;
  final DragDetails dragDetails;

  static Widget insertedNode<Data, Tree extends ITreeNode<Data>>({
    required int index,
    required Tree node,
    required TreeNodeWidgetBuilder<Tree> builder,
    required AutoScrollController scrollController,
    required Animation<double> animation,
    required ExpansionIndicatorBuilder<Data>? expansionIndicator,
    required ValueSetter<Tree>? onItemTap,
    required ValueSetter<Tree> onToggleExpansion,
    required bool showRootNode,
    required Indentation indentation,
    required DragDetails dragDetails
  }) {
    return ValueListenableBuilder<INode>(
      valueListenable: node,
      builder: (context, treeNode, _) => ValueListenableBuilder(
        valueListenable: (treeNode as Tree).listenableData,
        builder: (context, data, _) => ExpandableNodeItem<Data, Tree>(
          builder: builder,
          scrollController: scrollController,
          node: node,
          index: index,
          animation: animation,
          indentation: indentation,
          expansionIndicatorBuilder: expansionIndicator,
          onToggleExpansion: onToggleExpansion,
          onItemTap: onItemTap,
          showRootNode: showRootNode,
          dragDetails: dragDetails,
        ),
      ),
    );
  }

  static Widget removedNode<Data, Tree extends ITreeNode<Data>>({
    required Tree node,
    required TreeNodeWidgetBuilder<Tree> builder,
    required AutoScrollController scrollController,
    required Animation<double> animation,
    required ExpansionIndicatorBuilder<Data>? expansionIndicator,
    required ValueSetter<Tree>? onItemTap,
    required ValueSetter<Tree> onToggleExpansion,
    required bool showRootNode,
    required bool isLastChild,
    required Indentation indentation,
    required DragDetails dragDetails
  }) {
    return ExpandableNodeItem<Data, Tree>(
      builder: builder,
      scrollController: scrollController,
      node: node,
      remove: true,
      animation: animation,
      indentation: indentation,
      expansionIndicatorBuilder: expansionIndicator,
      onItemTap: onItemTap,
      onToggleExpansion: onToggleExpansion,
      showRootNode: showRootNode,
      dragDetails: dragDetails,
    );
  }

  const ExpandableNodeItem({
    super.key,
    required this.builder,
    required this.scrollController,
    required this.node,
    required this.animation,
    required this.onToggleExpansion,
    this.index,
    this.remove = false,
    this.expansionIndicatorBuilder,
    this.onItemTap,
    required this.showRootNode,
    required this.indentation,
    required this.dragDetails
  });

  @override
  Widget build(BuildContext context) {
    final itemContainer = ExpandableNodeContainer(
      animation: animation,
      node: node,
      child: builder(context, node),
      indentation: indentation,
      minLevelToIndent: showRootNode ? 0 : 1,
      expansionIndicator: node.childrenAsList.isEmpty
          ? null
          : expansionIndicatorBuilder?.call(context, node),
      onTap: remove
          ? null
          : (dynamic item) {
              onToggleExpansion(item);
              if (onItemTap != null) onItemTap!(item);
            },
      toggleExpansion: (dynamic item) => onToggleExpansion(item),
      dragDetails: dragDetails,
    );

    if (index == null || remove) return itemContainer;

    return AutoScrollTag(
      key: ValueKey(node.key),
      controller: scrollController,
      index: index!,
      child: itemContainer,
    );
  }
}

class ExpandableNodeContainer<T> extends StatefulWidget {
  final Animation<double> animation;
  final ValueSetter<ITreeNode<T>>? onTap;
  final ValueSetter<ITreeNode<T>> toggleExpansion;
  final ITreeNode<T> node;
  final ExpansionIndicator? expansionIndicator;
  final Indentation indentation;
  final Widget child;
  final int minLevelToIndent;
  final DragDetails dragDetails;

  const ExpandableNodeContainer({
    super.key,
    required this.animation,
    required this.onTap,
    required this.toggleExpansion,
    required this.child,
    required this.node,
    required this.indentation,
    required this.minLevelToIndent,
    this.expansionIndicator,
    required this.dragDetails
  });

  @override
  State<ExpandableNodeContainer<T>> createState() => _ExpandableNodeContainerState<T>();
}

class _ExpandableNodeContainerState<T> extends State<ExpandableNodeContainer<T>> {
  final GlobalKey _feedbackKey = GlobalKey();
  bool _wasExpandedOnDragStart = false;

  @override
  Widget build(BuildContext context) {
    Widget item = widget.expansionIndicator == null
      ? widget.child
      : PositionedExpansionIndicator(
        expansionIndicator: widget.expansionIndicator!,
        child: widget.child,
    );

    return SizeTransition(
      axis: Axis.vertical,
      sizeFactor: CurvedAnimation(parent: widget.animation, curve: Curves.easeOut),
      child: Indent(
        indentation: widget.indentation,
        node: widget.node,
        minLevelToIndent: widget.minLevelToIndent,
        child: LayoutBuilder(
          builder: (context, constraints) {
            return LongPressDraggable(
              maxSimultaneousDrags: widget.node.isRoot ? 0 : 1,
              axis: Axis.vertical,
              data: widget.node,
              dragAnchorStrategy: (draggable, context, position){
                final RenderBox renderObject = context.findRenderObject()! as RenderBox;
                return Offset(renderObject.globalToLocal(position).dx, renderObject.size.height/2);
              },
              onDragStarted: _onDragStarted,
              onDraggableCanceled: _onDragCancel,
              onDragUpdate: _onDragUpdate,
              feedback: Material(
                elevation: 8,
                child: SizedBox(
                  key: _feedbackKey,
                  width: constraints.maxWidth,
                  child: Theme(
                    data: Theme.of(context).copyWith(canvasColor: Colors.grey.shade800),
                    child: widget.child
                ))
              ),
              child: DragTarget<ITreeNode<T>>(
                onMove: _onMove,
                builder: (BuildContext context, List<Object?> candidateData, List<dynamic> rejectedData) {
                  return GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onTap: widget.onTap == null ? null : () => widget.onTap!(widget.node),
                    child: item,
                  );
                },
              ),
            );
          }
        ),
      ),
    );
  }

  void _onDragStarted(){
    if(widget.node.isExpanded){
      _wasExpandedOnDragStart = true;
    }

    List<INode> children = widget.node.parent!.childrenAsList;
    int index = children.indexWhere((e) => e.key == widget.node.key);
    if(index == -1) throw Exception('Target node not found in tree');

    widget.dragDetails.originPosition = widget.dragDetails.destinationPosition = TreePosition(
      parentPath: widget.node.parent!.path,
      position: index
    );

    widget.dragDetails.draggedNode = widget.node;
    (widget.node as IIndexedNodeActions).delete();
  }

  void _onDragCancel(Velocity _, Offset __){
    ///this triggers DragDetails to notifyListeners and remove the gap widget
    ///before placing the node at its original position
    widget.dragDetails.destinationPosition = null;

    final parent = widget.node.parent as IIndexedNodeActions;
    parent.insert(
      widget.dragDetails.originPosition!.position,
      widget.dragDetails.draggedNode as IndexedNode
    );

    widget.dragDetails.reset();

    if(_wasExpandedOnDragStart){

      _wasExpandedOnDragStart = false;
    }
  }

  void _onDragUpdate(DragUpdateDetails _){
    RenderBox itemRenderBox = _feedbackKey.currentContext?.findRenderObject() as RenderBox;
    widget.dragDetails.currentFeedbackDy = itemRenderBox.localToGlobal(Offset(0, itemRenderBox.size.height / 2)).dy;
  }

  void _onMove(DragTargetDetails<ITreeNode<T>> details){
    bool willAccept = widget.node.level == details.data.level && widget.node.key != details.data.key;

    if(mounted && willAccept && widget.dragDetails.currentFeedbackDy != null){
      RenderBox itemRenderBox = context.findRenderObject()! as RenderBox;
      double targetDy = itemRenderBox.localToGlobal(Offset(0, itemRenderBox.size.height / 2)).dy;

      if(widget.dragDetails.currentFeedbackDy! >= targetDy){
        List<INode> children = widget.node.parent!.childrenAsList;
        int targetNodeIndex = children.indexWhere((e) => e.key == widget.node.key);
        if(targetNodeIndex == -1) throw Exception('Target node not found in tree');

        if(targetNodeIndex == children.length - 1){
          ///if this is the last child node
          widget.dragDetails.destinationPosition = TreePosition(
            parentPath: widget.node.parent!.path,
            position: children.length
          );
        }else{
          widget.dragDetails.destinationPosition = TreePosition(
            parentPath: widget.node.parent!.path,
            position: targetNodeIndex + 1
          );
        }
      }else{
        ///dragged item has to be placed before this node
        List<INode> children = widget.node.parent!.childrenAsList;
        int targetNodeIndex = children.indexWhere((e) => e.key == widget.node.key);
        if(targetNodeIndex == -1) throw Exception('Target node not found in tree');

        if(targetNodeIndex == 0){
          ///if this is the first child node
          widget.dragDetails.destinationPosition = TreePosition(
            parentPath: widget.node.parent!.path,
            position: 0
          );
        }else{
          ///otherwise specify that the dragged item should be
          ///placed after the node before this one
          widget.dragDetails.destinationPosition = TreePosition(
            parentPath: widget.node.parent!.path,
            position: targetNodeIndex - 1
          );
        }
      }
    }
  }
}
