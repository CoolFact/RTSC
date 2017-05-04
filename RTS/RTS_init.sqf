/**
 *  - RTS_init
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
_SpawnFnc = [] spawn compile PreprocessFileLineNumbers "RTS\COOL_RTS_SPWN_functions.sqf";
waitUntil {scriptDone _SpawnFnc};

COOL_RTS_VAR_TransWest = "B_Truck_01_transport_F";
COOL_RTS_VAR_TransEast = "O_Truck_03_transport_F";
COOL_RTS_VAR_TransInd = "I_Truck_02_transport_F";
COOL_RTS_VAR_BrokenVeh = [["B_T_LSV_01_armed_CTRG_F","B_T_LSV_01_armed_F"]];
null = [] spawn COOL_fnc_SpawnPoints;

