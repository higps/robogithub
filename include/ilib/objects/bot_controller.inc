#include <tf2_stocks>
#include "ilib/entity.inc"
#include "ilib/vector.inc"

#if defined _ilib_botcontroller_included
 #endinput
#endif
#define _ilib_botcontroller_included

methodmap UBotController < UObject
{
	public UBotController(FObject entity)
	{
		if (entity.Cast("bot_controller"))
			return view_as<UBotController>(entity.GetReference());

		return view_as<UBotController>(0);
	}

	property TFClassType Class
	{
		public set()
		{
			this.GetObject().SetKeyValueInt("Class", view_as<int>(Class));
		}
	}

	property int Team
	{
		public set()
		{
			this.GetObject().SetKeyValueInt("Team", Team);
		}
	}

	public void RespawnBot()
	{
		this.GetObject().Input("RespawnBot");
	}

	// Moves this bot to the given object - uses pathfinding.
	public void MoveToObject(FObject target)
	{
		char targetName[64];
		target.GetPropString(Prop_Data, "m_iName", targetName);

		SetVariantString(targetName);
		this.GetObject().Input("AddCommandMoveToEntity");
	}

	// Tells the controlled bot to attack the given target
	public void AttackTarget(FObject target)
	{
		char targetName[64];
        target.GetPropString(Prop_Data, "m_iName", targetName);

        SetVariantString(targetName);
        this.GetObject().Input("AddCommandAttackEntity");
	}

	// Tells the controlled bot to switch to the given weapon slot
	public void SwitchToSlot(TFWeaponSlot slot)
	{
		SetVariantInt(view_as<int>(slot));
		this.GetObject().Input("AddCommandSwitchWeapon");
	}

	/*
	* Tells the controlled bot to defend its current location. It will not move outside the given radius
	*
	* @param radius		Radius for this bot to defend
	*/
	public void DefendPosition(float radius)
	{
		SetVariantFloat(radius);
		this.GetObject().Input("AddCommandDefend");
	}

	/**
	 * Determines if the controlled bot can move
	 * 
	 * @param disable     If true, the controlled bot cannot move
	 */
	public void PreventMovement(bool disable)
	{
		SetVariantInt(view_as<int>(disable));
		this.GetObject().Input("PreventMovement");
	}

	/*
	 * Determines if the controlled bot should ignore human players
	 *
	 * @param ignore	If true, the controlled bot will ignore human players
	*/
	public void IgnoreHumans(bool ignore)
	{
		SetVariantInt(view_as<int>(ignore));
		this.GetObject().Input("SetIgnoreHumans");
	}

	// Clears the pending commands for the controlled bot
	public void ClearQueue()
	{
		this.GetObject().Input("ClearQueue");
	}

	// Creates a deferred bot controller object
	public static UBotController CreateBotController()
	{
		FObject controller;
		controller = CreateObjectDeferred("bot_controller");

		return view_as<UBotController>(controller.GetReference());
	}
}
