package com.umigo.umigoCrmBackend.Service.Impl;

import cn.hutool.core.bean.BeanUtil;
import com.umigo.umigoCrmBackend.Common.Enums.DictResultCodeEnum;
import com.umigo.umigoCrmBackend.Common.Exception.ServiceException;
import com.umigo.umigoCrmBackend.Common.Utils.JacksonUtils;
import com.umigo.umigoCrmBackend.Common.Utils.PageUtils;
import com.umigo.umigoCrmBackend.DTO.Request.DictDetailRequest;
import com.umigo.umigoCrmBackend.DTO.Response.DictDetailResponse;
import com.umigo.umigoCrmBackend.Entity.DictDetailEntity;
import com.umigo.umigoCrmBackend.Repository.DictDetailRepository;
import com.umigo.umigoCrmBackend.Repository.DictRepository;
import com.umigo.umigoCrmBackend.Service.DictDetailService;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Example;
import org.springframework.data.domain.ExampleMatcher;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.util.CollectionUtils;

import javax.annotation.Resource;
import java.util.List;

@Slf4j
@Service
public class DictDetailServiceImpl implements DictDetailService {

    @Resource
    private DictRepository dictRepository;
    @Resource
    private DictDetailRepository dictDetailRepository;

    @Override
    @Transactional(rollbackFor = ServiceException.class)
    public DictDetailResponse save(DictDetailRequest dictDetailRequest) throws ServiceException {
        log.info("save dictDetail request: {}", JacksonUtils.obj2json(dictDetailRequest));
        DictDetailEntity dictDetailEntity = BeanUtil.copyProperties(dictDetailRequest, DictDetailEntity.class);
        dictDetailEntity.setDict(dictRepository.findById(dictDetailRequest.getDictId()).orElse(null));
        List<DictDetailEntity> list = dictDetailRepository.findAllByDetailCode(dictDetailEntity.getDetailCode());
        if (!CollectionUtils.isEmpty(list) && dictDetailEntity.getId() == null) {
            throw new ServiceException(DictResultCodeEnum.DICT_DETAIL_CODE_IS_EXISTS);
        }
        dictDetailRepository.save(dictDetailEntity);
        DictDetailResponse dictDetailResponse = BeanUtil.copyProperties(dictDetailEntity, DictDetailResponse.class);
        log.info("save dictDetail request: {}, response{}", JacksonUtils.obj2json(dictDetailRequest), JacksonUtils.obj2json(dictDetailResponse));
        return dictDetailResponse;
    }

    @Override
    public void deleteByIds(List<Integer> ids) {
        log.info("dictDetail deleteByIds request: {}", ids);
        dictDetailRepository.deleteAllById(ids);
    }

    @Override
    public List<DictDetailEntity> findByDictId(Integer dictId) {
        log.info("dictDetail findByDictId request: {}", dictId);
        return dictDetailRepository.findByDictId(dictId);
    }

    @Override
    public Page<DictDetailEntity> getPageList() {
        PageRequest page = PageUtils.pageRequest();
        Page<DictDetailEntity> pageList = dictDetailRepository.findAll(page);
        return pageList;
    }
}
