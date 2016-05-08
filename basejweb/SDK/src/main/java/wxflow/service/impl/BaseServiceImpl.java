package wxflow.service.impl;

import java.util.List;

import org.hibernate.Criteria;
import org.hibernate.Session;
import org.hibernate.SessionFactory;
import org.hibernate.criterion.DetachedCriteria;
import org.springframework.beans.factory.annotation.Autowired;

import wxflow.service.BaseService;

public class BaseServiceImpl implements BaseService {
	
	@Autowired
    private SessionFactory sessionFactory;
	
	protected Session getSession() {
        return sessionFactory.getCurrentSession();
    }
	
	@SuppressWarnings("unchecked")
	@Override
    public <T> T get(Class<T> cls, long id) {
        return (T) this.getSession().get(cls, id);
    }

	@Override
	public void save(Object o) {
		this.getSession().save(o);
	}
	
	@Override
	public void delete(Object o) {
		this.getSession().delete(o);
	}
	
	@SuppressWarnings("unchecked")
	@Override
	public <T> T get(DetachedCriteria detachedCriteria) {
		if(detachedCriteria == null) return null;
		return (T) detachedCriteria.getExecutableCriteria(getSession()).uniqueResult();
	}
	
	@Override
	public <T> List<T> list(DetachedCriteria detachedCriteria) {
		return list(detachedCriteria, -1, -1);
	}
	
	@Override
	@SuppressWarnings("unchecked")
	public <T> List<T> list(DetachedCriteria detachedCriteria, int firstResult, int maxResults) {
		Criteria criteria = detachedCriteria.getExecutableCriteria(this.getSession());

        if (firstResult >= 0) {
            criteria.setFirstResult(firstResult);
        }

        if (maxResults > 0) {
            criteria.setMaxResults(maxResults);
        }

        return criteria.list();
	}
}
