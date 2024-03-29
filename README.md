# Exercise

Interview Exercise for liatrio

## Problem statement

A potential client, XYZ, is a traditional on prem infrastructure shop that is interested in moving to the cloud. Developers have been complaining about kickstarting new environments, long lead times and cycles for development, and lack of consistency between their environments. Management has also been complaining about downtime during deployments and code quality being released into production. Liatrio has been tasked with showing XYZ how to potentially do this. They want to migrate to the cloud and they’ve recently been interested in containerization. You can either build a simple application or leverage any open source “hello-world” application using the programming language of your choice. This exercise is not about your app dev skills but rather how you would build and deploy an application in a modern, scalable and resilient way.

## Prerequisites

- terraform installed
- aws cli installed
- cloud-nuke installed

# Terraform template for AWS ECS/Fargate

This terraform setup can be used to setup the AWS infrastructure for a dockerized application running on ECS with Fargate launch configuration.

## Resources

This setup creates the following resources:

- VPC
- One public and one private subnet per AZ
- Routing tables for the subnets
- Internet Gateway for public subnets
- NAT gateways with attached Elastic IPs for the private subnet
- Two security groups
  - one that allows HTTP/HTTPS access
  - one that allows access to the specified container port
- An ALB + target group with listeners for port 80 and 443
- An ECR for the docker images
- An ECS cluster with a service (incl. auto scaling policies for CPU and memory usage)
  and task definition to run docker containers from the ECR (incl. IAM execution role)
- Secrets - a Terraform module that creates many secrets based on a `map` input value, and has a list of secret ARNs as an output value

![example](https://d2908q01vomqb2.cloudfront.net/1b6453892473a467d07372d45eb05abc2031647a/2018/01/26/Slide5.png "Infrastructure illustration")
(Source: https://aws.amazon.com/de/blogs/compute/task-networking-in-aws-fargate/)

### Get Started building your own infrastructure

- create your own `secrets.tfvars` based on `secrets.example.tfvars`, insert the values for your AWS access key and secrets. If you don't create your `secrets.tfvars`, don't worry. Terraform will interactively prompt you for missing variables later on. You can also create your `environment.tfvars` file to manage non-secret values for different environments or projects with the same infrastructure
- execute `terraform init`, it will initialize your local terraform and connect it to the state store, and it will download all the necessary providers
- execute `terraform plan -var-file="secret.tfvars" -var-file="environment.tfvars" -out="out.plan"` - this will calculate the changes terraform has to apply and creates a plan. If there are changes, you will see them. Check if any of the changes are expected, especially deletion of infrastructure.
- if everything looks good, you can execute the changes with `terraform apply out.plan`

### Setting up Terraform Backend

Sometimes we need to setup the Terraform Backend from Scratch, if we need to setup a completely separate set of Infrastructure or start a new project. This involves setting up a backend where Terraform keeps track of the state outside your local machine, and hooking up Terraform with AWS.
Here is a guideline:

- Get access key and secret from IAM for your user
- execute `aws configure` .. enter your key and secret
- find your credentials stored in files within `~/.aws` folder
- Create s3 bucket to hold our terraform state with this command: `aws s3api create-bucket --bucket gregory-liatrio-example-terraform-backend-store --region us-east-2 --create-bucket-configuration LocationConstraint=us-east-2`
- Because the terraform state contains some very secret secrets, setup encryption of bucket: `aws s3api put-bucket-encryption --bucket gregory-liatrio-example-terraform-backend-store --server-side-encryption-configuration "{\"Rules\":[{\"ApplyServerSideEncryptionByDefault\":{\"SSEAlgorithm\":\"AES256\"}}]}"`
- Create IAM user for Terraform `aws iam create-user --user-name terraform-user`
- Add policy to access S3 and DynamoDB access -
  - `aws iam attach-user-policy --policy-arn arn:aws:iam::aws:policy/AmazonS3FullAccess --user-name terraform-user`
  - `aws iam attach-user-policy --policy-arn arn:aws:iam::aws:policy/AmazonDynamoDBFullAccess --user-name terraform-user`
- Create bucket policy, put against bucket `aws s3api put-bucket-policy --bucket gregory-liatrio-example-terraform-backend-store --policy file://policy.json`. Here is the policy file - the actual ARNs need to be adjusted based on the output of the steps above:

   ```sh
    cat <<-EOF >> policy.json
    {
        "Statement": [
            {
                "Effect": "Allow",
                "Principal": {
                    "AWS": "arn:aws:iam::937707138518:user/terraform-user"
                },
                "Action": "s3:*",
                "Resource": "arn:aws:s3:::gregory-liatrio-example-terraform-backend-store"
            }
        ]
    }
    EOF
   ```

- Enable versioning in bucket with `aws s3api put-bucket-versioning --bucket gregory-liatrio-example-terraform-remote-store --versioning-configuration Status=Enabled`
- create the AWS access keys for your deployment user with `aws iam create-access-key --user-name terraform-user`, this will output access key and secret, which can be used as credentials for executing Terraform against AWS - i.e. you can put the values into the `secrets.tfvars` file
- execute initial terraforming
- after initial terraforming, the state lock dynamo DB table is created and can be used for all subsequent executions. Therefore, this line in `main.tf` can be un-commented:

```hcl
    # dynamodb_table = "terraform-state-lock-dynamo" - uncomment this line once the terraform-state-lock-dynamo has been terraformed
```

### Clean up

`cloud-nuke aws --region us-west-2`

## [Presentation](https://gregoryfosterliatrio.github.io/exercise)
