package com.pia.config;

import io.swagger.v3.oas.annotations.enums.SecuritySchemeIn;
import io.swagger.v3.oas.annotations.enums.SecuritySchemeType;
import io.swagger.v3.oas.annotations.security.SecurityScheme;
import io.swagger.v3.oas.models.OpenAPI;
import io.swagger.v3.oas.models.info.Contact;
import io.swagger.v3.oas.models.info.Info;
import io.swagger.v3.oas.models.info.License;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

/**
 * Configures Swagger / OpenAPI docs.
 * The BearerAuth security scheme allows testing JWT-protected endpoints
 * directly in the Swagger UI.
 */
@Configuration
@SecurityScheme(
        name = "BearerAuth",
        type = SecuritySchemeType.HTTP,
        scheme = "bearer",
        bearerFormat = "JWT",
        in = SecuritySchemeIn.HEADER
)
public class OpenApiConfig {

    @Bean
    public OpenAPI piaOpenAPI() {
        return new OpenAPI()
                .info(new Info()
                        .title("PIA — Private Investigator for Apartments")
                        .description("Apartment decision-support platform API. " +
                                "Track listings, detect changes, score apartments, get alerted.")
                        .version("0.1.0")
                        .contact(new Contact().name("PIA Team"))
                        .license(new License().name("MIT")));
    }
}
