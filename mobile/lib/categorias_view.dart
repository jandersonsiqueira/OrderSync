import 'package:flutter/material.dart';

class CategoriasView extends StatelessWidget {
  final List<dynamic> categorias;
  final Function(String) onCategoriaTap;

  const CategoriasView({
    Key? key,
    required this.categorias,
    required this.onCategoriaTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return categorias.isEmpty
        ? const Center(child: CircularProgressIndicator())
        : GridView.builder(
      padding: const EdgeInsets.all(8.0),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 1.0,
      ),
      itemCount: categorias.length,
      itemBuilder: (context, index) {
        final categoria = categorias[index];
        return GestureDetector(
          onTap: () => onCategoriaTap(categoria['cd_categoria'].toString()),
          child: Container(
            margin: const EdgeInsets.all(4.0),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
              borderRadius: BorderRadius.circular(8),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: Text(
                categoria['nm_categoria'],
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
