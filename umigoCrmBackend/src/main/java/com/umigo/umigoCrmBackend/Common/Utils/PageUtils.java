package com.umigo.umigoCrmBackend.Common.Utils;

import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Sort;

public class PageUtils {

    private static final Integer PAGE_SIZE_DEF = 10;
    private static final String ORDER_BY_COLUMN_DEF = "id";
    private static final Sort.Direction SORT_DIRECTION = Sort.Direction.DESC;
 
    /**
     * 创建分页排序对象
     */
    public static PageRequest pageRequest(){
        return pageRequest(PAGE_SIZE_DEF, ORDER_BY_COLUMN_DEF, SORT_DIRECTION);
    }

    /**
     * 创建分页排序对象
     * @param sortDirection 排序方式默认值
     */
    public static PageRequest pageRequest(Sort.Direction sortDirection){
        return pageRequest(PAGE_SIZE_DEF, ORDER_BY_COLUMN_DEF, sortDirection);
    }

    /**
     * 创建分页排序对象
     * @param orderByColumnDef 排序字段名称默认值
     * @param sortDirection 排序方式默认值
     */
    public static PageRequest pageRequest(String orderByColumnDef, Sort.Direction sortDirection){
        return pageRequest(PAGE_SIZE_DEF, orderByColumnDef, sortDirection);
    }

    /**
     * 创建分页排序对象
     * @param pageSizeDef 分页数据数量默认值
     * @param orderByColumnDef 排序字段名称默认值
     * @param sortDirection 排序方式默认值
     */
    public static PageRequest pageRequest(Integer pageSizeDef, String orderByColumnDef, Sort.Direction sortDirection){
        Integer pageIndex = HttpServletUtils.getParameterInt("page", 1) - 1;
        Integer pageSize = HttpServletUtils.getParameterInt("size", pageSizeDef);
        String orderByColumn = HttpServletUtils.getParameter("orderByColumn", orderByColumnDef);
        String direction = HttpServletUtils.getParameter("isAsc", sortDirection.toString());
        Sort sort = Sort.by(Sort.Direction.fromString(direction), orderByColumn);
        return PageRequest.of(pageIndex, pageSize, sort);
    }
}
