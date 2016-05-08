package wxflow.service.impl;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.authentication.AuthenticationProvider;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.AuthenticationException;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.core.userdetails.UsernameNotFoundException;
import org.springframework.stereotype.Service;

import wxflow.service.UserService;

@Service
public class SecurityAuthenticationProvider implements AuthenticationProvider {
	
	@Autowired
	private UserService userService; 
	
	@Override
	public Authentication authenticate(Authentication authentication) throws AuthenticationException {
		String name = authentication.getName();
		UserDetails userDetails = userService.getUserDetailByLoginId(name);
		if(userDetails == null)
			throw new UsernameNotFoundException(name + " is not exist.");
		UsernamePasswordAuthenticationToken token = new UsernamePasswordAuthenticationToken(userDetails, authentication.getCredentials());
		return token;
	}

	@Override
	public boolean supports(Class<?> authentication) {
		return true;
	}

}
