class Word {
  final int _id;
  final String _english;
  final String _spanish;

  Word(this._id, this._english, this._spanish);

  Map<String, dynamic> toMap() {
    return {'id': _id, 'english': _english, 'spanish': _spanish};
  }

  String get spanish => _spanish;
  String get english => _english;

  int get id => _id;

  @override
  operator ==(other) => (other != null) && (other is Word) & (_id == other._id);

  @override
  int get hashCode => _id.hashCode;
}
