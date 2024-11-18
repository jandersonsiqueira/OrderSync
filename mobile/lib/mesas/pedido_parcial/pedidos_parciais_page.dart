import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:order_sync/mesas/pedido_parcial/pedidos_parciais_detalhes_page.dart';

import '../../variaveis_globais.dart';

class PedidosParciaisPage extends StatefulWidget {
  final String mesaId;

  const PedidosParciaisPage({Key? key, required this.mesaId}) : super(key: key);

  @override
  _PedidosParciaisPageState createState() => _PedidosParciaisPageState();
}

class _PedidosParciaisPageState extends State<PedidosParciaisPage> {
  List<dynamic> pedidos = [];
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
      _fetchPedidos();
    }
  }

  Future<void> _fetchPedidos() async {
    final response = await http.get(Uri.parse('https://ordersync.onrender.com/$uid/pedidos/parcial?numero_mesa=${widget.mesaId}'));

    if (response.statusCode == 200) {
      setState(() {
        pedidos = json.decode(response.body);
        isLoading = false;
      });
    } else {
      setState(() {
        isLoading = false;
      });
      throw Exception('Falha ao carregar pedidos');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
            'Pedidos Parciais',
            style: const TextStyle(
              color: Colors.white,
            )
        ),
        centerTitle: true,
        backgroundColor: Theme.of(context).primaryColor,
        iconTheme: const IconThemeData(
          color: Colors.white,
        ),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : pedidos.isEmpty
          ? Center(
        child: Text(
          'Nenhum pedido encontrado.',
          style: TextStyle(fontSize: 18, color: Colors.grey),
        ),
      )
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView.builder(
          itemCount: pedidos.length,
          itemBuilder: (context, index) {
            final pedido = pedidos[index];
            DateTime dtEmissao = DateTime.parse(pedido['dt_emissao']);
            String dtEmissaoFormatada = DateFormat('dd/MM/yyyy HH:mm:ss').format(dtEmissao);

            return Card(
              margin: const EdgeInsets.symmetric(vertical: 8.0),
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.all(16.0),
                title: Text(
                  'Código do Pedido: ${pedido['cd_pedido']}',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 4),
                    Text('Data Emissão: $dtEmissaoFormatada', style: TextStyle(fontSize: 16)),
                  ],
                ),
                trailing: Icon(Icons.arrow_forward, color: Theme.of(context).canvasColor),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PedidoDetalhesPage(pedido: pedido),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}
