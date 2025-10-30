package com.umigo.umigoCrmBackend.Service;

import com.umigo.umigoCrmBackend.Common.Exception.ServiceException;
import com.umigo.umigoCrmBackend.DTO.Request.DictRequest;
import com.umigo.umigoCrmBackend.DTO.Response.DictResponse;
import com.umigo.umigoCrmBackend.Entity.DictEntity;
import org.springframework.data.domain.Page;

import java.util.List;

public interface DictService {

    DictResponse save(DictRequest dictRequest) throws ServiceException;

    void deleteByIds(List<Integer> ids);

    DictResponse findById(Integer id);

    Page<DictEntity> getPageList(DictRequest request);

}
