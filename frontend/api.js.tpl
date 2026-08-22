// ==========================================================
// Backend Base URL
// ==========================================================

const BASE_URL = "http://${alb_dns_name}/server-inventory/api/servers";


// ==========================================================
// GET ALL SERVERS
// ==========================================================

async function getServers() {

    try {

        const response = await fetch(BASE_URL);

        if (!response.ok) {
            throw new Error(`Failed to fetch servers: ${response.status}`);
        }

        return await response.json();

    } catch (error) {

        console.error("GET servers error:", error);

        return [];

    }
}


// ==========================================================
// GET SERVER BY ID
// ==========================================================

async function getServerById(id) {

    try {

        const response = await fetch(`${BASE_URL}/${id}`);

        if (!response.ok) {
            throw new Error(`Server not found: ${response.status}`);
        }

        return await response.json();

    } catch (error) {

        console.error("GET server by ID error:", error);

        return null;

    }
}


// ==========================================================
// ADD SERVER
// ==========================================================

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
            throw new Error(`Unable to add server: ${response.status}`);
        }

        return await response.json();

    } catch (error) {

        console.error("POST server error:", error);

        return null;

    }
}


// ==========================================================
// UPDATE SERVER
// ==========================================================

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
            throw new Error(`Unable to update server: ${response.status}`);
        }

        return await response.json();

    } catch (error) {

        console.error("PUT server error:", error);

        return null;

    }
}


// ==========================================================
// DELETE SERVER
// ==========================================================

async function deleteServer(id) {

    try {

        const response = await fetch(`${BASE_URL}/${id}`, {

            method: "DELETE"

        });

        if (!response.ok) {
            throw new Error(`Unable to delete server: ${response.status}`);
        }

        return true;

    } catch (error) {

        console.error("DELETE server error:", error);

        return false;

    }
}
