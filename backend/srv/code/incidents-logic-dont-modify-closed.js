/**
 * 
 * @Before(event = { "UPDATE" }, entity = "jwincidentapp02Srv.Incidents")
 * @param {Object} request - User information, tenant-specific CDS model, headers and query parameters
 */
module.exports = async function(request) {
    const { Incidents } = cds.entities;

    // Retrieve the incident ID from the request data
    const { ID } = request.data;

    // Ensure the ID is defined
    if (ID === undefined) {
        return request.reject(400, 'Incident ID is required.');
    }

    // Fetch the incident from the database
    const incident = await SELECT.one.from(Incidents).where({ ID });

    // Ensure the incident exists
    if (!incident) {
        return request.reject(404, 'Incident not found.');
    }

    // Check if the status is closed (case insensitive)
    if (incident.status && incident.status.toLowerCase() === 'closed') {
        return request.reject(400, 'Cannot modify an incident with status closed.');
    }
};