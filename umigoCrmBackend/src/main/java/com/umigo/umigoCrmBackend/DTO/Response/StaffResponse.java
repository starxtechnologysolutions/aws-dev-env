package com.umigo.umigoCrmBackend.DTO.Response;

import java.time.LocalDate;
import java.time.OffsetDateTime;

import com.fasterxml.jackson.annotation.JsonFormat;
import com.umigo.umigoCrmBackend.Common.Enums.StaffStatus;
import com.umigo.umigoCrmBackend.Entity.Staff;

import lombok.Builder;
import lombok.Value;

@Value
@Builder
public class StaffResponse {
    Integer       id;
    String        userId;     // users.id (Firebase UID)
    Integer       roleId;     // roles.id (nullable)

    String        firstName;
    String        lastName;

    @JsonFormat(shape = JsonFormat.Shape.STRING, pattern = "yyyy-MM-dd")
    LocalDate     dob;

    String        phone;
    String        email;
    String        address;

    StaffStatus   status;

    @JsonFormat(shape = JsonFormat.Shape.STRING)
    OffsetDateTime createdAt;

    /** Optional mapper from entity */
    public static StaffResponse fromEntity(Staff s) {
        return StaffResponse.builder()
            .id(s.getId())
            .userId(s.getUserId())
            .roleId(s.getRoleId())
            .firstName(s.getFirstName())
            .lastName(s.getLastName())
            .dob(s.getDob())
            .phone(s.getPhone())
            .email(s.getEmail())
            .address(s.getAddress())
            .status(s.getStatus())
            .createdAt(s.getCreatedAt())
            .build();
    }
}