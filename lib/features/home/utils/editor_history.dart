// Undo/redo history for the card editor.
// Each [CardSnapshot] captures the full state of one card.
// [EditorHistory] manages a stack of snapshots with max 50 entries.

class CardSnapshot {
  final String id;
  final String term;
  final String definition;
  final String example;
  final String imageUrl;
  final List<String> tags;

  const CardSnapshot({
    required this.id,
    required this.term,
    required this.definition,
    required this.example,
    required this.imageUrl,
    required this.tags,
  });

  CardSnapshot copyWith({
    String? id,
    String? term,
    String? definition,
    String? example,
    String? imageUrl,
    List<String>? tags,
  }) {
    return CardSnapshot(
      id: id ?? this.id,
      term: term ?? this.term,
      definition: definition ?? this.definition,
      example: example ?? this.example,
      imageUrl: imageUrl ?? this.imageUrl,
      tags: tags ?? List<String>.from(this.tags),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CardSnapshot &&
          id == other.id &&
          term == other.term &&
          definition == other.definition &&
          example == other.example &&
          imageUrl == other.imageUrl &&
          _listEquals(tags, other.tags);

  @override
  int get hashCode => Object.hash(id, term, definition, example, imageUrl,
      Object.hashAll(tags));

  static bool _listEquals(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

class EditorHistory {
  static const int maxSnapshots = 50;

  final List<List<CardSnapshot>> _undoStack = [];
  final List<List<CardSnapshot>> _redoStack = [];

  bool get canUndo => _undoStack.isNotEmpty;
  bool get canRedo => _redoStack.isNotEmpty;

  /// Push a new state. Clears the redo stack.
  void pushState(List<CardSnapshot> state) {
    _undoStack.add(_deepCopy(state));
    _redoStack.clear();

    // Trim to max size
    while (_undoStack.length > maxSnapshots) {
      _undoStack.removeAt(0);
    }
  }

  /// Undo: moves current state to redo stack, returns previous state.
  /// [currentState] is the state before undo (so we can redo back to it).
  List<CardSnapshot>? undo(List<CardSnapshot> currentState) {
    if (!canUndo) return null;
    _redoStack.add(_deepCopy(currentState));
    return _deepCopy(_undoStack.removeLast());
  }

  /// Redo: moves current state to undo stack, returns next state.
  List<CardSnapshot>? redo(List<CardSnapshot> currentState) {
    if (!canRedo) return null;
    _undoStack.add(_deepCopy(currentState));
    return _deepCopy(_redoStack.removeLast());
  }

  void clear() {
    _undoStack.clear();
    _redoStack.clear();
  }

  int get undoCount => _undoStack.length;
  int get redoCount => _redoStack.length;

  static List<CardSnapshot> _deepCopy(List<CardSnapshot> state) {
    return state
        .map((s) => CardSnapshot(
              id: s.id,
              term: s.term,
              definition: s.definition,
              example: s.example,
              imageUrl: s.imageUrl,
              tags: List<String>.from(s.tags),
            ))
        .toList();
  }
}
