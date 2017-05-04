/**
 *  - COOL_RTS_SPWN_functions
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
 */

curatorModule addEventHandler [
	"CuratorObjectPlaced",
	{	
		_Object = _this select 1;
		_Grp = group _Object;
		
		//Control if unit is in vehicle
		_units = crew _Object;
		if (count _units < 1) then{
			_units = [_Object];
		};
		
		//Control Run function only with group leader
		if ( leader _Grp in _units) then {
			_pos = AGLToASL (screenToWorld getMousePosition);
			_vcl = [];
			_vclcontrol = [];
			//systemchat format["Work"];
			_closestPoint = [COOL_VAR_Sector,[],{_pos distance2d (getMarkerPos _x)},"ASCEND"] call BIS_fnc_sortBy;
 	 		//systemchat format["closestPoint:%1",_closestPoint];
			_spwnPos = getMarkerPos format["%1",_closestPoint select 0];
			_spwnDir = markerDir format["%1",_closestPoint select 0];
			{
				_unit = _x;
				_xrandom = random [-75, 0, 75] ;
				_yrandom = random [-75, 0, 75] ;
				vehicle _unit SetPos [(_spwnPos select 0) + _xrandom,(_spwnPos select 1) + _yrandom, _spwnPos select 2];
				vehicle _unit SetDir _spwnDir;
				if ((vehicle _unit) isKindOf "LandVehicle" OR ((vehicle _unit) isKindOf "Air")) then { 
					if (!(vehicle _unit in _vclcontrol)) then {
						_veh = (vehicle _unit);
						_vclcontrol pushback _veh;
						
						// --- Group Sorting --- Makes sure armed vehicle is in own group
						if ((count crew _veh <= 1)  && (count units _Grp > count crew _veh)) then { //&& (leader _unit in crew _veh)
							moveOut _unit;
							_Grp leaveVehicle _veh;	
							if (typeof _veh in COOL_RTS_VAR_BrokenVeh)	then {
								{
									if (typeof _veh == _x select 0) then {
										_pos1 = position _veh;
										deletevehicle _veh;
										_veh = _x select 1 createVehicle _pos1;
									};
								} foreach COOL_RTS_VAR_BrokenVeh;
							} else {
								createVehicleCrew _veh;	
							};	
							_newgroup = group driver _veh;
							systemchat format ["%1",_newgroup];
							{
								curatorModule addCuratorEditableObjects [[_x]];
							} foreach crew _veh;
						} else {
							_newgroup = creategroup side _unit;
							crew _veh joinSilent _newgroup;
							_Grp leaveVehicle _veh;	
						};						
					};
					//systemchat format ["%1",count units _Grp];
				};				
			} foreach units _Grp; 
			
			
			_Turrets = [];
			_Cargo = [];
			_Driver = [];
			_Commander = [];
			_emptyturrets = [];
			_emptycommander = [];
			_emptycargo = [];
			{
				_Turrets = fullCrew [_x,"gunner",true];
				_Cargo = fullCrew [_x,"cargo",true];
				_Driver = fullCrew [_x,"driver",true];
				_Commander = fullCrew [_x,"commander",true];
				
				_emptyturrets = _Turrets - fullCrew [_x,"gunner"];
				_emptycommander = _Commander - fullCrew [_x,"gunner"];
				_emptycargo = _Cargo - fullCrew [_x,"gunner"];
				_vcl pushback [_Driver,_Turrets,_Commander,_Cargo];
			} foreach _vclcontrol;
			
			//systemchat format["%1 <= %2 - %3",count (units _Grp), (count _emptyturrets)+(count _emptycommander)+(count _emptycargo),count (units _Grp)<= (count _emptyturrets)+(count _emptycommander)+(count _emptycargo)];
			if (count (units _Grp) <= (count _emptyturrets)+(count _emptycommander)+(count _emptycargo)) then {
				{	
					_x AssignAsCargo _veh;
					_x MoveInCargo _veh;
				} foreach units _Grp;
			} else {
				_vehclassname = "";
				_xrandom = random [-75, 0, 75] ;
				_yrandom = random [-75, 0, 75] ;
				switch (side leader _Grp) do {
   					case WEST: {_vehclassname = COOL_RTS_VAR_TransWest;};
    				case EAST: {_vehclassname = COOL_RTS_VAR_TransEast};
    				case resistance: {_vehclassname = COOL_RTS_VAR_TransInd};
				};
				//systemchat format ["Create transport: %1",_vehclassname];
				_veh1 = _vehclassname createVehicle [(_spwnPos select 0) + _xrandom,(_spwnPos select 1) + _yrandom, _spwnPos select 2];
				curatorModule addCuratorEditableObjects [[_veh1]];
				_veh1 setVariable ["BIS_enableRandomization", false];
				_veh1 SetDir _spwnDir;
				{	
					if (units _Grp select 0 == _x) then {
						_x MoveInDriver _veh1;
					} else {
						_x AssignAsCargo _veh1;
						_x MoveInCargo _veh1;
					};
				} foreach units _Grp;
			};
			_wp =_Grp addWaypoint [_pos, 2];
			_wp1 =_newgroup addWaypoint [_pos, 1];
		};
	} 
];

KK_fnc_inString = {
    /*
    Author: Killzone_Kid

    Description:
    Find a string within a string (case insensitive)

    Parameter(s):
    _this select 0: <string> string to be found
    _this select 1: <string> string to search in

    Returns:
    Boolean (true when string is found)

    How to use:
    _found = ["needle", "Needle in Haystack"] call KK_fnc_inString;
    */

    private ["_needle","_haystack","_needleLen","_hay","_found"];
    _needle = [_this, 0, "", [""]] call BIS_fnc_param;
    _haystack = toArray ([_this, 1, "", [""]] call BIS_fnc_param);
    _needleLen = count toArray _needle;
    _hay = +_haystack;
    _hay resize _needleLen;
    _found = false;
    for "_i" from _needleLen to count _haystack do {
        if (toString _hay == _needle) exitWith {_found = true};
        _hay set [_needleLen, _haystack select _i];
        _hay set [0, "x"];
        _hay = _hay - ["x"]
    };
    _found
};

COOL_fnc_SpawnPoints = {
	COOL_VAR_Sector = [];
	{
 		_found = ["COOL_RTS_spwn", _x] call KK_fnc_inString;
 		if _found then{
 			COOL_VAR_Sector pushback _x;
 		};
	} foreach allMapMarkers;
	//systemchat format["%1",COOL_VAR_Sector];
};



