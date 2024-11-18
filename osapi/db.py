from pymongo import MongoClient

client = MongoClient('mongodb+srv://janderssampaio:at08YxfXaqrJWlST@cluster0.4c4wh.mongodb.net/?retryWrites=true&w=majority&appName=Cluster0')

def get_database(uid):
    """Retorna a base de dados específica para o usuário (admin) com base no UID"""
    return client[uid]

def get_collection(uid, collection_name):
    """Retorna a coleção específica dentro da base de dados do usuário"""
    db = get_database(uid)
    return db[collection_name]