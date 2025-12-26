import json
import boto3
import os
from datetime import datetime

sns = boto3.client('sns')

def lambda_handler(event, context):
    print(f"[INFO] RECEPTOR WEB - Evento recibido de Web: {json.dumps(event)}")
    
    # Validar y limpiar datos
    detail = event.get('detail', {})
    
    mensaje_limpio = {
        'source': 'web',
        'timestamp': datetime.utcnow().isoformat(),
        'data': detail,
        'processed_by': 'lambda-web-receptor'
    }
    
    # Publicar a SNS
    sns.publish(
        TopicArn=os.environ['SNS_TOPIC_ARN'],
        Message=json.dumps(mensaje_limpio),
        MessageAttributes={
            'source': {'DataType': 'String', 'StringValue': 'web'}
        }
    )
    
    print(f"[INFO] RECEPTOR WEB - Mensaje publicado a SNS exitosamente")
    
    return {
        'statusCode': 200,
        'body': json.dumps('Mensaje procesado desde Web')
    }
