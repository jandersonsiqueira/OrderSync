import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class CarrinhoPedidoPage extends StatelessWidget {
  final double subtotal;
  final int quantidadeProdutos;
  final VoidCallback onTap;

  const CarrinhoPedidoPage({
    Key? key,
    required this.subtotal,
    required this.quantidadeProdutos,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(12.0),
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor,
            borderRadius: BorderRadius.circular(12.0),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const FaIcon(
                FontAwesomeIcons.shoppingCart,
                color: Colors.white,
              ),
              const SizedBox(width: 8.0),
              Text(
                'R\$ ${subtotal.toStringAsFixed(2)} • $quantidadeProdutos',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
