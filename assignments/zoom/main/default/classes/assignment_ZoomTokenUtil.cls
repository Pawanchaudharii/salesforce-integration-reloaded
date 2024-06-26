/**
 * @description       : 
 * @author            : Amit Singh - PantherSchools
 * @group             : 
 * @last modified on  : 03-30-2024
 * @last modified by  : Amit Singh - PantherSchools
**/
public with sharing class assignment_ZoomTokenUtil {
    
    public PageReference getAuthCode(){
        /*
            TODO: Get the Custom Metadata Record
        */
        zoom_Metadata__mdt config = zoom_Metadata__mdt.getInstance(System.Label.PS_ZoomTokenLabel); // Use Custom Label
        if(config != null){
            
            String redirect_uri = System.URL.getOrgDomainURL().toExternalForm()+'/apex/'+config.PageName__c;
            System.System.debug( redirect_uri );

            String authorizeUrl = config.auth_url__c+'?client_id='+config.client_id__c
                            +'&redirect_uri='+redirect_uri+'&response_type=code';
            System.System.debug( authorizeUrl );

            return new PageReference(authorizeUrl);
        } else {
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.WARNING, 'Config not found' ));
            return null;
        }
    }

    public void getAccessToken(){
        
        String code = ApexPages.currentPage().getParameters().get('code');
        System.debug(code);
        zoom_Metadata__mdt config = zoom_Metadata__mdt.getInstance(System.Label.PS_ZoomTokenLabel); // Use Custom Label
        if(config != null){

            String tokenUrl = config.token_url__c;
            String redirect_uri = System.URL.getOrgDomainURL().toExternalForm()+'/apex/'+config.PageName__c;
            System.System.debug( redirect_uri );

            String requestBody = 'code='+code+'&grant_type=authorization_code&client_id='
                                +config.client_id__c+'&client_secret='+config.client_secret__c+'&redirect_uri='+redirect_uri;
            
            System.debug(requestBody);

            HttpRequest httpReq = PS_CalloutUtils.prepareRequest(tokenUrl,'POST',requestBody,'application/json', 'application/x-www-form-urlencoded');

            Http http = new Http();
            try{
                HttpResponse httpRes = http.send(httpReq);
                if(httpRes.getStatusCode() == 200){
                    Assignment_ZoomTokenWrapper wrapper = (Assignment_ZoomTokenWrapper)System.JSON.deserialize(httpRes.getBody(), Assignment_ZoomTokenWrapper.class);
                    
                    String fullName = 'zoom_Metadata.'+System.Label.PS_ZoomTokenLabel;
                    String label = System.Label.PS_ZoomTokenLabel;
                    Map<String, Object> fieldWithValuesMap = new Map<String, Object>();
                    fieldWithValuesMap.put('access_token__c', wrapper.access_token);
                    fieldWithValuesMap.put('expires_in__c',wrapper.expires_in);
                    fieldWithValuesMap.put('expires_in_time__c', System.now().addSeconds(wrapper.expires_in) );
                    fieldWithValuesMap.put('refresh_token__c', wrapper.refresh_token);

                    System.debug('SUCCESS \n '+httpRes.getBody());
                    CreateUpdateMetadataUtils.createUpdateMetadata(fullName, label, fieldWithValuesMap);
                    ApexPages.addmessage(new ApexPages.message(ApexPages.severity.CONFIRM,'Successfull!'));
                    // Success
                } else {
                    // 400
                    System.debug('ERROR \n '+ httpRes.getBody());
                    ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR, httpRes.getBody() ));
                    // error
                }
            }catch(System.CalloutException ex){
                ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR, ex.getMessage() ));
            }catch(System.Exception ex){
                ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR, ex.getMessage() ));
            }
        }
    }

    public static Boolean isValid(zoom_Metadata__mdt config){
        Boolean isValid = true;
        if(config.expires_in_time__c < System.now()){
            isValid = false;
        }
        return isValid;
    }

    public static Map<String, Object> refreshToken(zoom_Metadata__mdt config){
        
        String tokenUrl = config.token_url__c;
        
        String requestBody = 'grant_type=refresh_token&client_id='+config.client_id__c
                            +'&client_secret='+config.client_secret__c+'&refresh_token='+config.refresh_token__c;
        
        System.debug(requestBody);
        HttpRequest httpReq = PS_CalloutUtils.prepareRequest(tokenUrl,'POST',requestBody,'application/json', 'application/x-www-form-urlencoded');
        Map<String, Object> fieldWithValuesMap = new Map<String, Object>();
        try{
            HttpResponse httpRes = (new Http()).send(httpReq);
            if(httpRes.getStatusCode() == 200 || httpRes.getStatusCode() == 201 ){
                Assignment_ZoomTokenWrapper wrapper = (Assignment_ZoomTokenWrapper)System.JSON.deserialize(httpRes.getBody(), Assignment_ZoomTokenWrapper.class);
                fieldWithValuesMap.put('access_token__c', wrapper.access_token);
                fieldWithValuesMap.put('expires_in__c',wrapper.expires_in);
                fieldWithValuesMap.put('expires_in_time__c', System.now().addSeconds(wrapper.expires_in) );
                fieldWithValuesMap.put('refresh_token__c', wrapper.refresh_token);
            }else{
                
            }
        }catch(System.CalloutException ex){
            
        }catch(System.Exception ex){
            
        }
        return fieldWithValuesMap;
    }
}