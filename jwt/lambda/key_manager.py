# key_manager.py

import os
import json
import boto3
import base64

kms_client = boto3.client('kms')
s3_client = boto3.client('s3')

JWKS_BUCKET_NAME = os.environ['JWKS_BUCKET_NAME']
KMS_KEY_ID = os.environ.get('KMS_KEY_ID')

def base64url_encode(data):
    """Codifica datos en base64url sin padding."""
    return base64.urlsafe_b64encode(data).rstrip(b'=').decode('ascii')

def get_jwk_from_kms_key(key_id):
    """Obtiene la clave pública de KMS y crea un JWK simplificado."""
    
    # Obtener la clave pública de KMS
    response = kms_client.get_public_key(KeyId=key_id)
    
    # Para demo: crear JWK con valores de ejemplo
    # En producción usarías una librería para parsear la clave real
    jwk_data = {
        "kty": "RSA",
        "use": "sig",
        "kid": key_id.split('/')[-1],
        "alg": "RS256",
        "n": "demo-modulus-base64url",  # En producción: parsear de response['PublicKey']
        "e": "AQAB"  # Exponente estándar RSA
    }
    
    return jwk_data

def handler(event, context):
    print("--- INICIANDO GESTIÓN DE JWKS ---")
    
    try:
        # Usar la clave KMS creada por Terraform
        if not KMS_KEY_ID:
            raise ValueError("KMS_KEY_ID no está configurado")
            
        print(f"Usando clave KMS: {KMS_KEY_ID}")
        
        # Obtener la clave pública en formato JWK
        jwk = get_jwk_from_kms_key(KMS_KEY_ID)
        
        # Crear el JWKS
        jwks_set = {"keys": [jwk]}
        jwks_json = json.dumps(jwks_set, indent=2)
        
        print(f"JWKS generado: {jwks_json}")
        
        # Publicar en S3
        s3_client.put_object(
            Bucket=JWKS_BUCKET_NAME,
            Key=".well-known/jwks.json",
            Body=jwks_json,
            ContentType='application/json',
            CacheControl='max-age=3600'
        )
        
        print(f"JWKS publicado en s3://{JWKS_BUCKET_NAME}/.well-known/jwks.json")
        
        return {
            'statusCode': 200,
            'body': json.dumps({
                'message': 'JWKS generado y publicado exitosamente',
                'kid': jwk['kid']
            })
        }
        
    except Exception as e:
        print(f"Error: {str(e)}")
        return {
            'statusCode': 500,
            'body': json.dumps({'error': str(e)})
        }