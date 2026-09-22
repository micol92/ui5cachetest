using { jwincidentapp02Srv } from '../srv/service.cds';

annotate jwincidentapp02Srv.Incidents with @UI.HeaderInfo: { TypeName: 'Incident', TypeNamePlural: 'Incidents', Title: { Value: incidentsID } };
annotate jwincidentapp02Srv.Incidents with {
  ID @UI.Hidden @Common.Text: { $value: incidentsID, ![@UI.TextArrangement]: #TextOnly }
};
annotate jwincidentapp02Srv.Incidents with @UI.Identification: [{ Value: incidentsID }];
annotate jwincidentapp02Srv.Incidents with {
  customer @Common.ValueList: {
    CollectionPath: 'Customers',
    Parameters    : [
      {
        $Type            : 'Common.ValueListParameterInOut',
        LocalDataProperty: customer_ID, 
        ValueListProperty: 'ID'
      },
      {
        $Type            : 'Common.ValueListParameterDisplayOnly',
        ValueListProperty: 'firstName'
      },
      {
        $Type            : 'Common.ValueListParameterDisplayOnly',
        ValueListProperty: 'lastName'
      },
      {
        $Type            : 'Common.ValueListParameterDisplayOnly',
        ValueListProperty: 'phoneNumber'
      },
      {
        $Type            : 'Common.ValueListParameterDisplayOnly',
        ValueListProperty: 'email'
      },
    ],
  }
};
annotate jwincidentapp02Srv.Incidents with @UI.DataPoint #title: {
  Value: title,
  Title: 'Title',
};
annotate jwincidentapp02Srv.Incidents with @UI.DataPoint #urgency: {
  Value: urgency,
  Title: 'Urgency',
};
annotate jwincidentapp02Srv.Incidents with @UI.DataPoint #status: {
  Value: status,
  Title: 'Status',
};
annotate jwincidentapp02Srv.Incidents with {
  incidentsID @title: 'ID';
  title @title: 'Title';
  urgency @title: 'Urgency';
  status @title: 'Status'
};

annotate jwincidentapp02Srv.Incidents with @UI.LineItem: [
    { $Type: 'UI.DataField', Value: incidentsID },
    { $Type: 'UI.DataField', Value: title },
    { $Type: 'UI.DataField', Value: urgency },
    { $Type: 'UI.DataField', Value: status },
    { $Type: 'UI.DataField', Label: 'Customer', Value: customer_ID }
];

annotate jwincidentapp02Srv.Incidents with @UI.FieldGroup #Main: {
  $Type: 'UI.FieldGroupType', Data: [
    { $Type: 'UI.DataField', Value: incidentsID },
    { $Type: 'UI.DataField', Value: title },
    { $Type: 'UI.DataField', Value: urgency },
    { $Type: 'UI.DataField', Value: status },
    { $Type: 'UI.DataField', Label: 'Customer', Value: customer_ID }
  ]
};

annotate jwincidentapp02Srv.Incidents with {
  conversations @Common.Label: 'Conversations';
  customer @Common.Label: 'Customer'
};

annotate jwincidentapp02Srv.Incidents with @UI.HeaderFacets: [
 { $Type : 'UI.ReferenceFacet', Target : '@UI.DataPoint#title' },
 { $Type : 'UI.ReferenceFacet', Target : '@UI.DataPoint#urgency' },
 { $Type : 'UI.ReferenceFacet', Target : '@UI.DataPoint#status' }
];

annotate jwincidentapp02Srv.Incidents with @UI.Facets: [
  { $Type: 'UI.ReferenceFacet', ID: 'Main', Label: 'General Information', Target: '@UI.FieldGroup#Main' },
  { $Type : 'UI.ReferenceFacet', ID : 'Conversations', Target : 'conversations/@UI.LineItem' }
];

annotate jwincidentapp02Srv.Incidents with @UI.SelectionFields: [
  customer_ID
];

annotate jwincidentapp02Srv.Conversations with @UI.HeaderInfo: { TypeName: 'Conversation', TypeNamePlural: 'Conversations' };
annotate jwincidentapp02Srv.Conversations with {
  incident @Common.ValueList: {
    CollectionPath: 'Incidents',
    Parameters    : [
      {
        $Type            : 'Common.ValueListParameterInOut',
        LocalDataProperty: incident_ID, 
        ValueListProperty: 'ID'
      },
      {
        $Type            : 'Common.ValueListParameterDisplayOnly',
        ValueListProperty: 'incidentsID'
      },
      {
        $Type            : 'Common.ValueListParameterDisplayOnly',
        ValueListProperty: 'title'
      },
      {
        $Type            : 'Common.ValueListParameterDisplayOnly',
        ValueListProperty: 'urgency'
      },
      {
        $Type            : 'Common.ValueListParameterDisplayOnly',
        ValueListProperty: 'status'
      },
    ],
  }
};
annotate jwincidentapp02Srv.Conversations with @UI.DataPoint #timestamp: {
  Value: timestamp,
  Title: 'Timestamp',
};
annotate jwincidentapp02Srv.Conversations with @UI.DataPoint #author: {
  Value: author,
  Title: 'Author',
};
annotate jwincidentapp02Srv.Conversations with @UI.DataPoint #message: {
  Value: message,
  Title: 'Message',
};
annotate jwincidentapp02Srv.Conversations with {
  timestamp @title: 'Timestamp';
  author @title: 'Author';
  message @title: 'Message'
};

annotate jwincidentapp02Srv.Conversations with @UI.LineItem: [
    { $Type: 'UI.DataField', Value: timestamp },
    { $Type: 'UI.DataField', Value: author },
    { $Type: 'UI.DataField', Value: message }
];

annotate jwincidentapp02Srv.Conversations with @UI.FieldGroup #Main: {
  $Type: 'UI.FieldGroupType', Data: [
    { $Type: 'UI.DataField', Value: timestamp },
    { $Type: 'UI.DataField', Value: author },
    { $Type: 'UI.DataField', Value: message }
  ]
};

annotate jwincidentapp02Srv.Conversations with {
  incident @Common.Text: { $value: incident.incidentsID, ![@UI.TextArrangement]: #TextOnly }
};

annotate jwincidentapp02Srv.Conversations with {
  incident @Common.Label: 'Incident'
};

annotate jwincidentapp02Srv.Conversations with @UI.HeaderFacets: [
 { $Type : 'UI.ReferenceFacet', Target : '@UI.DataPoint#timestamp' },
 { $Type : 'UI.ReferenceFacet', Target : '@UI.DataPoint#author' },
 { $Type : 'UI.ReferenceFacet', Target : '@UI.DataPoint#message' }
];

annotate jwincidentapp02Srv.Conversations with @UI.Facets: [
  { $Type: 'UI.ReferenceFacet', ID: 'Main', Label: 'General Information', Target: '@UI.FieldGroup#Main' }
];

annotate jwincidentapp02Srv.Conversations with @UI.SelectionFields: [
  incident_ID
];

annotate jwincidentapp02Srv.Customers with @UI.HeaderInfo: { TypeName: 'Customer', TypeNamePlural: 'Customers' };
annotate jwincidentapp02Srv.Customers with @UI.DataPoint #firstName: {
  Value: firstName,
  Title: 'First Name',
};
annotate jwincidentapp02Srv.Customers with @UI.DataPoint #lastName: {
  Value: lastName,
  Title: 'Last Name',
};
annotate jwincidentapp02Srv.Customers with @UI.DataPoint #phoneNumber: {
  Value: phoneNumber,
  Title: 'Phone Number',
};
annotate jwincidentapp02Srv.Customers with {
  firstName @title: 'First Name';
  lastName @title: 'Last Name';
  phoneNumber @title: 'Phone Number';
  email @title: 'Email'
};

annotate jwincidentapp02Srv.Customers with @UI.LineItem: [
    { $Type: 'UI.DataField', Value: firstName },
    { $Type: 'UI.DataField', Value: lastName },
    { $Type: 'UI.DataField', Value: phoneNumber },
    { $Type: 'UI.DataField', Value: email }
];

annotate jwincidentapp02Srv.Customers with @UI.FieldGroup #Main: {
  $Type: 'UI.FieldGroupType', Data: [
    { $Type: 'UI.DataField', Value: firstName },
    { $Type: 'UI.DataField', Value: lastName },
    { $Type: 'UI.DataField', Value: phoneNumber },
    { $Type: 'UI.DataField', Value: email }
  ]
};

annotate jwincidentapp02Srv.Customers with {
  incidents @Common.Label: 'Incidents'
};

annotate jwincidentapp02Srv.Customers with @UI.HeaderFacets: [
 { $Type : 'UI.ReferenceFacet', Target : '@UI.DataPoint#firstName' },
 { $Type : 'UI.ReferenceFacet', Target : '@UI.DataPoint#lastName' },
 { $Type : 'UI.ReferenceFacet', Target : '@UI.DataPoint#phoneNumber' }
];

annotate jwincidentapp02Srv.Customers with @UI.Facets: [
  { $Type: 'UI.ReferenceFacet', ID: 'Main', Label: 'General Information', Target: '@UI.FieldGroup#Main' }
];

