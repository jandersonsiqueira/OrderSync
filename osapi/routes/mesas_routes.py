from flask import Blueprint, jsonify, request
from ..db import get_collection

mesas_bp = Blueprint('mesas', __name__)

@mesas_bp.route('/<string:uid>/mesas', methods=['POST'])
def criar_mesa(uid):
    try:
        mesas_collection = get_collection(uid, 'mesas')

        dados = request.json
        if not dados or 'numero_mesa' not in dados:
            return jsonify({"error": "Campo 'numero_mesa' é obrigatório"}), 400

        nova_mesa = {
            "numero_mesa": dados['numero_mesa'],
            "status": dados.get('status', 'livre'),
            "observacao": dados.get('observacao', '')
        }
        mesas_collection.insert_one(nova_mesa)
        nova_mesa['_id'] = str(nova_mesa['_id'])
        
        return jsonify({"msg": "Mesa criada com sucesso!", "mesa": nova_mesa}), 201

    except Exception as e:
        return jsonify({"error": str(e)}), 500

@mesas_bp.route('/<string:uid>/mesas', methods=['GET'])
def listar_mesas(uid):
    try:
        mesas_collection = get_collection(uid, 'mesas')
        
        mesas = list(mesas_collection.find())
        for mesa in mesas:
            mesa['_id'] = str(mesa['_id'])
        return jsonify(mesas), 200

    except Exception as e:
        return jsonify({"error": str(e)}), 500

@mesas_bp.route('/<string:uid>/mesas/<int:num>', methods=['GET'])
def consultar_mesa(uid, num):
    try:
        mesas_collection = get_collection(uid, 'mesas')
        
        mesa = mesas_collection.find_one({"numero_mesa": num})
        if mesa:
            mesa['_id'] = str(mesa['_id'])
            return jsonify(mesa), 200
        return jsonify({"msg": "Mesa não encontrada!"}), 404

    except Exception as e:
        return jsonify({"error": str(e)}), 500

@mesas_bp.route('/<string:uid>/mesas/<int:num>', methods=['PUT'])
def atualizar_mesa(uid, num):
    try:
        mesas_collection = get_collection(uid, 'mesas')
        
        dados = request.json
        mesa = mesas_collection.find_one({"numero_mesa": num})
        if mesa:
            mesas_collection.update_one(
                {"numero_mesa": num},
                {"$set": {
                    "status": dados.get('status', mesa['status']),
                    "observacao": dados.get('observacao', mesa.get('observacao', ''))
                }}
            )
            return jsonify({"msg": "Mesa atualizada com sucesso!", "numero_mesa": num}), 200
        return jsonify({"msg": "Mesa não encontrada!"}), 404

    except Exception as e:
        return jsonify({"error": str(e)}), 500