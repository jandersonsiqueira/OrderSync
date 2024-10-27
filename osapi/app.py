from flask import Flask
from .routes.mesas_routes import mesas_bp
from .routes.produtos_routes import produtos_bp
from .routes.categorias_routes import categorias_bp
from .routes.pedido_parcial_routes import pedidos_bp

app = Flask(__name__)

# Registro dos blueprints
app.register_blueprint(mesas_bp)
app.register_blueprint(produtos_bp)
app.register_blueprint(categorias_bp)
app.register_blueprint(pedidos_bp)

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
