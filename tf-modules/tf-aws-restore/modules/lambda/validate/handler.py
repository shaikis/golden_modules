def lambda_handler(event, context):
    return {"valid": True, **event}