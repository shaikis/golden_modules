# ---------------------------------------------------------------------------
# SageMaker Training Job Definitions
# ---------------------------------------------------------------------------
# Training jobs in SageMaker are typically triggered imperatively (via SDK,
# Step Functions, or Pipeline steps) rather than declared as persistent
# Terraform resources. The aws_sagemaker_training_job resource does NOT exist
# in the AWS provider.
#
# This file documents the recommended patterns:
#
#   1. Pipeline-based training  — declare a SageMaker Pipeline (see pipelines.tf)
#      whose pipeline_definition JSON contains TrainingStep nodes.
#
#   2. Step Functions orchestration — use the tf-aws-data-e-stepfunctions module
#      with a state machine that calls sagemaker:CreateTrainingJob.
#
#   3. Automated retraining     — combine an EventBridge schedule rule with a
#      Step Functions state machine or SageMaker Pipeline execution.
#
# The examples/complete directory shows a pipeline_definition that embeds a
# full TrainingStep referencing hyperparameters, input channels, and output
# paths so that Terraform manages the pipeline definition while the job
# lifecycle is driven by SageMaker.
# ---------------------------------------------------------------------------
