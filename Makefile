.PHONY: plan apply destroy outputs

plan:
	cd infra/terraform && terraform plan -out tfplan
apply:
	cd infra/terraform && terraform apply tfplan
outputs:
	cd infra/terraform && terraform output
destroy:
	cd infra/terraform && terraform destroy -auto-approve
