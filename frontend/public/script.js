javascript
// This file will be used later to fetch and display cost data.
console.log("Dashboard script loaded.");
// frontend/public/script.js

// This placeholder will be replaced by the CI/CD pipeline.
const API_ENDPOINT = '%%API_ENDPOINT%%';

document.addEventListener('DOMContentLoaded', () => {
    const container = document.getElementById('dashboard-container');

    if (API_ENDPOINT === '%%API_ENDPOINT%%') {
        container.innerHTML = '<h2>Error: API Endpoint not configured.</h2><p>The application has not been deployed correctly.</p>';
        console.error("API_ENDPOINT has not been replaced by the CI/CD pipeline.");
        return;
    }

    fetchData(container);
});

async function fetchData(container) {
    try {
        container.innerHTML = '<p>Loading cost data...</p>';
        
        // Fetch data from our API Gateway endpoint
        const response = await fetch(`${API_ENDPOINT}/costs`, {
            method: 'GET',
        });

        if (!response.ok) {
            throw new Error(`API request failed with status ${response.status}`);
        }

        const data = await response.json();
        renderData(data, container);

    } catch (error) {
        console.error('Failed to fetch or render data:', error);
        container.innerHTML = `<h2>Failed to load data</h2><p>${error.message}</p>`;
    }
}

function renderData(data, container) {
    let tableRows = data.costsByService
        .map(item => `<tr><td>${item.service}</td><td class="cost-cell">$${item.cost.toFixed(2)}</td></tr>`)
        .join('');

    const html = `
        <h2>Weekly Cost Summary</h2>
        <p><b>Reporting Period:</b> ${data.reportingPeriod.start} to ${data.reportingPeriod.end}</p>
        <table class="cost-table">
            <thead>
                <tr>
                    <th>Service</th>
                    <th>Cost (USD)</th>
                </tr>
            </thead>
            <tbody>
                ${tableRows}
            </tbody>
            <tfoot>
                <tr>
                    <td><strong>Total Estimated Cost</strong></td>
                    <td class="cost-cell"><strong>$${data.totalCost.toFixed(2)}</strong></td>
                </tr>
            </tfoot>
        </table>
    `;
    container.innerHTML = html;
}