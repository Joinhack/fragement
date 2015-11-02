require "public_config"

redis_vt_name =
{
    vt_friendNum       = 'friendNum',
    vt_items           = 'items',
    vt_battleProps     = 'battleProps',
    vt_skillBag        = 'skillBag',
    vt_arenicFight     = 'arenicFight',
}
redis_vt_seq = 
{
    [redis_vt_name.vt_friendNum]   = 1,
    [redis_vt_name.vt_items]       = 2,
    [redis_vt_name.vt_battleProps] = 3,
    [redis_vt_name.vt_skillBag]    = 4,
    [redis_vt_name.vt_arenicFight] = 5,
}

--self.DbidToPlayers存redis的字段以及对应的key
redis_DbidToPlayers_index = 
{
    [redis_vt_name.vt_friendNum]       = public_config.USER_MGR_PLAYER_FRIEND_NUM_INDEX,
    [redis_vt_name.vt_items]           = public_config.USER_MGR_PLAYER_ITEMS_INDEX,
    [redis_vt_name.vt_battleProps]     = public_config.USER_MGR_PLAYER_BATTLE_PROPS,
    [redis_vt_name.vt_skillBag]        = public_config.USER_MGR_PLAYER_SKILL_BAG,
}
--self.m_lFights存redis的字段以及对应的key
redis_m_lFights_index = 
{
    [redis_vt_name.vt_arenicFight] = public_config.USER_MGR_FIGHTS_FIGHT_INDEX,
}


--mysql
mysql_vt_name = 
{
    vt_friendNum       = 'friendNum',
    vt_arenicFight     = 'arenicFight',
}
mysql_DbidToPlayers_index = 
{
    [redis_vt_name.vt_friendNum] = public_config.USER_MGR_PLAYER_FRIEND_NUM_INDEX,
}
mysql_m_lFights_index =
{
    [redis_vt_name.vt_arenicFight] = public_config.USER_MGR_FIGHTS_FIGHT_INDEX,
}