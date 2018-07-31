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