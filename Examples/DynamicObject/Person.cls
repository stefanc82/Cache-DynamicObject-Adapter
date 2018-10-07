/// A sample person class to demonstrate the capabilities of the DynamicObject adapter
Class Examples.DynamicObject.Person Extends (%Persistent, MasterLib.Utils.DynamicObject.Adapter)
{

/// Will serialize references persistent objects in to dynamic object. Set to 0 and retest to see the difference
Parameter SerializeEmbeddedPersistentObjects = 1;

Property Name As %String(MAXLEN = 40) [ Required ];

Property Surname As %String(MAXLEN = 100) [ Required ];

/// Will project as an array of objects
Property Addresses As array Of Examples.DynamicObject.Address(ArrayDynamicObjectMode = "native");

/// Will discard the key during projection as it is not relevant
Property Dependants As array Of Examples.DynamicObject.Person;

/// Shows a List projection
Property FavouriteCars As list Of %String(MAXLEN = 60);

/// Will not be serialised
Property DateTimeStamp As %TimeStamp(BlockDOProjection = 1) [ InitialExpression = {$zdatetime($Horolog,3)}, Required ];

Storage Default
{
<Data name="Addresses">
<Attribute>Addresses</Attribute>
<Structure>subnode</Structure>
<Subscript>"Addresses"</Subscript>
</Data>
<Data name="Dependants">
<Attribute>Dependants</Attribute>
<Structure>subnode</Structure>
<Subscript>"Dependants"</Subscript>
</Data>
<Data name="PersonDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>Name</Value>
</Value>
<Value name="3">
<Value>Surname</Value>
</Value>
<Value name="4">
<Value>FavouriteCars</Value>
</Value>
<Value name="5">
<Value>DateTimeStamp</Value>
</Value>
</Data>
<DataLocation>^Examples.DynamicObject.PersonD</DataLocation>
<DefaultData>PersonDefaultData</DefaultData>
<IdLocation>^Examples.DynamicObject.PersonD</IdLocation>
<IndexLocation>^Examples.DynamicObject.PersonI</IndexLocation>
<StreamLocation>^Examples.DynamicObject.PersonS</StreamLocation>
<Type>%Library.CacheStorage</Type>
}

}
