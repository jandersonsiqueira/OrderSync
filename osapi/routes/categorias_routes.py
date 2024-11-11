# categorias_routes.py
from flask import Blueprint, jsonify, request
from bson.objectid import ObjectId
from ..db import categorias_collection
from pymongo import DESCENDING

# Criação do Blueprint para categorias
categorias_bp = Blueprint('categorias', __name__)

@categorias_bp.route('/categorias', methods=['POST'])
def criar_categoria():
    try:
        dados = request.json
        if not dados or 'nm_categoria' not in dados:
            return jsonify({"error": "Campo 'nm_categoria' é obrigatório"}), 400

        ultima_categoria = categorias_collection.find_one(sort=[("cd_categoria", -1)])
        novo_cd_categoria = 1 if not ultima_categoria else ultima_categoria.get('cd_categoria', 0) + 1

        nova_categoria = {
            "cd_categoria": novo_cd_categoria,
            "nm_categoria": dados['nm_categoria']
        }
        resultado = categorias_collection.insert_one(nova_categoria)
        
        nova_categoria['_id'] = str(resultado.inserted_id)

        return jsonify({"msg": "Categoria criada com sucesso!", "categoria": nova_categoria}), 201

    except Exception as e:
        return jsonify({"error": str(e)}), 500

@categorias_bp.route('/categorias', methods=['GET'])
def listar_categorias():
    categorias = list(categorias_collection.find())
    for categoria in categorias:
        categoria['_id'] = str(categoria['_id'])
    return jsonify(categorias), 200

@categorias_bp.route('/categorias/<int:cd_categoria>', methods=['GET'])
def consultar_categoria(cd_categoria):
    categoria = categorias_collection.find_one({"cd_categoria": cd_categoria})
    if categoria:
        categoria['_id'] = str(categoria['_id'])
        return jsonify(categoria), 200
    return jsonify({"msg": "Categoria não encontrada!"}), 404

@categorias_bp.route('/categorias/<int:cd_categoria>', methods=['PUT'])
def atualizar_categoria(cd_categoria):
    dados = request.json
    categoria = categorias_collection.find_one({"cd_categoria": cd_categoria})
    if categoria:
        categorias_collection.update_one(
            {"cd_categoria": cd_categoria},
            {"$set": {"nm_categoria": dados.get('nm_categoria', categoria['nm_categoria'])}}
        )
        return jsonify({"msg": "Categoria atualizada com sucesso!"}), 200
    return jsonify({"msg": "Categoria não encontrada!"}), 404
