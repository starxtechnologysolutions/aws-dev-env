package com.umigo.umigoCrmBackend.Entity;

import jakarta.persistence.*;
import lombok.Data;

import java.io.Serializable;
import java.time.OffsetDateTime;
import java.util.HashSet;
import java.util.Set;

import com.umigo.umigoCrmBackend.Common.Enums.CategoryEnum;
import lombok.ToString;

@Data
@Entity
@Table(name = "dict")
@ToString
public class DictEntity implements Serializable {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Integer id;

    /**
     * Dictionary unique code
     */
    private String code;

    /**
     * Dictionary name
     */
    private String name;

    /**
     * @see com.umigo.umigoCrmBackend.Common.Enums.CategoryEnum
     * Dictionary category
     */
    private String category;

    private OffsetDateTime createdAt = OffsetDateTime.now();

    private OffsetDateTime updatedAt = OffsetDateTime.now();

    @OneToMany(mappedBy = "dict", fetch = FetchType.LAZY, cascade = CascadeType.ALL)
    private Set<DictDetailEntity> dictDetails = new HashSet<>();
}
