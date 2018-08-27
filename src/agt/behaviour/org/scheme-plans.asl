+!clean_scheme(Scheme,AOrgId,WOrgId)	
<-
//	.abolish(org::focused(_,Scheme,_)); 
	org::destroyScheme(Scheme)[artifact_id(AOrgId),wid(WOrgId)];
	.
-!clean_scheme(Scheme,AOrgId,WOrgId).

+!clean_group(GroupName,AOrgId,WOrgId)	
<-   	
//	.abolish(org::focused(_,GroupName,_)); // why do I have to use abolish?
   	org::destroyGroup(GroupName)[artifact_id(AOrgId),wid(WOrgId)];   	
	.
-!clean_group(GroupName,AOrgId,WOrgId).

+goalState(Scheme,item_manufactured,_,_,satisfied)
	: ::schemes(Schemes)[artifact_name(_,GroupName)] & .member(Scheme,Schemes) & default::group(_,_,GroupId)[artifact_id(AOrgId)] & default::joined(org,WOrgId)
<-
   	.print("*** Compound Item deliveried for ",Scheme,"! ***");  
   	!clean_scheme(Scheme,AOrgId,WOrgId); 
   	!clean_group(GroupName,AOrgId,WOrgId);
   	.

+!retrive_items
	: .intend(::retrive_items)
<-
	.print("I'm already collecting items");
	.suspend;
	.
+!retrive_items
	: strategies::winner(Name,Type,Duty,Tasks,TaskId) & strategies::centerStorage(Storage) & strategies::centerWorkshop(Workshop)
<-
	!action::goto(Storage);
	!stock::store_all_items(Storage);
	!go_retrieve(Tasks);
	!action::goto(Workshop);	
	-strategies::winner(Name,Type,Duty,Tasks,TaskId); // at this point we won't use this belief anymore	
	!!strategies::always_recharge;
	.resume(::retrive_items);
	.
+!go_retrieve([])
<-
	.print("I've collected all items");	
	.
+!go_retrieve([retrieve(Storage,Item,Qty)|Tasks])
<-
	.print("My team needs ",Item," ",Qty);
	!action::goto(Storage);
	!stock::retrieve_items(Item,Qty,Storage);
	!go_retrieve(Tasks);
	.

+!assist_assemble[scheme(Scheme)]
	: ::schemes(Schemes)[artifact_name(_,GroupName)] & .member(Scheme,Schemes) & ::play(Assembler,assembler,GroupName)
<-
	.print("doing assisting ",Assembler);
	!assemble::assist_assemble(Assembler);
	!assist_assemble[scheme(Scheme)];
	.
+!stop_assist[scheme(Scheme)]
	: ::schemes(Schemes)[artifact_name(_,GroupName)] & .member(Scheme,Schemes) & ::play(Assembler,assembler,GroupName) & default::joined(org,OrgId) 
<-
	.print("stop assisting to ",Assembler);
//	.succeed_goal(assemble::assist_assemble(Assembler));
    .drop_desire(assemble::assist_assemble(Assembler));
    org::goalAchieved(assist_assemble)[artifact_name(Scheme),wid(OrgId)];
	.print("stopped ",Assembler);
	
	if (not .desire(::assemble) & not .desire(::assist_assemble) ){
		!!go_back_to_work;
	}
	.
	   
//+!assemble[scheme(Scheme)]
//	: ::goalArgument(Scheme,_,"Item",SItem) & .term2string(Item,SItem) & ::goalArgument(Scheme,_,"Qty",Qty)
//<-
//	!do_assemble(Scheme,Item,Qty);
//	. 
+!assemble[scheme(Scheme)]
	: ::goalArgument(Scheme,_,"Item",Item) & ::goalArgument(Scheme,_,"Qty",Qty)
<-
	!do_assemble(Scheme,Item,Qty);
	. 
+!do_assemble(Scheme,Item,Qty)
	: default::hasItem(Item,Qty)
	.  
+!do_assemble(Scheme,Item,Qty)
	: default::joined(org,OrgId) 
<-
//	org::resetGoal(assist_assemble)[artifact_name(Scheme),wid(OrgId)];
	!assemble::assemble(Item,Qty);
	!do_assemble(Scheme,Item,Qty);
	.    
	
+!delivery[scheme(Scheme)]
	: .desire(::assemble) | .desire(::assist_assemble) 
<-
	.print("I still have to help my teammates");
	.suspend;	
	.
+!delivery[scheme(Scheme)]
	: default::hasItem(_,_) & strategies::centerStorage(Storage)
<-
	.print("I'm going to delivery items");
	!action::forget_old_action(Id);
	!action::goto(Storage);
	for(default::hasItem(Item,Qty)){
		!stock::store_manufactored_item(Item,Qty,Storage)
	}	
	.resume(::delivery);
	!!go_back_to_work;
	.
	
+!go_back_to_work
	: .my_name(Me) & default::play(Me,CurrentRole,_)
<-
	.print("I'm going back to work");
	!action::forget_old_action(Id);
	!strategies::change_role(CurrentRole,gatherer);
	!strategies::gather;
	.
