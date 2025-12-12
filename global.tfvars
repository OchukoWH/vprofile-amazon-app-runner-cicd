region = "us-east-1"                   
bucket = "ochuko-terraform-state-new34"       
aws_region = "us-east-1"               
project_name = "vprofile"             
environment  = "prod"                   
github_repos = [
  "OchukoWH/vprofile-amazon-app-runner-cicd",
]
ecr_repo_db  = "vprofiledb"            
ecr_repo_app = "vprofileapp"           
ecr_repo_web = "vprofileweb"           
instance_type    = "t2.medium"           
root_volume_size = 30                                         
