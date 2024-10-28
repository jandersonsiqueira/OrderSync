from flask import Blueprint, jsonify, request
from bson import ObjectId 
from ..db import pedido_parcial_collection, item_pedido_parcial_collection, pedido_collection, item_pedido_collection
from datetime import datetime

pedido_final_bp = Blueprint('pedido_final', __name__)

@pedido_final_bp.route('/pedidos/final', methods=['POST'])
def finalizar_atendimento():
    dados = request.json
    cd_pedido = dados['cd_pedido']
    numero_mesa = dados['numero_mesa']
    dt_emissao = dados['dt_emissao']
    
    # Obter todos os pedidos parciais da mesa
    pedidos_parciais = list(pedido_parcial_collection.find({"numero_mesa": numero_mesa}))
    
    if not pedidos_parciais:
        return jsonify({"msg": "Nenhum pedido parcial encontrado para a mesa informada."}), 404

    # Calcular o valor total do pedido finalizado
    vr_pedido = sum(pedido['vr_pedido'] for pedido in pedidos_parciais)

    # Criar o pedido na tabela 'pedido'
    pedido_final = {
        "cd_pedido": cd_pedido,
        "numero_mesa": numero_mesa,
        "dt_emissao": dt_emissao,
        "vr_pedido": vr_pedido
    }
    pedido_collection.insert_one(pedido_final)

    # Transferir itens dos pedidos parciais para 'item_pedido'
    for pedido in pedidos_parciais:
        itens_parciais = list(item_pedido_parcial_collection.find({"cd_pedido": pedido['cd_pedido']}))
        for item in itens_parciais:
            item_pedido = {
                "cd_pedido": cd_pedido,
                "cd_produto": item['cd_produto'],
                "pr_venda": item['pr_venda'],
                "qt_item": item['qt_item'],
                "observacao": item.get('observacao', '')
            }
            item_pedido_collection.insert_one(item_pedido)

    # Remover pedidos parciais e itens parciais da mesa
    pedido_parcial_collection.delete_many({"numero_mesa": numero_mesa})
    item_pedido_parcial_collection.delete_many({"cd_pedido": {"$in": [pedido['cd_pedido'] for pedido in pedidos_parciais]}})

    return jsonify({"msg": "Atendimento finalizado e pedidos transferidos com sucesso!", "cd_pedido": cd_pedido}), 200
