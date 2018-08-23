+winner(_,_,_,Item,assist,_,_,_,TaskId)
	: default::joined(org,OrgId)
<-
	lookupArtifact(TaskId,SchArtId)[wid(OrgId)];
	org::focus(SchArtId)[wid(OrgId)];
	.print("I won the task to assist assemble ",Item);
	org::commitMission(massist)[artifact_id(SchArtId)];
	.
+winner(_,_,_,Item,assemble,_,_,_,TaskId)
	: default::joined(org,OrgId)
<-
	lookupArtifact(TaskId,SchArtId)[wid(OrgId)];
	org::focus(SchArtId)[wid(OrgId)];
	.print("I won the task to assemble ",Item);
	org::commitMission(massemble)[artifact_id(SchArtId)];
	.

//+default::task(Task,ContractNetName,TaskId)
//	: .my_name(Me) & play(Me,MyRole,_) & MyRole == gatherer
//<-
//	.print("Got a new task for: ",Task," CNP ",ContractNetName," taskid ",TaskId);
//	!create_bid(Distance,MaxLoad,Role);
//	default::bid(Distance,MaxLoad,Role)[artifact_name(ContractNetName)];
//	.
//+default::task(Task,ContractNetName,TaskId)
//<-
//	default::bid(-1,-1,-1)[artifact_name(ContractNetName)];
//	.
	
//+!create_bid(Distance,MaxLoad,Role)
//	: default::role(Role, _, _, _, _, _, _, _, _, _, _) & default::maxLoad(MaxLoad) & default::centerStorage(Storage) & default::centerWorkshop(Workshop) & default::speed(Speed)
//<-
//	actions.route(Role,Speed,Storage,RouteStorage);
//	actions.route(Role,Speed,Storage,Workshop,RouteWorkshop);
//	actions.route(Role,Speed,Workshop,Storage,RouteStorage2);
//	Distance = RouteStorage + RouteWorkshop + RouteStorage2;
//	.