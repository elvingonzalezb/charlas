import json
import boto3
import os
from datetime import datetime

sns = boto3.client('sns')

def lambda_handler(event, context):
    print(f"[INFO] RECEPTOR WHATSAPP - Evento recibido de WhatsApp: {json.dumps(event)}")
    
    detail = event.get('detail', {})
    
    mensaje_limpio = {
        'source': 'whatsapp',
        'timestamp': datetime.utcnow().isoformat(),
        'data': detail,
        'processed_by': 'lambda-whatsapp-receptor'
    }
    
    sns.publish(
        TopicArn=os.environ['SNS_TOPIC_ARN'],
        Message=json.dumps(mensaje_limpio),
        MessageAttributes={
            'source': {'DataType': 'String', 'StringValue': 'whatsapp'}
        }
    )
    
    print(f"[INFO] RECEPTOR WHATSAPP - Mensaje publicado a SNS exitosamente")
    
    return {
        'statusCode': 200,
        'body': json.dumps('Mensaje procesado desde WhatsApp')
    }
