n_steps(3).
n_steps_ct(0).
n_walks(0).

+!explore
<-
	!go_explore_charging;
	!explore;
	.

+!go_explore_charging
	: new::chargingList(List) & rules::farthest_facility(List, Facility)
<-
	.print("Going to my farthest charging station",Facility," to explore");
	!action::goto(Facility);
	!action::charge;
	.

+!go_walk
	: n_steps(S) & S \== 0 & n_steps_ct(SC) & default::minLat(MinLat) & default::minLon(MinLon) & default::maxLat(MaxLat) & default::maxLon(MaxLon) & CLat = (MinLat+MaxLat)/2 & CLon = (MinLon+MaxLon)/2 & new::chargingList(List) & rules::closest_facility(List, CLat, MinLon + 0.001, Facility)
<- 
	!go_explore_edges;
	if (SC == 0){
		CT = S - 1;
		-+n_steps_ct(CT);
	} else {
		CT = SC - 1;
		-+n_steps_ct(CT);
		if(CT == 0) {
			!go_walk;
		}
	}
	M = (S - CT);
	-+n_walks(0.00600 * M);
	!go_walk;
	.

// Verificar porque nao para o plano quando chega no n_steps_ct = 0
-!go_walk
	: n_steps_ct(SC) & SC == 0
<- 
	.print("Explorer completed!").

// |---|---|
// | 1 | 2 |
// |---|---|
// | 3 | 4 |
// |---|---| 

+!go_explore_edges // Quarter 1
	: .my_name(vehicle1) & n_walks(W) & default::minLat(MinLat) & default::minLon(MinLon) & default::maxLat(MaxLat) & default::maxLon(MaxLon) & CLat = (MinLat+MaxLat)/2 & CLon = (MinLon+MaxLon)/2 & new::chargingList(List) & rules::closest_facility(List, CLat, MinLon + 0.001, Facility)
<-	
	!action::goto(CLat + 0.00550 + W, CLon - 0.00800 - W);
	!action::goto(MaxLat - 0.00550 - W, CLon - 0.00800 - W);
	!action::goto(MaxLat - 0.00550 - W, MinLon + 0.00800 + W);
	!action::goto(CLat + 0.00550 + W, MinLon + 0.00800 + W);
	.
+!go_explore_edges // Quarter 2
	: .my_name(vehicle2) & n_walks(W) & default::minLat(MinLat) & default::minLon(MinLon) & default::maxLat(MaxLat) & default::maxLon(MaxLon) & CLat = (MinLat+MaxLat)/2 & CLon = (MinLon+MaxLon)/2 & new::chargingList(List) & rules::closest_facility(List, CLat, MinLon + 0.001, Facility)
<-	
	!action::goto(CLat + 0.00550 + W, CLon + 0.00800 + W);
	!action::goto(MaxLat - 0.00550 - W, CLon + 0.00800 + W);
	!action::goto(MaxLat - 0.00550 - W, MaxLon - 0.00800 - W);
	!action::goto(CLat + 0.00550 + W, MaxLon - 0.00800 - W);
	.
+!go_explore_edges // Quarter 3
 	: .my_name(vehicle3) & n_walks(W) & default::minLat(MinLat) & default::minLon(MinLon) & default::maxLat(MaxLat) & default::maxLon(MaxLon) & CLat = (MinLat+MaxLat)/2 & CLon = (MinLon+MaxLon)/2 & new::chargingList(List) & rules::closest_facility(List, CLat, MinLon + 0.001, Facility)
<-	
	!action::goto(CLat - 0.00550 - W, CLon - 0.00800 - W);
	!action::goto(MinLat + 0.00550 + W, CLon - 0.00800 - W);
	!action::goto(MinLat + 0.00550 + W, MinLon + 0.00800 + W);
	!action::goto(CLat - 0.00550 - W, MinLon + 0.00800 + W);
	.
+!go_explore_edges // Quarter 4
	: .my_name(vehicle4) & n_walks(W) & default::minLat(MinLat) & default::minLon(MinLon) & default::maxLat(MaxLat) & default::maxLon(MaxLon) & CLat = (MinLat+MaxLat)/2 & CLon = (MinLon+MaxLon)/2 & new::chargingList(List) & rules::closest_facility(List, CLat, MinLon + 0.001, Facility)
<-	
	!action::goto(CLat - 0.00550 - W, CLon + 0.00800 + W);
	!action::goto(MinLat + 0.00550 + W, CLon + 0.00800 + W);
	!action::goto(MinLat + 0.00550 + W, MaxLon - 0.00800 - W);
	!action::goto(CLat - 0.00550 - W, MaxLon - 0.00800 - W);
	.
