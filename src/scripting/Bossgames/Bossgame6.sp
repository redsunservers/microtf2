/**
 * MicroTF2 - Bossgame 6
 * 
 * Target Practice
 */

/*
 * HORIZONTAL MIN: -5631, -5101, -469
 * HORIZONTAL MAX: -3262, -5153, -469
 * VERTICAL MAX: -4279, -4929, -469
 * VERTICAL MIN: -4391, -6305, -469
 * (3) -469 is the floor coord / Z
 * (2) is the Y - forward and back from view 
 * (1) is the X - left and right from view
 */

int Bossgame6_EntityIndexes[32];
int Bossgame6_Timer;

public void Bossgame6_EntryPoint()
{
	AddToForward(GlobalForward_OnMapStart, INVALID_HANDLE, Bossgame6_OnMapStart);
	AddToForward(GlobalForward_OnTfRoundStart, INVALID_HANDLE, Bossgame6_OnTfRoundStart);
	AddToForward(GlobalForward_OnMinigameSelectedPre, INVALID_HANDLE, Bossgame6_OnMinigameSelectedPre);
	AddToForward(GlobalForward_OnMinigameSelected, INVALID_HANDLE, Bossgame6_OnMinigameSelected);
	AddToForward(GlobalForward_OnBossStopAttempt, INVALID_HANDLE, Bossgame6_OnBossStopAttempt);
	AddToForward(GlobalForward_OnMinigameFinish, INVALID_HANDLE, Bossgame6_OnMinigameFinish);
}

public void Bossgame6_OnMapStart()
{
}

public bool Bossgame6_OnCheck()
{
	if (GetTeamClientCount(2) < 1 || GetTeamClientCount(3) < 1)
	{
		return false;
	}

	return true;
}

public void Bossgame6_OnTfRoundStart()
{
	Bossgame6_SendDoorInput("Close");
}

public void Bossgame6_OnMinigameSelectedPre()
{
	if (BossgameID == 6)
	{
		for (int i = 0; i < 32; i++)
		{
			Bossgame6_EntityIndexes[i] = 0;
		}

		IsBlockingDamage = true;
		IsOnlyBlockingDamageByPlayers = true;
		IsBlockingDeathCommands = true;

		Bossgame6_SendDoorInput("Close");

		Bossgame6_Timer = 9;
		CreateTimer(0.5, Bossgame6_SwitchTimer, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	}
}

public void Bossgame6_OnMinigameSelected(int client)
{
	if (!IsMinigameActive || BossgameID != 6)
	{
		return;
	}

	Player player = new Player(client);

	if (!player.IsValid)
	{
		return;
	}

	player.RemoveAllWeapons();
	player.SetClass(TFClass_Engineer);
	player.SetGodMode(true);
	player.SetCollisionsEnabled(false);
	player.ResetHealth();

	ResetWeapon(client, true);

	float vel[3] = { 0.0, 0.0, 0.0 };
	float ang[3] = { 0.0, 90.0, 0.0 };
	float pos[3];

	int column = client;
	int row = 0;

	while (column > 24)
	{
		column = column - 24;
		row = row + 1;
	}

	pos[0] = -5550.0 + float(column*60); 
	pos[1] = -6625.0 - float(row*100);
	pos[2] = -213.0;

	TeleportEntity(client, pos, ang, vel);
}

public void Bossgame6_OnBossStopAttempt()
{
	if (!IsMinigameActive || BossgameID != 6)
	{
		return;
	}

	int alivePlayers = 0;
	int successfulPlayers = 0;
	int pendingPlayers = 0;

	for (int i = 1; i <= MaxClients; i++)
	{
		Player player = new Player(i);

		if (player.IsValid && player.IsAlive)
		{
			alivePlayers++;

			if (PlayerStatus[i] == PlayerStatus_Failed || PlayerStatus[i] == PlayerStatus_NotWon)
			{
				pendingPlayers++;
			}
			else
			{
				successfulPlayers++;
			}
		}
	}

	if (alivePlayers < 1)
	{
		EndBoss();
	}

	if (successfulPlayers > 0 && pendingPlayers == 0)
	{
		EndBoss();
	}
}

public void Bossgame6_OnMinigameFinish()
{
	if (BossgameID == 6 && IsMinigameActive) 
	{
		Bossgame6_SendDoorInput("Close");
		Bossgame6_CleanupEntities();
	}
}

public Action Bossgame6_SwitchTimer(Handle timer)
{
	if (BossgameID == 6 && IsMinigameActive && !IsMinigameEnding) 
	{
		switch (Bossgame6_Timer)
		{
			case 8: 
				Bossgame6_SendDoorInput("Close");
				
			case 7: 
				Bossgame6_CleanupEntities();

			case 6: 
				Bossgame6_DoEntitySpawns();

			case 5: 
				Bossgame6_SendDoorInput("Open");

			case 0:
				Bossgame6_Timer = 9;
		}

		Bossgame6_Timer--;
		return Plugin_Continue;
	}

	Bossgame6_Timer = 9;
	return Plugin_Stop; 
}

public void Bossgame6_DoEntitySpawns()
{
	float Bossgame6_SpawnedEntityPositions[32][3];

	for (int i = 0; i < 32; i++)
	{
		bool validPosition = false;
		float position[3];
		int calculationAttempts = 0;

		while (!validPosition)
		{
			validPosition = true;
			calculationAttempts++;

			if (calculationAttempts > 32)
			{
				return;
			}

			position[0] = GetRandomFloat(-5631.0, -3262.0);
			position[1] = GetRandomFloat(-6305.0, -4929.0);
			position[2] = -469.0;

			for (int j = 0; j < 32; j++)
			{
				if (j == i)
				{
					continue;
				}

				float distance = GetVectorDistance(position, Bossgame6_SpawnedEntityPositions[j]);

				if (distance <= 100)
				{
					validPosition = false;
				}
			}
		}

		int entity = CreateEntityByName("prop_physics");

		if (IsValidEdict(entity))
		{
			// TODO: Random model here
			DispatchKeyValue(entity, "model", "models/props_farm/wooden_barrel.mdl");
			DispatchSpawn(entity);

			TeleportEntity(entity, position, NULL_VECTOR, NULL_VECTOR);
		}

		Bossgame6_EntityIndexes[i] = entity;
	}
}

public void Bossgame6_CleanupEntities()
{
	for (int i = 0; i < 32; i++)
	{
		int entity = Bossgame6_EntityIndexes[i];

		if (IsValidEdict(entity) && entity > MaxClients)
		{
			CreateTimer(0.0, Timer_RemoveEntity, entity);
		}
	}
}

public void Bossgame6_SendDoorInput(const char[] input)
{
	int entity = -1;
	char entityName[32];
	
	while ((entity = FindEntityByClassname(entity, "func_door")) != INVALID_ENT_REFERENCE)
	{
		GetEntPropString(entity, Prop_Data, "m_iName", entityName, sizeof(entityName));

		if (strcmp(entityName, "plugin_TPBoss_Door") == 0)
		{
			AcceptEntityInput(entity, input, -1, -1, -1);
			break;
		}
	}
}