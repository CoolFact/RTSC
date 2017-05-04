/**
 *  - CopytoClipboard
 * 
 * Author: 
 * 
 * Description:
 * Not given
 * 
 * Parameter(s):
 * 0: None <Any>
 * 
 * Return Value:
 * None <Any>
 * 
 
COOL_fnc_SaveUnits = {
	// -------------------  Init  ----------------------- //
	_countThis = count _this;

	// ----------------  Parameters  -------------------- //
	_unit = _this select 0;
	_pos = _this select 1;

	// --  Delete the unit (this is always done ASAP)  -- //
	_unitArray = [];
	_unitGroup = group _unit;
	_unitsInGroup = units _unitGroup;
	_unitCount = count _unitsInGroup;
	_unitsInGroupAdd = [];
	_side = side _unitGroup;

	while { _unitCount > 0 } do { 
		// The currently worked on unit
		_unitsInGroup = units _unitGroup;
		_unit = _unitsInGroup select 0;
		_unitCount = count _unitsInGroup;
		// Check if its a vehicle
		if ( (vehicle _unit) isKindOf "LandVehicle" OR ((vehicle _unit) isKindOf "Air")) then { 
			_vcl = vehicle _unit;
			if (!(_vcl in _unitsInGroupAdd) AND (typeOf _vcl != "")) then {
				_unitsIngroupAdd set [count _unitsInGroupAdd, _vcl];
				_unitCrewArray = [];
				_crew = crew _vcl;
				{ _unitCrewArray set [count _unitCrewArray, typeOf _x]; } forEach _crew;
				_unitInfoArray = [typeOf _vcl,vehicleVarName _vcl,weapons _vcl,magazines _vcl,_unitCrewArray];
				_unitArray set [count _unitArray, _unitInfoArray];
				deleteVehicle _vcl;
				{ deleteVehicle _x; } forEach _crew;
			};
		}
		// Otherwise its infantry
		else {
			_unitInfoArray = [typeOf _unit,vehicleVarName _unit,weapons _unit,magazines _unit,[]]; 
			_unitArray set [count _unitArray, _unitInfoArray];
			deleteVehicle _unit;
		};
		//sleep 1; //Broke ????
	};
	deleteGroup _unitGroup;
	[_unitGroup,_side,_pos] call COOL_fnc_SpawnGroup;
	//systemchat format["%1",_unitArray];
};


COOL_fnc_SpawnGroup = {
	// We need to pass the old group so we can copy waypoints from it, the rest we already know
	_oldGroup = _this select 0;
	_side = _this select 1;
	_newGroup = createGroup _side;
	_coordpoint = _this select 2;
	//_waypointsArray = _this select 2;
	// If the old group doesnt have any units in it its a spawned group rather than respawned
	if ( count (units _oldGroup) == 0) then { deleteGroup _oldGroup; };
	//Find nearest spawnpoint
	_closestPoint = [COOL_VAR_Sector,[],{_coordpoint distance2d (getMarkerPos _x)},"ASCEND"] call BIS_fnc_sortBy;
 	 //systemchat format["closestPoint:%1",_closestPoint];
	_spwnPos = getMarkerPos format["%1",_closestPoint select 0];
	_spwnDir = markerDir format["%1",_closestPoint select 0];
	
	
	{
		_spawnUnit = Object;
		_spawnVeh = Object;
		_unitType = _x select 0; 
		_unitName = _x select 1; 
		_unitWeapons = _x select 2; 
		_unitMagazines = _x select 3; 
		_unitCrew = _x select 4;
		// Check if the unit has a crew, if so we know its a vehicle
		if (count _unitCrew > 0) then { 
			if (_spwnPos select 2 >= 10) then { 
				_spawnVeh = createVehicle [_unitType,_spwnPos, [], 0, "FLY"]; 
				curatorModule addCuratorEditableObjects [[_spawnVeh]];
				_spawnVeh setVelocity [50 * (sin _spwnDir), 50 * (cos _spwnDir), 0];
			}
			else {
				 _spawnVeh = _unitType createVehicle _spwnPos; 
				curatorModule addCuratorEditableObjects [[_spawnVeh]];
			};
			// Create the entire crew
			_crew = [];
			//_turrets = [configFile >> "CfgVehicles" >> _unitType >> "turrets"] call COOL_fnc_returnVehicleTurrets;
     		{ 
     			_unit = _newGroup createUnit [_x, getPos _spawnVeh, [], 0, "NONE"]; 
     			curatorModule addCuratorEditableObjects [[_unit]];
     			_crew set [count _crew, _unit]; 
     		} forEach _unitCrew;
	      	// We assume that all vehicles have a driver, the first one of the crew
			(_crew select 0) moveInDriver _spawnVeh;
			// Count the turrets and move the men inside	      	
	      	//[_turrets, [], 1, _crew, _spawnUnit,_newGroup] call COOL_fnc_moveInTurrets; 	
	      	_spawnVeh setDir _spwnDir;
			_spawnVeh setVehicleVarName _unitName;   	
		}
		// Otherwise its infantry
		else { 
			_spawnUnit = _newGroup createUnit [_unitType,_spwnPos, [], 0, "NONE"]; 
			curatorModule addCuratorEditableObjects [[_spawnUnit]];
			removeAllWeapons _spawnUnit;
			{_spawnUnit removeMagazine _x} forEach magazines _spawnUnit;
			removeAllItems _spawnUnit;
			{_spawnUnit addMagazine _x} forEach _unitMagazines;
			{_spawnUnit addWeapon _x} forEach _unitWeapons;
			_spawnUnit selectWeapon (primaryWeapon _spawnUnit);
			_spawnUnit setDir _spwnDir;
		_spawnUnit setVehicleVarName _unitName;
		};
		// Set all the things common to the spawned unit
		
	} forEach _unitArray;
	
 
 // -----------------  Functions  -------------------- //

// *WARNING* BIS FUNCTION RIPOFF - Taken from fn_returnConfigEntry as its needed for turrets and shortened a bit
COOL_fnc_returnConfigEntry = {
	private ["_config", "_entryName","_entry", "_value"];
	_config = _this select 0;
	_entryName = _this select 1;
	_entry = _config >> _entryName;
	//If the entry is not found and we are not yet at the config root, explore the class' parent.
	if (((configName (_config >> _entryName)) == "") && (!((configName _config) in ["CfgVehicles", "CfgWeapons", ""]))) then {
		[inheritsFrom _config, _entryName] call COOL_fnc_returnConfigEntry;
	}
	else { if (isNumber _entry) then { _value = getNumber _entry; } else { if (isText _entry) then { _value = getText _entry; }; }; };
	//Make sure returning 'nil' works.
	if (isNil "_value") exitWith {nil};
	_value;
};
	
// *WARNING* BIS FUNCTION RIPOFF - Taken from fn_fnc_returnVehicleTurrets and shortened a bit
COOL_fnc_returnVehicleTurrets = {
	private ["_entry","_turrets", "_turretIndex"];
	_entry = _this select 0;
	_turrets = [];
	_turretIndex = 0;
	//Explore all turrets and sub-turrets recursively.
	for "_i" from 0 to ((count _entry) - 1) do {
		private ["_subEntry"];
		_subEntry = _entry select _i;
		if (isClass _subEntry) then {
			private ["_hasGunner"];
			_hasGunner = [_subEntry, "hasGunner"] call COOL_fnc_returnConfigEntry;
			//Make sure the entry was found.
			if (!(isNil "_hasGunner")) then {
				if (_hasGunner == 1) then {
					_turrets = _turrets + [_turretIndex];		
					//Include sub-turrets, if present.
					if (isClass (_subEntry >> "Turrets")) then { _turrets = _turrets + [[_subEntry >> "Turrets"] call COOL_fnc_returnVehicleTurrets]; } 
					else { _turrets = _turrets + [[]]; };
				};
			};
			_turretIndex = _turretIndex + 1;
		};
	};
	_turrets;
};

COOL_fnc_moveInTurrets = {	
	private ["_turrets","_path","_i"];
	_turrets = _this select 0;
	_path = _this select 1;
	_currentCrewMember = _this select 2;
	_crew = _this select 3;
	_spawnUnit = _this select 4;
	_newGroup = _this select 5;
	_i = 0;  
	
	if (count _turrets > (count _crew) -1) then {
		_Unitdiff = (count _turrets) - ((count _crew) -1);
		for "_i" from 0 to _Unitdiff do {
			_unit = _newGroup createUnit [typeOf(_crew select 0), getPos _spawnUnit, [], 0, "NONE"]; 
			curatorModule addCuratorEditableObjects [[_unit]];
			_crew set [count _crew, _unit]; 
		};
	};
	
  
	while {_i < (count _turrets)} do { 
		 _turretIndex = _turrets select _i;
		_thisTurret = _path + [_turretIndex];
		(_crew select _currentCrewMember) moveInTurret [_spawnUnit, _thisTurret]; _currentCrewMember = _currentCrewMember + 1;
		//Spawn units into subturrets.
		[_turrets select (_i + 1), _thisTurret, _currentCrewmember, _crew, _spawnUnit] call COOL_fnc_moveInTurrets;
		_i = _i + 2;
	};
};

// This is the general cleanup function running in the background for the group, replaces the removebody eventhandler and delete group in V5
COOL_fnc_cleanGroup = {
	_group = _this select 0;
	_unitsGroup = units _group;
	_sleep = _this select 1;
	// Hold until the entire group is dead
	while { ({alive _x} count _unitsGroup) > 0 } do { sleep 5; };
	sleep _sleep;
	{
		_origPos = getPos _x;
		_z = _origPos select 2;
		_desiredPosZ = if ( (vehicle _x) iskindOf "Man") then { (_origPos select 2) - 0.5 } else { (_origPos select 2) - 3 };
		if ( vehicle _x == _x ) then {
			_x enableSimulation false;
			while { _z > _desiredPosZ } do { 
				_z = _z - 0.01;
				_x setPos [_origPos select 0, _origPos select 1, _z];
				sleep 0.1;
			};
		};
		deleteVehicle _x; 
		sleep 5;
	} forEach _unitsGroup;		
	// Now we know that all units are deleted
	deleteGroup _group;
};
 

 */

[[[[B Alpha 1-2:1,"driver",-1,[],false]],[[<NULL-object>,"gunner",-1,[2],false],[<NULL-object>,"gunner",-1,[3],false]],[],[]]]