Include MasterLib.Utils.DynamicObject.Adapter

/// Class intended to be used by Dynamic Object Adapter to generate code <br>
/// needed to de-serialize a pCompiledClass from a dynamic object.<br>
/// Has one public method: Generate(pCompiledClass As %Dictionary.CompiledClass) As %String
Class MasterLib.Utils.DynamicObject.FromDynamicObjSourceGenerator Extends %RegisteredObject
{

/// Private string of generated code generated and used internaly.
Property ReturnSourceCode As %String(MAXLEN = "") [ Private ];

/// Generates a sequence of code as a multiline string which can be used to de-serialize a <br>
/// dynamic object into the current class extending the adapter class which is using this generator. <br>
/// pSerializeEmbededObjectsMode is a boolean value that determines if the properties of embedded objects<br>
/// are returned or if only their Id's are returned for persisted embedded objects.
Method Generate(pCompiledClass As %Dictionary.CompiledClass) As %String
{
	for i=1:1:pCompiledClass.Properties.Count() {
		#dim tCompiledPoperty As %Dictionary.CompiledProperty
		set tCompiledPoperty=pCompiledClass.Properties.GetAt(i)
		if ..IsGettableSettableProperty(tCompiledPoperty) {
			do ..AddDynamicObjToCurrentAssignmentCodeForProperty(tCompiledPoperty)
		}
	}
	quit ..ReturnSourceCode
}

/// Determines if the pCompiledProperty is a settable property or not.
Method IsGettableSettableProperty(pCompiledProperty As %Dictionary.CompiledProperty) As %Boolean [ Private ]
{
	quit:..IsSystemPercentProperty(pCompiledProperty) 0 //Excluding % start values as "internal"
	quit:pCompiledProperty.Private 0 //Private properties are not settable/gettable.
	quit:pCompiledProperty.ReadOnly 0 //
	quit:((pCompiledProperty.Cardinality="many") || (pCompiledProperty.Cardinality="children")) 0 //Relationships not supported - Remove and add rules if support is needed in future.
	quit 1
}

/// Returns True if the pCompiledProperty is to be considered a system property due to it's name starting with a %
Method IsSystemPercentProperty(pCompiledProperty As %Dictionary.CompiledProperty) As %Boolean [ Private ]
{
	quit ($EXTRACT(pCompiledProperty.Name,1,1)="%") //Excluding % start values as "internal"
}

/// Adds code to handle pCompiledProperty's deserialization to the ReturnSourceCode source.
Method AddDynamicObjToCurrentAssignmentCodeForProperty(pCompiledProperty As %Dictionary.CompiledProperty) [ Private ]
{
	set tPropertyAssignmentType=..GetPropertyAssignmentType(pCompiledProperty)
	if (tPropertyAssignmentType=$$$DataTypeAssignmentMode) {
		do ..AddDataTypeAssignmentSourceCode(pCompiledProperty)
	} elseif (tPropertyAssignmentType=$$$PersistentObjectAssignmentMode) {
		do ..AddPersistentObjectAssignmentSourceCode(pCompiledProperty)
	} elseif (tPropertyAssignmentType=$$$SerialObjectAssignmentMode) {
		do ..AddSerialObjectDynamicAssignmentReferencesSourceCode(pCompiledProperty)
	} elseif (tPropertyAssignmentType=$$$ArrayOfDTAssignmentMode) {
		do ..AddArrayOfDTAssignmentSourceCode(pCompiledProperty)
	} elseif (tPropertyAssignmentType=$$$ArrayOfObjectsPersistantAssignmentMode) {
		do ..AddArrayOfObjectsPersistantAssignmentSourceCode(pCompiledProperty)
	} elseif (tPropertyAssignmentType=$$$ArrayOfObjectsNonPersistantAssignmentMode) {
		do ..AddArrayOfObjectsNonPersistantAssignmentSourceCode(pCompiledProperty)
	} elseif (tPropertyAssignmentType=$$$ListOfDTAssignmentMode) {
		do ..AddListOfDTAssignmentSourceCode(pCompiledProperty)
	} elseif (tPropertyAssignmentType=$$$ListOfObjectsPersistantAssignmentMode) {
		do ..AddListOfObjectsPersistantAssignmentSourceCode(pCompiledProperty)
	} elseif (tPropertyAssignmentType=$$$ListOfObjectsNonPersistantAssignmentMode) {
		do ..AddListOfObjectsNonPersistantAssignmentSourceCode(pCompiledProperty)
	} elseif (tPropertyAssignmentType=$$$EmbededRegisteredObjectAssignmentMode) {
		do ..AddEmbededRegisteredObjectDynamicAssignmentReferencesSourceCode(pCompiledProperty)
	}else {
		//Unknown mode detected. //Ignore
	}
}

/// Determines the type of assignment logic needed for pCompiledProperty,
/// at present there are three scenarios covered:
/// $$$DataTypeAssignmentMode						-	this is used for flat data type classes which may or may not support<br>
/// 													XSDToLogical or not. <br>
/// <br>
/// $$$SerialObjectAssignmentMode					-	this is used for serial embeded objects, and is resolved by invoking the serialObject <br>
/// 													itself's FromDynamicObj generated implementation.<br>
/// <br>
/// $$$PersistentObjectAssignmentMode				-	this is used for embeded persistant objects where the assigning of their content is not <br>
/// 													desired, but the changing of their reference id.
/// <br>
/// $$$ArrayOfDTAssignmentMode						-	this is used for flat data types which are in an array.<br>
/// <br>
/// $$$ArrayOfObjectsPersistantAssignmentMode		-	this is used for embeded persistant objects that are part of an array where the assigning<br>
/// 													 of their content is not desired, but the changing of their reference id.<br>
/// <br>
/// $$$ArrayOfObjectsNonPersistantAssignmentMode	-	this is used for embeded non persistant objects such as registered objects or serial objects <br>
/// <br>
/// $$$ListOfDTAssignmentMode						-	this is used for flat data types which are in a list.<br>
/// <br>
/// $$$ListOfObjectsPersistantAssignmentMode		-	this is used for embeded persistant objects that are part of a list where the assigning<br>
/// 													 of their content is not desired, but the changing of their reference id.<br>
/// <br>
/// $$$ListOfObjectsNonPersistantAssignmentMode		-	this is used for embeded non persistant objects such as registered objects or serial objects <br>
/// <br>
/// $$$EmbededRegisteredObjectAssignmentMode		-	this is used for embeded registered objects, and is resolved by invoking the registered objects' <br>
/// 													FromDynamicObj generated implementation.<br>
/// <br>
/// $$$UnsupportedMode								-	returned when the property falls out of the scope of the current mode detection logic.
Method GetPropertyAssignmentType(pCompiledProperty As %Dictionary.CompiledProperty) As %String [ Private ]
{
 	set tCompiledClass=##class(%Dictionary.CompiledClass).%OpenId(pCompiledProperty.Type,0)
 
	if pCompiledProperty.Collection="array" {
		quit ..GetArrayAssignmentType(tCompiledClass.ClassType)
	} elseif pCompiledProperty.Collection="list" {
		quit ..GetListAssignmentType(tCompiledClass.ClassType)	
	} else {
		quit:tCompiledClass=$$$NULLOREF $$$UnsupportedMode //Relationships tend to compile together with the class, so their compiled classes are unavailable.
		set tIsRegisteredExtention=..IsRegisteredObjectExtention(tCompiledClass) 
		quit ..GetOtherAssignmentType(tCompiledClass.ClassType,pCompiledProperty.Cardinality,tIsRegisteredExtention)
		
	}
}

/// Determines which "array" type of assignment mode is required for the property under inspection. <br>|
/// pArrayElementClassType corresponds to the ClassType field of the %Dictionary.CompiledClass of the property.<br>|
Method GetArrayAssignmentType(pArrayElementClassType As %String) As %String [ Private ]
{
	if (pArrayElementClassType="datatype") {
		quit $$$ArrayOfDTAssignmentMode
	} else {
		if (pArrayElementClassType="persistent") {
			quit $$$ArrayOfObjectsPersistantAssignmentMode
		} else {
			quit $$$ArrayOfObjectsNonPersistantAssignmentMode
		}
	}
	quit //Will never be reached - just here for convension.
}

/// Determines which "list" type of assignment mode is required for the property under inspection.<br>|
/// pListElementClassType corresponds to the ClassType field of the %Dictionary.CompiledClass of the property.<br>|
Method GetListAssignmentType(pListElementClassType As %String) As %String [ Private ]
{
	if (pListElementClassType="datatype") {
		quit $$$ListOfDTAssignmentMode
	} else {
		if (pListElementClassType="persistent") {
			quit $$$ListOfObjectsPersistantAssignmentMode
		} else {
			quit $$$ListOfObjectsNonPersistantAssignmentMode
		}
	}
	quit //Will never be reached - just here for convension.
}

/// Determines if the compiled class extends %RegisteredObject
Method IsRegisteredObjectExtention(pCompiledClass As %Dictionary.CompiledClass) As %Boolean
{
	quit (pCompiledClass.PrimarySuper["~%Library.RegisteredObject~")
}

/// Determines which "other" type of assignment mode is required for the property under inspection.<br>|
/// pPropertyClassType corresponds to the ClassType field of the %Dictionary.CompiledClass of the property.<br>|
/// pPropertyCardinality corresponds to the CompiledProperty's Cardinality field.<br>|
Method GetOtherAssignmentType(pPropertyClassType As %String, pPropertyCardinality As %String, pIsExtentionOfRegisteredObject As %Boolean) As %String [ Private ]
{
	if (pPropertyClassType="datatype") {
		quit $$$DataTypeAssignmentMode
	} elseif (pPropertyClassType="serial") { //Registered Objects share serial output mode
		quit $$$SerialObjectAssignmentMode
	} elseif (((pPropertyClassType="persistent")&&(pPropertyCardinality="")) || (pPropertyCardinality="one") || (pPropertyCardinality="parent")) {
		quit $$$PersistentObjectAssignmentMode
	} elseif ((pPropertyClassType="") && (pIsExtentionOfRegisteredObject)) {
		quit $$$EmbededRegisteredObjectAssignmentMode
	}else {
		quit $$$UnsupportedMode
	}
}

/// Generates source code to deserialize pCompiledProperty as a $$$DataTypeAssignmentMode property<br>
/// Source code is added to the ReturnSourceCode property.<br>
/// <br>
Method AddDataTypeAssignmentSourceCode(pCompiledProperty As %Dictionary.CompiledProperty) [ Private ]
{
	set tSourcePropertyName=..GetCompiledPropertyOutputName(pCompiledProperty)
	do ..AddSourceCodeLine("		if ("_$$$DynamicObjReferenceName_".%IsDefined("""_tSourcePropertyName_""")) && ("_..MakeTargetPropertyReference(pCompiledProperty.Name)_"'="_..MakeDynamicObjectPropertyValueReference(tSourcePropertyName)_") {")
	do ..AddSourceCodeLine("			try {")
	if ..IsLogicalToXSDCapable(pCompiledProperty) {
		do ..AddSourceCodeLine("				try {")
		do ..AddSourceCodeLine("					set tDynamicValue="_..MakeDynamicObjectPropertyValueReference(tSourcePropertyName))
		do ..AddSourceCodeLine("					set value=$METHOD($THIS,"""_pCompiledProperty.Name_$$$XSDToLogicalMethodName_""",tDynamicValue)")
		do ..AddSourceCodeLine("					set:((tDynamicValue'="""")&&(value="""")) value=tDynamicValue")
		do ..AddSourceCodeLine("				} catch(ex) {")
		do ..AddSourceCodeLine("					set value="_..MakeDynamicObjectPropertyValueReference(tSourcePropertyName))
		do ..AddSourceCodeLine("					set $ZERROR=""""")
		do ..AddSourceCodeLine("				}")
	} else {
		do ..AddSourceCodeLine("				set value="_..MakeDynamicObjectPropertyValueReference(tSourcePropertyName))
	}
	do ..AddSourceCodeLine("				set "_..MakeTargetPropertyReference(pCompiledProperty.Name) _ "=value")
	do ..AddSourceCodeLine("			} catch(ex) {")
	do ..AddSourceCodeLine("				set sc=$SYSTEM.Status.AppendStatus(ex.AsStatus(),sc)")
	do ..AddSourceCodeLine("			}")
	do ..AddSourceCodeLine("		}")
}

/// Returns the name of the dynamic object property to read for the compiled property pCompiledProperty
Method GetCompiledPropertyOutputName(pCompiledProperty As %Dictionary.CompiledProperty) As %String [ Private ]
{
	quit pCompiledProperty.Name
}

/// Adds the pCode code line to the ReturnSourceCode property string.
Method AddSourceCodeLine(pCode As %String) [ Private ]
{
	set ..ReturnSourceCode=..ReturnSourceCode_pCode_$$$NewLine
}

/// Determines if attempts should be made for pCompiledProperty to call LogicalToXSD when deserializing it's value.
Method IsLogicalToXSDCapable(pCompiledProperty As %Dictionary.CompiledProperty) As %Boolean [ Private ]
{
	set tCompiledMethod=##class(%Dictionary.CompiledPropertyMethod).%OpenId(pCompiledProperty.%Id()_"||"_$$$LogicalToXSDMethodName,0)
	quit:tCompiledMethod=$$$NULLOREF 0
	quit 1
}

/// Returns the full XSDToLogical reference name for pTargetPropertyName.<br>
/// pTargetPropertyName is the name of the property being deserialized.
Method MakeTargetPropertyXSDToLogicalMethodNameReference(pTargetPropertyName As %String) As %String [ Private ]
{
	quit ..MakeTargetPropertyReference(pTargetPropertyName)_$$$XSDToLogicalMethodName
}

/// Returns a current object property reference string for pTargetPropertyName
Method MakeTargetPropertyReference(pTargetPropertyName As %String) As %String [ Private ]
{
	quit ".."_pTargetPropertyName
}

/// Returns a full reference to the dymaic object property of pSourcePropertyName
Method MakeDynamicObjectPropertyValueReference(pSourcePropertyName As %String) As %String [ Private ]
{
	quit $$$DynamicObjReferenceName_"."""_pSourcePropertyName_""""
}

/// Generates source code to deserialize pCompiledProperty as a $$$PersistentObjectAssignmentMode property<br>
/// Source code is added to the ReturnSourceCode property.<br>
/// <br>
/// It makes use of the SetObjectId and GetObjectId generator methods created for embeded persistant objects,<br>
/// one side of one to many relationships, and parent side of parent child relationships.
Method AddPersistentObjectAssignmentSourceCode(pCompiledProperty As %Dictionary.CompiledProperty) [ Private ]
{
	set tSourcePropertyName=..GetCompiledPropertyOutputName(pCompiledProperty)
	do ..AddSourceCodeLine("		if ("_$$$DynamicObjReferenceName_".%IsDefined("""_tSourcePropertyName_""")) {")
	do ..AddSourceCodeLine("			try {")
	do ..AddSourceCodeLine("				set newIdvalue="_..MakeDynamicObjectPropertyValueReference(tSourcePropertyName))
	do ..AddSourceCodeLine("				set existingIdValue="_..MakeTargetPropertyReference(pCompiledProperty.Name)_"GetObjectId()")
	do ..AddSourceCodeLine("				do:(existingIdValue'=newIdvalue) "_..MakeTargetPropertyReference(pCompiledProperty.Name) _ "SetObjectId(newIdvalue)")
	do ..AddSourceCodeLine("			} catch(ex) {")
	do ..AddSourceCodeLine("				set sc=$SYSTEM.Status.AppendStatus(ex.AsStatus(),sc)")
	do ..AddSourceCodeLine("			}")
	do ..AddSourceCodeLine("		}")
}

/// Generates source code to deserialize pCompiledProperty as a $$$SerialObjectAssignmentMode property<br>
/// Source code is added to the ReturnSourceCode property.<br>
/// The code generated works on the principal that the serial object itself also is a extention of the DynamicObject<br>
/// Adapter class, and calls its implementation of FromDynamicObj passing the dynamic object representing the serial object.
Method AddSerialObjectDynamicAssignmentReferencesSourceCode(pCompiledProperty As %Dictionary.CompiledProperty) [ Private ]
{
	set tSourcePropertyName=..GetCompiledPropertyOutputName(pCompiledProperty)
	do ..AddSourceCodeLine("		if ("_$$$DynamicObjReferenceName_".%IsDefined("""_tSourcePropertyName_""")) {")
	do ..AddSourceCodeLine("			try {")
	set tDynamicObjectReference=..MakeDynamicObjectPropertyValueReference(tSourcePropertyName)
	do ..AddSourceCodeLine("				set value="_tDynamicObjectReference)
	do ..AddSourceCodeLine("				if (..IsDynamicObject(value)) {")
	do ..AddSourceCodeLine("					set sc1="_..MakeTargetPropertyReference(pCompiledProperty.Name) _ ".FromDynamicObj(value)")
	do ..AddSourceCodeLine("				} else {")
	do ..AddSourceCodeLine("					set sc1=$$$ERROR($$$ReferenceIsNotADynamicObject,""The reference '" _ $REPLACE(tDynamicObjectReference,"""","""""") _"' is not a dynamic object."")")
	do ..AddSourceCodeLine("				}")
	do ..AddSourceCodeLine("				set:$$$ISERR(sc1) sc=$SYSTEM.Status.AppendStatus(sc1,sc)")
	do ..AddSourceCodeLine("			} catch(ex) {")
	do ..AddSourceCodeLine("				set sc=$SYSTEM.Status.AppendStatus(ex.AsStatus(),sc)")
	do ..AddSourceCodeLine("			}")
	do ..AddSourceCodeLine("		}")
}

/// Generates source code to deserialize pCompiledProperty as a $$$ArrayOfDTAssignmentMode property<br>
/// Source code is added to the ReturnSourceCode property.<br>
Method AddArrayOfDTAssignmentSourceCode(pCompiledProperty As %Dictionary.CompiledProperty) [ Private ]
{
	set tSourcePropertyName=..GetCompiledPropertyOutputName(pCompiledProperty)
	set tDynamicObjectReference=..MakeDynamicObjectPropertyValueReference(tSourcePropertyName)
	set tCommand="..SetArrayOfDTFromDynamicObjectArray(tSourceDynamicArray,"_..MakeTargetPropertyReference(pCompiledProperty.Name)_
						",$This,"""_pCompiledProperty.Name_""")"
	do ..AddIsDefinedDynamicArrayWithTryCommand(tSourcePropertyName,tDynamicObjectReference,tCommand)
}

/// Generates generic dynamic array source field code for specified pCommand.
/// pSourcePropertyName is the name of the property representing the dymaic array in the source data.
/// pDynamicObjectReference is a string representing the code needed in the context of the generator to 
/// make reference to the dynamic array.
Method AddIsDefinedDynamicArrayWithTryCommand(pSourcePropertyName As %String, pDynamicObjectReference As %String, pCommand As %String) [ Private ]
{
	do ..AddSourceCodeLine("		if ("_$$$DynamicObjReferenceName_".%IsDefined("""_pSourcePropertyName_""")) {")
	do ..AddSourceCodeLine("			try {")
	do ..AddSourceCodeLine("				set tSourceDynamicArray="_pDynamicObjectReference)
	do ..AddSourceCodeLine("				if (..IsDynamicArray(tSourceDynamicArray)) {")
	do ..AddSourceCodeLine("					set sc1="_pCommand)
	do ..AddSourceCodeLine("				} else {")
	do ..AddSourceCodeLine("					set sc1=$$$ERROR($$$ReferenceIsNotADynamicObject,""The reference '" _ $REPLACE(pDynamicObjectReference,"""","""""") _"' is not a dynamic object."")")
	do ..AddSourceCodeLine("				}")
	do ..AddSourceCodeLine("				set:$$$ISERR(sc1) sc=$SYSTEM.Status.AppendStatus(sc1,sc)")
	do ..AddSourceCodeLine("			} catch(ex) {")
	do ..AddSourceCodeLine("				set sc=$SYSTEM.Status.AppendStatus(ex.AsStatus(),sc)")
	do ..AddSourceCodeLine("			}")
	do ..AddSourceCodeLine("		}")
}

/// Generates source code to deserialize pCompiledProperty as a $$$ArrayOfObjectsPersistantAssignmentMode property<br>
/// Source code is added to the ReturnSourceCode property.<br>
Method AddArrayOfObjectsPersistantAssignmentSourceCode(pCompiledProperty As %Dictionary.CompiledProperty) [ Private ]
{
	set tSourcePropertyName=..GetCompiledPropertyOutputName(pCompiledProperty)
	set tDynamicObjectReference=..MakeDynamicObjectPropertyValueReference(tSourcePropertyName)
	set tCommand="..SetArrayOfPersistentObjectsFromDynamicObjectIdArray(tSourceDynamicArray,"_..MakeTargetPropertyReference(pCompiledProperty.Name)_")"
	do ..AddIsDefinedDynamicArrayWithTryCommand(tSourcePropertyName,tDynamicObjectReference,tCommand)
}

/// Generates source code to deserialize pCompiledProperty as a $$$ArrayOfObjectsNonPersistantAssignmentMode property<br>
/// Source code is added to the ReturnSourceCode property.<br>
Method AddArrayOfObjectsNonPersistantAssignmentSourceCode(pCompiledProperty As %Dictionary.CompiledProperty) [ Private ]
{
	set tSourcePropertyName=..GetCompiledPropertyOutputName(pCompiledProperty)
	set tDynamicObjectReference=..MakeDynamicObjectPropertyValueReference(tSourcePropertyName)
	set tCommand="..SetArrayOfObjectsFromDynamicObjectArray(tSourceDynamicArray,"_..MakeTargetPropertyReference(pCompiledProperty.Name)_","""_pCompiledProperty.Type_""")"
	do ..AddIsDefinedDynamicArrayWithTryCommand(tSourcePropertyName,tDynamicObjectReference,tCommand)
}

/// Generates source code to deserialize pCompiledProperty as a $$$ListOfDTAssignmentMode property<br>
/// Source code is added to the ReturnSourceCode property.<br>
Method AddListOfDTAssignmentSourceCode(pCompiledProperty As %Dictionary.CompiledProperty) [ Private ]
{
	set tSourcePropertyName=..GetCompiledPropertyOutputName(pCompiledProperty)
	set tDynamicObjectReference=..MakeDynamicObjectPropertyValueReference(tSourcePropertyName)
	set tCommand="..SetListOfDTFromDynamicObjectArray(tSourceDynamicArray,"_..MakeTargetPropertyReference(pCompiledProperty.Name)_
						",$This,"""_pCompiledProperty.Name_""")"
	do ..AddIsDefinedDynamicArrayWithTryCommand(tSourcePropertyName,tDynamicObjectReference,tCommand)
}

/// Generates source code to deserialize pCompiledProperty as a $$$ListOfObjectsPersistantAssignmentMode property<br>
/// Source code is added to the ReturnSourceCode property.<br>
Method AddListOfObjectsPersistantAssignmentSourceCode(pCompiledProperty As %Dictionary.CompiledProperty) [ Private ]
{
	set tSourcePropertyName=..GetCompiledPropertyOutputName(pCompiledProperty)
	set tDynamicObjectReference=..MakeDynamicObjectPropertyValueReference(tSourcePropertyName)
	set tCommand="..SetListOfPersistentObjectsFromDynamicObjectArray(tSourceDynamicArray,"_..MakeTargetPropertyReference(pCompiledProperty.Name)_")"
	do ..AddIsDefinedDynamicArrayWithTryCommand(tSourcePropertyName,tDynamicObjectReference,tCommand)
}

/// Generates source code to deserialize pCompiledProperty as a $$$ListOfObjectsNonPersistantAssignmentMode property<br>
/// Source code is added to the ReturnSourceCode property.<br>
Method AddListOfObjectsNonPersistantAssignmentSourceCode(pCompiledProperty As %Dictionary.CompiledProperty) [ Private ]
{
	set tSourcePropertyName=..GetCompiledPropertyOutputName(pCompiledProperty)
	set tDynamicObjectReference=..MakeDynamicObjectPropertyValueReference(tSourcePropertyName)
	set tCommand="..SetListOfObjectsFromDynamicObjectArray(tSourceDynamicArray,"_..MakeTargetPropertyReference(pCompiledProperty.Name)_","""_pCompiledProperty.Type_""")"
	do ..AddIsDefinedDynamicArrayWithTryCommand(tSourcePropertyName,tDynamicObjectReference,tCommand)
}

/// Generates source code to deserialize pCompiledProperty as a $$$EmbededRegisteredObjectAssignmentMode property<br>
/// Source code is added to the ReturnSourceCode property.<br>
/// The code generated works on the principal that the registed object itself also is a extention of the DynamicObject<br>
/// Adapter class, and calls its implementation of FromDynamicObj passing the dynamic object representing the serial object.
Method AddEmbededRegisteredObjectDynamicAssignmentReferencesSourceCode(pCompiledProperty As %Dictionary.CompiledProperty) [ Private ]
{
	set tSourcePropertyName=..GetCompiledPropertyOutputName(pCompiledProperty)
	do ..AddSourceCodeLine("		if ("_$$$DynamicObjReferenceName_".%IsDefined("""_tSourcePropertyName_""")) {")
	do ..AddSourceCodeLine("			try {")
	set tDynamicObjectReference=..MakeDynamicObjectPropertyValueReference(tSourcePropertyName)
	do ..AddSourceCodeLine("				set value="_tDynamicObjectReference)
	do ..AddSourceCodeLine("				if (..IsDynamicObject(value)) {")
	do ..AddSourceCodeLine("					set:("_..MakeTargetPropertyReference(pCompiledProperty.Name) _ "=$$$NULLOREF) "_
															..MakeTargetPropertyReference(pCompiledProperty.Name)_
																	"=##class("_pCompiledProperty.Type_").%New()")
	do ..AddSourceCodeLine("					set sc1="_..MakeTargetPropertyReference(pCompiledProperty.Name) _ ".FromDynamicObj(value)")
	do ..AddSourceCodeLine("				} else {")
	do ..AddSourceCodeLine("					set sc1=$$$ERROR($$$ReferenceIsNotADynamicObject,""The reference '" _ $REPLACE(tDynamicObjectReference,"""","""""") _"' is not a dynamic object."")")
	do ..AddSourceCodeLine("				}")
	do ..AddSourceCodeLine("				set:$$$ISERR(sc1) sc=$SYSTEM.Status.AppendStatus(sc1,sc)")
	do ..AddSourceCodeLine("			} catch(ex) {")
	do ..AddSourceCodeLine("				set sc=$SYSTEM.Status.AppendStatus(ex.AsStatus(),sc)")
	do ..AddSourceCodeLine("			}")
	do ..AddSourceCodeLine("		}")
}

}
