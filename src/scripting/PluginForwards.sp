/**
 * MicroTF2 - PluginForwards.sp
 * 
 * Implements functionality for other SourceMod plugins to interact
 * with the gamemode.
 */

Handle PluginForward_IntermissionStartMapVote;
Handle PluginForward_IntermissionHasMapVoteEnded;
Handle PluginForward_EventOnPlayerWinMinigame;
Handle PluginForward_EventOnPlayerFailedMinigame;
Handle PluginForward_EventOnPlayerWinBossgame;
Handle PluginForward_EventOnPlayerFailedBossgame;
Handle PluginForward_EventOnPlayerWinRound;
Handle PluginForward_EventOnPlayerLoseRound;

stock void InitializePluginForwards()
{
	#if defined LOGGING_STARTUP
	LogMessage("Initializing Plugin Forwards...");
	#endif

	PluginForward_IntermissionStartMapVote = CreateGlobalForward("WarioWare_Intermission_StartMapVote", ET_Ignore);
	PluginForward_IntermissionHasMapVoteEnded = CreateGlobalForward("WarioWare_Intermission_HasMapVoteEnded", ET_Single);
	PluginForward_EventOnPlayerWinMinigame = CreateGlobalForward("WarioWare_Event_OnPlayerWinMinigame", ET_Ignore, Param_Any, Param_Any);
	PluginForward_EventOnPlayerFailedMinigame = CreateGlobalForward("WarioWare_Event_OnPlayerFailedMinigame", ET_Ignore, Param_Any, Param_Any);
	PluginForward_EventOnPlayerWinBossgame = CreateGlobalForward("WarioWare_Event_OnPlayerWinBossgame", ET_Ignore, Param_Any, Param_Any);
	PluginForward_EventOnPlayerFailedBossgame = CreateGlobalForward("WarioWare_Event_OnPlayerFailedBossgame", ET_Ignore, Param_Any, Param_Any);
	PluginForward_EventOnPlayerWinRound = CreateGlobalForward("WarioWare_Event_OnPlayerWinRound", ET_Ignore, Param_Any, Param_Any);
	PluginForward_EventOnPlayerLoseRound = CreateGlobalForward("WarioWare_Event_OnPlayerLoseRound", ET_Ignore, Param_Any, Param_Any);
}

stock void RemovePluginForwardsFromMemory()
{
	SafelyRemoveAllFromForward(PluginForward_IntermissionStartMapVote);
	SafelyRemoveAllFromForward(PluginForward_IntermissionHasMapVoteEnded);
}

public void PluginForward_StartMapVote()
{
	Call_StartForward(PluginForward_IntermissionStartMapVote);
	Call_Finish();
}

public bool PluginForward_HasMapVoteEnded()
{
	bool voteIsInProgress = false;

	Call_StartForward(PluginForward_IntermissionHasMapVoteEnded);
	Call_Finish(voteIsInProgress);

	return voteIsInProgress;
}

public void PluginForward_SendPlayerWinMinigame(int client, int minigameId)
{
	Call_StartForward(PluginForward_EventOnPlayerWinMinigame);
	Call_PushCell(client);
	Call_PushCell(minigameId);
	Call_Finish();
}

public void PluginForward_SendPlayerFailedMinigame(int client, int minigameId)
{
	Call_StartForward(PluginForward_EventOnPlayerFailedMinigame);
	Call_PushCell(client);
	Call_PushCell(minigameId);
	Call_Finish();
}

public void PluginForward_SendPlayerWinBossgame(int client, int bossgameId)
{
	Call_StartForward(PluginForward_EventOnPlayerWinBossgame);
	Call_PushCell(client);
	Call_PushCell(bossgameId);
	Call_Finish();
}

public void PluginForward_SendPlayerFailedBossgame(int client, int bossgameId)
{
	Call_StartForward(PluginForward_EventOnPlayerFailedBossgame);
	Call_PushCell(client);
	Call_PushCell(bossgameId);
	Call_Finish();
}

public void PluginForward_SendPlayerWinRound(int client, int score)
{
	Call_StartForward(PluginForward_EventOnPlayerWinRound);
	Call_PushCell(client);
	Call_PushCell(score);
	Call_Finish();
}

public void PluginForward_SendPlayerLoseRound(int client, int score)
{
	Call_StartForward(PluginForward_EventOnPlayerLoseRound);
	Call_PushCell(client);
	Call_PushCell(score);
	Call_Finish();
}