import json

# lambda powertools imports
from aws_lambda_powertools import Logger
from aws_lambda_powertools.utilities.data_classes.sqs_event import SQSEvent
from aws_lambda_powertools.utilities.data_classes import event_source
from aws_lambda_powertools.utilities.typing import LambdaContext

logger = Logger()

@logger.inject_lambda_context
@event_source(data_class=SQSEvent)
def lambda_handler(event: SQSEvent, context: LambdaContext):
    for record in event.records:
        json_record = json.loads(str(record.body))
        print(json_record['Message'])
