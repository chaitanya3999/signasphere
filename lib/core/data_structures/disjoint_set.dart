/// DISJOINT SET (Union-Find) — Concept Grouping for Learn Mode
/// Uses path compression + union by rank for O(α(N)) operations.

class DisjointSet {
  final Map<String, String> _parent = {};
  final Map<String, int> _rank = {};
  final Map<String, String> _groupLabel = {};

  /// Creates a new single-element set. Each element is its own parent initially.
  void makeSet(String element, {String? groupName}) {
    if (_parent.containsKey(element)) return; // Skip if already exists
    _parent[element] = element; // Element points to itself
    _rank[element] = 0;
    if (groupName != null) _groupLabel[element] = groupName;
  }

  /// Finds the root of the set containing [element] with path compression.
  /// Path compression flattens the tree for faster future lookups.
  String find(String element) {
    if (!_parent.containsKey(element)) makeSet(element);
    if (_parent[element] != element) {
      _parent[element] = find(
        _parent[element]!,
      ); // Compress path by updating parent
    }
    return _parent[element]!;
  }

  /// Unites two sets using union by rank optimization.
  /// The smaller tree is always attached to the larger one to minimize depth.
  void union(String a, String b) {
    final rootA = find(a);
    final rootB = find(b);
    if (rootA == rootB) return; // Already in same set

    // Attach smaller rank tree under larger rank tree
    if (_rank[rootA]! < _rank[rootB]!) {
      _parent[rootA] = rootB;
      // Propagate group label if needed
      if (!_groupLabel.containsKey(rootB) && _groupLabel.containsKey(rootA)) {
        _groupLabel[rootB] = _groupLabel[rootA]!;
      }
    } else if (_rank[rootA]! > _rank[rootB]!) {
      _parent[rootB] = rootA;
      if (!_groupLabel.containsKey(rootA) && _groupLabel.containsKey(rootB)) {
        _groupLabel[rootA] = _groupLabel[rootB]!;
      }
    } else {
      // Equal ranks: attach B to A and increase A's rank
      _parent[rootB] = rootA;
      _rank[rootA] = _rank[rootA]! + 1;
      if (!_groupLabel.containsKey(rootA) && _groupLabel.containsKey(rootB)) {
        _groupLabel[rootA] = _groupLabel[rootB]!;
      }
    }
    print('[DS:DisjointSet][UNION] "$a" ∪ "$b"');
  }

  /// Checks if two elements belong to the same set.
  bool isConnected(String a, String b) => find(a) == find(b);

  /// Returns all elements in the same group as [element].
  List<String> getGroup(String element) {
    final root = find(element);
    return _parent.keys.where((e) => find(e) == root).toList();
  }

  /// Returns all groups with their elements, grouped by label or root identifier.
  Map<String, List<String>> getAllGroups() {
    final groups = <String, List<String>>{};
    for (final element in _parent.keys) {
      final root = find(element);
      final label =
          _groupLabel[root] ?? root; // Use custom label or root as key
      groups.putIfAbsent(label, () => []);
      groups[label]!.add(element);
    }
    return groups;
  }

  /// Gets the custom label assigned to the group containing [element].
  String? getGroupLabel(String element) {
    return _groupLabel[find(element)];
  }

  int get totalElements => _parent.length;
}
