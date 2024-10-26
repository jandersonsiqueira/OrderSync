# categorias_routes.py
from flask import Blueprint, jsonify, request
from bson.objectid import ObjectId
from ..db import categorias_collection  # Importa do db.py

# Criação do Blueprint para categorias
categorias_bp = Blueprint('categorias', __name__)

@categorias_bp.route('/categorias', methods=['POST'])
def criar_categoria():
    dados = request.json
    nova_categoria = {
        "cd_categoria": dados['cd_categoria'],
        "nm_categoria": dados['nm_categoria']
    }
    categorias_collection.insert_one(nova_categoria)
    return jsonify({"msg": "Categoria criada com sucesso!", "categoria": nova_categoria}), 201

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
