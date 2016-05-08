package wxflow.models;

import java.util.Set;

import javax.persistence.CascadeType;
import javax.persistence.Entity;
import javax.persistence.FetchType;
import javax.persistence.GeneratedValue;
import javax.persistence.GenerationType;
import javax.persistence.Id;
import javax.persistence.JoinColumn;
import javax.persistence.ManyToMany;
import javax.persistence.ManyToOne;
import javax.persistence.OneToMany;

@Entity
public class Organization {
	private Long id;
	
	private String name;
	
	private Organization parent;
	
	private Set<Organization> childrens;
	
	private Set<User> users;
	
	private Set<Role> roles;
	
	@Id
	@GeneratedValue(strategy = GenerationType.AUTO)
	public Long getId() {
		return id;
	}

	public void setId(Long id) {
		this.id = id;
	}

	public String getName() {
		return name;
	}

	public void setName(String name) {
		this.name = name;
	}

	@OneToMany(cascade = {CascadeType.PERSIST, CascadeType.MERGE, CascadeType.REFRESH}, fetch=FetchType.LAZY)
	public Set<Organization> getChildrens() {
		return childrens;
	}

	public void setChildrens(Set<Organization> childrens) {
		this.childrens = childrens;
	}
	
	@ManyToOne(cascade={CascadeType.PERSIST, CascadeType.MERGE,CascadeType.REFRESH},optional=true, fetch=FetchType.LAZY)
	@JoinColumn(name="parent_id")
	public Organization getParent() {
		return parent;
	}

	public void setParent(Organization parent) {
		this.parent = parent;
	}
	
	@OneToMany(cascade = {CascadeType.PERSIST, CascadeType.MERGE, CascadeType.REFRESH}, fetch=FetchType.LAZY)
	public Set<User> getUsers() {
		return users;
	}

	public void setUsers(Set<User> users) {
		this.users = users;
	}

	@ManyToMany(cascade={CascadeType.PERSIST, CascadeType.MERGE,CascadeType.REFRESH}, fetch=FetchType.LAZY)
	public Set<Role> getRoles() {
		return roles;
	}

	public void setRoles(Set<Role> roles) {
		this.roles = roles;
	}
	
}
