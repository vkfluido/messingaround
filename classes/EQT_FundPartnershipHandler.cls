/**
    About
    -----
    Description: Trigger Handler for the Fund Partnership SObject.
                 This class implements the EQT_ITrigger interface to help ensure the trigger code is bulkified and all in one place.
    Created for: EQT
    Create date: June 2016
    
    Details / Methods
    -----------------
    Use case 1. Create fund commitments when mapping a partnership

    Update History
    --------------
    Created June 2016 - R.B.

    Issues / TODOs
    --------------
*/
public with sharing class EQT_FundPartnershipHandler implements EQT_ITrigger {
	
	//map of investran commitments for given partnership legal entitites, Partnership id -> investran commitment
	private Map<String, EQT_Investran_Commitment__c> investranCommitmentMap = new Map<String, EQT_Investran_Commitment__c>();
	//set of investran partnership legal entities in contaxt
	private Set<String> partnershipLegalEntityIds = new Set<String>();
	//map of fund commitment to check if fund commitment exists, LPCode -> fund commitments
	private Map<String, List<EQT_Fund_Commitment__c>> fundCommitmentMap = new Map<String, List<EQT_Fund_Commitment__c>>();
	//list of fund commitments to create
	private List<EQT_Fund_Commitment__c> toInsert = new List<EQT_Fund_Commitment__c>();
	private String ORIGIN_INVESTRAN = 'Investran';

	public EQT_FundPartnershipHandler() {}

	public void bulkBefore() {}
    
    public void bulkAfter() {
    	if(Trigger.isInsert || Trigger.isUpdate) {
    		for(SObject so : Trigger.new) {
                if(so.get('EQT_Fund__c') != null) {
                    partnershipLegalEntityIds.add((String)so.get('EQT_Investran_Partnership_Legal_EntityID__c'));
                }
            }
    	}
    	/*
    	else if(Trigger.isUpdate) {
    		for(SObject so : Trigger.new) {
    			EQT_Fund_Partnership__c fpNew = (EQT_Fund_Partnership__c) so;
                EQT_Fund_Partnership__c fpOld = (EQT_Fund_Partnership__c) Trigger.oldMap.get(fpNew.Id);

                if(fpOld.EQT_Fund__c == null && fpNew.EQT_Fund__c != null) {
                	partnershipLegalEntityIds.add(fpNew.EQT_Fund__c);
                }
    		}
    	}
    	*/

    	//build investran map based on partnership legal entities
    	for(EQT_Investran_Commitment__c ic : [SELECT Id, EQT_Amount_Total_Commitment__c, EQT_Commitment_Investran_ID_Invester_ID__c,
    											Commitment_LP_Code_Investor_Reference__c, EQT_Partnership_Legal_Entity__c,
    											EQT_Partnership_Legal_Entity_Name__c, EQT_Vehicle_ID_Organization_ID__c,
    											EQT_Vehicle_Name_Investor__c
    											FROM EQT_Investran_Commitment__c
    											WHERE EQT_Partnership_Legal_Entity__c IN :partnershipLegalEntityIds]) {

    		investranCommitmentMap.put(ic.EQT_Partnership_Legal_Entity__c, ic);
    	}

    	//build fund commitment map for later process
    	for(EQT_Fund_Commitment__c fc : [SELECT Id, EQT_Fund__c, EQTInvestran_Partnership_Legal_Entity_ID__c, EQT_LP_Code__c
    										FROM EQT_Fund_Commitment__c]) {

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
        
    public void beforeInsert(SObject so) {}
    
    public void beforeUpdate(SObject oldSo, SObject so) {}
    
    public void beforeDelete(SObject so) {}
    
    public void afterInsert(SObject so) {
    	EQT_Fund_Partnership__c fp = (EQT_Fund_Partnership__c)so;

    	if(fp.EQT_Fund__c != null && fp.EQT_Investran_Partnership_Legal_EntityID__c != null) {
    		//check if for given legal entity investran commitment exists
    		if(investranCommitmentMap.containsKey(fp.EQT_Investran_Partnership_Legal_EntityID__c)) {
    			//check if there are some fund commitments for given lp code
    			EQT_Investran_Commitment__c ic = investranCommitmentMap.get(fp.EQT_Investran_Partnership_Legal_EntityID__c);
    			String lpCode = ic.Commitment_LP_Code_Investor_Reference__c;

    			if(!fundCommitmentMap.containsKey(LPCode)) {
    				//create new fund commitment record
					toInsert.add(new EQT_Fund_Commitment__c
						(
							EQT_Amount__c = ic.EQT_Amount_Total_Commitment__c,
							EQT_Fund__c = fp.EQT_Fund__c,
							EQT_Investran_Invester_ID__c = ic.EQT_Commitment_Investran_ID_Invester_ID__c,
							EQTInvestran_Partnership_Legal_Entity_ID__c = ic.EQT_Partnership_Legal_Entity__c,
							EQT_LP_Code__c = lpCode,
							EQT_Partnership_Name__c = ic.EQT_Partnership_Legal_Entity_Name__c,
							EQT_Vehicle_Name__c = ic.EQT_Vehicle_Name_Investor__c,
							EQT_Vehicle_Organization_ID__c = ic.EQT_Vehicle_ID_Organization_ID__c,
							EQT_Origin__c = ORIGIN_INVESTRAN
						)
					);
    			}
    			/*
    			if(fundCommitmentMap.containsKey(LPCode)) {
    				//check if fund commitment for given fund exists
    				Boolean shouldCreate = true;
    				for(EQT_Fund_Commitment__c fc : fundCommitmentMap.get(LPCode)) {
    					if(fc.EQT_Fund__c == fp.EQT_Fund__c) {
    						shouldCreate = false;
    						break;
    					}
    				}

    				if(shouldCreate) {
    					//create new fund commitment record
    					toInsert.add(new EQT_Fund_Commitment__c
    						(
    							EQT_Amount__c = ic.EQT_Amount_Total_Commitment__c,
    							EQT_Fund__c = fp.EQT_Fund__c,
    							EQT_Investran_Invester_ID__c = ic.EQT_Commitment_Investran_ID_Invester_ID__c,
    							EQTInvestran_Partnership_Legal_Entity_ID__c = ic.EQT_Partnership_Legal_Entity__c,
    							EQT_LP_Code__c = lpCode,
    							EQT_Partnership_Name__c = ic.EQT_Partnership_Legal_Entity_Name__c,
    							EQT_Vehicle_Name__c = ic.EQT_Vehicle_Name_Investor__c,
    							EQT_Vehicle_Organization_ID__c = ic.EQT_Vehicle_ID_Organization_ID__c,
    							EQT_Origin__c = ORIGIN_INVESTRAN
    						)
    					);
    				}
    			}
    			else {
    				system.debug('Radek create');
    				//create new fund commitment record
    				toInsert.add(new EQT_Fund_Commitment__c
						(
							EQT_Amount__c = ic.EQT_Amount_Total_Commitment__c,
							EQT_Fund__c = fp.EQT_Fund__c,
							EQT_Investran_Invester_ID__c = ic.EQT_Commitment_Investran_ID_Invester_ID__c,
							EQTInvestran_Partnership_Legal_Entity_ID__c = ic.EQT_Partnership_Legal_Entity__c,
							EQT_LP_Code__c = lpCode,
							EQT_Partnership_Name__c = ic.EQT_Partnership_Legal_Entity_Name__c,
							EQT_Vehicle_Name__c = ic.EQT_Vehicle_Name_Investor__c,
							EQT_Vehicle_Organization_ID__c = ic.EQT_Vehicle_ID_Organization_ID__c,
							EQT_Origin__c = ORIGIN_INVESTRAN
						)
					);
    			}
    			*/
    		}
    	}
    }
    
    public void afterUpdate(SObject oldSo, SObject so) {
    	EQT_Fund_Partnership__c fpNew = (EQT_Fund_Partnership__c)so;
    	EQT_Fund_Partnership__c fpOld = (EQT_Fund_Partnership__c)oldSo;

    	if(fpOld.EQT_Fund__c == null && fpNew.EQT_Fund__c != null) {
    		if(fpNew.EQT_Fund__c != null && fpNew.EQT_Investran_Partnership_Legal_EntityID__c != null) {
	    		//check if for given legal entity investran commitment exists
	    		if(investranCommitmentMap.containsKey(fpNew.EQT_Investran_Partnership_Legal_EntityID__c)) {
	    			//check if there are some fund commitments for given lp code
	    			EQT_Investran_Commitment__c ic = investranCommitmentMap.get(fpNew.EQT_Investran_Partnership_Legal_EntityID__c);
	    			String lpCode = ic.Commitment_LP_Code_Investor_Reference__c;

	    			if(!fundCommitmentMap.containsKey(LPCode)) {
	    				toInsert.add(new EQT_Fund_Commitment__c
    						(
    							EQT_Amount__c = ic.EQT_Amount_Total_Commitment__c,
    							EQT_Fund__c = fpNew.EQT_Fund__c,
    							EQT_Investran_Invester_ID__c = ic.EQT_Commitment_Investran_ID_Invester_ID__c,
    							EQTInvestran_Partnership_Legal_Entity_ID__c = ic.EQT_Partnership_Legal_Entity__c,
    							EQT_LP_Code__c = lpCode,
    							EQT_Partnership_Name__c = ic.EQT_Partnership_Legal_Entity_Name__c,
    							EQT_Vehicle_Name__c = ic.EQT_Vehicle_Name_Investor__c,
    							EQT_Vehicle_Organization_ID__c = ic.EQT_Vehicle_ID_Organization_ID__c,
							    EQT_Origin__c = ORIGIN_INVESTRAN
    						)
    					);
	    			}
	    			/*
	    			if(fundCommitmentMap.containsKey(LPCode)) {
	    				//check if fund commitment for given fund exists
	    				Boolean shouldCreate = true;
	    				for(EQT_Fund_Commitment__c fc : fundCommitmentMap.get(LPCode)) {
	    					if(fc.EQT_Fund__c == fpNew.EQT_Fund__c) {
	    						shouldCreate = false;
	    						break;
	    					}
	    				}

	    				if(shouldCreate) {
	    					//create new fund commitment record
	    					toInsert.add(new EQT_Fund_Commitment__c
	    						(
	    							EQT_Amount__c = ic.EQT_Amount_Total_Commitment__c,
	    							EQT_Fund__c = fpNew.EQT_Fund__c,
	    							EQT_Investran_Invester_ID__c = ic.EQT_Commitment_Investran_ID_Invester_ID__c,
	    							EQTInvestran_Partnership_Legal_Entity_ID__c = ic.EQT_Partnership_Legal_Entity__c,
	    							EQT_LP_Code__c = lpCode,
	    							EQT_Partnership_Name__c = ic.EQT_Partnership_Legal_Entity_Name__c,
	    							EQT_Vehicle_Name__c = ic.EQT_Vehicle_Name_Investor__c,
	    							EQT_Vehicle_Organization_ID__c = ic.EQT_Vehicle_ID_Organization_ID__c,
	    							EQT_Origin__c = ORIGIN_INVESTRAN
	    						)
	    					);
	    				}
	    			}
	    			else {
	    				//create new fund commitment record
	    				toInsert.add(new EQT_Fund_Commitment__c
							(
								EQT_Amount__c = ic.EQT_Amount_Total_Commitment__c,
								EQT_Fund__c = fpNew.EQT_Fund__c,
								EQT_Investran_Invester_ID__c = ic.EQT_Commitment_Investran_ID_Invester_ID__c,
								EQTInvestran_Partnership_Legal_Entity_ID__c = ic.EQT_Partnership_Legal_Entity__c,
								EQT_LP_Code__c = lpCode,
								EQT_Partnership_Name__c = ic.EQT_Partnership_Legal_Entity_Name__c,
								EQT_Vehicle_Name__c = ic.EQT_Vehicle_Name_Investor__c,
								EQT_Vehicle_Organization_ID__c = ic.EQT_Vehicle_ID_Organization_ID__c,
								EQT_Origin__c = ORIGIN_INVESTRAN
							)
						);
	    			}
	    			*/
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
    	if(!toInsert.isEmpty()) {
    		insert toInsert;
    	}
    }
}