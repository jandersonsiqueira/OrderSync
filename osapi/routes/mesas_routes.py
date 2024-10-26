# mesas_routes.py
from flask import Blueprint, jsonify, request
from bson.objectid import ObjectId
from ..db import mesas_collection  # Importa do db.py

mesas_bp = Blueprint('mesas', __name__)

@mesas_bp.route('/mesas', methods=['POST'])
def criar_mesa():
    dados = request.json
    nova_mesa = {
        "numero_mesa": dados['numero_mesa'],
        "status": dados.get('status', 'livre'),
        "observacao": dados.get('observacao', '')
    }
    mesas_collection.insert_one(nova_mesa)
    return jsonify({"msg": "Mesa criada com sucesso!", "mesa": nova_mesa}), 201

@mesas_bp.route('/mesas', methods=['GET'])
def listar_mesas():
    mesas = list(mesas_collection.find())
    for mesa in mesas:
        mesa['_id'] = str(mesa['_id'])
    return jsonify(mesas), 200

@mesas_bp.route('/mesas/<int:num>', methods=['GET'])
def consultar_mesa(num):
    mesa = mesas_collection.find_one({"numero_mesa": num})
    if mesa:
        mesa['_id'] = str(mesa['_id'])
        return jsonify(mesa), 200
    return jsonify({"msg": "Mesa não encontrada!"}), 404

@mesas_bp.route('/mesas/<int:num>', methods=['PUT'])
def atualizar_mesa(num):
    dados = request.json
    mesa = mesas_collection.find_one({"numero_mesa": num})
    if mesa:
        mesas_collection.update_one({"numero_mesa": num}, {"$set": {"status": dados.get('status', mesa['status'])}})
        return jsonify({"msg": "Mesa atualizada com sucesso!", "numero_mesa": num}), 200
    return jsonify({"msg": "Mesa não encontrada!"}), 404
