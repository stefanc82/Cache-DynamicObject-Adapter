Include MasterLib.Utils.DynamicObject.Adapter

/// FromDynamic Object Abstraction for Adapter
Class MasterLib.Utils.DynamicObject.AdapterFromDynamicObj [ Abstract, DependsOn = MasterLib.Utils.DynamicObject.FromDynamicObjSourceGenerator ]
{

/// Processes data from pDynamicObject into the current class<br>
/// Any exceptions are returned via the %Status return value.
/// Will continue to assign remaining fields to current object even if a field's XSDToLogical fails, <br>
/// In this scenario it will skip the field and process the next field and add the exception raised by
/// the XSDToLogical call to the returned status.
Method FromDynamicObj(pDynamicObject As %Library.DynamicObject) As %Status [ CodeMode = objectgenerator ]
{
	set sc=$$$OK
	set tCodeGeneratorUtility=##class(MasterLib.Utils.DynamicObject.FromDynamicObjSourceGenerator).%New()
	set tDynamicObjectToCurrentObjectCode=tCodeGeneratorUtility.Generate(%compiledclass)
	do %code.WriteLine("	set sc=$$$OK")
   	do %code.WriteLine("	try {")
   	do %code.WriteLine(tDynamicObjectToCurrentObjectCode)
   	do %code.WriteLine("	} catch(ex) {")
   	do %code.WriteLine("		set sc=$SYSTEM.Status.AppendStatus(ex.AsStatus(),sc)")
   	do %code.WriteLine("	}")
   	do %code.WriteLine("	quit sc") //Ends Of code line
   	quit sc
}

/// Returns a boolean value which determines if the object passed is indeed a dynamic object or not. <br>
Method IsDynamicObject(pDynamicObject As %Library.DynamicObject) As %Boolean [ Internal, Private ]
{
	quit:($GET(pDynamicObject,$$$NULLOREF)=$$$NULLOREF) 0
	quit:'$ISOBJECT(pDynamicObject) 0
	quit pDynamicObject.%Extends("%Library.DynamicObject")
}

/// Returns a boolean value which determines if the object passed is indeed a dynamic array or not. <br>
Method IsDynamicArray(pDynamicArray As %Library.DynamicArray) As %Boolean [ Internal, Private ]
{
	quit:($GET(pDynamicArray,$$$NULLOREF)=$$$NULLOREF) 0
	quit:'$ISOBJECT(pDynamicArray) 0
	quit pDynamicArray.%Extends("%Library.DynamicArray")
}

/// Assigns DT values of pDynamicArray Dynamic Array to the pTargetedArrayOfDataTypes data type array. <br>
/// pTargetedArrayOfDataTypes is cleared prior to any assignments occuring. <br>
Method SetArrayOfDTFromDynamicObjectArray(pDynamicArray As %Library.DynamicArray, pTargetedArrayOfDataTypes As %Collection.ArrayOfDT, pParentObject As %RegisteredObject, pPropertyName As %String) As %Status [ Internal, Private ]
{
	set sc=$$$OK
	quit:'$ISOBJECT($GET(pDynamicArray,$$$NULLOREF)) //The dynamic array element did not exist or wasn't appropriate so leave existing array as is.
	try {
		do pTargetedArrayOfDataTypes.Clear() //Logic is to clear all existing elements as per business logic requested.
		#dim tIterator As %Iterator.Array
		set tIterator = pDynamicArray.%GetIterator()
		set tKey="",tValue=""
		while tIterator.%GetNext(.tKey , .tValue ) {
			do pTargetedArrayOfDataTypes.SetAt(..GetXSDAssignValue(pParentObject,pPropertyName,tValue),(tKey+1)) //Adding 1 since arrays in DynamicArrays are 0 bassed.
		}
	} catch(ex) {
		#dim ex as %Exception.AbstractException
		set sc=ex.AsStatus()
	}
	quit sc
}

/// Assigns object Id references in the pDynamicArray Dynamic Array to the pTargetedArrayOfPersistentObjects objects array.<br>
/// pTargetedArrayOfPersistentObjects is cleared prior to any assignments occuring.<br>
Method SetArrayOfPersistentObjectsFromDynamicObjectIdArray(pDynamicArray As %Library.DynamicArray, pTargetedArrayOfPersistentObjects As %Collection.ArrayOfObj) As %Status [ Internal, Private ]
{
	set sc=$$$OK
	quit:'$ISOBJECT($GET(pDynamicArray,$$$NULLOREF)) //The dynamic array element did not exist or wasn't appropriate so leave existing array as is.
	try {
		do pTargetedArrayOfPersistentObjects.Clear() //Logic is to clear all existing elements as per business logic requested.
		#dim tIterator As %Iterator.Array
		set tIterator = pDynamicArray.%GetIterator()
		set tKey="",tObjectId=""
		while tIterator.%GetNext(.tKey , .tObjectId ) {
			do pTargetedArrayOfPersistentObjects.SetObjectIdAt(tObjectId,tKey+1)
		}
	} catch(ex) {
		#dim ex as %Exception.AbstractException
		set sc=ex.AsStatus()
	}
	quit sc
}

/// Creates a instance of pTargetArrayElementTypeClassName's class for each DynamicObject in pDynamicArray, <br>
/// each new instance is FromDynamicObj initialized using the DynamicObject and then added to the <br>
/// pTargetedArrayOfObjects Array. <br>
/// pTargetedArrayOfObjects is cleared prior to any assignments occuring. <br>
Method SetArrayOfObjectsFromDynamicObjectArray(pDynamicArray As %Library.DynamicArray, pTargetedArrayOfObjects As %Collection.ArrayOfObj, pTargetArrayElementTypeClassName As %String) As %Status [ Internal, Private ]
{
	set sc=$$$OK
	quit:'$ISOBJECT($GET(pDynamicArray,$$$NULLOREF)) $$$OK //The dynamic array element did not exist or wasn't appropriate.
	
	try {
		do pTargetedArrayOfObjects.Clear() //Logic is to clear all existing elements as per business logic requested.
		#dim tIterator As %Iterator.Array
		set tIterator = pDynamicArray.%GetIterator()
		set tKey="",tDynamicObjectElement=$$$NULLOREF
		while tIterator.%GetNext(.tKey , .tDynamicObjectElement ) {
			set tNewArrayElement=$CLASSMETHOD(pTargetArrayElementTypeClassName,"%New")
			set sc1=tNewArrayElement.FromDynamicObj(tDynamicObjectElement)
			set:$$$ISERR(sc1) sc=$SYSTEM.Status.AppendStatus(sc1,sc)
			do pTargetedArrayOfObjects.SetAt(tNewArrayElement,(tKey+1)) //Adding 1 since arrays in DynamicArrays are 0 bassed.
		}
	} catch(ex) {
		#dim ex as %Exception.AbstractException
		set sc=ex.AsStatus()
	}
	quit sc
}

/// Assigns DT values of pDynamicArray Dynamic Array to the pTargetedListOfDataTypes data type list. <br>
/// pTargetedListOfDataTypes is cleared prior to any assignments occuring. <br>
Method SetListOfDTFromDynamicObjectArray(pDynamicArray As %Library.DynamicArray, pTargetedListOfDataTypes As %Collection.ListOfDT, pParentObject As %RegisteredObject, pPropertyName As %String) As %Status [ Internal, Private ]
{
	set sc=$$$OK
	quit:'$ISOBJECT($GET(pDynamicArray,$$$NULLOREF)) //The dynamic array element did not exist or wasn't appropriate so leave existing array as is.
	try {
		do pTargetedListOfDataTypes.Clear() //Logic is to clear all existing elements as per business logic requested.
		#dim tIterator As %Iterator.Array
		set tIterator = pDynamicArray.%GetIterator()
		set tKey="",tValue=""
		while tIterator.%GetNext(.tKey , .tValue ) {
			do pTargetedListOfDataTypes.Insert(..GetXSDAssignValue(pParentObject,pPropertyName,tValue))
		}
	} catch(ex) {
		#dim ex as %Exception.AbstractException
		set sc=ex.AsStatus()
	}
	quit sc
}

/// Converts pXSDValue to it's logical counterpart
/// pParentObject - object holding the XXXXXXSDToLogical method
/// pPropertyName - name of property for which logical transformation is being called.
Method GetXSDAssignValue(pParentObject As %RegisteredObject, pPropertyName As %String, pXSDValue As %String) As %String
{
	quit:pXSDValue="" ""
	try {
		set tLogicalValue=$METHOD(pParentObject,pPropertyName_$$$XSDToLogicalMethodName,pXSDValue)
		set:tLogicalValue="" tLogicalValue=pXSDValue
	} catch(ex) {
		set tLogicalValue=pXSDValue
	}
	quit tLogicalValue
}

/// Assigns object Id references in the pDynamicArray Dynamic Array to the pTargetedListOfPersistentObjects objects list.<br>
/// pTargetedListOfPersistentObjects is cleared prior to any assignments occuring.<br>
Method SetListOfPersistentObjectsFromDynamicObjectArray(pDynamicArray As %Library.DynamicArray, pTargetedListOfPersistentObjects As %Collection.ListOfObj) As %Status [ Internal, Private ]
{
	set sc=$$$OK
	quit:'$ISOBJECT($GET(pDynamicArray,$$$NULLOREF)) //The dynamic array element did not exist or wasn't appropriate so leave existing array as is.
	try {
		do pTargetedListOfPersistentObjects.Clear() //Logic is to clear all existing elements as per business logic requested.
		#dim tIterator As %Iterator.Array
		set tIterator = pDynamicArray.%GetIterator()
		set tKey="",tObjectId=""
		while tIterator.%GetNext(.tKey , .tObjectId ) {
			do pTargetedListOfPersistentObjects.InsertObjectId(tObjectId)
		}
	} catch(ex) {
		#dim ex as %Exception.AbstractException
		set sc=ex.AsStatus()
	}
	quit sc
}

/// Creates a instance of pTargetListElementTypeClassName's class for each DynamicObject in pDynamicArray, <br>
/// each new instance is FromDynamicObj initialized using the DynamicObject and then added to the <br>
/// pTargetedListOfObjects List. <br>
/// pTargetedListOfObjects is cleared prior to any assignments occuring. <br>
Method SetListOfObjectsFromDynamicObjectArray(pDynamicArray As %Library.DynamicArray, pTargetedListOfObjects As %Collection.ListOfObj, pTargetListElementTypeClassName As %String) As %Status [ Internal, Private ]
{
	set sc=$$$OK
	quit:'$ISOBJECT($GET(pDynamicArray,$$$NULLOREF)) $$$OK //The dynamic array element did not exist or wasn't appropriate.
	
	try {
		do pTargetedListOfObjects.Clear() //Logic is to clear all existing elements as per business logic requested.
		#dim tIterator As %Iterator.Array
		set tIterator = pDynamicArray.%GetIterator()
		set tKey="",tDynamicObjectElement=$$$NULLOREF
		while tIterator.%GetNext(.tKey , .tDynamicObjectElement ) {
			set tNewListElement=$CLASSMETHOD(pTargetListElementTypeClassName,"%New")
			set sc1=tNewListElement.FromDynamicObj(tDynamicObjectElement)
			set:$$$ISERR(sc1) sc=$SYSTEM.Status.AppendStatus(sc1,sc)
			do pTargetedListOfObjects.Insert(tNewListElement)
		}
	} catch(ex) {
		#dim ex as %Exception.AbstractException
		set sc=ex.AsStatus()
	}
	quit sc
}

}
