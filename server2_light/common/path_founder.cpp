#include <math.h>
#include <queue>
#include "path_founder.h"


namespace mogo
{

    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    //障碍数据管理器
    CBlockMapMgr::CBlockMapMgr()
    {

    }

    CBlockMapMgr::~CBlockMapMgr()
    {
        ClearMap(m_bms);
    }

    //读取障碍文件
    void CBlockMapMgr::ReadBlockMap(uint16_t unMapId, const char* pszBmFn)
    {
        FILE* f = fopen(pszBmFn, "rb");
        if(f == NULL)
        {
            LogError("read_bm_err", "failed_to_open=%s", pszBmFn);
            return;
        }

        SMapBlockData* bm = new SMapBlockData;

        bm->max_y = fgetc(f);
        bm->max_x = fgetc(f);

        bm->bm_size = (bm->max_x * bm->max_y)/8 + 1;
        bm->bm = new unsigned char[bm->bm_size];
        memset(bm->bm, 0, bm->bm_size);

        for(int i=0; i<bm->max_x; ++i)
        {
            for(int j=0; j<bm->max_y; ++j)
            {
                int bm_mask = fgetc(f);
                if((bm_mask & 0x1) == 0x1)
                {
                    int nIdx = j*bm->max_x + i;
                    enum { LSHIFT_SIZE = 3, CHAR_MASK = 0x7,};
                    int nCharIdx = nIdx >> LSHIFT_SIZE;

                    unsigned char c = bm->bm[nCharIdx];
                    unsigned char c2 = c | ( 1 << (nIdx & CHAR_MASK) );
                    bm->bm[nCharIdx] = c2;
                }
            }
        }
        fclose(f);

        m_bms.insert(make_pair(unMapId, bm));
        LogInfo("read_bm", "bm_loaded,map=%d;file=%s", unMapId, pszBmFn);
    }

    //根据map_id获取障碍数据
    SMapBlockData* CBlockMapMgr::GetBlockMap(uint16_t unMapId)
    {
        map<uint16_t, SMapBlockData*>::iterator iter = m_bms.find(unMapId);
        if(iter != m_bms.end())
        {
            return iter->second;
        }

        return NULL;
    }

    //判断是否障碍
    bool CBlockMapMgr::IsBlock(SMapBlockData* bm, int nIdx)
    {
        enum { LSHIFT_SIZE = 3, CHAR_MASK = 0x7, };
        int nCharIdx = nIdx >> LSHIFT_SIZE;
        if(nCharIdx > bm->bm_size)
        {
            return false;
        }

        unsigned char c = bm->bm[nCharIdx];
        unsigned int nRet = c & (1 << (nIdx & CHAR_MASK ) );

        return nRet > 0;
    }

    bool CBlockMapMgr::IsBlock(SMapBlockData* bm, int tx, int ty)
    {
        int idx = tx + ty * bm->max_x;
        return IsBlock(bm, idx);
    }

    /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    inline void _FormatPos(float x, int& x2)
    {
        if(x < 0.0f)
        {
            x2 = 0;
        }
        else
        {
            x2 = (uint16_t)x;
        }
    }

    float _move(int16_t x1, int16_t y1, int16_t x2, int16_t y2, float speed, int& x3, int& y3)
    {
        int32_t dx = (int32_t)x2 - (int32_t)x1;
        int32_t dy = (int32_t)y2 - (int32_t)y1;

        int32_t d = dx*dx + dy*dy;
        float speed_square = speed * speed;
        //printf("_move,%d,%d\n", (int)speed_square, d);
        if(speed_square > d)
        {
            //速度大于间隔距离,还需要走下一个路点
            x3 = x2;
            y3 = y2;
            return speed-sqrt((float)d);
        }

        float sloop = sqrt((float)d);
        _FormatPos(x1 + (dx/sloop)*speed, x3);
        _FormatPos(y1 + (dy/sloop)*speed, y3);

        return 0.0f;
    }

#define _CHECK_POS_X(x, max_x) \
{\
    if(x >= max_x)\
    {\
        return false;\
    }\
}

    //尝试走格子
    float CSimplePathFounder::TryTileMove(int x1, int y1, int x2, int y2, float speed, SMapBlockData* bm,
                                          int& x3, int& y3, float& speed3)
    {
        int tx1 = x1 / TILE_X_SIZE;
        int ty1 = y1 / TILE_Y_SIZE;
        int tx2 = x2 / TILE_X_SIZE;
        int ty2 = y2 / TILE_Y_SIZE;

        _CHECK_POS_X(tx1, bm->max_x);
        _CHECK_POS_X(ty1, bm->max_y);
        _CHECK_POS_X(tx2, bm->max_x);
        _CHECK_POS_X(ty2, bm->max_y);

        int dx = tx2 - tx1;
        int dy = ty2 - ty1;
        if(dx > 0)
        {
            if(dy > 0)
            {
                //尝试x1+1,y1+1
                if(!CBlockMapMgr::IsBlock(bm, tx1+1, ty1+1))
                {
                    //可以移动
                    speed3 = _move(x1, y1, x1+TILE_X_SIZE, y1+TILE_Y_SIZE, speed, x3, y3);
                    return true;
                }
            }
            else if(dy < 0)
            {
                //尝试x1+1,y1-1
                if(!CBlockMapMgr::IsBlock(bm, tx1+1, ty1-1))
                {
                    //可以移动
                    speed3 = _move(x1, y1, x1+TILE_X_SIZE, y1-TILE_Y_SIZE, speed, x3, y3);
                    return true;
                }
            }
            else
            {
                //尝试x1+1,y1
                if(!CBlockMapMgr::IsBlock(bm, tx1+1, ty1))
                {
                    //可以移动
                    speed3 = _move(x1, y1, x1+TILE_X_SIZE, y1, speed, x3, y3);
                    return true;
                }
            }
        }
        else if(dx<0)
        {
            if(dy > 0)
            {
                //尝试x1-1,y1+1
                if(!CBlockMapMgr::IsBlock(bm, tx1-1, ty1+1))
                {
                    //可以移动
                    speed3 = _move(x1, y1, x1-TILE_X_SIZE, y1+TILE_Y_SIZE, speed, x3, y3);
                    return true;
                }
            }
            else if(dy < 0)
            {
                //尝试x1-1,y1-1
                if(!CBlockMapMgr::IsBlock(bm, tx1-1, ty1-1))
                {
                    //可以移动
                    speed3 = _move(x1, y1, x1-TILE_X_SIZE, y1-TILE_Y_SIZE, speed, x3, y3);
                    return true;
                }
            }
            else
            {
                //尝试x1-1,y1
                if(!CBlockMapMgr::IsBlock(bm, tx1-1, ty1))
                {
                    //可以移动
                    speed3 = _move(x1, y1, x1-TILE_X_SIZE, y1, speed, x3, y3);
                    return true;
                }
            }
        }

        if(dy > 0)
        {
            //尝试x1,y1+1
            if(!CBlockMapMgr::IsBlock(bm, tx1, ty1+1))
            {
                //可以移动
                speed3 = _move(x1, y1, x1, y1+TILE_Y_SIZE, speed, x3, y3);
                return true;
            }
        }
        else if(dy<0)
        {
            //try x1,y1-1
            if(!CBlockMapMgr::IsBlock(bm, tx1, ty1-1))
            {
                //可以移动
                speed3 = _move(x1, y1, x1, y1-TILE_Y_SIZE, speed, x3, y3);
                return true;
            }
        }

        return false;
    }

    //出发点:(x1,y1),目标点:(x2,y2),实际到达点:(x3,y3)
    bool CSimplePathFounder::FindWay(int x1, int y1, int x2, int y2, float speed,
                                     CBlockMapMgr& bmm, uint16_t unMapId, int& x3, int& y3)
    {
        SMapBlockData* bm = bmm.GetBlockMap(unMapId);
        if(bm == NULL)
        {
            //找不到障碍信息,走直线
            //todo
            printf("not_found_bm\n");
            return false;
        }

        for(;;)
        {
            float speed3 = 0.0f;
            //printf("begin, %d,%d --> %d,%d, speed=%.4f, %d,%d\n", x1, y1, x2, y2, speed,bm->max_x,bm->max_y);

            if(TryTileMove(x1, y1, x2, y2, speed, bm, x3, y3, speed3))
            {
                if(speed3 < 0.001)
                {
                    return true;
                }
                else
                {
                    x1 = x3;
                    y1 = y3;
                    speed = speed3;

                    //printf("way, %d,%d speed=%.4f\n", x3, y3, speed3);
                }
            }
            else
            {
                //最后一步走不了,但之前的的一步是可以走的
                x3 = x1;
                y3 = y1;
                return true;
            }
        }

        return false;
    }

    ///////////////////////////////////////////////////////////////////////////////////////////////////////////

    class AStarNodePool
    {
        public:
            AStarNode* getNode()
            {
                if(m_pool.empty())
                {
                    printf("new,,,,\n");
                    return new AStarNode;
                }
                else
                {
                    AStarNode* n = m_pool.front();
                    m_pool.pop_front();
                    return n;
                }
            }

            void pushNode(AStarNode* p)
            {
                m_pool.push_back(p);
            }

        private:
            list<AStarNode*> m_pool;

    };
    AStarNodePool g_pool;

    inline uint16_t _make_idx(int16_t x, int16_t y, int16_t x_size)
    {
        return x + y*x_size;
    }

    AStarNode* CAStarPathFounder::GetOpenNode(int x, int y, int x2, int y2, SMapBlockData* bm, AStarNode* pre)
    {
        if( ( 0 <= x && x < bm->max_x )  && ( 0 <= y && y < bm->max_y ) )
        {
            if(!CBlockMapMgr::IsBlock(bm, x, y))
            {
                int d = ((x2-x)*(x2-x)+(y2-y)*(y2-y))<<4;
                //AStarNode* n2 = new AStarNode(x, y, pre->g+1, d, pre, NULL);
                AStarNode* n2 = new(g_pool.getNode()) AStarNode(x, y, pre->g+1, d, pre, NULL);
                return n2;
            }
        }

        return NULL;
    }

    bool IsNotInCloseList(set<uint16_t>& closed, int idx)
    {
        return closed.find(idx) == closed.end();
    }



    //astar
    bool CAStarPathFounder::FindWayAstar(int x1, int y1, int x2, int y2, SMapBlockData* bm)
    {
        CBlockMapMgr bmm;
        bmm.ReadBlockMap(37101, "F:\\CW\\xx_lua\\lua\\data\\blockmap\\37101.bm");
        bm = bmm.GetBlockMap(37101);

        if(bm == NULL)
        {
            //找不到障碍信息,走直线
            //todo
            printf("not_found_bm\n");
            return false;
        }


        for(int i = 0; i<1000; ++i)
        {
            AStarNode* p = new AStarNode;
            g_pool.pushNode(p);
        }


#ifdef _WIN32
        DWORD t1 = GetTickCount();
        LARGE_INTEGER litmp;
        QueryPerformanceCounter(&litmp);
#else
        CGetTimeOfDay td;
#endif


        int tx1 = x1 / TILE_X_SIZE;
        int ty1 = y1 / TILE_Y_SIZE;
        int tx2 = x2 / TILE_X_SIZE;
        int ty2 = y2 / TILE_Y_SIZE;

        _CHECK_POS_X(tx1, bm->max_x);
        _CHECK_POS_X(ty1, bm->max_y);
        _CHECK_POS_X(tx2, bm->max_x);
        _CHECK_POS_X(ty2, bm->max_y);

        //#define _XXXX

#ifdef _XXXX
        using std::priority_queue;
        priority_queue<AStarNode*, vector<AStarNode*>, AStarNodeOp> open_list;
        AStarNode* n1 = new AStarNode(tx1, ty1, 1, 1, NULL, NULL);
        open_list.push(n1);
#else
        list<AStarNode*> open_list;
        AStarNode* n1 = new AStarNode(tx1, ty1, 1, 1, NULL, NULL);
        open_list.push_back(n1);
#endif
        set<uint16_t> close_list;
        set<uint16_t> open_list2;





        int i = 0;
        while(!open_list.empty())
        {
#ifdef _XXXX
            AStarNode* nn = open_list.top();
            open_list.pop();
#else
            int min_f = 0x7fffffff;
            AStarNode* nn = NULL;
            list<AStarNode*>::iterator iter = open_list.begin();
            list<AStarNode*>::iterator iter2;
            for(; iter != open_list.end(); ++iter)
            {
                AStarNode* nn2 = *iter;
                if(nn2->f < min_f)
                {
                    min_f = nn2->f;
                    nn = nn2;
                    iter2 = iter;
                }
            }
            open_list.erase(iter2);
#endif
            close_list.insert(_make_idx(nn->x, nn->y, bm->max_x));
            //printf("g:%d\n", nn->f);
            //Sleep(100);
            //printf("open_list size=%d\n", open_list.size());

            {
                int idx = _make_idx(nn->x+1, nn->y, bm->max_x);
                if(IsNotInCloseList(close_list, idx) && IsNotInCloseList(open_list2, idx))
                {
                    AStarNode* n2 = GetOpenNode(nn->x+1, nn->y, x2, y2, bm, nn);
                    if(nn->x+1 == tx2 && nn->y == ty2)
                    {
                        printf("found1\n");
                        break;
                    }
                    if(n2)
                    {
                        open_list2.insert(idx);
#ifdef _XXXX
                        open_list.push(n2);
#else
                        open_list.push_back(n2);
#endif
                    }
                }
            }
            {
                int idx = _make_idx(nn->x-1, nn->y, bm->max_x);
                if(IsNotInCloseList(close_list, idx) && IsNotInCloseList(open_list2, idx))
                {
                    AStarNode* n2 = GetOpenNode(nn->x-1, nn->y, x2, y2,bm, nn);
                    if(nn->x-1 == tx2 && nn->y == ty2)
                    {
                        printf("found2\n");
                        break;
                    }
                    if(n2)
                    {
                        open_list2.insert(idx);
#ifdef _XXXX
                        open_list.push(n2);
#else
                        open_list.push_back(n2);
#endif
                    }
                }
            }
            {
                int idx = _make_idx(nn->x, nn->y+1, bm->max_x);
                if(IsNotInCloseList(close_list, idx) && IsNotInCloseList(open_list2, idx))
                {
                    AStarNode* n2 = GetOpenNode(nn->x, nn->y+1, x2, y2,bm, nn);
                    if(nn->x == tx2 && nn->y+1 == ty2)
                    {
                        printf("found3\n");
                        //AStarNode* nnn = nn;
                        //for(; nnn != NULL; nnn = nnn->pre)
                        //{
                        //  printf("%d-%d\n", nnn->x, nnn->y);
                        //}
                        break;
                    }
                    if(n2)
                    {
                        open_list2.insert(idx);
#ifdef _XXXX
                        open_list.push(n2);
#else
                        open_list.push_back(n2);
#endif
                    }
                }
            }
            {
                int idx = _make_idx(nn->x, nn->y-1, bm->max_x);
                if(IsNotInCloseList(close_list, idx) && IsNotInCloseList(open_list2, idx))
                {
                    AStarNode* n2 = GetOpenNode(nn->x, nn->y-1, x2, y2,bm, nn);
                    if(nn->x == tx2 && nn->y-1 == ty2)
                    {
                        printf("found4\n");
                        break;
                    }
                    if(n2)
                    {
                        open_list2.insert(idx);
#ifdef _XXXX
                        open_list.push(n2);
#else
                        open_list.push_back(n2);
#endif
                    }
                }
            }


            //printf("close %d %d,%d\n", ++i, nn->x, nn->y);

            ++i;

            //Sleep(100);

        }

#ifdef _WIN32
        DWORD t2 = GetTickCount();
        printf("time used:%d,count=%d\n", t2-t1, i);


        LARGE_INTEGER m_liPerfFreq= {0};
        //获取每秒多少CPU Performance Tick
        QueryPerformanceFrequency(&m_liPerfFreq);

        LARGE_INTEGER litmp2;
        QueryPerformanceCounter(&litmp2);
        printf("time used2:%.9f\n", ((litmp2.QuadPart-litmp.QuadPart)*1000/(double)m_liPerfFreq.QuadPart));
#else
        printf("time used:%d;count=%d\n", td.GetLapsedTime(), i);
#endif


        return true;
    }


    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////




};


