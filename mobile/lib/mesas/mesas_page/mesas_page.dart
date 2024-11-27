import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../variaveis_globais.dart';
import '../pedido/pedido_page.dart';

class MesasPage extends StatefulWidget {
  const MesasPage({Key? key}) : super(key: key);

  @override
  _MesasPageState createState() => _MesasPageState();
}

class _MesasPageState extends State<MesasPage> {
  List<dynamic> mesas = [];
  List<dynamic> mesasLivres = [];
  List<dynamic> mesasAndamento = [];
  List<dynamic> mesasAguardandoPagamento = [];
  String searchQuery = '';
  bool isLoading = true;
  String? uid;

  @override
  void initState() {
    super.initState();
    _fetchCacheUid();
  }

  Future<void> _fetchCacheUid() async {
    String? cachedUid = await VariaveisGlobais.getUidFromCache();
    setState(() {
      uid = cachedUid;
    });

    if (uid != null) {
      _fetchMesas();
    }
  }

  Future<void> _fetchMesas() async {
    setState(() {
      isLoading = true;
    });

    try {
      final response = await http.get(Uri.parse('$LINK_BASE/$uid/mesas'));
      if (response.statusCode == 200) {
        setState(() {
          mesas = json.decode(response.body);
          _filterMesas();
        });
      } else {
        throw Exception('Falha ao carregar mesas');
      }
    } catch (e) {
      print('Erro: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _filterMesas() {
    mesasLivres = mesas.where((mesa) => mesa['status'] == 'livre').toList();
    mesasAndamento = mesas.where((mesa) => mesa['status'] == 'andamento').toList();
    mesasAguardandoPagamento = mesas.where((mesa) => mesa['status'] == 'aguardando pagamento').toList();
  }

  Future<void> _abrirMesa(String mesaId) async {
    setState(() {
      isLoading = true;
    });

    try {
      final response = await http.put(
        Uri.parse('$LINK_BASE/$uid/mesas/$mesaId'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, String>{
          'status': 'andamento',
        }),
      );

      if (response.statusCode == 200) {
        setState(() {
          mesasLivres.removeWhere((mesa) => mesa['numero_mesa'].toString() == mesaId);
          mesasAndamento.add({
            "numero_mesa": mesaId,
            "status": "andamento",
            "observacao": "",
          });
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Mesa $mesaId aberta",
              style: TextStyle(color: Colors.white),
            ),
            duration: const Duration(seconds: 2),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        throw Exception('Falha ao abrir mesa');
      }
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _searchMesas(String query) {
    setState(() {
      searchQuery = query;
      if (query.isNotEmpty) {
        mesasLivres = mesasLivres
            .where((mesa) => mesa['numero_mesa'].toString().contains(query))
            .toList();
        mesasAndamento = mesasAndamento
            .where((mesa) => mesa['numero_mesa'].toString().contains(query))
            .toList();
        mesasAguardandoPagamento = mesasAguardandoPagamento
            .where((mesa) => mesa['numero_mesa'].toString().contains(query))
            .toList();
      } else {
        _filterMesas();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Mesas',
          style: TextStyle(
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        backgroundColor: Theme.of(context).primaryColor,
        iconTheme: const IconThemeData(
          color: Colors.white,
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: isLoading
            ? Center(child: CircularProgressIndicator())
            : Column(
          children: [
            TextField(
              decoration: InputDecoration(
                hintText: 'Pesquisar por número da mesa...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
                prefixIcon: Icon(Icons.search, color: Theme.of(context).canvasColor),
              ),
              onChanged: _searchMesas,
            ),
            const SizedBox(height: 20),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _buildMesaSection('Mesas em Andamento', mesasAndamento, true),
                    const SizedBox(height: 16),
                    _buildMesaSection('Mesas Aguardando Pagamento', mesasAguardandoPagamento, false, isAguardandoPagamento: true),
                    const SizedBox(height: 16),
                    _buildMesaSection('Mesas Livres', mesasLivres, false),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMesaSection(String title, List<dynamic> mesas, bool isAndamento, {bool isAguardandoPagamento = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            title,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            childAspectRatio: 1.0,
          ),
          itemCount: mesas.length,
          itemBuilder: (context, index) {
            final mesa = mesas[index];
            return GestureDetector(
              onTap: () {
                if (!isAndamento && !isAguardandoPagamento) {
                  _abrirMesa(mesa['numero_mesa'].toString());
                } else {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PedidoPage(mesa: mesa),
                    ),
                  );
                }
              },
              child: Container(
                margin: const EdgeInsets.all(4.0),
                decoration: BoxDecoration(
                  color: isAndamento
                      ? Colors.green
                      : isAguardandoPagamento
                      ? Colors.amber
                      : Colors.grey,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (!isAndamento && !isAguardandoPagamento)
                      Text(
                        'ABRIR',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                        ),
                      ),
                    Text(
                      mesa['numero_mesa'].toString(),
                      style: const TextStyle(
                          color: Colors.white, fontSize: 18
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
