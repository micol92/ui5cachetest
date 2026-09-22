sap.ui.define([
    "sap/fe/test/JourneyRunner",
	"frontendui02/test/integration/pages/IncidentsList",
	"frontendui02/test/integration/pages/IncidentsObjectPage",
	"frontendui02/test/integration/pages/ConversationsObjectPage"
], function (JourneyRunner, IncidentsList, IncidentsObjectPage, ConversationsObjectPage) {
    'use strict';

    var runner = new JourneyRunner({
        launchUrl: sap.ui.require.toUrl('frontendui02') + '/test/flp.html#app-preview',
        pages: {
			onTheIncidentsList: IncidentsList,
			onTheIncidentsObjectPage: IncidentsObjectPage,
			onTheConversationsObjectPage: ConversationsObjectPage
        },
        async: true
    });

    return runner;
});

