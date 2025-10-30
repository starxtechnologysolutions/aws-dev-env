package com.umigo.umigoCrmBackend.Entity;

import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.CreationTimestamp;

import java.time.LocalDate;
import java.time.OffsetDateTime;

import com.umigo.umigoCrmBackend.Common.Enums.*;

@Entity
@Table(name = "staff")
@Getter @Setter
@NoArgsConstructor @AllArgsConstructor
@Builder
public class Staff {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Integer id;

    // users.id (Firebase UID)
    @Column(name = "user_id", length = 128)
    private String userId;

    // FK to roles.id (nullable, ON DELETE SET NULL)
    @Column(name = "role_id")
    private Integer roleId;

    @Column(name = "first_name")
    private String firstName;

    @Column(name = "last_name")
    private String lastName;

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
    private StaffStatus status; // 'Active','Suspended','Deleted'

    @CreationTimestamp
    @Column(name = "created_at")
    private OffsetDateTime createdAt;

}