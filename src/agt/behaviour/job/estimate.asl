// given a list of storages, return the itemized available items; return pattern item(Item,Qtd)
get_available_items([],Temp,ListItems)
:- 
	ListItems = Temp.
get_available_items([Storage|Storages],Temp,ListItems)
:-
	team::available_items(Storage,Items) & 
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
//	.print("Building global stock of compound items");
	?get_available_items(SList,[],ItemizedAvailableItems);
	?sum_up_items(ItemizedAvailableItems,[],AvailableItems);	
	for(.member(item(Item,Qtd),AvailableItems)){
		+::partial_stock(Qtd,Item);
//		.print("Partial stock: ",Item," ",Qtd);
	} 	
	.	

+!priced_estimate(Id,Items)
	: new::storageList(SList)
<-
	?evaluate_items(Items,SList);
	?evaluate_steps;
//	.print(Id," is feasible");
	.
//-!priced_estimate(Id,Storage,Items)[error_msg(Message)]
//<-
//	maybe perform the metrics for failed evaluation here
//	.fail;
//	.

//calculate_lot(Item,DesiredQty,Lot)
//:-
//	Lot = math.ceil(DesiredQty*0.5)
//	.
max_capacity([],Temp,Capacity)
:-
	Capacity = Temp
	.
max_capacity([Role|Roles],Temp,Capacity)
:-
	Role == car &
	Temp <= 50 & 
	NewTemp = 50 &
	max_capacity(Roles,NewTemp,Capacity)
	.
max_capacity([Role|Roles],Temp,Capacity)
:-
	Role == truck &
	Capacity = 100
	.
max_capacity([Role|Roles],Temp,Capacity)
:-
	max_capacity(Roles,Temp,Capacity)
	.
calculate_lot(Item,DesiredQty,Lot)
:-
	default::item(Item,Vol,roles(Roles),_) &
	max_capacity(Roles,30,Capacity) &
	MaxQty = math.floor(Capacity/Vol) & // truck load
	Temp = math.floor(DesiredQty*0.5) &
	HalfQty = math.max(Temp,1) &
	Lot = math.min(HalfQty,MaxQty)	
	.
get_real_desired([],Temp,RealDesired)
:-
	RealDesired = Temp
	.	
get_real_desired([item(Percentual,Item,Qty)|Desired],Temp,RealDesired)
:-
	Percentual < 99 &
	get_real_desired(Desired,[item(Percentual,Item,Qty)|Temp],RealDesired)
	.
get_real_desired([item(Percentual,Item,Qty)|Desired],Temp,RealDesired)
:-
	get_real_desired(Desired,Temp,RealDesired)
	.

+!compound_estimate(Items)
	: new::storageList(SList) & team::desired_compound(CList) & ::get_real_desired(CList,[],RCList) & .print("real desired compound items ",RCList) & not .empty(RCList) & .sort(RCList,SCList)
<-
	!global_stock;
//	.print("Priority Compound: ",SCList);
	!compound_priority(SCList);
	.findall(item(Item,MinimumQty),::must_assemble(MinimumQty,Item),SelectedItems);
	.reverse(SelectedItems,Items);
	.abolish(::partial_stock(_,_));
	.abolish(::must_assemble(_,_));
	.
+!compound_estimate(Items)
<-
	.print("There is no compound item to assemble");
	Items = [];
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
	: not ::partial_stock(_,Part) | ::partial_stock(0,Part)
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
