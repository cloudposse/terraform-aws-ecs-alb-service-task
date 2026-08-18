package test

import (
	"regexp"
	"strings"
	"testing"

	"github.com/gruntwork-io/terratest/modules/random"
	"github.com/gruntwork-io/terratest/modules/terraform"
	testStructure "github.com/gruntwork-io/terratest/modules/test-structure"
	"github.com/stretchr/testify/assert"
)

// Test the native ECS blue/green example in examples/blue-green using Terratest.
func TestExamplesBlueGreen(t *testing.T) {
	t.Parallel()
	randID := strings.ToLower(random.UniqueId())
	attributes := []string{randID}

	rootFolder := "../../"
	terraformFolderRelativeToRoot := "examples/blue-green"
	varFiles := []string{"fixtures.us-east-2.tfvars"}

	tempTestFolder := testStructure.CopyTerraformFolderToTemp(t, rootFolder, terraformFolderRelativeToRoot)

	terraformOptions := &terraform.Options{
		TerraformDir: tempTestFolder,
		Upgrade:      true,
		VarFiles:     varFiles,
		Vars: map[string]interface{}{
			"attributes": attributes,
		},
	}

	// At the end of the test, run `terraform destroy` to clean up any resources that were created
	defer cleanup(t, terraformOptions, tempTestFolder)

	// This will run `terraform init` and `terraform apply` and fail the test if there are any errors
	terraform.InitAndApply(t, terraformOptions)

	basename := "eg-test-ecs-bg-" + randID

	// The blue/green ECS service applies cleanly (strategy = BLUE_GREEN with advanced_configuration).
	serviceName := terraform.Output(t, terraformOptions, "service_name")
	assert.Equal(t, basename, serviceName)

	// The ALB fronting the deployment exists.
	albArn := terraform.Output(t, terraformOptions, "alb_arn")
	assert.Contains(t, albArn, ":loadbalancer/app/")

	albDNSName := terraform.Output(t, terraformOptions, "alb_dns_name")
	assert.NotEmpty(t, albDNSName)

	// Both the production ("blue") and alternate ("green") target groups exist.
	productionTargetGroupArn := terraform.Output(t, terraformOptions, "blue_green_production_target_group_arn")
	assert.Contains(t, productionTargetGroupArn, ":targetgroup/")

	alternateTargetGroupArn := terraform.Output(t, terraformOptions, "blue_green_alternate_target_group_arn")
	assert.Contains(t, alternateTargetGroupArn, ":targetgroup/bgalt")

	// Port plumbing: both target groups listen on the configured container port.
	productionTargetGroupPort := terraform.Output(t, terraformOptions, "blue_green_production_target_group_port")
	assert.Equal(t, "80", productionTargetGroupPort)

	alternateTargetGroupPort := terraform.Output(t, terraformOptions, "blue_green_alternate_target_group_port")
	assert.Equal(t, "80", alternateTargetGroupPort)

	// `production_listener_rule`/`test_listener_rule` must be listener RULE ARNs, not listener ARNs.
	productionListenerRuleArn := terraform.Output(t, terraformOptions, "blue_green_production_listener_rule_arn")
	assert.Contains(t, productionListenerRuleArn, ":listener-rule/app/")

	testListenerRuleArn := terraform.Output(t, terraformOptions, "blue_green_test_listener_rule_arn")
	assert.Contains(t, testListenerRuleArn, ":listener-rule/app/")
}

func TestExamplesBlueGreenDisabled(t *testing.T) {
	t.Parallel()
	randID := strings.ToLower(random.UniqueId())
	attributes := []string{randID}

	rootFolder := "../../"
	terraformFolderRelativeToRoot := "examples/blue-green"
	varFiles := []string{"fixtures.us-east-2.tfvars"}

	tempTestFolder := testStructure.CopyTerraformFolderToTemp(t, rootFolder, terraformFolderRelativeToRoot)

	terraformOptions := &terraform.Options{
		TerraformDir: tempTestFolder,
		Upgrade:      true,
		VarFiles:     varFiles,
		Vars: map[string]interface{}{
			"attributes": attributes,
			"enabled":    "false",
		},
	}

	// At the end of the test, run `terraform destroy` to clean up any resources that were created
	defer cleanup(t, terraformOptions, tempTestFolder)

	// This will run `terraform init` and `terraform apply` and fail the test if there are any errors
	results := terraform.InitAndApply(t, terraformOptions)

	// Should complete successfully without creating or changing any resources.
	re := regexp.MustCompile(`Resources: [^.]+\.`)
	match := re.FindString(results)
	assert.Equal(t, "Resources: 0 added, 0 changed, 0 destroyed.", match, "Re-applying the same configuration should not change any resources")
}
