+goalState(Scheme,item_manufactured,_,_,satisfied)
	: ::schemes(Schemes)[artifact_name(_,GroupName)] & .member(Scheme,Schemes) & default::group(_,_,GroupId)[artifact_id(AOrgId)] & .my_name(Me) & ::play(Me,assembler,GroupName) & default::joined(org,WOrgId)
<-
   	.print("*** Compound Item deliveried for ",Scheme,", removing artifacts! ***");  
   	org::destroyScheme(Scheme)[artifact_id(AOrgId),wid(WOrgId)];
   	org::destroyGroup(GroupName)[artifact_id(AOrgId),wid(WOrgId)]; 
	for(org::focused(_,SchemeName,_) & .substring(Scheme,SchemeName)){
		.abolish(org::focused(_,SchemeName,_));
	}
   	.
+goalState(Scheme,item_manufactured,_,_,satisfied)
<-
   	.print("*** Compound Item deliveried for ",Scheme,"! ***");  
   	for(org::focused(_,SchemeName,_) & .substring(Scheme,SchemeName)){
		.abolish(org::focused(_,SchemeName,_));
	}
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
	!clean_up_load(Storage);
	!go_retrieve(Tasks);
	!action::goto(Workshop);	
	-strategies::winner(Name,Type,Duty,Tasks,TaskId); // at this point we won't use this belief anymore	
	!!strategies::always_recharge;
	.resume(::retrive_items);
	.
+!clean_up_load(CenterStorage)
	: rules::can_I_use_center_storage
<-
	!action::goto(CenterStorage);
	!stock::store_all_items(CenterStorage);
	.
+!clean_up_load(CenterStorage)
	: new::dumpList(DList) & rules::closest_facility(DList,Facility)
<-
	!action::goto(Facility);
	for(default::hasItem(Item,Qty)){
		!action::dump(Item,Qty);
	}
	!action::goto(CenterStorage);
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
	: ::goalState(Scheme,assemble,ListAssembler,_,_) & .nth(0,ListAssembler,Assembler)
<-
	!action::forget_old_action(strategies,always_recharge);
	!do_assist(Scheme,Assembler);
	.
+!assist_assemble[scheme(Scheme)]
	: ::schemes(Schemes)[artifact_name(_,GroupName)] & .member(Scheme,Schemes) & ::play(Assembler,assembler,GroupName)
<-
	!action::forget_old_action(strategies,always_recharge);
	!do_assist(Scheme,Assembler);
	.
+!do_assist(Scheme,Assembler)
<-
	.print("doing assisting ",Assembler);
	!assemble::assist_assemble(Assembler);
	!do_assist(Scheme,Assembler);
	.
+!stop_assist[scheme(Scheme)]
	: ::schemes(Schemes)[artifact_name(_,GroupName)] & .member(Scheme,Schemes) & ::play(Assembler,assembler,GroupName) & default::joined(org,OrgId) 
<-
	.print("stop assisting to ",Assembler);
	!action::forget_old_action(org,assist_assemble[scheme(Scheme)]);
    org::goalAchieved(assist_assemble)[artifact_name(Scheme),wid(OrgId)];	
	if (not .desire(::assemble) & not .desire(::assist_assemble) ){
		!!go_back_to_work;
	}
	.
+!stop_assist[scheme(Scheme)]
	: ::goalState(Scheme,assemble,ListAssembler,_,_) & .nth(0,ListAssembler,Assembler)
<-
	.print("stop assisting without assembler belief ",Assembler);
	!action::forget_old_action(org,assist_assemble[scheme(Scheme)]);
    org::goalAchieved(assist_assemble)[artifact_name(Scheme),wid(OrgId)];	
	if (not .desire(::assemble) & not .desire(::assist_assemble) ){
		!!go_back_to_work;
	}
	.

+!assemble[scheme(Scheme)]
	: ::goalArgument(Scheme,_,"Item",Item) & ::goalArgument(Scheme,_,"Qty",Qty)
<-
	!action::forget_old_action(strategies,always_recharge);
	!do_assemble(Scheme,Item,Qty);
	. 
+!do_assemble(Scheme,Item,Qty)
	: default::hasItem(Item,Qty)
	.  
+!do_assemble(Scheme,Item,Qty)
	: default::joined(org,OrgId) 
<-
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
	!action::forget_old_action;
	!action::goto(Storage);
	for(default::hasItem(Item,Qty)){
		!stock::store_manufactored_item(Item,Qty,Storage)
	}	
	.resume(::delivery);
	!!go_back_to_work;
	.
	
+!go_back_to_work
	: .my_name(Me) & default::play(Me,CurrentRole,g1) & strategies::should_become(PreviousRole)
<-
	.print("I'm going back to work");
	!strategies::change_role(CurrentRole,PreviousRole);
	!!strategies::go_back_to_work;
	.
