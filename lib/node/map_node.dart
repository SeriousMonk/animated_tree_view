import 'dart:collection';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:tree_structure_view/exceptions/exceptions.dart';
import 'base/i_node_actions.dart';
import 'node.dart';

export 'node.dart';

class MapNode<T> with NodeViewData<T> implements Node<T>, IMapNodeActions<T> {
  final Map<String, MapNode<T>> children;
  final String key;
  String path;

  @mustCallSuper
  MapNode([String? key])
      : children = <String, MapNode<T>>{},
        key = key ?? UniqueKey().toString(),
        path = "";

  UnmodifiableListView<Node<T>> get childrenAsList =>
      UnmodifiableListView(children.values.toList(growable: false));

  @override
  void add(Node<T> value) {
    if (children.containsKey(value.key)) throw DuplicateKeyException(value.key);
    value.path = childrenPath;
    final updatedValue = _updateChildrenPaths(value as MapNode);
    children[value.key] = updatedValue as MapNode<T>;
  }

  @override
  Future<void> addAsync(Node<T> value) async {
    if (children.containsKey(value.key)) throw DuplicateKeyException(value.key);
    value.path = childrenPath;
    final updatedValue =
        await compute(_updateChildrenPaths, (value as MapNode));
    children[value.key] = updatedValue as MapNode<T>;
  }

  @override
  void addAll(Iterable<Node<T>> iterable) {
    for (final node in iterable) {
      add(node);
    }
  }

  @override
  Future<void> addAllAsync(Iterable<Node<T>> iterable) async {
    await Future.forEach(
        iterable, (dynamic node) async => await addAsync(node));
  }

  @override
  void clear() {
    children.clear();
  }

  @override
  void remove(String key) {
    children.remove(key);
  }

  @override
  void removeAll(Iterable<String> keys) {
    keys.forEach((key) => children.remove(key));
  }

  @override
  void removeWhere(bool Function(Node<T> element) test) {
    children.removeWhere((key, value) => test(value));
  }

  @override
  MapNode<T> operator [](String path) => elementAt(path);

  @override
  MapNode<T> elementAt(String path) {
    MapNode<T> currentNode = this;
    for (final nodeKey in path.splitToNodes) {
      if (nodeKey == currentNode.key) {
        continue;
      } else {
        final nextNode = currentNode.children[nodeKey];
        if (nextNode == null)
          throw NodeNotFoundException(path: path, key: nodeKey);
        currentNode = nextNode;
      }
    }
    return currentNode;
  }

  static MapNode _updateChildrenPaths(MapNode node) {
    node.children.forEach((_, childNode) {
      childNode.path = node.childrenPath;
      if (childNode.children.isNotEmpty) {
        _updateChildrenPaths(childNode);
      }
    });
    return node;
  }

  @override
  String toString() {
    return 'MapNode{children: $children, key: $key, path: $path}';
  }
}
