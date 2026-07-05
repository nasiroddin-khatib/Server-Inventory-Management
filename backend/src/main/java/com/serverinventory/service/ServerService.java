package com.serverinventory.service;

import java.util.List;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;

import com.serverinventory.entity.Server;
import com.serverinventory.exception.ResourceNotFoundException;
import com.serverinventory.repository.ServerRepository;

@Service
public class ServerService {

    private static final Logger logger =
            LoggerFactory.getLogger(ServerService.class);

    private final ServerRepository serverRepository;

    public ServerService(ServerRepository serverRepository) {
        this.serverRepository = serverRepository;
    }

    // Get All Servers
    public List<Server> getAllServers() {

        logger.info("Fetching all servers");

        return serverRepository.findAll();
    }

    // Get Server By Id
    public Server getServerById(Long id) {

        logger.info("Fetching server with id : {}", id);

        return serverRepository.findById(id)
                .orElseThrow(() ->
                        new ResourceNotFoundException(
                                "Server not found with id : " + id));
    }

    // Add Server
    public Server addServer(Server server) {

        logger.info("Adding new server : {}", server.getServerName());

        return serverRepository.save(server);
    }

    // Update Server
    public Server updateServer(Long id, Server updatedServer) {

        logger.info("Updating server with id : {}", id);

        Server existingServer = serverRepository.findById(id)
                .orElseThrow(() ->
                        new ResourceNotFoundException(
                                "Server not found with id : " + id));

        existingServer.setServerName(updatedServer.getServerName());
        existingServer.setIpAddress(updatedServer.getIpAddress());
        existingServer.setOperatingSystem(updatedServer.getOperatingSystem());
        existingServer.setEnvironment(updatedServer.getEnvironment());
        existingServer.setStatus(updatedServer.getStatus());
        existingServer.setOwner(updatedServer.getOwner());

        return serverRepository.save(existingServer);
    }

    // Delete Server
    public void deleteServer(Long id) {

        logger.info("Deleting server with id : {}", id);

        Server server = serverRepository.findById(id)
                .orElseThrow(() ->
                        new ResourceNotFoundException(
                                "Server not found with id : " + id));

        serverRepository.delete(server);

        logger.info("Server deleted successfully : {}", id);
    }

    // Search Server
    public List<Server> searchServers(String serverName) {

        logger.info("Searching server : {}", serverName);

        return serverRepository
                .findByServerNameContainingIgnoreCase(serverName);
    }

}
