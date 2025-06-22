class Item {
  final String nome;
  final String categoria;
  bool comprado;

  Item({
    required this.nome,
    required this.categoria,
    this.comprado = false,
  });

  // Converte de JSON para objeto Item
  factory Item.fromJson(Map<String, dynamic> json) {
    return Item(
      nome: json['nome'],
      categoria: json['categoria'],
      comprado: json['comprado'] ?? false,
    );
  }

  // Converte de objeto Item para JSON
  Map<String, dynamic> toJson() {
    return {
      'nome': nome,
      'categoria': categoria,
      'comprado': comprado,
    };
  }
}
