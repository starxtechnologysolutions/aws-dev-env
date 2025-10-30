package com.umigo.umigoCrmBackend.Entity;

import jakarta.persistence.*;
import lombok.*;

@Entity @Table(name = "users")
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class Users {
    @Id
    private String id;              // Firebase UID
    @Column(unique = true) private String email;
    @Column(name="is_driver") private boolean driver;
    @Column(name="is_staff")  private boolean staff;
}