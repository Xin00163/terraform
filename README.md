# Set Up a Selenium Grid with Terraform

## Introduction

This is a terraform project to set up a selenium grid in aws using fargate.

## Setup
Prerequisite: valid AWS installation and configuration.

* To install terraform with the following commands:

    OSX: brew install terraform\
    Windows: choco install terraform

* Clone this repo

* Create a new file `terraform.tfvars` in terrafom directory and make sure it's in the gitignore file

* For this project, we will use AWS as the cloud provider. Please generate a pair of AWS_ACCESS_KEY and AWS_SECRET_KEY and save them to `terraform.tfvars` like below:
    ```
    AWS_ACCESS_KEY = "XXXXXXXXXXX"
    AWS_SECRET_KEY = "XXXXXXXXXXXXXXXXXXX"
    ```
* Log in to your AWS console

* You are all set.

## Steps

### 1. Initialize, Plan and Apply

```bash
terraform init
terraform plan
terraform apply
```

### 2. AWS concole

Click on ECS then you should see the cluster `selenium-cluster`. If you click on the cluster, you can check the running services `selenium-service`. Then, please go to the `Tasks` tab and click on the running task. 

Notice, you should be able to see the Public IP address under Network. Also, under Containers there are selenium hub, firefox and chrome node.

### 3. Selenium Hub & Nodes

Open a new tab in the browser, then go to this link: `http://[Public IP Address]:4444/grid/console`. Please replace `[Public IP Address]` with the public IP address of your selenium task.

Now you should see a firefox node and a chrome node in the browser.

### 4. Run tests with Selenium Grid

Check if you have node installed by running node -v. If not, please install node.

Install or export java version "1.8.0_172".

In the terminal, `cd` into the test directory and run command `npm install` to install the dependencies.

There is a sample selenium webdriver test in `grid-test.js`. Please open this in your IDE and replace `XXXX` with the public IP address being used earlier.

Once it's done, type `node grid-test.js` in the terminal to run the test.

When the test is running, the firefox or chrome node will become grey which indicates that this node is being used.

### 5. Destroy

Don't forget to destroy your demo instances.
Issue the following command `terraform destroy` to clean the AWS provider.
