import 'package:flutter/material.dart';

class FechamentoPedidoPage extends StatelessWidget {
  final Map<String, dynamic> carrinho;
  final String mesaId;

  const FechamentoPedidoPage({Key? key, required this.carrinho, required this.mesaId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    double totalPedido = carrinho.values
        .map((item) => item['produto']['pr_venda'] * item['quantidade'])
        .reduce((value, element) => value + element);

    return Scaffold(
      appBar: AppBar(
        title: Text('Resumo do Pedido - Mesa $mesaId'),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: carrinho.length,
              itemBuilder: (context, index) {
                final produto = carrinho.values.elementAt(index)['produto'];
                final quantidade = carrinho.values.elementAt(index)['quantidade'];
                final totalProduto = produto['pr_venda'] * quantidade;

                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Theme.of(context).primaryColor,
                    child: Text(
                        produto['cd_produto'].toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        )
                    ),
                  ),
                  title: Text(produto['nm_produto']),
                  subtitle: Text('Quantidade: $quantidade'),
                  trailing: Text(
                    'R\$ $totalProduto',
                    style: const TextStyle(
                      color: Colors.green,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Total do Pedido: R\$ $totalPedido',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
