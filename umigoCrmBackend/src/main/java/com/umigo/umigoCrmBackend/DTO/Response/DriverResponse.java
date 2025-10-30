package com.umigo.umigoCrmBackend.DTO.Response;


import java.time.LocalDate;
import java.time.OffsetDateTime;

import com.fasterxml.jackson.annotation.JsonFormat;
import com.fasterxml.jackson.databind.JsonNode;
import com.umigo.umigoCrmBackend.Common.Enums.DriverStatus;
import com.umigo.umigoCrmBackend.Entity.Driver;

import lombok.Builder;
import lombok.Value;

@Value
@Builder
public class DriverResponse {
    
    Integer      id;
    String       userId;

    // JSONB stored as String in the entity (you can switch to JsonNode later if you prefer)
    JsonNode licenseImg;
    JsonNode verificationImg;

    String       firstName;
    String       lastName;
    Short        gender;

    String       licenseNumber;
    String       licenseCardNumber;

    @JsonFormat(shape = JsonFormat.Shape.STRING, pattern = "yyyy-MM-dd")
    LocalDate    licenseExpiryDate;

    @JsonFormat(shape = JsonFormat.Shape.STRING, pattern = "yyyy-MM-dd")
    LocalDate    dob;

    String       phone;
    String       email;
    String       address;

    DriverStatus status;

    // ISO-8601 in JSON (e.g., "2025-10-28T12:34:56+11:00")
    @JsonFormat(shape = JsonFormat.Shape.STRING)
    OffsetDateTime createdAt;

    // Optional convenience mapper
    public static DriverResponse fromEntity(Driver d) {
        return DriverResponse.builder()
            .id(d.getId())
            .userId(d.getUserId())
            .licenseImg(d.getLicenseImg())
            .verificationImg(d.getVerificationImg())
            .firstName(d.getFirstName())
            .lastName(d.getLastName())
            .gender(d.getGender())
            .licenseNumber(d.getLicenseNumber())
            .licenseCardNumber(d.getLicenseCardNumber())
            .licenseExpiryDate(d.getLicenseExpiryDate())
            .dob(d.getDob())
            .phone(d.getPhone())
            .email(d.getEmail())
            .address(d.getAddress())
            .status(d.getStatus())
            .createdAt(d.getCreatedAt())
            .build();
    }
}