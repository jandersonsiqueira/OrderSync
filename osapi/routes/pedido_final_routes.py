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

        # Consolidar itens dos pedidos parciais para 'item_pedido'
        itens_consolidados = {}
        for pedido in pedidos_parciais:
            itens_parciais = list(item_pedido_parcial_collection.find({"cd_pedido": pedido['cd_pedido']}))
            for item in itens_parciais:
                cd_produto = item['cd_produto']
                if cd_produto in itens_consolidados:
                    itens_consolidados[cd_produto]['qt_item'] += item['qt_item']
                else:
                    itens_consolidados[cd_produto] = {
                        "cd_pedido": cd_pedido,
                        "cd_produto": cd_produto,
                        "pr_venda": item['pr_venda'],
                        "qt_item": item['qt_item'],
                        "observacao": item.get('observacao', '')
                    }

        # Inserir os itens consolidados na coleção 'item_pedido'
        for item_consolidado in itens_consolidados.values():
            item_pedido_collection.insert_one(item_consolidado)

        # Remover pedidos parciais e itens parciais da mesa
        pedido_parcial_collection.delete_many({"numero_mesa": numero_mesa})
        item_pedido_parcial_collection.delete_many({"cd_pedido": {"$in": [pedido['cd_pedido'] for pedido in pedidos_parciais]}})

        return jsonify({"msg": "Atendimento finalizado e pedidos transferidos com sucesso!", "cd_pedido": cd_pedido}), 200

    except Exception as e:
        return jsonify({"error": str(e)}), 500

# Rota para listar pedidos finais
@pedido_final_bp.route('/<string:uid>/pedidos/final', methods=['GET'])
def listar_pedidos(uid):
    try:
        # Obtém as coleções específicas usando a função genérica
        pedido_collection = get_collection(uid, 'pedido')
        item_pedido_collection = get_collection(uid, 'item_pedido')
        produto_collection = get_collection(uid, 'produto')

        # Filtros
        numero_mesa = request.args.get('numero_mesa')
        dt_inicial = request.args.get('dt_inicial')
        dt_final = request.args.get('dt_final')
        cd_pedido = request.args.get('cd_pedido')

        filtro = {}
        if cd_pedido:
            filtro['cd_pedido'] = cd_pedido
        elif numero_mesa:
            filtro['numero_mesa'] = numero_mesa
        
        # Data de filtro
        if dt_inicial and dt_final:
            try:
                dt_inicial = datetime.strptime(dt_inicial, '%Y-%m-%d')
                dt_final = datetime.strptime(dt_final, '%Y-%m-%d') + timedelta(days=1) - timedelta(seconds=1)
                filtro['dt_emissao'] = {"$gte": dt_inicial.isoformat(), "$lte": dt_final.isoformat()}
            except ValueError:
                return jsonify({"msg": "Data inválida, utilize o formato YYYY-MM-DD."}), 400
        
        # Busca de pedidos
        pedidos = list(pedido_collection.find(filtro))
        if not pedidos:
            return jsonify([]), 200

        pedidos_ids = [pedido['cd_pedido'] for pedido in pedidos]
        itens = list(item_pedido_collection.find({"cd_pedido": {"$in": pedidos_ids}}))
        
        produtos_ids = list(set(item['cd_produto'] for item in itens))
        produtos = produto_collection.find({"cd_produto": {"$in": produtos_ids}})
        produtos_map = {produto['cd_produto']: produto['nm_produto'] for produto in produtos}

        # Montagem dos itens
        for item in itens:
            item['_id'] = str(item['_id'])
            item['nm_produto'] = produtos_map.get(item['cd_produto'], "Produto não encontrado")

        # Montagem dos pedidos
        pedidos_map = {pedido['cd_pedido']: pedido for pedido in pedidos}
        for item in itens:
            pedidos_map[item['cd_pedido']].setdefault('itens', []).append(item)
        
        for pedido in pedidos:
            pedido['_id'] = str(pedido['_id'])

        return jsonify(pedidos), 200

    except Exception as e:
        return jsonify({"error": str(e)}), 500