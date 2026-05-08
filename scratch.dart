void main() {
  dynamic json = {'participants': [162, "5k62nLGve4SgS4qcB0FclgWUMwj1"]};
  try {
    List<String> list = List<String>.from(json['participants']);
    print(list);
  } catch (e) {
    print("ERROR: $e");
  }
}
