package com.umigo.umigoCrmBackend.Controller;

import com.umigo.umigoCrmBackend.Common.Exception.ServiceException;
import com.umigo.umigoCrmBackend.Common.Result.*;

import com.umigo.umigoCrmBackend.DTO.Request.DictRequest;
import com.umigo.umigoCrmBackend.Service.DictService;
import jakarta.annotation.Resource;
import jakarta.validation.Valid;
import org.springframework.web.bind.annotation.*;

import java.util.Arrays;

@RequestMapping("/api/v1/dict/dict")
@RestController
public class DictController {

    @Resource
    private DictService dictService;

    @PostMapping("/save")
    public Result save(@RequestBody @Valid DictRequest dictRequest) throws ServiceException {
        return Result.success(dictService.save(dictRequest));
    }

    @GetMapping("/getPageList")
    public Result getPageList() {
        return Result.success(dictService.getPageList(null));
    }

    @DeleteMapping("/delete/{id}")
    public Result deleteById(@PathVariable("id") Integer id) {
        dictService.deleteByIds(Arrays.asList(id));
        return Result.success();
    }

}

