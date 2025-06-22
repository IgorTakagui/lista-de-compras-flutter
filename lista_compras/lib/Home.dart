import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart';
import 'item_model.dart';
import 'HistoricoPage.dart';

class Home extends StatefulWidget {
  const Home({Key? key}) : super(key: key);

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final List<Item> _listaItens = [];
  final TextEditingController _controllerNome = TextEditingController();
  final TextEditingController _controllerCategoria = TextEditingController();

  @override
  void initState() {
    super.initState();
    _carregarLista();
  }

  Future<void> _carregarLista() async {
    final prefs = await SharedPreferences.getInstance();
    final dados = prefs.getString('lista_compras');
    if (dados != null) {
      final jsonList = json.decode(dados) as List;
      setState(() {
        _listaItens.clear();
        _listaItens.addAll(jsonList.map((e) => Item.fromJson(e)));
      });
    }
  }

  Future<void> _salvarLista() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = _listaItens.map((e) => e.toJson()).toList();
    await prefs.setString('lista_compras', json.encode(jsonList));
  }

  Future<void> _salvarNoHistorico() async {
    final prefs = await SharedPreferences.getInstance();
    final historico = prefs.getStringList('historico_listas') ?? [];
    final listaAtual = _listaItens.map((e) => e.toJson()).toList();
    historico.add(json.encode(listaAtual));
    await prefs.setStringList('historico_listas', historico);
  }

  void _compartilharLista() {
    if (_listaItens.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('A lista está vazia')),
      );
      return;
    }

    final buffer = StringBuffer();
    buffer.writeln("🛒 Minha Lista de Compras:\n");

    final categorias = <String, List<Item>>{};
    for (var item in _listaItens) {
      categorias.putIfAbsent(item.categoria, () => []).add(item);
    }

    categorias.forEach((categoria, itens) {
      buffer.writeln("📂 $categoria:");
      for (var item in itens) {
        final status = item.comprado ? "✅" : "🔲";
        buffer.writeln("  $status ${item.nome}");
      }
      buffer.writeln("");
    });

    Share.share(buffer.toString());
  }

  void _adicionarItem() async {
    _controllerNome.clear();
    _controllerCategoria.clear();

    final confirmado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Adicionar item"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _controllerNome,
              decoration: const InputDecoration(labelText: 'Nome do item'),
            ),
            TextField(
              controller: _controllerCategoria,
              decoration:
                  const InputDecoration(labelText: 'Categoria (opcional)'),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Cancelar")),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text("Adicionar")),
        ],
      ),
    );

    if (confirmado == true && _controllerNome.text.trim().isNotEmpty) {
      final nome = _controllerNome.text.trim();
      final categoria = _controllerCategoria.text.trim().isEmpty
          ? "Sem categoria"
          : _controllerCategoria.text.trim();

      setState(() {
        _listaItens.add(Item(nome: nome, categoria: categoria));
      });
      _salvarLista();
    }
  }

  void _marcarComoComprado(int index) {
    setState(() {
      _listaItens[index].comprado = !_listaItens[index].comprado;

      final comprados = _listaItens.where((e) => e.comprado).length;
      final total = _listaItens.length;

      String mensagem;
      if (comprados == total && total > 0) {
        mensagem = "✅ Todos os itens foram comprados!";
      } else if (comprados > 0) {
        mensagem = "💪 Ótimo! Você já comprou $comprados de $total!";
      } else {
        mensagem = "🛒 Vamos às compras!";
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(mensagem), duration: const Duration(seconds: 2)),
      );
    });
    _salvarLista();
  }

  void _excluirItem(int index) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Confirmar exclusão"),
        content: Text("Deseja remover \"${_listaItens[index].nome}\"?"),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancelar")),
          TextButton(
              onPressed: () {
                setState(() => _listaItens.removeAt(index));
                _salvarLista();
                Navigator.pop(context);
              },
              child: const Text("Remover")),
        ],
      ),
    );
  }

  void _limparLista() {
    if (_listaItens.isEmpty) return;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Limpar lista"),
        content: const Text(
            "Deseja salvar esta lista no histórico antes de apagar?"),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancelar")),
          TextButton(
              onPressed: () async {
                await _salvarNoHistorico();
                setState(() => _listaItens.clear());
                _salvarLista();
                Navigator.pop(context);
              },
              child: const Text("Salvar e Apagar")),
        ],
      ),
    );
  }

  void _abrirHistorico() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => HistoricoPage(
          onSelecionarLista: (jsonList) {
            setState(() {
              _listaItens.clear();
              _listaItens.addAll(jsonList.map((e) => Item.fromJson(e)));
            });
            _salvarLista();
          },
        ),
      ),
    );
  }

  String _emojiCategoria(String categoria) {
    final map = {
      'hortifruti': '🥦',
      'padaria': '🍞',
      'bebidas': '🧃',
      'limpeza': '🧼',
      'carnes': '🥩',
      'doces': '🍬',
    };

    final chave = categoria.toLowerCase();
    return map.entries
            .firstWhere((e) => chave.contains(e.key),
                orElse: () => const MapEntry('', '🗂️'))
            .value +
        " $categoria";
  }

  @override
  Widget build(BuildContext context) {
    final agrupado = <String, List<Item>>{};
    for (var item in _listaItens) {
      agrupado.putIfAbsent(item.categoria, () => []).add(item);
    }

    final total = _listaItens.length;
    final comprados = _listaItens.where((e) => e.comprado).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text("🛒 Lista de Compras"),
        backgroundColor: const Color(0xFFC8F2E2),
        foregroundColor: Colors.black,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.folder),
            tooltip: 'Ver histórico',
            onPressed: _abrirHistorico,
          ),
          IconButton(
            icon: const Icon(Icons.share),
            tooltip: 'Compartilhar lista',
            onPressed: _compartilharLista,
          ),
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            tooltip: 'Limpar lista',
            onPressed: _limparLista,
          )
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            alignment: Alignment.center,
            child: Text(
              "Comprados: $comprados de $total",
              style: const TextStyle(fontSize: 16),
            ),
          ),
          Expanded(
            child: _listaItens.isEmpty
                ? const Center(
                    child: Text(
                      "Nenhum item adicionado ainda!",
                      style: TextStyle(fontSize: 16),
                    ),
                  )
                : ListView(
                    children: agrupado.entries.map((grupo) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            child: Text(
                              _emojiCategoria(grupo.key),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                          ),
                          ...grupo.value.map((item) {
                            final index = _listaItens.indexOf(item);
                            return Card(
                              elevation: 2,
                              margin: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 4),
                              child: ListTile(
                                leading: Icon(
                                  item.comprado
                                      ? Icons.check_circle
                                      : Icons.radio_button_unchecked,
                                  color: item.comprado
                                      ? Colors.green
                                      : Colors.grey,
                                ),
                                title: Text(
                                  item.nome,
                                  style: TextStyle(
                                    decoration: item.comprado
                                        ? TextDecoration.lineThrough
                                        : TextDecoration.none,
                                  ),
                                ),
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete,
                                      color: Colors.red),
                                  onPressed: () => _excluirItem(index),
                                ),
                                onTap: () => _marcarComoComprado(index),
                              ),
                            );
                          }),
                        ],
                      );
                    }).toList(),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _adicionarItem,
        backgroundColor: const Color(0xFFFCD74B),
        child: const Icon(Icons.add, color: Colors.black),
      ),
    );
  }
}
