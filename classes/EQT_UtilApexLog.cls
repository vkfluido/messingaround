/**
    About
    -----
    Description: Util class to handle logs
    Created for: EQT POC
    Create date: April 2016
    
    Details / Methods
    -----------------
   
    Update History
    --------------
    Created April 2016 - R.B.
    Updated August 2017 - felix.guerrero@fluidogroup.com    Implemented inner Log (Error,Warning,Info) class and corresponding methods to create and save log details.
    
    Issues / TODOs
**/
global class EQT_UtilApexLog {
    private static Map<String,EQT_ProcessLog__c> processMap = new Map<String,EQT_ProcessLog__c>();
    /*
        A Virtual Class that Defines the Structure of a Log
    */
    public virtual class Log{
        public String Process;
        public String ExecutionId;
        public String Type;
        public String ApexClass;
        public String Method;
        public String Message;
        public Datetime TimeStamp;

        public Log(){}
        public Log(String processName, String executionId, String cls, String routine, String msg){
            this.Process = processName;
            this.ExecutionId = executionId;
            this.ApexClass = cls;
            this.Method = routine;
            this.Message = msg;
            this.TimeStamp = System.now();
        }
        public List<EQT_Event_Log__c> getEvent(){
            List<EQT_Event_Log__c> events = new List<EQT_Event_Log__c>();
            Integer MAX_LENGTH = 32000;
            Integer mLength = Message.length();
            Integer j = (Math.floor( mLength / MAX_LENGTH)).intValue();
            for(Integer i = 0; i <= j; i++){
                Integer istart = i*MAX_LENGTH;
                Integer iend = (i == j?mLength:MAX_LENGTH);
                String m = Message.substring(istart, iend);
                events.add(new EQT_Event_Log__c(
                    ProcessName__c = Process,
                    ExecutionId__c = ExecutionId,
                    Type__c = Type,
                    ApexClass__c = ApexClass,
                    Method__c = Method,
                    EQT_Log_Detail__c = m,
                    TimeStamp__c = TimeStamp.getTime()
                ));
            }
            return events;
        }
    }

    /*
        Classes that Extend the Virtual Class - Log to define a log of type - Error, Warning or Info
    */
    public class Error extends Log{
        public Error(String process, String executionId, String cls, String routine, String msg){
            super(process, executionId, cls, routine, msg);
            this.Type = 'ERROR';
        }
    }
    public class Warning extends Log{
        public Warning(String process, String executionId, String cls, String routine, String msg){
            super(process, executionId, cls, routine, msg);
            this.Type = 'WARNING';
        }
    }
    public class Info extends Log{
        public Info(String process, String executionId, String cls, String routine, String msg){
            super(process, executionId, cls, routine, msg);
            this.Type = 'INFO';
        }
    }

    public static void saveLog(Log logToInsert){
        List<Log> logsToInsert = new List<Log>();
        logsToInsert.add(logToInsert);
        saveLog(logsToInsert);
    }

    public static void saveLog(List<Log> logsToInsert){
        List<EQT_Event_Log__c> apexDebugLogs = new List<EQT_Event_Log__c>();
        for(Log log : logsToInsert)
             apexDebugLogs.addAll(log.getEvent());
        try{
            if(!apexDebugLogs.isEmpty())
                insert apexDebugLogs;
        }catch(DmlException e){
            System.debug('An error has occurred while committing the Log to the database!\nError: ' + e.getMessage());
        }
        //System.debug(apexDebugLogs);
    }

    // Returns execution Id
    public static String startProcessLog(String processName){
        String executionId;
        EQT_ProcessLog__c process = loadProcessSettings(processName);
        System.debug('@startProcessLog: ' + processName + '\n' + process);
        if(process != null && process.IsEnabled__c){
            process.StartDate__c = System.now();
            process.EndDate__c = null;
            for(String s : process.Name.splitByCharacterType()){
                String c = s.left(1);
                if(c.isAlphanumeric())
                    executionId += c.toUpperCase();
            }
            executionId = process.StartDate__c.format('yyyyMMdd.HHmmss.SSS.');
            executionId += String.valueOf(Math.mod(Math.abs(Crypto.getRandomInteger()),1000)).leftPad(3).replace(' ','X'); //Random characters
            process.ExecutionId__c = executionId;
            process.ProcessStatus__c = 'Running';
            try{
                update process;
                System.debug('@EQT_UtilApexLog: Process log initialized.');
                EQT_UtilApexLog.saveLog(
                    new Info(processName, process.ExecutionId__c, 'EQT_UtilApexLog', 'startProcessLog', 'Process "' +processName+ '" started. Log initialized.')
                );
            }catch(Exception e){
                String message = 'Error starting log for Process '+processName+'. Cannot Update Process Log Settings.';
                EQT_UtilApexLog.saveLog(
                    new Error(processName, process.ExecutionId__c, 'EQT_UtilApexLog', 'startProcessLog', message + '\n' + e.getMessage() + '\n' + e.getStackTraceString())
                );
            }
            processMap.put(processName,process);
        }
        return executionId;
    }

    public static void endProcessLog(String processName, Boolean success){
        EQT_ProcessLog__c process = loadProcessSettings(processName);
        System.debug('@endProcessLog for process:'+process.ProcessLabel__c);
        if(process != null && process.IsEnabled__c){
            process.EndDate__c = System.now();
            process.ProcessStatus__c = (success?'Success':'Error');
            try{
                update process;
                System.debug('@EQT_UtilApexLog: Process log finalized.');
                EQT_UtilApexLog.saveLog(
                    new Info(processName, process.ExecutionId__c, 'EQT_UtilApexLog', 'endProcessLog', 'Process ' +processName+ ' ended with status: '+(success?'Success':'Error')+'.')
                );
            }catch(Exception e){
                String message = 'Error closing log for Process '+processName+'. Cannot Update Process Log Settings.';
                EQT_UtilApexLog.saveLog(
                    new Error(processName, process.ExecutionId__c, 'EQT_UtilApexLog', 'endProcessLog', message + '\n' + e.getMessage() + '\n' + e.getStackTraceString())
                );
            }
        }
    }

    // Used by start and end process methods to retrieve the process log settings record.
    private static EQT_ProcessLog__c loadProcessSettings(String processName){
        EQT_ProcessLog__c process;
        if(!processMap.containsKey(processName)){
            process = EQT_ProcessLog__c.getInstance(processName);
            if(process != null){
                    processMap.put(processName,process);        
            }
        }else
            process = processMap.get(processName);
        return process;
    }

    public static String getProcessExecutionId(String processName){
        String executionId;
        EQT_ProcessLog__c process = loadProcessSettings(processName);
        if(process != null && process.ProcessStatus__c.equals('Running')){
            executionId = process.ExecutionId__c;
        }
        return executionId;
    }

    public static void sendProcessLogNotification(String processName, String message){
        EQT_ProcessLog__c process = loadProcessSettings(processName);
        System.debug(process);
        if(process != null){
            if(process.SendEmailNotification__c && String.isNotBlank(process.NotificationRecipient__c)){
                String emailBody = process.ProcessLabel__c + '\n';
                emailBody += 'Process started: ' + process.StartDate__c.format() + '\n';
                emailBody += 'Process ended: ' + process.EndDate__c.format() + '\n';
                emailBody += 'Ended with status: ' + process.ProcessStatus__c + '\n';

                emailBody += message;
                emailBody += '\nLog Error details:';

                List<EQT_Event_Log__c> logs = [SELECT Id, Type__c, EQT_Log_Detail__c FROM EQT_Event_Log__c WHERE ExecutionId__c = :process.ExecutionId__c AND Type__c = 'ERROR' ORDER BY Id];
                if(logs.isEmpty())
                    emailBody += '\nNo errors encountered.';
                else
                    for(EQT_Event_Log__c log : logs){
                        emailBody +=   '\n[' + log.Type__c + '] ' + log.EQT_Log_Detail__c;
                    }
                
                String subject = process.ProcessLabel__c + ' - ' + String.valueOf(System.today());
                System.debug('@sendProcessLogNotification\nSubject: ' + subject + '\n' + emailBody);

                Messaging.SendEmailResult[] sendResults;
                if(!Test.isRunningTest()){
                    try{
                        sendResults = sendEmail(subject,emailBody,new List<String>{process.NotificationRecipient__c});
                    }catch(Exception e){
                        EQT_UtilApexLog.saveLog(
                          new Error(processName, process.ExecutionId__c, 'EQT_UtilApexLog', 'sendProcessLogNotification', 'Error sending notification email.\n' + e.getMessage())
                        );
                    }
                 }
                if(sendResults != null && sendResults.size() > 0){
                    Messaging.SendEmailResult sendResult = sendResults[0];
                    if(!sendResult.isSuccess()){
                        Messaging.SendEmailError[] sendErrors = sendResult.getErrors();
                        EQT_UtilApexLog.saveLog(
                          new Error(processName, process.ExecutionId__c, 'EQT_UtilApexLog', 'sendProcessLogNotification', 'Error sending notification email.\n' + String.valueOf(sendErrors))
                        );
                    }
                }
            }
        }
    }
    /*
    public static void generateLog(Id recordId, Database.Error[] errors) {
        
        String message = 'There were errors for user Id: ' + UserInfo.getUserId();
        for(Database.Error error : errors) {
            message += '\n' + error.getMessage();
        }
        
        if(String.isNotEmpty(message)) {
            EQT_Event_Log__c logToSave = new EQT_Event_Log__c(EQT_Log_Detail__c = message);
            insert logToSave;
        }
        
    }
    */

    public static void setEventLogsToInsert(List<EQT_Event_Log__c> eventLogList, String messageToLog) {
        if(String.isNotEmpty(messageToLog)) {
            eventLogList.add(new EQT_Event_Log__c(EQT_Log_Detail__c = messageToLog));
        }
    }

    public static void insertEventLogList(List<EQT_Event_Log__c> eventLogList) {
        system.debug('Radek inserting log list='+eventLogList);
        if(!eventLogList.isEmpty()) {
            insert eventLogList;
        }
    }
    
    public static void generateLog(String customMessage, String error) {
        String message = customMessage;
        if(String.isNotEmpty(error)) {
            message += '\n' + error;
        }
        
        if(String.isNotEmpty(message)) {
            EQT_Event_Log__c logToSave = new EQT_Event_Log__c(EQT_Log_Detail__c = message);
            insert logToSave;
        }
    }

    public static Messaging.SendEmailResult[] sendEmail(String subject, String body, List<String> emails) {
        // Define the email
        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        // Sets the paramaters of the email
        email.setSubject(subject);
        email.setToAddresses(emails);
        email.setPlainTextBody(body);

        // Sends the email
        Messaging.SendEmailResult[] send;
        if( !Test.isRunningTest() )
            send = Messaging.sendEmail(new Messaging.SingleEmailMessage[] {email});
        else
            System.debug('Email being sent:\n'+email);
        
        return send;
    }
}