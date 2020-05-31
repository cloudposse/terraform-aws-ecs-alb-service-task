package test

import (
	"encoding/json"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
	"testing"
)

// Test the Terraform module in examples/complete using Terratest.
func TestExamplesComplete(t *testing.T) {
	t.Parallel()

	terraformOptions := &terraform.Options{
		// The path to where our Terraform code is located
		TerraformDir: "../../examples/complete",
		Upgrade:      true,
		// Variables to pass to our Terraform code using -var-file options
		VarFiles: []string{"fixtures.us-east-2.tfvars"},
	}

	// At the end of the test, run `terraform destroy` to clean up any resources that were created
	defer terraform.Destroy(t, terraformOptions)

	// This will run `terraform init` and `terraform apply` and fail the test if there are any errors
	terraform.InitAndApply(t, terraformOptions)

	// Run `terraform output` to get the value of an output variable
	jsonMap := terraform.OutputRequired(t, terraformOptions, "container_definition_json_map")
	// Verify we're getting back the outputs we expect
	var jsonObject map[string]interface{}
	err := json.Unmarshal([]byte(jsonMap), &jsonObject)
	assert.NoError(t, err)
	assert.Equal(t, "geodesic", jsonObject["name"])
	assert.Equal(t, "cloudposse/geodesic", jsonObject["image"])
	assert.Equal(t, 256, int((jsonObject["memory"]).(float64)))
	assert.Equal(t, 128, int((jsonObject["memoryReservation"]).(float64)))
	assert.Equal(t, 256, int((jsonObject["cpu"]).(float64)))
	assert.Equal(t, true, jsonObject["essential"])
	assert.Equal(t, false, jsonObject["readonlyRootFilesystem"])

	// Run `terraform output` to get the value of an output variable
	vpcCidr := terraform.Output(t, terraformOptions, "vpc_cidr")
	// Verify we're getting back the outputs we expect
	assert.Equal(t, "172.16.0.0/16", vpcCidr)

	// Run `terraform output` to get the value of an output variable
	privateSubnetCidrs := terraform.OutputList(t, terraformOptions, "private_subnet_cidrs")
	// Verify we're getting back the outputs we expect
	assert.Equal(t, []string{"172.16.0.0/19", "172.16.32.0/19"}, privateSubnetCidrs)

	// Run `terraform output` to get the value of an output variable
	publicSubnetCidrs := terraform.OutputList(t, terraformOptions, "public_subnet_cidrs")
	// Verify we're getting back the outputs we expect
	assert.Equal(t, []string{"172.16.96.0/19", "172.16.128.0/19"}, publicSubnetCidrs)

	// Run `terraform output` to get the value of an output variable
	ecsClusterId := terraform.Output(t, terraformOptions, "ecs_cluster_id")
	// Verify we're getting back the outputs we expect
	assert.Equal(t, "arn:aws:ecs:us-east-2:126450723953:cluster/eg-test-ecs-alb-service-task", ecsClusterId)

	// Run `terraform output` to get the value of an output variable
	ecsClusterArn := terraform.Output(t, terraformOptions, "ecs_cluster_arn")
	// Verify we're getting back the outputs we expect
	assert.Equal(t, "arn:aws:ecs:us-east-2:126450723953:cluster/eg-test-ecs-alb-service-task", ecsClusterArn)

	// Run `terraform output` to get the value of an output variable
	ecsExecRolePolicyName := terraform.Output(t, terraformOptions, "ecs_exec_role_policy_name")
	// Verify we're getting back the outputs we expect
	assert.Equal(t, "eg-test-ecs-alb-service-task-exec", ecsExecRolePolicyName)

	// Run `terraform output` to get the value of an output variable
	serviceName := terraform.Output(t, terraformOptions, "service_name")
	// Verify we're getting back the outputs we expect
	assert.Equal(t, "eg-test-ecs-alb-service-task", serviceName)

	// Run `terraform output` to get the value of an output variable
	taskDefinitionFamily := terraform.Output(t, terraformOptions, "task_definition_family")
	// Verify we're getting back the outputs we expect
	assert.Equal(t, "eg-test-ecs-alb-service-task", taskDefinitionFamily)

	// Run `terraform output` to get the value of an output variable
	taskExecRoleName := terraform.Output(t, terraformOptions, "task_exec_role_name")
	// Verify we're getting back the outputs we expect
	assert.Equal(t, "eg-test-ecs-alb-service-task-exec", taskExecRoleName)

	// Run `terraform output` to get the value of an output variable
	taskExecRoleArn := terraform.Output(t, terraformOptions, "task_exec_role_arn")
	// Verify we're getting back the outputs we expect
	assert.Equal(t, "arn:aws:iam::126450723953:role/eg-test-ecs-alb-service-task-exec", taskExecRoleArn)

	// Run `terraform output` to get the value of an output variable
	taskRoleName := terraform.Output(t, terraformOptions, "task_role_name")
	// Verify we're getting back the outputs we expect
	assert.Equal(t, "eg-test-ecs-alb-service-task-task", taskRoleName)

	// Run `terraform output` to get the value of an output variable
	taskRoleArn := terraform.Output(t, terraformOptions, "task_role_arn")
	// Verify we're getting back the outputs we expect
	assert.Equal(t, "arn:aws:iam::126450723953:role/eg-test-ecs-alb-service-task-task", taskRoleArn)
}
