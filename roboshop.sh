#!/bin/bash

SG_ID="sg-092f9baf10de817bb"
AMI_ID="ami-0220d79f3f480ecf5"
HOSTED_ZONE_ID="Z03921621E9OHYF28C7PJ"
DOMAIN_NAME="crazycoolmaster.space"

for instance in $@
do
    instance_id=$( aws ec2 run-instances \
    --image-id $AMI_ID \
    --instance-type t3.micro \
    --security-group-ids $SG_ID \
    --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$instance}]" \
    --query 'Instances[0].InstanceId' \
    --output text )

    if [ $instance == "frontend" ]; then
        IP=$(
            aws ec2 describe-instances \
            --instance-ids $instance_id \
            --query 'Reservations[].Instances[].PublicIpAddress' \
            --output text
        )
        RECORD_NAME="$DOMAIN_NAME"
    else
        IP=$(
            aws ec2 describe-instances \
            --instance-ids $instance_id \
            --query 'Reservations[].Instances[].PrivateIpAddress' \
            --output text
        )
        RECORD_NAME="$instance.$DOMAIN_NAME"
    fi

    echo "IP Address: $IP"

    aws route53 change-resource-record-sets \
    --hosted-zone-id $HOSTED_ZONE_ID 
    --change-batch '
    {
    "Comment": "Update A record for www.example.com",
        "Changes": [
            {
                "Action": "UPSERT",
                "ResourceRecordSet": {
                    "Name": "'$RECORD_NAME'",
                    "Type": "A",
                    "TTL": 1,
                    "ResourceRecords": [
                        {
                            "Value": "'$IP'"
                        }
                    ]
                }
            }
        ]
    }
    '

    echo "Record created for $insance"
 done   