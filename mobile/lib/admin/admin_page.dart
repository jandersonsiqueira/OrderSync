import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import 'cadastro_categorias/cadastro_categorias.dart';
import 'cadastro_mesas/cadastro_mesas.dart';
import 'cadastro_produtos/cadastro_produtos.dart';

class AdminPage extends StatelessWidget {
  const AdminPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Administração',
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: Theme.of(context).primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 16.0,
          mainAxisSpacing: 16.0,
          children: [
            _adminOptionButton(
              context,
              text: 'Produtos',
              icon: FontAwesomeIcons.box,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CadastroProdutosPage(),
                  ),
                );
              },
            ),
            _adminOptionButton(
              context,
              text: 'Categorias',
              icon: FontAwesomeIcons.list,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CadastroCategoriasPage(),
                  ),
                );
              },
            ),
            _adminOptionButton(
              context,
              text: 'Mesas',
              icon: FontAwesomeIcons.table,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CadastroMesasPage(),
                  ),
                );
              },
            ),
            _adminOptionButton(
              context,
              text: 'Usuários',
              icon: FontAwesomeIcons.user,
              onPressed: () {
               // Navigator.push(
                //  context,
               //   MaterialPageRoute(
                  //  builder: (context) => CadastroUsuariosPage(),
                //  ),
               // );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _adminOptionButton(
      BuildContext context, {
        required String text,
        required IconData icon,
        required VoidCallback onPressed,
      }) {
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.all(16.0),
        side: BorderSide(color: Theme.of(context).primaryColor),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
      ),
      onPressed: onPressed,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FaIcon(
            icon,
            size: 40,
            color: Theme.of(context).primaryColor,
          ),
          const SizedBox(height: 8),
          Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Theme.of(context).primaryColor,
            ),
          ),
        ],
      ),
    );
  }
}
