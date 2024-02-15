public class AccountTriggerHandler extends TriggerHandler {

    public AccountTriggerHandler() {}

    public override void beforeInsert() {
        assigningRecordsToInternalUser();
        assignSalesArea();
    }

    public override void beforeUpdate() {
        fillingInAutoNumberField();
        assignSalesArea();
    }

    private void assigningRecordsToInternalUser() {
        List<Account> newAccountsList = Trigger.new;

        Map<Id, String> mapAccountIdAndFederationIdentifiers = new Map<Id, String>();
        Map<String, Id> mapFederationIdentifiersAndUserId = new Map<String, Id>();

        if (!FeatureToggleService.isFeatureEnabled(Constants.TOGGLED_FUNCTION_NAME_C3P_210)) {
            return;
        }

        List<String> federationIdentifiersList = getListOfFederationIdentifiersForOrganization();
        Set<Id> userIdsFromGroup = getIdOfUsersFromGroup(Constants.QUEUE_NAME_SGIS_ACCOUNT_OWNERS);

        for (Account a : newAccountsList) {
            if (!String.isBlank(a.Account_Master__c) && a.Account_Master__c != Constants.SALESFORCE && federationIdentifiersList.contains(a.Sales_Rep_SGID__c)) {
                mapAccountIdAndFederationIdentifiers.put(a.Id, a.Sales_Rep_SGID__c);
            }
        }          

        if (!mapAccountIdAndFederationIdentifiers.isEmpty()) {
            List<User> internalUsers = [SELECT Id, FederationIdentifier FROM User WHERE FederationIdentifier IN :mapAccountIdAndFederationIdentifiers.values()];
        
            for (User u : internalUsers) {
                mapFederationIdentifiersAndUserId.put(u.FederationIdentifier, u.Id);
            }

            for (Account a : newAccountsList) {
                if (!String.isBlank(a.Account_Master__c) && a.Account_Master__c != Constants.SALESFORCE) {
                    a.OwnerId = mapFederationIdentifiersAndUserId.get(mapAccountIdAndFederationIdentifiers.get(a.Id));
                }
            }
        } else {
            for (Account a : newAccountsList) {
                if (!String.isBlank(a.Account_Master__c) && a.Account_Master__c != Constants.SALESFORCE && a.Account_Master__c.contains(Constants.PREFIX_SAP)) {
                    a.OwnerId = chooseRandomUserId(userIdsFromGroup);
                } else if (String.isBlank(a.Account_Master__c)) {
                    a.Account_Master__c = Constants.SALESFORCE;
                }
            }
        }
    }

    private Set<Id> getIdOfUsersFromGroup(String groupName) {
        
        Map<Id, User> users= new Map<Id, User>([SELECT Id, 
                                  Name 
                           FROM User 
                           WHERE Id 
                            IN (SELECT UserOrGroupId 
                                FROM GroupMember 
                                WHERE Group.DeveloperName =: groupName)]);

        return users.keySet();
    }

    private Id chooseRandomUserId(Set<Id> userIdsFromGroup) {

        List<Id> userIds = new List<Id>(userIdsFromGroup);
        Integer randomNumber = Integer.valueof((Math.random() * userIds.size()));

        return userIds[randomNumber];
    }

    private List<String> getListOfFederationIdentifiersForOrganization() {

        List<String> federationIdentifiersList = new List<String>();

        List<User> internalUsers = [SELECT Id, FederationIdentifier FROM User];

        for (User user : internalUsers) {
            if (!String.isBlank(user.FederationIdentifier)) {
                federationIdentifiersList.add(user.FederationIdentifier);
            }
        }

        return federationIdentifiersList;
    }

    private void fillingInAutoNumberField() {
        if (!FeatureToggleService.isFeatureEnabled(Constants.TOGGLED_FUNCTION_NAME_C3P_207)) {
            return;
        }

        for (Account a : (List<Account>) Trigger.new) {
            a.AccountNumber = String.valueOf(a.Id).right(Constants.ACCOUNT_LENGTH_OF_AUTO_NUMBER_FIELD).toUpperCase();
        }
    }
    
    private void assignSalesArea() {
        for (Account acc : (List<Account>) Trigger.new) {
            if (acc.Brands__c != null && isChangedField(acc, Account.BillingPostalCode)) {
                if (acc.Brands__c.split(';').contains(Constants.BRAND_WEBER)) {
                    acc.Weber_Sales_Area__c = SalesAllocationService.getSalesArea(acc.BillingPostalCode)?.Id;
                }
            }
        }
    }
}
// Deploy
