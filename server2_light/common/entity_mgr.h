#ifndef __ENTITY_MGR_HEAD__
#define __ENTITY_MGR_HEAD__

#include "util.h"
#include "type_mogo.h"


namespace mogo
{


    template<typename T>
    class CEntityMgr
    {
        public:
            typedef map<TENTITYID, T*> TENTITYMAPS;

        public:
            CEntityMgr();
            virtual ~CEntityMgr();

        public:
            bool AddEntity(T* p);
            bool DelEntity(T* p);
            T* GetEntity(TENTITYID nid);

        public:
            inline typename map<TENTITYID, T*>::size_type Size() const
            {
                return m_entities.size();
            }
            inline const map<TENTITYID, T*>& ConstEntities() const
            {
                return m_entities;
            }
            inline map<TENTITYID, T*>& Entities()
            {
                return m_entities;
            }

        private:
            map<TENTITYID, T*> m_entities;

    };

    template<typename T>
    CEntityMgr<T>::CEntityMgr()
    {

    }

    template<typename T>
    CEntityMgr<T>::~CEntityMgr()
    {

    }

    template<typename T>
    bool CEntityMgr<T>::AddEntity(T* p)
    {
        TENTITYID eid = p->GetId();
        typename TENTITYMAPS::iterator iter = m_entities.lower_bound(eid);
        if(iter != m_entities.end() && iter->second->GetId() == eid)
        {
            return false;
        }
        else
        {
            m_entities.insert(iter, make_pair(eid, p));
            return true;
        }

    }

    template<typename T>
    bool CEntityMgr<T>::DelEntity(T* p)
    {
        TENTITYID eid = p->GetId();
        typename TENTITYMAPS::iterator iter = m_entities.find(eid);
        if(iter != m_entities.end())
        {
            m_entities.erase(iter);
            return true;
        }
        else
        {
            return false;
        }
    }

    template<typename T>
    T* CEntityMgr<T>::GetEntity(TENTITYID nid)
    {
        typename TENTITYMAPS::iterator iter = m_entities.find(nid);
        if(iter != m_entities.end())
        {
            return iter->second;
        }

        return NULL;
    }

}


#endif

