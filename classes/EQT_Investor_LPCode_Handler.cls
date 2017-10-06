/**
    About
    -----
    Description: Trigger Handler for the Investor LP Code SObject.
                 This class implements the EQT_ITrigger interface to help ensure the trigger code is bulkified and all in one place.
    Created for: EQT
    Create date: June 2016
    
    Details / Methods
    -----------------
    Use case 1. Connects Commitments to Investor based on LP Code

    Update History
    --------------
    Created June 2016 - R.B.

    Issues / TODOs
    --------------
*/
public with sharing class EQT_Investor_LPCode_Handler implements EQT_ITrigger {
	
	private Map<String, List<EQT_Fund_Commitment__c>> fundCommitmentMap = new Map<String, List<EQT_Fund_Commitment__c>>();
	private Set<String> lpCodeList = new Set<String>();
    private List<EQT_Fund_Commitment__c> fundCommitmentToUpdate = new List<EQT_Fund_Commitment__c>();

	public EQT_Investor_LPCode_Handler() {}

	public void bulkBefore() {}
    
    public void bulkAfter() {
        if(Trigger.isInsert) {
            for(SObject so : Trigger.new) {
                if(so.get('EQT_Investor__c') != null) {
                    lpCodeList.add((String)so.get('Name'));
                }
            }
        }
        else if(Trigger.isUpdate) {
            for(SObject so : Trigger.new) {
                if(so.get('EQT_Investor__c') != null) {
                    lpCodeList.add((String)so.get('Name'));
                }
            }

            for(SObject so : Trigger.old) {
                if(so.get('EQT_Investor__c') != null) {
                    lpCodeList.add((String)so.get('Name'));
                }
            }
        }

        if(!lpCodeList.isEmpty()) {
            for(EQT_Fund_Commitment__c fc : [SELECT Id, EQT_Amount__c, EQT_Fund__c, EQT_LP_Code__c, EQT_Investor__c
                                                FROM EQT_Fund_Commitment__c
                                                WHERE EQT_LP_Code__c IN :lpCodeList]) {
                if(fundCommitmentMap.containsKey(fc.EQT_LP_Code__c)) {
                    fundCommitmentMap.get(fc.EQT_LP_Code__c).add(fc);
                }
                else {
                    List<EQT_Fund_Commitment__c> tmp = new List<EQT_Fund_Commitment__c>();
                    tmp.add(fc);
                    fundCommitmentMap.put(fc.EQT_LP_Code__c, tmp);
                }
            }
        }
    }
        
    public void beforeInsert(SObject so) {}
    
    public void beforeUpdate(SObject oldSo, SObject so) {}
    
    public void beforeDelete(SObject so) {}
    
    public void afterInsert(SObject so) {
        EQT_Investor_LP_Code__c investorLPCode = (EQT_Investor_LP_Code__c)so;

        if(investorLPCode.EQT_Investor__c != null) {
            //check for fund commitment for this investor based on LP Code
            if(fundCommitmentMap.containsKey(investorLPCode.Name)) {
                for(EQT_Fund_Commitment__c fc : fundCommitmentMap.get(investorLPCode.Name)) {
                    //check if fund commitment have lookup to account not set
                    if(fc.EQT_Investor__c == null) {
                         fc.EQT_Investor__c = investorLPCode.EQT_Investor__c;
                        fundCommitmentToUpdate.add(fc);
                    }
                }
            }
        }
    }
    
    public void afterUpdate(SObject oldSo, SObject so) {        
        EQT_Investor_LP_Code__c investorLPCodeNew = (EQT_Investor_LP_Code__c)so;
        EQT_Investor_LP_Code__c investorLPCodeOld = (EQT_Investor_LP_Code__c)oldSo;

        //if there was no investor and now it is
        if(investorLPCodeOld.EQT_Investor__c == null && investorLPCodeNew.EQT_Investor__c != null) {
            //check for fund commitment for this investor based on LP Code
            if(fundCommitmentMap.containsKey(investorLPCodeNew.Name)) {
                for(EQT_Fund_Commitment__c fc : fundCommitmentMap.get(investorLPCodeNew.Name)) {
                    //check if fund commitment have lookup to account not set
                    if(fc.EQT_Investor__c == null) {
                         fc.EQT_Investor__c = investorLPCodeNew.EQT_Investor__c;
                        fundCommitmentToUpdate.add(fc);
                    }
                }
            }
        }
        //if investor was changed
        else if(investorLPCodeOld.EQT_Investor__c != null && investorLPCodeNew.EQT_Investor__c != null && investorLPCodeNew.EQT_Investor__c != investorLPCodeOld.EQT_Investor__c){
            //get all commitments for old investor and update it with new one
            if(fundCommitmentMap.containsKey(investorLPCodeOld.Name)) {
                for(EQT_Fund_Commitment__c fc : fundCommitmentMap.get(investorLPCodeOld.Name)) {
                    fc.EQT_Investor__c = investorLPCodeNew.EQT_Investor__c;
                    fundCommitmentToUpdate.add(fc);
                }
            }
        }
        //if investor was removed
        else if(investorLPCodeOld.EQT_Investor__c != null && investorLPCodeNew.EQT_Investor__c == null) {
            if(fundCommitmentMap.containsKey(investorLPCodeOld.Name)) {
                /*
                EQT_Fund_Commitment__c fc = fundCommitmentMap.get(investorLPCodeOld.Name);
                if(fc != null) {
                    fundCommitmentToDelete.add(fc);
                }
                */
                for(EQT_Fund_Commitment__c fc : fundCommitmentMap.get(investorLPCodeOld.Name)) {
                    fc.EQT_Investor__c = null;
                    fundCommitmentToUpdate.add(fc);
                }
            }
        }
    }
    
    public void afterDelete(SObject so) {}
    
    /**
     * andFinally
     *
     * This method is called once all records have been processed by the trigger. Use this 
     * method to accomplish any final operations such as creation or updates of other records.
     */
    public void andFinally() {
    	if(!fundCommitmentToUpdate.isEmpty()) {
    		update fundCommitmentToUpdate;
    	}
    }
}