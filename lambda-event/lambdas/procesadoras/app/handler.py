import json

def lambda_handler(event, context):
    for record in event['Records']:
        body = json.loads(record['body'])
        message = json.loads(body['Message'])
        
        print(f"[INFO] PROCESADOR APP - Procesando mensaje final de App: {json.dumps(message)}")
        
        # Lógica de negocio final para App
        print(f"[INFO] PROCESADOR APP - Mensaje procesado exitosamente")
        
    return {
        'statusCode': 200,
        'body': json.dumps('Procesamiento final App completado')
    }
