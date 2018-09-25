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
	!which_map;
	.
	
+!which_map
	: vLat(V) & vLon(L) & vVolta(T)
<-
	?default::map(Map);
	if(Map == copenhagen){
		-vLat(V);
		+vLat(0.00550);
		-vLon(L);
        +vLon(0.00900);
        -vVolta(T);
 	   	+vVolta(0.00950); 
	}
	if(Map == berlin){
		-vLat(V);
	   	+vLat(0.00550);
	   	-vLon(L);
        +vLon(0.00900);
        -vVolta(T);
 	   	+vVolta(0.00900); 
	}
	if(Map == saopaulo){
		-vLat(V);
	  	+vLat(0.00550);
	  	-vLon(L);
        +vLon(0.00600);
        -vVolta(T);
	  	+vVolta(0.00800);
	}
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
	: n_steps(S) & n_walks(W) & s_total(T) & S == (T+1)
<- 
	.print("Explorer completed, exploring again.");
	-n_steps(S);
	+n_steps(0);
	-n_walks(W);
	+n_walks(0);
	if(.my_name(vehicle4)){
		// Run after all agents explorer all quadrants
		!go_full_map;
	} else{
		!go_walk;		
	}	
	.
//EXPLORER OUTSIDE TO INSIDE
//+!go_walk
//	: n_steps(S) & n_walks(W) & vVolta(V)
//<- 
//	!go_explore_edges;
//	-n_steps(S);
//	+n_steps(S+1);
//	-n_walks(W);
//	+n_walks(V * (S + 1));
//	!go_walk;
//	.
//EXPLORER INSIDE TO OUTSIDE
+!go_walk
	: n_steps(S) & n_walks(W) & vVolta(V) & s_total(T)
<- 
	-n_walks(W);
	+n_walks(V * (T - S));
	!go_explore_edges;
	-n_steps(S);
	+n_steps(S + 1);
	!go_walk;
	.

+!go_full_map 
<-
	+n_Lat(0.00550);
	+n_Lon(0.00800);
	+n_times(0);
	+m_Lon(0);
	+m_Lat(0);
	!go_for;
	.
	
+!go_for : n_times(N) & s_total(S) & N == 3 &
	 m_Lat(M) & m_Lon(L) & n_Lat(P) & n_Lon(O)
<-
	.print("Explorer full map completed!");
	//Call again the explorer in which quadrant
	-n_times(N);
	+n_times(0);
	!go_for;
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
	: .my_name(vehicle1) & n_walks(W) & vLat(V) & vLon(L) & default::minLat(MinLat) & default::minLon(MinLon) & default::maxLat(MaxLat) & default::maxLon(MaxLon) & CLat = (MinLat+MaxLat)/2 & CLon = (MinLon+MaxLon)/2
<-	
	!action::goto(CLat + V + W, CLon - L - W);
	!action::goto(MaxLat - V - W, CLon - L - W);
	!action::goto(MaxLat - V - W, MinLon + L + W);
	!action::goto(CLat + V + W, MinLon + L + W);
	.
+!go_explore_edges // Quarter 2
	: .my_name(vehicle2) & n_walks(W) & vLat(V) & vLon(L) & default::minLat(MinLat) & default::minLon(MinLon) & default::maxLat(MaxLat) & default::maxLon(MaxLon) & CLat = (MinLat+MaxLat)/2 & CLon = (MinLon+MaxLon)/2
<-	
	!action::goto(CLat + V + W, CLon + 	L + W);
	!action::goto(MaxLat - V - W, CLon + L + W);
	!action::goto(MaxLat - V - W, MaxLon - L - W);
	!action::goto(CLat + V + W, MaxLon - L - W);
	.
+!go_explore_edges // Quarter 3
 	: .my_name(vehicle3) & n_walks(W) & vLat(V) & vLon(L) & default::minLat(MinLat) & default::minLon(MinLon) & default::maxLat(MaxLat) & default::maxLon(MaxLon) & CLat = (MinLat+MaxLat)/2 & CLon = (MinLon+MaxLon)/2
<-	
	!action::goto(CLat - V - W, CLon - L - W);
	!action::goto(MinLat + V + W, CLon - L - W);
	!action::goto(MinLat + V + W, MinLon + L + W);
	!action::goto(CLat - V - W, MinLon + L + W);
	.
+!go_explore_edges // Quarter 4
	: .my_name(vehicle4) & n_walks(W) & vLat(V) & vLon(L) & default::minLat(MinLat) & default::minLon(MinLon) & default::maxLat(MaxLat) & default::maxLon(MaxLon) & CLat = (MinLat+MaxLat)/2 & CLon = (MinLon+MaxLon)/2
<-	
	!action::goto(CLat - V - W, CLon + L + W);
	!action::goto(MinLat + V + W, CLon + L + W);
	!action::goto(MinLat + V + W, MaxLon - L - W);
	!action::goto(CLat - V - W, MaxLon - L - W);
	.
+!go_explore_map // Only vehicle 4
	: .my_name(vehicle4) & m_Lat(R) & m_Lon(S) & default::minLat(MinLat) & default::minLon(MinLon) & default::maxLat(MaxLat) & default::maxLon(MaxLon) & CLat = (MinLat+MaxLat)/2 & CLon = (MinLon+MaxLon)/2
<-	

	!action::goto(MinLat + 0.00001 + R, MaxLon - 0.00001 - S);	
	!action::goto(MinLat + ((CLat - MinLat)/2) + R, MaxLon - 0.00001 - S)
	!action::goto(CLat - R, MaxLon - 0.00001 - S);
	
	!action::goto(CLat + ((MaxLat - CLat)/2) + R, MaxLon - 0.00001 - S)
	!action::goto(MaxLat - 0.00001 - R, MaxLon - 0.00001 - S);	
	!action::goto(MaxLat - 0.00001 - R, MaxLon - ((MaxLon - CLon)/2) - S);
	
	!action::goto(MaxLat - 0.00001 - R, CLon + S);	
	!action::goto(MaxLat - 0.00001 - R, MinLon + ((CLon - MinLon)/2) + S);	
	!action::goto(MaxLat - 0.00001 - R, MinLon + 0.00001 + S);
	
	!action::goto(MaxLat - ((MaxLat - CLat)/2) - R, MinLon + 0.00001 + S)
	!action::goto(CLat - R, MinLon + 0.00001 + S);	
	!action::goto(MinLat + ((CLat - MinLat)/2) + R, MinLon + 0.00001 + S);
	
	!action::goto(MinLat + 0.00001 + R, MinLon + 0.00001 + S);	
	!action::goto(MinLat + 0.00001 + R, MinLon + ((CLon - MinLon)/2) + S);
	!action::goto(MinLat + 0.00001 + R, CLon + S);
	
	!action::goto(MinLat + 0.00001 + R, CLon + ((MaxLon - CLon)/2) + S);
	!action::goto(MinLat + 0.00001 + R, MaxLon - 0.00001 - S);
	.
