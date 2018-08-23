+goalState(TaskId,retrieve_completed,_,_,satisfied)
	: strategies::winner(_,_,Duty,_,TaskId)
<-
   .print("*** retrieve done! ***");   
   !remove_scheme(TaskId);
   !prepare_assembly(TaskId,Duty);
   .
   
+!retrive_items
	: strategies::winner(Name,Type,Duty,Tasks,TaskId)
<-
	!go_retrieve(Tasks);
	.
+!retrive_items_assemble
	: strategies::winner(Name,Type,Duty,Tasks,TaskId)
<-
	!go_retrieve(Tasks);
	.

+!go_retrieve([])
	: strategies::centerWorkshop(Workshop)
<-
	-cleaned_load_once;
	.print("I've collected all items");
	!action::goto(Workshop);
	!!strategies::always_recharge;
	.
+!go_retrieve([retrieve(Storage,Item,Qty)|Tasks])
<-
	.print("My team needs ",Item," ",Qty);
	!action::goto(Storage);
	!clean_load(Storage);
	+cleaned_load_once;
	!stock::retrieve_items(Item,Qty,Storage);
	!go_retrieve(Tasks);
	.

+!clean_load(Storage)
	: not cleaned_load_once & hasItem(_,_)
<-	
	.print("I have load of base items");
	!stock::store_all_items(Storage);
	.
+!clean_load(Storage).
	
+!prepare_assembly(TaskId,[]).
+!prepare_assembly(TaskId,[assemble(Item,Qty)|Duty])
	: default::joined(org,OrgId) & .concat(TaskId,"_",Item,NewId) & .my_name(Me)
<-
	.print("created scheme for ",Item," ",Qty);
	org::createScheme(NewId, assembly, SchArtId)[wid(OrgId)];
	org::focus(SchArtId)[wid(OrgId)];
	setArgumentValue(assembly_completed,"Assembler",Me)[artifact_id(SchArtId)];
	!commit_assemble(NewId);
   	!prepare_assembly(TaskId,Duty);
	.
+!prepare_assembly(TaskId,[assist(Assembler,Item)|Duty])
	: default::joined(org,OrgId) & .concat(TaskId,"_",Item,NewId)
<-	
	org::focusWhenAvailable(NewId)[wid(OrgId)];
	.print("focused on ",NewId);
   	!prepare_assembly(TaskId,Duty);
	.