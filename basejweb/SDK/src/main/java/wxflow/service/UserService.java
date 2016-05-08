package wxflow.service;

import org.springframework.security.core.userdetails.UserDetails;

import wxflow.models.User;

public interface UserService extends BaseService {
	
	public User getUserByLoginId(String loginId);
	
	public UserDetails getUserDetailByLoginId(String loginId);
	
}
