/**
    About
    -----
    Description: Trigger factory pattern
    Created for: EQT
    Create date: May 2016
    
    Details / Methods
    -----------------
        - createHandler // method to create and execute a trigger handler. Throws a TriggerException if no handler has been coded.
        - getHandler // method to get the appropriate handler for the object type
   
    Update History
    --------------
    Created May 2016 - R.B.
    2017-03-16: RMOHR - Added EQT_AffiliationHandler

    Issues / TODOs
    --------------
*/
public with sharing class EQT_TriggerFactory {
    
    public class TriggerException extends Exception{}
    
    public static void createHandler(Schema.sObjectType soType) {
        // Get a handler appropriate to the object being processed
        EQT_ITrigger handler = getHandler(soType);
        
        // Make sure we have a handler registered, new handlers must be registered in the getHandler method.
        if(handler == null) {
            throw new TriggerException('No Trigger Handler registered for Object Type: ' + soType);
        }
        
        // Execute the handler to fulfil the trigger
        execute(handler);
    }

    private static void execute(EQT_ITrigger handler) {
        // Before Trigger
        if(Trigger.isBefore) {
            // Call the bulk before to handle any caching of data and enable bulkification
            handler.bulkBefore();
            
            // Iterate through the records to be deleted passing them to the handler.
            if(Trigger.isDelete) {
                for(SObject so : Trigger.old) {
                    handler.beforeDelete(so);
                }
            }
            // Iterate through the records to be inserted passing them to the handler.
            else if(Trigger.isInsert) {
                for(SObject so : Trigger.new) {
                    handler.beforeInsert(so);
                }
            }
            // Iterate through the records to be updated passing them to the handler.
            else if(Trigger.isUpdate) {
                for(SObject so : Trigger.old) {
                    handler.beforeUpdate(so, Trigger.newMap.get(so.Id));
                }
            }
        }
        else {
            // Call the bulk after to handle any caching of data and enable bulkification
            handler.bulkAfter();
            
            // Iterate through the records deleted passing them to the handler.
            if(Trigger.isDelete) {
                for(SObject so : Trigger.old) {
                    handler.afterDelete(so);
                }
            }
            // Iterate through the records inserted passing them to the handler.
            else if(Trigger.isInsert) {
                for(SObject so : Trigger.new) {
                    handler.afterInsert(so);
                }
            }
            // Iterate through the records updated passing them to the handler.
            else if(Trigger.isUpdate) {
                for(SObject so : Trigger.old) {
                    handler.afterUpdate(so, Trigger.newMap.get(so.Id));
                }
            }
        }
        
        // Perform any post processing
        handler.andFinally();
    }

    private static EQT_ITrigger getHandler(Schema.sObjectType soType) {
        if(soType == Contact.sObjectType) {
            return new EQT_ContactHandler();
        }
        if(soType == Account.sObjectType) {//else if(soType == Account.sObjectType) {
            return new EQT_AccountHandler();
        }
        if(soType == Fund__c.sObjectType) {
            return new EQT_FundHandler();
        }
        else if(soType == Opportunity.sObjectType) {
            return new EQT_OpportunityHandler();
        }
        else if(soType == EQT_Commitment__c.sObjectType) {
            return new EQT_CommitmentHandler();
        }
        else if(soType == EQT_Proxy_AccountContactRelation__c.sObjectType) {
            return new EQT_Proxy_AccountContactRelationHandler();
        }
        else if(soType == EQT_Investran_Commitment__c.sObjectType) {
            return new EQT_InvestranCommitmentHandler();
        }
        else if(soType == EQT_Investor_LP_Code__c.sObjectType) {
            return new EQT_Investor_LPCode_Handler();
        }
        else if(soType == EQT_Fund_Partnership__c.sObjectType) {
            return new EQT_FundPartnershipHandler();
        }
        else if(soType == EQT_Fund_Commitment__c.sObjectType) {
            return new EQT_FundCommitmentHandler();
        }
        else if(soType == EQT_Investran_Contact_List_Import__c.sObjectType) {
            return new EQT_InvestranContactListImportHandler();
        }
        else if(soType == Event.sObjectType) {
            return new EQT_EventHandler();
        }
        else if(soType == EQT_Proxy_EventRelation__c.sObjectType) {
            return new EQT_ProxyEventRelationHandler();
        }
        else if(soType == Case.sObjectType) {
            return new EQT_CaseHandler();
        }
        else if(soType == Task.sObjectType) {
            return new EQT_TaskHandler();
        }
        else if(soType == EQT_Assignment__c.sObjectType) {
            return new EQT_AssignmentHandler();
        }
        else if(soType == Bespoke_Reporting__c.sObjectType) {
            return new EQT_BespokeReportingHandler();
        }
        else if(soType == EQT_IA_Contract__c.sObjectType) {
            return new EQT_AgreementHandler();
        }
        else if(soType == EQT_Affiliation__c.sObjectType) {
            return new EQT_AffiliationHandler();
        }
        else if(soType == OpportunityTeamMember.sObjectType) {
            return new EQT_OpportunityTeamMemberHandler();
        }
        else if(soType == EQT_Sector_Team_Member__c.sObjectType) {
            return new EQT_SectorTeamMemberHandler();
        }
        else if(soType == EQT_Sector_Rating__c.sObjectType) {
            return new EQT_SectorRatingHandler();
        }
        else if(soType == User.sObjectType) {
            return new EQT_UserHandler();
        }
        return null;
    }
}