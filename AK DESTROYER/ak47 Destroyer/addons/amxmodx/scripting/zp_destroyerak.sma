#include <amxmodx>
#include <cstrike>
#include <amxmisc>
#include <hamsandwich>
#include <fakemeta>
#include <zombie_plague_special>

#if ZPS_INC_VERSION < 45
	#assert Zombie Plague Special 4.5 Include File Required. Download Link: https://forums.alliedmods.net/showthread.php?t=260845
#endif


new const ITEM_NAME[] = "destroyer AK";
new const ITEM_COST = 300;


new const V_destroyer_MODEL[] = "models/zombie_plague/v_ak47_destroyer.mdl";
new const P_destroyer_MODEL[] = "models/zombie_plague/p_ak47_destroyer.mdl";
new const W_destroyer_MODEL[] = "models/w_ak47.mdl";

new const WPN_ENTITY[] = "weapon_ak47"
const WPN_CSW = CSW_AK47;
const WPN_TYPE = WPN_PRIMARY;
const WPN_KEY = 1400;


new const TracePreEntities[][] = { "func_breakable", "func_wall", "func_door", "func_door_rotating", "func_plat", "func_rotating", "player", "worldspawn" }
new g_iItemID, m_spriteTexture, cvar_dmg_multi, cvar_limit, cvar_zoom, g_buy_limit, bool:g_HasAKD[33], g_iDmg[33], g_Zoom[33];

#define is_valid_player(%1) (1 <= %1 <= 32)

new const ZP_ARMASCVAR[] = "zp_configs/zp_armas_cvars.cfg"

public plugin_cfg(){
	static cfgdir[32]; get_configsdir(cfgdir, charsmax(cfgdir)) // Get configs dir
	server_cmd("exec %s/%s", cfgdir, ZP_ARMASCVAR) // Execute .cfg config file
}

public plugin_init() {
	
	register_plugin("[ZP] Extra Item: destroyer AK", "1.1", "Teixeira")
	
	register_clcmd("say /ak", "zp_extra_item_selected")
	cvar_dmg_multi = register_cvar("zp_destroyerak_dmg_multiplier", "2.7") 
	cvar_limit = register_cvar("zp_destroyerak_buy_limit", "3")		
	cvar_zoom  = register_cvar("zp_destroyer_ak47_zoom", "1") 

	register_forward(FM_SetModel, "fw_SetModel")
	register_forward(FM_CmdStart, "fw_CmdStart")
	RegisterHam(Ham_TakeDamage, "player", "fw_TakeDamage")
	RegisterHam(Ham_Item_AddToPlayer, WPN_ENTITY, "fw_WpnAddToPlayer")
	register_event("HLTV", "event_round_start", "a", "1=0", "2=0")

	for(new i = 0; i < sizeof TracePreEntities; i++)
		RegisterHam(Ham_TraceAttack, TracePreEntities[i], "fw_TraceAttackPre");
	
	g_iItemID = zp_register_extra_item(ITEM_NAME, ITEM_COST, ZP_TEAM_HUMAN) 
}


public plugin_precache() {
	// Models
	precache_model(V_destroyer_MODEL)
	precache_model(P_destroyer_MODEL)
	precache_sound("weapons/zoom.wav")
	
	// Sprites
	m_spriteTexture = precache_model("sprites/dot.spr");
}

public client_disconnected(id) reset_vars(id);
public zp_user_humanized_post(id) reset_vars(id);
public zp_player_spawn_post(id) reset_vars(id);


public reset_vars(id)
{
	g_HasAKD[id] = false
	g_iDmg[id] = 0
	g_Zoom[id] = false
}

public zp_user_infected_post(infected, infector)
{
	if (g_HasAKD[infected])
	{
		g_HasAKD[infected] = false
		g_iDmg[infected] = 0
		g_Zoom[infected] = false
	}
}

public fw_CmdStart(id, uc_handle, seed)
{
	if(!is_user_alive(id)) 
		return PLUGIN_HANDLED
	
	if (get_pcvar_num(cvar_zoom))
	{

		if((get_uc(uc_handle, UC_Buttons) & IN_ATTACK2) && !(pev(id, pev_oldbuttons) & IN_ATTACK2))
		{
			new szClip, szAmmo
			new szWeapID = get_user_weapon(id, szClip, szAmmo)
		
			if(szWeapID == WPN_CSW && g_HasAKD[id] == true && !g_Zoom[id] == true)
			{
				g_Zoom[id] = true
				cs_set_user_zoom( id, CS_SET_AUGSG552_ZOOM, 0)
				emit_sound(id, CHAN_ITEM, "weapons/zoom.wav", 0.20, 2.40, 0, 100)
			}

			else if (szWeapID == WPN_CSW && g_HasAKD[id] == true && g_Zoom[id])
			{
				g_Zoom[id] = false
				cs_set_user_zoom(id, CS_RESET_ZOOM, 0)
			}
		}
	}
	return PLUGIN_HANDLED
}

public event_round_start() 
{
	for (new id = 1; id <= 32; id++)
	{
		if (!is_user_connected(id) || !is_user_alive(id))
			continue;

		if (g_HasAKD[id])
		{
			g_HasAKD[id] = false
			g_Zoom[id] = false
		}
	}
	g_buy_limit = 0
}

public zp_extra_item_selected_pre(player, itemid) {
	if (itemid != g_iItemID) 
		return PLUGIN_CONTINUE
	
	zp_extra_item_textadd(fmt("\r[%d/%d]", g_buy_limit, get_pcvar_num(cvar_limit)))

	if(g_HasAKD[player] || g_buy_limit >= get_pcvar_num(cvar_limit))
		return ZP_PLUGIN_HANDLED

	return PLUGIN_CONTINUE;	
}

public zp_extra_item_selected(player, itemid) {
	if(itemid != g_iItemID) 
		return PLUGIN_CONTINUE;

	if(g_HasAKD[player])
		return ZP_PLUGIN_HANDLED;

	zp_drop_weapons(player, WPN_TYPE);
	g_HasAKD[player] = true
	
	set_pev(player, pev_renderfx, kRenderFxGlowShell)
	switch(random_num(4,4))
	{
			case 1: set_pev(player, pev_rendercolor, Float:{0.0,0.0,255.0})
			case 2: set_pev(player, pev_rendercolor, Float:{0.0,255.0,0.0})
			case 3: set_pev(player, pev_rendercolor, Float:{255.0,0.0,0.0})
			case 4: set_pev(player, pev_rendercolor, Float:{255.0,255.0,255.0})
	}
	zp_give_item(player, WPN_ENTITY, 1)
	client_print_color(player, print_team_grey, "^4[ZP]^1 Voce comprou ^1%s^4 !!!", ITEM_NAME)
	g_buy_limit++

	return PLUGIN_CONTINUE;
}


public fw_TakeDamage(victim, inflictor, attacker, Float:damage, damage_type) {
	if (is_valid_player(attacker) && get_user_weapon(attacker) == WPN_CSW && g_HasAKD[attacker])
	{
		SetHamParamFloat(4, damage * get_pcvar_float(cvar_dmg_multi));
	}
}

public fw_TraceAttackPre(iVictim, iAttacker, Float:fDamage, Float:fDeriction[3], iTraceHandle, iBitDamage) {
	if(!is_user_alive(iAttacker))
		return;

	if(get_user_weapon(iAttacker) != CSW_AK47 || !g_HasAKD[iAttacker]) 
		return;

	free_tr2(iTraceHandle);

	static Float:end[3]
	get_tr2(iTraceHandle, TR_vecEndPos, end)

	message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
	write_byte(TE_BEAMENTPOINT)
	write_short(iAttacker | 0x1000)
	engfunc(EngFunc_WriteCoord, end[0])
	engfunc(EngFunc_WriteCoord, end[1])
	engfunc(EngFunc_WriteCoord, end[2])
	write_short(m_spriteTexture)
	write_byte(1) // framerate
	write_byte(5) // framerate
	write_byte(2) // life
	write_byte(10)  // width
	write_byte(0)// noise
	write_byte(200)// r, g, b
	write_byte(0)// r, g, b
	write_byte(0)// r, g, b
	write_byte(200)	// brightness
	write_byte(150)	// speed
	message_end()
}

public zp_fw_deploy_weapon(id, wpn_id) {
	if(!is_user_alive(id) || wpn_id != WPN_CSW)
		return;

	if(g_HasAKD[id]) {
		set_pev(id, pev_viewmodel2, V_destroyer_MODEL)
		set_pev(id, pev_weaponmodel2, P_destroyer_MODEL)
	}
}


public fw_SetModel(entity, model[]) {
	if(!pev_valid(entity)) 
		return FMRES_IGNORED

	if(!equali(model, W_destroyer_MODEL)) 
		return FMRES_IGNORED

	static className[32], iOwner, iStoredWeapon;
	pev(entity, pev_classname, className, charsmax(className))

	iOwner = pev(entity, pev_owner) 
	iStoredWeapon = fm_find_ent_by_owner(-1, WPN_ENTITY, entity) 

	if(g_HasAKD[iOwner] && pev_valid(iStoredWeapon)) {
		set_pev(iStoredWeapon, pev_impulse, WPN_KEY) 
		g_HasAKD[iOwner] = false 
		engfunc(EngFunc_SetModel, entity, W_destroyer_MODEL) 
		return FMRES_SUPERCEDE
	}
	return FMRES_IGNORED
}


public fw_WpnAddToPlayer(wpn_ent, id) {

	if(pev_valid(wpn_ent) && is_user_connected(id) && pev(wpn_ent, pev_impulse) == WPN_KEY) {
		g_HasAKD[id] = true 
		set_pev(wpn_ent, pev_impulse, 0) 
		return HAM_HANDLED;
	}
	return HAM_IGNORED
}

// From fakemeta_util
stock fm_find_ent_by_owner(index, const classname[], owner, jghgtype = 0) {
	new strtype[11] = "classname", ent = index;
	switch (jghgtype) {
		case 1: strtype = "target";
		case 2: strtype = "targetname";
	}

	while ((ent = engfunc(EngFunc_FindEntityByString, ent, strtype, classname)) && pev(ent, pev_owner) != owner) {}

	return ent;
}
// fix
