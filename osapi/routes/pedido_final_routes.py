from flask import Blueprint, jsonify, request
from bson import ObjectId
from datetime import datetime, timedelta
from ..db import get_collection

pedido_final_bp = Blueprint('pedido_final', __name__)

# Rota para finalizar atendimento
@pedido_final_bp.route('/<string:uid>/pedidos/final', methods=['POST'])
def finalizar_atendimento(uid):
    try:
        # Obtém as coleções específicas usando a função genérica
        pedido_parcial_collection = get_collection(uid, 'pedido_parcial')
        item_pedido_parcial_collection = get_collection(uid, 'item_pedido_parcial')
        pedido_collection = get_collection(uid, 'pedido')
        item_pedido_collection = get_collection(uid, 'item_pedido')

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

    except Exception as e:
        return jsonify({"error": str(e)}), 500

# Rota para listar pedidos
@pedido_final_bp.route('/<string:uid>/pedidos/final', methods=['GET'])
def listar_pedidos(uid):
    try:
        # Obtém as coleções específicas usando a função genérica
        pedido_collection = get_collection(uid, 'pedido')
        item_pedido_collection = get_collection(uid, 'item_pedido')

        numero_mesa = request.args.get('numero_mesa')
        dt_inicial = request.args.get('dt_inicial')
        dt_final = request.args.get('dt_final')
        cd_pedido = request.args.get('cd_pedido')

        # Inicializa o filtro
        filtro = {}

        # Adiciona filtros conforme necessário
        if cd_pedido:
            filtro['cd_pedido'] = cd_pedido
        elif numero_mesa:
            filtro['numero_mesa'] = numero_mesa

        # Busca os pedidos com o filtro aplicado
        pedidos = list(pedido_collection.find(filtro))

        # Converte as datas recebidas para objetos datetime
        if dt_inicial and dt_final:
            try:
                dt_inicial = datetime.strptime(dt_inicial, '%Y-%m-%d')
                dt_final = datetime.strptime(dt_final, '%Y-%m-%d') + timedelta(days=1) - timedelta(seconds=1)

                # Filtra os pedidos com base na dt_emissao
                pedidos = [pedido for pedido in pedidos 
                           if dt_inicial <= datetime.fromisoformat(pedido['dt_emissao'][:-1]) <= dt_final]
            
            except ValueError:
                return jsonify({"msg": "Data inválida, utilize o formato YYYY-MM-DD."}), 400

        # Adiciona os itens ao pedido
        for pedido in pedidos:
            pedido['_id'] = str(pedido['_id'])

            # Buscar os itens do pedido
            itens = list(item_pedido_collection.find({"cd_pedido": pedido['cd_pedido']}))
            
            # Converter ObjectId para string e adicionar os itens ao pedido
            for item in itens:
                item['_id'] = str(item['_id'])
            pedido['itens'] = itens

        return jsonify(pedidos), 200

    except Exception as e:
        return jsonify({"error": str(e)}), 500