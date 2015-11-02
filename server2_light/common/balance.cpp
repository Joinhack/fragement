/*----------------------------------------------------------------
// Copyright (C) 2013 广州，爱游
//
// 模块名：balance
// 创建者：Steven Yang
// 修改者列表：
// 创建日期：2013.1.5
// 模块描述：baseapp 和 cellapp 的静态平衡
//----------------------------------------------------------------*/

#include <stdlib.h>
#include "balance.h"


namespace mogo
{

    CBalance::CBalance()
    {

    }


    CBalance::~CBalance()
    {
        ClearContainer(m_weights);
    }


    //新增一个id
    void CBalance::AddNewId(uint16_t id)
    {
        m_weights.push_back(new _SWeight(id));
    }

    //增加权重数据
    void CBalance::AddWeight(uint16_t id, uint32_t weight)
    {
        list<_SWeight*>::iterator iter = m_weights.begin();
        for(; iter != m_weights.end(); ++iter)
        {
            _SWeight* p = *iter;
            if(p->id == id)
            {
                p->weight += weight;
                return;
            }
        }

        //如果找不到就新加一个
        this->AddNewId(id);
    }

    //批量更新权重数据,例如:其他服务器汇报自己的负载情况给cwmd
    //todo

    //获取权重最小的id
    uint16_t CBalance::GetLestWeightId()
    {
        uint16_t min_id = 0;
        uint32_t min_weight = 0xffffffff;
        list<_SWeight*>::iterator iter = m_weights.begin();
        for(; iter != m_weights.end(); ++iter)
        {
            _SWeight* p = *iter;
            if(p->weight < min_weight)
            {
                min_id = p->id;
                min_weight = p->weight;
            }
        }

        return min_id;
    }

    //随机获取一个id
    uint16_t CBalance::GetRandomId()
    {
        int nSize = (int)m_weights.size();
        int nPos = rand() % nSize;

        int i = 0;
        list<_SWeight*>::iterator iter = m_weights.begin();
        for(; iter != m_weights.end(); ++iter)
        {
            if(i == nPos)
            {
                return (*iter)->id;
            }
            ++i;
        }

        return 0;
    }

}

