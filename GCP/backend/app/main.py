import os
from flask import Flask, jsonify, request, make_response
from google.cloud import firestore

app = Flask(__name__)

PROJECT_ID = os.environ.get("GCP_PROJECT")  # set in Cloud Run env
COUNTER_DOC = os.environ.get("COUNTER_DOC", "site/visitorCounter")
ALLOWED_ORIGIN = os.environ.get("ALLOWED_ORIGIN", "https://cloudwithzarapalevani.site")

db = firestore.Client(project=PROJECT_ID)

def cors(resp):
    resp.headers["Access-Control-Allow-Origin"] = ALLOWED_ORIGIN
    resp.headers["Vary"] = "Origin"
    resp.headers["Access-Control-Allow-Methods"] = "GET,OPTIONS"
    resp.headers["Access-Control-Allow-Headers"] = "Content-Type"
    return resp

@app.route("/count", methods=["GET", "OPTIONS"])
def count():
    if request.method == "OPTIONS":
        return cors(make_response("", 204))

    doc_ref = db.document(COUNTER_DOC)

    @firestore.transactional
    def increment(transaction):
        snap = doc_ref.get(transaction=transaction)
        if snap.exists:
            current = int(snap.get("count") or 0)
        else:
            current = 0
        new_val = current + 1
        transaction.set(doc_ref, {"count": new_val}, merge=True)
        return new_val

    transaction = db.transaction()
    new_count = increment(transaction)

    resp = jsonify({"count": new_count})
    return cors(resp)

@app.get("/health")
def health():
    return jsonify({"ok": True})
