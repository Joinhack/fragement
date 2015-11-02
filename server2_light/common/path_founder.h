#ifndef __PATH_FOUNDER_HEAD__
#define __PATH_FOUNDER_HEAD__

#include "util.h"
#include "type_mogo.h"
#include "logger.h"

namespace mogo
{

    //障碍信息
    struct SMapBlockData
    {
        int max_x;
        int max_y;
        int bm_size;        //bm的size
        unsigned char* bm;  //按位存储的障碍信息
    };

    enum { TILE_X_SIZE = 50, TILE_Y_SIZE = 30, };   //每个格子的像素点大小


    //障碍数据管理器
    class CBlockMapMgr
    {
        public:
            CBlockMapMgr();
            ~CBlockMapMgr();

        public:
            //读取障碍文件
            void ReadBlockMap(uint16_t unMapId, const char* pszBmFn);
            //根据map_id获取障碍数据
            SMapBlockData* GetBlockMap(uint16_t unMapId);

        public:
            //判断是否障碍
            static bool IsBlock(SMapBlockData* bm, int nIdx);
            static bool IsBlock(SMapBlockData* bm, int tx, int ty);

        private:
            map<uint16_t, SMapBlockData*> m_bms;    //按地图分的障碍信息

    };


    /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    //简单的寻路算法,只判断一步是否障碍
    class CSimplePathFounder
    {
        public:
            //出发点:(x1,y1),目标点:(x2,y2),实际到达点:(x3,y3)
            static bool FindWay(int x1, int y1, int x2, int y2, float speed, CBlockMapMgr& bmm, uint16_t unMapId, int& x3, int& y3);

        private:
            //尝试走格子
            static float TryTileMove(int x1, int y1, int x2, int y2, float speed, SMapBlockData* bm, int& x3, int& y3, float& speed3);

    };

    /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    //A星寻路算法
    struct AStarNode
    {
        int16_t x;
        int16_t y;
        uint32_t idx;
        uint16_t f;
        uint16_t g;
        uint16_t h;
        AStarNode* pre;
        AStarNode* next;

        AStarNode()
        {

        }

        AStarNode(int16_t x, int16_t y, uint16_t g, uint16_t h, AStarNode* pre, AStarNode* next)
        {
            this->x = x;
            this->y = y;
            this->g = g;
            this->h = h;
            this->f = g+h;
            this->pre = pre;
            this->next = next;
        }
    };

    class AStarNodeOp
    {
        public:
            bool operator()(AStarNode* n1, AStarNode* n2)
            {
                return n1->f < n2->f;
            }
    };

    class CAStarPathFounder
    {
        public:
            //astar
            static bool FindWayAstar(int x1, int y1, int x2, int y2, SMapBlockData* bm);

        private:
            static AStarNode* GetOpenNode(int x, int y, int x2, int y2, SMapBlockData* bm, AStarNode* pre);

    };


};



#endif

