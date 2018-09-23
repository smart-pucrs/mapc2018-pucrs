+!goto(Facility)
	: .substring("node",Facility) & team::resNode(ResourceNode,Lat,Lon,Base)
<-
	!action::goto(Lat, Lon)
	.
	
	
// Goto (option 1)
// FacilityId must be a string
+!goto(FacilityId) : default::facility(FacilityId).
+!goto(FacilityId)
	: default::charge(0)
<-
	!recharge;
	!goto(FacilityId);
	.
+!goto(FacilityId)
	: default::routeLength(R) & R \== 0
<-	
	!continue;
	!goto(FacilityId);
	.
// We should not test battery if we are already going to a charging station	
+!goto(FacilityId)
: not .desire(action::go_charge(_)) & new::chargingList(List) & .member(FacilityId,List)
<-	
    !action::commit_action(goto(FacilityId));
	!goto(FacilityId);
	.
// Tests if there is enough battery to go to my goal AND to the nearest charging station around that goal	
+!goto(FacilityId)
: not .desire(action::go_charge(_)) & new::chargingList(List) & rules::closest_facility(List, FacilityId, FacilityId2) & rules::enough_battery(FacilityId, FacilityId2, Result)
<-	
    if (Result == "false") { !go_charge(FacilityId); }
    else { !action::commit_action(goto(FacilityId)); }
	!goto(FacilityId);
	.
	
// Goto (option 2)
// Lat and Lon must be floats
+!goto(Lat, Lon) : going(Lat,Lon) & default::routeLength(R) & R == 0 <- -going(Lat,Lon).
+!goto(Lat, Lon)
	: default::charge(0)
<-
	!recharge;
	!goto(Lat, Lon);
	.
+!goto(Lat, Lon)
	: going(Lat,Lon) & default::routeLength(R) & R \== 0
<-	
	!continue;
	!goto(Lat, Lon);
	.
// Tests if there is enough battery to go to my goal AND to the nearest charging station around that goal	
+!goto(Lat, Lon)
: not .desire(go_charge(_,_)) & new::chargingList(List) & rules::closest_facility(List, Lat, Lon, FacilityId2) & rules::enough_battery(Lat, Lon, FacilityId2, Result)
<-	
    if (Result == "false") { !go_charge(Lat, Lon); }
    else { +going(Lat,Lon); !action::commit_action(goto(Lat,Lon)); }
	!goto(Lat, Lon);
	.
	
//  for verifying battery and going to charging stations
+!go_charge(Flat,Flon)
	: new::chargingList(List) & default::lat(Lat) & default::lon(Lon) & default::role(_, Speed, _, _, _, _, _, _, _, BatteryCap, _)
<-
	+onMyWay([]);
	for(.member(ChargingId,List)){
		?default::chargingStation(ChargingId,Clat,Clon,_);
		if(math.sqrt((Lat-Flat)**2+(Lon-Flon)**2)>(math.sqrt((Lat-Clat)**2+(Lon-Clon)**2)) & math.sqrt((Lat-Flat)**2+(Lon-Flon)**2)>(math.sqrt((Clat-Flat)**2+(Clon-Flon)**2))){
			?onMyWay(AuxList);
			-onMyWay(AuxList);
			+onMyWay([ChargingId|AuxList]);
		}
	}
	?onMyWay(Aux2List);
	if(.empty(Aux2List)){
		?rules::closest_facility(List,Facility);
		?rules::closest_facility(List,Flat,Flon,FacilityId2);
		?rules::enough_battery2(Facility, Flat, Flon, FacilityId2, Result, BatteryCap);
		if (Result == "false") {
			+impossible;
			.print("@@@@ Impossible route, going to try anyway.");
			+going(Flat,Flon);
			!action::commit_action(goto(Flat,Flon));
			!goto(Flat,Flon);
		}
		else {
			FacilityAux2 = Facility;
			.print("There is no charging station between me and my goal, going to the nearest one.");
		}
	}
	else{
		?rules::closest_facility(Aux2List,Facility);
		?rules::enough_battery_charging(Facility, Result);
		if (Result == "false") {
			?rules::closest_facility(List,FacilityAux);
			?rules::enough_battery_charging2(FacilityAux, Facility, Result2, BatteryCap);
			if (Result2 == "false") {
				+impossible;
				.print("@@@@ Impossible route, going to try anyway and hopefully call service breakdown.");
				+going(Flat,Flon);
				!action::commit_action(goto(Flat,Flon));
				!goto(Flat,Flon);
			}
			else {
				FacilityAux2 = FacilityAux;
				.print("There is no charging station between me and my goal, going to the nearest one.");
			}
		}
		else {
			?rules::closest_facility(Aux2List,Flat,Flon,FacilityAux);
			?rules::enough_battery_charging(FacilityAux, ResultAux);
			if (ResultAux == "true") {
				FacilityAux2 = FacilityAux;
			}
			else {
				.delete(FacilityAux,Aux2List,Aux2List2);
				!check_list_charging(Aux2List2,Flat,Flon);
				?charge_in(FacAux);
				-charge_in(FacAux);
				FacilityAux2 = FacAux;
			}
		}
	}
	-onMyWay(Aux2List);
	if (not action::impossible) {
		.print("**** Going to charge my battery at ", FacilityAux2);
		!action::commit_action(goto(FacilityAux2));
		!goto(FacilityAux2);
		!charge;		
	}
	else {
		-impossible;
	}
	.
+!check_list_charging(List,Lat,Lon)
<-
	?rules::closest_facility(List,Lat,Lon,Facility);
	?rules::enough_battery_charging(Facility, ResultC);
	if (ResultC == "true") {
		+charge_in(Facility);
	}
	else {
		.delete(Facility,List,ListAux);
		!check_list_charging(ListAux,Lat,Lon);
	}
	.
+!check_list_charging(List,FacilityId)
<-
	?rules::closest_facility(List,FacilityId,Facility);
	?rules::enough_battery_charging(Facility, ResultC);
	if (ResultC == "true") {
		+charge_in(Facility);
	}
	else {
		.delete(Facility,List,ListAux);
		!check_list_charging(ListAux,FacilityId);
	}
	.

+!go_charge(FacilityId)
	: new::chargingList(List) & default::lat(Lat) & default::lon(Lon) & rules::getFacility(FacilityId,Flat,Flon,Aux1,Aux2) & default::role(_, Speed, _, _, _, _, _, _, _, BatteryCap, _)
<-
	+onMyWay([]);
	?default::facility(Fac);
	if (.member(Fac,List)) {
		.delete(Fac,List,List2);
	}
	else {
		List2 = List;
	}
	for(.member(ChargingId,List2)){
		?default::chargingStation(ChargingId,Clat,Clon,_);
		if(math.sqrt((Lat-Flat)**2+(Lon-Flon)**2)>(math.sqrt((Lat-Clat)**2+(Lon-Clon)**2)) & math.sqrt((Lat-Flat)**2+(Lon-Flon)**2)>(math.sqrt((Clat-Flat)**2+(Clon-Flon)**2))){
			?onMyWay(AuxList);
			-onMyWay(AuxList);
			+onMyWay([ChargingId|AuxList]);
		}
	}
	?onMyWay(Aux2List);
	if(.empty(Aux2List)){
		?rules::closest_facility(List2,Facility);
		?rules::closest_facility(List,FacilityId,FacilityId2);
//		?enough_battery_charging2(Facility, FacilityId, Result, BatteryCap);
		?rules::enough_battery2(Facility, FacilityId, FacilityId2, Result, BatteryCap);
		if (Result == "false") {
			+impossible;
			.print("@@@@ Impossible route, going to try anyway.");
			!action::commit_action(goto(FacilityId));
			!goto(FacilityId);
		}
		else {
			FacilityAux2 = Facility;
			.print("There is no charging station between me and my goal, going to the nearest one.");
		}
	}
	else{
		?rules::closest_facility(Aux2List,Facility);
		?rules::enough_battery_charging(Facility, Result);
		if (Result == "false") {
			?rules::closest_facility(List2,FacilityAux);
			?rules::enough_battery_charging2(FacilityAux, Facility, Result2, BatteryCap);
			if (Result2 == "false") {
				+impossible;
				.print("@@@@ Impossible route, going to try anyway and hopefully call service breakdown.");
				!action::commit_action(goto(FacilityId));
				!goto(FacilityId);
			}
			else {
				FacilityAux2 = FacilityAux;
				.print("There is no charging station between me and my goal, going to the nearest one.");
			}
		}
		else {
			?rules::closest_facility(Aux2List,FacilityId,FacilityAux);
			?rules::enough_battery_charging(FacilityAux, ResultAux);
			if (ResultAux == "true") {
				FacilityAux2 = FacilityAux;
			}
			else {
				.delete(FacilityAux,Aux2List,Aux2List2);
				!check_list_charging(Aux2List2,FacilityId);
				?charge_in(FacAux);
				-charge_in(FacAux);
				FacilityAux2 = FacAux;
			}
		}
	}
	-onMyWay(Aux2List);
	if (not action::impossible) {
		.print("**** Going to charge my battery at ", FacilityAux2);
		!action::commit_action(goto(FacilityAux2));
		!goto(FacilityAux2);
		!charge;		
	}
	else {
		-impossible;
	}
	.

	