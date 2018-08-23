// ### BIDS ###
+default::task(Agents,assemble(_),ContractNetName,TaskId)
	: .my_name(Me) & .member(Me,Agents)
<-
	!create_bid(Bid);
	.print("My bid for taskss ",TaskId," is ",Bid);
    manyBids(Bid)[artifact_name(ContractNetName)];
	ceaseBids[artifact_name(ContractNetName)];
	.print(ContractNetName);
	.
	
+!create_bid(Bid)
	: default::role(Role,_,_,_,_,_,_,_,_,_,_) & default::maxLoad(MaxLoad) & strategies::centerStorage(Storage) & strategies::centerWorkshop(Workshop) & default::speed(Speed)
<-
	actions.route(Role,Speed,Storage,RouteStorage);
	actions.route(Role,Speed,Storage,Workshop,RouteWorkshop);
	actions.route(Role,Speed,Workshop,Storage,RouteStorage2);
	Distance = RouteStorage + RouteWorkshop + RouteStorage2;
	Bid = [bid(Distance,MaxLoad,Role)];
	.

// ### ASSEMBLE ###
+!assemble(Item,Qty)
	: true
<-
	!action::assemble(Item,Qty);
	.
-!assemble(Item,Qty)[code(.fail(action(Action),result(Result)))]
<-
	!recover_from_failure(Action,Result,Item,Qty);
	.	
	
+!assist_assemble(Assembler)
	: true
<-
	!action::assist_assemble(Assembler);
	!assist_assemble(Assembler);
	.
-!assist_assemble(Assembler)[code(.fail(action(Action),result(Result)))]
<-
	!recover_from_failure(Action,Result,Assembler);
	.	
	
+!recover_from_failure(Action, Result, Item, Qty)
	: not default::hasItem(Item,Qty) & (Result == failed_item_amount | Result == failed_tools)
<-	
	.print("Some agent must have failed assist assemble, trying to assemble again.");
	!assemble(Item,Qty);
	.
	
+!recover_from_failure(Action, Result, Item, Qty)
<-	
	.print("Action ",Action," failed because of ",Result);
	.
+!recover_from_failure(Action, Result, Assembler)
<-	
	.print("Action ",Action," failed because of ",Result);
	.