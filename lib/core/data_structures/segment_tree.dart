/// SEGMENT TREE — Range Query for Learning Progress Tracking
/// Supports: point update O(log N), range sum query O(log N)

class SegmentTree {
  late List<int> _tree;
  late int _n;

  SegmentTree(int size) {
    _n = size;
    _tree = List.filled(4 * _n, 0);
  }

  void update(int index, int value, [int node = 1, int start = 0, int? end]) {
    end ??= _n - 1;
    if (start == end) {
      _tree[node] += value;
      print('[DS:SegTree][UPDATE] day=$index += $value, total=${_tree[node]}');
      return;
    }
    final mid = (start + end) ~/ 2;
    if (index <= mid) {
      update(index, value, 2 * node, start, mid);
    } else {
      update(index, value, 2 * node + 1, mid + 1, end);
    }
    _tree[node] = _tree[2 * node] + _tree[2 * node + 1];
  }

  int query(int l, int r, [int node = 1, int start = 0, int? end]) {
    end ??= _n - 1;
    if (r < start || end < l) return 0;
    if (l <= start && end <= r) return _tree[node];
    final mid = (start + end) ~/ 2;
    return query(l, r, 2 * node, start, mid) +
        query(l, r, 2 * node + 1, mid + 1, end);
  }

  /// Query words learned in last N days from a reference day.
  int wordsLearnedInRange(int fromDay, int toDay) {
    final result = query(fromDay, toDay);
    print('[DS:SegTree][QUERY] days $fromDay..$toDay → $result words');
    return result;
  }
}
