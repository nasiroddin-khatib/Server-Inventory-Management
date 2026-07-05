// =============================
// Global Variables
// =============================

const modal = document.getElementById("serverModal");
const addServerBtn = document.getElementById("addServerBtn");
const closeModal = document.getElementById("closeModal");
const serverForm = document.getElementById("serverForm");
const serverContainer = document.getElementById("serverContainer");
const searchInput = document.getElementById("searchInput");

let editingServerId = null;
let servers = [];

// =============================
// Initial Load
// =============================

document.addEventListener("DOMContentLoaded", () => {
    loadServers();
});

// =============================
// Load Servers
// =============================

async function loadServers() {

    servers = await getServers();

    renderServers(servers);

}

// =============================
// Render Cards
// =============================

function renderServers(serverList) {

    serverContainer.innerHTML = "";

    if (serverList.length === 0) {

        serverContainer.innerHTML = `
            <div class="server-card">
                <h2>No Servers Found</h2>
                <p>Add your first server.</p>
            </div>
        `;

        return;

    }

    serverList.forEach(server => {

        let statusClass = "";

        switch (server.status.toLowerCase()) {

            case "running":
                statusClass = "running";
                break;

            case "stopped":
                statusClass = "stopped";
                break;

            default:
                statusClass = "maintenance";
        }

        serverContainer.innerHTML += `

        <div class="server-card">

            <h2>${server.serverName}</h2>

            <div class="info">

                <p><strong>IP :</strong> ${server.ipAddress}</p>

                <p><strong>OS :</strong> ${server.operatingSystem}</p>

                <p><strong>Environment :</strong> ${server.environment}</p>

                <p><strong>Status :</strong>

                    <span class="status ${statusClass}">
                        ${server.status}
                    </span>

                </p>

                <p><strong>Owner :</strong> ${server.owner}</p>

            </div>

            <div class="card-buttons">

                <button
                    class="edit-btn"
                    onclick="editServer(${server.id})">

                    Edit

                </button>

                <button
                    class="delete-btn"
                    onclick="removeServer(${server.id})">

                    Delete

                </button>

            </div>

        </div>

        `;

    });

}

// =============================
// Modal
// =============================

addServerBtn.onclick = () => {

    editingServerId = null;

    serverForm.reset();

    modal.style.display = "flex";

};

closeModal.onclick = () => {

    modal.style.display = "none";

};

window.onclick = function (event) {

    if (event.target === modal) {

        modal.style.display = "none";

    }

};

// =============================
// Save Server
// =============================

serverForm.addEventListener("submit", async function (e) {

    e.preventDefault();

    const server = {

        serverName: document.getElementById("serverName").value,

        ipAddress: document.getElementById("ipAddress").value,

        operatingSystem: document.getElementById("operatingSystem").value,

        environment: document.getElementById("environment").value,

        status: document.getElementById("status").value,

        owner: document.getElementById("owner").value

    };

    if (editingServerId == null) {

        await addServer(server);

        alert("Server Added Successfully");

    } else {

        await updateServer(editingServerId, server);

        alert("Server Updated Successfully");

    }

    modal.style.display = "none";

    loadServers();

});

// =============================
// Edit
// =============================

async function editServer(id) {

    const server = await getServerById(id);

    editingServerId = id;

    document.getElementById("serverName").value = server.serverName;

    document.getElementById("ipAddress").value = server.ipAddress;

    document.getElementById("operatingSystem").value = server.operatingSystem;

    document.getElementById("environment").value = server.environment;

    document.getElementById("status").value = server.status;

    document.getElementById("owner").value = server.owner;

    modal.style.display = "flex";

}

// =============================
// Delete
// =============================

async function removeServer(id) {

    const confirmDelete = confirm("Delete this server?");

    if (!confirmDelete)
        return;

    const success = await deleteServer(id);

    if (success) {

        alert("Server Deleted");

        loadServers();

    }

}

// =============================
// Search
// =============================

searchInput.addEventListener("keyup", function () {

    const keyword = this.value.toLowerCase();

    const filtered = servers.filter(server =>

        server.serverName.toLowerCase().includes(keyword) ||

        server.ipAddress.toLowerCase().includes(keyword) ||

        server.owner.toLowerCase().includes(keyword) ||

        server.environment.toLowerCase().includes(keyword)

    );

    renderServers(filtered);

});
