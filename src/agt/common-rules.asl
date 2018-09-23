compareStrings(Str1,Str2) :- .term2string(Str1,T1) & .term2string(Str2,T2) & (T1==T2).

my_role(Role,CurrentRole):- .my_name(Me) & default::play(Me,CurrentRole,g1) & CurrentRole == Role.

am_I_at_right_position(Lat,Lon) :- default::lat(CurrentLat) & (Lat == CurrentLat) & default::lon(CurrentLon) & (Lon == CurrentLon).

farthest_facility(List, Facility) :- default::role(Role, _, _, _, _, _, _, _, _, _, _) & actions.farthest(Role, List, Facility).
closest_facility(List, Facility) :- default::role(Role, _, _, _, _, _, _, _, _, _, _) & actions.closest(Role, List, Facility).
closest_facility(List, Facility1, Facility2) :- default::role(Role, _, _, _, _, _, _, _, _, _, _) & actions.closest(Role, List, Facility1, Facility2).
closest_facility(List, Lat, Lon, Facility2) :- default::role(Role, _, _, _, _, _, _, _, _, _, _) & actions.closest(Role, List, Lat, Lon, Facility2).

closest_facility_truck(List, Facility1, Facility2) :-actions.closest(truck, List, Facility1, Facility2).
closest_facility_truck(List, Lat, Lon, Facility2) :- actions.closest(truck, List, Lat, Lon, Facility2).

my_route_closest_facility(List,Facility,Route) 
:- 
	default::role(Role, Speed, _, _, _, _, _, _, _, _, _) & 
	default::lat(Lat) &
	default::lon(Lon) &
	actions.closest(Role,List,Lat,Lon,Facility) &
	actions.route(Role,Speed,Lat,Lon,Facility,_,Route)
	.

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
enough_money :- default::massium(Money) & build::minimum_money(RequiredMoney) & Money >= RequiredMoney.

// select what base item is needed most and pick a resource node to go
select_resource_node(SelectedResource)
:-
	team::desired_base(List) &
	remove_unknown_bases(List,[],PrunedList) &
	.print("list pruned: ",PrunedList)&
	sum_percentages(PrunedList,Total) & 
	.random(N) &
	chosen_item(PrunedList, 0, (N * Total), item(_,Name,_)) &
//	.print("<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< TEST >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>\n") &
//	.print("[ TEST ] Pruned List: ",PrunedList) &
//	.print("[ TEST ] Sun of Percentages (Total): ",Total,"\n | Random Number [0 to Total]: ",(N*Total),"\n | Chosen Item: ",Name,"\n") &
	.findall(ResourceNode,team::resNode(ResourceNode,Lat,Lon,Name),Resources) & 
	closest_facility(Resources,SelectedResource)
	.

// count(item(Priority,Name,Quantity)|L], Total)
sum_percentages([],0).
sum_percentages([item(P,I,Q)|L], Total) :- sum_percentages(L,T) & Total = T + P.

chosen_item([Item|[]],_,_,Item).
chosen_item([item(P,N,Q)|L], Temp, R, item(P,N,Q)):- (P + Temp) > R.
chosen_item([item(P,N,Q)|L], Temp, R, Item) :- chosen_item(L, P + Temp, R, Item).

remove_unknown_bases([],AuxList,PrunedList) :- PrunedList = AuxList.	
remove_unknown_bases([item(X,Base,Y)|List],AuxList,PrunedList) :- team::resNode(_,_,_,Base) & X > 1 & remove_unknown_bases(List,[item(X,Base,Y)|AuxList],PrunedList).
remove_unknown_bases([item(X,Base,Y)|List],AuxList,PrunedList) :- remove_unknown_bases(List,AuxList,PrunedList).

can_I_bid
:-
	not strategies::winner(_,_,_,_,_) & // assembly winner
	not strategies::winner(_,_,_) // delivery winner
	.
am_I_winner
:-
	strategies::winner(_,_,_,_,_) | // assembly winner
	strategies::winner(_,_,_)
	.
	
estimate_route(Role,Speed,Battery,_,[],TemQty,QtySteps)
:-
	QtySteps = TemQty
	.
estimate_route(Role,Speed,Battery,location(Lat,Lon),[location(Facility)|Locations],TemQty,QtySteps)
:-
	new::chargingList(CList) & 
	actions.route(Role,Speed,Lat,Lon,Facility,_,RouteFacility) & 
	rules::closest_facility(CList,Facility,SafeHaven) &
	actions.route(Role,Speed,Facility,SafeHaven,RouteSafeHaven) & 
	Battery > (RouteFacility+RouteSafeHaven) & 
//	.print("tenho bateria my position ate ",Facility," bateria: ",Battery," rota: ",RouteFacility," safe haven: ",RouteSafeHaven)&
	estimate_route(Role,Speed,Battery-RouteFacility,location(Facility),Locations,TemQty+RouteFacility,QtySteps)
	.
estimate_route(Role,Speed,Battery,location(Lat,Lon),Locations,TemQty,QtySteps)
:-
//	.print("não tenho bateria my position ")&
	new::chargingList(CList) & 
	rules::closest_facility(CList,Lat,Lon,ChargingStation) & 
	actions.route(Role,Speed,Lat,Lon,ChargingStation,_,RouteFacility) & 
	default::maxBattery(MaxBattery) &
	default::chargingStation(ChargingStation,_,_,Rate) &
	StepsToRecharge = math.ceil(MaxBattery / Rate) &
//	.print("desvio ",StepsToRecharge," ",RouteFacility)&
	estimate_route(Role,Speed,MaxBattery,location(ChargingStation),Locations,TemQty+StepsToRecharge+RouteFacility,QtySteps)
	.
estimate_route(Role,Speed,Battery,location(Facility),[location(Destination)|Locations],TemQty,QtySteps)
:-
	new::chargingList(CList) & 	
	actions.route(Role,Speed,Facility,Destination,Route) & 
	rules::closest_facility(CList,Destination,SafeHaven) &
	actions.route(Role,Speed,Destination,SafeHaven,RouteSafeHaven) & 
	Battery > (Route+RouteSafeHaven) &
//	.print("tenho bateria ",Facility," ate ",Destination," bateria: ",Battery," rota: ",Route," safe haven: ",RouteSafeHaven)&
	estimate_route(Role,Speed,Battery-Route,location(Destination),Locations,TemQty+Route,QtySteps)
	.
estimate_route(Role,Speed,Battery,location(Facility),Locations,TemQty,QtySteps)
:-
//	.print("não tenho bateria ",Facility)&
	new::chargingList(CList) & 
	.member(Facility,CList) & // I'm already on a charging station I won't go to another
	estimate_route(Role,Speed,MaxBattery,location(ChargingStation),[],1000,QtySteps)
	.
estimate_route(Role,Speed,Battery,location(Facility),Locations,TemQty,QtySteps)
:-
//	.print("não tenho bateria ",Facility)&
	new::chargingList(CList) & 
	.difference(CList,[Facility],List) &
	rules::closest_facility(List,Facility,ChargingStation) & 
	actions.route(Role,Speed,Facility,ChargingStation,Route) & 
	default::maxBattery(MaxBattery) &
	default::chargingStation(ChargingStation,_,_,Rate) &
	StepsToRecharge = math.ceil(MaxBattery / Rate) &
//	.print("desvio ",StepsToRecharge," ",Route)&
	estimate_route(Role,Speed,MaxBattery,location(ChargingStation),Locations,TemQty+StepsToRecharge+Route,QtySteps)
	.
	
my_current_pos_is_valid
:-
	default::role(Role, Speed, _, _, _, _, _, _, _, _, _) & 
	actions.route(Role, Speed, storage0, RouteLen1)
	.
desired_pos_is_valid(Lat,Lon)
:-
	default::role(_,Speed,_,_,_,_,_,_,_,_,_) & 
	actions.route(truck,Speed,Lat,Lon,_,_,_,RouteLen1) &
	actions.route(truck,Speed,Lat,Lon,storage0,_,RouteLen2)
	.
