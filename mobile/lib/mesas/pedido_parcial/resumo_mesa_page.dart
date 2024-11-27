import 'package:flutter/material.dart';

class ResumoMesaPage extends StatelessWidget {
  final List<dynamic> pedidos;

  const ResumoMesaPage({Key? key, required this.pedidos}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    List<dynamic> todosItens = [];
    double valorTotal = 0;
    final String numeroMesa = pedidos.isNotEmpty ? pedidos.first['numero_mesa'] : 0;

    for (var pedido in pedidos) {
      valorTotal += pedido['vr_pedido'];
      todosItens.addAll(pedido['itens']);
    }

    // Agrupando itens por código e somando as quantidades
    Map<String, dynamic> itensAgrupados = {};
    for (var item in todosItens) {
      if (itensAgrupados.containsKey(item['cd_produto'])) {
        itensAgrupados[item['cd_produto']]['qt_item'] += item['qt_item'];
        itensAgrupados[item['cd_produto']]['subtotal'] += item['pr_venda'] * item['qt_item'];
      } else {
        itensAgrupados[item['cd_produto'].toString()] = {
          'cd_produto': item['cd_produto'],
          'nm_produto': item['nm_produto'],
          'pr_venda': item['pr_venda'],
          'qt_item': item['qt_item'],
          'subtotal': item['pr_venda'] * item['qt_item'],
        };
      }
    }

    List<dynamic> itensResumidos = itensAgrupados.values.toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Resumo da Mesa $numeroMesa',
          style: const TextStyle(
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              margin: const EdgeInsets.symmetric(vertical: 8.0),
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Valor Total: R\$ $valorTotal',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).canvasColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16),
            Text(
              'Itens da Mesa:',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                itemCount: itensResumidos.length,
                itemBuilder: (context, index) {
                  final item = itensResumidos[index];

                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8.0),
                    elevation: 3,
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        children: [
                          Icon(Icons.fastfood, color: Theme.of(context).canvasColor),
                          SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Produto: ${item['nm_produto']}',
                                ),
                                SizedBox(height: 4),
                                Text('Preço Unitário: R\$ ${item['pr_venda'].toStringAsFixed(2)}'),
                                Text('Quantidade: ${item['qt_item']}'),
                                Text('Subtotal: R\$ ${item['subtotal'].toStringAsFixed(2)}'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
