package wxflow.service;

import java.util.List;

import org.hibernate.criterion.DetachedCriteria;

public interface BaseService {
	
	<T> T get(Class<T> cls, long id);
	
	void save(Object o);
	
	public void delete(Object o);
	
	public <T> List<T> list(DetachedCriteria detachedCriteria);
	
	public <T> List<T> list(DetachedCriteria detachedCriteria, int firstResult, int maxResults);
	
	public <T> T get(DetachedCriteria detachedCriteria);
	
}
