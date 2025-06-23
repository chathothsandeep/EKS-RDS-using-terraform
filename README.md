Overview

This document describes a fully automated infrastructure setup on AWS using Terraform, GitLab CI/CD, and Kubernetes, designed to host a Strapi-based application. After provisioning the infrastructure, you can authenticate to AWS using the AWS CLI and retrieve the EKS cluster's kubeconfig by running aws eks update-kubeconfig --region ap-south-1 --name <cluster_name>, which enables kubectl access to the EKS cluster.

 The infrastructure includes:

        Amazon EKS for container orchestration


        Amazon RDS (PostgreSQL) as the backend database


        Amazon ECR for storing Docker images


        GitLab as the source code and CI/CD platform


        AWS Classic Load Balancer (CLB) to expose the application


        Amazon S3 for remote Terraform state


        Bastion Host for secure database access


        AWS Region: ap-south-1 (Mumbai)



Components
1. EKS Cluster
        Provisioned using Terraform


        Deployed in AWS Region ap-south-1 using 2 Availability Zones for high availability


        Configured with 2 active worker nodes, scaling up to 3 nodes maximum


        Node group spans both Availability Zones


        Hosts the Strapi application as a Kubernetes deployment with 3 pods


        GitLab Kubernetes Agent installed for CI/CD integration


2. GitLab CI/CD
        GitLab repository stores both the Strapi code and Kubernetes YAML manifests


        On each commit:


        Docker image is built


        Image is pushed to Amazon ECR


        Kubernetes manifests are applied to EKS


        GitLab Agent ensures seamless GitOps-style deployment


        CI/CD variables hold secrets and environment configuration


3. Amazon ECR
        Used as the container registry for application images


        EKS cluster uses an imagePullSecret to authenticate and pull from ECR


4. AWS Classic Load Balancer (CLB)
        Application is exposed via a Kubernetes Service of type LoadBalancer


        aws-load-balancer-controller (with CLB support) is installed in EKS


        Associated with an IAM service account with the appropriate policies


        Automatically provisions and configures CLB for external access


5. Amazon RDS (PostgreSQL)
        Managed PostgreSQL database instance


        Hosted in a private subnet to prevent direct internet access


        Access restricted to a Bastion Host for security


6. Bastion Host
        EC2 instance deployed in a public subnet


        Used exclusively to SSH into the private network and access RDS


        Acts as a secure entry point for database administration


7. S3 Backend
        
        Remote state is stored in Amazon S3


        Enables team collaboration and state locking


8. IAM Policy for AWS Load Balancer Controller

        This IAM policy grants permissions necessary for the AWS Load Balancer Controller (used in EKS/Kubernetes clusters) to:

        Create & configure ELBs (Classic, Application, and Network)


        Modify Security Groups


        Work with ACM, IAM certificates, WAF, and AWS Shield


        Register targets (EC2 instances or IPs)


        Attach tags to identify and track cluster-owned resources


        These permissions are implemented via a custom IAM policy attached to a dedicated role for the Load Balancer Controller. This role is then associated with a Kubernetes service    account using IAM Roles for Service Accounts (IRSA), enabling secure and granular access from within the EKS cluster.

9. Other files
        I've updated the document to clarify that variables.tf and output.tf are part of the repo, while terraform.tfvars—containing sensitive values like db_instance_password, bastion_ami_id, and bastion_ssh_key_name—is intentionally not committed.

10. Workflow 

        Developer pushes code to GitLab repo.


        GitLab CI/CD pipeline triggers:


        Builds Docker image


        Pushes image to ECR


        Applies Kubernetes manifests to EKS


        EKS pulls the image using ECR credentials and deploys pods


        aws-load-balancer-controller provisions a CLB to expose the application


        Application connects to RDS (PostgreSQL) via internal networking


        Bastion Host allows secure access to the database


        Terraform state is stored in S3 to support collaborative infrastructure management



11. Security and Best Practices

        IAM Roles and Policies for least privilege


        GitLab variables for managing secrets securely


        Private subnets for database resources


        S3 backend with state locking and versioning


        Bastion host access restricted via security groups



This setup ensures a fully automated, secure, and scalable deployment environment for the Strapi application using modern DevOps practices and AWS-native tools.

