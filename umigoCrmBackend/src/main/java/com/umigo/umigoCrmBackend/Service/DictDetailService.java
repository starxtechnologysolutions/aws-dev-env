package com.umigo.umigoCrmBackend.Service;

import com.umigo.umigoCrmBackend.Common.Exception.ServiceException;
import com.umigo.umigoCrmBackend.DTO.Request.DictDetailRequest;
import com.umigo.umigoCrmBackend.DTO.Response.DictDetailResponse;
import com.umigo.umigoCrmBackend.Entity.DictDetailEntity;
import org.springframework.data.domain.Page;

import java.util.List;

public interface DictDetailService {

    DictDetailResponse save(DictDetailRequest dictDetailRequest) throws ServiceException;

    void deleteByIds(List<Integer> ids);

    List<DictDetailEntity> findByDictId(Integer dictId);

    Page<DictDetailEntity> getPageList();
}
