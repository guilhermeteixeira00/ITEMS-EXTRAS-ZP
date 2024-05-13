#include <amxmodx>
#include <amxmisc>
#include <hamsandwich>
#include <fakemeta>
#include <zombie_plague_special>

#if ZPS_INC_VERSION < 45
	#assert Zombie Plague Special 4.5 Include File Required. Download Link: https://forums.alliedmods.net/showthread.php?t=260845
#endif


new const ITEM_NAME[] = "Galaxy AK";
new const ITEM_COST = 100;


new const V_GALAXY_MODEL[] = "models/zombie_plague/v_akgalaxy_new_ndk.mdl";
new const P_GALAXY_MODEL[] = "models/zombie_plague/p_akgalaxy_new.mdl";
new const w_GALAXY_MODEL[] = "models/w_ak47.mdl";

new const SOUND_IDLE[] = "weapons/ak47galaxyndk_idle.wav"
new const SOUND_DRAW[] = "weapons/ak47galaxyndk_draw.wav"
new const SOUND_RELOAD[] = "weapons/ak47galaxyndk_reload.wav"

new const SPRITES_AKGALAXY[][] = {
	"sprites/galaxyndk/spritegalaxyr.spr",
	"sprites/galaxyndk/spritegalaxyg.spr",
	"sprites/galaxyndk/spritegalaxyb.spr",
	"sprites/galaxyndk/spritegalaxyy.spr"
}

new const WPN_ENTITY[] = "weapon_ak47"
const WPN_CSW = CSW_AK47;
const WPN_TYPE = WPN_PRIMARY;
const WPN_KEY = 1200;


new const TracePreEntities[][] = { "func_breakable", "func_wall", "func_door", "func_door_rotating", "func_plat", "func_rotating", "player", "worldspawn" }
new g_iItemID, m_spriteTexture, b_spritegalaxy[4], cvar_dmg_multi, cvar_limit, g_buy_limit, bool:g_HasAKG[33], g_iDmg[33];

#define is_valid_player(%1) (1 <= %1 <= 32)

new const ZP_ARMASCVAR[] = "zp_configs/zp_armas_cvars.cfg"

public plugin_cfg(){
	static cfgdir[32]; get_configsdir(cfgdir, charsmax(cfgdir)) // Get configs dir
	server_cmd("exec %s/%s", cfgdir, ZP_ARMASCVAR) // Execute .cfg config file
}

public plugin_init() {
	
	register_plugin("[ZP] Extra Item: Galaxy AK", "1.1", "Teixeira")
	
	
	cvar_dmg_multi = register_cvar("zp_galaxak_dmg_multiplier", "1.5") 
	cvar_limit = register_cvar("zp_galaxy_buy_limit", "3")		

	register_forward(FM_SetModel, "fw_SetModel")
	RegisterHam(Ham_TakeDamage, "player", "fw_TakeDamage")
	RegisterHam(Ham_Item_AddToPlayer, WPN_ENTITY, "fw_WpnAddToPlayer")
	register_event("HLTV", "event_round_start", "a", "1=0", "2=0")

	for(new i = 0; i < sizeof TracePreEntities; i++)
		RegisterHam(Ham_TraceAttack, TracePreEntities[i], "fw_TraceAttackPre");
	
	g_iItemID = zp_register_extra_item(ITEM_NAME, ITEM_COST, ZP_TEAM_HUMAN) 
}


public plugin_precache() {
	// Models
	precache_model(V_GALAXY_MODEL)
	precache_model(P_GALAXY_MODEL)

	precache_sound(SOUND_IDLE)
	precache_sound(SOUND_DRAW)
	precache_sound(SOUND_RELOAD)

	
	// Sprites
	m_spriteTexture = precache_model("sprites/laserbeam.spr");
	b_spritegalaxy[0] = precache_model(SPRITES_AKGALAXY[0]);
	b_spritegalaxy[1] = precache_model(SPRITES_AKGALAXY[1]);
	b_spritegalaxy[2] = precache_model(SPRITES_AKGALAXY[2]);
	b_spritegalaxy[3] = precache_model(SPRITES_AKGALAXY[3]);
}

public client_disconnected(id) reset_vars(id);
public zp_user_infected_post(id) reset_vars(id);
public zp_user_humanized_post(id) reset_vars(id);
public zp_player_spawn_post(id) reset_vars(id);

public reset_vars(id) {
	g_HasAKG[id] = false
	g_iDmg[id] = 0
}

public event_round_start() 
{
	g_buy_limit = 0
}

public zp_extra_item_selected_pre(player, itemid) {
	if (itemid != g_iItemID) 
		return PLUGIN_CONTINUE
	
	zp_extra_item_textadd(fmt("\r[%d/%d]", g_buy_limit, get_pcvar_num(cvar_limit)))

	if(g_HasAKG[player] || g_buy_limit >= get_pcvar_num(cvar_limit))
		return ZP_PLUGIN_HANDLED

	return PLUGIN_CONTINUE;	
}

public zp_extra_item_selected(player, itemid) {
	if(itemid != g_iItemID) 
		return PLUGIN_CONTINUE;

	if(g_HasAKG[player])
		return ZP_PLUGIN_HANDLED;

	zp_drop_weapons(player, WPN_TYPE);
	g_HasAKG[player] = true
	zp_give_item(player, WPN_ENTITY, 1)
	client_print_color(player, print_team_grey, "^4[ZP]^1 Voce comprou ^1%s^4 !!!", ITEM_NAME)
	g_buy_limit++

	return PLUGIN_CONTINUE;
}

public fw_TakeDamage(victim, inflictor, attacker, Float:damage, damage_type) {
	if (is_valid_player(attacker) && get_user_weapon(attacker) == WPN_CSW && g_HasAKG[attacker])
	{
		SetHamParamFloat(4, damage * get_pcvar_float(cvar_dmg_multi));
	}
}

public fw_TraceAttackPre(iVictim, iAttacker, Float:fDamage, Float:fDeriction[3], iTraceHandle, iBitDamage) {
	if(!is_user_alive(iAttacker))
		return;

	if(get_user_weapon(iAttacker) != CSW_AK47 || !g_HasAKG[iAttacker]) 
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
	write_byte(0) // framerate
	write_byte(1) // framerate
	write_byte(1) // life
	write_byte(10)  // width
	write_byte(4)// noise
	write_byte(random_num(0, 255))// r, g, b
	write_byte(random_num(0, 255))// r, g, b
	write_byte(random_num(0, 255))// r, g, b
	write_byte(200)	// brightness
	write_byte(0)	// speed
	message_end()

	pontinhos(iAttacker)
}

public pontinhos(id)
{
	new origin[3]
   
	get_user_origin(id, origin, 3)
   
	message_begin(MSG_ALL,SVC_TEMPENTITY,{0,0,0},id)
	write_byte(TE_SPRITETRAIL)
	write_coord(origin[0])
	write_coord(origin[1])
	write_coord(origin[2]+5)
	write_coord(origin[0])
	write_coord(origin[1])
	write_coord(origin[2]+80)
	write_short(b_spritegalaxy[random_num(0,3)])
	write_byte(1)   //  framerate
	write_byte(5)   //  framerate
	write_byte(4)   //  life
	write_byte(20)  //  width
	write_byte(10) 	//  noise
	message_end()
}

public zp_fw_deploy_weapon(id, wpn_id) {
	if(!is_user_alive(id) || wpn_id != WPN_CSW)
		return;

	if(g_HasAKG[id]) {
		set_pev(id, pev_viewmodel2, V_GALAXY_MODEL)
		set_pev(id, pev_weaponmodel2, P_GALAXY_MODEL)
	}
}


public fw_SetModel(entity, model[]) {
	if(!pev_valid(entity)) 
		return FMRES_IGNORED

	if(!equali(model, w_GALAXY_MODEL)) 
		return FMRES_IGNORED

	static className[32], iOwner, iStoredWeapon;
	pev(entity, pev_classname, className, charsmax(className))

	iOwner = pev(entity, pev_owner) 
	iStoredWeapon = fm_find_ent_by_owner(-1, WPN_ENTITY, entity) 

	if(g_HasAKG[iOwner] && pev_valid(iStoredWeapon)) {
		set_pev(iStoredWeapon, pev_impulse, WPN_KEY) 
		g_HasAKG[iOwner] = false 
		engfunc(EngFunc_SetModel, entity, w_GALAXY_MODEL) 
		return FMRES_SUPERCEDE
	}
	return FMRES_IGNORED
}


public fw_WpnAddToPlayer(wpn_ent, id) {

	if(pev_valid(wpn_ent) && is_user_connected(id) && pev(wpn_ent, pev_impulse) == WPN_KEY) {
		g_HasAKG[id] = true 
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
