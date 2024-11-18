import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../variaveis_globais.dart';

class VendasPage extends StatefulWidget {
  @override
  _VendasPageState createState() => _VendasPageState();
}

class _VendasPageState extends State<VendasPage> {
  DateTime dtInicial = DateTime.now();
  DateTime dtFinal = DateTime.now();
  String numeroMesa = '';
  List<dynamic> pedidos = [];
  bool showFilters = false;
  bool isLoading = false;
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
      _buscarPedidos();
    }
  }

  Future<void> _buscarPedidos() async {
    setState(() {
      isLoading = true;
    });

    final response = await http.get(
      Uri.parse('https://ordersync.onrender.com/$uid/pedidos/final?dt_inicial=${DateFormat('yyyy-MM-dd').format(dtInicial)}&dt_final=${DateFormat('yyyy-MM-dd').format(dtFinal)}&numero_mesa=$numeroMesa'),
    );

    if (response.statusCode == 200) {
      setState(() {
        pedidos = json.decode(response.body);
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao buscar pedidos')));
    }

    setState(() {
      isLoading = false;
      showFilters = false;
    });
  }

  void _selectDate(DateTime initialDate, bool isStartDate) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != initialDate) {
      setState(() {
        if (isStartDate) {
          dtInicial = picked;
        } else {
          dtFinal = picked;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    int totalPedidos = pedidos.length;
    double valorTotal = pedidos.fold(0.0, (sum, pedido) => sum + pedido['vr_pedido']);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Vendas',
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: Theme.of(context).primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Filtros',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                    IconButton(
                      icon: Icon(
                        showFilters ? Icons.expand_less : Icons.expand_more,
                        color: Theme.of(context).primaryColor,
                      ),
                      onPressed: () {
                        setState(() {
                          showFilters = !showFilters;
                        });
                      },
                    ),
                  ],
                ),
                if (showFilters)
                  Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    elevation: 3,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Data Inicial:',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              Text('${DateFormat('dd/MM/yyyy').format(dtInicial)}'),
                              IconButton(
                                icon: Icon(Icons.calendar_today, color: Theme.of(context).primaryColor),
                                onPressed: () => _selectDate(dtInicial, true),
                              ),
                            ],
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Data Final:',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              Text('${DateFormat('dd/MM/yyyy').format(dtFinal)}'),
                              IconButton(
                                icon: Icon(Icons.calendar_today, color: Theme.of(context).primaryColor),
                                onPressed: () => _selectDate(dtFinal, false),
                              ),
                            ],
                          ),
                          TextField(
                            decoration: InputDecoration(
                              labelText: 'Número da Mesa',
                              labelStyle: TextStyle(color: Theme.of(context).canvasColor),
                              enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(color: Theme.of(context).canvasColor),
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(color: Theme.of(context).primaryColor),
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                            ),
                            onChanged: (value) {
                              setState(() {
                                numeroMesa = value;
                              });
                            },
                          ),
                          SizedBox(height: 10),
                          ElevatedButton.icon(
                            onPressed: _buscarPedidos,
                            icon: Icon(Icons.search, color: Colors.white),
                            label: Text(
                              'Buscar',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context).primaryColor,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                SizedBox(height: 20),
                Expanded(
                  child: pedidos.isEmpty
                      ? Center(
                    child: Text(
                      'Nenhum pedido encontrado.',
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                      : ListView.builder(
                    itemCount: pedidos.length,
                    itemBuilder: (context, index) {
                      final pedido = pedidos[index];
                      DateTime dtEmissao = DateTime.parse(pedido['dt_emissao']);
                      String dtEmissaoFormatada = DateFormat('dd/MM/yyyy HH:mm:ss').format(dtEmissao);
                      return Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        elevation: 3,
                        margin: EdgeInsets.symmetric(vertical: 8.0),
                        child: ListTile(
                          contentPadding: EdgeInsets.all(16.0),
                          title: Text(
                            'Pedido: ${pedido['cd_pedido']}',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(height: 4),
                              Text('Mesa: ${pedido['numero_mesa']}'),
                              SizedBox(height: 4),
                              Text('Data: $dtEmissaoFormatada'),
                              SizedBox(height: 4),
                              Text('Total: R\$ ${pedido['vr_pedido']}'),
                            ],
                          ),
                          leading: CircleAvatar(
                            backgroundColor: Theme.of(context).primaryColor,
                            child: Icon(Icons.receipt_long, color: Colors.white),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total de Pedidos: $totalPedidos',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Valor Total: R\$ ${valorTotal.toStringAsFixed(2)}',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (isLoading)
            Container(
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }
}
