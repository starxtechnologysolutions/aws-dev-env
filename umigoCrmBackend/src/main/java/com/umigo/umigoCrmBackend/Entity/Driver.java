package com.umigo.umigoCrmBackend.Entity;

import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.type.SqlTypes;

import com.fasterxml.jackson.databind.JsonNode;
import com.umigo.umigoCrmBackend.Common.Enums.*;

import java.time.LocalDate;
import java.time.OffsetDateTime;

@Entity
@Table(name = "driver")
@Getter 
@Setter
@NoArgsConstructor 
@AllArgsConstructor
@Builder
public class Driver {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Integer id;

    // users.id (Firebase UID)
    @Column(name = "user_id", length = 128)
    private String userId;

    // Store JSONB as String (or switch to a JSON type with hibernate-types if desired)
    @JdbcTypeCode(SqlTypes.JSON)
    @Column(name = "license_img", columnDefinition = "jsonb")
    private JsonNode licenseImg;

    @JdbcTypeCode(SqlTypes.JSON)
    @Column(name = "verification_img", columnDefinition = "jsonb")
    private JsonNode verificationImg;

    @Column(name = "first_name")
    private String firstName;

    @Column(name = "last_name")
    private String lastName;

    // 0/1 per schema; keep as Short, or switch to an enum with an AttributeConverter if you prefer
    @Column(name = "gender")
    private Short gender;

    @Column(name = "license_number", unique = true)
    private String licenseNumber;

    @Column(name = "license_card_number")
    private String licenseCardNumber;

    @Column(name = "license_expiry_date")
    private LocalDate licenseExpiryDate;

    @Column(name = "dob")
    private LocalDate dob;

    @Column(name = "phone")
    private String phone;

    @Column(name = "email")
    private String email;

    @Column(name = "address")
    private String address;

    @Enumerated(EnumType.STRING)
    @Column(name = "status")
    private DriverStatus status;  // 'Verified','Unverified','Incomplete','Blacklisted','Rejected'

    @CreationTimestamp
    @Column(name = "created_at")
    private OffsetDateTime createdAt;
}