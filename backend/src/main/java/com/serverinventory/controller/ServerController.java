package com.serverinventory.controller;

import java.util.List;

import com.serverinventory.entity.Server;
import com.serverinventory.service.ServerService;

import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/servers")
@CrossOrigin(origins = "*")
public class ServerController {

    private final ServerService serverService;

    public ServerController(ServerService serverService) {
        this.serverService = serverService;
    }

    // Get All Servers
    @GetMapping
    public ResponseEntity<List<Server>> getAllServers() {

        return ResponseEntity.ok(serverService.getAllServers());

    }

    // Get Server By Id
    @GetMapping("/{id}")
    public ResponseEntity<Server> getServerById(
            @PathVariable Long id) {

        return ResponseEntity.ok(serverService.getServerById(id));

    }

    // Search Server
    @GetMapping("/search")
    public ResponseEntity<List<Server>> searchServers(
            @RequestParam String name) {

        return ResponseEntity.ok(
                serverService.searchServers(name));

    }

    // Add Server
    @PostMapping
    public ResponseEntity<Server> addServer(
            @RequestBody Server server) {

        Server savedServer = serverService.addServer(server);

        return new ResponseEntity<>(
                savedServer,
                HttpStatus.CREATED);

    }

    // Update Server
    @PutMapping("/{id}")
    public ResponseEntity<Server> updateServer(
            @PathVariable Long id,
            @RequestBody Server server) {

        return ResponseEntity.ok(
                serverService.updateServer(id, server));

    }

    // Delete Server
    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deleteServer(
            @PathVariable Long id) {

        serverService.deleteServer(id);

        return ResponseEntity.noContent().build();

    }

}
