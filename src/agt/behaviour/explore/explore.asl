+!go_explore_charging
	: new::chargingList(List) & rules::farthest_facility(List, Facility)
<-
	.print("Going to my farthest charging station",Facility," to explore");
	!action::goto(Facility);
	!action::charge;
	!strategies::free;
	.
	
+!go_explore_edges
	: .my_name(vehicle1) & default::minLat(MinLat) & default::minLon(MinLon) & default::maxLat(MaxLat) & default::maxLon(MaxLon) & CLat = (MinLat+MaxLat)/2 & CLon = (MinLon+MaxLon)/2 & new::chargingList(List) & rules::closest_facility(List, CLat, MinLon + 0.001, Facility)
<-
	!action::goto(Facility);
	!action::charge;
	!action::goto(CLat,MinLon + 0.001);
	!action::goto(MinLat + 0.001,MinLon + 0.001);
	!action::goto(MinLat + 0.001,CLon);
	?rules::closest_facility(List,Facility2);
	!action::goto(Facility2);
	!action::charge;
	!strategies::free;
	.
+!go_explore_edges
	: .my_name(vehicle2) & default::minLat(MinLat) & default::minLon(MinLon) & default::maxLat(MaxLat) & default::maxLon(MaxLon) & CLat = (MinLat+MaxLat)/2 & CLon = (MinLon+MaxLon)/2 & new::chargingList(List) & rules::closest_facility(List, CLat, MinLon + 0.001, Facility)
<-
	!action::goto(Facility);
	!action::charge;
	!action::goto(CLat,MinLon + 0.001);
	!action::goto(MaxLat - 0.00001,MinLon + 0.001);
	!action::goto(MaxLat - 0.00001,CLon);
	?rules::closest_facility(List,Facility2);
	!action::goto(Facility2);
	!action::charge;
	!strategies::free;
	.
+!go_explore_edges
	: .my_name(vehicle3) & default::minLat(MinLat) & default::minLon(MinLon) & default::maxLat(MaxLat) & default::maxLon(MaxLon) & CLat = (MinLat+MaxLat)/2 & CLon = (MinLon+MaxLon)/2 & new::chargingList(List) & rules::closest_facility(List, CLat, MaxLon - 0.00001, Facility)
<-
	!action::goto(Facility);
	!action::charge;
	!action::goto(CLat,MaxLon - 0.00001);
	!action::goto(MaxLat - 0.00001,MaxLon - 0.00001);
	!action::goto(MaxLat - 0.00001,CLon);
	?rules::closest_facility(List,Facility2);
	!action::goto(Facility2);
	!action::charge;
	!strategies::free;
	.
+!go_explore_edges
	: .my_name(vehicle4) & default::minLat(MinLat) & default::minLon(MinLon) & default::maxLat(MaxLat) & default::maxLon(MaxLon) & CLat = (MinLat+MaxLat)/2 & CLon = (MinLon+MaxLon)/2 & new::chargingList(List) & rules::closest_facility(List, CLat, MaxLon - 0.00001, Facility)
<-
	!action::goto(Facility);
	!action::charge;
	!action::goto(CLat,MaxLon - 0.00001);
	!action::goto(MinLat + 0.001,MaxLon - 0.00001);
	!action::goto(MinLat + 0.001,CLon);
	?rules::closest_facility(List,Facility2);
	!action::goto(Facility2);
	!action::charge;
	!strategies::free;
	.