import json
import os
import azure.functions as func
from azure.data.tables import TableServiceClient, UpdateMode

TABLE_NAME = os.getenv("TABLE_NAME", "VisitorCounter")
CONN_STR = os.getenv("STORAGE_CONNECTION_STRING")

PARTITION_KEY = "counter"
ROW_KEY = "visitors"

def main(req: func.HttpRequest) -> func.HttpResponse:
    # Handle preflight
    if req.method == "OPTIONS":
        return func.HttpResponse(
            "",
            status_code=204,
            headers={
                "Access-Control-Allow-Origin": "*",
                "Access-Control-Allow-Methods": "GET,OPTIONS",
                "Access-Control-Allow-Headers": "Content-Type",
            },
        )

    if not CONN_STR:
        return func.HttpResponse(
            json.dumps({"error": "Missing STORAGE_CONNECTION_STRING app setting"}),
            status_code=500,
            mimetype="application/json",
        )

    service = TableServiceClient.from_connection_string(CONN_STR)
    table = service.get_table_client(TABLE_NAME)

    try:
        entity = table.get_entity(partition_key=PARTITION_KEY, row_key=ROW_KEY)
        current = int(entity.get("count", 0))
    except Exception:
        current = 0
        entity = {"PartitionKey": PARTITION_KEY, "RowKey": ROW_KEY, "count": 0}

    new_count = current + 1
    entity["count"] = new_count

    table.upsert_entity(mode=UpdateMode.MERGE, entity=entity)

    return func.HttpResponse(
        json.dumps({"count": new_count}),
        status_code=200,
        mimetype="application/json",
        headers={
            "Access-Control-Allow-Origin": "*",
            "Access-Control-Allow-Methods": "GET,OPTIONS",
            "Access-Control-Allow-Headers": "Content-Type",
        },
    )
