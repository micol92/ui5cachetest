using { jwincidentapp02 as my } from '../db/schema.cds';

@path: '/service/jwincidentapp02'
@requires: 'authenticated-user'
service jwincidentapp02Srv {
  @odata.draft.enabled
  entity Incidents as projection on my.Incidents;
  @odata.draft.enabled
  entity Customers as projection on my.Customers;

  annotate my.Incidents {
  customer @changelog: [customer.name];
  title    @changelog;
  status   @changelog;
  }

  annotate my.Customers with @PersonalData : {
    DataSubjectRole : 'Customer',
    EntitySemantics : 'DataSubject'
  } {
    ID           @PersonalData.FieldSemantics: 'DataSubjectID';
    firstName    @PersonalData.IsPotentiallyPersonal;
    lastName     @PersonalData.IsPotentiallyPersonal;
    email        @PersonalData.IsPotentiallyPersonal;
    creditCardNumber @PersonalData.IsPotentiallySensitive;
  };

}