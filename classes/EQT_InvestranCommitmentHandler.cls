/**
    About
    -----
    Description: Trigger Handler for the Investran Commitment SObject.
                 This class implements the EQT_ITrigger interface to help ensure the trigger code is bulkified and all in one place.
    Created for: EQT
    Create date: June 2016
    
    Details / Methods
    -----------------
    Use case 1. Create new objects (Fund Partnerships, Investor LP Codes, Fund Commitments)
   
    Update History
    --------------
    Created June 2016 - R.B.

    Issues / TODOs
    --------------
*/
public without sharing class EQT_InvestranCommitmentHandler implements EQT_ITrigger {
	
	// BUG: Add back in lists of investors and partnerships to be mapped by end user
	/*private List<EQT_Fund_Commitment__c> fundCommitmentsToInsert = new List<EQT_Fund_Commitment__c>();
	private List<EQT_Investor_LP_Code__c> investorLPCodeToInsert = new List<EQT_Investor_LP_Code__c>();
	private List<EQT_Fund_Partnership__c> fundPartnershipsToInsert = new List<EQT_Fund_Partnership__c>();
	//set of uniques entities - used to check if fund partnerships for those ids already exists
	private Set<String> partnershipLegalEntityIds = new Set<String>();
	//set of unique investor lp codes- used to check if Investor lp code for those codes already exists
	private Set<String> investorLPCodes = new Set<String>();
	//fund partnership map - for later Fund commitments creation. Investran Legal Entity Id -> fund partnership record
	private Map<String, EQT_Fund_Partnership__c> fundPartnershipMap = new Map<String, EQT_Fund_Partnership__c>();
	//set of Partnership Legal Entities in currnet context
	private Set<String> partnershipLegalEntitiesInContext = new Set<String>();
	//fund commitment map for later use, LegalEntityId:FundId -> Fund Commitment
	private Map<String, EQT_Fund_Commitment__c> fundCommitmentMap = new Map<String, EQT_Fund_Commitment__c>();
*/

	// commitments by fund partnership
	private Map<String, EQT_Investran_Commitment__c> commitmentsByfundPartnership = new Map<String, EQT_Investran_Commitment__c>();
	private Map<String,EQT_Investor_LP_Code__c> investorsByLPCode = new Map<String,EQT_Investor_LP_Code__c>();
	private Map<String,EQT_Fund_Partnership__c> fundsByLegalEntity = new Map<String,EQT_Fund_Partnership__c>();
	private List<EQT_Fund_Commitment__c> fundCommitmentsToUpsert = new List<EQT_Fund_Commitment__c>();
	private Map<String, EQT_Fund_Partnership__c> fundPartnershipsToUpsert = new Map<String, EQT_Fund_Partnership__c>();
	private List<EQT_Investor_LP_Code__c> investorLPCodeToUpsert = new List<EQT_Investor_LP_Code__c>();
	private String ORIGIN_INVESTRAN = 'Investran';
	private static String PROCESS = 'Investran_Import_Process';
	private static String EX_ID = EQT_UtilApexLog.getProcessExecutionId(PROCESS);
	private Boolean loggingActive = (EX_ID != null);
	private Set<String> logMessages = new Set<String>();

	public EQT_InvestranCommitmentHandler() {}

	public void bulkBefore() {}
    
    public void bulkAfter() {
    	if(Trigger.isInsert) {

			/*for(SObject so : Trigger.new) {
				if(so.get('EQT_Partnership_Legal_Entity__c') != null) {
					partnershipLegalEntitiesInContext.add((String)so.get('EQT_Partnership_Legal_Entity__c'));
				}
			}

			//get all investran partnership legal entity ids for already exising Fund Partnership records to avoid duplicates
			for(EQT_Fund_Partnership__c fp : [SELECT Id, Name, Partnership_Name__c, EQT_Investran_Partnership_Legal_EntityID__c, EQT_Fund__c
												FROM EQT_Fund_Partnership__c]) {

				partnershipLegalEntityIds.add(fp.EQT_Investran_Partnership_Legal_EntityID__c);

				//build map for later process
				fundPartnershipMap.put(fp.EQT_Investran_Partnership_Legal_EntityID__c, fp);
			}

			//get all investor lp codes for already existing Investor LP Code records to avoid duplicates
			for(EQT_Investor_LP_Code__c invLPCode : [SELECT Id, Name FROM EQT_Investor_LP_Code__c]) {
				investorLPCodes.add(invLPCode.Name);
			}

			//get fund commitments for partnership legal entity
			for(EQT_Fund_Commitment__c fc : [SELECT Id, EQT_Fund__c, EQTInvestran_Partnership_Legal_Entity_ID__c
												FROM EQT_Fund_Commitment__c
												WHERE EQTInvestran_Partnership_Legal_Entity_ID__c IN :partnershipLegalEntitiesInContext]) {
				
				if(fc.EQT_Fund__c != null) {
					fundCommitmentMap.put(fc.EQTInvestran_Partnership_Legal_Entity_ID__c + ':' + fc.EQT_Fund__c, fc);
				}
			}*/

    		fundCommitmentsToUpsert = new List<EQT_Fund_Commitment__c>(); // The fund commitments to upsert when done
    		investorsByLPCode = new Map<String,EQT_Investor_LP_Code__c>(); // Investors mapped to LP Code 
    		fundsByLegalEntity = new Map<String,EQT_Fund_Partnership__c>(); // Funds mapped to legal entity id's ("Partnerships")

    		// Get those commitments from investran that have a mapping to partnership
			Set<String> lpCodes = new Set<String>();
			for(SObject so : Trigger.new) {
				if(so.get('Commitment_LP_Code_Investor_Reference__c') != null && so.get('EQT_Partnership_Legal_Entity__c') != null) {
					commitmentsByfundPartnership.put((String)so.get('EQT_Partnership_Legal_Entity__c'), (EQT_Investran_Commitment__c)so);
					lpCodes.add((String)so.get('Commitment_LP_Code_Investor_Reference__c'));
				}
			}

			// get those LP codes that match the investor (some may not be mapped yet)
			for(EQT_Investor_LP_Code__c lpCode : [SELECT Id, Name, EQT_Investor__c, EQT_Vehicle_Name__c
													FROM EQT_Investor_LP_Code__c
													WHERE Name IN :lpCodes]) {
				
				investorsByLPCode.put(lpCode.Name.toUpperCase(), lpCode);
			}
			// get those partnerhsips (legel enetity id's) that are mapped to these partnerships
			for(EQT_Fund_Partnership__c partnership : [SELECT Id, EQT_Fund__c, EQT_Investran_Partnership_Legal_EntityID__c
														FROM EQT_Fund_Partnership__c
														WHERE EQT_Investran_Partnership_Legal_EntityID__c IN :commitmentsByfundPartnership.keySet()]) {

				fundsByLegalEntity.put(partnership.EQT_Investran_Partnership_Legal_EntityID__c, partnership);
			}

			System.debug(LoggingLevel.INFO,'@@ lpCodes: '+lpCodes);
			System.debug(LoggingLevel.INFO,'@@ investorsByLPCode: '+investorsByLPCode);
			System.debug(LoggingLevel.INFO,'@@ fundsByLegalEntity: '+fundsByLegalEntity);
			System.debug(LoggingLevel.INFO,'@@ commitmentsByfundPartnership.size: '+commitmentsByfundPartnership.size());
			System.debug(LoggingLevel.INFO,'@@ commitmentsByfundPartnership: '+commitmentsByfundPartnership);
		}
    }
        
    public void beforeInsert(SObject so) {}
    
    public void beforeUpdate(SObject oldSo, SObject so) {}
    
    public void beforeDelete(SObject so) {}
    
    public void afterInsert(SObject so) {
    	/*
    	EQT_Investran_Commitment__c investranCommitment = (EQT_Investran_Commitment__c)so;

    	//if partnership legal entity is set
    	if(investranCommitment.EQT_Partnership_Legal_Entity__c != null) {
    		//if there is no fund partnership record for given entity
    		if(!partnershipLegalEntityIds.contains(investranCommitment.EQT_Partnership_Legal_Entity__c)) {
    			//create new fund partnership record
    			fundPartnershipsToInsert.add(new EQT_Fund_Partnership__c
	    			(
	    				EQT_Investran_Partnership_Legal_EntityID__c = investranCommitment.EQT_Partnership_Legal_Entity__c,
	    				Partnership_Name__c = investranCommitment.EQT_Partnership_Legal_Entity_Name__c.length() > 80 ? investranCommitment.EQT_Partnership_Legal_Entity_Name__c.substring(0,80) : investranCommitment.EQT_Partnership_Legal_Entity_Name__c
	    			)
	    		);
    		}
    		//if for such legal entity fund partnership record exists and is mapped
    		else if(partnershipLegalEntityIds.contains(investranCommitment.EQT_Partnership_Legal_Entity__c)
    			&& fundPartnershipMap.get(investranCommitment.EQT_Partnership_Legal_Entity__c).EQT_Fund__c != null) {
	    		//create Fund Commitment record (if does not exists)
	    		String mapKey = investranCommitment.EQT_Partnership_Legal_Entity__c + ':' + fundPartnershipMap.get(investranCommitment.EQT_Partnership_Legal_Entity__c).EQT_Fund__c;

	    		if(!fundCommitmentMap.containsKey(mapKey)) {
	    			//create new fund commitment record
	    			
	    			fundCommitmentsToInsert.add(new EQT_Fund_Commitment__c
	    				(
	    					EQT_Amount__c = investranCommitment.EQT_Amount_Total_Commitment__c,
	    					EQT_Fund__c = fundPartnershipMap.get(investranCommitment.EQT_Partnership_Legal_Entity__c).EQT_Fund__c,
	    					EQT_Investran_Invester_ID__c = investranCommitment.EQT_Commitment_Investran_ID_Invester_ID__c,
	    					EQTInvestran_Partnership_Legal_Entity_ID__c = investranCommitment.EQT_Partnership_Legal_Entity__c,
	    					EQT_LP_Code__c = investranCommitment.Commitment_LP_Code_Investor_Reference__c,
	    					EQT_Partnership_Name__c = investranCommitment.EQT_Partnership_Legal_Entity_Name__c,
	    					EQT_Vehicle_Name__c = investranCommitment.EQT_Vehicle_Name_Investor__c,
	    					EQT_Vehicle_Organization_ID__c = investranCommitment.EQT_Vehicle_ID_Organization_ID__c,
	    					EQT_Origin__c = ORIGIN_INVESTRAN
	    				)
	    			);
	    			
	    		}

	    	}
    	}
    	//if LP Code is set
    	if(investranCommitment.Commitment_LP_Code_Investor_Reference__c != null) {
	    	//check if for current lp code Investor LP Code record already exists - if not create it
	    	if(!investorLPCodes.contains(investranCommitment.Commitment_LP_Code_Investor_Reference__c)) {
	    		investorLPCodeToInsert.add(new EQT_Investor_LP_Code__c
	    			(
	    				Name = investranCommitment.Commitment_LP_Code_Investor_Reference__c,
	    				EQT_Vehicle_Name__c = investranCommitment.EQT_Vehicle_Name_Investor__c
	    			)
	    		);
	    	}
	    }
	    EQTInvestran_Partnership_Legal_Entity_ID__c,EQT_Amount__c,EQT_Fund__c,EQT_Investor__c,EQT_Investran_Invester_ID__c,EQT_LP_Code__c,EQT_Partnership_Name__c,EQT_Vehicle_Name__c,EQT_Vehicle_Organization_ID__c FROM EQT_Fund_Commitment__c

	    */

	    // Create a new Fund commitment record for each commitment row (grouped by LP code)
    	EQT_Investran_Commitment__c investranCommitment = (EQT_Investran_Commitment__c)so;
		//System.debug(LoggingLevel.INFO,'@@ investranCommitment: '+investranCommitment);
		String lpCode;
		if(investranCommitment.Commitment_LP_Code_Investor_Reference__c != null)
			lpCode = investranCommitment.Commitment_LP_Code_Investor_Reference__c.toUpperCase();
	    if(investranCommitment.EQT_Partnership_Legal_Entity__c != null)
		    if(fundsByLegalEntity.containsKey(investranCommitment.EQT_Partnership_Legal_Entity__c)) {
		    	
		    	if(fundsByLegalEntity.get(investranCommitment.EQT_Partnership_Legal_Entity__c).EQT_Fund__c != null) {
			    	EQT_Fund_Commitment__c fundCommitment = new EQT_Fund_Commitment__c();

					fundCommitment.EQT_Amount__c = investranCommitment.EQT_Amount_Total_Commitment__c;
					fundCommitment.EQT_Fund__c = fundsByLegalEntity.get(investranCommitment.EQT_Partnership_Legal_Entity__c).EQT_Fund__c;
					//fundCommitment..EQT_Investran_Invester_ID__c = investranCommitment.EQT_Commitment_Investran_ID_Invester_ID__c,
					fundCommitment.EQTInvestran_Partnership_Legal_Entity_ID__c = investranCommitment.EQT_Partnership_Legal_Entity__c;
					fundCommitment.EQT_LP_Code__c = lpCode;
					fundCommitment.EQT_Partnership_Name__c = investranCommitment.EQT_Partnership_Legal_Entity_Name__c;
					fundCommitment.EQT_Vehicle_Name__c = investranCommitment.EQT_Vehicle_Name_Investor__c;
				    fundCommitment.EQT_Origin__c = ORIGIN_INVESTRAN;
					//fundCommitment..EQT_Vehicle_Organization_ID__c = investranCommitment.EQT_Vehicle_ID_Organization_ID__c
					
			    	if (investorsByLPCode.containsKey(lpCode))
			    	{
			    		fundCommitment.EQT_Investor__c = investorsByLPCode.get(lpCode).EQT_Investor__c; 
						System.debug(LoggingLevel.INFO,'@@ fundCommitment: mapped investor investorsByLPCode: '+fundCommitment.EQT_Investor__c);
			    	}

					System.debug(LoggingLevel.INFO,'@@ fundCommitment: '+fundCommitment);
					fundCommitmentsToUpsert.add(fundCommitment);
				}else{
					logMessages.add('Unmapped Legal Entity '+investranCommitment.EQT_Partnership_Legal_Entity__c + ': "' + investranCommitment.EQT_Partnership_Legal_Entity_Name__c + '". Commitment by ' + (String.isBlank(investranCommitment.EQT_Vehicle_Name_Investor__c)?'[Unknown]':investranCommitment.EQT_Vehicle_Name_Investor__c) + ' could not be registered.');
				}
		    }
		    else {//if there is no fund partnership record for given entity	    	
	    		//if(!fundsByLegalEntity.containsKey(investranCommitment.EQT_Partnership_Legal_Entity__c)) {
	    			//create new fund partnership record
	    			fundPartnershipsToUpsert.put(investranCommitment.EQT_Partnership_Legal_Entity__c, new EQT_Fund_Partnership__c
		    			(
		    				EQT_Investran_Partnership_Legal_EntityID__c = investranCommitment.EQT_Partnership_Legal_Entity__c,
		    				Partnership_Name__c = investranCommitment.EQT_Partnership_Legal_Entity_Name__c.length() > 80 ? investranCommitment.EQT_Partnership_Legal_Entity_Name__c.substring(0,80) : investranCommitment.EQT_Partnership_Legal_Entity_Name__c
		    			)
		    		);
		    		logMessages.add('New Partnership Legal Entity '+investranCommitment.EQT_Partnership_Legal_Entity__c + ': "' + investranCommitment.EQT_Partnership_Legal_Entity_Name__c + '" needs to be mapped to a Fund');
	    		//}
		    }

	    //if LP Code is set
    	if(lpCode != null) {
	    	//check if for current lp code Investor LP Code record already exists - if not create it
	    	if(!investorsByLPCode.containsKey(lpCode)) {
	    		EQT_Investor_LP_Code__c lp = new EQT_Investor_LP_Code__c
	    			(
	    				Name = lpCode,
	    				EQT_Vehicle_Name__c = investranCommitment.EQT_Vehicle_Name_Investor__c
	    			);
	    		investorLPCodeToUpsert.add(lp);
	    		investorsByLPCode.put(lpCode,lp);
	    		logMessages.add('New LP Code/Vehicle Name '+lpCode + ': "' + investranCommitment.EQT_Vehicle_Name_Investor__c + '" needs to be mapped to an Investor.');
	    	} else {
	    		EQT_Investor_LP_Code__c existingLPCode = investorsByLPCode.get(lpCode);
			    if(!existingLPCode.EQT_Vehicle_Name__c.equals(investranCommitment.EQT_Vehicle_Name_Investor__c)){
			    	existingLPCode.EQT_Vehicle_Name__c = investranCommitment.EQT_Vehicle_Name_Investor__c;
				    investorLPCodeToUpsert.add(existingLPCode);
				    logMessages.add('LP Code '+lpCode + ' had its vehicle name updated to: "' + investranCommitment.EQT_Vehicle_Name_Investor__c + '".');
			    }
		    }
	    }
    }
    
    public void afterUpdate(SObject oldSo, SObject so) {}
    
    public void afterDelete(SObject so) {}
    
    /**
     * andFinally
     *
     * This method is called once all records have been processed by the trigger. Use this 
     * method to accomplish any final operations such as creation or updates of other records.
     */
    public void andFinally() {
    	List<EQT_UtilApexLog.Log> logsToSave = new List<EQT_UtilApexLog.Log>();
    	if(!logMessages.isEmpty()){
	    	String triggerType = (Trigger.isBefore?'Before':'After')+(Trigger.isInsert?'Insert':(Trigger.isUpdate?'Update':'(Un)Delete'));
	    	logsToSave.add(new EQT_UtilApexLog.Warning(
				   PROCESS, EX_ID, 'EQT_InvestranCommitmentHandler', 'Trigger '+triggerType,
				   String.join(new List<String>(logMessages),'\n')));
	    }

		if(!fundCommitmentsToUpsert.isEmpty()) {
			List<String> upsertErrorMessages = new List<String>();
			System.debug(LoggingLevel.INFO,'@@ fundCommitmentsToUpsert.size: '+fundCommitmentsToUpsert.size());
			System.debug(LoggingLevel.INFO,'@@ fundCommitmentsToUpsert: '+fundCommitmentsToUpsert);
			Schema.SObjectField f = EQT_Fund_Commitment__c.Fields.EQT_LP_Code__c;
			Database.UpsertResult [] cr = Database.upsert(fundCommitmentsToUpsert, f, false);

			for(Database.UpsertResult ur : cr) {
				if(!ur.isSuccess()) {
					System.debug(LoggingLevel.INFO,'@@ fundCommitmentsToUpsert error: '+ur.getErrors());
					String[] errors = new List<String>();
					for(Database.Error e : ur.getErrors())
						errors.add(e.getStatusCode()+': '+e.getMessage());
					upsertErrorMessages.add(String.join(errors,'\n'));
				}
			}
			if(!upsertErrorMessages.isEmpty()){
				logsToSave.add(new EQT_UtilApexLog.Error(
						   PROCESS, EX_ID, 'EQT_InvestranCommitmentHandler', 'FundCommitments Upsert',
						   String.join(upsertErrorMessages,'\n')));
			}
		}

    	if(!investorLPCodeToUpsert.isEmpty()) {
			List<String> upsertErrorMessages = new List<String>();
			Schema.SObjectField f = EQT_Investor_LP_Code__c.Fields.Name;
			Database.UpsertResult [] cr = Database.upsert(investorLPCodeToUpsert, f, false);

			for(Database.UpsertResult ur : cr) {
				if(!ur.isSuccess()) {
					System.debug(LoggingLevel.INFO,'@@ investorLPCodeToUpsert error: '+ur.getErrors());
					String[] errors = new List<String>();
					for(Database.Error e : ur.getErrors())
						errors.add(e.getStatusCode()+': '+e.getMessage());
					upsertErrorMessages.add(String.join(errors,'\n'));
				}
			}
			if(!upsertErrorMessages.isEmpty()){
				logsToSave.add(new EQT_UtilApexLog.Error(
						   PROCESS, EX_ID, 'EQT_InvestranCommitmentHandler', 'InvestorLPCode Upsert',
						   String.join(upsertErrorMessages,'\n')));
			}
		}

    	if(!fundPartnershipsToUpsert.isEmpty()) {
    		List<String> upsertErrorMessages = new List<String>();
			Schema.SObjectField f = EQT_Fund_Partnership__c.Fields.EQT_Investran_Partnership_Legal_EntityID__c;
			Database.UpsertResult [] cr = Database.upsert(fundPartnershipsToUpsert.values(), f, false);

			for(Database.UpsertResult ur : cr) {
				if(!ur.isSuccess()) {
					System.debug(LoggingLevel.INFO,'@@ fundPartnershipsToUpsert error: '+ur.getErrors());
					String[] errors = new List<String>();
					for(Database.Error e : ur.getErrors())
						errors.add(e.getStatusCode()+': '+e.getMessage());
					upsertErrorMessages.add(String.join(errors,'\n'));
				}
			}
			if(!upsertErrorMessages.isEmpty()){
				logsToSave.add(new EQT_UtilApexLog.Error(
						   PROCESS, EX_ID, 'EQT_InvestranCommitmentHandler', 'FundPartnershipLE Upsert',
						   String.join(upsertErrorMessages,'\n')));
			}
		}
		if(loggingActive && !logsToSave.isEmpty())
			EQT_UtilApexLog.saveLog(logsToSave);
    }

}