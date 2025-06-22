import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HistoricoPage extends StatefulWidget {
  final void Function(List<Map<String, dynamic>>) onSelecionarLista;

  const HistoricoPage({Key? key, required this.onSelecionarLista})
      : super(key: key);

  @override
  State<HistoricoPage> createState() => _HistoricoPageState();
}

class _HistoricoPageState extends State<HistoricoPage> {
  List<String> _listasSalvas = [];

  @override
  void initState() {
    super.initState();
    _carregarHistorico();
  }

  Future<void> _carregarHistorico() async {
    final prefs = await SharedPreferences.getInstance();
    final listas = prefs.getStringList('historico_listas') ?? [];
    setState(() => _listasSalvas = listas);
  }

  Future<void> _limparHistorico() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('historico_listas');
    setState(() => _listasSalvas.clear());
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Histórico apagado com sucesso!")),
    );
  }

  void _restaurarLista(String jsonLista) {
    final lista = json.decode(jsonLista) as List;
    widget.onSelecionarLista(List<Map<String, dynamic>>.from(lista));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("📁 Histórico de Listas"),
        backgroundColor: const Color(0xFFC8F2E2),
        foregroundColor: Colors.black,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_forever),
            tooltip: "Apagar histórico",
            onPressed: () {
              showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text("Confirmar"),
                  content:
                      const Text("Deseja apagar todo o histórico de listas?"),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("Cancelar"),
                    ),
                    TextButton(
                      onPressed: () {
                        _limparHistorico();
                        Navigator.pop(context);
                      },
                      child: const Text("Apagar"),
                    ),
                  ],
                ),
              );
            },
          )
        ],
      ),
      body: _listasSalvas.isEmpty
          ? const Center(child: Text("Nenhuma lista salva no histórico."))
          : ListView.builder(
              itemCount: _listasSalvas.length,
              itemBuilder: (context, index) {
                final listaJson = _listasSalvas[index];
                final data = json.decode(listaJson) as List;
                final preview = data.map((e) => e['nome']).join(", ");

                return ListTile(
                  title: Text("Lista #${index + 1}"),
                  subtitle: Text(preview,
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  trailing: const Icon(Icons.restore),
                  onTap: () => _restaurarLista(listaJson),
                );
              },
            ),
    );
  }
}
