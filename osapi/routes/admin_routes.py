from flask import Blueprint, jsonify, request
from firebase_admin import auth
from pymongo import MongoClient
from ..db import client

admin_bp = Blueprint('admin', __name__)

@admin_bp.route('/create-admin', methods=['POST'])
def create_admin():
    try:
        data = request.json
        token = data.get('token')

        if not token:
            return jsonify({"error": "Token é obrigatório"}), 400

        admin_db = client[token]
        admin_db.create_collection('mesas')
        admin_db.create_collection('produto')
        admin_db.create_collection('categoria_produto')
        admin_db.create_collection('pedido_parcial')
        admin_db.create_collection('item_pedido_parcial')
        admin_db.create_collection('pedido')
        admin_db.create_collection('item_pedido')

        return jsonify({"message": "Base de dados e coleções criadas com sucesso"}), 201
    except Exception as e:
        return jsonify({"error": str(e)}), 400