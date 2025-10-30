package com.umigo.umigoCrmBackend.Repository;

import com.umigo.umigoCrmBackend.Entity.DictEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface DictRepository extends JpaRepository<DictEntity, Integer> {
    DictEntity findByCode(String code);
}
