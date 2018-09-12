compareStrings(Str1,Str2) :- .term2string(Str1,T1) & .term2string(Str2,T2) & (T1==T2).

my_role(Role,CurrentRole):- .my_name(Me) & default::play(Me,CurrentRole,g1) & CurrentRole == Role.

am_I_at_right_position(Lat,Lon) :- default::lat(CurrentLat) & (Lat == CurrentLat) & default::lon(CurrentLon) & (Lon == CurrentLon).

farthest_facility(List, Facility) :- default::role(Role, _, _, _, _, _, _, _, _, _, _) & actions.farthest(Role, List, Facility).
closest_facility(List, Facility) :- default::role(Role, _, _, _, _, _, _, _, _, _, _) & actions.closest(Role, List, Facility).
closest_facility(List, Facility1, Facility2) :- default::role(Role, _, _, _, _, _, _, _, _, _, _) & actions.closest(Role, List, Facility1, Facility2).
closest_facility(List, Lat, Lon, Facility2) :- default::role(Role, _, _, _, _, _, _, _, _, _, _) & actions.closest(Role, List, Lat, Lon, Facility2).

closest_facility_truck(List, Facility1, Facility2) :-actions.closest(truck, List, Facility1, Facility2).
closest_facility_truck(List, Lat, Lon, Facility2) :- actions.closest(truck, List, Lat, Lon, Facility2).

enough_battery(FacilityId1, FacilityId2, Result) :- default::role(Role, Speed, _, _, _, _, _, _, _, _, _) & actions.route(Role, Speed, FacilityId1, RouteLen1) & actions.route(Role, Speed, FacilityId1, FacilityId2, RouteLen2) & default::charge(Battery) & ((Battery > (RouteLen1 + RouteLen2) & Result = "true") | (Result = "false")).
enough_battery(Lat, Lon, FacilityId2, Result) :- default::role(Role, Speed, _, _, _, _, _, _, _, _, _) & actions.route(Role, Speed, Lat, Lon, _, _, _, RouteLen1) & actions.route(Role, Speed, Lat, Lon, FacilityId2, _, RouteLen2)  & default::charge(Battery) & ((Battery > (RouteLen1 + RouteLen2) & Result = "true") | (Result = "false")).
enough_battery2(FacilityAux, FacilityId1, FacilityId2, Result, Battery) :- default::role(Role, Speed, _, _, _, _, _, _, _, _, _) & actions.route(Role, Speed, FacilityAux, FacilityId1, RouteLen1) & actions.route(Role, Speed, FacilityId1, FacilityId2, RouteLen2) & ((Battery > (RouteLen1 + RouteLen2) & Result = "true") | (Result = "false")).
enough_battery2(FacilityAux, Lat, Lon, FacilityId2, Result, Battery) :- default::role(Role, Speed, _, _, _, _, _, _, _, _, _) & actions.route(Role, Speed, FacilityAux, Lat, Lon, RouteLen1) & actions.route(Role, Speed, Lat, Lon, FacilityId2, _, RouteLen2) & ((Battery > (RouteLen1 + RouteLen2) & Result = "true") | (Result = "false")).
enough_battery_charging(FacilityId, Result) :- default::role(Role, Speed, _, _, _, _, _, _, _, _, _) & actions.route(Role, Speed, FacilityId, RouteLen) & default::charge(Battery) & ((Battery > RouteLen & Result = "true") | (Result = "false")).
enough_battery_charging2(FacilityAux, FacilityId, Result, Battery) :- default::role(Role, Speed, _, _, _, _, _, _, _, _, _) & actions.route(Role, Speed, FacilityAux, FacilityId, RouteLen) & ((Battery > RouteLen & Result = "true") | (Result = "false")).

getFacility(FacilityId,Flat,Flon,LatAux,LonAux):- default::shop(FacilityId, LatAux, LonAux) & Flat=LatAux & Flon=LonAux.
getFacility(FacilityId,Flat,Flon,LatAux,LonAux):- default::storage(FacilityId, LatAux, LonAux,_,_,_) & Flat=LatAux & Flon=LonAux.
getFacility(FacilityId,Flat,Flon,LatAux,LonAux):- default::dump(FacilityId,LatAux,LonAux) & Flat=LatAux & Flon=LonAux.
getFacility(FacilityId,Flat,Flon,LatAux,LonAux):- default::workshop(FacilityId,LatAux,LonAux) & Flat=LatAux & Flon=LonAux.

// from the predicate list required(ItemName,Qtd), returns a list containing only the items' name
get_items_names([],Temp,NewItems):- NewItems = Temp.
get_items_names([required(Item,_)|Items],Temp,NewItems) :- get_items_names(Items,[Item|Temp],NewItems).
get_items_names(Items,NewItems) :- get_items_names(Items,[],NewItems).

// has enough money to buy a well
enough_money :- default::massium(Money) & strategies::minimum_money(RequiredMoney) & Money >= RequiredMoney.

// select what base item is needed most and pick a resource node to go
select_resource_node(SelectedResource)
:-
	default::desired_base(List) &
	remove_unknown_bases(List,[],PrunedList) &
	sum_percentages(PrunedList,Total) & .random(N) &
	chosen_item(PrunedList, 0, (N * Total), item(_,Name,_)) &
//	.print("<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< TEST >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>\n") &
//	.print("[ TEST ] Pruned List: ",PrunedList) &
//	.print("[ TEST ] Sun of Percentages (Total): ",Total,"\n | Random Number [0 to Total]: ",(N*Total),"\n | Chosen Item: ",Name,"\n") &
	.findall(ResourceNode,default::resNode(ResourceNode,Lat,Lon,Name),Resources) & 
	closest_facility(Resources,SelectedResource)
	.

// count(item(Priority,Name,Quantity)|L], Total)
sum_percentages([],0).
sum_percentages([item(P,I,Q)|L], Total) :- sum_percentages(L,T) & Total = T + P.

chosen_item([Item|[]],_,_,Item).
chosen_item([item(P,N,Q)|L], Temp, R, item(P,N,Q)):- (P + Temp) > R.
chosen_item([item(P,N,Q)|L], Temp, R, Item) :- chosen_item(L, P + Temp, R, Item).

remove_unknown_bases([],AuxList,PrunedList) :- PrunedList = AuxList.	
remove_unknown_bases([item(X,Base,Y)|List],AuxList,PrunedList) :- default::resNode(_,_,_,Base) & remove_unknown_bases(List,[item(X,Base,Y)|AuxList],PrunedList).
remove_unknown_bases([item(X,Base,Y)|List],AuxList,PrunedList) :- remove_unknown_bases(List,AuxList,PrunedList).

can_I_bid
:-
	not default::biding(_) &
	not strategies::winner(_,_,_,_,_) & // assembly winner
	not strategies::winner(_,_,_) // delivery winner
	.
