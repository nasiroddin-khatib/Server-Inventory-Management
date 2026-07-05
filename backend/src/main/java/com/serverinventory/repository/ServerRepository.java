package com.serverinventory.repository;

import java.util.List;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import com.serverinventory.entity.Server;

@Repository
public interface ServerRepository extends JpaRepository<Server, Long> {

    List<Server> findByServerNameContainingIgnoreCase(String serverName);

}
