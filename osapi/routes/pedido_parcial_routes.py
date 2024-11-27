from flask import Blueprint, jsonify, request
from bson import ObjectId
from ..db import get_collection

pedido_parcial_bp = Blueprint('pedido_parcial', __name__)

# Rota para criar um pedido parcial usando <uid>
@pedido_parcial_bp.route('/<uid>/pedidos/parcial', methods=['POST'])
def criar_pedido_parcial(uid):
    dados = request.json
    cd_pedido = dados['cd_pedido']
    numero_mesa = dados['numero_mesa']
    dt_emissao = dados['dt_emissao']
    vr_pedido = dados['vr_pedido']
    itens = dados['itens']

    # Obtendo as coleções usando get_collection
    pedido_parcial_collection = get_collection(uid, 'pedido_parcial')
    item_pedido_parcial_collection = get_collection(uid, 'item_pedido_parcial')

    # Criar o pedido parcial
    pedido_parcial = {
        "cd_pedido": cd_pedido,
        "numero_mesa": numero_mesa,
        "dt_emissao": dt_emissao,
        "vr_pedido": vr_pedido
    }
    result = pedido_parcial_collection.insert_one(pedido_parcial)
    pedido_parcial['_id'] = str(result.inserted_id)

    # Criar os itens do pedido
    for item in itens:
        item_pedido_parcial = {
            "cd_pedido": cd_pedido,
            "cd_produto": item['cd_produto'],
            "pr_venda": item['pr_venda'],
            "qt_item": item['qt_item'],
            "observacao": item.get('observacao', '')
        }
        item_pedido_parcial_collection.insert_one(item_pedido_parcial)

    return jsonify({"msg": "Pedido parcial criado com sucesso!", "pedido": pedido_parcial}), 201

# Rota para listar pedidos parciais filtrando pelo número da mesa usando <uid>
@pedido_parcial_bp.route('/<uid>/pedidos/parcial', methods=['GET'])
def listar_pedidos_parciais(uid):
    numero_mesa = request.args.get('numero_mesa')

    # Obtendo as coleções usando get_collection
    pedido_parcial_collection = get_collection(uid, 'pedido_parcial')
    item_pedido_parcial_collection = get_collection(uid, 'item_pedido_parcial')
    produto_collection = get_collection(uid, 'produto')

    # Filtragem por número da mesa, se fornecido
    filtro = {"numero_mesa": numero_mesa} if numero_mesa else {}
    pedidos = list(pedido_parcial_collection.find(filtro))

    for pedido in pedidos:
        pedido['_id'] = str(pedido['_id'])  # Converter ObjectId para string

        # Buscar os itens do pedido
        itens = list(item_pedido_parcial_collection.find({"cd_pedido": pedido['cd_pedido']}))

        # Converter ObjectId para string e adicionar os itens ao pedido
        for item in itens:
            item['_id'] = str(item['_id'])

            produto = produto_collection.find_one({"cd_produto": item['cd_produto']})

            if produto:
                item['nm_produto'] = produto['nm_produto']
            else:
                item['nm_produto'] = "Produto não encontrado"
        
        pedido['itens'] = itens

    return jsonify(pedidos), 200