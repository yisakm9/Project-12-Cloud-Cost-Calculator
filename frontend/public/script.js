// frontend/public/script.js

// This placeholder will be replaced by the CI/CD pipeline.
const API_ENDPOINT = '%%API_ENDPOINT%%';

document.addEventListener('DOMContentLoaded', () => {
    const dashboardContainer = document.getElementById('dashboard-container');

    // Fail-safe check: If the placeholder was not replaced, show an error.
    if (API_ENDPOINT === '%%API_ENDPOINT%%' || !API_ENDPOINT) {
        dashboardContainer.innerHTML = '<h2>Error: API Endpoint Not Configured</h2><p>The application has not been deployed correctly. Please check the CI/CD pipeline configuration.</p>';
        console.error("API_ENDPOINT placeholder was not replaced. This is a deployment configuration issue.");
        return;
    }

    fetchCostData(dashboardContainer);
});

async function fetchCostData(container) {
    try {
        container.innerHTML = '<p>Loading cost data...</p>';
        const apiUrl = `${API_ENDPOINT}/costs`;
        console.log(`Fetching data from: ${apiUrl}`);

        const response = await fetch(apiUrl, { method: 'GET' });

        if (!response.ok) {
            const errorBody = await response.text();
            throw new Error(`API request failed with status ${response.status}: ${errorBody}`);
        }

        const data = await response.json();
        renderCostData(data, container);
    } catch (error) {
        console.error('Failed to fetch or render data:', error);
        container.innerHTML = `<h2>Failed to Load Cost Data</h2><p>There was an error communicating with the backend API.</p><p><i>Details: ${error.message}</i></p>`;
    }
}

function renderCostData(data, container) {
    const tableRows = data.costsByService
        .map(item => `
            <tr>
                <td>${item.service}</td>
                <td class="cost-cell">$${item.cost.toFixed(2)}</td>
            </tr>
        `)
        .join('');

    const dashboardHtml = `
        <h2>Weekly Cost Summary</h2>
        <p><b>Reporting Period:</b> ${data.reportingPeriod.start} to ${data.reportingPeriod.end}</p>
        <table class="cost-table">
            <thead>
                <tr><th>Service</th><th>Cost (USD)</th></tr>
            </thead>
            <tbody>${tableRows}</tbody>
            <tfoot>
                <tr>
                    <td><strong>Total Estimated Cost</strong></td>
                    <td class="cost-cell"><strong>$${data.totalCost.toFixed(2)}</strong></td>
                </tr>
            </tfoot>
        </table>
    `;
    container.innerHTML = dashboardHtml;
}