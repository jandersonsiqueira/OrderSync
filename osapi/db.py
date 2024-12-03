import os
from pymongo import MongoClient
from dotenv import load_dotenv

load_dotenv()

mongo_conn_str = os.getenv('MONGO_CONN')

if not mongo_conn_str:
    raise Exception("MONGO_CONN não está definido no .env")

client = MongoClient(mongo_conn_str)

def get_database(uid):
    """Retorna a base de dados específica para o usuário (admin) com base no UID"""
    return client[uid]

def get_collection(uid, collection_name):
    """Retorna a coleção específica dentro da base de dados do usuário"""
    db = get_database(uid)
    return db[collection_name]