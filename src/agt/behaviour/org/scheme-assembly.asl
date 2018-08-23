got_assemble_to_do(Scheme)
:-
	goalState(Scheme,assemble,_,_,waiting) & 
	.my_name(Me) & 
	.term2string(Me,SMe) & 
	SMe == Assembler & 
	not ::commitment(Me,_,_)
	.
got_assist_to_do(Scheme)
:-
	goalState(Scheme,assemble,_,_,enabled) & 
	.my_name(Me) & 
	not ::commitment(Me,_,_)
	.
  
@assistAssemble[atomic]
+!commit_assist(Scheme)
	: .my_name(Me) & not ::commitment(Me,_,_)
<-
	.print("*** assembler of ",Scheme," is ready, going assist ***");
    !action::forget_old_action(Id);
    org::commitMission(massist)[artifact_name(Scheme)];
	.
+!commit_assist(Scheme).
@assembleAssemble[atomic]
+!commit_assemble(Scheme)
	: .my_name(Me) & not ::commitment(Me,_,_)
<-
	.print("*** I'm the assembler of ",Scheme,", going assemble ***");
    !action::forget_old_action(Id);
    org::commitMission(massemble)[artifact_name(Scheme)];
	.
+!commit_assemble(Scheme). 

+goalState(TaskId,assembly_completed,_,_,satisfied)
<-
   .print("*** assembly ",TaskId," done! ***");
   !remove_scheme(TaskId);
   .
   
+goalState(Scheme,assemble,_,_,enabled)
 	: .my_name(Me) & not ::commitment(Me,_,_)
<-
   !commit_assist(Scheme)
   .

// first the observable properties of goals are added, after that, the goal arguments are added
//+goalArgument(Scheme,_,_,Assembler)
//	: .my_name(Me) & .term2string(Me,SMe) & SMe == Assembler & not ::commitment(Me,_,_)
//<-
//	!commit_assemble(Scheme);
//	.

+!assist[scheme(Scheme)]
	: ::goalArgument(Scheme,_,_,Assembler)
<-
	.print("Starting assisting");
	!!assemble::assist_assemble(Assembler);
	.   
+!stop_assist[scheme(Scheme)]
	: default::joined(org,OrgId)
<-
	.print("Stopping assisting");
	!action::forget_old_action(Id);
	lookupArtifact(Scheme,SchArtId)[wid(OrgId)]
	org::stopFocus(SchArtId)[wid(OrgId)];
	!what_to_do;
	.   
   
+!assemble
	: strategies::winner(Name,Type,[assemble(Item,Qty)|Duty],Tasks,TaskId)
<-
	.print("Starting assembling");
	!assemble::assemble(Item,Qty);
	
	!what_to_do;
	.    
	
+!what_to_do
	: ::got_assemble_to_do(Scheme)
<- 
	!commit_assemble(Scheme);
	.
+!what_to_do
	: ::got_assist_to_do(Scheme)
<- 
	!commit_assist(Scheme);	
	.
+!what_to_do
<-
	!!go_back_work;
	.
+!go_back_work
	: default::hasItem(Item,Qty) & strategies::centerStorage(Storage)
<-
	.print("I'm going to delivery items");
	!stock::store_all_items(Storage);
	!go_back_work;
	.
+!go_back_work
	: .my_name(Me) & default::play(Me,CurrentRole,_)
<-
	.print("I'm going back to work");
	!action::forget_old_action(Id);
	!strategies::change_role(CurrentRole,gatherer);
	!strategies::gather;
	.
