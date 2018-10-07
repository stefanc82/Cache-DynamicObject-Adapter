Include MasterLib.Utils.DynamicObject.Adapter

/// Class intended to be used by Dynamic Object Adapter to generate code <br>
/// needed to serialize a pCompiledClass to a dynamic object.<br>
/// Has one public method: Generate(pCompiledClass As %Dictionary.CompiledClass) As %String
Class MasterLib.Utils.DynamicObject.ToDynamicObjSourceGenerator Extends %RegisteredObject
{

/// String of generated code generated and used internaly.
Property ReturnSourceCode As %String(MAXLEN = "") [ Private ];

/// String containing code expression needed to make a reference to the currently being processed <br>
/// property at runtime.
Property PropertyValueReferenceString As %String(MAXLEN = "") [ Private ];

/// Boolean indicating if the currently processed property is a data type or not.
Property IsPropertyNotDT As %Boolean [ Private ];

/// Transient internal reference to the compiled property for which output code is currently being generated.
Property CompiledProperty As %Dictionary.CompiledProperty [ Private, Transient ];

/// Indicates the mode in which the generator is currently being run with respect to if<br>
/// embeded persistent objects or one/parent relationship references should be serialized<br>
/// as the id of their object, or as a dynamic object representing the actual object itself <br>
/// with associate properties.
Property IsSerializeEmbededObjectsMode As %Boolean [ Private ];

/// Indicates the default mode in which the generator is currently being run with respect to if<br>
/// arrays of objects and datatypes are serialized as JSON arrays or key value pair objects.
Property IsSerializeArraysAsDynamicArraysMode As %Boolean [ Private ];

/// Indicates the mode in which the generator is generating the current property with respect to<br>
/// arrays of objects and datatypes are serialized as JSON arrays or key value pair objects.
Property IsCurrentPropertySerializeEmbededObjectsMode As %Boolean [ Private ];

/// Generates a dynamic object expression source code to represent the pCompiledClass as dynamic object and returns <br>
/// the expression as a string. <br>
/// pSerializeEmbededObjectsMode is a boolean value that determines if the properties of embedded objects<br>
/// are returned or if only their Id's are returned for persisted embedded objects.
Method Generate(pCompiledClass As %Dictionary.CompiledClass, pIsSerializeEmbededObjectsMode As %Boolean, pIsSerializeArraysAsDynamicArraysMode As %Boolean) As %String
{
	set ..ReturnSourceCode=..MakeDynamicObjectSourceObjectOpenTag()
	set ..IsSerializeEmbededObjectsMode=pIsSerializeEmbededObjectsMode
	set ..IsSerializeArraysAsDynamicArraysMode=pIsSerializeArraysAsDynamicArraysMode
	set tFirstPropertyAdded=0
	
	if ..IsPersistentClass(pCompiledClass) {
		set ..ReturnSourceCode=..ReturnSourceCode_..GenerateToDynamicObjSourceCodeForID()
		set tFirstPropertyAdded=1
	}
	
	for i=1:1:pCompiledClass.Properties.Count() {
		#dim tCompiledPoperty As %Dictionary.CompiledProperty
		set tCompiledPoperty=pCompiledClass.Properties.GetAt(i)
		
		if ..IsGettableSettableProperty(tCompiledPoperty) {
			set:tFirstPropertyAdded ..ReturnSourceCode=..ReturnSourceCode_
															..MakeDynamicObjectSourceFieldSeperator() //Next property
			
			set ..ReturnSourceCode=..ReturnSourceCode_..GenerateToDynamicObjSourceCodeForProperty(tCompiledPoperty)
			set tFirstPropertyAdded=1
		}
	}
	set ..ReturnSourceCode=..ReturnSourceCode_..MakeDynamicObjectSourceObjectCloseTag()
	quit ..ReturnSourceCode
}

/// Determines if pCompiledClass is a persistant class which has a %Id() method.
Method IsPersistentClass(pCompiledClass As %Dictionary.CompiledClass) As %Boolean [ Private ]
{
	quit (pCompiledClass.ClassType="persistent")
}

/// Generates a reference to the class's %Id() method.
Method GenerateToDynamicObjSourceCodeForID() As %String [ Private ]
{
	quit ..MakeQuotedValue("ID") _ ..MakeDynamicObjectSourceOpeningFieldValueSeperator() _ "(..%Id())"
}

/// Returns the opening tag for dynamic objects
Method MakeDynamicObjectSourceObjectOpenTag() As %String [ Private ]
{
	quit "{"
}

/// Returns seperator to be used between fields:(value) dynamic object source pairs
Method MakeDynamicObjectSourceFieldSeperator() As %String [ Private ]
{
	quit ","
}

/// Returns true if a property is not a system property not part of the output, it <br>
/// is not an unsettable private property, and finaly it is not a relationship <br>
/// parent/one property. This last relationship condition parent/one property is a <br>
/// catch check to stop infinite recursive looping up and down the same structure<br>
/// from parent to child to parent to child etc.
Method IsGettableSettableProperty(pCompiledProperty As %Dictionary.CompiledProperty) As %Boolean [ Private ]
{
	quit:..IsSystemPercentProperty(pCompiledProperty) 0 //Excluding % start values as "internal"
	quit:pCompiledProperty.Private 0 //Private properties are not settable/gettable.
	quit:pCompiledProperty.Parameters.GetAt("BlockDOProjection")=1 0 //Properties marked for internal use only.
	//quit:..IsOneOrChildRelationShip(pCompiledProperty) 0 //Excluding to stop infinite recursion
	quit 1
}

/// Returns True if the property is to be considered a system property due to it's name starting with a %
Method IsSystemPercentProperty(pCompiledProperty As %Dictionary.CompiledProperty) As %Boolean [ Private ]
{
	quit ($EXTRACT(pCompiledProperty.Name,1,1)="%") //Excluding % start values as "internal"
}

/// Returns whether or not pCompiledProperty is a parent or one relationship.
Method IsOneOrChildRelationShip(pCompiledProperty As %Dictionary.CompiledProperty) As %Boolean [ Private ]
{
	quit ((pCompiledProperty.Cardinality="one") || (pCompiledProperty.Cardinality="parent"))
}

/// Generates the field:(value) Dynamic Object Source for the pCompiledProperty compiled property and returns it.
Method GenerateToDynamicObjSourceCodeForProperty(pCompiledProperty As %Dictionary.CompiledProperty) As %String [ Private ]
{
	set ..CompiledProperty=pCompiledProperty
	set ..IsPropertyNotDT=..IsEmbededObjectType(pCompiledProperty)
	set ..PropertyValueReferenceString=".."_pCompiledProperty.Name
	set ..IsCurrentPropertySerializeEmbededObjectsMode=..GetObjectSerializeEmbededMode(pCompiledProperty)
	
	quit ..MakeDynamicObjectSourceFieldName() _
			..MakeDynamicObjectSourceOpeningFieldValueSeperator()_
			..GenerateDynamicObjectFieldValueSource()
}

Method GetObjectSerializeEmbededMode(pCompiledProperty As %Dictionary.CompiledProperty) As %Boolean
{
	set tDynamicObjectProjectionMode=pCompiledProperty.Parameters.GetAt($$$ArrayDynamicObjectProjectionModeParameter)
	quit:tDynamicObjectProjectionMode="" ..IsSerializeArraysAsDynamicArraysMode //Value not set default to class default.
	quit:tDynamicObjectProjectionMode=$$$DynamicJSONArrayProjection 1
	quit:tDynamicObjectProjectionMode=$$$DynamicNativeProjection 0
	quit ..IsSerializeArraysAsDynamicArraysMode //Value was not set to a valid setting set to class default.
}

/// Returns a quoted dynamic object field name.
Method MakeDynamicObjectSourceFieldName() As %String [ Private ]
{
	set tFieldName=..GetCompiledPropertyOutputName(..CompiledProperty)
	quit ..MakeQuotedValue(tFieldName)
}

/// Adds double quotes to pValue before and afterwards.
Method MakeQuotedValue(pValue As %String) As %String [ Private ]
{
	quit """" _ pValue _ """"
}

/// Returns seperator for field and value in dynamic objects
Method MakeDynamicObjectSourceOpeningFieldValueSeperator() As %String [ Private ]
{
	quit ":"
}

/// Generates the Dynamic Object source code needed to get the value of the current<br>
/// ..CompiledProperty
Method GenerateDynamicObjectFieldValueSource() As %String [ Private ]
{
	if (..IsManyRelationShip(..CompiledProperty)) {
		quit "(..GenerateManyRelationshipDynamicObjects("_..PropertyValueReferenceString_",.sc))"
	} elseif ..IsArray(..CompiledProperty) {
		if ..IsCurrentPropertySerializeEmbededObjectsMode {
			if ..IsPropertyNotDT {
				quit "(..GenerateArrayOfObjDynamicArray("_..PropertyValueReferenceString_",.sc))"
			} else {
				quit "(..GenerateArrayOfDTDynamicArray($This,"_..MakeQuotedValue(..CompiledProperty.Name)_","_
														..PropertyValueReferenceString_"))"
			}
		} else {
			if ..IsPropertyNotDT {
				quit "(..GenerateArrayOfObjDynamicObj("_..PropertyValueReferenceString_",.sc))"
			} else {
				quit "(..GenerateArrayOfDTDynamicObj($This,"_..MakeQuotedValue(..CompiledProperty.Name)_","_
														..PropertyValueReferenceString_"))"
			}
		}
	} elseif ..IsList(..CompiledProperty) {
		if ..IsPropertyNotDT {
			quit "(..GenerateListOfObjDynamicObj("_..PropertyValueReferenceString_",.sc))"
		} else {
			quit "(..GenerateListOfDTDynamicObj($This,"_..MakeQuotedValue(..CompiledProperty.Name)_","_
												..PropertyValueReferenceString_"))"
		}
	} elseif (..IsPropertyNotDT) { //Embeded object
		if (..IsPersistentEmbededObjectType(..CompiledProperty) && (('..IsSerializeEmbededObjectsMode) || (..IsOneOrChildRelationShip(..CompiledProperty)))) {
			quit "("_
						"$CASE("_
							"$ISOBJECT("_..PropertyValueReferenceString_"),"_
							"1:"_..PropertyValueReferenceString_".%Id(),"_
							":$$$NULLOREF"_
						")"_
					")"
		} else {
			quit "("_
						"$CASE("_
							"$ISOBJECT("_..PropertyValueReferenceString_"),"_
							"1:"_
									"$CASE("_..PropertyValueReferenceString_".%Extends(""%Stream.Object""),"_
											"1:..CopyStreamToString("_..PropertyValueReferenceString_"),"_
											":"_..PropertyValueReferenceString_".ToDynamicObjRecursive(.sc)),"_
							":$$$NULLOREF"_
						")"_
					")"
					
					//"1:"_..PropertyValueReferenceString_".ToDynamicObjRecursive(.sc),"_
		}
	} else {
		//Plain datatype
		if ..IsLogicalToXSDCapable(..CompiledProperty) {
			quit "(..GetLogicalToXSDValue($This,"_..MakeQuotedValue(..CompiledProperty.Name)_","_
											..PropertyValueReferenceString_")"_
				")"
		} else {
			quit "("_..PropertyValueReferenceString_")"
		}
	}
	quit """""" //Never going to reach this quit
}

/// Returns the name of the dynamic object property name to be setup for pCompiledProperty.
Method GetCompiledPropertyOutputName(pCompiledProperty As %Dictionary.CompiledProperty) As %String [ Private ]
{
	quit pCompiledProperty.Name
}

/// Determines if pCompiledProperty is a many/children relationship reference.
Method IsManyRelationShip(pCompiledProperty As %Dictionary.CompiledProperty) As %Boolean [ Private ]
{
	quit ((pCompiledProperty.Cardinality="many") || (pCompiledProperty.Cardinality="children"))
}

/// Determines if pCompiledProperty is a "array of".
Method IsArray(pCompiledProperty As %Dictionary.CompiledProperty) As %Boolean [ Private ]
{
	quit ((pCompiledProperty.Collection="array") && (pCompiledProperty.Cardinality=""))
}

/// Determines if pCompiledProperty is a "list of".
Method IsList(pCompiledProperty As %Dictionary.CompiledProperty) As %Boolean [ Private ]
{
	quit ((pCompiledProperty.Collection="list") && (pCompiledProperty.Cardinality=""))
}

/// Determines if pCompiledProperty is a type of embeded object, i.e. it is not a flat data type<br>
/// i.e. like string
Method IsEmbededObjectType(pCompiledProperty As %Dictionary.CompiledProperty) As %Boolean [ Private ]
{
	//We are opening the compiled type of the property to check if it is a data type.
	set tCompiledClass=##class(%Dictionary.CompiledClass).%OpenId(pCompiledProperty.Type,0)
	quit:tCompiledClass=$$$NULLOREF 0 //Relationships tend to compile together with the class, so their compiled classes are unavailable.
	quit tCompiledClass.ClassType'="datatype"
}

/// Returns true if the compiled property's type is a persistent type.
Method IsPersistentEmbededObjectType(pCompiledProperty As %Dictionary.CompiledProperty) As %Boolean [ Private ]
{
	//We are opening the compiled type of the property to check if it is a data type.
	set tCompiledClass=##class(%Dictionary.CompiledClass).%OpenId(pCompiledProperty.Type,0)
	quit:tCompiledClass=$$$NULLOREF 0 //Relationships tend to compile together with the class, so their compiled classes are unavailable.
	quit tCompiledClass.ClassType="persistent"
}

/// Determines if attempts should be made on pCompiledProperty to call LogicalToXSD when generating output
Method IsLogicalToXSDCapable(pCompiledProperty As %Dictionary.CompiledProperty) As %Boolean [ Private ]
{
	set tCompiledMethod=##class(%Dictionary.CompiledPropertyMethod).%OpenId(pCompiledProperty.%Id()_"||"_$$$LogicalToXSDMethodName,0)
	quit:tCompiledMethod=$$$NULLOREF 0
	quit 1
}

/// Returns closing tag for a dynamic object's source
Method MakeDynamicObjectSourceObjectCloseTag() As %String [ Private ]
{
	quit "}"
}

}
