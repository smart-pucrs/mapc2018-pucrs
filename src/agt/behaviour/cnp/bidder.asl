+default::winner(Item,Base,Mode,TaskId)
	: default::joined(org,OrgId)
<-
	lookupArtifact(TaskId,SchArtId)[wid(OrgId)];
	org::focus(SchArtId)[wid(OrgId)];
	.print("I won the task to assemble ",Item," mode: ",Mode," scheme art id: ",SchArtId);
//	org::commitMission(massist)[artifact_id(SchArtId)];
	.