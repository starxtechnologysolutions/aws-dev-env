Push-Location apps/hello-service-java
mvn -q -DskipTests package
java -cp target/hello-service-0.1.0.jar App
Pop-Location
