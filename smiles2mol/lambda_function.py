# deploy: 2026-03-16
import json
from rdkit import Chem
from rdkit.Chem import Draw
from io import BytesIO
import base64

def lambda_handler(event, context):
    try:
        body = event.get("body", "{}")

        # Parse body into a dict
        if isinstance(body, str):
            try:
                body_dict = json.loads(body)
            except json.JSONDecodeError:
                body_dict = json.loads(json.loads(body))
        else:
            body_dict = body

        smiles = body_dict.get("smiles")

        if not smiles:
            return {
                "statusCode": 400,
                "headers": {"Content-Type": "application/json"},
                "body": json.dumps({"error": "Missing 'smiles' parameter"})
            }

        # Generate molecule image
        molecule = Chem.MolFromSmiles(smiles)
        if not molecule:
            return {
                "statusCode": 400,
                "headers": {"Content-Type": "application/json"},
                "body": json.dumps({"error": "Invalid SMILES"})
            }

        img = Draw.MolToImage(molecule, size=(500, 500))
        img = img.convert("RGB")

        buffer = BytesIO()
        img.save(buffer, format="JPEG", quality=95)
        buffer.seek(0)

        return {
            "statusCode": 200,
            "headers": {
                "Content-Type": "image/jpeg",
                "Access-Control-Allow-Origin": "*"
            },
            "body": base64.b64encode(buffer.getvalue()).decode("utf-8"),
            "isBase64Encoded": True
        }

    except json.JSONDecodeError:
        return {
            "statusCode": 400,
            "headers": {"Content-Type": "application/json"},
            "body": json.dumps({"error": "Invalid JSON format"})
        }
    except Exception as e:
        return {
            "statusCode": 500,
            "headers": {"Content-Type": "application/json"},
            "body": json.dumps({"error": str(e)})
        }
