# Cache, Ensemble and IRIS DynamicObject adapter
A package of classes that can "serialize" and "deserialize" class instances to and from DynamicObject instances

##### Key Features
 + "Serialize" any object that extends from the adapter into a DynamicObject.
 + "Deserialize" a DynamicObject to an instance of an object that extends the adapter.
 + Serialize embedded object references recursively.
 + Block the projection of a property.
 + Control how arrays are projected. As objects (native) or JSON arrays (jsonarray)
 + Populate arrays and lists of serial objects within another object in a songle call.

## Installation
Import into yout project. Compile the MasterLib.Util.DynamicObject package prior to compiling the classes where it will be used.

## Examples
See the Examples.DynamicObject package for usage examples.
