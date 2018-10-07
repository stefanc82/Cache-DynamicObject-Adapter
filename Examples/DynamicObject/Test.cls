/// A class containing the test methods
Class Examples.DynamicObject.Test Extends %RegisteredObject [ DependsOn = Examples.DynamicObject.Person ]
{

/// set sc = ##class(Examples.DynamicObject.Test).PopulateTestDate()
ClassMethod PopulateTestDate() As %Status
{
	set sc = $$$OK
	try
	{
		// Create son
		set tSon = ##class(Examples.DynamicObject.Person).%New()
		set tSon.Name = "James"
		set tSon.Surname = "Smth"
		set tSonAddr = ##class(Examples.DynamicObject.Address).%New()
		set tSonAddr.Line1 = "123 Noville Ave."
		set tSonAddr.City = "Nowhere"
		set tSonAddr.PostalCode = "00000"
		do tSon.Addresses.SetAt(tSonAddr, "college")
		set tSonAddrH = ##class(Examples.DynamicObject.Address).%New()
		set tSonAddrH.Line1 = "158 Middle Ave."
		set tSonAddrH.City = "Nowhere"
		set tSonAddrH.PostalCode = "00000"
		do tSon.Addresses.SetAt(tSonAddr, "home")
		do tSon.FavouriteCars.SetAt("Mercedes Benz", tSon.FavouriteCars.Count()+1)
		do tSon.FavouriteCars.SetAt("BMW", tSon.FavouriteCars.Count()+1)
		$$$ThrowOnError(tSon.%Save())
		
		// Create daughter
		set tDaughter = ##class(Examples.DynamicObject.Person).%New()
		set tDaughter.Name = "Jenny"
		set tDaughter.Surname = "Smth"
		set tDaughterAddr = ##class(Examples.DynamicObject.Address).%New()
		set tDaughterAddr.Line1 = "158 Middle Ave."
		set tDaughterAddr.City = "Nowhere"
		set tDaughterAddr.PostalCode = "00000"
		do tDaughter.Addresses.SetAt(tDaughterAddr, "home")
		do tDaughter.FavouriteCars.SetAt("Toyota", tDaughter.FavouriteCars.Count()+1)
		$$$ThrowOnError(tDaughter.%Save())
		
		// Create mother
		set tMom = ##class(Examples.DynamicObject.Person).%New()
		set tMom.Name = "Barbara"
		set tMom.Surname = "Smth"
		set tMomAddr = ##class(Examples.DynamicObject.Address).%New()
		set tMomAddr.Line1 = "158 Middle Ave."
		set tMomAddr.City = "Nowhere"
		set tMomAddr.PostalCode = "00000"
		do tMom.Addresses.SetAt(tMomAddr, "home")
		do tMom.FavouriteCars.SetAt("Jeep", tMom.FavouriteCars.Count()+1)
		do tMom.Dependants.SetAt(tSon, tMom.Dependants.Count()+1)
		do tMom.Dependants.SetAt(tDaughter, tMom.Dependants.Count()+1)
		$$$ThrowOnError(tMom.%Save())
		
	} catch tEx {
		set:(sc=$$$OK) sc = tEx.AsStatus()
		write "Exception: " _ $System.Status.GetErrorText(sc)
	}
	quit sc
}

/// set sc = ##class(Examples.DynamicObject.Test).SerializePersonToDO("Barbara", .tDO)
ClassMethod SerializePersonToDO(pName As %String, ByRef pDO As %Library.DynamicObject) As %Status
{
	set sc = $$$OK
	set pDO = ""
	try
	{
		set tName = pName
		set tID = 0
		
		&sql(select top 1 ID into :tID from Examples_DynamicObject.Person where Name = :tName)
		if ((SQLCODE'=0) && (SQLCODE'=100)) {
			throw ##class(%Exception.SQL).CreateFromSQLCODE(SQLCODE, %msg)
		}
		
		set tPerson = ##class(Examples.DynamicObject.Person).%OpenId(tID)
		set tDO = ##class(%DynamicObject).%New()
		set sc = tPerson.ToDynamicObj(.tDO)
		set pDO = tDO
		
		write "Play around with the DynamicObject returned",!
		write "You can finally do ""w tDO.%ToJSON()""",!
		write "Once done, update the person class to NOT serialize embedded persistent objects and run this test again.",!
		
	} catch tEx {
		set:(sc=$$$OK) sc = tEx.AsStatus()
		write "Exception: " _ $System.Status.GetErrorText(sc)
	}
	quit sc
}

/// This test assumes the ID values of James, Jenny and Barbara is 1, 2 and 3
/// set tJSONData = "{""ID"": ""3"",""Addresses"": {""home"": {""City"": ""Nowhere"",""Line1"": ""158 Middle Ave."",""Line2"": """",""PostalCode"": ""00000""}},""Dependants"": [""1"",""2"",""3""],""FavouriteCars"": [""Corvette"",""Porsche""],""Name"": ""Dave"",""Surname"": ""Smth""}"<br>
/// set sc = ##class(Examples.DynamicObject.Test).DeserializePersonFromJSON(tJSONData, .tPerson)
ClassMethod DeserializePersonFromJSON(pJSONData As %String(MAXLEN=""), ByRef pPerson As Examples.DynamicObject.Person) As %Status
{
	set sc = $$$OK
	set pDO = ""
	try
	{
		set tDO = ##class(%DynamicObject).%FromJSON(pJSONData)
						
		set tPerson = ##class(Examples.DynamicObject.Person).%New()
		set sc = tPerson.FromDynamicObj(.tDO)
		
		set pPerson = tPerson
		write "Play around with the Person Object returned",!
		write "You can finally do ""w tPerson.%Save()""",!
		
	} catch tEx {
		set:(sc=$$$OK) sc = tEx.AsStatus()
		write "Exception: " _ $System.Status.GetErrorText(sc)
	}
	quit sc
}

}
