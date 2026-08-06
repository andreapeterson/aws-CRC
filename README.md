# Andrea Peterson — Portfolio and AWS Cloud Resume Challenge

Source for [andrea-peterson.com](https://andrea-peterson.com), a static portfolio and serverless visitor counter deployed on AWS.

## Architecture

- **Frontend:** semantic HTML, CSS, and JavaScript served from a private S3 bucket through CloudFront
- **Visitor counter:** Python 3.12 Lambda Function URL with an atomic DynamoDB update
- **Infrastructure:** Terraform manages the site objects, CloudFront distribution, Route 53 record, Lambda, DynamoDB table, IAM, and CloudWatch logs
- **Delivery:** GitHub Actions tests and validates pull requests, then deploys and invalidates CloudFront after a merge to `main`

## Repository layout

```text
my_website/   Portfolio pages and static assets
terra/        Terraform, Lambda source, and unit tests
.github/      CI/CD workflow
```

## Run locally

From the repository root:

```bash
python3 -m http.server 8000 --directory my_website
```

Then open `http://localhost:8000`. The visitor counter is restricted to the production origin and will show a fallback label locally.

## Validate changes

```bash
python3 -m unittest discover -s terra -p 'test_*.py' -v
terraform -chdir=terra fmt -check
terraform -chdir=terra init -backend=false
terraform -chdir=terra validate
```

An authenticated Terraform plan runs in GitHub Actions before deployment. Production deploys occur only after changes are merged to `main`.

## Background

This project began as the [Cloud Resume Challenge](https://cloudresumechallenge.dev/) and has since evolved into the infrastructure for my portfolio. I wrote about the original build in [From Aspiring to Achieving: My Journey Conquering the AWS Resume Challenge](https://dev.to/andreapeterson/from-aspiring-to-achieving-my-journey-conquering-the-aws-resume-challenge-36ff).
