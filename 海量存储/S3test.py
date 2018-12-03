import boto
import boto.s3.connection

access_key = 'TCRBE7E5LXILLD01FH3O'
secret_key = '9TwNNYTS2sux1IOOlmeuCMerptBzdAEEMMTIqV2H'
conn = boto.connect_s3(
        aws_access_key_id = access_key,
        aws_secret_access_key = secret_key,
        host = '172.16.0.138', port = '80',
        is_secure=False, calling_format = boto.s3.connection.OrdinaryCallingFormat(),
        )

bucket = conn.create_bucket('my-new-bucket')
for bucket in conn.get_all_buckets():
            print "{name}".format(
                    name = bucket.name,
                    created = bucket.creation_date,
 )