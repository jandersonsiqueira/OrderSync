# produtos_routes.py
from flask import Blueprint, jsonify, request
from bson.objectid import ObjectId
from ..db import produtos_collection  # Importa do db.py

# Criação do Blueprint para produtos
produtos_bp = Blueprint('produtos', __name__)

@produtos_bp.route('/produtos', methods=['POST'])
def criar_produto():
    dados = request.json
    novo_produto = {
        "cd_produto": dados['cd_produto'],
        "nm_produto": dados['nm_produto'],
        "pr_custo": dados['pr_custo'],
        "pr_venda": dados['pr_venda'],
        "cd_categoria": dados['cd_categoria']
    }
    produtos_collection.insert_one(novo_produto)
    return jsonify({"msg": "Produto criado com sucesso!", "produto": novo_produto}), 201

@produtos_bp.route('/produtos', methods=['GET'])
def listar_produtos():
    produtos = list(produtos_collection.find())
    for produto in produtos:
        produto['_id'] = str(produto['_id'])
    return jsonify(produtos), 200

@produtos_bp.route('/produtos/<int:cd_produto>', methods=['GET'])
def consultar_produto(cd_produto):
    produto = produtos_collection.find_one({"cd_produto": cd_produto})
    if produto:
        produto['_id'] = str(produto['_id'])
        return jsonify(produto), 200
    return jsonify({"msg": "Produto não encontrado!"}), 404

@produtos_bp.route('/produtos/<int:cd_produto>', methods=['PUT'])
def atualizar_produto(cd_produto):
    dados = request.json
    produto = produtos_collection.find_one({"cd_produto": cd_produto})
    if produto:
        produtos_collection.update_one(
            {"cd_produto": cd_produto},
            {"$set": {
                "nm_produto": dados.get('nm_produto', produto['nm_produto']),
                "pr_custo": dados.get('pr_custo', produto['pr_custo']),
                "pr_venda": dados.get('pr_venda', produto['pr_venda']),
                "cd_categoria": dados.get('cd_categoria', produto['cd_categoria'])
            }}
        )
        return jsonify({"msg": "Produto atualizado com sucesso!"}), 200
    return jsonify({"msg": "Produto não encontrado!"}), 404
