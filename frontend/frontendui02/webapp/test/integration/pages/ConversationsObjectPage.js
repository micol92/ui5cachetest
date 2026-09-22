sap.ui.define(['sap/fe/test/ObjectPage'], function(ObjectPage) {
    'use strict';

    var CustomPageDefinitions = {
        actions: {},
        assertions: {}
    };

    return new ObjectPage(
        {
            appId: 'frontendui02',
            componentId: 'ConversationsObjectPage',
            contextPath: '/Incidents/conversations'
        },
        CustomPageDefinitions
    );
});