from flask import Flask, jsonify
from db import db, User

app = Flask(__name__)


@app.get('/users/<uid>')
def get_user(uid: str):
    user = db.query(User).filter(User.id == uid).first()
    return jsonify({
        'id': user.id,
        'email': user.email,
        'phone': user.phone,
        'password_hash': user.password_hash,
    })
