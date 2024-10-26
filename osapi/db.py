# db.py
from pymongo import MongoClient

client = MongoClient('mongodb+srv://janderssampaio:at08YxfXaqrJWlST@cluster0.4c4wh.mongodb.net/?retryWrites=true&w=majority&appName=Cluster0')
db = client['sistema_restaurante']

# Definindo as coleções
mesas_collection = db['mesas']
produtos_collection = db['produto']
categorias_collection = db['categoria_produto']
