import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class PedidoDetalhesPage extends StatelessWidget {
  final dynamic pedido;

  const PedidoDetalhesPage({Key? key, required this.pedido}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    DateTime dtEmissao = DateTime.parse(pedido['dt_emissao']);
    String dtEmissaoFormatada = DateFormat('dd/MM/yyyy HH:mm:ss').format(dtEmissao);

    return Scaffold(
      appBar: AppBar(
        title: Text('Detalhes do Pedido ${pedido['cd_pedido']}'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cabeçalho com informações do pedido
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
                        'Código do Pedido: ${pedido['cd_pedido']}',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Número da Mesa: ${pedido['numero_mesa']}',
                        style: TextStyle(fontSize: 18),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Data Emissão: $dtEmissaoFormatada',
                        style: TextStyle(fontSize: 18),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Valor Total: R\$ ${pedido['vr_pedido'].toStringAsFixed(2)}',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 16),
              Text(
                'Itens do Pedido:',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              // Lista de itens
              ListView.builder(
                itemCount: pedido['itens'].length,
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(), // Para evitar scroll na lista
                itemBuilder: (context, index) {
                  final item = pedido['itens'][index];
                  double subtotal = item['pr_venda'] * item['qt_item']; // Calcular subtotal do item

                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8.0),
                    elevation: 3,
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        children: [
                          Icon(Icons.fastfood, color: Theme.of(context).primaryColor),
                          SizedBox(width: 10), // Espaço entre ícone e texto
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Produto: ${item['cd_produto']}',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                SizedBox(height: 4),
                                Text('Preço: R\$ ${item['pr_venda'].toStringAsFixed(2)}'),
                                Text('Quantidade: ${item['qt_item']}'),
                                Text('Observação: ${item['observacao']}'),
                                Text('Subtotal: R\$ ${subtotal.toStringAsFixed(2)}'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}