#!/usr/bin/env python3
import aws_cdk as cdk
from stacks.cloudoptima_stack import CloudOptimaStack

app = cdk.App()

CloudOptimaStack(
    app,
    "CloudOptimaStack",
    env=cdk.Environment(
        account=app.node.try_get_context("account"),
        region=app.node.try_get_context("region") or "us-east-1"
    ),
    description="CloudOptima AI - FinOps Platform Infrastructure"
)

app.synth()
