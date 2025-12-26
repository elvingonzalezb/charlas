import json

def lambda_handler(event, context):
    for record in event['Records']:
        body = json.loads(record['body'])
        message = json.loads(body['Message'])
        
        print(f"[INFO] PROCESADOR WHATSAPP - Procesando mensaje final de WhatsApp: {json.dumps(message)}")
        
        # Lógica de negocio final para WhatsApp
        print(f"[INFO] PROCESADOR WHATSAPP - Mensaje procesado exitosamente")
        
    return {
        'statusCode': 200,
        'body': json.dumps('Procesamiento final WhatsApp completado')
    }
