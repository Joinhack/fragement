package wxflow.service.impl;

import java.util.ArrayList;
import java.util.Collection;
import java.util.HashSet;
import java.util.List;
import java.util.Set;

import org.hibernate.criterion.DetachedCriteria;
import org.hibernate.criterion.Restrictions;
import org.springframework.security.core.GrantedAuthority;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.stereotype.Service;

import wxflow.models.Organization;
import wxflow.models.Role;
import wxflow.models.User;
import wxflow.service.UserService;

@Service
public class UserServiceImpl extends BaseServiceImpl implements UserService {

	@Override
	public User getUserByLoginId(String loginId) {
		DetachedCriteria criteria = DetachedCriteria.forClass(User.class);
		criteria.add(Restrictions.eq("loginId", loginId));
		return get(criteria);
	}
	
	@SuppressWarnings("unchecked")
	@Override
	public UserDetails getUserDetailByLoginId(String loginId) {
		DetachedCriteria criteria = DetachedCriteria.forClass(User.class);
		criteria.add(Restrictions.eq("loginId", loginId));
		User user = get(criteria);
		if(user == null) return null;
		Set<Role> roles = new HashSet<>();
		Organization org = user.getOrganization();
		while(org != null) {
			roles.addAll(org.getRoles());
			org = org.getParent();
		}
		roles.addAll(user.getRoles());
		List<GrantedAuthority> grants = new ArrayList<>();
		roles.forEach((Role r)->grants.add(new SimpleGrantedAuthority(r.getRoleDesc())));
		UserDetails details = new org.springframework.security.core.userdetails.User(user.getLoginId(), user.getPasswd(), ((Collection<? extends GrantedAuthority>) roles));
		return details;
	}

}
