#!/usr/bin/env bash
# =============================================================================
# Provision an EC2 instance for OpenClaw
# =============================================================================
# Creates a t3.medium Ubuntu 24.04 instance with:
#   - SSH (22) and Gateway (18789) security group
#   - SSM IAM role for remote management
#   - User-data that auto-installs OpenClaw + skills
#
# Prerequisites:
#   - AWS CLI v2 configured with appropriate permissions
#   - Region set (defaults to us-east-1)
#
# Usage:
#   chmod +x scripts/provision-ec2.sh
#   ./scripts/provision-ec2.sh
# =============================================================================

set -euo pipefail

REGION="${AWS_DEFAULT_REGION:-us-east-1}"
INSTANCE_TYPE="t3.medium"
KEY_NAME="openclaw-ec2-key"
SG_NAME="openclaw-sg"
INSTANCE_NAME="openclaw-server"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo ""
echo "========================================="
echo "  OpenClaw EC2 Provisioner"
echo "  Region: $REGION"
echo "  Instance: $INSTANCE_TYPE"
echo "========================================="
echo ""

# ---------------------------------------------------------------------------
# Find latest Ubuntu 24.04 AMI
# ---------------------------------------------------------------------------
echo "Finding latest Ubuntu 24.04 AMI..."
AMI_ID=$(aws ec2 describe-images \
  --owners 099720109477 \
  --filters "Name=name,Values=ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*" \
            "Name=state,Values=available" \
  --query 'Images | sort_by(@, &CreationDate) | [-1].ImageId' \
  --output text \
  --region "$REGION")
echo "  AMI: $AMI_ID"

# ---------------------------------------------------------------------------
# Get default VPC
# ---------------------------------------------------------------------------
VPC_ID=$(aws ec2 describe-vpcs \
  --filters "Name=isDefault,Values=true" \
  --query 'Vpcs[0].VpcId' \
  --output text \
  --region "$REGION")
echo "  VPC: $VPC_ID"

# ---------------------------------------------------------------------------
# Create or find key pair
# ---------------------------------------------------------------------------
if aws ec2 describe-key-pairs --key-names "$KEY_NAME" --region "$REGION" &>/dev/null; then
    echo "  Key pair '$KEY_NAME' already exists."
else
    echo "  Creating key pair '$KEY_NAME'..."
    aws ec2 create-key-pair \
      --key-name "$KEY_NAME" \
      --query 'KeyMaterial' \
      --output text \
      --region "$REGION" \
      > "${SCRIPT_DIR}/../${KEY_NAME}.pem"
    chmod 400 "${SCRIPT_DIR}/../${KEY_NAME}.pem"
    echo "  Key saved to ${SCRIPT_DIR}/../${KEY_NAME}.pem"
fi

# ---------------------------------------------------------------------------
# Create or find security group
# ---------------------------------------------------------------------------
SG_ID=$(aws ec2 describe-security-groups \
  --filters "Name=group-name,Values=$SG_NAME" "Name=vpc-id,Values=$VPC_ID" \
  --query 'SecurityGroups[0].GroupId' \
  --output text \
  --region "$REGION" 2>/dev/null || echo "None")

if [ "$SG_ID" = "None" ] || [ -z "$SG_ID" ]; then
    echo "  Creating security group '$SG_NAME'..."
    SG_ID=$(aws ec2 create-security-group \
      --group-name "$SG_NAME" \
      --description "OpenClaw EC2 - SSH + Gateway" \
      --vpc-id "$VPC_ID" \
      --query 'GroupId' \
      --output text \
      --region "$REGION")

    aws ec2 authorize-security-group-ingress \
      --group-id "$SG_ID" \
      --ip-permissions \
        '[{"IpProtocol":"tcp","FromPort":22,"ToPort":22,"IpRanges":[{"CidrIp":"0.0.0.0/0","Description":"SSH"}]},{"IpProtocol":"tcp","FromPort":18789,"ToPort":18789,"IpRanges":[{"CidrIp":"0.0.0.0/0","Description":"OpenClaw Gateway"}]}]' \
      --region "$REGION" > /dev/null
fi
echo "  Security Group: $SG_ID"

# ---------------------------------------------------------------------------
# Create IAM role + instance profile for SSM (if not exists)
# ---------------------------------------------------------------------------
ROLE_NAME="OpenClawEC2Role"
PROFILE_NAME="OpenClawEC2Profile"

if ! aws iam get-role --role-name "$ROLE_NAME" &>/dev/null; then
    echo "  Creating IAM role '$ROLE_NAME'..."
    aws iam create-role \
      --role-name "$ROLE_NAME" \
      --assume-role-policy-document '{
        "Version":"2012-10-17",
        "Statement":[{"Effect":"Allow","Principal":{"Service":"ec2.amazonaws.com"},"Action":"sts:AssumeRole"}]
      }' > /dev/null
    aws iam attach-role-policy \
      --role-name "$ROLE_NAME" \
      --policy-arn arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore
fi

if ! aws iam get-instance-profile --instance-profile-name "$PROFILE_NAME" &>/dev/null; then
    aws iam create-instance-profile --instance-profile-name "$PROFILE_NAME" > /dev/null
    aws iam add-role-to-instance-profile \
      --instance-profile-name "$PROFILE_NAME" \
      --role-name "$ROLE_NAME"
    echo "  Waiting for instance profile propagation..."
    sleep 10
fi
echo "  IAM Profile: $PROFILE_NAME"

# ---------------------------------------------------------------------------
# Launch instance with user-data
# ---------------------------------------------------------------------------
echo ""
echo "Launching EC2 instance..."
INSTANCE_ID=$(aws ec2 run-instances \
  --image-id "$AMI_ID" \
  --instance-type "$INSTANCE_TYPE" \
  --key-name "$KEY_NAME" \
  --security-group-ids "$SG_ID" \
  --iam-instance-profile "Name=$PROFILE_NAME" \
  --block-device-mappings '[{"DeviceName":"/dev/sda1","Ebs":{"VolumeSize":20,"VolumeType":"gp3"}}]' \
  --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$INSTANCE_NAME}]" \
  --user-data "file://${SCRIPT_DIR}/user-data.sh" \
  --count 1 \
  --query 'Instances[0].InstanceId' \
  --output text \
  --region "$REGION")

echo "  Instance ID: $INSTANCE_ID"
echo "  Waiting for instance to be running..."

aws ec2 wait instance-running --instance-ids "$INSTANCE_ID" --region "$REGION"

PUBLIC_IP=$(aws ec2 describe-instances \
  --instance-ids "$INSTANCE_ID" \
  --query 'Reservations[0].Instances[0].PublicIpAddress' \
  --output text \
  --region "$REGION")

echo ""
echo "========================================="
echo "  EC2 Instance Ready!"
echo "========================================="
echo ""
echo "  Instance ID:  $INSTANCE_ID"
echo "  Public IP:    $PUBLIC_IP"
echo "  SSH:          ssh -i ${KEY_NAME}.pem ubuntu@${PUBLIC_IP}"
echo ""
echo "  OpenClaw is auto-installing via user-data."
echo "  Check bootstrap log:"
echo "    ssh -i ${KEY_NAME}.pem ubuntu@${PUBLIC_IP} 'tail -f /var/log/openclaw-bootstrap.log'"
echo ""
echo "  After bootstrap completes:"
echo "    ssh -i ${KEY_NAME}.pem ubuntu@${PUBLIC_IP}"
echo "    openclaw configure     # set your API keys"
echo "    openclaw onboard --install-daemon"
echo ""
