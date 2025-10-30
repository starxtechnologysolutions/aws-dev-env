package com.umigo.umigoCrmBackend.Repository;

import com.umigo.umigoCrmBackend.Entity.DictDetailEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface DictDetailRepository extends JpaRepository<DictDetailEntity, Integer> {
    @Query(value = "select * from dict_detail where dict_id = :dictId", nativeQuery = true)
    List<DictDetailEntity> findByDictId(Integer dictId);

    List<DictDetailEntity> findAllByDetailCode(String detailCode);
}
