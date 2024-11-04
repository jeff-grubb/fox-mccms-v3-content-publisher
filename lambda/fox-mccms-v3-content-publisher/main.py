import json
import os
import time

# boto3 imports
import boto3
from boto3.dynamodb.types import TypeDeserializer

# lambda powertools imports
from aws_lambda_powertools import Logger
from aws_lambda_powertools.utilities.data_classes import event_source, DynamoDBStreamEvent
from aws_lambda_powertools.utilities.data_classes.dynamo_db_stream_event import (
    DynamoDBRecord,
    DynamoDBRecordEventName
)
from aws_lambda_powertools.utilities.typing import LambdaContext

# initialize powertools logger
logger = Logger()

# get environment variables
S3_BUCKET = os.environ.get("S3_BUCKET", None)
ENVIRONMENT = os.environ.get("ENVIRONMENT", "none")
BUSINESS_UNIT = os.environ.get("BUSINESS_UNIT", "none")

# S3 writer class for writing dynamo objects to S3
class S3Writer(object):
    _s3 = None
    _s3_bucket = None

    def __init__(self, s3_bucket):
        self._s3_bucket = s3_bucket

        if(self._s3_bucket is not None):
            self._s3 = boto3.resource("s3").Bucket(self._s3_bucket)

    def write(self, key, value):
        if(self._s3 is None):
            raise "S3 bucket object not defined"

        logger.info("writing s3://" + self._s3_bucket + "/" + key)

        # If this fails, an exception will be raised. Then what? This isn't in a queue,
        # so this would just fail without a retry. Would need to handle this more gracefully.
        return self._s3.put_object(Key=key, Body=value.encode('utf-8'))

# Lambda entrypoint
@logger.inject_lambda_context
@event_source(data_class=DynamoDBStreamEvent)
def lambda_handler(records: DynamoDBStreamEvent, context: LambdaContext):
    logger.info("Content publisher enhancement lambda start")
    objects = []

    for record in records:
        obj = executeRequest(DynamoDBRecord(record))
        objects.append(obj)

    #logger.debug(objects)
    logger.info("Content publisher enhancement lambda end")
    return objects

def executeRequest(record: DynamoDBRecord):
    deserializer = TypeDeserializer()
    spark_id = deserializer.deserialize(record.dynamodb['Keys']['spark_id'])
    seconds = time.time()
    s3_filename = "{0}-{1}.json".format(spark_id, seconds)
    logger.debug("s3 filename {0}".format(s3_filename))

    s3writer = S3Writer(S3_BUCKET)

    dynamodbevent = record.raw_event['dynamodb']

    if dynamodbevent['NewImage'] is not None and str(record.raw_event['eventName']) is not "DELETE":
        print ("shouldn't happen, let's take a look at this")

    # Get the record. If there's a new image, it's the current record. If no new image, this was a delete?
    image = dynamodbevent['NewImage'] if dynamodbevent['NewImage'] is not None else dynamodbevent['OldImage']

    s3obj = s3writer.write(s3_filename, json.dumps(image))

    if dynamodbevent['NewImage'] is not None: del dynamodbevent['NewImage']
    if dynamodbevent['OldImage'] is not None: del dynamodbevent['OldImage']

    dynamodbevent['spark_id'] = spark_id
    dynamodbevent['environment'] = ENVIRONMENT
    dynamodbevent['business_unit'] = BUSINESS_UNIT
    dynamodbevent['s3_url'] = "s3://" + S3_BUCKET + "/" + s3_filename

    return dynamodbevent

    # old way - create new message. Saving for visibility
    #obj = {}
    #obj['spark_id'] = spark_id
    #obj['event_name'] = str(record.raw_event['eventName'])
    #obj['environment'] = ENVIRONMENT
    #obj['business_unit'] = BUSINESS_UNIT
    #obj['event_source'] = str(record.raw_event['eventSource'])
    #obj['s3_url'] = "s3://" + S3_BUCKET + "/" + s3_filename

    #logger.debug("dynamodb record executed {0}".format(str(obj)))

    #return obj
