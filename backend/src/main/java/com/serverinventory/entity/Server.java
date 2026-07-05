package com.serverinventory.entity;

import jakarta.persistence.*;

@Entity
@Table(name = "servers")
public class Server {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "server_name", nullable = false)
    private String serverName;

    @Column(name = "ip_address", nullable = false, unique = true)
    private String ipAddress;

    @Column(name = "operating_system", nullable = false)
    private String operatingSystem;

    @Column(nullable = false)
    private String environment;

    @Column(nullable = false)
    private String status;

    @Column(nullable = false)
    private String owner;

    // Default Constructor
    public Server() {
    }

    // Parameterized Constructor
    public Server(Long id, String serverName, String ipAddress,
                  String operatingSystem, String environment,
                  String status, String owner) {

        this.id = id;
        this.serverName = serverName;
        this.ipAddress = ipAddress;
        this.operatingSystem = operatingSystem;
        this.environment = environment;
        this.status = status;
        this.owner = owner;
    }

    // Getters and Setters

    public Long getId() {
        return id;
    }

    public void setId(Long id) {
        this.id = id;
    }

    public String getServerName() {
        return serverName;
    }

    public void setServerName(String serverName) {
        this.serverName = serverName;
    }

    public String getIpAddress() {
        return ipAddress;
    }

    public void setIpAddress(String ipAddress) {
        this.ipAddress = ipAddress;
    }

    public String getOperatingSystem() {
        return operatingSystem;
    }

    public void setOperatingSystem(String operatingSystem) {
        this.operatingSystem = operatingSystem;
    }

    public String getEnvironment() {
        return environment;
    }

    public void setEnvironment(String environment) {
        this.environment = environment;
    }

    public String getStatus() {
        return status;
    }

    public void setStatus(String status) {
        this.status = status;
    }

    public String getOwner() {
        return owner;
    }

    public void setOwner(String owner) {
        this.owner = owner;
    }

    @Override
    public String toString() {
        return "Server{" +
                "id=" + id +
                ", serverName='" + serverName + '\'' +
                ", ipAddress='" + ipAddress + '\'' +
                ", operatingSystem='" + operatingSystem + '\'' +
                ", environment='" + environment + '\'' +
                ", status='" + status + '\'' +
                ", owner='" + owner + '\'' +
                '}';
    }
}
