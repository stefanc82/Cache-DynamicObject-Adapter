Include MasterLib.Utils.DynamicObject.Adapter

Class MasterLib.Utils.DynamicObject.AdapterToDynamicObjParameters [ Abstract ]
{

/// Property parameter which when applied to "array of" properties shall override the <br>
/// SerializeArraysAsDynamicArrays class parameter setting.
/// Has two values:
/// $$$DynamicJSONArrayProjection (which corresponds to "jsonarray"):
/// 	Projects the array of collection as a dynamic array, doing this discards key <br>
/// 		related information, which does not form part of the output.<br>
/// 
/// 
/// $$$DynamicNativeProjection (which corresponds to "native"):
/// 	Projects the array of collection as a dynamic object, doing this projects the key <br>
/// 		values as property names of the output dynamic object with their values being the array<br>
/// 		elements.
/// 
/// Value needs to be set explicitly to "jsonarray" / "native" (case sensitive)
Parameter ArrayDynamicObjectMode;

/// Property Parameter which blocks the projection of a property from cache class to dynamic object.
Parameter BlockDOProjection;

}
