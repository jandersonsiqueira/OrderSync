from flask import Blueprint, jsonify, request
from bson import ObjectId 
from ..db import pedido_parcial_collection, item_pedido_parcial_collection

pedidos_bp = Blueprint('pedidos', __name__)

@pedidos_bp.route('/pedidos/parcial', methods=['POST'])
def criar_pedido_parcial():
    dados = request.json
    cd_pedido = dados['cd_pedido']
    numero_mesa = dados['numero_mesa']
    dt_emissao = dados['dt_emissao']
    vr_pedido = dados['vr_pedido']
    itens = dados['itens']

    # Criar o pedido parcial
    pedido_parcial = {
        "cd_pedido": cd_pedido,
        "numero_mesa": numero_mesa,
        "dt_emissao": dt_emissao,
        "vr_pedido": vr_pedido
    }
    result = pedido_parcial_collection.insert_one(pedido_parcial)

    # Atualizar o pedido com o ID inserido e converter para string
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


# Rota para listar pedidos parciais filtrando pelo número da mesa
@pedidos_bp.route('/pedidos/parcial', methods=['GET'])
def listar_pedidos_parciais():
    numero_mesa = request.args.get('numero_mesa')  # Obtém o número da mesa dos parâmetros de consulta

    if numero_mesa:
        pedidos = list(pedido_parcial_collection.find({"numero_mesa": numero_mesa}))
    else:
        pedidos = list(pedido_parcial_collection.find())

    for pedido in pedidos:
        pedido['_id'] = str(pedido['_id'])  # Converter ObjectId para string
        
        # Buscar os itens do pedido
        itens = list(item_pedido_parcial_collection.find({"cd_pedido": pedido['cd_pedido']}))
        
        # Converter ObjectId para string e adicionar os itens ao pedido
        for item in itens:
            item['_id'] = str(item['_id'])  # Converter ObjectId para string
        pedido['itens'] = itens  # Adiciona a lista de itens ao pedido

    return jsonify(pedidos), 200

