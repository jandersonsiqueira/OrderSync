from flask import Blueprint, jsonify, request
from ..db import get_collection

mesas_bp = Blueprint('mesas', __name__)

@mesas_bp.route('/<string:uid>/mesas', methods=['POST'])
def criar_mesa(uid):
    try:
        mesas_collection = get_collection(uid, 'mesas')
        dados = request.json
    
        if not dados:
            return jsonify({"error": "Dados inválidos ou ausentes"}), 400

        # Se os dados forem um dicionário (criação de uma única mesa)
        if isinstance(dados, dict) and 'numero_mesa' in dados:
            numero_mesa = dados['numero_mesa']

            # Verifica se a mesa já existe
            if mesas_collection.find_one({"numero_mesa": numero_mesa}):
                return jsonify({"error": f"Mesa {numero_mesa} já existe"}), 400

            nova_mesa = {
                "numero_mesa": numero_mesa,
                "status": dados.get('status', 'livre'),
                "observacao": dados.get('observacao', '')
            }
            mesas_collection.insert_one(nova_mesa)
            nova_mesa['_id'] = str(nova_mesa['_id'])
            
            return jsonify({"msg": "Mesa criada com sucesso!", "mesa": nova_mesa}), 201

        # Se os dados forem uma lista (criação em lote de mesas)
        elif isinstance(dados, list):

            novas_mesas = []
            for mesa_dados in dados:
                if 'numero_mesa' not in mesa_dados:
                    return jsonify({"error": "Cada item da lista deve conter o campo 'numero_mesa'"}), 400

                numero_mesa = mesa_dados['numero_mesa']

                # Verifica se a mesa já existe
                if mesas_collection.find_one({"numero_mesa": numero_mesa}):
                    return jsonify({"error": f"Mesa {numero_mesa} já existe"}), 400

                nova_mesa = {
                    "numero_mesa": numero_mesa,
                    "status": mesa_dados.get('status', 'livre'),
                    "observacao": mesa_dados.get('observacao', '')
                }
                novas_mesas.append(nova_mesa)

            if novas_mesas:
                mesas_collection.insert_many(novas_mesas)
                for mesa in novas_mesas:
                    mesa['_id'] = str(mesa['_id'])

            return jsonify({"msg": "Mesas criadas com sucesso!", "mesas": novas_mesas}), 201

        else:
            return jsonify({"error": "Formato de dados inválido"}), 400

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