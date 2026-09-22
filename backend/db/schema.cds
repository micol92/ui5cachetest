namespace jwincidentapp02;
using { cuid } from '@sap/cds/common';
using { Attachments } from '@cap-js/attachments';

entity Incidents : cuid {
  title: String(100);
  urgency: String(20);
  status: String(20);
  attachments: Composition of many Attachments;
  conversations: Composition of many Conversations on conversations.incident = $self;
  customer: Association to Customers;
}

entity Conversations : cuid {
  timestamp: Timestamp;
  author: String(100);
  message: String(500);
  incident: Association to Incidents;
}

entity Customers : cuid {
  firstName: String(50);
  lastName: String(50);
  name : String(100) = (firstName || ' ' || lastName);
  phoneNumber: String(20);
  email: String(100);
  creditCardNumber: String(20);
  incidents: Association to many Incidents on incidents.customer = $self;
}