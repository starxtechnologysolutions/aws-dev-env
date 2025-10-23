# Dev Smoke Test
1. Ensure SSM session works.
2. Port-forward DB/Redis/MQ or run on EC2.
3. Set `S3_BUCKET_NAME` to Terraform output bucket name.
4. `mvn -q -DskipTests package && java -cp target/hello-service-0.1.0.jar App`
