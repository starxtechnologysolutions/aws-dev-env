aws_region = "ap-southeast-2"
project    = "umigo"
env        = "dev"

private_cidrs = ["10.20.10.0/24", "10.20.11.0/24"]

db_username = "appuser"
db_name     = "appdb"
db_password = "CkfN&D1hkyy_vv-l6dF-dtry"

rabbit_user = "app"
rabbit_pass = "#nJKbhTBw6Q53h#HCzFWRrjf"

# CI/CD pipeline configuration
github_owner            = "starxtechnologysolutions"
github_repo             = "aws-dev-env"
github_branch           = "master"
codestar_connection_arn = "arn:aws:codeconnections:ap-southeast-2:699475954652:connection/ace70f39-c9ed-42d1-8acd-1d1c66e1d55b"