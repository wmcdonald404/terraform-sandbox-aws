# terraform-sandbox
Simple Terraform playground to create a VPC, associated resources and EC2 instances.

## Usage
1. Clone the repository
    ```
    wmcdonald@fedora:~$ git clone git@github.com:wmcdonald404/terraform-sandbox.git ~/repos/personal/terraform-sandbox/
    ```

2. Initialise the Terraform configuration
    ```
    wmcdonald@fedora:~$ cd ~/repos/personal/terraform-sandbox/
    wmcdonald@fedora:~/repos/personal/terraform-sandbox$ tf init

    Initializing the backend...

    Initializing provider plugins...
    - Finding hashicorp/aws versions matching ">= 5.51.1"...
    - Installing hashicorp/aws v5.51.1...
    <snip>

    Terraform has been successfully initialized!
    ```

3. Validate the Terraform configuration
    ```
    wmcdonald@fedora:~/repos/personal/terraform-sandbox$ tf validate
    Success! The configuration is valid.
    ```

4. Review the Terraform plan

    ```
    wmcdonald@fedora:~/repos/personal/terraform-sandbox$ terraform plan | grep -E -A1 'create|Plan'
    + create

    --
    # aws_internet_gateway.gw will be created
    + resource "aws_internet_gateway" "gw" {
    --
    # aws_route_table.second_rt will be created
    + resource "aws_route_table" "second_rt" {
    --
    # aws_subnet.private_subnets[0] will be created
    + resource "aws_subnet" "private_subnets" {
    --
    # aws_subnet.private_subnets[1] will be created
    + resource "aws_subnet" "private_subnets" {
    --
    # aws_subnet.private_subnets[2] will be created
    + resource "aws_subnet" "private_subnets" {
    --
    # aws_subnet.public_subnets[0] will be created
    + resource "aws_subnet" "public_subnets" {
    --
    # aws_subnet.public_subnets[1] will be created
    + resource "aws_subnet" "public_subnets" {
    --
    # aws_subnet.public_subnets[2] will be created
    + resource "aws_subnet" "public_subnets" {
    --
    # aws_vpc.main will be created
    + resource "aws_vpc" "main" {
    --
    Plan: 9 to add, 0 to change, 0 to destroy.

    ```

5. Apply the Terraform configuration

    List the existing VPCs before the Terraform apply:
    ```
    wmcdonald@fedora:~/repos/personal/terraform-sandbox$ aws ec2 describe-vpcs --region eu-west-1 | jq '.Vpcs[] | {VpcId, Name: (if .Tags then (.Tags[] | select(.Key == "Name") | .Value) else "" end)}'
    {
        "VpcId": "vpc-0965acd85e2644836",
        "Name": "ansible-sandbox"
    }

    ```

    Apply the Terraform:
    ```
    wmcdonald@fedora:~/repos/personal/terraform-sandbox$ tf apply -auto-approve
    Plan: 9 to add, 0 to change, 0 to destroy.
    aws_vpc.main: Creating...
    aws_vpc.main: Creation complete after 1s [id=vpc-0c766b517e58585c5]
    aws_internet_gateway.gw: Creating...
    aws_subnet.private_subnets[0]: Creating...
    aws_subnet.public_subnets[2]: Creating...
    aws_subnet.private_subnets[2]: Creating...
    aws_subnet.public_subnets[0]: Creating...
    aws_subnet.public_subnets[1]: Creating...
    aws_subnet.private_subnets[1]: Creating...
    aws_internet_gateway.gw: Creation complete after 0s [id=igw-0762cec232861d7db]
    aws_route_table.second_rt: Creating...
    aws_subnet.public_subnets[0]: Creation complete after 0s [id=subnet-020c0e911b7c235c4]
    aws_subnet.public_subnets[1]: Creation complete after 1s [id=subnet-0fa7cc25951eb7781]
    aws_subnet.private_subnets[0]: Creation complete after 1s [id=subnet-0a974db649530becd]
    aws_subnet.public_subnets[2]: Creation complete after 1s [id=subnet-0d895243f8df20009]
    aws_subnet.private_subnets[2]: Creation complete after 1s [id=subnet-015fe165047f758cc]
    aws_subnet.private_subnets[1]: Creation complete after 1s [id=subnet-04cec12cf5c83183f]
    aws_route_table.second_rt: Creation complete after 1s [id=rtb-0eb3259edfb34d13a]

    Apply complete! Resources: 9 added, 0 changed, 0 destroyed.
    ```

    Compare the list of VPCs after Terraform apply:
    ```
    wmcdonald@fedora:~/repos/personal/terraform-sandbox$ aws ec2 describe-vpcs --region eu-west-1 | jq '.Vpcs[] | {VpcId, Name: (if .Tags then (.Tags[] | select(.Key == "Name") | .Value) else "" end)}'
    {
        "VpcId": "vpc-0965acd85e2644836",
        "Name": "ansible-sandbox"
    }
    {
        "VpcId": "vpc-0c766b517e58585c5",
        "Name": "terraform-sandbox"
    }
    ```

## References
- [How to Build AWS VPC using Terraform – Step by Step](https://spacelift.io/blog/terraform-aws-vpc)
- [.Multiple EC2 Instances using Terraform](https://gist.github.com/saissemet/7dead669cba388240cf67745cd535d40)