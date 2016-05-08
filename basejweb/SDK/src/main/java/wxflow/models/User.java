package wxflow.models;

import java.util.Set;

import javax.persistence.CascadeType;
import javax.persistence.Column;
import javax.persistence.Entity;
import javax.persistence.FetchType;
import javax.persistence.GeneratedValue;
import javax.persistence.GenerationType;
import javax.persistence.Id;
import javax.persistence.Index;
import javax.persistence.JoinColumn;
import javax.persistence.ManyToMany;
import javax.persistence.ManyToOne;
import javax.persistence.Table;

@Entity
@Table(indexes={
	@Index(name = "loginId", columnList = "loginId"),
})
public class User {
	
	private Long id;
	
	private String loginId;
	
	private String passwd;
	
	private Organization organization;
	
	private Set<Role> roles;
	
	@Id
	@GeneratedValue(strategy = GenerationType.AUTO)
	public Long getId() {
		return id;
	}

	public void setId(Long id) {
		this.id = id;
	}
	
	@Column(nullable=false)
	public String getLoginId() {
		return loginId;
	}

	public void setLoginId(String loginId) {
		this.loginId = loginId;
	}

	public String getPasswd() {
		return passwd;
	}

	public void setPasswd(String passwd) {
		this.passwd = passwd;
	}

	@ManyToOne(cascade={CascadeType.PERSIST, CascadeType.MERGE,CascadeType.REFRESH},optional=true, fetch=FetchType.LAZY)
	@JoinColumn(name="org_id")
	public Organization getOrganization() {
		return organization;
	}

	public void setOrganization(Organization organization) {
		this.organization = organization;
	}
	
	@ManyToMany(cascade={CascadeType.PERSIST, CascadeType.MERGE,CascadeType.REFRESH}, fetch=FetchType.LAZY)
	public Set<Role> getRoles() {
		return roles;
	}

	public void setRoles(Set<Role> roles) {
		this.roles = roles;
	}
	
}
