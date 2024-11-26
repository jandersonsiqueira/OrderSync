from flask import Flask, jsonify
from .routes.mesas_routes import mesas_bp
from .routes.produtos_routes import produtos_bp
from .routes.categorias_routes import categorias_bp
from .routes.pedido_parcial_routes import pedido_parcial_bp
from .routes.pedido_final_routes import pedido_final_bp
from .routes.admin_routes import admin_bp

app = Flask(__name__)

# Registro dos blueprints
app.register_blueprint(mesas_bp)
app.register_blueprint(produtos_bp)
app.register_blueprint(categorias_bp)
app.register_blueprint(pedido_parcial_bp)
app.register_blueprint(pedido_final_bp)
app.register_blueprint(admin_bp)

# Rota para verificar o status do serviço
@app.route('/about', methods=['GET'])
def about():
    return jsonify({
        "status": "active",
        "service": "Sistema de Gerenciamento para Restaurantes e Bares",
        "version": "1.0.0"
    }), 200

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)