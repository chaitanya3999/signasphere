/// DISJOINT SET (Union-Find) — Concept Grouping for Learn Mode
/// Uses path compression + union by rank for O(α(N)) operations.

class DisjointSet {
  final Map<String, String> _parent = {};
  final Map<String, int> _rank = {};
  final Map<String, String> _groupLabel = {};

  void makeSet(String element, {String? groupName}) {
    if (_parent.containsKey(element)) return;
    _parent[element] = element;
    _rank[element] = 0;
    if (groupName != null) _groupLabel[element] = groupName;
  }

  String find(String element) {
    if (!_parent.containsKey(element)) makeSet(element);
    if (_parent[element] != element) {
      _parent[element] = find(_parent[element]!);
    }
    return _parent[element]!;
  }

  void union(String a, String b) {
    final rootA = find(a);
    final rootB = find(b);
    if (rootA == rootB) return;

    if (_rank[rootA]! < _rank[rootB]!) {
      _parent[rootA] = rootB;
      if (!_groupLabel.containsKey(rootB) && _groupLabel.containsKey(rootA)) {
        _groupLabel[rootB] = _groupLabel[rootA]!;
      }
    } else if (_rank[rootA]! > _rank[rootB]!) {
      _parent[rootB] = rootA;
      if (!_groupLabel.containsKey(rootA) && _groupLabel.containsKey(rootB)) {
        _groupLabel[rootA] = _groupLabel[rootB]!;
      }
    } else {
      _parent[rootB] = rootA;
      _rank[rootA] = _rank[rootA]! + 1;
      if (!_groupLabel.containsKey(rootA) && _groupLabel.containsKey(rootB)) {
        _groupLabel[rootA] = _groupLabel[rootB]!;
      }
    }
    print('[DS:DisjointSet][UNION] "$a" ∪ "$b"');
  }

  bool isConnected(String a, String b) => find(a) == find(b);

  List<String> getGroup(String element) {
    final root = find(element);
    return _parent.keys.where((e) => find(e) == root).toList();
  }

  Map<String, List<String>> getAllGroups() {
    final groups = <String, List<String>>{};
    for (final element in _parent.keys) {
      final root = find(element);
      final label = _groupLabel[root] ?? root;
      groups.putIfAbsent(label, () => []);
      groups[label]!.add(element);
    }
    return groups;
  }

  String? getGroupLabel(String element) {
    return _groupLabel[find(element)];
  }

  int get totalElements => _parent.length;
}
