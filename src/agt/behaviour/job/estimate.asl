// given a list of storages, return the itemized available items; return pattern item(Item,Qtd)
get_available_items([],Temp,ListItems)
:- 
	ListItems = Temp.
get_available_items([Storage|Storages],Temp,ListItems)
:-
	default::available_items(Storage,Items) & 
	.concat(Items,Temp,NewList)&
	get_available_items(Storages,NewList,ListItems) 
	.
// given a list of items, sums up all items of the same type
sum_up_items([],Temp,ListItems)
:-
	ListItems = Temp
	.
sum_up_items([item(Item,Qtd)|Items],Temp,ListItems)
:- 
	.member(item(Item,OldQtd),Temp) & 
	.difference(Temp,[item(Item,OldQtd)],NewList) &
	sum_up_items(Items,[item(Item,Qtd+OldQtd)|NewList],ListItems)
	.
sum_up_items([item(Item,Qtd)|Items],Temp,ListItems)
:- 
	not .member(item(Item,_),Temp) & 
	sum_up_items(Items,[item(Item,Qtd)|Temp],ListItems)
	.
// given a list of required items and quantities "required(Item,Qtd)", and another list of available items and quantities "item(Item,Qtd)", evaluates the difference taking into account the quantities
difference_in_quantities([],_):-true.
difference_in_quantities([required(Item,ReqQtd)|RequiredItems],AvailableItems)
:-
	.member(item(Item,AvaQtd),AvailableItems) &
	AvaQtd >= ReqQtd &
	difference_in_quantities(RequiredItems,AvailableItems)
	.
	
evaluate_items(Items,StoragesToLook)
:- 	
	get_available_items(StoragesToLook,[],ItemizedAvailableItems)&
	sum_up_items(ItemizedAvailableItems,[],AvailableItems)&
	difference_in_quantities(Items,AvailableItems)
	.
evaluate_steps
:-
	true
	.

+!global_stock
	: new::storageList(SList)
<-
	.print("Building global stock of compound items");
	?get_available_items(SList,[],ItemizedAvailableItems);
	?sum_up_items(ItemizedAvailableItems,[],AvailableItems);	
	for(.member(item(Item,Qtd),AvailableItems)){
		+::partial_stock(Qtd,Item);
	} 	
	.	

+!priced_estimate(Id,Items)
	: new::storageList(SList)
<-
	?evaluate_items(Items,SList);
	?evaluate_steps;
	.print(Id," is feasible");
	.
//-!priced_estimate(Id,Storage,Items)[error_msg(Message)]
//<-
//	maybe perform the metrics for failed evaluation here
//	.fail;
//	.

calculate_lot(Item,DesiredQty,Lot)
:-
	Lot = math.ceil(DesiredQty*0.5)
	.
+!compound_estimate(Items)
	: new::storageList(SList) & default::desired_compound(CList) & .sort(CList,SCList)
<-
	!global_stock;
	!compound_priority(SCList);
	.findall(item(Item,MinimumQty),::must_assemble(MinimumQty,Item),Items);
	.abolish(::partial_stock(_,_));
	.abolish(::must_assemble(_,_));
	.
+!compound_priority([]).
+!compound_priority([item(_,Item,DesiredQty)|List])
	: default::item(Item,_,_,parts(Parts)) & ::calculate_lot(Item,DesiredQty,Lot)
<-		
	.findall(item(TQtd,TItem),::partial_stock(TQtd,TItem),TItems);
//	.print("Our production lot for ",Item," is ",Lot);
	!compound_tracking(Parts,Lot,MinimumQty);
	+::must_assemble(MinimumQty,Item);
	!compound_priority(List);
	.
-!compound_priority([item(_,_,_)|List])
<-	
	!compound_priority(List);
	.
+!compound_tracking([],Lot,MinimumQty)
<-
	MinimumQty = Lot;
	.
+!compound_tracking([Part|Parts],Lot,MinimumQty)
	: not ::partial_stock(_,Part)
<-
	.fail;
	.
+!compound_tracking([Part|Parts],Lot,MinimumQty)
	: ::partial_stock(Qty,Part)
<-
	if (Qty < Lot){
		!compound_tracking(Parts,Qty,MinimumQty);
	} else{
		!compound_tracking(Parts,Lot,MinimumQty);
	}
	-::partial_stock(_,Part);
	+::partial_stock(Qty-MinimumQty,Part);
	.
