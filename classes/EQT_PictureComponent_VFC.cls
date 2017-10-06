/**
    About
    -----
    Description: Controller for Lightning component to upload picture
    Created for: EQT
    Create date: February 2017
    
    Details / Methods
    -----------------
    - getPhoto - get lastes image attachment
    - savePhoto - save new attachment
   
    Update History
    --------------
    Created February 2017 - R.B.

    Issues / TODOs
    --------------
*/
public with sharing class EQT_PictureComponent_VFC {

    @AuraEnabled
    public static Attachment getPhoto(Id parentId) {
        return [SELECT Id, Name, LastModifiedDate, ContentType
                FROM Attachment 
                WHERE ParentId = :parentId
                AND ContentType IN ('image/png', 'image/jpeg', 'image/gif', 'image/bmp', 'image/jpg') 
                ORDER BY LastModifiedDate DESC LIMIT 1];
    }

    @AuraEnabled
    public static Id savePhoto(Id parentId, String fileName, String base64Data, String contentType) {
        Attachment attachment = new Attachment();
        attachment.parentId = parentId;
        attachment.body = EncodingUtil.base64Decode(base64Data);
        attachment.name = fileName;
        attachment.contentType = contentType;
        insert attachment;
        
        return attachment.id;
    }
}