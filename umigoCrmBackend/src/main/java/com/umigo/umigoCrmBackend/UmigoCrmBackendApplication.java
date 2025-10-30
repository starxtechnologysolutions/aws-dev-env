package com.umigo.umigoCrmBackend;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.boot.context.properties.ConfigurationPropertiesScan;

@SpringBootApplication
@ConfigurationPropertiesScan
public class UmigoCrmBackendApplication {

	public static void main(String[] args) {
		SpringApplication.run(UmigoCrmBackendApplication.class, args);
	}

}
