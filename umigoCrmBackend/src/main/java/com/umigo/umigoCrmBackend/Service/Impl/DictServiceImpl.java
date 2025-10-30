package com.umigo.umigoCrmBackend.Service.Impl;

import cn.hutool.core.bean.BeanUtil;
import com.umigo.umigoCrmBackend.Common.Enums.CategoryEnum;
import com.umigo.umigoCrmBackend.Common.Enums.DictResultCodeEnum;
import com.umigo.umigoCrmBackend.Common.Exception.ServiceException;
import com.umigo.umigoCrmBackend.Common.Utils.JacksonUtils;
import com.umigo.umigoCrmBackend.Common.Utils.PageUtils;
import com.umigo.umigoCrmBackend.DTO.Request.DictRequest;
import com.umigo.umigoCrmBackend.DTO.Response.DictResponse;
import com.umigo.umigoCrmBackend.Entity.DictEntity;
import com.umigo.umigoCrmBackend.Repository.DictRepository;
import com.umigo.umigoCrmBackend.Service.DictService;
import jakarta.annotation.Resource;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.BeanUtils;
import org.springframework.data.domain.Example;
import org.springframework.data.domain.ExampleMatcher;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Optional;

@Slf4j
@Service
public class DictServiceImpl implements DictService {

    @Resource
    private DictRepository dictRepository;

    @Transactional(rollbackFor = ServiceException.class)
    @Override
    public DictResponse save(DictRequest dictRequest) throws ServiceException {
        log.info("save dict request: {}", JacksonUtils.obj2json(dictRequest));
        DictEntity dict = dictRepository.findByCode(dictRequest.getCode());
        if (dict != null && dict.getId() == null) {
            throw new ServiceException(DictResultCodeEnum.DICT_CODE_IS_EXISTS);
        }
        if (CategoryEnum.getByCode(dictRequest.getCategory()) == null) {
            throw new ServiceException(DictResultCodeEnum.DICT_CATEGORY_IS_EXISTS);
        }
        dict = BeanUtil.copyProperties(dictRequest, DictEntity.class);
        DictResponse dictResponse = BeanUtil.copyProperties(dictRepository.save(dict), DictResponse.class);
        return dictResponse;
    }

    @Transactional(rollbackFor = Exception.class)
    @Override
    public void deleteByIds(List<Integer> ids) {
        log.info("dict deleteByIds request: {}", ids);
        dictRepository.deleteAllByIdInBatch(ids);
    }

    @Override
    public DictResponse findById(Integer id) {
        Optional<DictEntity> optionalDict = dictRepository.findById(id);
        return optionalDict.map(dict -> BeanUtil.copyProperties(dict, DictResponse.class)).orElse(null);
    }

    @Override
    public Page<DictEntity> getPageList(DictRequest request) {
        PageRequest page = PageUtils.pageRequest();
        if (request == null) {
            return dictRepository.findAll(page);
        }
        DictEntity probe = new DictEntity();
        BeanUtils.copyProperties(request, probe);
        ExampleMatcher matcher = ExampleMatcher.matchingAll()
                .withIgnoreNullValues()
                .withMatcher("name", ExampleMatcher.GenericPropertyMatchers.contains())
                .withIgnoreCase();
        Example<DictEntity> example = Example.of(probe, matcher);
        return dictRepository.findAll(example, page);
    }
}
