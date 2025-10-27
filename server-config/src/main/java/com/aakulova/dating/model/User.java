package com.aakulova.dating.model;

import jakarta.persistence.*;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import java.time.LocalDateTime;
import java.util.List;

@Entity
@Table(name = "users")
public class User {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long userId;

    @NotBlank
    @Size(max = 100)
    private String userName;

    @NotBlank
    @Column(unique = true)
    private String userPhone;

    @NotBlank
    private String userPassword;

    private Integer userAge;

    private String userGender;

    private String userDescription;

    private String userPhotoUrl;

    @OneToMany(mappedBy = "fromUser", cascade = CascadeType.ALL)
    private List<Like> userFromLike;

    @OneToMany(mappedBy = "toUser", cascade = CascadeType.ALL)
    private List<Like> userToLike;

    @OneToMany(mappedBy = "user", cascade = CascadeType.ALL)
    private List<UserAnswer> userAnswers;

    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;

    // Constructors
    public User() {
        this.createdAt = LocalDateTime.now();
        this.updatedAt = LocalDateTime.now();
    }

    // Getters and Setters
    public Long getUserId() { return userId; }
    public void setUserId(Long userId) { this.userId = userId; }

    public String getUserName() { return userName; }
    public void setUserName(String userName) { this.userName = userName; }

    public String getUserPhone() { return userPhone; }
    public void setUserPhone(String userPhone) { this.userPhone = userPhone; }

    public String getUserPassword() { return userPassword; }
    public void setUserPassword(String userPassword) { this.userPassword = userPassword; }

    public Integer getUserAge() { return userAge; }
    public void setUserAge(Integer userAge) { this.userAge = userAge; }

    public String getUserGender() { return userGender; }
    public void setUserGender(String userGender) { this.userGender = userGender; }

    public String getUserDescription() { return userDescription; }
    public void setUserDescription(String userDescription) { this.userDescription = userDescription; }

    public String getUserPhotoUrl() { return userPhotoUrl; }
    public void setUserPhotoUrl(String userPhotoUrl) { this.userPhotoUrl = userPhotoUrl; }

    public LocalDateTime getCreatedAt() { return createdAt; }
    public void setCreatedAt(LocalDateTime createdAt) { this.createdAt = createdAt; }

    public LocalDateTime getUpdatedAt() { return updatedAt; }
    public void setUpdatedAt(LocalDateTime updatedAt) { this.updatedAt = updatedAt; }
}
