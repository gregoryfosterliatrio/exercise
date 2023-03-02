name                = "terminal"
environment         = "example"
availability_zones  = ["us-east-2a", "us-east-2b"]
private_subnets     = ["10.0.0.0/20", "10.0.32.0/20"]
public_subnets      = ["10.0.16.0/20", "10.0.48.0/20"]
# tsl_certificate_arn = "mycertificatearn"
container_memory    = 512
