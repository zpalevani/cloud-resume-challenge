import json
import os
import boto3
from botocore.exceptions import ClientError

# Single-item counter design (teacher-style)
COUNTER_ID = "global"


def _table():
    """
    Lazy-init DynamoDB table to avoid import-time AWS config issues in local/test runs.
    """
    table_name = os.environ["TABLE_NAME"]
    ddb = boto3.resource("dynamodb")
    return ddb.Table(table_name)


def _response(status_code: int, body: dict):
    return {
        "statusCode": status_code,
        "headers": {
            "Content-Type": "application/json",
        },
        "body": json.dumps(body),
    }


def _get_count() -> int:
    resp = _table().get_item(Key={"counter_id": COUNTER_ID})
    item = resp.get("Item")
    if not item:
        return 0
    return int(item.get("count", 0))


def _increment_count() -> int:
    resp = _table().update_item(
        Key={"counter_id": COUNTER_ID},
        UpdateExpression="SET #c = if_not_exists(#c, :zero) + :one",
        ExpressionAttributeNames={"#c": "count"},
        ExpressionAttributeValues={":zero": 0, ":one": 1},
        ReturnValues="UPDATED_NEW",
    )
    return int(resp["Attributes"]["count"])


def handler(event, context):
    """
    Supports HTTP API v2 events.
    GET  /counter  -> returns {"count": n}
    POST /counter  -> increments then returns {"count": n}
    """
    try:
        method = (
            event.get("requestContext", {})
            .get("http", {})
            .get("method", "")
            .upper()
        )

        if method == "POST":
            count = _increment_count()
            return _response(200, {"count": count})

        # Default to GET behavior (safe)
        count = _get_count()
        return _response(200, {"count": count})

    except ClientError as e:
        return _response(500, {"error": "DynamoDB error", "detail": str(e)})
    except Exception as e:
        return _response(500, {"error": "Unhandled error", "detail": str(e)})
