#ifndef __BALANCE_HEAD__
#define __BALANCE_HEAD__

#include <queue>
#include "util.h"
#include "type_mogo.h"


namespace mogo
{

    using std::priority_queue;


    struct _SWeight
    {
        _SWeight(uint16_t id):id(id), weight(0)
        {
        }

        uint16_t id;
        uint32_t weight;
    };


    //负载均衡数据管理器
    class CBalance
    {
        public:
            CBalance();
            ~CBalance();

        public:
            //新增一个id,id必须>=0
            void AddNewId(uint16_t id);
            //增加权重数据
            void AddWeight(uint16_t id, uint32_t weight);
            //批量更新权重数据,例如:其他服务器汇报自己的负载情况给cwmd
            //todo
            //获取权重最小的id
            uint16_t GetLestWeightId();
            //随机获取一个id
            uint16_t GetRandomId();

        private:
            list<_SWeight*> m_weights;

    };


}



#endif


