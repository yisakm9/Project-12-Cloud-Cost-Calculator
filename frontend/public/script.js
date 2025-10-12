// frontend/public/script.js

// This placeholder, '%%API_ENDPOINT%%', will be found and replaced by
// a 'sed' command in the GitHub Actions workflow during the deployment process.
const API_ENDPOINT = '%%API_ENDPOINT%%';

/**
 * Main execution function that runs after the DOM is fully loaded.
 */
document.addEventListener('DOMContentLoaded', () => {
    const dashboardContainer = document.getElementById('dashboard-container');

    // Fail-safe check: If the placeholder was not replaced, show an error.
    // This prevents a broken state if the CI/CD pipeline fails to inject the URL.
    if (API_ENDPOINT === '%%API_ENDPOINT%%' || !API_ENDPOINT) {
        dashboardContainer.innerHTML = '<h2>Error: API Endpoint Not Configured</h2><p>The application has not been deployed correctly. Please check the CI/CD pipeline configuration.</p>';
        console.error("API_ENDPOINT placeholder was not replaced. This is a deployment configuration issue.");
        return;
    }

    // Start the process of fetching and rendering the data.
    fetchCostData(dashboardContainer);
});

/**
 * Fetches cost data from the backend API.
 * @param {HTMLElement} container - The container element to update with status messages.
 */
async function fetchCostData(container) {
    try {
        // Display a loading message while the data is being fetched.
        container.innerHTML = '<p>Loading cost data...</p>';
        
        // Construct the full URL for the API endpoint.
        const apiUrl = `${API_ENDPOINT}/costs`;
        console.log(`Fetching data from: ${apiUrl}`);

        // Perform the GET request to our API Gateway.
        const response = await fetch(apiUrl, {
            method: 'GET',
        });

        // Check if the HTTP response is successful (status code 200-299).
        if (!response.ok) {
            const errorBody = await response.text();
            throw new Error(`API request failed with status ${response.status}: ${errorBody}`);
        }

        // Parse the JSON response body.
        const data = await response.json();
        
        // Pass the successfully fetched data to the rendering function.
        renderCostData(data, container);

    } catch (error) {
        // If any part of the try block fails, catch the error and display it.
        console.error('Failed to fetch or render data:', error);
        container.innerHTML = `<h2>Failed to Load Cost Data</h2><p>There was an error communicating with the backend API.</p><p><i>Details: ${error.message}</i></p>`;
    }
}

/**
 * Renders the fetched cost data into an HTML table inside the container.
 * @param {object} data - The cost data object returned from the API.
 * @param {HTMLElement} container - The container element to render the data into.
 */
function renderCostData(data, container) {
    // Generate an HTML string for each table row using the costsByService array.
    const tableRows = data.costsByService
        .map(item => `
            <tr>
                <td>${item.service}</td>
                <td class="cost-cell">$${item.cost.toFixed(2)}</td>
            </tr>
        `)
        .join('');

    // Construct the final HTML for the dashboard.
    const dashboardHtml = `
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

    // Replace the container's content with the new HTML.
    container.innerHTML = dashboardHtml;
}