get_suitable_well_type([], wellType(Type,_,_), Massium, SuitableType) :- SuitableType=Type.
get_suitable_well_type([wellType(Type, Cost, CostPerEfficiency)|RemainingList], wellType(TypeTemp, CostTemp, CostPerEfficiencyTemp), Massium, SuitableType) :-  
CostPerEfficiencyTemp<=CostPerEfficiency & get_suitable_well_type(RemainingList, wellType(TypeTemp, CostTemp, CostPerEfficiencyTemp), Massium, SuitableType).
get_suitable_well_type([wellType(Type, Cost, CostPerEfficiency)|RemainingList], wellType(TypeTemp, CostTemp, CostPerEfficiencyTemp), Massium, SuitableType) :-  
CostPerEfficiencyTemp>CostPerEfficiency & Cost>Massium & get_suitable_well_type(RemainingList, wellType(TypeTemp, CostTemp, CostPerEfficiencyTemp), Massium, SuitableType).
get_suitable_well_type([wellType(Type, Cost, CostPerEfficiency)|RemainingList], wellType(TypeTemp, CostTemp, CostPerEfficiencyTemp), Massium, SuitableType) :-  
CostPerEfficiencyTemp>CostPerEfficiency & Cost<=Massium & get_suitable_well_type(RemainingList, wellType(Type, Cost, CostPerEfficiency), Massium, SuitableType).
get_suitable_well_type([wellType(Type, Cost, CostPerEfficiency)|RemainingList], Massium, SuitableType) :- Cost<=Massium 
& get_suitable_well_type(RemainingList, wellType(Type, Cost, CostPerEfficiency), Massium, SuitableType).
get_suitable_well_type([wellType(Type, Cost, CostPerEfficiency)|RemainingList], Massium, SuitableType) :- Cost>Massium 
& get_suitable_well_type(RemainingList, Massium, SuitableType).
get_suitable_well_type(SuitableType) :- default::myRanking(Ranking) & default::massium(Massium) & ::get_suitable_well_type(Ranking, Massium, SuitableType).

calc(Type, Cost, Efficiency, Result) :- (CostPerEfficiency = Cost/Efficiency) & (Result = wellType(Type, Cost, CostPerEfficiency)).

ranking([], PartialList, Ranking) :- Ranking=PartialList.
ranking([wellType(Type, Cost, Efficiency)|RemainingList], PartialList, Ranking) :- ::calc(Type, Cost, Efficiency, Result)
& .concat(PartialList, [Result], NewList) & ::ranking(RemainingList, NewList, Ranking).
ranking(List, Ranking) :- ::ranking(List, [], Ranking).

list_of_wells(List) :- .findall(wellType(Type, Cost, Efficiency), default::wellType(Type, Cost, Efficiency,_,_), List).

!make_well_types_ranking.

+!make_well_types_ranking
	: default::actionID(S) & list_of_wells(List) & ::ranking(List, Ranking)
<-
	.print("Ranking: ", Ranking);
	+default::myRanking(Ranking);
	.
	
+!make_well_types_ranking
	: true
<-
	.wait( default::actionID(S) & S \== 0 );
	!make_well_types_ranking
	.

+!buy_well 
	: ::get_suitable_well_type(Type) & rules::enough_money
<-  
	!action::build(Type); 
	!build_well(Type);	
	.
+!buy_well 
<-
	.print("Not enough money to buy the desired well");
	.
-!buy_well[code(.fail(action(Action),result(Result)))]
<-
	!recover_from_failure(Action,Result);
	.
	
// we need the Type term to know what is the maximum integrity of a well type
+!build_well(Type,Lat,Lon) 
	: rules::am_I_at_right_position(Lat,Lon)
<-
	.print("I'm not at the desired position, going to Lat(",Lat,") Lon(",Lon,")");
	!action::goto(Lat,Lon);
	!build_well(Type);
	.
+!build_well(Type) 
	: default::well(Id,Lat,Lon,Type,Team,Integrity) & default::wellType(Type,_,_,_,TotalIntegrity) & (Integrity < TotalIntegrity)
<- 
	.print("Building well ",Id);
	!action::buildExistingOne; 
	!build_well(Type);
	.
+!build_well(Type)
	: true
<- 
	.print("I finished the well of type ",Type);
	.
	
+!recover_from_failure(Action, failed_resources)
<-	
	.print("Some agent bought the well before me");
	.
+!recover_from_failure(Action, failed_location)
	: default::lat(Lat) & default::lon(Lon)
<-	
	.print("There is another well/facility here, moving on");
	!action::goto(Lat + 0.001,Lon + 0.001);
	.
+!recover_from_failure(Action, Result)
<-	
	.print("Action ",Action," failed because of ",Result);
	.