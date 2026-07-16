// ===============================
// Backend Base URL
// ===============================

// Change this URL after deploying your backend.

const BASE_URL = "http://43.205.125.210:8080/server-inventory/api/servers";


// ===============================
// GET ALL SERVERS
// ===============================

async function getServers() {

    try {

        const response = await fetch(BASE_URL);

        if (!response.ok) {
            throw new Error("Failed to fetch servers");
        }

        return await response.json();

    } catch (error) {

        console.error("GET Error :", error);

        return [];

    }

}


// ===============================
// GET SERVER BY ID
// ===============================

async function getServerById(id) {

    try {

        const response = await fetch(`${BASE_URL}/${id}`);

        if (!response.ok) {
            throw new Error("Server not found");
        }

        return await response.json();

    } catch (error) {

        console.error(error);

    }

}


// ===============================
// ADD SERVER
// ===============================

async function addServer(server) {

    try {

        const response = await fetch(BASE_URL, {

            method: "POST",

            headers: {
                "Content-Type": "application/json"
            },

            body: JSON.stringify(server)

        });

        if (!response.ok) {
            throw new Error("Unable to add server");
        }

        return await response.json();

    } catch (error) {

        console.error(error);

    }

}


// ===============================
// UPDATE SERVER
// ===============================

async function updateServer(id, server) {

    try {

        const response = await fetch(`${BASE_URL}/${id}`, {

            method: "PUT",

            headers: {
                "Content-Type": "application/json"
            },

            body: JSON.stringify(server)

        });

        if (!response.ok) {
            throw new Error("Unable to update server");
        }

        return await response.json();

    } catch (error) {

        console.error(error);

    }

}


// ===============================
// DELETE SERVER
// ===============================

async function deleteServer(id) {

    try {

        const response = await fetch(`${BASE_URL}/${id}`, {

            method: "DELETE"

        });

        if (!response.ok) {
            throw new Error("Unable to delete server");
        }

        return true;

    } catch (error) {

        console.error(error);

        return false;

    }

}
