

#ifndef _IEVENT_H
#define _IEVENT_H

#include <map>
#include <iostream>
#include <string>
#include <vector>
#include <list>
//#include "delegate.h"
#include "lua.h"
#include "lauxlib.h"
#include "lualib.h"
#include <string.h>
#include "logger.h"
#include "type_mogo.h"
#include "lua_mogo.h"
using namespace std;
typedef int EventId;

typedef list<pair<TENTITYID, string> > TEventList;

//实现事件分发器
class CEventDispatcher
{
    public:
        

        CEventDispatcher() {}
        //析构注册的事件
        ~CEventDispatcher()
        {
            //map<TENTITYID, map<EventId, list<pair<TENTITYID, const char *> >*>>::iterator iter = handlers.end();
        }

        //注册新事件
        void AddToMap(TENTITYID triggerEid, EventId eventId, TENTITYID eid, const char * szFuncName)
        {

            map<TENTITYID, map<EventId, TEventList* >* >::iterator iter = handlers.find(triggerEid);
            if( iter != handlers.end() )
            {
                map<EventId, TEventList*> *EventMap = iter->second;
                map<EventId, TEventList*>::iterator iter1 = EventMap->find(eventId);
                if (iter1 != EventMap->end())
                {
                    TEventList* l = iter1->second;
                    TEventList::iterator iter2 = l->begin();
                    for (;iter2 != l->end(); iter2++)
                    {
                        //如果已经注册了，则无须处理
                        if (iter2->first == eid && iter2->second.compare(szFuncName) == 0)
                        {
                            return;
                        }
                    }
                    iter1->second->push_back(make_pair(eid, szFuncName));
                }
                else
                {
                    TEventList* l = new TEventList();
                    l->push_back(make_pair(eid, szFuncName));
                    EventMap->insert(make_pair(eventId, l));
                }
            }
            else
            {
                map<EventId, TEventList*>* m = new map<EventId, TEventList*>();
                TEventList* l = new TEventList();
                l->push_back(make_pair(eid, szFuncName));

                m->insert(make_pair(eventId, l));

                handlers.insert(make_pair(triggerEid, m));
            }
        }

        //删除事件
        void DeleteFromMap(TENTITYID triggerEid, EventId eventId, TENTITYID eid)
        {
            map<TENTITYID, map<EventId, TEventList* >* >::iterator iter = handlers.find(triggerEid);
            if( iter != handlers.end() )
            {
                map<EventId, TEventList*> *EventMap = iter->second;
                map<EventId, TEventList*>::iterator iter1 = EventMap->find(eventId);
                if (iter1 != EventMap->end())
                {
                    TEventList* l = iter1->second;
                    typedef TEventList::reverse_iterator RIT;
                    RIT iter2 = l->rbegin();
                    for(;iter2 != l->rend(); )
                    {
                        if (iter2->first == eid)
                        {
                            iter2 = RIT(l->erase((++iter2).base()));
                        }
                        else
                        {
                            ++iter2;
                        }
                    }

                        //if (l->empty())
                        //{
                        //    //如果没有人关注这个事件了，则需要删除list
                        //    delete l;
                        //    EventMap->erase(iter1);
                        //}
                }
            }
        }

        //触发事件
        TEventList* TriggerEvent(TENTITYID triggerEid, EventId eventId)
        {
            map<TENTITYID, map<EventId, TEventList* >* >::iterator iter = handlers.find(triggerEid);
            if (iter != handlers.end())
            {
                map<EventId, TEventList*> *EventMap = iter->second;
                map<EventId, TEventList*>::iterator iter1 = EventMap->find(eventId);
                if (iter1 != EventMap->end())
                {
                    return iter1->second;
                }
            }
            return NULL;
        }

        //删除entity
        void DeleteEntity(TENTITYID eid)
        {

            map<TENTITYID, map<EventId, TEventList* >* >::iterator iter = handlers.find(eid);
            if (iter != handlers.end())
            {
                map<EventId, TEventList*> *EventMap = iter->second;
                map<EventId, TEventList*>::iterator iter1 = EventMap->begin();
                for (;iter1 != EventMap->end();iter1++)
                {
                    TEventList* p = iter1->second;
                    p->clear();
                    delete p;
                }
                delete EventMap;
                handlers.erase(iter);
            }

            iter = handlers.begin();
            for (; iter != handlers.end(); iter++)
            {
                map<EventId, TEventList*> *EventMap = iter->second;
                map<EventId, TEventList*>::iterator iter1 = EventMap->begin();

                for (; iter1 != EventMap->end(); iter1++)
                {
                    TEventList* l = iter1->second;
                    typedef TEventList::reverse_iterator RIT;
                    RIT iter2 = l->rbegin();
                    for(;iter2 != l->rend(); )
                    {
                        if (iter2->first == eid)
                        {
                            iter2 = RIT(l->erase((++iter2).base()));
                        }
                        else
                        {
                            ++iter2;
                        }
                    }

                    //if (l->empty())
                    //{
                    //    //如果没有人关注这个事件了，则需要删除list
                    //    delete l;
                    //    EventMap->erase(iter1);
                    //}
                }
            }

        }

    private:
        map<TENTITYID, map<EventId, TEventList* >* > handlers;
        //map<EventId, list<pair<TENTITYID, const char *> >*> handlers;
};

#endif
