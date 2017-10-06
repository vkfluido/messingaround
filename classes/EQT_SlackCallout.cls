/**
    About
    -----
    Description: Handle logic for Slack callouts
    Created for: EQT
    Create date: May 2016
    
    Details / Methods
    -----------------
    	- checkIfChannelExists // checks if channel exists in Slack based on it's name
    	- inviteUserToChannel  // invite users to given channel (and) if needed remove non salesforce users
    						   // from this channel except integration user and Iris bot
   
    Update History
    --------------
    Created May 2016 - R.B.
    Updated July 2017 - R.B.

    Issues / TODOs
    --------------
*/
public with sharing class EQT_SlackCallout {

	private static String irisBotId;

	public class SlackException extends Exception {}

	public class SlackResponse {
		public Boolean isSuccess {get;set;}
		public String errorMessage {get;set;}
		public String channelId {get;set;}
		public Map<String, String> channelMap {get;set;}
		public String slackDomainName {get;set;}

		public EQT_SlackCallout.SlackResponse() {
			channelMap = new Map<String, String>();
		}
	}

	public static String checkIfChannelExists(String channelName) {
		String channelId = '';
		//get map of all private channels from slack name->id
		Map<String, String> availablePrivateGroups = getPrivateGroupList();

		if(availablePrivateGroups.containsKey(channelName)) {
			channelId = availablePrivateGroups.get(channelName);
		}

		return channelId;
	}

	public static void inviteUserToChannel(String fundId, String channelId, Boolean shouldDeleteNonSalesforceUsers) {
		String slackIntegrationUserId;
		Map<String, String> slackUserMap;
		Set<String> usersAlreadyInChannel;

		if(Test.isRunningTest()) {
			slackIntegrationUserId = '123';
			slackUserMap = new Map<String, String>();
			slackUserMap.put('321', 't@t.com');

			usersAlreadyInChannel = new Set<String>();
			usersAlreadyInChannel.add('444');
		}
		else {
			//get integration user ID - this is needed to avoid self kicking from group
			slackIntegrationUserId = getIntegrationUserId();
			//get available users from Slack (slack user Id -> user email)
			slackUserMap = getAvailableUserFromSlack();
			//get channel member ids
			usersAlreadyInChannel = getChannelMembers(channelId);
		}

		//get user from Fundraising Team Member
		Set<String> userEmailList = new Set<String>();
		for(EQT_Team_Member_Association__c tma : [SELECT Id, User__r.Email FROM EQT_Team_Member_Association__c
		WHERE EQT_Fund__c = :fundId]) {
			userEmailList.add(tma.User__r.Email);
		}


		//delete non salesforce users from given channel
		if(shouldDeleteNonSalesforceUsers) {
			for(String slackUserId : usersAlreadyInChannel) {
				String userEmail = slackUserMap.get(slackUserId);

				if(!userEmailList.contains(userEmail)) {
					//delete from group if not integration user
					if(slackUserId != slackIntegrationUserId && slackUserId != irisBotId) {
						if(!Test.isRunningTest()) {
							kickUserFromGroup(slackUserId, channelId);
						}
					}
				}
			}
		}

		//if there are some users to add to private channel and there are users in Slack
		if(!userEmailList.isEmpty() && !slackUserMap.isEmpty()) {
			//adding users
			for(String userEmail : userEmailList) {

				String slackUserId = getSlackUserId(userEmail, slackUserMap);

				if(String.isNotEmpty(slackUserId)) {
					//check if this user is not already added to private group; if not add it
					if(!usersAlreadyInChannel.contains(slackUserId)) {
						if(!Test.isRunningTest()) {
							inviteUserToGroup(slackUserId, channelId);
						}
					}
				}
			}

			//check if Iris bot is in group - if not invite it
			if(!usersAlreadyInChannel.contains(irisBotId)) {
				if(!Test.isRunningTest()) {
					inviteUserToGroup(irisBotId, channelId);
				}
			}
		}
	}

	/*
	@future(callout=true)
	public static void postMessageToSlack(String contactEmail, String message) {
		String slackUserId = '';
		Map<String, String>	slackUserMap = new Map<String, String>();
		//first check if given email is assign to some user in Slack
		//get available users from Slack (slack user Id -> user email)
		if(!Test.isRunningTest()) {
			slackUserMap = getAvailableUserFromSlack();
		}
		else {
			slackUserMap.put('123', 'test@test.test');
		}

		if(!slackUserMap.isEmpty()) {
			for(String key : slackUserMap.keySet()) {
				//if user in slack is found for given email
				if(contactEmail.equalsIgnoreCase(slackUserMap.get(key))) {
					slackUserId = key;
					break;
				}
			}
		}

		system.debug(LoggingLevel.INFO,'Radek contactEmail=' + contactEmail);
		system.debug(LoggingLevel.INFO,'Radek slackUserId=' + slackUserId);

		if(String.isNotEmpty(slackUserId)) {

			//get IM channel for given user id
			//String imToPost = getIMChannelId(slackUserId);

			String slackToken = EQT_UTIL_Settings.getSlackIntegrationUserToken();

			system.debug(LoggingLevel.INFO,'Radek slackToken=' + slackToken);

			//open im channel for given user
			String imToPost = openIMChannel(slackUserId);
			system.debug(LoggingLevel.INFO, 'Radek imToPost=' + imToPost);
			//post message to this channel

			Map<String, String> params = new Map<String, String>();
			params.put('channel', imToPost);
			params.put('text', EncodingUtil.urlEncode(message,'UTF-8'));
			params.put('username', '@stefan');
			params.put('as_user', 'false');

			HttpRequest request = new HttpRequest();
			request.setEndpoint('https://slack.com/api/chat.postMessage');
			request.setMethod('POST');

			String body = 'token=' + slackToken + '&pretty=1';

			if(params != null && !params.isEmpty()) {
			    for(String key : params.keySet()) {
			        body += '&' + key + '=' + params.get(key);
			    }
			}

			request.setBody(body);
			system.debug(LoggingLevel.INFO,'Radek body=' + body);

			Http http = new Http();

			try {
				HttpResponse response = http.send(request);
			}
			catch(Exception e) {
				EQT_UtilApexLog.generateLog('EQT_SlackCallout: Request to post message could not be sent from Salesforce:', e.getMessage());
			}

			//close im channel
			closeIMChannel(imToPost);
		}
	}

	//@testVisible
	public static String getIMChannelId(String slackUserId) {
		String imChannelId = '';

		HttpRequest request = buildRequest('im.list', null);

		Http http = new Http();

		try {
			HttpResponse response = http.send(request);

			if(response.getStatusCode() == 200) {
				Map<String, Object> results = (Map<String, Object>)JSON.deserializeUntyped(response.getBody());

				if(!results.containsKey('error')) {
					List<Object> imList = (List<Object>)results.get('ims');
					for (Object im : imList) {
						//get members attributes
					    Map<String, Object> imAttributes = (Map<String, Object>)im;

					    if(String.valueOf(imAttributes.get('user')) == slackUserId) {
					    	imChannelId = String.valueOf(imAttributes.get('id'));
					    	break;
					    }
					}
				}
			}
		}
		catch(Exception e) {}

		return imChannelId;
	}

	public static String openIMChannel(String slackUserId) {
		Map<String, String> params = new Map<String, String>();
		params.put('user', slackUserId);

		HttpRequest request = buildRequest('im.open', params);
		Http http = new Http();

		try {
			HttpResponse response = http.send(request);

			if(response.getStatusCode() == 200) {
				Map<String, Object> results = (Map<String, Object>)JSON.deserializeUntyped(response.getBody());

				if(!results.containsKey('error')) {
					system.debug(LoggingLevel.INFO, 'Radek results channel=' + results.get('channel'));
					Object channel = (Object)results.get('channel');
					Map<String, Object> channelAttributes = (Map<String, Object>)channel;
					//system.debug(LoggingLevel.INFO, 'Radek results channel id=' + channel.keySet());
					//system.debug(LoggingLevel.INFO, 'Radek results channel id=' + channel.values());
					return String.valueOf(channelAttributes.get('id'));
				}
			}
		}
		catch(Exception e) {}

		return '';
	}

	public static void closeIMChannel(String channelId) {
		Map<String, String> params = new Map<String, String>();
		params.put('channel', channelId);

		HttpRequest request = buildRequest('im.close', params);
		Http http = new Http();

		try {
			HttpResponse response = http.send(request);
		}
		catch(Exception e) {}
	}
*/
	public static String getSlackUserId(String userEmail, Map<String, String> slackUserMap) {
		String slackUserId = '';
		for(String userId : slackUserMap.keySet()) {
			if(slackUserMap.get(userId) != null && slackUserMap.get(userId).equalsIgnoreCase(userEmail)) {
				slackUserId = userId;
				break;
			}
		}

		return slackUserId;
	}

	private static HttpRequest buildRequest(String methodName, Map<String, String> params) {
		//check for configuration
		String slackEndpointURL = EQT_UTIL_Settings.getSlackEndpointURL();
		String slackToken = EQT_UTIL_Settings.getSlackIntegrationUserToken();

		if(String.isEmpty(slackEndpointURL) || String.isEmpty(slackToken)) {
			throw new SlackException('Configuration was not found.');
		}

		if(!slackEndpointURL.endsWith('/')) {
			slackEndpointURL += '/';
		}

		HttpRequest request = new HttpRequest();
		request.setEndpoint(slackEndpointURL +  methodName);
		request.setMethod('GET');

		String body = 'token=' + slackToken + '&pretty=1';

		if(params != null && !params.isEmpty()) {
			for(String key : params.keySet()) {
				body += '&' + key + '=' + params.get(key);
			}
		}

		request.setBody(body);

		return request;
	}

	@testVisible
	private static Map<String, String> getPrivateGroupList() {
		Map<String, String> channelList = new Map<String, String>();

		HttpRequest request = buildRequest('groups.list', null);

		Http http = new Http();

		try {
			HttpResponse response = http.send(request);

			if(response.getStatusCode() == 200) {
				Map<String, Object> results = (Map<String, Object>)JSON.deserializeUntyped(response.getBody());

				if(results.containsKey('error')) {
					throw new SlackException('EQT_SlackCallout response error message: ' + (String)results.get('error'));
				}

				List<Object> channels = (List<Object>)results.get('groups');
				for (Object channel : channels) {
					Map<String, Object> channelAttributes = (Map<String, Object>)channel;

					channelList.put((String)channelAttributes.get('name'), (String)channelAttributes.get('id'));
				}
			}
			else {
				throw new SlackException(String.valueOf(response.getStatusCode()) + ': ' + response.getStatus());
			}
		}
		catch(Exception e) {
			throw new SlackException('EQT_SlackCallout: Request to get private group list could not be sent from Salesforce: ' + e.getMessage());
		}

		return channelList;
	}

	public static Map<String, String> getAvailableUserFromSlack() {
		//slack user Id -> user email
		Map<String, String> userMap = new Map<String, String>();

		HttpRequest request = buildRequest('users.list', null);

		Http http = new Http();

		try {
			HttpResponse response = http.send(request);

			if(response.getStatusCode() == 200) {
				Map<String, Object> results = (Map<String, Object>)JSON.deserializeUntyped(response.getBody());

				if(results.containsKey('error')) {
					throw new SlackException('EQT_SlackCallout response error message: ' + (String)results.get('error'));
				}

				List<Object> memberList = (List<Object>)results.get('members');
				for (Object member : memberList) {
					//get members attributes
					Map<String, Object> memberAttributes = (Map<String, Object>)member;
					//get profile attributes
					Map<String, Object> profileInfo = (Map<String, Object>) memberAttributes.get('profile');

					//exclude deleted users
					Boolean isDeleted = (Boolean)memberAttributes.get('deleted');
					if(!isDeleted) {
						//exclude bots from user list
						Boolean isBot = (Boolean)memberAttributes.get('is_bot');
						if(!isBot) {
							userMap.put((String)memberAttributes.get('id'), (String)profileInfo.get('email'));
						}

						//get iris bot user id
						if(isBot) {
							String botName = (String)memberAttributes.get('name');
							if(botName.equalsIgnoreCase(EQT_UTIL_Settings.getIrisBotName())) {
								irisBotId = (String)memberAttributes.get('id');
							}
						}
					}
				}
			}
			else {
				throw new SlackException(String.valueOf(response.getStatusCode()) + ': ' + response.getStatus());
			}
		}
		catch(Exception e) {
			throw new SlackException('EQT_SlackCallout: Request to get available users could not be sent from Salesforce: ' + e.getMessage());
		}

		return userMap;
	}

	@testVisible
	private static Set<String> getChannelMembers(String channelId) {
		Set<String> userList = new Set<String>();

		Map<String, String> params = new Map<String, String>();
		params.put('channel', channelId);

		HttpRequest request = buildRequest('groups.info', params);

		Http http = new Http();

		try {
			HttpResponse response = http.send(request);

			if(response.getStatusCode() == 200) {
				Map<String, Object> results = (Map<String, Object>)JSON.deserializeUntyped(response.getBody());

				if(results.containsKey('error')) {
					throw new SlackException('EQT_SlackCallout response error message: ' + (String)results.get('error'));
				}

				Map<String, Object> groupInfo = (Map<String, Object>)results.get('group');
				List<Object> memberList = (List<Object>)groupInfo.get('members');
				for(Object member : memberList) {
					userList.add((String)member);
				}
			}
			else {
				throw new SlackException(String.valueOf(response.getStatusCode()) + ': ' + response.getStatus());
			}
		}
		catch(Exception e) {
			throw new SlackException('EQT_SlackCallout: Request to get channel members could not be sent from Salesforce: ' + e.getMessage());
		}

		return userList;
	}

	@testVisible
	private static void kickUserFromGroup(String slackUserId, String slackGroupId) {
		Map<String, String> params = new Map<String, String>();
		params.put('channel', slackGroupId);
		params.put('user', slackUserId);

		HttpRequest request = buildRequest('groups.kick', params);

		Http http = new Http();

		try {
			HttpResponse response = http.send(request);

			if(response.getStatusCode() == 200) {
				Map<String, Object> results = (Map<String, Object>)JSON.deserializeUntyped(response.getBody());

				if(results.containsKey('error')) {
					throw new SlackException('EQT_SlackCallout response error message: ' + (String)results.get('error'));
				}
			}
			else {
				throw new SlackException(String.valueOf(response.getStatusCode()) + ': ' + response.getStatus());
			}
		}
		catch(Exception e) {
			throw new SlackException('EQT_SlackCallout: Request to delete user from channel could not be sent from Salesforce: ' + e.getMessage());
		}
	}

	@testVisible
	private static void inviteUserToGroup(String slackUserId, String slackGroupId) {
		Map<String, String> params = new Map<String, String>();
		params.put('channel', slackGroupId);
		params.put('user', slackUserId);

		HttpRequest request = buildRequest('groups.invite', params);

		Http http = new Http();

		try {
			HttpResponse response = http.send(request);

			if(response.getStatusCode() == 200) {
				Map<String, Object> results = (Map<String, Object>)JSON.deserializeUntyped(response.getBody());

				if(results.containsKey('error')) {
					throw new SlackException('EQT_SlackCallout response error message: ' + (String)results.get('error'));
				}
			}
			else {
				throw new SlackException(String.valueOf(response.getStatusCode()) + ': ' + response.getStatus());
			}
		}
		catch(Exception e) {
			throw new SlackException('EQT_SlackCallout: Request to invite user to channel could not be sent from Salesforce: ' + e.getMessage());
		}
	}

	@testVisible
	private static String getIntegrationUserId() {
		String integrationUserId = '';

		HttpRequest request = buildRequest('auth.test', null);

		Http http = new Http();

		try {
			HttpResponse response = http.send(request);

			if(response.getStatusCode() == 200) {
				Map<String, Object> results = (Map<String, Object>)JSON.deserializeUntyped(response.getBody());

				if(results.containsKey('error')) {
					throw new SlackException('EQT_SlackCallout response error message: ' + (String)results.get('error'));
				}

				integrationUserId = (String)results.get('user_id');
			}
			else {
				throw new SlackException(String.valueOf(response.getStatusCode()) + ': ' + response.getStatus());
			}
		}
		catch(Exception e) {
			throw new SlackException('EQT_SlackCallout: Request to get available users could not be sent from Salesforce: ' + e.getMessage());
		}

		return integrationUserId;
	}

	public static EQT_SlackTeamID_WS.SlackTeamResult getSlackTeamId() {
		EQT_SlackTeamID_WS.SlackTeamResult result = new EQT_SlackTeamID_WS.SlackTeamResult();

		HttpRequest request = buildRequest('team.info', null);

		Http http = new Http();

		HttpResponse response = http.send(request);

		if(response.getStatusCode() == 200) {
			Map<String, Object> results = (Map<String, Object>)JSON.deserializeUntyped(response.getBody());

			if(results.containsKey('error')) {
				result.message = (String)results.get('error');
			}
			else {
				Map<String, Object> teamInfo = (Map<String, Object>)results.get('team');
				system.debug(LoggingLevel.INFO, 'TeamInfo=' + teamInfo);
				result.teamId = (String)teamInfo.get('id');
			}
		}
		else {
			throw new SlackException(String.valueOf(response.getStatusCode()) + ': ' + response.getStatus());
		}

		return result;
	}

	/*
	* Deal platform slack integration methods SFMAIN-180
	* */

	public static String createSlackChannel(String channelName, Boolean restricted) {
		SlackResponse result = new SlackResponse();

		Map<String, String> params = new Map<String, String>();
		params.put('name', channelName);

		//if opportunity is restricted - create private channel
		HttpRequest request = buildRequest(restricted ? 'groups.create' : 'channels.create', params);

		Http http = new Http();

		try {
			result = handleSlackResponse(http.send(request));
		}
		catch (Exception e) {
			result.isSuccess = false;
			result.errorMessage = 'EQT_SlackCallout: Request to create new channel could not be sent from Salesforce: ' + e.getMessage();
		}

		return JSON.serialize(result);
	}

	public static String inviteUserToChannelDM(String slackUserId, String channelId, Boolean restricted) {
		SlackResponse result = new SlackResponse();

		Map<String, String> params = new Map<String, String>();
		params.put('channel', channelId);
		params.put('user', slackUserId);

		//if opportunity is restricted - invite to private channel
		HttpRequest request = buildRequest(restricted ? 'groups.invite' : 'channels.invite', params);

		Http http = new Http();

		try {
			result = handleSlackResponse(http.send(request));
		}
		catch(Exception e) {
			result.isSuccess = false;
			result.errorMessage = 'EQT_SlackCallout: Request to invite user to channel could not be sent from Salesforce: ' + e.getMessage();
		}

		return JSON.serialize(result);
	}

	public static String removeUserFromChannel(String slackUserId, String channelId, Boolean restricted) {
		SlackResponse result = new SlackResponse();

		Map<String, String> params = new Map<String, String>();
		params.put('channel', channelId);
		params.put('user', slackUserId);

		HttpRequest request = buildRequest(restricted ? 'groups.kick' : 'channels.kick', params);

		Http http = new Http();

		try {
			result = handleSlackResponse(http.send(request));
		}
		catch(Exception e) {
			result.isSuccess = false;
			result.errorMessage = 'EQT_SlackCallout: Request to delete user from channel could not be sent from Salesforce: ' + e.getMessage();
		}

		return JSON.serialize(result);
	}

	public static String postToChannel(String channelId, String message) {
		SlackResponse result = new SlackResponse();

		Map<String, String> params = new Map<String, String>();
		params.put('channel', channelId);
		params.put('text', message);
		params.put('username', 'Notification');

		HttpRequest request = buildRequest('chat.postMessage', params);

		Http http = new Http();

		try {
			result = handleSlackResponse(http.send(request));
		}
		catch(Exception e) {
			result.isSuccess = false;
			result.errorMessage = 'EQT_SlackCallout: Request to post message to channel could not be sent from Salesforce: ' + e.getMessage();
		}

		return JSON.serialize(result);
	}

	public static String renameChannel(String channelId, String channelName, Boolean restricted) {
		SlackResponse result = new SlackResponse();

		Map<String, String> params = new Map<String, String>();
		params.put('channel', channelId);
		params.put('name', channelName);

		HttpRequest request = buildRequest(restricted ? 'groups.rename' : 'channels.rename', params);

		Http http = new Http();

		try {
			result = handleSlackResponse(http.send(request));
		}
		catch(Exception e) {
			result.isSuccess = false;
			result.errorMessage = 'EQT_SlackCallout: Request to rename channel could not be sent from Salesforce: ' + e.getMessage();
		}

		return JSON.serialize(result);
	}

	public static Boolean slackOpportunityChannelExists(String channelId, Boolean restricted) {
		//get map of all private channels from slack id->name
		SlackResponse response = (SlackResponse)JSON.deserializeStrict(getChannelList(restricted), SlackResponse.class);

		if(response.channelMap.containsKey(channelId)) {
			return true;
		}

		return false;
	}

	private static String getChannelList(Boolean restricted) {
		SlackResponse result = new SlackResponse();

		HttpRequest request = buildRequest(restricted ? 'groups.list' : 'channels.list', null);

		Http http = new Http();

		try {
			result = handleSlackResponse(http.send(request));
		}
		catch(Exception e) {
			result.isSuccess = false;
			result.errorMessage = 'EQT_SlackCallout: Request to get channel list could not be sent from Salesforce: ' + e.getMessage();
		}

		return JSON.serialize(result);
	}

	public static String getDomainNameFromSlack() {
		String domainName = '';

		HttpRequest request = buildRequest('team.info', new Map<String, String>());

		Http http = new Http();

		try {
			SlackResponse result = handleSlackResponse(http.send(request));
			if(String.isNotEmpty(result.slackDomainName)) {
				domainName = result.slackDomainName;
			}
		}
		catch(Exception e) {

		}

		return domainName;
	}

	private static SlackResponse handleSlackResponse(HttpResponse response) {
		SlackResponse result = new SlackResponse();

		if(response.getStatusCode() == 200) {
			Map<String, Object> results = (Map<String, Object>)JSON.deserializeUntyped(response.getBody());

			if(results.containsKey('error')) {
				result.isSuccess = false;
				if(results.get('error').equals('name_taken')) {
					result.errorMessage = Label.EQT_SlackChannelCreationError;
				}
				else {
					result.errorMessage = 'EQT_SlackCallout response error message: ' + (String) results.get('error');
				}
			}
			else {
				result.isSuccess = true;
				if(results.containsKey('group') && !results.containsKey('message')) {
					Map<String, Object> channelMap = (Map<String, Object>) results.get('group');
					String channelId = (String)channelMap.get('id');
					system.debug(LoggingLevel.INFO, channelId);
					result.channelId = channelId;
				}
				else if(results.containsKey('groups')) {
					List<Object> channels = (List<Object>)results.get('groups');
					result.channelMap = new Map<String, String>();
					for (Object channel : channels) {
						Map<String, Object> channelAttributes = (Map<String, Object>)channel;

						result.channelMap.put((String)channelAttributes.get('id'), (String)channelAttributes.get('name'));
					}
				}
				else if(results.containsKey('team')) {
					Map<String, Object> teamMap = (Map<String, Object>) results.get('team');
					String domainName = (String)teamMap.get('domain');
					result.slackDomainName = domainName;
				}
				else if(results.containsKey('channel') && !results.containsKey('message')) {
					Map<String, Object> channelMap = (Map<String, Object>) results.get('channel');
					String channelId = (String)channelMap.get('id');
					system.debug(LoggingLevel.INFO, channelId);
					result.channelId = channelId;
				}
				else if(results.containsKey('channels')) {
					List<Object> channels = (List<Object>)results.get('channels');
					result.channelMap = new Map<String, String>();
					for (Object channel : channels) {
						Map<String, Object> channelAttributes = (Map<String, Object>)channel;

						result.channelMap.put((String)channelAttributes.get('id'), (String)channelAttributes.get('name'));
					}
				}
			}
		}
		else {
			result.isSuccess = false;
			result.errorMessage = String.valueOf(response.getStatusCode()) + ': ' + response.getStatus();
		}

		return result;
	}
}