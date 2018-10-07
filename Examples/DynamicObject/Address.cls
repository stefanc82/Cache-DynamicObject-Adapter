/// Serial Object to store an address of a person
Class Examples.DynamicObject.Address Extends (%SerialObject, MasterLib.Utils.DynamicObject.Adapter)
{

Property Line1 As %String(MAXLEN = 100) [ Required ];

Property Line2 As %String(MAXLEN = 100);

Property City As %String [ Required ];

/// The StringRgx datatype can be used here to enforce numeric values
Property PostalCode As %String(MAXLEN = 5);

Storage Default
{
<Data name="AddressState">
<Value name="1">
<Value>Line1</Value>
</Value>
<Value name="2">
<Value>Line2</Value>
</Value>
<Value name="3">
<Value>City</Value>
</Value>
<Value name="4">
<Value>PostalCode</Value>
</Value>
</Data>
<State>AddressState</State>
<StreamLocation>^Examples.DynamicOb9AA4.AddressS</StreamLocation>
<Type>%Library.CacheSerialState</Type>
}

}
