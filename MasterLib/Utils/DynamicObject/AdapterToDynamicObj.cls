Include MasterLib.Utils.DynamicObject.Adapter

/// ToDynamic Object Abstraction for Adapter
Class MasterLib.Utils.DynamicObject.AdapterToDynamicObj [ Abstract, DependsOn = (MasterLib.Utils.DynamicObject.ToDynamicObjSourceGenerator, MasterLib.Utils.DynamicObject.AdapterToDynamicObjParameters), PropertyClass = MasterLib.Utils.DynamicObject.AdapterToDynamicObjParameters ]
{

/// Allows for switching to a mode that outputs the content of a embeded persistant object instead of it's Id
Parameter SerializeEmbeddedPersistentObjects = 0;

/// Toggles whether JSON serialization of "array of XXXX" properties should occur as a JSON array or as a key value pair object. <br>
/// 1 - JSON Array
/// 0 - Key/Value pair object. (Compatible with InterSystems Caché JSON Provider de-serialization)
/// Determines default behaviour, can be overriden by per property parameter DynamicObjectProjectionMode = "jsonarray" / "native"
/// 	with "object" taking they key value of arrays and making a object with properties out of them with the key forming
/// the property name.
Parameter SerializeArraysAsDynamicArrays = 1;

/// Converts the current class to a dynamic object returned via pDynamicObject, <br>
/// Any exceptions are returned via the %Status return value.
Method ToDynamicObj(Output pDynamicObject As %Library.DynamicObject) As %Status [ CodeMode = objectgenerator ]
{
	set sc=$$$OK
	try {
		set tSerializeEmbedded=$GET(%parameter("SerializeEmbeddedPersistentObjects"),0)
		set tSerializeArraysAsDynamicArrays=$GET(%parameter("SerializeArraysAsDynamicArrays"),1)
		set tCodeGeneratorUtility=##class(MasterLib.Utils.DynamicObject.ToDynamicObjSourceGenerator).%New()
	   	set tDynamicObjectCode=tCodeGeneratorUtility.Generate(%compiledclass,tSerializeEmbedded,tSerializeArraysAsDynamicArrays)
	   	do %code.WriteLine("	set sc=$$$OK")
	   	do %code.WriteLine("	try {")
	   	do %code.WriteLine("		set pDynamicObject="_tDynamicObjectCode)
	   	do %code.WriteLine("	} catch(ex) {")
	   	do %code.WriteLine("		set sc=$SYSTEM.Status.AppendStatus(ex.AsStatus(),sc)")
	   	do %code.WriteLine("	}")
	   	do %code.WriteLine("	quit sc") //Ends Of code line
	} catch(ex) {
		set sc=ex.AsStatus()
	}
	quit sc
}

/// A Internal version of ToDynamicObj, which ToDynamicObject's generated code <br>
/// uses to generate dynamic object output recursively. This was needed to <br>
/// allow for a version of ToDynamicObject to act like a functional call as <br>
/// oposed to a procedural call, so that it could be used inline in ToDynamicObj's<br>
/// tDynamicObjectCode output code.
/// 
/// Converts the current class to a dynamic object and returns it
/// Any exceptions are returned via the sc %Status value.
Method ToDynamicObjRecursive(ByRef sc As %Status) As %Library.DynamicObject [ Internal ]
{
	set:$GET(sc)="" sc=$$$OK
	set tSCNew=$$$OK
	set tDynamicObject=$$$NULLOREF
	try {
		set tSCNew=..ToDynamicObj(.tDynamicObject)
		set:$$$ISERR(tSCNew) sc=$SYSTEM.Status.AppendStatus(tSCNew,sc)
	} catch(ex) {
		#dim ex As %Exception.AbstractException
		set:$$$ISERR(tSCNew) sc=$SYSTEM.Status.AppendStatus(ex.AsStatus(),sc)
	}
	quit tDynamicObject
}

/// Generates a dynamic array for a many relationship reference.<br>
/// pManyRelationShip is a reference to a %Library.RelationshipObject which<br>
/// shall be converted into a dynamic array and returned.
Method GenerateManyRelationshipDynamicObjects(pManyRelationShip As %Library.RelationshipObject, ByRef sc As %Status) As %Library.DynamicArray [ Internal ]
{
	quit ..GenerateListOfObjDynamicObj(pManyRelationShip,.sc) //Acts same as list of objects
}

/// Generates a dynamic array for a array of data types
Method GenerateArrayOfDTDynamicArray(pArrayParentObject As %RegisteredObject, pArrayPropertyName As %String, pArray As %Collection.ArrayOfDT) As %Library.DynamicArray [ Internal ]
{
	#dim tDynamicArray As %Library.DynamicArray
	set tDynamicArray=[]
	set tArrayKey=""
	for  {
		set tArrayElementValue=pArray.GetNext(.tArrayKey)
		quit:tArrayKey=""
		do tDynamicArray.%Push(..GetLogicalToXSDValue(pArrayParentObject,pArrayPropertyName,tArrayElementValue))
	}
	quit tDynamicArray
}

/// Generates a dynamic array for a array of objects
Method GenerateArrayOfObjDynamicArray(pArray As %Collection.ArrayOfObj, ByRef sc As %Status) As %Library.DynamicArray [ Internal ]
{
	#dim tDynamicArray As %Library.DynamicArray
	set tDynamicArray=[]
	set tArrayKey=""
	for  {
		#dim tArrayElement As %RegisteredObject
		set tArrayElement=pArray.GetNext(.tArrayKey)
		quit:tArrayKey=""
		
		set tValue=""
		if (('..#SerializeEmbeddedPersistentObjects) && (tArrayElement.%Extends("%Library.Persistent"))) {
			set tValue=tArrayElement.%Id()
		} else {
			set tValue=tArrayElement.ToDynamicObjRecursive(.sc)
		}
		do tDynamicArray.%Push(tValue)
	}
	quit tDynamicArray
}

/// Generates a dynamic object for a array of data types
Method GenerateArrayOfDTDynamicObj(pArrayParentObject As %RegisteredObject, pArrayPropertyName As %String, pArray As %Collection.ArrayOfDT) As %Library.DynamicObject [ Internal ]
{
	set tDynamicObj={}
	set tArrayKey=""
	for  {
		set tArrayElementValue=pArray.GetNext(.tArrayKey)
		quit:tArrayKey=""
		do tDynamicObj.%Set(	tArrayKey, 
								..GetLogicalToXSDValue(pArrayParentObject,pArrayPropertyName,tArrayElementValue)							
							)
	}
	quit tDynamicObj
}

/// Generates a dynamic object for a array of objects
Method GenerateArrayOfObjDynamicObj(pArray As %Collection.ArrayOfObj, ByRef sc As %Status) As %Library.DynamicObject [ Internal ]
{
	
	set tDynamicObj={}
	set tArrayKey=""
	for  {
		#dim tArrayElement As %RegisteredObject
		set tArrayElement=pArray.GetNext(.tArrayKey)
		quit:tArrayKey=""
		
		set tValue=""
		if (('..#SerializeEmbeddedPersistentObjects) && (tArrayElement.%Extends("%Library.Persistent"))) {
			set tValue=tArrayElement.%Id()
		} else {
			set tValue=tArrayElement.ToDynamicObjRecursive(.sc)
		}	
		do tDynamicObj.%Set(tArrayKey, tValue)
	}
	quit tDynamicObj
}

/// Generates a dynamic array from pList a list of objects
Method GenerateListOfObjDynamicObj(pList As %Collection.ListOfObj, ByRef sc As %Status) As %Library.DynamicArray [ Internal ]
{
	set tDynamicArray=[]
	for i=1:1:pList.Count() {
		set tListElement=pList.GetAt(i)
		
		if (('..#SerializeEmbeddedPersistentObjects) && (tListElement.%Extends("%Library.Persistent"))) {
			set tValue=tListElement.%Id()
		} else {
			set tValue=tListElement.ToDynamicObjRecursive(.sc)
		}
		
		do tDynamicArray.%Push(tValue)
		do pList.%UnSwizzleAt(i) //Memory Management
	}
	quit tDynamicArray
}

/// Generates a dynamic array from pList a list of datatypes
Method GenerateListOfDTDynamicObj(pListParentObject As %RegisteredObject, pListPropertyName As %String, pList As %Collection.ListOfDT) As %Library.DynamicArray [ Internal ]
{
	set tDynamicArray=[]
	for i=1:1:pList.Count() {
		set tElementValue=pList.GetAt(i)
		do tDynamicArray.%Push(	..GetLogicalToXSDValue(pListParentObject,pListPropertyName,tElementValue))
	}
	quit tDynamicArray
}

/// Finds the XSD normalized value for a property of a object.<br>
/// pObject - instance object which's property value needs to be LogicalToXSD converted<br>
/// pPropertyName - name of the property which's value and LogicalToXSD will be used to convert 
/// 					to the XSD value
/// pValue - value that needs XSD conversion
/// Returns the XSD value
Method GetLogicalToXSDValue(pObject As %RegisteredObject, pPropertyName As %String, pValue As %String) As %String [ Internal ]
{
	set tReturnValue=""
	try {
		set:(pValue'="") tReturnValue=$Method(pObject,pPropertyName_$$$LogicalToXSDMethodName,pValue)
	} catch(ex) {
		//We explicitly check for this error to identify that LogicalToXSD did not exist
		//the reason being that sometimes on arrays of types which implement LogicalToXSD
		//using codemode=generator instead of objectgenerator results in the CompiledProperty 
		//of the array claiming the LogicalToXSD method exists during compile on the array itself.
		if (($ZERROR[$$$MethodDoesNotExistErrorPrefix)&&($ZERROR[$$$LogicalToXSDMethodName)) { 
			set tReturnValue=pValue //Did not exist so straight assign is correct
		} else {
			throw ex
		}
		set $ZERROR=""
	}
	quit tReturnValue
}

/// Copy's pStream to a string value which is returned.
Method CopyStreamToString(pStream As %Stream.Object) As %String [ Internal ]
{
	set tStreamContent=""
	set tStreamContent=pStream.Read(pStream.SizeGet())
	quit tStreamContent
}

}
