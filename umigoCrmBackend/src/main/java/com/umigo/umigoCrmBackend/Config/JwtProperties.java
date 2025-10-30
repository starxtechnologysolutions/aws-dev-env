package com.umigo.umigoCrmBackend.Config;

import java.time.Duration;
import lombok.Getter;
import lombok.Setter;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.context.annotation.Configuration;

@Getter
@Setter
@Configuration
@ConfigurationProperties(prefix = "umigo.jwt")
public class JwtProperties {
    private String accessSecret;
    private String refreshSecret;
    private Duration accessTtl;
    private Duration refreshTtl;
}
