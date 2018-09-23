// Plan to calculate how much the quadrant should be traversed
+!size_map 
	: 	default::minLat(MinLat) & default::minLon(MinLon) & 
		default::maxLat(MaxLat) & default::maxLon(MaxLon) & 
		CLat = (MinLat+MaxLat)/2 & CLon = (MinLon+MaxLon)/2 & 
		new::chargingList(List) & rules::closest_facility(List, CLat, MinLon + 0.001, Facility)
<- 
	VHipo = ((((CLat - MinLat)/2) * ((CLat - MinLat)/2)) + (((CLon - MinLon)/2) * ((CLon - MinLon)/2)));
	HalfH = VHipo / 2;
	+s_total(math.floor((math.sqrt(HalfH)/0.0060))-2);
	.

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
	: n_steps(S) & n_walks(W) & s_total(T) & S == T
<- 
	.print("Explorer completed, exploring again.");
	-n_steps(S);
	+n_steps(0);
	-n_walks(W);
	+n_walks(0);
	if(.my_name(vehicle4)){
		// Run after all agents explorer all quadrants
		!go_full_map;
	} else {
		!go_walk;
	}	
	.
+!go_walk
	: n_steps(S) & n_walks(W)
<- 
	!go_explore_edges;
	-n_steps(S);
	+n_steps(S+1);
	-n_walks(W);
	+n_walks(0.00600 * (S + 1));
	!go_walk;
	.

+!go_full_map : .my_name(vehicle4)
<-
	+n_Lat(0.00550);
	+n_Lon(0.00800);
	+n_times(0);
	+m_Lon(0);
	+m_Lat(0);
	!go_for;
	.
	
+!go_for : n_times(N) & s_total(S) & N == (S * 2)
<-
	.print("Explorer full map completed!")
	//Call again the explorer in which quadrant
	!go_walk;
	.	
	
+!go_for
	: m_Lat(M) & m_Lon(L) & n_times(T) & n_Lat(N) & n_Lon(O)
<-
	!go_explore_map;
	-n_times(T);
	+n_times(T + 1);
	-m_Lon(L);
	+m_Lon(O * T);
	-m_Lat(M);
	+m_Lat(N * T);
	!go_for;
	.

// |---|---|
// | 1 | 2 |
// |---|---|
// | 3 | 4 |
// |---|---| 

+!go_explore_edges // Quarter 1
	: .my_name(vehicle1) & n_walks(W) & default::minLat(MinLat) & default::minLon(MinLon) & default::maxLat(MaxLat) & default::maxLon(MaxLon) & CLat = (MinLat+MaxLat)/2 & CLon = (MinLon+MaxLon)/2
<-	
	!action::goto(CLat + 0.00550 + W, CLon - 0.00800 - W);
	!action::goto(MaxLat - 0.00550 - W, CLon - 0.00800 - W);
	!action::goto(MaxLat - 0.00550 - W, MinLon + 0.00800 + W);
	!action::goto(CLat + 0.00550 + W, MinLon + 0.00800 + W);
	.
+!go_explore_edges // Quarter 2
	: .my_name(vehicle2) & n_walks(W) & default::minLat(MinLat) & default::minLon(MinLon) & default::maxLat(MaxLat) & default::maxLon(MaxLon) & CLat = (MinLat+MaxLat)/2 & CLon = (MinLon+MaxLon)/2
<-	
	!action::goto(CLat + 0.00550 + W, CLon + 0.00800 + W);
	!action::goto(MaxLat - 0.00550 - W, CLon + 0.00800 + W);
	!action::goto(MaxLat - 0.00550 - W, MaxLon - 0.00800 - W);
	!action::goto(CLat + 0.00550 + W, MaxLon - 0.00800 - W);
	.
+!go_explore_edges // Quarter 3
 	: .my_name(vehicle3) & n_walks(W) & default::minLat(MinLat) & default::minLon(MinLon) & default::maxLat(MaxLat) & default::maxLon(MaxLon) & CLat = (MinLat+MaxLat)/2 & CLon = (MinLon+MaxLon)/2
<-	
	!action::goto(CLat - 0.00550 - W, CLon - 0.00800 - W);
	!action::goto(MinLat + 0.00550 + W, CLon - 0.00800 - W);
	!action::goto(MinLat + 0.00550 + W, MinLon + 0.00800 + W);
	!action::goto(CLat - 0.00550 - W, MinLon + 0.00800 + W);
	.
+!go_explore_edges // Quarter 4
	: .my_name(vehicle4) & n_walks(W) & default::minLat(MinLat) & default::minLon(MinLon) & default::maxLat(MaxLat) & default::maxLon(MaxLon) & CLat = (MinLat+MaxLat)/2 & CLon = (MinLon+MaxLon)/2
<-	
	!action::goto(CLat - 0.00550 - W, CLon + 0.00800 + W);
	!action::goto(MinLat + 0.00550 + W, CLon + 0.00800 + W);
	!action::goto(MinLat + 0.00550 + W, MaxLon - 0.00800 - W);
	!action::goto(CLat - 0.00550 - W, MaxLon - 0.00800 - W);
	.
+!go_explore_map // Only vehicle 4
	: .my_name(vehicle4) & m_Lat(R) & m_Lon(S) & default::minLat(MinLat) & default::minLon(MinLon) & default::maxLat(MaxLat) & default::maxLon(MaxLon) & CLat = (MinLat+MaxLat)/2 & CLon = (MinLon+MaxLon)/2
<-	
	!action::goto(MaxLat - 0.00001 - R, MinLon + 0.00001 + S);
	!action::goto(MinLat + 0.00001 + R, MinLon + 0.00001 + S);
	!action::goto(MinLat + 0.00001 + R, MaxLon - 0.00001 - S);
	!action::goto(MaxLat - 0.00001 - R, MaxLon - 0.00001 - S);
	!action::goto(MaxLat - 0.00001 - R, MinLon + 0.00001 + S);
	.
