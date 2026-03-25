# Tests — tf-aws-athena

Automated tests using the Terraform test framework (requires Terraform >= 1.6).

## Test Types
| Folder | Command | Cost | When to Run |
|--------|---------|------|-------------|
| unit/ | terraform test -filter=tests/unit | Free (plan only) | Every PR |
| integration/ | terraform test -filter=tests/integration | Costs money | Merge to main |

## Prerequisites
export AWS_ACCESS_KEY_ID="..."
export AWS_SECRET_ACCESS_KEY="..."
export AWS_DEFAULT_REGION="us-east-1"

## Running Tests
terraform test -filter=tests/unit
terraform test -filter=tests/integration
terraform test

## Test Structure
- unit/defaults.tftest.hcl: Verifies feature gates default to false, BYO pattern
- unit/validation.tftest.hcl: Verifies variable validation rules reject bad inputs
- integration/basic.tftest.hcl: Creates minimal resources, checks outputs, destroys
