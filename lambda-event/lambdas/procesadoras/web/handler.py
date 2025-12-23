import json

def lambda_handler(event, context):
    for record in event['Records']:
        body = json.loads(record['body'])
        message = json.loads(body['Message'])
        
        print(f"[INFO] PROCESADOR WEB - Procesando mensaje final de Web: {json.dumps(message)}")
        
        # Aquí va la lógica de negocio final
        # Ejemplo: guardar en DB, enviar email, etc.
        print(f"[INFO] PROCESADOR WEB - Mensaje procesado exitosamente")
        
    return {
        'statusCode': 200,
        'body': json.dumps('Procesamiento final Web completado')
    }
