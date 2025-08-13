global class PartProductSyncBatch implements Database.Batchable<SObject> {
    
    global Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator(
            'SELECT ID, Active__c, Name, Part_Number__c, Product__c ' +
            'FROM SQX_Part__c ' +
            'WHERE Product__c = NULL'
        );
    }
    
    global void execute(Database.BatchableContext BC, List<SQX_Part__c> partList) {
        
        Set<String> partNames = new Set<String>();
        Set<String> partNumber = new Set<String>();
        Map<String, SQX_Part__c> partMap = new Map<String, SQX_Part__c>();
        Map<String, Product2> existProdRecsMap = new Map<String, Product2>();
        List<SQX_Part__c> updatePartList = new List<SQX_Part__c>();
        List<Product2> insertNewProdList = new List<Product2>();
        
        if (partList != null && !partList.isEmpty()) {
            
            for (SQX_Part__c partRecord : partList) {
                if (partRecord.Name != null && partRecord.Part_Number__c != null) {
                    partNames.add(partRecord.Name);
                    partNumber.add(partRecord.Part_Number__c);
                    partMap.put(partRecord.Name + '-' + partRecord.Part_Number__c, partRecord);
                }
            }
            
            if (partNames != null && !partNames.isEmpty() && partNumber != null && !partNumber.isEmpty()) {
                for (Product2 prodRec : [
                    SELECT Id, Name, ProductCode
                    FROM Product2
                    WHERE Name IN :partNames
                    AND ProductCode IN :partNumber
                ]) {
                    if (prodRec.Name != null && prodRec.ProductCode != null) {
                        existProdRecsMap.put(prodRec.Name + '-' + prodRec.ProductCode, prodRec);
                    }
                }  
            }
            
            for (SQX_Part__c partRecord : partList) {
                Product2 existProdRec = existProdRecsMap.get(partRecord.Name + '-' + partRecord.Part_Number__c);
                if (existProdRec != null) {
                    partRecord.Product__c = existProdRec.Id;
                    updatePartList.add(partRecord);
                } else {
                    Product2 newProdRecord = new Product2();
                    newProdRecord.Name = partRecord.Name;
                    newProdRecord.ProductCode = partRecord.Part_Number__c;
                    newProdRecord.IsActive = true;
                    insertNewProdList.add(newProdRecord);
                }
            }
            
            if (insertNewProdList != null && !insertNewProdList.isEmpty()) {
                Database.insert(insertNewProdList, false);
                
                for (Product2 newProd : insertNewProdList) {
                    SQX_Part__c updatePart = partMap.get(newProd.Name + '-' + newProd.ProductCode);
                    if (updatePart != null) {
                        updatePart.Product__c = newProd.Id;
                        updatePartList.add(updatePart);
                    }
                }
            }
            
            if (updatePartList != null && !updatePartList.isEmpty()) {
                Database.update(updatePartList, false);  
            }
        }
    }
    
    global void finish(Database.BatchableContext BC) {
    }
}