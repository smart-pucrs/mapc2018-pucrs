compareStrings(Str1,Str2) :- .term2string(Str1,T1) & .term2string(Str2,T2) & (T1==T2).

closest_facility(List, Facility) :- default::role(Role, _, _, _, _, _, _, _, _, _, _) & actions.closest(Role, List, Facility).
closest_facility(List, Facility1, Facility2) :- default::role(Role, _, _, _, _, _, _, _, _, _, _) & actions.closest(Role, List, Facility1, Facility2).
closest_facility(List, Lat, Lon, Facility2) :- default::role(Role, _, _, _, _, _, _, _, _, _, _) & actions.closest(Role, List, Lat, Lon, Facility2).

enough_battery(FacilityId1, FacilityId2, Result) :- default::role(Role, Speed, _, _, _, _, _, _, _, _, _) & actions.route(Role, Speed, FacilityId1, RouteLen1) & actions.route(Role, Speed, FacilityId1, FacilityId2, RouteLen2) & default::charge(Battery) & ((Battery > (RouteLen1 + RouteLen2) & Result = "true") | (Result = "false")).
enough_battery(Lat, Lon, FacilityId2, Result) :- default::role(Role, Speed, _, _, _, _, _, _, _, _, _) & actions.route(Role, Speed, Lat, Lon, _, _, _, RouteLen1) & actions.route(Role, Speed, Lat, Lon, FacilityId2, _, RouteLen2)  & default::charge(Battery) & ((Battery > (RouteLen1 + RouteLen2) & Result = "true") | (Result = "false")).
enough_battery2(FacilityAux, FacilityId1, FacilityId2, Result, Battery) :- default::role(Role, Speed, _, _, _, _, _, _, _, _, _) & actions.route(Role, Speed, FacilityAux, FacilityId1, RouteLen1) & actions.route(Role, Speed, FacilityId1, FacilityId2, RouteLen2) & ((Battery > (RouteLen1 + RouteLen2) & Result = "true") | (Result = "false")).
enough_battery2(FacilityAux, Lat, Lon, FacilityId2, Result, Battery) :- default::role(Role, Speed, _, _, _, _, _, _, _, _, _) & actions.route(Role, Speed, FacilityAux, Lat, Lon, RouteLen1) & actions.route(Role, Speed, Lat, Lon, FacilityId2, _, RouteLen2) & ((Battery > (RouteLen1 + RouteLen2) & Result = "true") | (Result = "false")).
enough_battery_charging(FacilityId, Result) :- default::role(Role, Speed, _, _, _, _, _, _, _, _, _) & actions.route(Role, Speed, FacilityId, RouteLen) & default::charge(Battery) & ((Battery > RouteLen & Result = "true") | (Result = "false")).
enough_battery_charging2(FacilityAux, FacilityId, Result, Battery) :- default::role(Role, Speed, _, _, _, _, _, _, _, _, _) & actions.route(Role, Speed, FacilityAux, FacilityId, RouteLen) & ((Battery > RouteLen & Result = "true") | (Result = "false")).
